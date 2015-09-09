module physicsentity;

import dlib;
import dgl;
import dmech;

class PhysicsEntity: Entity
{
    ShapeComponent shape;
    RigidBody rbody;
    
    this(Drawable d, RigidBody rb, uint shapeIndex = 0)
    {           
        rbody = rb;
        
        if (rbody.shapes.length > shapeIndex)
        {
            shape = rbody.shapes[shapeIndex];
        }
        
        if (shape)
            super(d, shape.position);
        else
            super(d, Vector3f(0, 0, 0));
    }
    
    override void draw(double dt)
    {
        if (shape !is null)
            transformation = shape.transformation;
        else
            transformation = Matrix4x4f.identity;
        super.draw(dt);
    }
    
    override void drawModel(double dt)
    {
        super.drawModel(dt);
    }
    
    override void free()
    {
        Delete(this);
    }
}