module game;

import std.stdio;
import std.format;

import dlib.core.memory;
import dlib.container.array;
import dlib.math.vector;
import dlib.math.matrix;
import dlib.math.affine;
import dlib.image.color;

import derelict.opengl.gl;
import derelict.opengl.glu;
import derelict.sdl.sdl;
import dgl.core.application;
import dgl.core.interfaces;
import dgl.core.event;
import dgl.graphics.shapes;
import dgl.graphics.material;
import dgl.ui.font;
import dgl.ui.ftfont;
import dgl.ui.textline;

import dmech.world;
import dmech.geometry;
import dmech.rigidbody;
import dmech.shape;

import testbed.grid;
import testbed.physicsentity;
import testbed.fpcamera;
import testbed.character;

class TestApp: Application
{
    FirstPersonCamera camera;
    CharacterController charController;
    
    DynamicArray!Drawable drawables;
    Vector4f lightPosition;

    Grid grid;
    ShapeBox sBox;
    
    Material boxMaterial;
    
    PhysicsWorld world;
    GeomBox gFloor;
    GeomBox gBox;
    GeomSphere gSphere;
    
    RigidBody bFloor;
    
    enum fixedTimeStep = 1.0 / 60.0;
    
    Font font;
    TextLine fpsText;
    TextLine ctrlText;
    
    bool mouseControl = true;
    
    this()
    {
        super(800, 600, "dmech game demo");
        
        clearColor = Color4f(0.5f, 0.5f, 0.5f);
        lightPosition = Vector4f(5, 10, 2, 1);

        grid = New!Grid();
        
        world = New!PhysicsWorld(null, 1000);
        
        gFloor = New!GeomBox(world, Vector3f(40, 1, 40));
        bFloor = world.addStaticBody(Vector3f(0, -1, 0));
        world.addShapeComponent(bFloor, gFloor, Vector3f(0, 0, 0), 1.0f);
        
        Vector3f boxHalfSize = Vector3f(0.75f, 0.75f, 0.75f);
        gBox = New!GeomBox(world, boxHalfSize); // Physical shape
        sBox = New!ShapeBox(boxHalfSize); // Graphical shape
      
        Vector3f characterPos = Vector3f(0, 5, 5);
        camera = New!FirstPersonCamera(characterPos);
        camera.turn = -90.0f;

        gSphere = New!GeomSphere(world, 1.0f);
        charController = New!CharacterController(world, characterPos, 1.0f, gSphere);
        
        boxMaterial = New!Material();
        boxMaterial.ambientColor = Color4f(0.75f, 0.3f, 0);
        boxMaterial.diffuseColor = Color4f(1, 0.5f, 0);
        
        foreach(i; 0..10)
            addBoxEntity(Vector3f(-10 + i, 2 + i * 2.1, 0), boxMaterial);
            
        font = New!FreeTypeFont("data/fonts/droid/DroidSans.ttf", 12);
        
        fpsText = New!TextLine(font, "FPS: 0", Vector2f(8, 8));
        fpsText.color = Color4f(1, 1, 1);
        
        ctrlText = New!TextLine(font, 
            "Mouse/WASD - move; Space - jump; Enter - release mouse pointer; Esc - exit", 
            Vector2f(8, eventManager.windowHeight - font.height - 8));
        ctrlText.color = Color4f(1, 1, 1);
        
        eventManager.showCursor(false);
    }
    
    ~this()
    {
        camera.free();
        charController.free();
        foreach(d; drawables.data)
            d.free();
        drawables.free();
        grid.free();
        Delete(world);
        sBox.free();
        font.free();
        fpsText.free();
        ctrlText.free();
        boxMaterial.free();
    }
    
    PhysicsEntity addBoxEntity(Vector3f pos, Material m)
    {
        auto bBox = world.addDynamicBody(pos, 0.0f);
        auto scBox = world.addShapeComponent(bBox, gBox, Vector3f(0, 0, 0), 10.0f);
        PhysicsEntity peBox = New!PhysicsEntity(sBox, bBox);
        peBox.material = m;
        addDrawable(peBox);
        return peBox;
    }
    
