module tpcamera;

import derelict.opengl.gl;
import dlib.math.vector;
import dlib.math.matrix;
import dlib.math.affine;
import dgl.core.modifier;

class ThirdPersonCamera: Modifier
{
    Matrix4x4f localMatrix;
    Vector3f position;
    Vector3f playerPosition;
    Vector3f playerDirection;
    
    this()
    {
        position = Vector3f(0.0f, 0.0f, 0.0f);
        playerPosition = Vector3f(0.0f, 0.0f, 1.0f);
        playerDirection = Vector3f(0.0f, 0.0f, 1.0f);
        localMatrix = Matrix4x4f.identity;
    }

    void collisionResponce(Vector3f contactNormal, float penetrationDepth)
    {
        position += contactNormal * penetrationDepth; 
    }

    void moveToPoint(Vector3f pt, float speed)
    {
        Vector3f dir = pt - position;
        dir.normalize();

        float dist = distance(position, pt);
        if (dist != 0.0f)
        {
            if (dist >= speed)
            {
                position += dir * speed;
            }
            else
            {
                position += dir * dist;
            }
        }
    }

    override void bind(double dt)
    {
        Vector3f cameraTargetPosition = playerPosition + (-playerDirection * 5.0f);
        cameraTargetPosition.y += 2.0f;
        if (position != cameraTargetPosition)
            position += ((cameraTargetPosition - position) * 5.0f) * dt;

        localMatrix = lookAtMatrix(
            position, 
            playerPosition, 
            Vector3f(0.0f, 1.0f, 0.0f));

        glPushMatrix();
        glMultMatrixf(localMatrix.arrayof.ptr);
    }

    override void unbind()
    {
        glPopMatrix();
    }

    override void free() {}
}
