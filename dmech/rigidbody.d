/*
Copyright (c) 2013-2017 Timur Gafarov

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

module dmech.rigidbody;

import std.math;

import dlib.core.memory;
import dlib.container.array;
import dlib.math.vector;
import dlib.math.matrix;
import dlib.math.quaternion;
import dlib.math.transformation;
import dlib.math.utils;

import dmech.shape;
import dmech.contact;

interface CollisionDispatcher
{
    void onNewContact(RigidBody rb, Contact c);
}

class RigidBody: Freeable
{
    Vector3f position;
    Quaternionf orientation;

    Vector3f linearVelocity;
    Vector3f angularVelocity;

    Vector3f pseudoLinearVelocity;
    Vector3f pseudoAngularVelocity;

    Vector3f linearAcceleration;
    Vector3f angularAcceleration;

    float mass;
    float invMass;

    Matrix3x3f inertiaTensor;
    Matrix3x3f invInertiaTensor; //TODO: rename to invInertiaWorld

    Vector3f centerOfMass;

    Vector3f forceAccumulator;
    Vector3f torqueAccumulator;

    float bounce;
    float friction;

    bool active = true;
    bool useGravity = true;
    bool enableRotation = true;

    DynamicArray!ShapeComponent shapes;

    bool dynamic;

    float damping = 0.5f;
    float stopThreshold = 0.15f; //0.15f
    float stopThresholdPV = 0.0f; //0.01f

    bool useOwnGravity = false;
    Vector3f gravity = Vector3f(0, 0, 0);

    DynamicArray!CollisionDispatcher collisionDispatchers;

    void contactEvent(Contact c)
    {
        foreach(d; collisionDispatchers.data)
        {
            d.onNewContact(this, c);
        }
    }

    bool raycastable = true;
    uint numContacts = 0;
    bool useFriction = true;
    
    float maxSpeed = float.max;

    this()
    {
        position = Vector3f(0.0f, 0.0f, 0.0f);
        orientation = Quaternionf(0.0f, 0.0f, 0.0f, 1.0f);

        linearVelocity = Vector3f(0.0f, 0.0f, 0.0f);
        angularVelocity = Vector3f(0.0f, 0.0f, 0.0f);

        pseudoLinearVelocity = Vector3f(0.0f, 0.0f, 0.0f);
        pseudoAngularVelocity = Vector3f(0.0f, 0.0f, 0.0f);

        linearAcceleration = Vector3f(0.0f, 0.0f, 0.0f);
        angularAcceleration = Vector3f(0.0f, 0.0f, 0.0f);

        mass = 1.0f;
        invMass = 1.0f;

        inertiaTensor = matrixf(
            mass, 0, 0,
            0, mass, 0,
            0, 0, mass
        );
        invInertiaTensor = matrixf(
            0, 0, 0,
            0, 0, 0,
            0, 0, 0
        );

        centerOfMass = Vector3f(0.0f, 0.0f, 0.0f);

        forceAccumulator = Vector3f(0.0f, 0.0f, 0.0f);
        torqueAccumulator = Vector3f(0.0f, 0.0f, 0.0f);

        bounce = 0.0f;
        friction = 0.5f;

        dynamic = true;
    }

    Matrix4x4f transformation()
    {
        Matrix4x4f t;
        t = translationMatrix(position);
        t *= orientation.toMatrix4x4();
        return t;
    }

    void addShapeComponent(ShapeComponent shape)
    {
        shape.transformation = transformation() * translationMatrix(shape.centroid);
        shapes.append(shape);

        if (!dynamic)
            return;

        centerOfMass = Vector3f(0, 0, 0);
        float m = 0.0f;

        foreach (sh; shapes.data)
        {
            m += sh.mass;
            centerOfMass += sh.mass * sh.centroid;
        }

        float invm = 1.0f / m;
        centerOfMass *= invm;

        mass += shape.mass;
        invMass = 1.0f / mass;

        // Compute inertia tensor using Huygens-Steiner theorem
        inertiaTensor = Matrix3x3f.zero;
        foreach (sh; shapes.data)
        {
            Vector3f r = centerOfMass - sh.centroid;
            inertiaTensor +=
                sh.geometry.inertiaTensor(sh.mass) +
                (Matrix3x3f.identity * dot(r, r) - tensorProduct(r, r)) * sh.mass;
        }

        invInertiaTensor = inertiaTensor.inverse;
    }

    void integrateForces(float dt)
    {
        if (!active || !dynamic)
            return;

        linearAcceleration = forceAccumulator * invMass;
        if (enableRotation)
            angularAcceleration = torqueAccumulator * invInertiaTensor;

        linearVelocity += linearAcceleration * dt;
        if (enableRotation)
            angularVelocity += angularAcceleration * dt;
    }

    void integrateVelocities(float dt)
    {
        if (!active || !dynamic)
            return;

        float d = clamp(1.0f - dt * damping, 0.0f, 1.0f);
        linearVelocity *= d;
        angularVelocity *= d;
        
        float speed = linearVelocity.length;
        
        if (speed > maxSpeed)
            linearVelocity = linearVelocity.normalized * maxSpeed;

        if (speed > stopThreshold /* || numContacts < 3 */)
        {
            position += linearVelocity * dt;
        }

        if (enableRotation)
        if (angularVelocity.length > 0.2f /* || numContacts < 3 */) //stopThreshold
        {
            orientation += 0.5f * Quaternionf(angularVelocity, 0.0f) * orientation * dt;
            orientation.normalize();
        }
    }

    void integratePseudoVelocities(float dt)
    {
        if (!active || !dynamic)
            return;

        float d = clamp(1.0f - dt * damping, 0.0f, 1.0f);

        pseudoLinearVelocity *= d;
        pseudoAngularVelocity *= d;

        if (pseudoLinearVelocity.length > stopThresholdPV)
        {
            position += pseudoLinearVelocity;
        }

        if (enableRotation)
        if (pseudoAngularVelocity.length > stopThresholdPV)
        {
            orientation += 0.5f * Quaternionf(pseudoAngularVelocity, 0.0f) * orientation;
            orientation.normalize();
        }

        pseudoLinearVelocity = Vector3f(0.0f, 0.0f, 0.0f);
        pseudoAngularVelocity = Vector3f(0.0f, 0.0f, 0.0f);
    }

    @property Vector3f worldCenterOfMass()
    {
        return position + orientation.rotate(centerOfMass);
    }

    void updateInertia()
    {
        if (active && dynamic)
        {
            auto rot = orientation.toMatrix3x3;
            //invInertiaTensor = (rot * inertiaTensor * rot.transposed).inverse;
            invInertiaTensor = (rot * inertiaTensor.inverse * rot.transposed);
        }
    }

    void updateShapeComponents()
    {
        foreach (sh; shapes.data)
        {
            sh.transformation = transformation() * translationMatrix(sh.centroid);
        }
    }

    void resetForces()
    {
        forceAccumulator = Vector3f(0, 0, 0);
        torqueAccumulator = Vector3f(0, 0, 0);
    }

    void applyForce(Vector3f force)
    {
        if (!active || !dynamic)
            return;

        forceAccumulator += force;
    }

    void applyTorque(Vector3f torque)
    {
        if (!active || !dynamic)
            return;

        torqueAccumulator += torque;
    }

    void applyImpulse(Vector3f impulse, Vector3f point)
    {
        if (!active || !dynamic)
            return;

        linearVelocity += impulse * invMass;
        Vector3f angularImpulse = cross(point - worldCenterOfMass, impulse);
        angularVelocity += angularImpulse * invInertiaTensor;
    }

    void applyForceAtPos(Vector3f force, Vector3f pos)
    {
        if (!active || !dynamic)
            return;

        forceAccumulator += force;
        torqueAccumulator += cross(pos - worldCenterOfMass, force);
    }

    void applyPseudoImpulse(Vector3f impulse, Vector3f point)
    {
        if (!active || !dynamic)
            return;

        pseudoLinearVelocity += impulse * invMass;
        Vector3f angularImpulse = cross(point - worldCenterOfMass, impulse);
        pseudoAngularVelocity += angularImpulse * invInertiaTensor;
    }

    @property float linearKineticEnergy()
    {
        if (!active || !dynamic)
            return float.infinity;

        // 0.5 * m * v^2
        float v = linearVelocity.length;
        return 0.5f * mass * v * v;
    }

    @property float angularKineticEnergy()
    {
        if (!active || !dynamic)
            return float.infinity;

        // 0.5 * w * I * w
        Vector3f w = angularVelocity;
        return 0.5f * dot(w * inertiaTensor, w);
    }

    ~this()
    {
        shapes.free();
        collisionDispatchers.free();
    }

    void free()
    {
        Delete(this);
    }
}
