/*
Copyright (c) 2013-2025 Timur Gafarov

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/
module dmech.world;

import std.math;
import std.range;

import dlib.core.ownership;
import dlib.core.memory;
import dlib.container.array;
import dlib.math.vector;
import dlib.math.matrix;
import dlib.math.transformation;
import dlib.geometry.triangle;
import dlib.geometry.sphere;
import dlib.geometry.ray;
import dlib.geometry.plane;

import dmech.rigidbody;
import dmech.geometry;
import dmech.shape;
import dmech.contact;
import dmech.solver;
import dmech.pairhashtable;
import dmech.collision;
import dmech.pcm;
import dmech.constraint;
import dmech.bvh;
import dmech.mpr;
import dmech.raycast;

/*
 * World object stores bodies and constraints
 * and performs simulation cycles on them.
 * It also provides a generalized raycast query for all bodies.
 */

alias PairHashTable!PersistentContactManifold ContactCache;

class PhysicsWorld: Owner
{
    Array!ShapeComponent shapeComponents;
    Array!RigidBody staticBodies;
    Array!RigidBody dynamicBodies;
    Array!Constraint constraints;

    Vector3f gravity;

    protected uint maxShapeId = 1;

    ContactCache manifolds;

    bool broadphase = false;
    bool warmstart = false;

    uint positionCorrectionIterations = 20;
    uint constraintIterations = 40;

    BVHNode!Triangle bvhRoot = null;

    // Proxy triangle to deal with BVH data
    RigidBody proxyTri;
    ShapeComponent proxyTriShape;
    GeomTriangle proxyTriGeom;

    this(Owner owner, size_t maxCollisions = 1000)
    {
        super(owner);

        gravity = Vector3f(0.0f, -9.80665f, 0.0f); // Earth conditions

        manifolds = New!ContactCache(this, maxCollisions);

        // Create proxy triangle
        proxyTri = New!RigidBody(this);
        proxyTri.position = Vector3f(0, 0, 0);
        proxyTriGeom = New!GeomTriangle(this,
            Vector3f(-1.0f, 0.0f, -1.0f),
            Vector3f(+1.0f, 0.0f,  0.0f),
            Vector3f(-1.0f, 0.0f, +1.0f));
        proxyTriShape = New!ShapeComponent(this, proxyTriGeom, Vector3f(0, 0, 0), 1);
        proxyTriShape.id = maxShapeId;
        maxShapeId++;
        proxyTriShape.transformation =
            proxyTri.transformation() * translationMatrix(proxyTriShape.centroid);
        proxyTri.shapes.append(proxyTriShape);
        proxyTri.mass = float.infinity;
        proxyTri.invMass = 0.0f;
        proxyTri.inertiaTensor = matrixf(
            float.infinity, 0, 0,
            0, float.infinity, 0,
            0, 0, float.infinity
        );
        proxyTri.invInertiaTensor = matrixf(
            0, 0, 0,
            0, 0, 0,
            0, 0, 0
        );
        proxyTri.dynamic = false;
    }

    RigidBody addDynamicBody(Vector3f pos, float mass = 0.0f)
    {
        auto b = New!RigidBody(this);
        b.position = pos;
        b.mass = mass;
        b.invMass = 1.0f / mass;
        b.inertiaTensor = matrixf(
            mass, 0, 0,
            0, mass, 0,
            0, 0, mass
        );
        b.invInertiaTensor = matrixf(
            0, 0, 0,
            0, 0, 0,
            0, 0, 0
        );
        b.dynamic = true;
        dynamicBodies.append(b);
        return b;
    }

    RigidBody addStaticBody(Vector3f pos)
    {
        auto b = New!RigidBody(this);
        b.position = pos;
        b.mass = float.infinity;
        b.invMass = 0.0f;
        b.inertiaTensor = matrixf(
            float.infinity, 0, 0,
            0, float.infinity, 0,
            0, 0, float.infinity
        );
        b.invInertiaTensor = matrixf(
            0, 0, 0,
            0, 0, 0,
            0, 0, 0
        );
        b.dynamic = false;
        staticBodies.append(b);
        return b;
    }

