[![Build Status](https://travis-ci.org/gecko0307/dmech.svg?branch=master)](https://travis-ci.org/gecko0307/dmech)

dmech
=====
dmech stands for "D mechanics": it is a real-time 3D physics engine written in D language, capable of simulating rigid body dynamics. It is more suitable for computer games than scientific simulations: the goal is to convince a player, rather than giving accurate results. dmech is GC-free and fully platform-independent, it can be used with any API or graphics engine.

Screenshots
-----------
[![Screenshot1](/images/screenshot1_thumb.jpg)](/images/screenshot1.jpg)
[![Screenshot2](/images/screenshot2_thumb.jpg)](/images/screenshot2.jpg)
[![Screenshot3](/images/screenshot3_thumb.jpg)](/images/screenshot3.jpg)

Features
--------
Already implemented:
* Impulse-based rigid body dynamics with iterative SI solver
* High-performance collision detection (MPR algorithm)
* Basic geometry shapes (sphere, box, cylinder, cone, ellipsoid)
* Support for any convex shape defined by support mapping
* Multiple geometries per body
* Arbitrary static trimeshes (collision detection is optimized via BVH)
* Body constraints: distance, angular, slider, ball-socket, prismatic, hinge
* Persistent contact cache
* Ray cast support
* Partial C API (will be finished soon)

Planned in future:
* More shapes (capsule, plane, convex hull, etc.)
* Minkowski sum shape
* Force fields
* Convex cast
* In long-term: vehicle engine, particles, soft-body physics, OpenCL support

Dependencies
------------
dmech heavily relies on [dlib](http://github.com/gecko0307/dlib) - a collection of utility libraries for D, including linear math and computational geometry functionality.

Documentation
-------------
See [tutorials](/tutorials).

Usage examples
--------------
You can find some simple examples in [demos/new](/demos/new) directory. 

More advanced, real-world usage examples are [Dagon demo application](http://github.com/gecko0307/dagon-demo) which features vehicle physics and provides better graphics and interesting user interaction, and [Atrium](http://github.com/gecko0307/atrium), an in-development physics based action game. 

License
-------
Copyright (c) 2013-2017 Timur Gafarov.
Distributed under the Boost Software License, Version 1.0. (See accompanying file COPYING or at http://www.boost.org/LICENSE_1_0.txt)

