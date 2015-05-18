dmech
=====
dmech stands for "D mechanics": it is a real-time 3D physics engine written in D language, capable of simulating rigid body dynamics. It is more suitable for computer games than scientific simulations: the goal is to convince a player, rather than giving accurate results. dmech is GC-free and fully platform-independent, it can be used with any API or graphics engine. Currently dmech is in early stages of development and not considered for production use.

Screenshots
-----------
[![Screenshot1](/images/screenshot1_thumb.jpg)](/images/screenshot1.jpg)
[![Screenshot2](/images/screenshot2_thumb.jpg)](/images/screenshot2.jpg)
[![Screenshot3](/images/screenshot3_thumb.jpg)](/images/screenshot3.jpg)
[![Screenshot4](/images/screenshot4_thumb.jpg)](/images/screenshot4.jpg)

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

Planned in future:
* More shapes (capsule, plane, convex hull, etc.)
* Minkowski sum shape
* Force fields
* Convex cast
* In long-term: vehicle engine, particles, soft-body physics

Dependencies
------------
dmech heavily relies on [dlib](http://github.com/gecko0307/dlib) - a collection of utility libraries for D, including linear math and computational geometry functionality (it is recommended to use master, because dmech usually depends on latest repository changes).

Usage examples
--------------
See [demos](/demos) directory. All examples use [DGL](http://github.com/gecko0307/dgl) for rendering. Warning: demos may be not up-to-date with latest changes in dmech and DGL source code, please apologize for the inconvenience.

Precompiled demos (for Windows):
* [Third person game](https://www.dropbox.com/s/oks658nrzc9hz8n/third-person-game-robot-win32.zip?dl=0)

For real-world usage demo, check out [Atrium](http://github.com/gecko0307/atrium), a physics-based action game.

License
-------
Copyright (c) 2013-2015 Timur Gafarov.
Distributed under the Boost Software License, Version 1.0. (See accompanying file COPYING or at http://www.boost.org/LICENSE_1_0.txt)

