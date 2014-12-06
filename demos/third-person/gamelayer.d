module gamelayer;

import std.stdio;

import derelict.sdl.sdl;
import derelict.opengl.gl;

import dlib.math.vector;
import dlib.math.matrix;
import dlib.math.affine;
import dlib.geometry.triangle;
import dlib.image.color;

import dgl.core.layer;
import dgl.core.event;
import dgl.core.drawable;
import dgl.graphics.material;
import dgl.graphics.shapes;
import dgl.graphics.lamp;
import dgl.scene.tbcamera;
import dgl.vfs.vfs;
import dgl.asset.dgl;
import dgl.scene.scene;

import dmech.world;
import dmech.rigidbody;
import dmech.geometry;
import dmech.shape;
import dmech.bvh;
import dmech.contact;

import cc;
import gameobj;
import tpcamera;

// TODO: This function is total hack,
// need to rewrite BVH module to handle Triangle ranges,
// and add a method to Scene that will lazily return 
// transformed triangles for entities.
BVHTree!Triangle sceneBVH(Scene scene)
{
    Triangle[] tris;
    foreach(entity; scene.entities)
    {
        if (entity.type == 0)
        if (entity.meshId > -1)
        {
            Matrix4x4f mat = Matrix4x4f.identity;
            mat *= translationMatrix(entity.position);
            mat *= entity.rotation.toMatrix4x4;
            mat *= scaleMatrix(entity.scaling);

            auto mesh = scene.mesh(entity.meshId);
            foreach(fgroup; mesh.fgroups)
            foreach(tri; fgroup.tris)
            {
                Triangle tri2 = tri;
                tri2.v[0] = tri.v[0] * mat;
                tri2.v[1] = tri.v[1] * mat;
                tri2.v[2] = tri.v[2] * mat;
                tri2.normal = entity.rotation.rotate(tri.normal);
                tri2.barycenter = (tri2.v[0] + tri2.v[1] + tri2.v[2]) / 3;

                tris ~= tri2;
            }
        }
    }
    return new BVHTree!Triangle(tris, 4);
}

class GameLayer: Layer
{
    EventManager emanager;
    VirtualFileSystem vfs;

    PhysicsWorld world;
    RigidBody activeBody;

    enum double fixedDelta = 1.0 / 60.0;

    Scene scene;
    BVHTree!Triangle bvh;

    GameObject poRobot;
    CharacterController ccRobot;
    TrackballCamera camera;
    ThirdPersonCamera tpcamera;

    this(uint w, uint h, int depth, EventManager emanager)
    {
        super(0, 0, w, h, LayerType.Layer3D, depth);
        alignToWindow = true;

        this.emanager = emanager;

        // Create VFS
        vfs = new VirtualFileSystem();
        vfs.mount("data/testlevel");

        // Create pysics world
        world = new PhysicsWorld(10000);

        // Create floor object
        auto geomFloorBox = new GeomBox(Vector3f(100, 1, 100));
        RigidBody bFloor = world.addStaticBody(Vector3f(0, -2, 0));
        world.addShapeComponent(bFloor, geomFloorBox, Vector3f(0, 0, 0), 1);
        
        buildPyramid(Vector3f(5, 0, 0), 4, 0);

        // Create robot object
        Vector3f initPosition = Vector3f(4.0f, 6.0f, 0.0f);
        ccRobot = new CharacterController(world, initPosition, 1.0f);
        poRobot = new GameObject();
        poRobot.drawable = new ShapeSphere(1.0f);
        poRobot.shape = ccRobot.rbody.shapes[0];
        addDrawable(poRobot);

        auto geomPlatform = new GeomBox(Vector3f(1, 1, 1));
        auto platformBody = world.addDynamicBody(Vector3f(-5, 5, 0));
        platformBody.bounce = 0.8f;
        world.addShapeComponent(platformBody, geomPlatform, Vector3f(0, 0, 0), 1.0f);
        auto platformObj = new GameObject();
        platformObj.drawable = new ShapeBox(Vector3f(1, 1, 1));
        platformObj.shape = platformBody.shapes[0];
        addDrawable(platformObj);

        // Create lamp
        Lamp lamp = new Lamp(Vector4f(10.0f, 20.0f, 5.0f, 1.0f));
        addDrawable(lamp);

        // Create camera
        tpcamera = new ThirdPersonCamera();
        addModifier(tpcamera);

        // Create scene
        auto istrm = vfs.openForInput("testlevel.dgl");
        scene = loadScene(istrm, vfs);
        addDrawable(scene);
        bvh = sceneBVH(scene);
        world.bvhRoot = bvh.root;
    }

