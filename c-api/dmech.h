#ifndef _DMECH_H_
#define _DMECH_H_

typedef struct
{
    float sx; float sy; float sz;
    float dx; float dy; float dz;
    float length;
} DMRay;

typedef struct
{
    float px; float py; float pz;
    float nx; float ny; float nz;
    float param;
    void* rbody;
    void* shape;
} DMRayCastInfo;

void dmInit();
void* dmCreateWorld(unsigned int maxCollisions);
void dmDeleteWorld(void* pWorld);
int dmGetNumWorlds();

void* dmWorldAddStaticBody(void* pWorld, float px, float py, float pz);
void* dmWorldAddDynamicBody(void* pWorld, float px, float py, float pz, float mass);
int dmWorldGetNumStaticBodies(void* pWorld);
int dmWorldGetNumDynamicBodies(void* pWorld);
void* dmWorldAddCollisionShape(void* pWorld, void* pBody, void* pGeom, float px, float py, float pz, float mass);
int dmWorldGetNumCollisionShapes(void* pWorld);
void* dmWorldAddConstraint(void* pWorld, void* pConstraint);
int dmWorldGetNumConstraints(void* pWorld);
void* dmWorldSetStaticMesh(void* pMesh);
void dmWorldSetGravity(void* pWorld, float x, float y, float z);
void dmWorldSetSolverIterations(void* pWorld, unsigned int posCorrIter, unsigned int velCorrIter);
void dmWorldSetBroadphase(void* pWorld, int b);
void dmWorldUpdate(void* pWorld, double dt);
int dmWorldRayCastQuery(void* pWorld, DMRay* ray, DMRayCastInfo* info, int checkBodies, int checkBVH);

void* dmCreateGeomSphere(float r);
void* dmCreateGeomBox(float hsx, float hsy, float hsz);
void* dmCreateGeomCylinder(float h, float r);
void* dmCreateGeomCone(float h, float r);
void* dmCreateGeomEllipsoid(float rx, float ry, float rz);
void dmDeleteGeom(void* pGeom);

void dmBodyGetPosition(void* pBody, float* px, float* py, float* pz);
void dmBodyGetOrientation(void* pBody, float* x, float* y, float* z, float* w);
void dmBodyGetMatrix(void* pBody, float* m4x4);
void dmBodyGetVelocity(void* pBody, float* vx, float* vy, float* vz);
void dmBodyGetAngularVelocity(void* pBody, float* ax, float* ay, float* az);
float dmBodyGetMass(void* pBody);
void dmBodyGetInertiaTensor(void* pBody, float* inertia);
void dmBodyGetInvInertiaTensor(void* pBody, float* inertia);
void dmBodySetActive(void* pBody, int active);
int dmBodyGetActive(void* pBody);

#endif
