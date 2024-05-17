module libk.util.type;

enum bool isString(T) = isCString!(T) || isDString!(T);
enum bool isCString(T) = is(T == char*) || is(T == const(char)*) || is(T == immutable(char)*) ||
                         is(T == wchar*) || is(T == const(wchar)*) || is(T == immutable(wchar)*) ||
                         is(T == dchar*) || is(T == const(dchar)*) || is(T == immutable(dchar)*);
enum bool isDString(T) = is(T == string) || is(T == wstring) || is(T == dstring);

enum bool isNumeric(T) = isInteger!(T) || isFloatingPoint!(T);

enum bool isInteger(T) = isSigned!(T) || isUnsigned!(T);
enum bool isSigned(T) = is(T == byte) || is(T == short) || is(T == int) || is(T == long);
enum bool isUnsigned(T) = is(T == ubyte) || is(T == ushort) || is(T == uint) || is(T == ulong);
enum bool isCharacter(T) = is(T == char) || is(T == wchar) || is(T == dchar);

enum bool isFloatingPoint(T) = is(T == float) || is(T == double) || is(T == real);

template Signed(T) if (isUnsigned!T)
{
    static if (is(T == ubyte))
    {
        alias Signed = byte;
    }
    else static if (is(T == ushort))
    {
        alias Signed = short;
    }
    else static if (is(T == uint))
    {
        alias Signed = int;
    }
    else static if (is(T == ulong))
    {
        alias Signed = long;
    }
    else
    {
        static assert(0, "Signed type not found for " ~ T.stringof);
    }
}

template Unsigned(T) if (isSigned!T)
{
    static if (is(T == byte))
    {
        alias Unsigned = ubyte;
    }
    else static if (is(T == short))
    {
        alias Unsigned = ushort;
    }
    else static if (is(T == int))
    {
        alias Unsigned = uint;
    }
    else static if (is(T == long))
    {
        alias Unsigned = ulong;
    }
    else
    {
        static assert(0, "Unsigned type not found for " ~ T.stringof);
    }
}
