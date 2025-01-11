module scene;

import dagon;
import dmech;

class MyScene: Scene
{
    Game game;
    PhysicsWorld world;
    GeomBox gFloor;
    GeomBox gBox;
    
    ShapeBox sBox;
    Material mBox;

    this(Game game)
    {
        super(game);
        this.game = game;
    }

    override void beforeLoad()
    {
        // Create assets
        // aModel = addOBJAsset("data/model.obj");
        // aTexture = addTextureAsset("data/texture.png");
    }
    
    override void onLoad(Time t, float progress)
    {
    }

    override void afterLoad()
    {
        world = New!PhysicsWorld(null, 1000);
        
        gFloor = New!GeomBox(world, Vector3f(40, 1, 40));
        auto bFloor = world.addStaticBody(Vector3f(0, -1, 0));
        world.addShapeComponent(bFloor, gFloor, Vector3f(0, 0, 0), 1.0f);
        
        gBox = New!GeomBox(world, Vector3f(1, 1, 1)); // Physical shape
        sBox = New!ShapeBox(Vector3f(1, 1, 1), assetManager); // Graphical shape
        
        mBox = addMaterial();
        mBox.baseColorFactor = Color4f(1.0, 0.2, 0.2, 1.0);
        
        foreach(i; 0..10)
            addBoxEntity(Vector3f(-10 + i, 2 + i * 2.1, 0));
        
        auto camera = addCamera();
        auto freeview = New!FreeviewComponent(eventManager, camera);
        freeview.zoom(10);
        freeview.pitch(-30.0f);
        freeview.turn(10.0f);
        game.renderer.activeCamera = camera;

        auto sun = addLight(LightType.Sun);
        sun.shadowEnabled = true;
        sun.energy = 10.0f;
        sun.pitch(-45.0f);
        
        auto ePlane = addEntity();
        ePlane.drawable = New!ShapePlane(40, 40, 1, assetManager);
        
        game.deferredRenderer.ssaoEnabled = true;
        game.deferredRenderer.ssaoPower = 6.0;
        game.postProcessingRenderer.fxaaEnabled = true;
    }
    
    DMechBodyComponent addBoxEntity(Vector3f pos)
    {
        auto bBox = world.addDynamicBody(pos);
        auto scBox = world.addShapeComponent(bBox, gBox, Vector3f(0, 0, 0), 50.0f);
        bBox.addShapeComponent(scBox);
        Entity eBox = addEntity();
        eBox.position = pos;
        eBox.drawable = sBox;
        eBox.material = mBox;
        return New!DMechBodyComponent(eventManager, eBox, bBox);
    }
    
    override void onUpdate(Time t)
    {
        world.update(t.delta);
    }
    
    override void onKeyDown(int key) { }
    override void onKeyUp(int key) { }
    override void onMouseButtonDown(int button) { }
    override void onMouseButtonUp(int button) { }
}

class DMechBodyComponent: EntityComponent
{
    RigidBody rigidBody;
    Matrix4x4f prevTransformation;

    this(EventManager em, Entity e, RigidBody b)
    {
        super(em, e);
        rigidBody = b;
        
        rigidBody.position = e.position;
        rigidBody.orientation = e.rotation;
        
        prevTransformation = Matrix4x4f.identity;
    }

    override void update(Time t)
    {
        //rigidBody.update(t.delta);

        entity.prevTransformation = prevTransformation;

        entity.position = rigidBody.position.xyz;
        entity.transformation = rigidBody.transformation * scaleMatrix(entity.scaling);
        entity.invTransformation = entity.transformation.inverse;
        entity.rotation = rigidBody.orientation;

        entity.absoluteTransformation = entity.transformation;
        entity.invAbsoluteTransformation = entity.invTransformation;
        entity.prevAbsoluteTransformation = entity.prevTransformation;

        prevTransformation = entity.transformation;
    }
}
