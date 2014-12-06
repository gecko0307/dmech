module physlayer;

import derelict.sdl.sdl;

import dlib.math.vector;
import dlib.image.color;

import dgl.core.event;
import dgl.core.layer;
import dgl.core.drawable;
import dgl.graphics.shapes;
import dgl.graphics.material;
import dgl.scene.tbcamera;

import dmech.world;
import dmech.rigidbody;
import dmech.geometry;

import physobject;

class PhysicsLayer: Layer
{
    World world;
    RigidBody activeBody;

    TrackballCamera camera;

    this(uint w, uint h, int depth)
    {
        super(0, 0, w, h, LayerType.Layer3D, depth);
        alignToWindow = true;

        world = new World();
        auto geomFloorBox = new GeomBox(Vector3f(100, 1, 100));
        RigidBody bFloor = world.addStaticBody(Vector3f(0, -1, 0));
        world.addShapeComponent(bFloor, geomFloorBox, Vector3f(0, 0, 0), 1);

        auto geomSphere1 = new GeomSphere(1.0f);
        RigidBody bSphere = world.addDynamicBody(Vector3f(0, 3, 5));
        world.addShapeComponent(bSphere, geomSphere1, Vector3f(0, 0, 0), 1.0f);
        activeBody = bSphere;
        auto sSphere1 = new ShapeSphere(1.0f);
        auto pobj1 = new PhysicsObject();
        pobj1.drawable = sSphere1;
        pobj1.shape = bSphere.shapes[0];
        addDrawable(pobj1);

        buildPyramid(5);
    }

    override void onUpdate(EventManager emngr)
    {
        processInput(emngr);
        world.update(1.0 / 60.0);
    }

    void processInput(EventManager emngr)
    {
        if (camera is null)
            camera = emngr.getGlobal!TrackballCamera("camera");

        float forceMagnitude = 40.0f;
    
        if (emngr.key_pressed[SDLK_PAGEUP])
            activeBody.applyForce(Vector3f(0.0f, forceMagnitude, 0.0f));
        if (emngr.key_pressed[SDLK_PAGEDOWN])
            activeBody.applyForce(Vector3f(0.0f, -forceMagnitude, 0.0f));

        Vector3f right;
        if (camera !is null) 
            right = camera.getRightVector;
        else
            right = Vector3f(1.0f, 0.0f, 0.0f);
        Vector3f forward = cross(Vector3f(0.0f, 1.0f, 0.0f), right);

        if (emngr.key_pressed[SDLK_LEFT])
            activeBody.applyForce(-right * forceMagnitude);
        if (emngr.key_pressed[SDLK_RIGHT])
            activeBody.applyForce( right * forceMagnitude);
            
        if (emngr.key_pressed[SDLK_DOWN])
            activeBody.applyForce(-forward * forceMagnitude);
        if (emngr.key_pressed[SDLK_UP])
            activeBody.applyForce( forward * forceMagnitude);
    }

    void buildPyramid(uint pyramidSize)
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

        enum pyramidGeom = 0;

        auto geomBox = new GeomBox(Vector3f(size, cubeHeight * 0.5f, size));
        auto geomCylinder = new GeomCylinder(2.0f, 1.0f); 
        auto geomSphere = new GeomSphere(size); 
        auto geomCone = new GeomCone(2.0f, 1.0f); 

        foreach(i; 0..pyramidSize)
        foreach(e; i..pyramidSize)
        {
            auto position = Vector3f(
                (e - i * 0.5f) * (width + horizontal_spacing) - ((width + horizontal_spacing) * 5), 
                6.0f + (height + veritcal_spacing * 0.5f) + i * height + 0.26f,
                0.0f);

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

            auto gameObj = new PhysicsObject();
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

