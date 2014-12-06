module physobject;

import derelict.opengl.gl;

import dgl.core.drawable;
import dgl.graphics.material;

import dmech.shape;

class PhysicsObject: Drawable
{   
    ShapeComponent shape;
    Drawable drawable;
    Material material;

    this()
    {
    }
    
    void draw(double delta)
    {
        if (material !is null)
            material.bind(delta);

        glPushMatrix();
        if (shape !is null)
            glMultMatrixf(shape.transformation.arrayof.ptr);
        if (drawable !is null)
            drawable.draw(delta);
        glPopMatrix();

        if (material !is null)
            material.unbind();
    }
    
    void free() {}
}
