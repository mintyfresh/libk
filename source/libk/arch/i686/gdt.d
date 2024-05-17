module libk.arch.i686.gdt;

struct GDTDescriptor
{
align(1):
    ushort size;
    uint offset;
}

static assert(GDTDescriptor.size.offsetof == 0);
static assert(GDTDescriptor.offset.offsetof == 2);
static assert(GDTDescriptor.sizeof == 6);

struct GDTEntry
{
align(1):
    ushort limitLow;
    ushort baseLow;
    ubyte baseMiddle;
    ubyte access;
    ubyte granularity;
    ubyte baseHigh;

    this(uint base, uint limit, ubyte access, ubyte flags)
    {
        this.base   = base;
        this.limit  = limit;
        this.access = access;
        this.flags  = flags;
    }

    @property
    uint base() const nothrow @nogc @safe
    {
        return (baseLow << 0) | (baseMiddle << 16) | (baseHigh << 24);
    }

    @property
    void base(uint value) nothrow @nogc @safe
    {
        baseLow    = (value & 0x0000FFFF) >>  0;
        baseMiddle = (value & 0x00FF0000) >> 16;
        baseHigh   = (value & 0xFF000000) >> 24;
    }

    @property
    uint limit() const nothrow @nogc @safe
    {
        return (limitLow << 0) | (limitHigh << 16);
    }

    @property
    void limit(uint value) nothrow @nogc @safe
    {
        limitLow  = (value & 0x0000FFFF) >>  0;
        limitHigh = (value & 0x000F0000) >> 16;
    }

    @property
    ubyte limitHigh() const nothrow @nogc @safe
    {
        return (granularity & 0x0F) >> 0;
    }

    @property
    void limitHigh(ubyte value) nothrow @nogc @safe
    {
        granularity = (granularity & 0xF0) | ((value << 0) & 0x0F);
    }

    @property
    ubyte flags() const nothrow @nogc @safe
    {
        return (granularity & 0xF0) >> 4;
    }

    @property
    void flags(ubyte value) nothrow @nogc @safe
    {
        granularity = (granularity & 0x0F) | ((value << 4) & 0xF0);
    }

    ulong opCast(T : ulong)() const nothrow @nogc @safe
    {
        return (
            ulong(limitLow)    <<  0 |
            ulong(baseLow)     << 16 |
            ulong(baseMiddle)  << 32 |
            ulong(access)      << 40 |
            ulong(granularity) << 48 |
            ulong(baseHigh)    << 56
        );
    }
}

static assert(GDTEntry.limitLow.offsetof == 0);
static assert(GDTEntry.baseLow.offsetof == 2);
static assert(GDTEntry.baseMiddle.offsetof == 4);
static assert(GDTEntry.access.offsetof == 5);
static assert(GDTEntry.granularity.offsetof == 6);
static assert(GDTEntry.baseHigh.offsetof == 7);
static assert(GDTEntry.sizeof == 8);

// Verify encoding on some well-known GDT entries (taken from the OSDev Wiki)
static assert(cast(ulong) GDTEntry(0, 0, 0, 0) == 0x0000000000000000);
static assert(cast(ulong) GDTEntry(0, 0xFFFFFFFF, 0x9A, 0xC) == 0x00CF9A000000FFFF);
static assert(cast(ulong) GDTEntry(0, 0xFFFFFFFF, 0x92, 0xC) == 0x00CF92000000FFFF);
static assert(cast(ulong) GDTEntry(0, 0xFFFFFFFF, 0xFA, 0xC) == 0x00CFFA000000FFFF);
static assert(cast(ulong) GDTEntry(0, 0xFFFFFFFF, 0xF2, 0xC) == 0x00CFF2000000FFFF);