    void addDrawable(Drawable d)
    {
        drawables.append(d);
    }

    void updateCamera()
    {    
        int hWidth = eventManager.windowWidth / 2;
        int hHeight = eventManager.windowHeight / 2;
        float turn_m = -(hWidth - eventManager.mouseX) * 0.1f;
        float pitch_m = (hHeight - eventManager.mouseY) * 0.1f;
        camera.pitch += pitch_m;
        camera.turn += turn_m;       
        float pitchLimitMax = 60.0f;
        float pitchLimitMin = -60.0f;
        if (camera.pitch > pitchLimitMax)
            camera.pitch = pitchLimitMax;
        else if (camera.pitch < pitchLimitMin)
            camera.pitch = pitchLimitMin;
        
        eventManager.setMouseToCenter();
    }
    
    void updateCharacter()
    {        
        Vector3f forward = camera.characterMatrix.forward;
        Vector3f right = camera.characterMatrix.right;
        
        if (eventManager.keyPressed['w']) charController.move(forward, -12.0f);
        if (eventManager.keyPressed['s']) charController.move(forward, 12.0f);
        if (eventManager.keyPressed['a']) charController.move(right, -12.0f);
        if (eventManager.keyPressed['d']) charController.move(right, 12.0f);
        if (eventManager.keyPressed[SDLK_SPACE]) charController.jump(1.0f);
        
        charController.update();
    }
    
    override void onKeyDown(int key)
    {
        super.onKeyDown(key);
        
        if (key == SDLK_RETURN)
        {
            mouseControl = !mouseControl;
            eventManager.showCursor(!mouseControl);
            eventManager.setMouseToCenter();
        }
    }
    
    override void onMouseButtonDown(int button)
    {
    }
    
    override void free()
    {
        Delete(this);
    }
    
    double time = 0.0;
    
    override void onUpdate()
    {
        double dt = eventManager.deltaTime;
        
        if (mouseControl)
        {
            updateCamera();
        }
        
        time += dt;
        if (time >= fixedTimeStep)
        {
            time -= fixedTimeStep;
            updateCharacter();
            world.update(fixedTimeStep);
        }
    
        camera.position = charController.rbody.position;
        
        fpsText.setText(format("FPS: %s", eventManager.fps));
    }
    
    override void onRedraw()
    {       
        double dt = eventManager.deltaTime;
        
        float aspectRatio = cast(float)eventManager.windowWidth / cast(float)eventManager.windowHeight;
        
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        gluPerspective(60.0f, aspectRatio, 0.1, 1000.0);
        glMatrixMode(GL_MODELVIEW);
        
        glLoadIdentity();
        glPushMatrix();
        camera.bind(dt);
        
        grid.draw(dt);
        
        glEnable(GL_LIGHTING);
        glEnable(GL_LIGHT0);
        glLightfv(GL_LIGHT0, GL_POSITION, lightPosition.arrayof.ptr);
        
        foreach(d; drawables.data)
            d.draw(dt);
            
        glDisable(GL_LIGHTING);
        
        camera.unbind();
        glPopMatrix();
        
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        glOrtho(0, eventManager.windowWidth, 0, eventManager.windowHeight, 0, 1);
        glMatrixMode(GL_MODELVIEW);
        
        fpsText.draw(dt);
        ctrlText.draw(dt);
    }
    
    override void onResize(int width, int height)
    {
        super.onResize(width, height);
        ctrlText.setPosition(8, height - font.height - 8);
    }
}

void main(string[] args)
{
    loadLibraries();
    writefln("Allocated memory at start: %s", allocatedMemory);
    auto app = New!TestApp();
    app.run();
    Delete(app);
    writefln("Allocated memory at end: %s", allocatedMemory);
}
