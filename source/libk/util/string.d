module libk.util.string;

import libk.util.type;

enum alphadigits = "0123456789abcdefghijklmnopqrstuvwxyz";
enum int minBase = 2;
enum int maxBase = alphadigits.length;

template toStringLength(T) if (isInteger!T)
{
    enum size_t toStringLength = (8 * T.sizeof) + 1;
}

template ToStringBuffer(T) if (isInteger!T)
{
    alias ToStringBuffer = char[toStringLength!T];
}

void toString(T)(T value, ref ToStringBuffer!T buffer, int base) if (isInteger!T)
{
    if (base < minBase || base > maxBase)
    {
        buffer[0] = '\0';
        return;
    }

    static if (isSigned!T)
    {
        // 2's complement negatives are one greater in magnitude than their positive counterpart
        // This means a max negative value will overflow when negated
        // We need to convert the value to its unsigned counterpart to avoid this
        Unsigned!T v = value < 0 ? -value : value;
    }
    else
    {
        T v = value;
    }

    size_t index = 0;

    do
    {
        char digit = alphadigits[cast(size_t)(v % base)];
        buffer[index++] = digit;
        v /= base;
    }
    while (v != 0 && index + 1 < buffer.length);

    static if (isSigned!T)
    {
        if (value < 0 && base == 10)
        {
            buffer[index++] = '-';
        }
    }

    buffer[index] = '\0';
    buffer[0..index].reverse;
}

ToStringBuffer!T toString(T)(T value, int base) if (isInteger!T)
{
    ToStringBuffer!T buffer;

    toString!T(value, buffer, base);

    return buffer;
}

version (unittest)
{
    import core.stdc.stdio;
    import core.stdc.string;
}

unittest
{
    ToStringBuffer!int intBuffer;

    intBuffer = toString(12_345, 10);
    assert(strcmp(intBuffer.ptr, "12345") == 0);

    intBuffer = toString(-1234, 10);
    assert(strcmp(intBuffer.ptr, "-1234") == 0);

    intBuffer = toString(0xDEADBEEF, 16);
    assert(strcmp(intBuffer.ptr, "deadbeef") == 0);

    intBuffer = toString(0b10101100, 2);
    assert(strcmp(intBuffer.ptr, "10101100") == 0);

    ToStringBuffer!long longBuffer;

    longBuffer = toString(0x12345678_9ABCDEF0UL, 16);
    assert(strcmp(longBuffer.ptr, "123456789abcdef0") == 0);

    longBuffer = toString(long.min, 10);
    assert(strcmp(longBuffer.ptr, "-9223372036854775808") == 0);
}

@property
size_t length(T)(T* str) nothrow @nogc
    if (isCharacter!T)
{
    if (str is null)
    {
        return 0;
    }

    size_t len = 0;

    while (str[len] != '\0')
    {
        len++;
    }

    return len;
}

@property
T* reverse(T)(T* str) nothrow @nogc if (isCharacter!T)
{
    size_t len = str.length;

    foreach(i; 0..len / 2)
    {
        T temp = str[i];
        str[i] = str[len - i - 1];
        str[len - i - 1] = temp;
    }

    return str;
}

@property
T[] reverse(T)(T[] str) nothrow @nogc if (isCharacter!T)
{
    size_t len = str.length;

    foreach(i; 0..len / 2)
    {
        T temp = str[i];
        str[i] = str[len - i - 1];
        str[len - i - 1] = temp;
    }

    return str;
}
