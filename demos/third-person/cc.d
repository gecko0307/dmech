module cc;

import std.math;

import dlib.math.vector;
import dlib.math.matrix;
import dlib.math.affine;
import dlib.math.utils;

import dmech.world;
import dmech.rigidbody;
import dmech.geometry;
import dmech.raycast;
import dmech.contact;

/*
 * CharacterController implements kinematic body on top of dmech dynamics: 
 * it allows direct velocity changes for a RigidBody.
 * CharacterController is intended for generic action game character movement.
 */
class CharacterController
{
    PhysicsWorld world;
    RigidBody rbody;
    bool onGround = false;
    Vector3f direction = Vector3f(0, 0, 1);
    float speed = 0.0f;
    float maxVelocityChange = 0.75f;
    float artificalGravity = 50.0f;
    Matrix4x4f localMatrix;
    Vector3f rotation;

    this(PhysicsWorld world, Vector3f pos, float mass, Geometry geom = null)
    {
        this.world = world;
        rbody = world.addDynamicBody(pos);
        rbody.bounce = 0.0f;
        rbody.enableRotation = false;
        rbody.useOwnGravity = true;
        rbody.gravity = Vector3f(0.0f, -artificalGravity, 0.0f);
        rbody.raycastable = false;
        if (geom is null)
            geom = new GeomSphere(1.0f);
        world.addShapeComponent(rbody, geom, Vector3f(0, 0, 0), mass);
        localMatrix = Matrix4x4f.identity;
        rotation = Vector3f(0, 0, 0);

        rbody.onNewContact ~= (RigidBody b, Contact c)
        {
            if (dot((c.point - b.position).normalized, rbody.gravity.normalized) > 0.5f)
            {
                onGround = true;
            }
        };
    }
    
    void updateMatrix()
    {
        localMatrix = Matrix4x4f.identity;
        localMatrix *= rotationMatrix(Axis.x, degtorad(rotation.x));
        localMatrix *= rotationMatrix(Axis.y, degtorad(rotation.y));
        localMatrix *= rotationMatrix(Axis.z, degtorad(rotation.z));

        direction = localMatrix.forward;
    }

    void update(bool clampY = true)
    {
        Vector3f targetVelocity = direction * speed;

        Vector3f velocityChange = targetVelocity - rbody.linearVelocity;
        velocityChange.x = clamp(velocityChange.x, -maxVelocityChange, maxVelocityChange);
        velocityChange.z = clamp(velocityChange.z, -maxVelocityChange, maxVelocityChange);
        if (clampY)
            velocityChange.y = 0;
        else
            velocityChange.y = clamp(velocityChange.y, -maxVelocityChange, maxVelocityChange);
        rbody.linearVelocity += velocityChange;

        speed = 0.0f;
    }

    bool checkOnGround()
    {
        CastResult cr;
        bool hit = world.raycast(rbody.position, Vector3f(0, -1, 0), 10, cr, true, true);
        if (hit)
        {
            if (distance(cr.point, rbody.position) <= 1.1f)
                return true;
        }
        return false;
    }

    void turn(float angle)
    {
        rotation.y += angle;
    }

    void move(float spd)
    {
        speed = spd;
    }

    void jump(float height)
    {
        if (onGround || checkOnGround)
        {
            rbody.linearVelocity.y = jumpSpeed(height);
            onGround = false;
        }
    }

    float jumpSpeed(float jumpHeight)
    {
        return sqrt(2.0f * jumpHeight * artificalGravity);
    }
}
