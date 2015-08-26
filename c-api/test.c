#include <stdio.h>
#include <stdlib.h>
#include <GL/glut.h>
#include "dmech.h"

void* world;
void* g1;
void* g2;
void* g3;

typedef struct
{
    void* rbody;
    float color[4];
} Object;

#define MAX_OBJECTS 100
Object objects[MAX_OBJECTS];
int numObjects = 0;

GLuint dlSphere;
GLuint dlCube;
const double timeStep = 1.0 / 60.0;

void* addBody(void* geom, float x, float y, float z)
{
    if (numObjects < MAX_OBJECTS)
    {
        void* b = dmWorldAddDynamicBody(world, x, y, z, 0);
        dmWorldAddCollisionShape(world, b, geom, 0, 0, 0, 1);
        Object obj;
        obj.rbody = b;
        obj.color[0] = 0.1f + (float)numObjects/MAX_OBJECTS;
        obj.color[1] = 0;
        obj.color[2] = 0;
        obj.color[3] = 1;
        objects[numObjects] = obj;
        numObjects++;
        return b;
    }
    else
        return NULL;
}

void buildPyramid(void* geom, int pyramidSize)
{
    float size = 1.0f;
    float cubeHeight = 2.0f;
    float width = size * 2.0f;
    float height = cubeHeight;
    float horizontal_spacing = 0.1f;
    float veritcal_spacing = 0.1f;

    int i, e;
    for (i = 0; i < pyramidSize; i++)
    for (e = i; e < pyramidSize; e++)
    {
        float px = (e - i * 0.5f) * (width + horizontal_spacing) - ((width + horizontal_spacing) * 5);
        float py = 6.0f + (height + veritcal_spacing * 0.5f) + i * height + 0.26f;
        float pz = -3;
        addBody(geom, px, py, pz);
    }
}

void onKeyPress(unsigned char key, int a, int b)
{
    glutPostRedisplay();
}

void onDraw()
{
    dmWorldUpdate(world, timeStep);

    float m[16];

    glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
    glLoadIdentity();
    gluLookAt(
      35,  35,  35,  // eye pos
      0,  0,  0,   // aim point
      0,  1,  0);  // up direction
    glColor4f(1, 1, 1, 1);

    int i;
    for(i = 0; i < numObjects; i++)
    if (dmBodyGetActive(objects[i].rbody))
    {
        glPushMatrix();
        dmBodyGetMatrix(objects[i].rbody, m);
        glMultMatrixf(m);
        //glColor4fv(objects[i].color);
        glCallList(dlCube);
        glPopMatrix();
    }

    glutSwapBuffers();
}

void onInit()
{
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);

    dmInit();
    world = dmCreateWorld(1000);
    dmWorldSetBroadphase(world, 0);
    dmWorldSetSolverIterations(world, 10, 20);

    void* b1 = dmWorldAddStaticBody(world, 0, -1, 0);
    g1 = dmCreateGeomBox(30, 1, 30);
    dmWorldAddCollisionShape(world, b1, g1, 0, 0, 0, 1);

    g3 = dmCreateGeomBox(1, 1, 1);
    g2 = dmCreateGeomSphere(1);

    buildPyramid(g3, 8);
    dmBodySetActive(objects[numObjects-5].rbody, 0);

    GLUquadricObj* quadric = gluNewQuadric();
    gluQuadricNormals(quadric, GLU_SMOOTH);
    gluQuadricTexture(quadric, GL_TRUE);

    dlSphere = glGenLists(1);
    glNewList(dlSphere, GL_COMPILE);
    gluSphere(quadric, 1, 24, 16);
    glEndList();
    gluDeleteQuadric(quadric);

    dlCube = glGenLists(1);
    glNewList(dlCube, GL_COMPILE);
    glBegin(GL_QUADS);
    glNormal3f(0,0,1); glVertex3f(-1,-1,1);
    glNormal3f(0,0,1); glVertex3f(1,-1,1);
    glNormal3f(0,0,1); glVertex3f(1,1,1);
    glNormal3f(0,0,1); glVertex3f(-1,1,1);
    glNormal3f(1,0,0); glVertex3f(1,-1,1);
    glNormal3f(1,0,0); glVertex3f(1,-1,-1);
    glNormal3f(1,0,0); glVertex3f(1,1,-1);
    glNormal3f(1,0,0); glVertex3f(1,1,1);
    glNormal3f(0,1,0); glVertex3f(-1,1,1);
    glNormal3f(0,1,0); glVertex3f(1,1,1);
    glNormal3f(0,1,0); glVertex3f(1,1,-1);
    glNormal3f(0,1,0); glVertex3f(-1,1,-1);
    glNormal3f(0,0,-1); glVertex3f(-1,-1,-1);
    glNormal3f(0,0,-1); glVertex3f(-1,1,-1);
    glNormal3f(0,0,-1); glVertex3f(1,1,-1);
    glNormal3f(0,0,-1); glVertex3f(1,-1,-1);
    glNormal3f(0,-1,0); glVertex3f(-1,-1,-1);
    glNormal3f(0,-1,0); glVertex3f(1,-1,-1);
    glNormal3f(0,-1,0); glVertex3f(1,-1,1);
    glNormal3f(0,-1,0); glVertex3f(-1,-1,1);
    glNormal3f(-1,0,0); glVertex3f(-1,-1,-1);
    glNormal3f(-1,0,0); glVertex3f(-1,-1,1);
    glNormal3f(-1,0,0); glVertex3f(-1,1,1);
    glNormal3f(-1,0,0); glVertex3f(-1,1,-1);
    glEnd();
    glEndList();
}

void onExit()
{
    glDeleteLists(dlSphere, 1);
    dmDeleteGeom(g1);
    dmDeleteGeom(g2);
    dmDeleteWorld(world);
}

void onReshape(int w, int h)
{
    glViewport(0,0,w,h);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluPerspective(45,(float)w/h,0.1,100);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
}

void onIdle()
{
    glutPostRedisplay();
}

int main(int argc, char** argv)
{
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DEPTH | GLUT_RGB | GLUT_DOUBLE);
    glutInitWindowSize(640, 480);
    glutCreateWindow("dmech demo");
    glutDisplayFunc(onDraw);
    glutReshapeFunc(onReshape);
    glutKeyboardFunc(onKeyPress);
    glutIdleFunc(onIdle);
    onInit();
    atexit(onExit);
    glutMainLoop();
    return 0;
}

