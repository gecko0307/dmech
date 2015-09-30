module simple;

import std.stdio;
import std.format;

import dlib.core.memory;
import dlib.container.array;
import dlib.math.vector;
import dlib.image.color;

import derelict.opengl.gl;
import derelict.opengl.glu;
import derelict.sdl.sdl;

import dgl.core.application;
import dgl.core.interfaces;
import dgl.core.event;
import dgl.graphics.shapes;
import dgl.graphics.tbcamera;
import dgl.graphics.axes;
import dgl.ui.font;
import dgl.ui.ftfont;
import dgl.ui.textline;

import dmech.world;
import dmech.geometry;
import dmech.rigidbody;
import dmech.shape;

import testbed.grid;
import testbed.physicsentity;

class TestApp: Application
{
    TrackballCamera camera;
    DynamicArray!Drawable drawables;
    Vector4f lightPosition;
    
    Axes axes;
    Grid grid;
    ShapeBox sBox;
    
    PhysicsWorld world;
    GeomBox gFloor;
    GeomBox gBox;
    
    enum fixedTimeStep = 1.0 / 60.0;
    
    Font font;
    TextLine fpsText;
    
    this()
    {
        super(800, 600, "dmech test");
        clearColor = Color4f(0.5f, 0.5f, 0.5f);
        
        camera = New!TrackballCamera();
        camera.pitch(45.0f);
        camera.turn(45.0f);
        camera.setZoom(20.0f);
        
        lightPosition = Vector4f(1, 1, 0.5, 0);

        axes = New!Axes();
        grid = New!Grid();
        
        world = New!PhysicsWorld(1000);
        
        gFloor = New!GeomBox(Vector3f(40, 1, 40));
        auto bFloor = world.addStaticBody(Vector3f(0, -1, 0));
        world.addShapeComponent(bFloor, gFloor, Vector3f(0, 0, 0), 1.0f);
        
        gBox = New!GeomBox(Vector3f(1, 1, 1)); // Physical shape
        sBox = New!ShapeBox(Vector3f(1, 1, 1)); // Graphical shape
        
        foreach(i; 0..10)
            addBoxEntity(Vector3f(-10 + i, 2 + i * 2.1, 0));
            
        font = New!FreeTypeFont("data/fonts/droid/DroidSans.ttf", 18);
        
        fpsText = New!TextLine(font, "FPS: 0", Vector2f(8, 8));
        fpsText.color = Color4f(1, 1, 1);
    }
    
    PhysicsEntity addBoxEntity(Vector3f pos)
    {
        auto bBox = world.addDynamicBody(pos, 0.0f);
        auto scBox = world.addShapeComponent(bBox, gBox, Vector3f(0, 0, 0), 1.0f);
        PhysicsEntity peBox = New!PhysicsEntity(sBox, bBox);
        addDrawable(peBox);
        return peBox;
    }
    
    void addDrawable(Drawable d)
    {
        drawables.append(d);
    }
    
    ~this()
    {
        camera.free();
        foreach(d; drawables.data)
            d.free();
        drawables.free();
        axes.free();
        grid.free();
        world.free();
        sBox.free();
        
        gFloor.free();
        gBox.free();
        
        font.free();
        fpsText.free();
    }
    
    override void onKeyDown(int key)
    {
        super.onKeyDown(key);
    }
    
    int prevMouseX;
    int prevMouseY;
    
    override void onMouseButtonDown(int button)
    {
        if (button == SDL_BUTTON_MIDDLE)
        {
            prevMouseX = eventManager.mouseX;
            prevMouseY = eventManager.mouseY;
        }
        else if (button == SDL_BUTTON_WHEELUP)
        {
            camera.zoom(1.0f);
        }
        else if (button == SDL_BUTTON_WHEELDOWN)
        {
            camera.zoom(-1.0f);
        }
    }
    
    override void free()
    {
        Delete(this);
    }
    
    double time = 0.0;
    
    override void onUpdate()
    {
        double dt = eventManager.deltaTime;
        
        time += dt;
        if (time >= fixedTimeStep)
        {
            time -= fixedTimeStep;
            world.update(fixedTimeStep);
        }
    
        updateCamera();
        
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
        glDisable(GL_DEPTH_TEST);
        axes.draw(dt);
        glEnable(GL_DEPTH_TEST);
        
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
    }
    
    void updateCamera()
    {
        if (eventManager.mouseButtonPressed[SDL_BUTTON_MIDDLE] && eventManager.keyPressed[SDLK_LSHIFT])
        {
            float shift_x = (eventManager.mouseX - prevMouseX) * 0.1f;
            float shift_y = (eventManager.mouseY - prevMouseY) * 0.1f;
            Vector3f trans = camera.getUpVector * shift_y + camera.getRightVector * shift_x;
            camera.translateTarget(trans);
        }
        else if (eventManager.mouseButtonPressed[SDL_BUTTON_MIDDLE] && eventManager.keyPressed[SDLK_LCTRL])
        {
            float shift_x = (eventManager.mouseX - prevMouseX);
            float shift_y = (eventManager.mouseY - prevMouseY);
            camera.zoom((shift_x + shift_y) * 0.1f);
        }
        else if (eventManager.mouseButtonPressed[SDL_BUTTON_MIDDLE])
        {                
            float turn_m = (eventManager.mouseX - prevMouseX);
            float pitch_m = -(eventManager.mouseY - prevMouseY);
            camera.pitch(pitch_m);
            camera.turn(turn_m);
        }

        prevMouseX = eventManager.mouseX;
        prevMouseY = eventManager.mouseY;
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