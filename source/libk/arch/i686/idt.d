module libk.arch.i686.idt;

struct IDTDescriptor
{
align(1):
    ushort size;
    uint offset;
}

static assert(IDTDescriptor.size.offsetof == 0);
static assert(IDTDescriptor.offset.offsetof == 2);
static assert(IDTDescriptor.sizeof == 6);

enum GateType : ubyte
{
    task32      = 0x5,
    interrupt16 = 0x6,
    trap16      = 0x7,
    interrupt32 = 0xE,
    trap32      = 0xF
}

enum DPL : ubyte
{
    ring0 = 0x0,
    ring1 = 0x1,
    ring2 = 0x2,
    ring3 = 0x3
}

struct IDTEntry
{
    enum ubyte presentMask  = 0b10000000;
    enum ubyte dplMask      = 0b01100000;
    enum ubyte gateTypeMask = 0b00001111;

align(1):
    ushort offsetLow;
    ushort selector;
    ubyte reserved;
    ubyte type;
    ushort offsetHigh;

    this(uint offset, ushort selector, ubyte type) nothrow @nogc @safe
    {
        this.offset   = offset;
        this.selector = selector;
        this.reserved = 0;
        this.type     = type;
    }

    this(uint offset, ushort selector, GateType gateType, DPL dpl, bool present = true) nothrow @nogc @safe
    {
        this.offset   = offset;
        this.selector = selector;
        this.reserved = 0;
        this.gateType = gateType;
        this.dpl      = dpl;
        this.present  = present;
    }

    @property
    uint offset() const nothrow @nogc @safe
    {
        return (offsetLow << 0) | (offsetHigh << 16);
    }

    @property
    void offset(uint value) nothrow @nogc @safe
    {
        offsetLow  = (value & 0x0000FFFF) >>  0;
        offsetHigh = (value & 0xFFFF0000) >> 16;
    }

    @property
    GateType gateType() const nothrow @nogc @safe
    {
        return cast(GateType)(type & gateTypeMask);
    }

    @property
    void gateType(GateType value) nothrow @nogc @safe
    {
        type = (type & ~gateTypeMask) | cast(ubyte)((value << 0) & gateTypeMask);
    }

    @property
    DPL dpl() const nothrow @nogc @safe
    {
        return cast(DPL)((type & dplMask) >> 5);
    }

    @property
    void dpl(DPL value) nothrow @nogc @safe
    {
        type = (type & ~dplMask) | cast(ubyte)((value << 5) & dplMask);
    }

    @property
    bool present() const nothrow @nogc @safe
    {
        return (type & presentMask) != 0;
    }

    @property
    void present(bool value) nothrow @nogc @safe
    {
        type = (type & ~presentMask) | (value ? presentMask : 0);
    }

    ulong opCast(T : ulong)() const nothrow @nogc @safe
    {
        return (
            ulong(offsetLow)  <<  0 |
            ulong(selector)   << 16 |
            ulong(reserved)   << 32 |
            ulong(type)       << 40 |
            ulong(offsetHigh) << 48
        );
    }
}

static assert(IDTEntry.offsetLow.offsetof == 0);
static assert(IDTEntry.selector.offsetof == 2);
static assert(IDTEntry.reserved.offsetof == 4);
static assert(IDTEntry.type.offsetof == 5);
static assert(IDTEntry.offsetHigh.offsetof == 6);
static assert(IDTEntry.sizeof == 8);

static assert(IDTEntry(0, 0x8, GateType.interrupt32, DPL.ring0, true).type == 0x8E);
static assert(IDTEntry(0, 0x8, GateType.trap32, DPL.ring0, true).type == 0x8F);
static assert(IDTEntry(0, 0x8, GateType.task32, DPL.ring0, true).type == 0x85);
static assert(IDTEntry(0, 0x8, GateType.interrupt32, DPL.ring3, true).type == 0xEE);

static assert(cast(ulong) IDTEntry(0, 0x8, GateType.interrupt32, DPL.ring0, true) == 0x00008E0000080000);
static assert(cast(ulong) IDTEntry(0, 0x8, GateType.interrupt32, DPL.ring3, true) == 0x0000EE0000080000);
