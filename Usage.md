To use dmech in your application, import the following modules:

    import dmech.geometry;
    import dmech.rigidbody;
    import dmech.world;

    import dlib.math.vector;
    import dlib.math.matrix;

Create a world:

    PhysicsWorld world = new PhysicsWorld();

Add some bodies and apply geometries to them:

    // bGround - static box 40x40x1 m that acts as a ground plane
    RigidBody bGround = world.addStaticBody(Vector3f(0.0f, -1.0f, 0.0f));
    bGround.setGeometry(new GeomBox(Vector3f(40.0f, 1.0f, 40.0f)));

    // bSphere - dynamic sphere with radius of 1 m and mass of 1 kg 
    RigidBody bSphere = world.addDynamicBody(Vector3f(0.0f, 2.0f, 0.0f), 1.0f);
    bSphere.setGeometry(new GeomSphere(1.0f));

Now, whenever you want to update the world:

    // delta - simulation time step in seconds, usually is fixed
    double delta = 1.0 / 60.0;
    world.update(delta);

Then, align your graphical objects to corresponding body matrices:

    Matrix4x4f m;
    m = bGround.geometry.transformation;
    myGround.setMatrix(m);
    m = bSphere.geometry.transformation;
    mySphere.setMatrix(m);

4x4 matrices are OpenGL-friendly. Layout is the following:

    1 0 0 0
    0 1 0 0
    0 0 1 0
    x y z 1