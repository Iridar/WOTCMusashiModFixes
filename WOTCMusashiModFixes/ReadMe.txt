Created by Iridar

More info here: https://www.patreon.com/Iridar

[WOTC] Musashi's Mods Fixes

Fixes various issues with Musashi's mods:[list]
[*][url=https://steamcommunity.com/sharedfiles/filedetails/?id=1280477867][b]Musashi's RPG Overhaul[/b][/url]
[*][b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=2133399183]True Primary Secondaries[/url][/b]
[*][b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=2133397762]Ability To Slot Reassignment[/url][/b][/list]

If you're using at least one of these mods, make sure to subscribe to this fix to prevent gamebreaking bugs from happening. If you don't have any of these mods, it's still completely safe to subscribe to this mod; it will simply not do anything. 

This mod was previously called [b][WOTC] TPS and RPGO Items Fix[/b], but I decided to rename it for convenience.

[h1]True Primary Secondaries and RPG Overhaul[/h1]

Fixed the infamous "duplicate abilities" bug. Other mods can potentially cause this bug as well. I've reached out to authors of all problematic mods I could find, and hopefully they have already uploaded the fix for this bug. 

If you are a modmaker, and you have ever used the [b]CanAddItemToInventory_CH[/b] or [b]CanAddItemToInventory_CH_Improved[/b] DLC hooks in your mods, [b][url=https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/issues/1056#issuecomment-894805512]please carefully read this[/url][/b], and make sure your mods are not being a part of the problem.

[h1]Ability To Slot Reassignment[/h1]
[list]
[*] Fixed various typos in default configuration. [b][url=https://steamcommunity.com/workshop/filedetails/discussion/2133397762/3048360012553485872/]Manually fixing config files[/url][/b] is no longer necessary.
[*] It's now possible to have multiple [b][i]WeaponCategorySets[/i][/b] entries for each weapon set.
[*] Multiple [b][i]AbilityWeaponCategories[/i][/b] and [b][i]MandatoryAbilities[/i][/b] entries for the same ability name and different weapon category set are now allowed.
[*] [b][i]OverrideAbilities[/i][/b] array is now available for both [b][i]AbilityWeaponCategories[/i][/b] and [b][i]MandatoryAbilities[/i][/b]. Current use case is replacing [b][i]SwordSlice[/i][/b] with [b][i]SwordSlice_LW[/i][/b] as a mandatory ability, if it is available.
[*] Valid weapon categories for each configured ability will now be listed in ability description.[/list]

[h1]CONTRIBUTIONS[/h1]

I will be ignoring comment requests to fix other bugs in RPG Overhaul, but other modmakers are welcome to contribute more fixes through [b][url=https://github.com/Iridar/WOTCMusashiModFixes]GitHub[/url][/b]. 

[h1]CREDITS[/h1]

Huge thanks to [b]Tenga[/b] of XCOM 2 Modding Discord for figuring out reproduction steps for the duplicate items bug, which has eluded the modmakers for years.

Thanks to [b]RustyDios[/b] for listing known issues and fixes for Ability to Slot Reassignment.

A hearty thank you to my patrons for supporting me throughout the years.

Please support me on [b][url=https://www.patreon.com/Iridar]Patreon[/url][/b] if you require tech support, have a suggestion for a feature, or simply wish to help me create more awesome mods.