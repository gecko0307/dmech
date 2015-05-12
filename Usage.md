To use dmech in your application, import the following modules:

    import dmech.geometry;
    import dmech.rigidbody;
    import dmech.world;
    import dlib.core.memory;
    import dlib.math.vector;
    import dlib.math.matrix;

Create a world:

    PhysicsWorld world = New!PhysicsWorld();

Add some bodies and apply geometries to them:

    // bGround - static box 40x40x1 m that acts as a ground plane
    RigidBody bGround = world.addStaticBody(Vector3f(0.0f, -1.0f, 0.0f));
    Geometry gGround = New!GeomBox(Vector3f(40.0f, 1.0f, 40.0f));
    world.addShapeComponent(bGround, gGround, Vector3f(0.0f, 0.0f, 0.0f), 1.0f);

    // bSphere - dynamic sphere with radius of 1 m and mass of 1 kg 
    RigidBody bSphere = world.addDynamicBody(Vector3f(0.0f, 2.0f, 0.0f), 0.0f);
    Geometry gSphere = New!GeomSphere(1.0f);
    world.addShapeComponent(bSphere, gSphere, Vector3f(0.0f, 0.0f, 0.0f), 1.0f);

Now, whenever you want to update the world:

    // delta - simulation time step in seconds, usually is fixed
    double delta = 1.0 / 60.0;
    world.update(delta);

Then, align your graphical objects to corresponding body matrices:

    Matrix4x4f m;
    m = bGround.shapes[0].transformation;
    myGround.setMatrix(m);
    m = bSphere.shapes[0].transformation;
    mySphere.setMatrix(m);

4x4 matrices are OpenGL-friendly. Layout is the following:

    1 0 0 x
    0 1 0 y
    0 0 1 z
    0 0 0 1
    
When you are done with your simulation, don't forget to free the memory allocated by the PhysicsWorld:

    world.free();
    
Because dmech doesn't use D's garbage collector to allocate its memory, it needs to be freed manually.
Don't try to update the simulation of access bodies after the world was freed.

Also you should free your geometries once you don't need them anymore (they are not freed automatically
with the bodies, because they can be shared between several worlds).

    gGround.free();
    gSphere.free();

