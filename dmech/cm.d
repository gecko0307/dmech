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

module dmech.cm;

import std.math;

import dlib.math.vector;
import dlib.math.matrix;
import dlib.math.quaternion;
import dlib.math.utils;
import dlib.geometry.plane;
import dlib.geometry.triangle;

import dmech.contact;
import dmech.rigidbody;
import dmech.geometry;
import dmech.shape;
import dmech.mpr;
import dmech.clipping;

// TODO: move projectPointOnPlane and planeBasis to dlib.geometry.plane
/*
Vector3f projectPointOnPlane(Vector3f point, Vector3f planeOrigin, Vector3f planeNormal)
{
    Vector3f v = point - planeOrigin;
    float dist = dot(v, planeNormal);
    Vector3f projectedPoint = point - dist * planeNormal;
    return projectedPoint;
}

// Z direction in this basis is plane normal
Matrix4x4f planeBasis(Vector3f planeOrigin, Vector3f planeNormal)
{
    Matrix4x4f basis = directionToMatrix(planeNormal);
    basis.translation = planeOrigin;
    return basis;
}
*/

Vector2f projectPoint(
    Vector3f point, 
    Vector3f origin, 
    Vector3f right,
    Vector3f up)
{
    Vector2f res;
    res.x = dot(right, point - origin);
    res.y = dot(up, point - origin);
    return res;
}

Vector3f unprojectPoint(
    Vector2f point, 
    Vector3f origin, 
    Vector3f right,
    Vector3f up)
{
    Vector3f res;
    res = origin + up * point.y + right * point.x;
    return res;
}

/*
 * Contact manifold.
 * Stores information about two bodies' collision.
 * Contacts are generated at once using axis rotation method
 * (for incremental solution see pcm.d).
 */
struct ContactManifold
{
    Contact[8] contacts;
    uint numContacts = 0;
    Contact mainContact;
    Feature f1;
    Feature f2;
    Vector2f[8] pts;

