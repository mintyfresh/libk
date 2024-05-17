module libk.util.bitmap;

import libk.util.type;

enum BitmapInit
{
    initiallyReserved,
    initiallyReleased
}

struct Bitmap(T) if (isUnsigned!(T))
{
    enum size_t bitsPerBlock = 8 * T.sizeof;

private:
    T* _blocks;
    size_t _totalBlocks;
    size_t _totalBits;
    size_t _freeBits;
    size_t _firstFree;

    enum T fullyAvailable = 0;
    enum T fullyReserved = T.max;

    alias block_t = size_t;
    alias bit_t = size_t;

public:
    this(T* blocks, size_t totalBits, BitmapInit init = BitmapInit.initiallyReserved) nothrow @nogc
    {
        _blocks      = blocks;
        _totalBits   = totalBits;
        _totalBlocks = (totalBits / bitsPerBlock)
                     + (totalBits % bitsPerBlock == 0 ? 0 : 1);

        if (init == BitmapInit.initiallyReserved)
        {
            reserveAll();
        }
        else
        {
            releaseAll();
        }
    }

    @property
    size_t totalBits() const nothrow @nogc
    {
        return _totalBits;
    }

    @property
    size_t freeBits() const nothrow @nogc
    {
        return _freeBits;
    }

    bool alloc(out size_t index) nothrow @nogc
    {
        if (_freeBits == 0)
        {
            return false;
        }

        block_t block = indexToBlock(_firstFree);
        bit_t bit = indexToBit(_firstFree);

        for(; block < _totalBlocks; block++, bit = 0)
        {
            // Skip over blocks that are already fully reserved
            if (_blocks[block] == fullyReserved)
            {
                continue;
            }

            for(; bit < bitsPerBlock; bit++)
            {
                if (isBitReserved(block, bit))
                {
                    continue;
                }

                reserveBit(block, bit);
                _freeBits--;

                index = blockBitToIndex(block, bit);

                // Advance the first free bit index
                if (_firstFree == index)
                {
                    _firstFree++;
                }

                return true;
            }
        }

        return false;
    }

    bool free(size_t index) nothrow @nogc
    {
        if (index >= _totalBits)
        {
            return false;
        }

        block_t block = indexToBlock(index);
        bit_t bit = indexToBit(index);

        // Can't free a bit that is already available
        if (!isBitReserved(block, bit))
        {
            return false;
        }

        releaseBit(block, bit);
        _freeBits++;

        // Update the first free bit index
        if (_firstFree > index)
        {
            _firstFree = index;
        }

        return true;
    }

    bool allocAlignedChunk(out size_t index, size_t count) nothrow @nogc
    {
        if (count == 0 || _freeBits < count)
        {
            return false;
        }

        // Count must be aligned to the block size
        if (count % bitsPerBlock != 0)
        {
            return false;
        }

        // Calculate the number of blocks within the chunk
        const size_t blocksCount = count / bitsPerBlock;

        // Search the bitmap from the start in increments of the chunk size
        for (size_t block = 0; block < _totalBlocks; block += blocksCount)
        {
            size_t availableBlocks = 0;

            // Check if the chunk is fully available
            foreach (offset; 0..blocksCount)
            {
                if (_blocks[block + offset] == fullyAvailable)
                {
                    availableBlocks++;
                }
                else
                {
                    break;
                }
            }

            // Not fully available, move onto the next chunk
            if (availableBlocks != blocksCount)
            {
                continue;
            }

            // Reserve the chunk
            foreach (offset; 0..blocksCount)
            {
                _blocks[block + offset] = fullyReserved;
                _freeBits -= bitsPerBlock;
            }

            index = block * bitsPerBlock;

            // Place the first free bit index after the chunk if it was within it
            if (index <= _firstFree && _firstFree <= index + count)
            {
                _firstFree = index + count;
            }

            return true;
        }

        return false;
    }

    bool freeAlignedChunk(size_t index, size_t count) nothrow @nogc
    {
        if (index + count > _totalBits || count == 0)
        {
            return false;
        }

        // Count must be aligned to the block size
        if (count % bitsPerBlock != 0)
        {
            return false;
        }

        // Calculate the number of blocks within the chunk
        const size_t blocksCount = count / bitsPerBlock;
        
        block_t block = indexToBlock(index);

        foreach (offset; 0..blocksCount)
        {
            if (_blocks[block + offset] == fullyReserved)
            {
                _blocks[block + offset] = fullyAvailable;
                _freeBits += bitsPerBlock;
            }
            else
            {
                // NOTE: Something went wrong and there's free bits in the middle of the chunk
                // Quitting here with an error would only make the problem worse by leaving the
                // chunk partially reserved. Instead, just release all the bits that are reserved.
                reserve(blockBitToIndex(block + offset, 0), bitsPerBlock);
            }
        }

        // Update the first free bit index
        if (_firstFree > index)
        {
            _firstFree = index;
        }

        return true;
    }

