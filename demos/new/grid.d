module grid;

import dlib;
import dgl;

class Grid: Drawable
{
    float cellWidth = 1.0f;
    int size = 20;
    
    override void draw(double dt)
    {
        glColor4f(1, 1, 1, 0.25f);
        foreach(x; 0..size+1)
        {
            glBegin(GL_LINES);
            glVertex3f((x - size/2) * cellWidth, 0, -size/2);
            glVertex3f((x - size/2) * cellWidth, 0,  size/2);
            glEnd();
        }
        
        foreach(y; 0..size+1)
        {
            glBegin(GL_LINES);
            glVertex3f(-size/2, 0, (y - size/2) * cellWidth);
            glVertex3f( size/2, 0, (y - size/2) * cellWidth);
            glEnd();
        }
        glColor4f(1, 1, 1, 1);
    }

    override void free()
    {
        Delete(this);
    }
}