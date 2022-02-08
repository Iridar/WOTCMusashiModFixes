Created by Iridar

More info here: https://www.patreon.com/Iridar

[WOTC] Musashi's Mod Fixes

Fixes various issues with Musashi's mods:[list]
[*][url=https://steamcommunity.com/sharedfiles/filedetails/?id=1280477867][b]Musashi's RPG Overhaul[/b][/url]
[*][b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=2133399183]True Primary Secondaries[/url][/b][/list]
[*][b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=2133397762]Ability To Slot Reassignment[/url][/b][/list]

If you're using at least one of these mods, make sure to subscribe to this fix to prevent gamebreaking bugs from happening. If you don't have any of these mods, it's still completely safe to subscribe to this mod; it will simply not do anything. 

This mod was previously called [b][WOTC] [/b], but I decided to rename it for convenience.

[h1]True Primary Secondaries and RPG Overhaul[/h1]

Fixed the infamous "duplicate abilities" bug. Other mods can potentially cause this bug as well. I've reached out to authors of all problematic mods I could find, and they have already uploaded the fix for this bug, or are in the process of doing so. 

If you are a modmaker, and you have ever used the [b]CanAddItemToInventory_CH[/b] or [b]CanAddItemToInventory_CH_Improved[/b] DLC hooks in your mods, [b][url=https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/issues/1056#issuecomment-894805512]please carefully read this[/url][/b], and make sure your mods are not being a part of the problem.

[h1]Ability To Slot Reassignment[/h1]

Fixed various typos in default configuration. [b][url=https://steamcommunity.com/workshop/filedetails/discussion/2133397762/3048360012553485872/]Manually fixing config files[/url][/b] is no longer necessary.

It's now possible to have multiple [b][i]WeaponCategorySets[/i][/b] entries for each weapon category set.
Multiple [b][i]AbilityWeaponCategories[/i][/b] and [b][i]MandatoryAbilities[/i][/b] entries for the same ability name and different weapon category set are now allowed.

In other words, the mod can now actually fulfill its intended function and properly support abilities and weapon categories added by other mods.

[b][i]OverrideAbilities[/i][/b] array is now available for both [b][i]AbilityWeaponCategories[/i][/b] and [b][i]MandatoryAbilities[/i][/b]. Current use case is replacing [b][i]SwordSlice[/i][/b] with [b][i]SwordSlice_LW[/i][/b]  as a mandatory ability, if it is available.

[h1]CONTRIBUTIONS[/h1]



[h1]CREDITS[/h1]

Huge thanks to [b]Tenga[/b] of XCOM 2 Modding Discord for figuring out reproduction steps for this bug.

A hearty thank you to my patrons for supporting me throughout the years.

Please support me on [b][url=https://www.patreon.com/Iridar]Patreon[/url][/b] if you require tech support, have a suggestion for a feature, or simply wish to help me create more awesome mods.