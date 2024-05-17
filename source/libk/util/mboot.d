module libk.util.mboot;

enum MultibootHeaderMagic = 0x1BADB002;
enum MultibootLoaderMagic = 0x2BADB002;

enum MultibootHeaderFlags : uint
{
    pageAlign  = 1 << 0,
    memoryInfo = 1 << 1,
    videoMode  = 1 << 2,
    aoutKludge = 1 << 16,
}

struct MultibootHeader
{
align(1):
    uint magic;
    uint flags;
    uint checksum;

    // Fields for AOUT kludge (flags[16] == 1)
    uint headerAddress;
    uint loadAddress;
    uint loadEndAddress;
    uint bssEndAddress;
    uint entryAddress;

    // Fields for video mode (flags[2] == 1)
    uint modeType;
    uint width;
    uint height;
    uint depth;
}

static assert(MultibootHeader.sizeof == 48);

enum MultibootInfoFlags : uint
{
    memoryInfo       = 1 << 0,
    bootDevice       = 1 << 1,
    cmdline          = 1 << 2,
    modules          = 1 << 3,
    aoutSymbolTable  = 1 << 4,
    elfSectionHeader = 1 << 5,
    memoryMap        = 1 << 6,
    driveInfo        = 1 << 7,
    configTable      = 1 << 8,
    bootLoaderName   = 1 << 9,
    apmTable         = 1 << 10,
    vbeInfo          = 1 << 11,
    framebufferInfo  = 1 << 12,
}

struct MultibootInfo
{
align(1):
    uint flags;

    // Available memory from BIOS
    uint memLower;
    uint memUpper;

    // "root" partition
    uint bootDevice;

    // Kernel command line
    uint cmdline;

    // Boot modules
    uint modsCount;
    uint modsAddr;

    union
    {
        // ELF section header table
        uint[4] symbols;
        MultibootAOutSymbolTable aoutSymbolTable;
        MultibootElfSectionHeaderTable elfSectionHeaderTable;
    }

    // Memory map buffer
    uint mmapLength;
    uint mmapAddr;

    // Drives information
    uint drivesLength;
    uint drivesAddr;

    // ROM configuration table
    uint configTable;

    // String containing the boot loader name
    uint bootLoaderName;

    // APM table
    uint apmTable;

    // Video information
    uint vbeControlInfo;
    uint vbeModeInfo;
    ushort vbeMode;
    ushort vbeInterfaceSeg;
    ushort vbeInterfaceOff;
    ushort vbeInterfaceLen;

    // Framebuffer information
    ulong framebufferAddr;
    uint framebufferPitch;
    uint framebufferWidth;
    uint framebufferHeight;
    ubyte framebufferBpp;
    ubyte framebufferType;
    union
    {
        ubyte[6] colorInfo;
        struct
        {
            ubyte framebufferRedFieldPosition;
            ubyte framebufferRedMaskSize;
            ubyte framebufferGreenFieldPosition;
            ubyte framebufferGreenMaskSize;
            ubyte framebufferBlueFieldPosition;
            ubyte framebufferBlueMaskSize;
        }
        struct
        {
            uint framebufferPaletteAddr;
            ushort framebufferPaletteNumColors;
        }
    }
}

struct MultibootAOutSymbolTable
{
align(1):
    uint tabSize;
    uint strSize;
    uint addr;
    uint reserved;
}

static assert(MultibootAOutSymbolTable.sizeof == 16);

struct MultibootElfSectionHeaderTable
{
align(1):
    uint num;
    uint size;
    uint addr;
    uint shndx;
}

static assert(MultibootElfSectionHeaderTable.sizeof == 16);

enum MemoryMapEntryType : uint
{
    available = 1,
    reserved  = 2,
    acpiReclaimable = 3,
    acpiNVS = 4,
    badMemory = 5,
}

struct MultibootMemoryMapEntry
{
align(1):
    uint size;
    ulong baseAddr;
    ulong length;
    MemoryMapEntryType type;
}

struct MultibootModuleList
{
align(1):
    uint modStart;
    uint modEnd;
    uint cmdline;
    uint reserved;
}

struct MultibootAPMInfo
{
align(1):
    ushort version_;
    ushort cseg;
    uint offset;
    ushort cseg16;
    ushort dseg;
    ushort flags;
    ushort csegLen;
    ushort cseg16Len;
    ushort dsegLen;
}