    bool isAvailable(size_t index) const nothrow @nogc
    {
        if (index >= _totalBits)
        {
            return false;
        }

        return !isReserved(index);
    }

    bool isReserved(size_t index) const nothrow @nogc
    {
        if (index >= _totalBits)
        {
            return false;
        }

        block_t block = indexToBlock(index);
        bit_t bit = indexToBit(index);

        return isBitReserved(block, bit);
    }

    void reserve(size_t index, size_t count) nothrow @nogc
    {
        if (index >= _totalBits || count == 0)
        {
            return;
        }

        block_t block = indexToBlock(index);
        bit_t bit = indexToBit(index);

        for(; block < _totalBlocks && count > 0; block++, bit = 0)
        {
            // Skip over blocks that are already fully reserved
            if (_blocks[block] == fullyReserved)
            {
                count -= (bitsPerBlock - bit);
                continue;
            }

            for(; bit < bitsPerBlock && count > 0; bit++, count--)
            {
                // Nothing to do if the bit is already reserved
                if (isBitReserved(block, bit))
                {
                    continue;
                }

                reserveBit(block, bit);
                _freeBits--;

                if (_firstFree == blockBitToIndex(block, bit))
                {
                    _firstFree++;
                }
            }
        }
    }

    void release(size_t index, size_t count) nothrow @nogc
    {
        if (index >= _totalBits || count == 0)
        {
            return;
        }

        block_t block = indexToBlock(index);
        bit_t bit = indexToBit(index);

        for(; block < _totalBlocks && count > 0; block++, bit = 0)
        {
            // Skip over blocks that are already fully available
            if (_blocks[block] == fullyAvailable)
            {
                count -= (bitsPerBlock - bit);
                continue;
            }

            for(; bit < bitsPerBlock && count > 0; bit++, count--)
            {
                // Nothing to do if the bit is already available
                if (!isBitReserved(block, bit))
                {
                    continue;
                }

                releaseBit(block, bit);
                _freeBits++;

                if (_firstFree > blockBitToIndex(block, bit))
                {
                    _firstFree = blockBitToIndex(block, bit);
                }
            }
        }
    }

    void reserveAll() nothrow @nogc
    {
        foreach (index; 0.._totalBlocks)
        {
            _blocks[index] = fullyReserved;
        }

        _freeBits  = 0;
        _firstFree = _totalBits;
    }

    void releaseAll() nothrow @nogc
    {
        foreach (index; 0.._totalBlocks)
        {
            _blocks[index] = fullyAvailable;
        }

        _freeBits  = _totalBits;
        _firstFree = 0;
    }

private:
    pragma(inline, true)
    bool isBitReserved(block_t block, bit_t bit) const nothrow @nogc
    {
        return (_blocks[block] & (T(1) << bit)) != 0;
    }

    pragma(inline, true)
    void reserveBit(block_t block, bit_t bit) nothrow @nogc
    {
        _blocks[block] |= (T(1) << bit);
    }

    pragma(inline, true)
    void releaseBit(block_t block, bit_t bit) nothrow @nogc
    {
        _blocks[block] &= ~(T(1) << bit);
    }

    pragma(inline, true)
    block_t indexToBlock(size_t index) const pure nothrow @nogc
    {
        return index / bitsPerBlock;
    }

    pragma(inline, true)
    bit_t indexToBit(size_t index) const pure nothrow @nogc
    {
        return index % bitsPerBlock;
    }

    pragma(inline, true)
    size_t blockBitToIndex(block_t block, bit_t bit) const pure nothrow @nogc
    {
        return block * bitsPerBlock + bit;
    }
}

version (unittest)
{
    import core.stdc.stdlib : calloc, free;
    import core.stdc.stdio;
}

unittest
{
    const size_t blocksCount = 10;
    uint* blocks = cast(uint*) calloc(blocksCount, uint.sizeof);
    scope (exit) free(blocks);

    Bitmap!(uint) bitmap = Bitmap!(uint)(blocks, blocksCount * (8 * uint.sizeof));

    assert(bitmap.totalBits == blocksCount * 8 * uint.sizeof);
    assert(bitmap.freeBits == 0, "Bitmap should be initially reserved");
    assert(bitmap.isReserved(0), "First bit should be reserved");
    assert(bitmap.isReserved(bitmap.totalBits - 1), "Last bit should be reserved");
    assert(!bitmap.isReserved(bitmap.totalBits), "Out-of-bounds bit should not be reserved");

    bitmap.releaseAll();
    assert(bitmap.freeBits == bitmap.totalBits, "Bitmap should be fully released");
    assert(!bitmap.isReserved(0), "First bit should be released");
    assert(!bitmap.isReserved(bitmap.totalBits - 1), "Last bit should be released");
    assert(!bitmap.isReserved(bitmap.totalBits), "Out-of-bounds bit should not be reserved");
}