    ShapeComponent addShapeComponent(RigidBody b, Geometry geom, Vector3f position, float mass)
    {
        auto shape = New!ShapeComponent(this, geom, position, mass);
        shapeComponents.append(shape);
        shape.id = maxShapeId;
        maxShapeId++;
        b.addShapeComponent(shape);
        return shape;
    }

    ShapeComponent addSensor(RigidBody b, Geometry geom, Vector3f position)
    {
        auto shape = New!ShapeComponent(this, geom, position, 0.0f);
        shape.raycastable = false;
        shape.solve = false;
        shapeComponents.append(shape);
        shape.id = maxShapeId;
        maxShapeId++;
        b.addShapeComponent(shape);
        return shape;
    }

    Constraint addConstraint(Constraint c)
    {
        constraints.append(c);
        return c;
    }

    void update(double dt)
    {
        auto dynamicBodiesArray = dynamicBodies.data;

        if (dynamicBodiesArray.length == 0)
            return;

        foreach(ref m; manifolds)
        {
            m.update();
        }

        for (size_t i = 0; i < dynamicBodiesArray.length; i++)
        {
            auto b = dynamicBodiesArray[i];
            b.updateInertia();
            if (b.useGravity)
            {
                if (b.useOwnGravity)
                    b.applyForce(b.gravity * b.mass);
                else
                    b.applyForce(gravity * b.mass);
            }
            b.integrateForces(dt);
            b.resetForces();
        }

        if (broadphase)
            findDynamicCollisionsBroadphase();
        else
            findDynamicCollisionsBruteForce();

        findStaticCollisionsBruteForce();

        solveConstraints(dt);

        for (size_t i = 0; i < dynamicBodiesArray.length; i++)
        {
            auto b = dynamicBodiesArray[i];
            b.integrateVelocities(dt);
        }

        foreach(iteration; 0..positionCorrectionIterations)
        foreach(ref m; manifolds)
        foreach(i; 0..m.numContacts)
        {
            auto c = &m.contacts[i];
            solvePositionError(c, m.numContacts);
        }

        for (size_t i = 0; i < dynamicBodiesArray.length; i++)
        {
            auto b = dynamicBodiesArray[i];
            b.integratePseudoVelocities(dt);
            b.updateShapeComponents();
        }
    }

    bool raycast(
        Vector3f rayStart,
        Vector3f rayDir,
        float maxRayDist,
        out CastResult castResult,
        bool checkAgainstBodies = true,
        bool checkAgainstBVH = true)
    {
        bool res = false;
        float bestParam = float.max;

        CastResult cr;

        if (checkAgainstBodies)
        foreach(b; chain(staticBodies.data, dynamicBodies.data))
        if (b.active && b.raycastable)
        foreach(shape; b.shapes.data)
        if (shape.active && shape.raycastable)
        {
            bool hit = convexRayCast(shape, rayStart, rayDir, maxRayDist, cr);
            if (hit)
            {
                if (cr.param < bestParam)
                {
                    bestParam = cr.param;
                    castResult = cr;
                    castResult.rbody = b;
                    res = true;
                }
            }
        }

        if (!checkAgainstBVH)
            return res;

        Ray ray = Ray(rayStart, rayStart + rayDir * maxRayDist);

        if (bvhRoot !is null)
        foreach(tri; bvhRoot.traverseByRay(&ray))
        {
            Vector3f ip;
            bool hit = ray.intersectTriangle(tri, ip);
            if (hit)
            {
                float param = distance(rayStart, ip);
                if (param < bestParam)
                {
                    bestParam = param;
                    castResult.fact = true;
                    castResult.param = param;
                    castResult.point = ip;
                    castResult.normal = tri.normal;
                    castResult.rbody = proxyTri;
                    castResult.shape = null;
                    res = true;
                }
            }
        }

        return res;
    }

