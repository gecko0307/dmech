dmech
=====
dmech is a real-time 3D physics engine written in D language. It is more suitable for computer games than scientific simulations: the goal is to convince a player, rather than giving accurate results. Currently dmech is in early stages of development, hence not considered for production use.

Features
--------
Already implemented:
* Impulse-based rigid body dynamics with iterative SI solver
* Basic geometry shapes (sphere, box, cylinder, cone, ellipsoid)
* Support for any convex shapes defined by support mapping
* Muttiple geometries per body
* Simple body constraints: distance, ball-socket, slider
* Persistent contact cache

Planned in future:
* More shapes (capsule, plane, convex hull, etc.)
* Arbitrary static trimehes
* Combined constraint types
* Kinematic bodies
* In long-term: vehicle engine, particles, soft-body physics

Dependencies
------------
The project is completely self-sufficient, though dmech heavily relies on [dlib](http://github.com/gecko0307/dlib) - a collection of utility libraries for D, including linear math and comutational geometry functionality. dlib is currently under active development and has no stable release yet, so dmech comes with a compatible version of dlib source tree bundled. I try to sync the codebase timely, but dmech occasionally lags behind.

License
-------
Copyright (c) 2013 Timur Gafarov.
Distributed under the Boost Software License, Version 1.0. (See accompanying file COPYING or at http://www.boost.org/LICENSE_1_0.txt)



