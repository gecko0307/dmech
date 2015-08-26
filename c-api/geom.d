module geom;

import dlib.core.memory;
import dlib.math.vector;
import dmech.geometry;

extern(C):

export void* dmCreateGeomSphere(float r)
{
    GeomSphere geom = New!(GeomSphere)(r);
    return cast(void*)geom;
}

export void* dmCreateGeomBox(float hsx, float hsy, float hsz)
{
    GeomBox geom = New!(GeomBox)(Vector3f(hsx, hsy, hsz));
    return cast(void*)geom;
}

export void* dmCreateGeomCylinder(float h, float r)
{
    GeomCylinder geom = New!(GeomCylinder)(h, r);
    return cast(void*)geom;
}

export void* dmCreateGeomCone(float h, float r)
{
    GeomCone geom = New!(GeomCone)(h, r);
    return cast(void*)geom;
}

export void* dmCreateGeomEllipsoid(float rx, float ry, float rz)
{
    GeomEllipsoid geom = New!(GeomEllipsoid)(Vector3f(rx, ry, rz));
    return cast(void*)geom;
}

export void dmDeleteGeom(void* pGeom)
{
    Geometry geom = cast(Geometry)pGeom;        
    if (geom)
    {
        geom.free();
    }
}