    void findDynamicCollisionsBruteForce()
    {
        auto dynamicBodiesArray = dynamicBodies.data;
        for (int i = 0; i < dynamicBodiesArray.length - 1; i++)
        {
            auto body1 = dynamicBodiesArray[i];
            if (body1.active)
            foreach(shape1; body1.shapes.data)
            if (shape1.active)
            {
                for (int j = i + 1; j < dynamicBodiesArray.length; j++)
                {
                    auto body2 = dynamicBodiesArray[j];
                    if (body2.active)
                    foreach(shape2; body2.shapes.data)
                    if (shape2.active)
                    {
                        Contact c;
                        c.body1 = body1;
                        c.body2 = body2;
                        checkCollisionPair(shape1, shape2, c);
                    }
                }
            }
        }
    }

    void findDynamicCollisionsBroadphase()
    {
        auto dynamicBodiesArray = dynamicBodies.data;
        for (int i = 0; i < dynamicBodiesArray.length - 1; i++)
        {
            auto body1 = dynamicBodiesArray[i];
            if (body1.active)
            foreach(shape1; body1.shapes.data)
            if (shape1.active)
            {
                for (int j = i + 1; j < dynamicBodiesArray.length; j++)
                {
                    auto body2 = dynamicBodiesArray[j];
                    if (body2.active)
                    foreach(shape2; body2.shapes.data)
                    if (shape2.active)
                    if (shape1.boundingBox.intersectsAABB(shape2.boundingBox))
                    {
                        Contact c;
                        c.body1 = body1;
                        c.body2 = body2;
                        checkCollisionPair(shape1, shape2, c);
                    }
                }
            }
        }
    }

    void findStaticCollisionsBruteForce()
    {
        auto dynamicBodiesArray = dynamicBodies.data;
        auto staticBodiesArray = staticBodies.data;
        foreach(body1; dynamicBodiesArray)
        {
            if (body1.active)
            foreach(shape1; body1.shapes.data)
            if (shape1.active)
            {
                foreach(body2; staticBodiesArray)
                {
                    if (body2.active)
                    foreach(shape2; body2.shapes.data)
                    if (shape2.active)
                    {
                        Contact c;
                        c.body1 = body1;
                        c.body2 = body2;
                        c.shape2pos = shape2.position;
                        checkCollisionPair(shape1, shape2, c);
                    }
                }
            }
        }

        // Find collisions between dynamic bodies
        // and the BVH world (static triangle mesh)
        if (bvhRoot !is null)
        {
            checkCollisionBVH();
        }
    }

