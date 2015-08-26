module world;

import core.runtime;
import core.memory;
import dlib.core.memory;
import dlib.container.bst;
import dlib.math.vector;
import dmech.world;
import dmech.rigidbody;
import dmech.geometry;
import dmech.shape;
import dmech.constraint;
import dmech.raycast;

int numWorlds = 0;

extern(C):

export void dmInit()
{
    version(linux) Runtime.initialize();
    GC.disable();
}

export void* dmCreateWorld(uint maxCollisions)
{
    PhysicsWorld world = New!PhysicsWorld(maxCollisions);
    numWorlds++;
    return cast(void*)world;
}

export void dmDeleteWorld(void* pWorld)
{
    PhysicsWorld world = cast(PhysicsWorld)pWorld;        
    if (world)
    {
        Delete(world);
        numWorlds--;
    }
}

export int dmGetNumWorlds()
{
    return numWorlds;
}

export void* dmWorldAddStaticBody(void* pWorld, float px, float py, float pz)
{
    PhysicsWorld world = cast(PhysicsWorld)pWorld;        
    if (world)
    {
        RigidBody rb = world.addStaticBody(Vector3f(px, py, pz));
        return cast(void*)rb;
    }
    else
        return null;
}

export void* dmWorldAddDynamicBody(void* pWorld, float px, float py, float pz, float mass)
{
    PhysicsWorld world = cast(PhysicsWorld)pWorld;        
    if (world)
    {
        RigidBody rb = world.addDynamicBody(Vector3f(px, py, pz), mass);
        return cast(void*)rb;
    }
    else
        return null;
}

export int dmWorldGetNumStaticBodies(void* pWorld)
{
    PhysicsWorld world = cast(PhysicsWorld)pWorld;
    if (world)
        return world.staticBodies.length;
    else
        return 0;
}

export int dmWorldGetNumDynamicBodies(void* pWorld)
{
    PhysicsWorld world = cast(PhysicsWorld)pWorld;
    if (world)
        return world.dynamicBodies.length;
    else
        return 0;
}

export void* dmWorldAddCollisionShape(void* pWorld, void* pBody, void* pGeom, float px, float py, float pz, float mass)
{
    PhysicsWorld world = cast(PhysicsWorld)pWorld;
    RigidBody rb = cast(RigidBody)pBody;
    Geometry geom = cast(Geometry)pGeom;
    if (world && rb && geom)
    {
        ShapeComponent sc = world.addShapeComponent(rb, geom, Vector3f(px, py, pz), mass);
        return cast(void*)sc;
    }
    else
        return null;
}

export int dmWorldGetNumCollisionShapes(void* pWorld)
{
    PhysicsWorld world = cast(PhysicsWorld)pWorld;
    if (world)
        return world.shapeComponents.length;
    else
        return 0;
}

export void* dmWorldAddConstraint(void* pWorld, void* pConstraint)
{
    PhysicsWorld world = cast(PhysicsWorld)pWorld;
    Constraint c = cast(Constraint)pConstraint;
    if (world && c)
    {
        world.addConstraint(c);
        return pConstraint;
    }
    else
        return null;
}

export int dmWorldGetNumConstraints(void* pWorld)
{
    PhysicsWorld world = cast(PhysicsWorld)pWorld;
    if (world)
        return world.constraints.length;
    else
        return 0;
}

export void* dmWorldSetStaticMesh(void* pMesh)
{
    // TODO
    return null;
}

export void dmWorldSetGravity(void* pWorld, float x, float y, float z)
{
    PhysicsWorld world = cast(PhysicsWorld)pWorld;        
    if (world)
    {
        world.gravity = Vector3f(x, y, z);
    }
}

export void dmWorldSetSolverIterations(void* pWorld, uint posCorrIter, uint velCorrIter)
{
    PhysicsWorld world = cast(PhysicsWorld)pWorld;        
    if (world)
    {
        world.positionCorrectionIterations = posCorrIter;
        world.constraintIterations = velCorrIter;
    }
}

export void dmWorldSetBroadphase(void* pWorld, int b)
{
    PhysicsWorld world = cast(PhysicsWorld)pWorld;        
    if (world)
    {
        world.broadphase = cast(bool)b;
    }
}

export void dmWorldUpdate(void* pWorld, double dt)
{
    PhysicsWorld world = cast(PhysicsWorld)pWorld;        
    if (world)
    {
        world.update(dt);
    }
}

struct DMRay
{
    float sx; float sy; float sz;
    float dx; float dy; float dz;
    float length;
}

struct DMRayCastInfo
{
    float px; float py; float pz;
    float nx; float ny; float nz;
    float param;
    void* rbody;
    void* shape;
}

export int dmWorldRayCastQuery(void* pWorld, DMRay* ray, DMRayCastInfo* info, int checkBodies, int checkBVH)
{
    PhysicsWorld world = cast(PhysicsWorld)pWorld;        
    if (world && ray && info)
    {
        CastResult cr;
        bool res = world.raycast(
            Vector3f(ray.sx, ray.sy, ray.sz),
            Vector3f(ray.dx, ray.dy, ray.dz),
            ray.length, cr,
            cast(bool)checkBodies, cast(bool)checkBVH);

        if (res)
        {
            info.px = cr.point.x;
            info.py = cr.point.y;
            info.pz = cr.point.z;

            info.nx = cr.normal.x;
            info.ny = cr.normal.y;
            info.nz = cr.normal.z;

            info.param = cr.param;
            info.rbody = cast(void*)cr.rbody;
            info.shape = cast(void*)cr.shape;

            return 1;
        }
        else
            return 0;
    }
    else
        return 0;
}


