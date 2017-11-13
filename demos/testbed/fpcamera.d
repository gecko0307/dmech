module testbed.fpcamera;

import derelict.opengl.gl;

import dlib.core.memory;
import dlib.math.vector;
import dlib.math.matrix;
import dlib.math.affine;
import dlib.math.utils;

import dgl.core.interfaces;

class FirstPersonCamera: Modifier
{
    Matrix4x4f transformation;
    Matrix4x4f characterMatrix;
    Matrix4x4f worldTransInv;
    Vector3f position;
    float turn = 0.0f;
    float pitch = 0.0f;
    float roll = 0.0f;
    
    this(Vector3f position)
    {
        this.position = position;
    }
    
    Matrix4x4f worldTrans(double dt)
    {  
        Matrix4x4f m = translationMatrix(position + Vector3f(0, 1, 0));
        m *= rotationMatrix(Axis.y, degtorad(turn));
        characterMatrix = m;
        m *= rotationMatrix(Axis.x, degtorad(pitch));
        m *= rotationMatrix(Axis.z, degtorad(roll));
        return m;
    }
    
    override void bind(double dt)
    {
        transformation = worldTrans(dt);       
        worldTransInv = transformation.inverse;
        glPushMatrix();
        glMultMatrixf(worldTransInv.arrayof.ptr);
    }
    
    override void unbind()
    {
        glPopMatrix();
    }

    void free()
    {
        Delete(this);
    }
}

