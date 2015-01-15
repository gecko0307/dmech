module main;

import std.stdio;
import std.conv;
import std.string;

import derelict.sdl.sdl;
import derelict.opengl.gl;
import derelict.opengl.glu;
import derelict.freetype.ft;

import dlib.math.vector;
import dlib.image.color;

import dgl.core.application;
import dgl.core.layer;
import dgl.core.drawable;
import dgl.graphics.shapes;
import dgl.scene.tbcamera;
import dgl.templates.freeview;
import dgl.ui.ftfont;
import dgl.ui.textline;
//import dgl.ui.i18n;

import lamp;
import physobject;
import physlayer;

class PhysicsTestApp: Application
{
    alias eventManager this;
    FreeTypeFont font;
    TextLine fpsText;

    FreeviewLayer layer3d;
    PhysicsLayer layerPhysics;
    Layer layer2d;

    this()
    {
        super(640, 480, "DGL Test App");

        clearColor = Color4f(0.5f, 0.5f, 0.5f);

        layer3d = new FreeviewLayer(videoWidth, videoHeight, 1);
        addLayer(layer3d);
        eventManager.setGlobal("camera", layer3d.camera);

        Lamp lamp = new Lamp(Vector4f(10.0f, 20.0f, 5.0f, 1.0f));
        layer3d.addDrawable(lamp);

        layerPhysics = new PhysicsLayer(videoWidth, videoHeight, 0);
        layerPhysics.addModifier(layer3d.camera);
        addLayer(layerPhysics);

        layer2d = addLayer2D(-1);

        font = new FreeTypeFont("data/fonts/droid/DroidSans.ttf", 27);

        fpsText = new TextLine(font, format("FPS: %s", fps), Vector2f(10, 10));
        fpsText.alignment = Alignment.Left;
        fpsText.color = Color4f(1, 1, 1);
        layer2d.addDrawable(fpsText);
    }

    override void onQuit()
    {
        super.onQuit();
    }
    
    override void onKeyDown()
    {
        super.onKeyDown();
    }
    
    override void onMouseButtonDown()
    {
        super.onMouseButtonDown();
    }
    
    override void onUpdate()
    {
        super.onUpdate();
        fpsText.setText(format("FPS: %s", fps));
    }
}

void loadLibraries()
{
    version(Windows)
    {
        enum sharedLibSDL = "SDL.dll";
        enum sharedLibFT = "freetype.dll";
    }
    version(linux)
    {
        enum sharedLibSDL = "./libsdl.so";
        enum sharedLibFT = "./libfreetype.so";
    }

    DerelictGL.load();
    DerelictGLU.load();
    DerelictSDL.load(sharedLibSDL);
    DerelictFT.load(sharedLibFT);
}

void main()
{
    loadLibraries();
    auto app = new PhysicsTestApp();
    app.run();
}

