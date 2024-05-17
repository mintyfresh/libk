module libk.util.mboot;

alias multiboot_uint8_t = ubyte;
alias multiboot_uint16_t = ushort;
alias multiboot_uint32_t = uint;
alias multiboot_uint64_t = ulong;

enum MultibootHeaderMagic = 0x1BADB002;
enum MultibootLoaderMagic = 0x2BADB002;

enum MultibootHeaderFlags : multiboot_uint32_t
{
    pageAlign  = 1 << 0,
    memoryInfo = 1 << 1,
    videoMode  = 1 << 2,
    aoutKludge = 1 << 16,
}

struct MultibootHeader
{
align(1):
    multiboot_uint32_t magic;
    multiboot_uint32_t flags;
    multiboot_uint32_t checksum;

    // Fields for AOUT kludge (flags[16] == 1)
    multiboot_uint32_t headerAddress;
    multiboot_uint32_t loadAddress;
    multiboot_uint32_t loadEndAddress;
    multiboot_uint32_t bssEndAddress;
    multiboot_uint32_t entryAddress;

    // Fields for video mode (flags[2] == 1)
    multiboot_uint32_t modeType;
    multiboot_uint32_t width;
    multiboot_uint32_t height;
    multiboot_uint32_t depth;
}

static assert(MultibootHeader.sizeof == 48);

enum MultibootInfoFlags : multiboot_uint32_t
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

enum MultibootFramebufferType : multiboot_uint8_t
{
    indexed = 0,
    rgb     = 1,
    egaText = 2,
}

struct MultibootInfo
{
align(1):
    multiboot_uint32_t flags;

    // Available memory from BIOS
    multiboot_uint32_t memLower;
    multiboot_uint32_t memUpper;

    // "root" partition
    multiboot_uint32_t bootDevice;

    // Kernel command line
    multiboot_uint32_t cmdline;

    // Boot modules
    multiboot_uint32_t modulesCount;
    multiboot_uint32_t modulesAddress;

    union
    {
        // ELF section header table
        multiboot_uint32_t[4] symbols;
        MultibootAOutSymbolTable aoutSymbolTable;
        MultibootElfSectionHeaderTable elfSectionHeaderTable;
    }

    // Memory map buffer
    multiboot_uint32_t mmapLength;
    multiboot_uint32_t mmapAddress;

    // Drives information
    multiboot_uint32_t drivesLength;
    multiboot_uint32_t drivesAddress;

    // ROM configuration table
    multiboot_uint32_t configTable;

    // String containing the boot loader name
    multiboot_uint32_t bootLoaderName;

    // APM table
    multiboot_uint32_t apmTable;

    // Video information
    multiboot_uint32_t vbeControlInfo;
    multiboot_uint32_t vbeModeInfo;
    multiboot_uint16_t vbeMode;
    multiboot_uint16_t vbeInterfaceSeg;
    multiboot_uint16_t vbeInterfaceOff;
    multiboot_uint16_t vbeInterfaceLen;

    // Framebuffer information
    multiboot_uint64_t framebufferAddress;
    multiboot_uint32_t framebufferPitch;
    multiboot_uint32_t framebufferWidth;
    multiboot_uint32_t framebufferHeight;
    multiboot_uint8_t framebufferBpp;
    MultibootFramebufferType framebufferType;
    union
    {
        multiboot_uint8_t[6] colorInfo;
        struct
        {
            multiboot_uint8_t framebufferRedFieldPosition;
            multiboot_uint8_t framebufferRedMaskSize;
            multiboot_uint8_t framebufferGreenFieldPosition;
            multiboot_uint8_t framebufferGreenMaskSize;
            multiboot_uint8_t framebufferBlueFieldPosition;
            multiboot_uint8_t framebufferBlueMaskSize;
        }
        struct
        {
            multiboot_uint32_t framebufferPaletteAddr;
            multiboot_uint16_t framebufferPaletteNumColors;
        }
    }
}

struct MultibootAOutSymbolTable
{
align(1):
    multiboot_uint32_t tabSize;
    multiboot_uint32_t strSize;
    multiboot_uint32_t address;
    multiboot_uint32_t reserved;
}

static assert(MultibootAOutSymbolTable.sizeof == 16);

struct MultibootElfSectionHeaderTable
{
align(1):
    multiboot_uint32_t num;
    multiboot_uint32_t size;
    multiboot_uint32_t address;
    multiboot_uint32_t index;
}

static assert(MultibootElfSectionHeaderTable.sizeof == 16);

enum MultibootMMapEntryType : multiboot_uint32_t
{
    available       = 1,
    reserved        = 2,
    acpiReclaimable = 3,
    acpiNVS         = 4,
    badMemory       = 5,
}

struct MultibootMMapEntry
{
align(1):
    multiboot_uint32_t size;
    multiboot_uint64_t baseAddress;
    multiboot_uint64_t length;
    MultibootMMapEntryType type;
}

static assert(MultibootMMapEntry.sizeof == 24);

struct MultibootModuleList
{
align(1):
    multiboot_uint32_t moduleStart;
    multiboot_uint32_t moduleEnd;
    multiboot_uint32_t cmdline;
    multiboot_uint32_t reserved;
}

static assert(MultibootModuleList.sizeof == 16);

struct MultibootAPMInfo
{
align(1):
    multiboot_uint16_t version_;
    multiboot_uint16_t cseg;
    multiboot_uint32_t offset;
    multiboot_uint16_t cseg16;
    multiboot_uint16_t dseg;
    multiboot_uint16_t flags;
    multiboot_uint16_t csegLen;
    multiboot_uint16_t cseg16Len;
    multiboot_uint16_t dsegLen;
}

static assert(MultibootAPMInfo.sizeof == 20);
