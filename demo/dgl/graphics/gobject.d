module dgl.graphics.gobject;

import dgl.core.drawable;
import dgl.graphics.material;

abstract class GraphicObject: Drawable
{
    //Material material;
    
    void draw(double delta)
    {
        //if (material !is null)
        //    material.bind(delta);
            
        render(delta);
            
        //if (material !is null)
        //    material.unbind();
    }
    
    void render(double delta) // override me
    {
    }

    void free() // override me
    {
    }
}
