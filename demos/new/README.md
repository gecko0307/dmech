dmech usage demos
=================
Three demos are available:

* Simple (simple.d) - a simple physics world with rigid bodies
* Pyramid (pyramid.d) - object picking and dragging with mouse
* Game (game.d) - an example of fully physics-based first person game mechanics. Can be used as a base for action games

Graphics Engine
---------------
For 3D rendering, [DGL](http://github.com/gecko0307/dgl) is used. Because DGL is currently under active development and often breaks backward compatibility, the latest version is included here.

Building with DUB
-----------------
dub build --config=simple
dub build --config=pyramid
dub build --config=game

Building with Cook
------------------
cook --rsp simple
cook --rsp pyramid
cook --rsp game