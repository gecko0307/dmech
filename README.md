dmech
=====
Real-time 3D physics engine written in D language. It is more suitable for computer games than scientific simulations: the goal is to convince a player, rather than giving accurate results. Currently dmech is in early stages of development, hence not considered for production use.

Features
--------
Already implemented:
* Impulse-based rigid body dynamics with iterative SI solver
* Basic geometry shapes (sphere, box, cylinder, cone, ellipsoid)
* Support for any convex shapes defined by support mapping
* Simple body constraints: distance, ball-socket, slider

Planned in future:
* More shapes (capsule, plane, convex hull, etc.)
* Arbitrary static trimehes
* Combined constraint types
* Kinematic bodies
* Vehicle physics
* Particles

License
-------
Copyright (c) 2013 Timur Gafarov.
Distributed under the Boost Software License, Version 1.0. (See accompanying file COPYING or copy at http://www.boost.org/LICENSE_1_0.txt)



