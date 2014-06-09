dmech
=====
dmech is a real-time 3D physics engine written in D language. It is more suitable for computer games than scientific simulations: the goal is to convince a player, rather than giving accurate results. Currently dmech is in early stages of development, not considered for production use.

Features
--------
Already implemented:
* Impulse-based rigid body dynamics with iterative SI solver
* Basic geometry shapes (sphere, box, cylinder, cone, ellipsoid)
* Support for any convex shape defined by support mapping
* Multiple geometries per body
* Arbitrary static trimeshes
* Simple body constraints: distance and ball-socket
* Persistent contact cache

Planned in future:
* More shapes (capsule, plane, convex hull, etc.)
* Minkowski sum shape
* New constraint types
* Force fields
* Kinematic bodies
* In long-term: vehicle engine, particles, soft-body physics

Dependencies
------------
dmech heavily relies on [dlib](http://github.com/gecko0307/dlib) - a collection of utility libraries for D, including linear math and computational geometry functionality. The demo uses [DGL](http://github.com/gecko0307/dgl) for rendering.

License
-------
Copyright (c) 2013-2014 Timur Gafarov.
Distributed under the Boost Software License, Version 1.0. (See accompanying file COPYING or at http://www.boost.org/LICENSE_1_0.txt)

Screenshots
-----------
[![Screenshot1](/images/screenshot1_thumb.jpg)](/images/screenshot1.jpg)
[![Screenshot2](/images/screenshot2_thumb.jpg)](/images/screenshot2.jpg)

