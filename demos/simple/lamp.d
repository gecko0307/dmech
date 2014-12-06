module lamp;

import derelict.opengl.gl;
import dlib.math.vector;
import dgl.core.drawable;

class Lamp: Drawable
{
    Vector4f position;

    this(Vector4f position)
    {
        glEnable(GL_LIGHTING);
        glEnable(GL_LIGHT0);
        this.position = position;
        glLightfv(GL_LIGHT0, GL_POSITION, position.arrayof.ptr);
    }

    override void draw(double dt)
    {
        glLightfv(GL_LIGHT0, GL_POSITION, position.arrayof.ptr);
    }

    override void free() { }
}
