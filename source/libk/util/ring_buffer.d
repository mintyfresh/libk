module libk.util.ring_buffer;

enum RingBufferOverflow
{
    /// if buffer is full, overwrite the oldest element
    overwrite,
    /// if buffer is full, discard the new element
    reject
}

struct RingBuffer(T, size_t capacity_, RingBufferOverflow overflowPolicy = RingBufferOverflow.overwrite)
{
private:
    T[capacity] _buffer;
    size_t _head;
    size_t _tail;
    size_t _length;

public:
    /++
     + The type of elements stored in the buffer.
     +/
    alias ValueType = T;

    /++
     + The maximum number of elements the buffer can hold.
     +/
    @property
    enum size_t capacity = capacity_;

    /++
     + Returns true if the buffer is empty.
     +/
    @property
    bool empty() const nothrow @safe @nogc
    {
        return _length == 0;
    }

    /++
     + Returns true if the buffer is full.
     +/
    @property
    bool full() const nothrow @safe @nogc
    {
        return _length == capacity;
    }

    /++
     + Returns the number of elements currently in the buffer.
     +/
    @property
    size_t length() const nothrow @safe @nogc
    {
        return _length;
    }

    /++
     + Resets the buffer to its initial, empty state.
     +/
    void clear() nothrow @safe @nogc
    {
        _head = _tail = _length = 0;
        _buffer[] = T.init;
    }

    /++
     + Pushes a new element into the buffer.
     + If the buffer is full, the behavior is determined by the overflow policy.
     +
     + Params:
     +   value = the value to push into the buffer
     + Returns:
     +   true if the value was successfully pushed, false if the push was rejected
     +/
    bool push(T value) nothrow @safe @nogc
    {
        if (full)
        {
            final switch (overflowPolicy)
            {
                case RingBufferOverflow.overwrite:
                    advanceTail();
                    break;

                case RingBufferOverflow.reject:
                    return false;
            }
        }

        _buffer[_head] = value;
        advanceHead();

        return true;
    }

    /// ditto
    bool push(const ref T value) nothrow @safe @nogc
    {
        if (full)
        {
            final switch (overflowPolicy)
            {
                case RingBufferOverflow.overwrite:
                    advanceTail();
                    break;

                case RingBufferOverflow.reject:
                    return false;
            }
        }

        _buffer[_head] = value;
        advanceHead();

        return true;
    }

    /++
     + Returns the oldest element in the buffer without removing it.
     + If the buffer is empty, the default value of T is returned.
     + If the initial value of T is not suitable, use peek(out T value) instead.
     +
     + Returns:
     +   the oldest element in the buffer, or the default value of T if the buffer is empty
     +/
    T peek() const nothrow @safe @nogc
    {
        return _buffer[_tail];
    }

    /++
     + Returns the oldest element in the buffer without removing it.
     + If the buffer is empty, the output value is not modified and false is returned.
     +
     + Params:
     +   value = the output value
     + Returns:
     +   true if the value was successfully peeked, false if the buffer is empty
     +/
    bool peek(out T value) const nothrow @safe @nogc
    {
        if (empty)
        {
            return false;
        }

        value = _buffer[_tail];

        return true;
    }

    /++
     + Pops and directly returns the oldest element from the buffer.
     + If the buffer is empty, the default value of T is returned.
     + If the initial value of T is not suitable, use pop(out T value) instead.
     +
     + Returns:
     +   the oldest element in the buffer, or the default value of T if the buffer is empty
     +/
    T pop() nothrow @safe @nogc
    {
        T value = T.init;
        pop(value);

        return value;
    }

    /++
     + Pops the oldest element from the buffer.
     + If the buffer is empty, the output value is not modified and false is returned.
     +
     + Params:
     +   value = the output value
     + Returns:
     +   true if the value was successfully popped, false if the buffer is empty
     +/
    bool pop(out T value) nothrow @safe @nogc
    {
        if (empty)
        {
            return false;
        }

        value = _buffer[_tail];
        advanceTail();

        return true;
    }

private:
    void advanceHead() nothrow @safe @nogc
    {
        _head = (_head + 1) % capacity;
        _length++;
    }

    void advanceTail() nothrow @safe @nogc
    {
        _tail = (_tail + 1) % capacity;
        _length--;
    }
}

@safe @nogc unittest
{
    RingBuffer!(int, 4) buffer;

    assert(buffer.empty, "Ring buffer should be empty initially");
    assert(!buffer.full, "Ring buffer should not be full initially");

    buffer.push(1);
    assert(!buffer.empty, "Ring buffer should not be empty after pushing an element");
    assert(!buffer.full, "Ring buffer should not be full after pushing an element");
    assert(buffer.length == 1, "Ring buffer length should be 1 after pushing an element");

    buffer.push(2);
    buffer.push(3);
    buffer.push(4);
    assert(!buffer.empty, "Ring buffer should not be empty after pushing 4 elements");
    assert(buffer.full, "Ring buffer should be full after pushing 4 elements");
    assert(buffer.length == 4, "Ring buffer length should be 4 after pushing 4 elements");

    int result;
    assert(buffer.pop(result));
    assert(result == 1);
    assert(!buffer.empty);
    assert(!buffer.full);
    assert(buffer.length == 3);

    assert(buffer.pop(result));
    assert(result == 2);
    assert(buffer.length == 2);

    assert(buffer.pop(result));
    assert(result == 3);
    assert(buffer.length == 1);

    assert(buffer.pop(result));
    assert(result == 4);
    assert(buffer.length == 0);
    assert(buffer.empty);

    assert(!buffer.pop(result));
    assert(buffer.empty);
    assert(!buffer.full);

    buffer.push(5);
    buffer.push(6);

    // peek does not remove the element
    assert(buffer.length == 2);
    assert(buffer.peek(result));
    assert(result == 5);
    assert(buffer.length == 2);

    assert(buffer.pop(result));
    assert(result == 5);
    assert(buffer.pop(result));
    assert(result == 6);
    assert(buffer.empty);
    assert(!buffer.full);

    buffer.push(7);
    buffer.push(8);
    buffer.push(9);
    assert(!buffer.empty);
    assert(!buffer.full);
    assert(buffer.length == 3);

    // buffer is cleared
    buffer.clear();
    assert(buffer.empty);
    assert(!buffer.full);
    assert(buffer.length == 0);

    buffer.push(10);
    buffer.push(11);
    buffer.push(12);
    buffer.push(13);
    assert(buffer.full);
    assert(buffer.length == 4);

    // overwrite last element
    assert(buffer.push(14));
    assert(buffer.length == 4);

    // 10 was overwritten
    assert(buffer.pop(result));
    assert(result == 11);
    assert(buffer.pop(result));
    assert(result == 12);
    assert(buffer.pop(result));
    assert(result == 13);
    assert(buffer.pop(result));
    assert(result == 14);
}

