/*
Copyright (c) 2013-2017 Timur Gafarov 

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

module dmech.contact;

import dlib.math.vector;

import dmech.rigidbody;
import dmech.shape;

struct Contact
{
    RigidBody body1;
    RigidBody body2;
    
    ShapeComponent shape1;
    ShapeComponent shape2;
    
    Vector3f shape1pos;
    Vector3f shape2pos;
    
    bool fact;

    Vector3f point;
    Vector3f shape1RelPoint;
    Vector3f shape2RelPoint;
    
    Vector3f body1RelPoint;
    Vector3f body2RelPoint;

    Vector3f normal;
    float penetration;

    Vector3f fdir1;
    Vector3f fdir2;

    Vector3f n1;
    Vector3f w1;
    Vector3f n2;
    Vector3f w2;

    float initialVelocityProjection;
    float effectiveMass;

    float accumulatedImpulse = 0.0f;
    float accumulatedfImpulse1 = 0.0f;
    float accumulatedfImpulse2 = 0.0f;

    void calcFDir()
    {
        // Calculate tangent space for contact normal
        if (dot(normal, Vector3f(1,0,0)) < 0.5f)
            fdir1 = cross(normal, Vector3f(1,0,0)); 
        else
            fdir1 = cross(normal, Vector3f(0,0,1));
         
        //fdir1 = cross(randomUnitVector3!float, normal);
        fdir2 = cross(fdir1, normal);
        fdir1.normalize();
        fdir2.normalize();
    }
}