unittest
{
    const size_t blocksCount = 10;
    uint* blocks = cast(uint*) calloc(blocksCount, uint.sizeof);
    scope (exit) free(blocks);

    Bitmap!(uint) bitmap = Bitmap!(uint)(blocks, blocksCount * (8 * uint.sizeof));

    bitmap.release(0, 20);
    assert(bitmap.freeBits == 20, "20 bits should be available");
    assert(bitmap.isAvailable(0), "First bit should be available");
    assert(bitmap.isAvailable(19), "20th bit should be available");
    assert(bitmap.isReserved(20), "21st bit should be reserved");

    bitmap.release(0, 40);
    assert(bitmap.freeBits == 40, "40 bits should be available");
    assert(bitmap.isAvailable(0), "First bit should be available");
    assert(bitmap.isAvailable(39), "40th bit should be available");
    assert(bitmap.isReserved(40), "41st bit should be reserved");

    bitmap.reserve(0, 35);
    assert(bitmap.freeBits == 5, "5 bits should be available");
    assert(bitmap.isReserved(0), "First bit should be reserved");
    assert(bitmap.isReserved(34), "35th bit should be reserved");
    assert(bitmap.isAvailable(35), "36th bit should be available");
    assert(bitmap.isAvailable(39), "40th bit should be available");
    assert(bitmap.isReserved(40), "41st bit should be reserved");
}

unittest
{
    const size_t blocksCount = 10;
    uint* blocks = cast(uint*) calloc(blocksCount, uint.sizeof);
    scope (exit) free(blocks);

    Bitmap!(uint) bitmap = Bitmap!(uint)(blocks, blocksCount * (8 * uint.sizeof));

    size_t index;
    assert(!bitmap.alloc(index), "Should not be able to allocate when all bits are reserved");

    bitmap.release(0, 1);
    assert(bitmap.freeBits == 1, "1 bit should be available");
    assert(bitmap.alloc(index), "Should be able to allocate a single bit");
    assert(bitmap.freeBits == 0, "No more bits should be available");
    assert(index == 0, "First bit should be allocated");

    size_t index2;
    assert(bitmap.freeBits == 0, "No bits should be available");
    assert(!bitmap.alloc(index2), "Should not be able to allocate when all bits are reserved");

    assert(bitmap.free(index), "Should be able to free the first bit");
    assert(bitmap.freeBits == 1, "1 bit should be available");
    assert(!bitmap.free(index), "Should not be able to free an already available bit");
}

unittest
{
    const size_t blocksCount = 512;
    uint* blocks = cast(uint*) calloc(blocksCount, uint.sizeof);
    scope (exit) free(blocks);

    Bitmap!(uint) bitmap = Bitmap!(uint)(blocks, blocksCount * (8 * uint.sizeof), BitmapInit.initiallyReleased);
    assert(bitmap.freeBits == 16_384, "All bits should be available");

    size_t chunk1;
    assert(bitmap.allocAlignedChunk(chunk1, 32 * 32), "Should be able to allocate a 1024-bit chunk");
    assert(chunk1 == 0, "Chunk should start at the first bit");
    assert(bitmap.freeBits == 16_384 - 1024, "1024 bits should be reserved");

    size_t index;
    assert(bitmap.alloc(index), "Should be able to allocate a single bit");
    assert(index == 1024, "First bit should be allocated after the chunk");
    assert(bitmap.freeBits == 16_384 - 1024 - 1, "1025 bits should be reserved");

    size_t chunk2;
    assert(bitmap.allocAlignedChunk(chunk2, 32 * 32), "Should be able to allocate another 1024-bit chunk");
    // NOTE: The chunk at index 1024 is reserved by the single bit allocation above, 2048 is the next boundary
    assert(chunk2 == 2048, "Chunk should start at the next available 1024-bit boundary");
    assert(bitmap.freeBits == 16_384 - 1024 - 1 - 1024, "2049 bits should be reserved");

    size_t chunk3;
    assert(bitmap.free(index), "Should be able to free the first bit");
    assert(bitmap.allocAlignedChunk(chunk3, 32 * 32), "Should be able to allocate another 1024-bit chunk");
    assert(chunk3 == 1024, "Chunk should start at the first available 1024-bit boundary");
    assert(bitmap.freeBits == 16_384 - (3 * 1024), "3072 bits should be reserved");

    assert(bitmap.freeAlignedChunk(chunk1, 32 * 32), "Should be able to free the first chunk");
    assert(bitmap.freeBits == 16_384 - (2 * 1024), "2048 bits should be reserved");
    assert(bitmap.freeAlignedChunk(chunk2, 32 * 32), "Should be able to free the second chunk");
    assert(bitmap.freeBits == 16_384 - 1024, "1024 bits should be reserved");
    assert(bitmap.freeAlignedChunk(chunk3, 32 * 32), "Should be able to free the third chunk");
    assert(bitmap.freeBits == 16_384, "All bits should be available");
}