    // Find all contact points at once
    void computeContacts(Contact c)
    {
        mainContact = c;

        uint numPts = 0;

        // Calculate tangent space for contact normal
        Vector3f n0, n1;
        if (dot(c.normal, Vector3f(1,0,0)) < 0.5f)
            n0 = cross(c.normal, Vector3f(1,0,0)); 
        else
            n0 = cross(c.normal, Vector3f(0,0,1));
        n1 = cross(n0, c.normal);
        n0.normalize();
        n1.normalize();

        // If colliding with a sphere, there's only one contact
        if (c.shape1.geometry.type == GeomType.Sphere ||
            c.shape2.geometry.type == GeomType.Sphere)
        {
            contacts[0] = c;
            contacts[0].fdir1 = n0;
            contacts[0].fdir2 = n1;
            numContacts = 1;
            return;
        }

        if (c.shape1.geometry.type == GeomType.Ellipsoid ||
            c.shape2.geometry.type == GeomType.Ellipsoid)
        {
            contacts[0] = c;
            contacts[0].fdir1 = n0;
            contacts[0].fdir2 = n1;
            numContacts = 1;
            return;
        }
        
        Vector3f right = n0;
        Vector3f up = n1;
        
        // Calculate basis for contact plane
        Plane contactPlane;
        contactPlane.fromPointAndNormal(c.point, c.normal);

        // Scan contact features by rotating axis
        f1.numVertices = 0;
        f2.numVertices = 0;
        
        float eps = 0.05f;
        
        // If colliding with a cylinder, use smaller contact area
        if (c.shape1.geometry.type == GeomType.Cylinder ||
            c.shape2.geometry.type == GeomType.Cylinder)
        {
            eps = 0.01f;
        }

        if (c.shape1.geometry.type == GeomType.Cone ||
            c.shape2.geometry.type == GeomType.Cone)
        {
            eps = 0.01f;
        }

        float startAng = PI / 4;
        float stepAng = PI / 2; // 90 degrees

        uint numAxes1 = 4;

        if (c.shape1.geometry.type == GeomType.Triangle)
        {
            numAxes1 = 3;
            startAng = 0;
            stepAng = radtodeg(120.0f); // 2*PI/3 = 120 degrees
        }

        for(uint i = 0; i < numAxes1; i++)
        {
            float ang = startAng + stepAng * i;

            Vector3f axis = (c.normal + n0 * cos(ang) * eps + n1 * sin(ang) * eps).normalized;
            
            Vector3f p;

            supportTransformed(c.shape1, -axis, p);
            
            if (contactPlane.distance(p) < 0.0f)
            {
                Vector2f planePoint = projectPoint(p, c.point, right, up);
                f1.vertices[f1.numVertices] = planePoint;
                f1.numVertices++;
            }
        }

        uint numAxes2 = 4;

        if (c.shape2.geometry.type == GeomType.Triangle)
        {
            numAxes2 = 3;
            startAng = 0;
            stepAng = radtodeg(120.0f); // 2*PI/3 = 120 degrees
        }
        
        for(uint i = 0; i < numAxes2; i++)
        {
            float ang = startAng + stepAng * i;

            Vector3f axis = (c.normal + n0 * cos(ang) * eps + n1 * sin(ang) * eps).normalized;
            
            Vector3f p;

            supportTransformed(c.shape2, axis, p);
            if (contactPlane.distance(p) > 0.0f)
            {
                Vector2f planePoint = projectPoint(p, c.point, right, up);
                f2.vertices[f2.numVertices] = planePoint;
                f2.numVertices++;
            }
        }

        // Clip features in 2D space: find their overlapping polygon
        clip(f1, f2, pts, numPts);

        // Transform the resulting points back into 3D space       
        Contact[8] newManifold;
        Vector3f centroid = Vector3f(0.0f, 0.0f, 0.0f);
        for(uint i = 0; i < numPts; i++)
        {
            Contact newc;
            newc.fact = true;
            newc.body1 = c.body1;
            newc.body2 = c.body2;
            newc.shape1 = c.shape1;
            newc.shape2 = c.shape2;
            newc.point = unprojectPoint(pts[i], c.point, right, up);
            newc.normal = c.normal;
            newc.penetration = c.penetration;
            if (numPts > 1)
                centroid += newc.point;
            else
            {
                newc.fdir1 = n0;
                newc.fdir2 = n1;
            }
            newManifold[i] = newc;
        }

        if (numPts > 1)
        {
            centroid /= numPts;

            for(uint i = 0; i < numPts; i++)
            {
                newManifold[i].fdir1 = (newManifold[i].point - centroid).normalized;
                newManifold[i].fdir2 = cross(newManifold[i].fdir1, c.normal);
            }
        }
        
        // Update the existing manifold
        updateManifold(newManifold, numPts);
    }
    
    void updateManifold(ref Contact[8] newManifold, uint numNewContacts)
    {
        numContacts = 0;
    
        Contact[8] res;
        bool[8] used;
        uint resNum = 0;
        
        foreach(i; 0..numContacts)
        {        
            Vector3f p1 = contacts[i].point;
            
            foreach(j; 0..numNewContacts)
            {
                Vector3f p2 = newManifold[j].point;
                
                if (distance(p1, p2) < 0.1f)
                {
                    res[resNum] = contacts[i];
                    res[resNum].shape1 = newManifold[j].shape1;
                    res[resNum].shape2 = newManifold[j].shape2;
                    res[resNum].body1 = newManifold[j].body1;
                    res[resNum].body2 = newManifold[j].body2;
                    res[resNum].point = p2; //(p1 + p2) * 0.5f;
                    res[resNum].normal = newManifold[j].normal;
                    res[resNum].penetration = newManifold[j].penetration;
                    res[resNum].fdir1 = newManifold[j].fdir1;
                    res[resNum].fdir2 = newManifold[j].fdir2;
                    resNum++;
                    used[j] = true;
                }
            }
        }
        
        foreach(i; 0..numNewContacts)
        {
            if (!used[i])
            {
                res[resNum] = newManifold[i];
                resNum++;
            }
        }
        
        foreach(i; 0..resNum)
        {
            contacts[i] = res[i];
            numContacts++;
        }
    }
}

