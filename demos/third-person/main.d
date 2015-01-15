module main;

import std.string;

import derelict.sdl.sdl;
import derelict.opengl.gl;
import derelict.opengl.glu;
import derelict.freetype.ft;

import dlib.math.vector;
import dlib.image.color;

import dgl.core.application;
import dgl.core.layer;
import dgl.ui.ftfont;
import dgl.ui.textline;
import dgl.templates.freeview;

import gamelayer;

class GameApp: Application
{
    alias eventManager this;
    FreeTypeFont font;
    TextLine fpsText;

    FreeviewLayer layer3d;
    Layer layer2d;

    this()
    {
        super(640, 480, "Third Person Game Demo");
        clearColor = Color4f(0.5f, 0.5f, 0.5f);

        layer3d = new FreeviewLayer(videoWidth, videoHeight, 1);
        layer3d.alignToWindow = true;
        addLayer(layer3d);
        //eventManager.setGlobal("camera", layer3d.camera);

        GameLayer gameLayer = new GameLayer(videoWidth, videoHeight, 0, eventManager);
        addLayer(gameLayer);

        layer2d = addLayer2D(-1);
        layer2d.alignToWindow = true;

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
    auto app = new GameApp();
    app.run();
}
