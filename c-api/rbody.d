module rbody;

import dlib.math.vector;
import dlib.math.matrix;
import dmech.rigidbody;

extern(C):

void dmBodyGetPosition(void* pBody, float* px, float* py, float* pz)
{
    RigidBody rb = cast(RigidBody)pBody;        
    if (rb)
    {
        *px = rb.position.x;
        *py = rb.position.y;
        *pz = rb.position.z;
    }
}

void dmBodyGetOrientation(void* pBody, float* x, float* y, float* z, float* w)
{
    RigidBody rb = cast(RigidBody)pBody;        
    if (rb)
    {
        *x = rb.orientation.x;
        *y = rb.orientation.y;
        *z = rb.orientation.z;
        *w = rb.orientation.w;
    }
}

void dmBodyGetMatrix(void* pBody, float* m4x4)
{
    RigidBody rb = cast(RigidBody)pBody;        
    if (rb)
    {
        Matrix4x4f m = rb.transformation;
        for(uint i = 0; i < 16; i++)
            m4x4[i] = m.arrayof[i];
    }
}

void dmBodyGetVelocity(void* pBody, float* vx, float* vy, float* vz)
{
    RigidBody rb = cast(RigidBody)pBody;        
    if (rb)
    {
        *vx = rb.linearVelocity.x;
        *vy = rb.linearVelocity.y;
        *vz = rb.linearVelocity.z;
    }
}

void dmBodyGetAngularVelocity(void* pBody, float* ax, float* ay, float* az)
{
    RigidBody rb = cast(RigidBody)pBody;        
    if (rb)
    {
        *ax = rb.angularVelocity.x;
        *ay = rb.angularVelocity.y;
        *az = rb.angularVelocity.z;
    }
}

float dmBodyGetMass(void* pBody)
{
    RigidBody rb = cast(RigidBody)pBody;        
    if (rb)
    {
        return rb.mass;
    }
    else
        return -1.0f;
}

void dmBodyGetInertiaTensor(void* pBody, float* inertia)
{
    RigidBody rb = cast(RigidBody)pBody;        
    if (rb)
    {
        for(uint i = 0; i < 9; i++)
            inertia[i] = rb.inertiaTensor.arrayof[i];
    }
}

void dmBodyGetInvInertiaTensor(void* pBody, float* inertia)
{
    RigidBody rb = cast(RigidBody)pBody;        
    if (rb)
    {
        for(uint i = 0; i < 9; i++)
            inertia[i] = rb.invInertiaTensor.arrayof[i];
    }
}

void dmBodySetActive(void* pBody, int active)
{
    RigidBody rb = cast(RigidBody)pBody;        
    if (rb)
    {
        rb.active = cast(bool)active;
    }
}

int dmBodyGetActive(void* pBody)
{
    RigidBody rb = cast(RigidBody)pBody;        
    if (rb)
        return rb.active;
    else
        return 0;
}