    double time = 0.0;
    override void onUpdate(EventManager emngr)
    {
        time += emngr.deltaTime;
        if (time >= fixedDelta)
        {
            time -= fixedDelta;

            if (emngr.key_pressed[SDLK_DOWN]) ccRobot.move(-10.0f);
            if (emngr.key_pressed[SDLK_UP]) ccRobot.move(10.0f);
            if (emngr.key_pressed[SDLK_LEFT]) ccRobot.turn(-5.0f);
            if (emngr.key_pressed[SDLK_RIGHT]) ccRobot.turn(5.0f);
            if (emngr.key_pressed[SDLK_SPACE]) ccRobot.jump(3.0f);
        
            ccRobot.update();

            world.update(fixedDelta);
        }
            
        ccRobot.updateMatrix();
        poRobot.localTransformation = ccRobot.localMatrix;
        tpcamera.playerDirection = ccRobot.direction;
        tpcamera.playerPosition = ccRobot.rbody.position;
    }
    
    void buildPyramid(Vector3f pyramidPosition, uint pyramidSize, uint pyramidGeom = 0)
    {
        float size = 1.0f;

        float cubeHeight = 2.0f;

        auto box = new ShapeBox(Vector3f(size, cubeHeight * 0.5f, size));
        auto cyl = new ShapeCylinder(2.0f, 1.0f);
        auto con = new ShapeCone(2.0f, 1.0f);
        auto sph = new ShapeSphere(1.0f);

        float width = size * 2.0f;
        float height = cubeHeight;
        float horizontal_spacing = 0.1f;
        float veritcal_spacing = 0.1f;

        auto geomBox = new GeomBox(Vector3f(size, cubeHeight * 0.5f, size));
        auto geomCylinder = new GeomCylinder(2.0f, 1.0f); 
        auto geomSphere = new GeomSphere(size); 
        auto geomCone = new GeomCone(2.0f, 1.0f); 

        foreach(i; 0..pyramidSize)
        foreach(e; i..pyramidSize)
        {
            auto position = pyramidPosition + Vector3f(
                (e - i * 0.5f) * (width + horizontal_spacing) - ((width + horizontal_spacing) * 5), 
                6.0f + (height + veritcal_spacing * 0.5f) + i * height + 0.26f,
                -3);

            Geometry g;
            Drawable gobj;

            switch(pyramidGeom)
            {
                case 0:
                    g = geomBox;
                    gobj = box;
                    break;
                case 1:
                    g = geomCylinder;
                    gobj = cyl;
                    break;
                case 2:
                    g = geomSphere; 
                    gobj = sph;
                    break;
                case 4:
                    g = geomCone;
                    gobj = con;
                    break;
                default:
                    assert(0);
            }

            auto b = world.addDynamicBody(position, 0);
            world.addShapeComponent(b, g, Vector3f(0, 0, 0), 1);

            auto gameObj = new GameObject();
            gameObj.drawable = gobj; 
            gameObj.shape = b.shapes[0];

            Material mat = new Material();
            auto col = Color4f((randomUnitVector3!float + 0.5f).normalized);
            mat.ambientColor = col;
            mat.diffuseColor = col;
            gameObj.material = mat;

            addDrawable(gameObj);
        }
    }
}