    void checkCollisionBVH()
    {
        foreach(rb; dynamicBodies.data)
        if (rb.active)
        foreach(shape; rb.shapes.data)
        if (shape.active)
        {
            // There may be more than one contact at a time
            Contact[5] contacts;
            Triangle[5] contactTris;
            uint numContacts = 0;

            Contact c;
            c.body1 = rb;
            c.body2 = proxyTri;
            c.fact = false;

            Sphere sphere = shape.boundingSphere;

            foreach(tri; bvhRoot.traverseBySphere(&sphere))
            {
                // Update temporary triangle to check collision
                proxyTriShape.transformation = translationMatrix(tri.barycenter);
                proxyTriGeom.v[0] = tri.v[0] - tri.barycenter;
                proxyTriGeom.v[1] = tri.v[1] - tri.barycenter;
                proxyTriGeom.v[2] = tri.v[2] - tri.barycenter;

                bool collided = checkCollision(shape, proxyTriShape, c);

                if (collided)
                {
                    if (numContacts < contacts.length)
                    {
                        c.shape1RelPoint = c.point - shape.position;
                        c.shape2RelPoint = c.point - tri.barycenter;
                        c.body1RelPoint = c.point - c.body1.worldCenterOfMass;
                        c.body2RelPoint = c.point - tri.barycenter;
                        c.shape1 = shape;
                        c.shape2 = proxyTriShape;
                        c.shape2pos = tri.barycenter;
                        contacts[numContacts] = c;
                        contactTris[numContacts] = tri;
                        numContacts++;
                    }
                }
            }

           /*
            * NOTE:
            * There is a problem when rolling bodies over a triangle mesh. Instead of rolling
            * straight it will get influenced when hitting triangle edges.
            * Current solution is to solve only the contact with deepest penetration and
            * throw out all others. Other possible approach is to merge all contacts that
            * are within epsilon of each other. When merging the contacts, average and
            * re-normalize the normals, and average the penetration depth value.
            */
            int deepestContactIdx = -1;
            float maxPen = 0.0f;
            float bestGroundness = -1.0f;
            foreach(i; 0..numContacts)
            {
                if (contacts[i].penetration > maxPen)
                {
                    deepestContactIdx = i;
                    maxPen = contacts[i].penetration;
                }
            }
            
            if (deepestContactIdx >= 0)
            {
                auto co = &contacts[deepestContactIdx];
                co.calcFDir();

                auto m = manifolds.get(shape.id, proxyTriShape.id);
                if (m is null)
                {
                    PersistentContactManifold m1;
                    m1.addContact(*co);
                    manifolds.set(shape.id, proxyTriShape.id, m1);

                    shape.numCollisions++;
                }
                else
                {
                    m.addContact(*co);
                }

                c.body1.numContacts++;
                c.body2.numContacts++;
                
                c.body1.contactEvent(*co);
                c.body2.contactEvent(*co);
            }
            else
            {
                auto m = manifolds.get(shape.id, proxyTriShape.id);
                if (m !is null)
                {
                    manifolds.remove(shape.id, proxyTriShape.id);

                    c.body1.numContacts -= m.numContacts;
                    c.body2.numContacts -= m.numContacts;

                    shape.numCollisions--;
                }
            }
        }
    }

    void checkCollisionPair(ShapeComponent shape1, ShapeComponent shape2, ref Contact c)
    {
        if (checkCollision(shape1, shape2, c))
        {
            c.body1RelPoint = c.point - c.body1.worldCenterOfMass;
            c.body2RelPoint = c.point - c.body2.worldCenterOfMass;
            c.shape1RelPoint = c.point - shape1.position;
            c.shape2RelPoint = c.point - shape2.position;
            c.shape1 = shape1;
            c.shape2 = shape2;
            c.calcFDir();

            auto m = manifolds.get(shape1.id, shape2.id);
            if (m is null)
            {
                PersistentContactManifold m1;
                m1.addContact(c);
                manifolds.set(shape1.id, shape2.id, m1);

                c.body1.contactEvent(c);
                c.body2.contactEvent(c);

                shape1.numCollisions++;
                shape2.numCollisions++;
            }
            else
            {
                m.addContact(c);
            }

            c.body1.numContacts++;
            c.body2.numContacts++;
        }
        else
        {
            auto m = manifolds.get(shape1.id, shape2.id);
            if (m !is null)
            {
                manifolds.remove(shape1.id, shape2.id);

                c.body1.numContacts -= m.numContacts;
                c.body2.numContacts -= m.numContacts;

                shape1.numCollisions--;
                shape2.numCollisions--;
            }
        }
    }

    void solveConstraints(double dt)
    {
        foreach(ref m; manifolds)
        foreach(i; 0..m.numContacts)
        {
            auto c = &m.contacts[i];
            prepareContact(c);
        }

        auto constraintsData = constraints.data;
        foreach(c; constraintsData)
        {
            c.prepare(dt);
        }

        foreach(iteration; 0..constraintIterations)
        {
            foreach(c; constraintsData)
                c.step();

            foreach(ref m; manifolds)
            foreach(i; 0..m.numContacts)
            {
                auto c = &m.contacts[i];
                solveContact(c, dt);
            }
        }
    }

    ~this()
    {
        shapeComponents.free();
        dynamicBodies.free();
        staticBodies.free();
        constraints.free();
    }
}
