# Increased Weapon Ranges - IWR
This mod aim to increase weapon ranges (hancrafted/balanced values) for X4: Foundations.
Only Vanilla Weapons are affected, incl. DLC (except Hyperion and Envoy which I don't have).
It is provided with a generator script which can re-generate assets with the desired factor, angle and speed.

## What it does ?
It increase weapons ranges !

Simply download and install the main file. It's packaged, It's smooth, it will work. **It is a standalone mod, nothing more than the game is needed**.

### Suggestion of mods to use with (as you want)
I can  recommends you to use this mod with borther mods which increase space size and speeds like (there are recommendation, not obligation to run Increased Weapons Ranges)
[XRSGE](https://www.nexusmods.com/x4foundations/mods/1140) : It increase the size of space from 20 to 100, Increased Weapon Ranges takes all its meaning in this mod
[REM HYPERDRIVE](https://www.nexusmods.com/x4foundations/mods/1572) : To use in addition to XRSGE, It allow you ship to travel at very high speeds

## Technically ?
- <bullet> speed and/or lifetime and or angle (spread), depending of weapons type.
- It also affect Missiles/Torpedoes Speed by modifying their engines.
- Space Suit Laser (Gun and Repair) are excluded because you will not shoot very far in EVA anyway.

### Flavour
[REM INERTIAL](https://www.nexusmods.com/x4foundations/mods/1328) : Change the ship physics, it can be a bit clunky, but along side Increased Weapon Ranges, this mod can be a alternative to REM OVERHAUL (see below). Personally, I dont use it anymore because the drift make aiming very hard, AI hardly manage manoeuvers and even Lockboxes drifts while aiming to it :-D

### Alternative
Alternative mods if you don't like Increased Weapon Ranges mod.
First, if you want to change value a little bit and know how to execute a bash script, you can try out "generate.sh".
If what you're looking for is a mod which go further than range,

- For Vanilla Weapons :
	- [Simple Combat Overhaul (SCO)﻿﻿](https://www.nexusmods.com/x4foundations/mods/750) : 
﻿﻿		- This mods is like applying a factor 2 to weapons, but also adjust shield and S ship engines, and so, can't be used with REM HYPERDRIVE

- If you want a total overhaul of ship equipment which is compatible with XRSGE and REM HYPERDRIVE :
	- [REM OVERHAUL﻿](https://www.nexusmods.com/x4foundations/mods/848) :
﻿﻿		- This is the default choice if you want to play [XRSGE](https://www.nexusmods.com/x4foundations/mods/1140) and [REM HYPERDRIVE](https://www.nexusmods.com/x4foundations/mods/1572), with REM OVERHAUL﻿ you don't need REM INERTIAL MOD

- And at last but not least, the famous :
	- [Variety and Rebalance Overhaul (VRO)](https://www.nexusmods.com/x4foundations/mods/305)﻿ :
﻿﻿		- This is the most famous weapons and equipment overhaul, but also, it will not be compatible with any mod of the REM Suite

### The ./generate.sh script
The mod is delivered with a bash script (usable on linux or bash alternative like powershell on Windows) capable of applying rules on files located in "_default" folder. 
You must extract macros from the game files since I removed em from my repository. You maybe can find them in some of my 7z in the release section, prior 1.3.0 (X4 7.60).
It was bloating the repo. If you want a clean extract, you can use X TOOLS. The macro you're looking for are in CAT 07. As for the extensions, often in CAT ext_01.

Simply run ./generate.sh and prompt will ask you if you want to reset to default files before applying the factor it will ask you at the next prompt.

Concerning the generate script, where the most effort has been putted into, it has 3 levels of debug verbosity.
- 0 (no debug) : Will simply generate file without any warning of any sort
- 1 ("-v") : Will warn you if values are too high during the application of the intended factor (or adjusted factor)
- 2 ("-vv") : all that preceed and it will output old range value vs new range value for each file
- 3 ("-vvv") : it's a poke mode only used to debug the code inside the script and not actual value

The script is able to mitigate your factor to balance weapon a bit more and avoir beam kitting forever.
It's also able to detected over-valued ranges and under-valued angle. In fact, It can also apply a factor to ranges and another to angles.
Have a weapons like a shotgun than can shoot far away with the same precision has a railgun isn't really the purpose of this script, but you can try it if you want.
Anyway, the script will prompt you for everything it needs to generate files in a balanced way, that you can simply ignore and do your thing.

## Requirements ?
- None other than the game

## Redistribution and modification

### BSD 2-Clause License

#### Copyright (c) 2025, laryakan

You are free to use, modify and redistribute any code or assets of mine which is not directly extracted from the game as soon as you mention the above Copyright.
A link to my github is provided below. A little mention is all I ask.

- github : https://github.com/laryakan/iwr
- nexus : https://www.nexusmods.com/x4foundations/mods/1691
- nexus user : https://next.nexusmods.com/profile/Laryakan
- other nexus mods : https://www.nexusmods.com/games/x4foundations/mods?author=laryakan
- steam page : https://steamcommunity.com/sharedfiles/filedetails/?id=3487421450
- other steam mods : https://steamcommunity.com/id/laryakan/myworkshopfiles/?appid=392160

