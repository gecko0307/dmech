/*
Copyright (c) 2014-2025 Timur Gafarov

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/
module dmech.pairhashtable;

import dlib.core.ownership;
import dlib.core.memory;
import dmech.hashtable;

/*
 * Hash table that uses a pair of keys for indexing.
 * Pair order matters: (a,b) != (b,a)
 */

class PairHashTable(T): HashTable!(T, uint)
{
    this(Owner o, size_t size)
    {
        super(o, size);
    }

    T* get(uint k1, uint k2)
    {
        return super.get(szudzikPair(k1, k2));
    }

    void set(uint k1, uint k2, T value)
    {
        super.set(szudzikPair(k1, k2), value);
    }

    void remove(uint k1, uint k2)
    {
        super.remove(szudzikPair(k1, k2));
    }
}

uint szudzikPair(uint a, uint b)
{
    return a >= b ? a * a + a + b : a + b * b;
}
