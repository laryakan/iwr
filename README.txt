INCREASED WEAPON RANGES (IWR) by Laryakan
===

This mod aim to increase weapon ranges (hancrafted/balanced values) for X4: Foundations.
Only Vanilla Weapons are affected, incl. DLC (except Hyperion).

Rules applied by default affects :

<bullet> speed and/or lifetime and or angle (spread), depending of weapons type.

It also affect Missiles/Torpedoes Speed by modifying their engines.

Space Suit Laser (Gun and Repair) are excluded because you will not shoot very far in EVA anyway.

This mod have been develop to be use in cunjuction with mod increasing X4: Foundations default space and ship speed, like XRSGE (https://www.nexusmods.com/x4foundations/mods/1140) and REM HYPERDRIVE (https://www.nexusmods.com/x4foundations/mods/1572).
Used with REM INERTIAL MOD (https://www.nexusmods.com/x4foundations/mods/1328), it is a Vanilla alternative to REM OVERHAUL (https://www.nexusmods.com/x4foundations/mods/848) which affect a lot more things than just weapon ranges and ship physics.

You can, of course, use this mod without REM INERTIAL (https://www.nexusmods.com/x4foundations/mods/1328) and REM HYPERDRIVE (https://www.nexusmods.com/x4foundations/mods/1572), but combat may become less understable as weapons will be much more deadly.

The mod is delivered with a bash script (usable on linux or bash alternative like powershell on Windows) capable of applying rules on files located in "_default" folder (by default, only Vanilla ones). Simply run ./generate.sh and prompt will ask you if you want to reset to default files before applying the factor it will ask you at the next prompt.

Concerning the generate script, where the most effort has been putted into, it has 3 levels of debug verbosity.
- 0 (no debug) : Will simply generate file without any warning of any sort
- 1 ("-v") : Will warn you if values are too high during the application of the intended factor (or adjusted factor)
- 2 ("-vv") : all that preceed and it will output old range value vs new range value for each file
- 3 ("-vvv") : it's a poke mode only used to debug the code inside the script and not actual value

The script is able to mitigate your factor to balance weapon a bit more and avoir beam kitting forever.
It's also able to detected over-valued ranges and under-valued angle. In fact, It can also apply a factor to ranges and another to angles.
Have a weapons like a shotgun than can shoot far away with the same precision has a railgun isn't really the purpose of this script, but you can try it if you want.
Anyway, the script will prompt you for everything it needs to generate files in a balanced way, that you can simply ignore and do your thing.

GITHUB REPOSITORY : https://github.com/laryakan/iwr
NEXUS MOD : https://www.nexusmods.com/x4foundations/mods/1691
NEXUS USER : https://next.nexusmods.com/profile/Laryakan
