module libk.type;

enum bool isString(T) = isCString!(T) || isDString!(T);
enum bool isCString(T) = is(T == char*) || is(T == const(char)*) || is(T == immutable(char)*) ||
                         is(T == wchar*) || is(T == const(wchar)*) || is(T == immutable(wchar)*) ||
                         is(T == dchar*) || is(T == const(dchar)*) || is(T == immutable(dchar)*);
enum bool isDString(T) = is(T == string) || is(T == wstring) || is(T == dstring);

enum bool isInteger(T) = isSigned!(T) || isUnsigned!(T);
enum bool isSigned(T) = is(T == byte) || is(T == short) || is(T == int) || is(T == long);
enum bool isUnsigned(T) = is(T == ubyte) || is(T == ushort) || is(T == uint) || is(T == ulong);
enum bool isCharacter(T) = is(T == char) || is(T == wchar) || is(T == dchar);
