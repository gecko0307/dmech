module rbody;

import dlib.math.vector;
import dlib.math.matrix;
import dmech.rigidbody;

extern(C):

export void dmBodyGetPosition(void* pBody, float* px, float* py, float* pz)
{
    RigidBody rb = cast(RigidBody)pBody;        
    if (rb)
    {
        *px = rb.position.x;
        *py = rb.position.y;
        *pz = rb.position.z;
    }
}

export void dmBodyGetOrientation(void* pBody, float* x, float* y, float* z, float* w)
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

export void dmBodyGetMatrix(void* pBody, float* m4x4)
{
    RigidBody rb = cast(RigidBody)pBody;        
    if (rb)
    {
        Matrix4x4f m = rb.transformation;
        for(uint i = 0; i < 16; i++)
            m4x4[i] = m.arrayof[i];
    }
}

export void dmBodyGetVelocity(void* pBody, float* vx, float* vy, float* vz)
{
    RigidBody rb = cast(RigidBody)pBody;        
    if (rb)
    {
        *vx = rb.linearVelocity.x;
        *vy = rb.linearVelocity.y;
        *vz = rb.linearVelocity.z;
    }
}

export void dmBodyGetAngularVelocity(void* pBody, float* ax, float* ay, float* az)
{
    RigidBody rb = cast(RigidBody)pBody;        
    if (rb)
    {
        *ax = rb.angularVelocity.x;
        *ay = rb.angularVelocity.y;
        *az = rb.angularVelocity.z;
    }
}

export float dmBodyGetMass(void* pBody)
{
    RigidBody rb = cast(RigidBody)pBody;        
    if (rb)
    {
        return rb.mass;
    }
    else
        return -1.0f;
}

export void dmBodyGetInertiaTensor(void* pBody, float* inertia)
{
    RigidBody rb = cast(RigidBody)pBody;        
    if (rb)
    {
        for(uint i = 0; i < 9; i++)
            inertia[i] = rb.inertiaTensor.arrayof[i];
    }
}

export void dmBodyGetInvInertiaTensor(void* pBody, float* inertia)
{
    RigidBody rb = cast(RigidBody)pBody;        
    if (rb)
    {
        for(uint i = 0; i < 9; i++)
            inertia[i] = rb.invInertiaTensor.arrayof[i];
    }
}

export void dmBodySetActive(void* pBody, int active)
{
    RigidBody rb = cast(RigidBody)pBody;        
    if (rb)
    {
        rb.active = cast(bool)active;
    }
}

export int dmBodyGetActive(void* pBody)
{
    RigidBody rb = cast(RigidBody)pBody;        
    if (rb)
        return rb.active;
    else
        return 0;
}

export int dmBodyGetNumCollisionShapes(void* pBody)
{
    RigidBody rb = cast(RigidBody)pBody;        
    if (rb)
        return rb.shapes.length;
    else
        return 0;
}

export void* dmBodyGetCollisionShape(void* pBody, uint index)
{
    RigidBody rb = cast(RigidBody)pBody;        
    if (rb)
    {
        return cast(void*)rb.shapes[index];
    }
    else
        return null;
}

export void dmBodySetBounce(void* pBody, float bounce)
{
    RigidBody rb = cast(RigidBody)pBody;        
    if (rb)
        rb.bounce = bounce;
}

export float dmBodyGetBounce(void* pBody)
{
    RigidBody rb = cast(RigidBody)pBody;        
    if (rb)
        return rb.bounce;
    else
        return 0.0f;
}

export void dmBodySetFriction(void* pBody, float friction)
{
    RigidBody rb = cast(RigidBody)pBody;        
    if (rb)
        rb.friction = friction;
}

export float dmBodyGetFriction(void* pBody)
{
    RigidBody rb = cast(RigidBody)pBody;        
    if (rb)
        return rb.friction;
    else
        return 0.0f;
}

// TODO:
/*
    - dmBodySetUseGravity
    - dmBodySetEnableRotation
    - dmBodySetDamping
    - dmBodySetStopThreshold
    - dmBodySetUseOwnGravity
    - dmBodySetGravity
    - dmBodyAddCollisionCallback
    - dmBodySetRaycastable
    - dmBodySetUseFriction
    - dmBodySetMaxSpeed

    - dmBodyGetCenterOfMass
    - dmBodyRecalcMass

    - dmBodyApplyForce
    - dmBodyApplyTorque
    - dmBodyApplyForceAtPoint
    - dmBodyApplyForceAtRelPoint
    - dmBodyGetTotalForce
    - dmBodyGetTotalTorque
    - dmBodyApplyImpulse
    - dmBodyApplyImpulseAtPoint
    - dmBodyApplyImpulseAtRelPoint
    - dmBodySetVelocity
    - dmBodySetAngularVelocity
    - dmBodySetPosition
    - dmBodySetRotation
    - dmBodySetRotationMatrix
*/

