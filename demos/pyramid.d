module pyramid;

import std.stdio;
import std.format;
import std.math;

import dlib.core.memory;
import dlib.container.array;
import dlib.math.vector;
import dlib.math.utils;
import dlib.image.color;
import dlib.geometry.ray;
import dlib.geometry.aabb;

import derelict.opengl.gl;
import derelict.opengl.glu;
import derelict.sdl.sdl;

import dgl.core.application;
import dgl.core.interfaces;
import dgl.core.event;
import dgl.graphics.shapes;
import dgl.graphics.material;
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
    DynamicArray!Material materials;
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
    
    DynamicArray!PhysicsEntity entities;
    PhysicsEntity selectedEntity;
    
    float aspectRatio;
    float fovY = 60;
    float maxPickDistance = 1000.0f;
    float dragDistance;
    
    this()
    {
        super(800, 600, "dmech test");
        clearColor = Color4f(0.2f, 0.2f, 0.2f);
        
        camera = New!TrackballCamera();
        camera.pitch(45.0f);
        camera.turn(45.0f);
        camera.setZoom(20.0f);
        
        lightPosition = Vector4f(1, 1, 0.5, 0);

        axes = New!Axes();
        grid = New!Grid();
        
        world = New!PhysicsWorld(null, 1000);
        
        gFloor = New!GeomBox(world, Vector3f(40, 1, 40));
        auto bFloor = world.addStaticBody(Vector3f(0, -1, 0));
        world.addShapeComponent(bFloor, gFloor, Vector3f(0, 0, 0), 1.0f);
        
        gBox = New!GeomBox(world, Vector3f(1, 1, 1)); // Physical shape
        sBox = New!ShapeBox(Vector3f(1, 1, 1)); // Graphical shape
        
        buildPyramid(7);
            
        font = New!FreeTypeFont("data/fonts/droid/DroidSans.ttf", 18);
        
        fpsText = New!TextLine(font, "FPS: 0", Vector2f(8, 8));
        fpsText.color = Color4f(1, 1, 1);
    }
    
    void buildPyramid(uint pyramidSize)
    {
        float size = 1.0f;

        float cubeHeight = 2.0f;

        float width = size * 2.0f;
        float height = cubeHeight;
        float horizontal_spacing = 0.1f;
        float veritcal_spacing = 0.1f;

        foreach(i; 0..pyramidSize)
        foreach(e; i..pyramidSize)
        {
            auto position = Vector3f(
                (e - i * 0.5f) * (width + horizontal_spacing) - ((width + horizontal_spacing) * 5), 
                6.0f + (height + veritcal_spacing * 0.5f) + i * height + 0.26f,
                0.0f);

            PhysicsEntity entity = addBoxEntity(position);
            Material mat = New!Material();
            auto col = Color4f((randomUnitVector3!float + 0.5f).normalized);
            mat.ambientColor = col;
            mat.diffuseColor = col;
            entity.material = mat;
            materials.append(mat);
        }
    }
    
    PhysicsEntity addBoxEntity(Vector3f pos)
    {
        auto bBox = world.addDynamicBody(pos, 0.0f);
        auto scBox = world.addShapeComponent(bBox, gBox, Vector3f(0, 0, 0), 1.0f);
        PhysicsEntity peBox = New!PhysicsEntity(sBox, bBox);
        addDrawable(peBox);
        entities.append(peBox);
        return peBox;
    }
    
    void addDrawable(Drawable d)
    {
        drawables.append(d);
    }
    
    ~this()
    {
        camera.free();
        foreach(m; materials.data)
            m.free();
        materials.free();
        foreach(d; drawables.data)
            d.free();
        drawables.free();
        entities.free();
        axes.free();
        grid.free();
        sBox.free();

        Delete(world);
        
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
        if (button == SDL_BUTTON_LEFT)
        {
            Ray mray = mouseRay();
            selectedEntity = pickEntity(mray);
            if (selectedEntity)
                dragDistance = distance(selectedEntity.rbody.position, camera.getPosition);
        }
        else if (button == SDL_BUTTON_MIDDLE)
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
    
    PhysicsEntity pickEntity(Ray r)
    {
        PhysicsEntity res = null;

        float min_t = float.max;
        foreach(e; entities.data)
        {
            AABB aabb = e.getAABB();
            float t;
            if (aabb.intersectsSegment(r.p0, r.p1, t))
            {
                if (t < min_t)
                {
                    min_t = t;
                    res = e;
                }
            }
        }
        
        return res;
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
        
        if (eventManager.mouseButtonPressed[SDL_BUTTON_LEFT] && selectedEntity)
        {
            Vector3f dragPosition = cameraMousePoint(dragDistance);
            selectedEntity.rbody.position = dragPosition;
        }
        
        fpsText.setText(format("FPS: %s", eventManager.fps));
    }
    
    override void onRedraw()
    {       
        double dt = eventManager.deltaTime;
        
        aspectRatio = cast(float)eventManager.windowWidth / cast(float)eventManager.windowHeight;
        
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        gluPerspective(fovY, aspectRatio, 0.1, 1000.0);
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
        if (selectedEntity)
        {
            selectedEntity.useMaterial = false;
            drawWireframe(selectedEntity, dt);
            selectedEntity.useMaterial = true;
        }
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
    
    void drawWireframe(Drawable drw, double dt)
    {
        glDisable(GL_DEPTH_TEST);
        glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
        glDisable(GL_LIGHTING);
        glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
        drw.draw(dt);
        glEnable(GL_LIGHTING);
        glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
        glEnable(GL_DEPTH_TEST);
    }
    
    Vector3f cameraPoint(float x, float y, float dist)
    {        
        return camera.getPosition() + cameraDir(x, y) * dist;
    }
        
    Vector3f cameraMousePoint(float dist)
    {
        return cameraPoint(eventManager.mouseX, eventManager.windowHeight - eventManager.mouseY, dist);
    }
    
    Vector3f cameraDir(float x, float y)
    {
        Vector3f camDir = -camera.getDirectionVector();

        float fovX = fovXfromY(fovY, aspectRatio);

        float tfov1 = tan(fovY*PI/360.0f);
        float tfov2 = tan(fovX*PI/360.0f);
        
        Vector3f camUp = camera.getUpVector() * tfov1;
        Vector3f camRight = -camera.getRightVector() * tfov2;

        float width  = 1.0f - 2.0f * x / eventManager.windowWidth;
        float height = 1.0f - 2.0f * y / eventManager.windowHeight;
        
        Vector3f m = camDir + camUp * height + camRight * width;
        Vector3f dir = m.normalized;
        
        return dir;
    }
    
    Ray cameraRay(float x, float y)
    {
        Vector3f camPos = camera.getPosition();
        Ray r = Ray(camPos, camPos + cameraDir(x, y) * maxPickDistance);
        return r;
    }
    
    Vector3f mouseDir()
    {
        return cameraDir(eventManager.mouseX, eventManager.windowHeight - eventManager.mouseY);
    }
    
    Ray mouseRay()
    {
        return cameraRay(eventManager.mouseX, eventManager.windowHeight - eventManager.mouseY);
    }
    
    Ray mouseRay(float x, float y)
    {
        return cameraRay(x, eventManager.windowHeight - y);
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
