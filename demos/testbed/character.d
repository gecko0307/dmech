module testbed.character;

import std.math;

import dlib.core.memory;
import dlib.math.vector;
import dlib.math.matrix;
import dlib.math.transformation;
import dlib.math.utils;

import dmech.world;
import dmech.rigidbody;
import dmech.geometry;
import dmech.shape;
import dmech.contact;
import dmech.raycast;

/*
 * CharacterController implements kinematic body
 * on top of dmech dynamics: it allows direct
 * velocity changes for a RigidBody.
 * CharacterController is intended for
 * generic action game character movement.
 */
class CharacterController
{
    PhysicsWorld world;
    RigidBody rbody;
    bool onGround = false;
    Vector3f direction = Vector3f(0, 0, 1);
    float speed = 0.0f;
    float jumpSpeed = 0.0f;
    float artificalGravity = 50.0f;
    float boundingSphereRadius;
    RigidBody floorBody;

    this(PhysicsWorld world, Vector3f pos, float mass, Geometry geom)
    {
        this.world = world;
        rbody = world.addDynamicBody(pos);
        rbody.bounce = 0.0f;
        rbody.friction = 1.0f;
        rbody.enableRotation = false;
        rbody.useOwnGravity = true;
        rbody.gravity = Vector3f(0.0f, -artificalGravity, 0.0f);
        rbody.raycastable = false;
        world.addShapeComponent(rbody, geom, Vector3f(0, 0, 0), mass);
        boundingSphereRadius = 1.0f;
    }

    void update(bool clampY = true)
    {       
        Vector3f targetVelocity = direction * speed;
        Vector3f velocityChange = targetVelocity - rbody.linearVelocity;
        velocityChange.y = jumpSpeed;
        rbody.linearVelocity += velocityChange;

        onGround = checkOnGround();

        if (onGround && floorBody && speed == 0.0f && jumpSpeed == 0.0f)
            rbody.linearVelocity = floorBody.linearVelocity;
            
        speed = 0.0f;
        jumpSpeed = 0.0f;
    }
    
    bool checkOnGround()
    {
        floorBody = null;
        CastResult cr;
        bool hit = world.raycast(rbody.position, Vector3f(0, -1, 0), 10, cr, true, true);
        if (hit)
        {
            if (distance(cr.point, rbody.position) <= boundingSphereRadius)
            {
                floorBody = cr.rbody;
                return true;
            }
        }
        return false;
    }

    void move(Vector3f direction, float spd)
    {
        this.direction = direction;
        this.speed = spd;
    }

    void jump(float height)
    {
        if (onGround)
        {
            //rbody.linearVelocity.y = jumpSpeed(height);
            jumpSpeed = calcJumpSpeed(height);
            onGround = false;
        }
    }
    
    float calcJumpSpeed(float jumpHeight)
    {
        return sqrt(2.0f * jumpHeight * artificalGravity);
    }

    void free()
    {
        Delete(this);
    }
}
