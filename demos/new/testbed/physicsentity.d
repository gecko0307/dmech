module testbed.physicsentity;

import dlib.core.memory;
import dlib.math.vector;
import dlib.math.matrix;
import dgl.core.interfaces;
import dgl.graphics.entity;
import dgl.graphics.material;
import dmech.rigidbody;
import dmech.shape;

class PhysicsEntity: Entity
{
    ShapeComponent shape;
    RigidBody rbody;
    Material material;
    bool useMaterial = true;
    
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
        if (material && useMaterial)
            material.bind(dt);
        super.drawModel(dt);
        if (material && useMaterial)
            material.unbind();
    }
    
    override void free()
    {
        Delete(this);
    }
}