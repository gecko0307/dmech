module dmech.integrator;

import dlib.math.vector;
import dlib.math.quaternion;
import dmech.rigidbody;

class Integrate
{
    static void classicEuler(RigidBody b, double delta)
    {
        if (b.type == BodyType.Dynamic)
        with (b)
        {
            Vector3f acceleration;

            acceleration = forceAccumulator * invMass;
            linearVelocity += acceleration * delta;

            acceleration = torqueAccumulator * invInertiaMoment;
            angularVelocity += acceleration * delta;
            
            linearVelocity *= dampingFactor;
            angularVelocity *= dampingFactor;
            //linearVelocity *= pow(dampingFactor, delta);
            //angularVelocity *= pow(dampingFactor, delta);
            
            position += linearVelocity * delta;
            
            orientation += 0.5f * Quaternionf(angularVelocity, 0.0f) * orientation * delta;
            orientation.normalize();
        }
    }

    static void improvedEuler(RigidBody b, double delta)
    {
        if (b.type == BodyType.Dynamic)
        with (b)
        {
            double halfDelta2 = 0.5 * delta * delta;

            Vector3f acceleration;

            acceleration = forceAccumulator * invMass;
            position += linearVelocity * delta;
            position += acceleration * halfDelta2;
            linearVelocity += acceleration * delta;

            acceleration = torqueAccumulator * invInertiaMoment;
            orientation += 0.5f * Quaternionf(angularVelocity, 0.0f) * orientation * delta;
            orientation.normalize();
            orientation += 0.5f * Quaternionf(acceleration, 0.0f) * orientation * halfDelta2;
            orientation.normalize();
            angularVelocity += acceleration * delta;

            linearVelocity *= dampingFactor;
            angularVelocity *= dampingFactor;
        }
    }
}

