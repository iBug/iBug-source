---
title: "Recovering a Minecraft world from a crash, the technician way"
tags: games minecraft
redirect_from: /p/54
header:
  teaser: /image/minecraft/create-mod-1.jpg
  og_image: /image/minecraft/create-mod-1.jpg
---

While a friend was building an automatic brewing pipeline, our [Create: Astral](https://www.curseforge.com/minecraft/modpacks/create-astral) server crashed and wouldn't start again. At first we thought it'd be easy to restore our world from a backup, only to find that the automatic backup mechanism wasn't working at all due to misconfiguration. The last manual backup was taken a few days ago, so reverting to that backup means a lot of progress loss, which is undesirable for us.

## Gathering information

If at all possible, we would like to salvage this broken world, so we start with an investigation of the crash log. It appears to be an infinite recursion with Create.

```text
at com.simibubi.create.foundation.item.ItemHelper.extract(ItemHelper.java:219)
at com.simibubi.create.foundation.item.ItemHelper.extract(ItemHelper.java:223)
at com.simibubi.create.foundation.item.ItemHelper.extract(ItemHelper.java:223)
at com.simibubi.create.foundation.item.ItemHelper.extract(ItemHelper.java:223)
at com.simibubi.create.foundation.item.ItemHelper.extract(ItemHelper.java:223)
at com.simibubi.create.foundation.item.ItemHelper.extract(ItemHelper.java:223)
at com.simibubi.create.foundation.item.ItemHelper.extract(ItemHelper.java:223)
at com.simibubi.create.foundation.item.ItemHelper.extract(ItemHelper.java:223)
```

None of us has any knowledge in Java, but fortunately with [Not Enough Crashes (Fabric)](https://www.curseforge.com/minecraft/mc-mods/not-enough-crashes), the crash log gives a hint on which block is going wrong, as shown below:

```text
-- Block entity being ticked --
Details:
        Name: create:funnel // com.simibubi.create.content.logistics.block.funnel.FunnelTileEntity
        Block: Block{create:brass_funnel}[extracting=true,facing=north,powered=false]
        Block location: World: (-15,65,172), Section: (at 1,1,12 in -1,4,10; chunk contains blocks -16,-64,160 to -1,319,175), Region: (-1,0; contains chunks -32,0 to -1,31, blocks -512,-64,0 to -1,319,511)
        Block: Block{create:brass_funnel}[extracting=true,facing=north,powered=false]
        Block location: World: (-15,65,172), Section: (at 1,1,12 in -1,4,10; chunk contains blocks -16,-64,160 to -1,319,175), Region: (-1,0; contains chunks -32,0 to -1,31, blocks -512,-64,0 to -1,319,511)
Stacktrace:
        at net.minecraft.class_2818$class_5563.method_31703(class_2818.java:670)
        at net.minecraft.class_2818$class_5564.method_31703(class_2818.java:713)
        ...
```

One idea now surfaces: If we can remove or replace with something else the offending block, we can probably fix the save with minimal progress loss.

The following information can be summarized from the above portion of the crash log:

- The offending block is a Brass Funnel from Create
- It's located at (-15,65,172), in chunk (-1,10), section 4 (a vertical 16×16×16 section)
- The block coordinates are (1,1,12) **within the section**
- The region is (-1,0), meaning that the file that contains is `r.-1.0.mca`.

Recalling that Minecraft worlds are also saved in NBT format, I try opening the region file with [nbted](https://github.com/C4K3/nbted), a tool that I previously used to tamper with player data. However, it complains:

```text
Error: Unable to parse r.-1.0.mca, are you sure it's an NBT file?
        caused by: Unknown compression format where first byte is 0
```

This indicates that the region file is not a single, complete NBT file, so I have to look for another tool to handle this.

## Reading the world file

Google-ing for `minecraft region site:github.com` leads me to Fenixin/Minecraft-Region-Fixer, of which an included [NBT library](https://github.com/Fenixin/Minecraft-Region-Fixer/tree/master/nbt) seems promising. I grab this repository and take the `nbt` directory out, throwing away everything else.

The `region.py` file provides a `RegionFile` class that can be used to access region files, so I start playing with it:

```console?lang=python&prompt=>>>%20
>>> import nbt
>>> r = nbt.region.RegionFile('r.-1.0.mca')
>>> r.get_chunk(-1,10)
# Traceback (most recent call last):
KeyError: (-1, 10)
>>> r.get_chunk(31, 10)
<NBTFile with TAG_Compound('') at 0x7f8a8d014eb0>
>>> c = _
```

So this Python library arranges chunks by offset *within the region file*. That's fine.

Now that I have access to an NBT tag, it's time to study its structure. The [Chunk format][chunk-format] page from Minecraft Wiki is the ultimate reference here.

  [chunk-format]: https://minecraft.fandom.com/wiki/Chunk_format

I know that `c` holds the "root tag" of the chunk I'm looking for. This is easily verified:

```console?lang=python&prompt=>>>%20
>>> c['xPos'].value, c['zPos'].value
(-1, 10)
```

I find the vertical section containing the offending block:

```console?lang=python&prompt=>>>%20
>>> [s for s in c['sections'] if s['Y'].value == 4]
[<TAG_Compound('') at 0x7f8a8d44c1c0>]
>>> s = _[0]
```

The [Anvil file format](https://minecraft.fandom.com/wiki/Anvil_file_format) page shows that block data is ordered in YZX order, so I try to find the block data from the `data` key:

```console?lang=python&prompt=>>>%20
>>> s['block_states']['data'][256 + 12*16 + 1]
72624976668147841
```

... which is, unfortunately not something I can decipher.

I look closely to the description of the `data` tag:

> **A packed array** of 4096 indices pointing to the palette, stored in an array of 64-bit integers. \[...\] All indices are the same length: the minimum amount of bytes required to represent the largest index in the palette. \[...\] Since 1.16, the indices are not packed across multiple elements of the array, meaning that if there is no more space in a given 64-bit integer for the next index, it starts instead at the first (lowest) bit of the next 64-bit element.

So not only was that number *not* for a single block, but also was I looking for a wrong index. I need to inspect the block palette first:

```console?lang=python&prompt=>>>%20,...%20
>>> len(s['block_states']['palette'])
95
>>> [(i, b) for i, b in enumerate(s['block_states']['palette'])
...  if b['Name'].value == "create:brass_funnel"]
[(55, <TAG_Compound('') at 0x7f8a8d49d120>), (77, <TAG_Compound('') at 0x7f8a8d49ff40>)]
```

There are two indices allotted for the funnel block, but at this point it cannot be determined which one is correct. I look inside the packed `data` array, recalculating the index from the block coordinates using information above:

```console?lang=python&prompt=>>>%20
>>> s['block_states']['data'][(256 + 12*16 + 1) // 9]
3963735054717000501
>>> i = _
```

Because there are 95 blocks in the palette, 7 bits is enough to hold an index, and a 64-bit integer holds 9 indices. The calculation can be verified by the following:

```console?lang=python&prompt=>>>%20
>>> len(s['block_states']['data'])
456
>>> 456 * 9
4104
# just slightly over 4096
```

Now I unpack that large integer into 9 indices, and try to translate them into blocks:

```console?lang=python&prompt=>>>%20,...%20
>>> [(i >> (7*x)) & 0x7F for x in range(9)]
[53, 54, 46, 1, 1, 1, 1, 1, 55]
>>> [s['block_states']['palette'][((i >> (7*x)) & 0x7F)]['Name'].value
...  for x in range(9)]
['create:spout',
 'create:mechanical_pump',
 'tconstruct:seared_drain',
 'minecraft:air',
 'minecraft:air',
 'minecraft:air',
 'minecraft:air',
 'minecraft:air',
 'create:brass_funnel']
```

It starts to make sense now. I can recall a [Smeltery](https://tinkers-construct.fandom.com/wiki/Smeltery) structure that we built together near this area.

## Replacing the block

The offending Brass Funnel is the last index within this packed 64-bit integer. I can replace it with air (index = 1) using bit manipulation:

```console?lang=python&prompt=>>>%20
>>> ii = i ^ ((55 ^ 1) << (7*8))
>>> ii
72624976668891957
>>> s['block_states']['data'][(256 + 12*16 + 1) // 9] = ii
```

Now I try to save the file, only to find that `nbt.region.RegionFile` offers no `.save()` or `.write()` methods:

```console?lang=python&prompt=>>>%20
>>> f.<TAB><TAB>
f.STATUS_CHUNK_IN_HEADER           f.get_chunk_coords()
f.STATUS_CHUNK_MISMATCHED_LENGTHS  f.get_chunks()
f.STATUS_CHUNK_NOT_CREATED         f.get_metadata()
f.STATUS_CHUNK_OK                  f.get_nbt(
f.STATUS_CHUNK_OUT_OF_FILE         f.get_size()
f.STATUS_CHUNK_OVERLAPPING         f.get_timestamp(
f.STATUS_CHUNK_ZERO_LENGTH         f.header
f.chunk_count()                    f.iter_chunks()
f.chunk_headers                    f.iter_chunks_class()
f.chunkclass                       f.loc
f.close()                          f.metadata
f.closed                           f.size
f.file                             f.unlink_chunk(
f.filename                         f.write_blockdata(
f.get_blockdata(                   f.write_chunk(
f.get_chunk(
```

<i class="fas fa-fw fa-lightbulb"></i> In my original attempt, I took a diversion from the right track, forgetting that each chunk comes in a single-root NBT tag, and that the region file *packs* multiple chunks into a single file. I only realized that the file format was different from what I expected at first after multiple failed attempts to modify the file using a hex editor.
{: .notice--primary}

Reading [Region file format](https://minecraft.fandom.com/wiki/Region_file_format), I learn that each chunk is compressed (using Zlib) separately and stored together in the region file, and that `f.write_chunk` is the method I am looking for.

```console?lang=python&prompt=>>>%20
>>> f.write_chunk(31, 10, c)
>>>
```

The file size is reduced by some 60 KB. Considering that compression algorithm provides no guarantee on the size of the compressed data, this is not an indicator whether the file's going well or not. The only way to verify is to load the world and check the result in game.

With uncertainty, I make a backup of the broken world, and replace `r.-1.0.mca` with my modified copy. The server now starts normally, and I can see the brass funnel disappeared.

![Block removed](/image/minecraft/createastral-1.jpg)

## Extra tests

To convince myself that I have successfully changed the correct block, I decide that I need to replace it with something visible, not just air. I look inside the palette of the section, and found a few blocks available for use.

```console?lang=python&prompt=>>>%20
>>> s['block_states']['palette'][25]['Name']
minecraft:grass_block
>>> ii = i ^ ((55 ^ 25) << (7*8))
>>> s['block_states']['data'][(256 + 12*16 + 1) // 9] = ii
>>> f.write_chunk(31, 10, c)
```

I then copy the file back to the server, and start it again. As expected, the block at that coordinate is now a grass block.

![Block replaced with Grass Block](/image/minecraft/createastral-2.jpg)

## Additional information

According to [Chunk format][chunk-format], block entities are stored in a `block_entity` tag under the root tag of the chunk. It's possible to inspect the block entity data for the offending Brass Funnel, using information provided under the [Block entity format](https://minecraft.fandom.com/wiki/Chunk_format#Block_entity_format) section.

```console?lang=python&prompt=>>>
>>> len(c['block_entities'])
420
>>> c['block_entities'][0]['x'].value
-14
```

So the coordinates for block entities are absolute, not relative to the chunk. Now find the Brass Funnel:

```console?lang=python&prompt=>>>%20,...%20
>>> [be for be in c['block_entities']
...  if be['x'].value == -15 and be['y'].value == 65 and be['z'].value == 172]
[<TAG_Compound('') at 0x7f8a8d4afd30>]
>>> be = _[0]
>>> be.keys()
['z', 'x', 'TransferCooldown', 'id', 'y', 'FilterAmount', 'keepPacked', 'Filter']
```

More than half of these keys are familiar: They are common to all block entities. Another one `TransferCooldown` is also present for Hoppers. The names of the remaining two tags are self-explanatory.

```console?lang=python&prompt=>>>
>>> be['FilterAmount'].value
2
>>> be['Filter']
<TAG_Compound('Filter') at 0x7f8a8d1000a0>
>>> be['Filter'].keys()
['id', 'tag', 'Count']
```

So the `Filter` key is an item. In my case it's a [Filter](https://create.fandom.com/wiki/Filter) (normal filter, crafted with Iron Nuggets). The contents of the filter can be further inspected:

```console?lang=python&prompt=>>>%20
>>> be['Filter']['tag'].keys()
['RespectNBT', 'Blacklist', 'Items']
>>> be['Filter']['tag']['Blacklist'].value
1
>>> be['Filter']['tag']['Items']
<TAG_Compound('Items') at 0x7f8a8d100070>
>>> be['Filter']['tag']['Items'].keys()
['Size', 'Items']
>>> be['Filter']['tag']['Items']['Items']
2 entries of type TAG_Compound
>>> be['Filter']['tag']['Items']['Items'][0]
<TAG_Compound('') at 0x7f8a8d1003d0>
>>> be['Filter']['tag']['Items']['Items'][0].keys()
['Slot', 'id', 'Count']
>>> [it['id'] for it in be['Filter']['tag']['Items']['Items']]
[create:cinder_flour, minecraft:glass_bottle]
```

Now the mystery has been completely uncovered. The Brass Funnel is configured to take everything but Cinder Flour and Glass Bottles, 2 at a time. Considering that the Depot behind is part of a brewing system, there will be brewed Potions, which are unstackable. A friend helped us find the GitHub issue [<i class="fab fa-github"></i> Create#570](https://github.com/Fabricators-of-Create/Create/issues/570), confirming that we ran into the same bug as reported in that thread.

## Epilogue

The use of block/item names since Java Edition 1.7.2 ([13w37a](https://minecraft.fandom.com/wiki/Java_Edition_13w37a)) hinted that block/item IDs would eventually become dynamic, which actually took place in [the Flattening](https://minecraft.fandom.com/wiki/Java_Edition_1.13/Flattening) in Java Edition 1.13. The smart use of the "palette + array of indices" paves the way for mods and future expansions to add new blocks without having to worry about the block ID limit, which is also reminiscent of the [color table](https://en.wikipedia.org/wiki/BMP_file_format#Color_table) in 8-bit (256 colors) BMP bitmap images.

Contrary to player data (`playerdata/*.dat`), the region file is a lot more complicated. Thanks to the large fan base of Minecraft, libraries for handling the file format are readily available. I am inclined to believe that a few steps taken and decisions made here are critical to the success of salvaging our save.

- First and foremost, checking the logs: We know which block is going wrong, and *have faith in ourselves that we can fix it*.
- Looking in the correct direction: Instead of using a complete "world edit" tool, we decide to find some library on GitHub and improvise from there.
- Reading the documentation carefully and in detail.
- Doing math correctly (LOL...)

Finally, I want to credit my friend [sirius](https://sirius1242.github.io/) for his unsurpassed knowledge of Minecraft, without whose help I would not have been able to take on this wonderful adventure.
