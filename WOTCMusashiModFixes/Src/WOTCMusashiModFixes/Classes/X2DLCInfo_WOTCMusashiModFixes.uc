class X2DLCInfo_WOTCMusashiModFixes extends X2DownloadableContentInfo;

// This DLC Info runs *before* AtSR.

struct AbilityOverrideStruct
{
	var name AbilityName;
	var name OverrideWithAbilityName;
};

var config(AbilityToSlotReassignment) array<AbilityOverrideStruct> OverrideAbilities;
var config(AbilityToSlotReassignment) bool bLog;

var private class<X2DownloadableContentInfo> DLCInfo_TPS;
var private class<X2DownloadableContentInfo> DLCInfo_RPGO;

var private config array<name> AbilitiesWithUpdatedLocalization;

`define LLOG(msg) `LOG(GetFuncName() @ `msg, class'WOTCMusashiModFixes_Defaults'.default.VERSION_CFG > class'WOTCMusashiModFixes_MCMScreen'.default.VERSION_CFG ? class'WOTCMusashiModFixes_Defaults'.default.DEBUG_LOGGING : class'WOTCMusashiModFixes_MCMScreen'.default.DEBUG_LOGGING, 'AtSR_Fixes')

`include(WOTCMusashiModFixes\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

static event OnPostTemplatesCreated()
{
	CacheCDOs();

	if (IsModActive('AbilityToSlotReassignment'))
	{
		FixDefaultConfigEntries();

		// Allow adding weapon categories into a weapon set with multiple lines,
		// and allow an ability to reference multiple weapon sets.
		CompileWeaponCategorySets();
		CompileAbilityWeaponCategories();
		CompileWeaponCategorySets(); // Repeat in case CompileAbilityWeaponCategories() created duplicates.

		AddAdditionalMandatoryAbilities();
		AddAdditionalAbilityWeaponCategories();
		PerformOverrideAbilities();
		
		// Remove entries that reference abilities that are not currently present in the game.
		ValidateAbilities();
		ValidateWeaponCategories();
		ValidateWeaponCategorySets();

		// If an ability requires specific weapon categories,
		// add these categories to its description.
		if (`GETMCMVAR(SHOW_VALID_WEAPON_CATEGORIES))
		{
			UpdateAbilityLocalization();
		}
	}
}

static private function PerformOverrideAbilities()
{
	local name OverrideAbility;
	local int i;

	for (i = class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories.Length - 1; i >= 0; i--)
	{	
		OverrideAbility = GetOverrideAbility(class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].AbilityName);
		if (OverrideAbility != '')
		{
			`LLOG("Replacing:" @ class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].AbilityName @ "with:" @ OverrideAbility);
			class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].AbilityName = OverrideAbility;
		}
	}

	for (i = class'AbilityToSlotReassignmentLib'.default.MandatoryAbilities.Length - 1; i >= 0; i--)
	{	
		OverrideAbility = GetOverrideAbility(class'AbilityToSlotReassignmentLib'.default.MandatoryAbilities[i].AbilityName);
		if (OverrideAbility != '')
		{
			`LLOG("Replacing:" @ class'AbilityToSlotReassignmentLib'.default.MandatoryAbilities[i].AbilityName @ "with:" @ OverrideAbility);
			class'AbilityToSlotReassignmentLib'.default.MandatoryAbilities[i].AbilityName = OverrideAbility;
		}
	}
}

// ------------------------------------------------------------------------------------------
// If a Mandatory Ability has Additional Abilities specified in its template, make those additional abilities mandatory as well.
// ...and additional abilities of those additional abilities, ad infinitum.

static private function AddAdditionalMandatoryAbilities()
{
	local X2AbilityTemplateManager Mgr;
	local int i;

	Mgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	for (i = class'AbilityToSlotReassignmentLib'.default.MandatoryAbilities.Length - 1; i >= 0; i--)
	{	
		InsertAdditionalAbilitiesRecursive(class'AbilityToSlotReassignmentLib'.default.MandatoryAbilities[i].AbilityName, 
										   class'AbilityToSlotReassignmentLib'.default.MandatoryAbilities[i].WeaponCategorySetName, Mgr);
	}
}

static private function InsertAdditionalAbilitiesRecursive(const name MandatoryAbilityName, const name WeaponSetName, X2AbilityTemplateManager Mgr)
{
	local X2AbilityTemplate		MandatoryAbilityTemplate;
	local X2AbilityTemplate		AdditionalAbilityTemplate;
	local name					AdditionalAbilityName;
	local int					LastElementIndex;

	MandatoryAbilityTemplate = Mgr.FindAbilityTemplate(MandatoryAbilityName);
	if (MandatoryAbilityTemplate != none)
	{
		foreach MandatoryAbilityTemplate.AdditionalAbilities(AdditionalAbilityName)
		{
			AdditionalAbilityTemplate = Mgr.FindAbilityTemplate(AdditionalAbilityName);
			if (AdditionalAbilityTemplate != none)
			{
				if (!DoesMandatoryAbilityEntryExist(AdditionalAbilityName, WeaponSetName))
				{
					LastElementIndex = class'AbilityToSlotReassignmentLib'.default.MandatoryAbilities.Length;
					class'AbilityToSlotReassignmentLib'.default.MandatoryAbilities.Add(1);
					class'AbilityToSlotReassignmentLib'.default.MandatoryAbilities[LastElementIndex].AbilityName = AdditionalAbilityName;
					class'AbilityToSlotReassignmentLib'.default.MandatoryAbilities[LastElementIndex].WeaponCategorySetName = WeaponSetName;
				}
				InsertAdditionalAbilitiesRecursive(AdditionalAbilityName, WeaponSetName, Mgr);
			}
		}
	}
}

static private function bool DoesMandatoryAbilityEntryExist(const name MandatoryAbilityName, const name WeaponSetName)
{
	local int i;

	for (i = class'AbilityToSlotReassignmentLib'.default.MandatoryAbilities.Length - 1; i >= 0; i--)
	{	
		if (class'AbilityToSlotReassignmentLib'.default.MandatoryAbilities[i].AbilityName == MandatoryAbilityName &&
			class'AbilityToSlotReassignmentLib'.default.MandatoryAbilities[i].WeaponCategorySetName == WeaponSetName)
		{
			return true;
		}
	}
	return false;
}

// ---------------------------------------------------------------------------------------------------------------------
// Now do the same for ability weapon categories array.. zzz....
static private function AddAdditionalAbilityWeaponCategories()
{
	local X2AbilityTemplateManager Mgr;
	local int i;

	Mgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	for (i = class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories.Length - 1; i >= 0; i--)
	{	
		InsertAdditionalAbilityWeaponCatRecursive(class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].AbilityName, 
												  class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].WeaponCategorySetName, Mgr);
	}
}

static private function InsertAdditionalAbilityWeaponCatRecursive(const name AbilityWeaponCatName, const name WeaponSetName, X2AbilityTemplateManager Mgr)
{
	local X2AbilityTemplate		AbilityWeaponCatTemplate;
	local X2AbilityTemplate		AdditionalAbilityTemplate;
	local name					AdditionalAbilityName;
	local int LastElementIndex;

	AbilityWeaponCatTemplate = Mgr.FindAbilityTemplate(AbilityWeaponCatName);
	if (AbilityWeaponCatTemplate != none)
	{
		foreach AbilityWeaponCatTemplate.AdditionalAbilities(AdditionalAbilityName)
		{
			AdditionalAbilityTemplate = Mgr.FindAbilityTemplate(AdditionalAbilityName);
			if (AdditionalAbilityTemplate != none)
			{

				if (!DoesAbilityWeaponCatEntryExist(AdditionalAbilityName, WeaponSetName))
				{
					LastElementIndex = class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories.Length;
					class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories.Add(1);
					class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[LastElementIndex].AbilityName = AdditionalAbilityName;
					class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[LastElementIndex].WeaponCategorySetName = WeaponSetName;
				}
				InsertAdditionalAbilityWeaponCatRecursive(AdditionalAbilityName, WeaponSetName, Mgr);
			}
		}
	}
}

static private function bool DoesAbilityWeaponCatEntryExist(const name AbilityName, const name WeaponSetName)
{
	local int i;

	for (i = class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories.Length - 1; i >= 0; i--)
	{	
		if (class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].AbilityName == AbilityName &&
			class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].WeaponCategorySetName == WeaponSetName)
		{
			return true;
		}
	}
	return false;
}

// =====================================================================================================================

static private function name GetOverrideAbility(const name AbilityName)
{
	local int i;

	for (i = default.OverrideAbilities.Length - 1; i >= 0; i--)
	{
		if (default.OverrideAbilities[i].AbilityName == AbilityName && IsAbilityValid(default.OverrideAbilities[i].OverrideWithAbilityName))
		{
			return default.OverrideAbilities[i].OverrideWithAbilityName;
		}
	}

	return '';
}

static private function ValidateWeaponCategorySets()
{
	local int i;

	for (i = class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories.Length - 1; i >= 0; i--)
	{	
		if (!IsWeaponCategorySetValid(class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].WeaponCategorySetName))
		{
			`LLOG("AbilityWeaponCategories entry:" @ class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].AbilityName @ "does not belong to a valid Weapon Category Set:" @ class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].WeaponCategorySetName @ ", removing.");
			class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories.Remove(i, 1);
		}
	}

	for (i = class'AbilityToSlotReassignmentLib'.default.MandatoryAbilities.Length - 1; i >= 0; i--)
	{	
		if (!IsWeaponCategorySetValid(class'AbilityToSlotReassignmentLib'.default.MandatoryAbilities[i].WeaponCategorySetName))
		{
			`LLOG("MandatoryAbilities entry:" @ class'AbilityToSlotReassignmentLib'.default.MandatoryAbilities[i].AbilityName @ "does not belong to a valid Weapon Category Set:" @ class'AbilityToSlotReassignmentLib'.default.MandatoryAbilities[i].WeaponCategorySetName @ ", removing.");
			class'AbilityToSlotReassignmentLib'.default.MandatoryAbilities.Remove(i, 1);
		}
	}
}

static private function bool IsWeaponCategorySetValid(const name WeaponCategorySetName)
{
	local int i;

	for (i = 0; i < class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets.Length; i++)
	{
		if (class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets[i].WeaponCategorySetName == WeaponCategorySetName &&
			class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets[i].WeaponCategories.Length != 0) // Shouildn't be necessary, but just in case.
		{
			return true;
		}
	}
	return false;
}

static private function ValidateWeaponCategories()
{
	local int i;
	local int j;

	for (i = class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets.Length - 1; i >= 0; i--)
	{	
		for (j = class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets[i].WeaponCategories.Length - 1; j >= 0; j--)
		{
			if (!IsWeaponCategoryValid(class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets[i].WeaponCategories[j]))
			{
				`LLOG("Weapon Category:" @ class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets[i].WeaponCategories[j] @ "in Weapon Category Set:" @ class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets[i].WeaponCategorySetName @ "is invalid, removing.");
				class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets[i].WeaponCategories.Remove(j, 1);
			}
		}

		if (class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets[i].WeaponCategories.Length == 0)
		{
			`LLOG("Weapon Category Set:" @ class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets[i].WeaponCategorySetName @ "contains no valid weapon categories, removing.");
			class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets.Remove(i, 1);
		}
	}
}

static private function bool IsWeaponCategoryValid(const name WeaponCat)
{
	local X2ItemTemplateManager	Mgr;
	local X2WeaponTemplate		WeaponTemplate;
	local X2DataTemplate		DataTemplate;

	Mgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach Mgr.IterateTemplates(DataTemplate)
	{
		WeaponTemplate = X2WeaponTemplate(DataTemplate);
		if (WeaponTemplate != none && WeaponTemplate.WeaponCat == WeaponCat)
		{
			return true;
		}
	}
	return false;
}

static private function ValidateAbilities()
{
	local int i;

	for (i = class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories.Length - 1; i >= 0; i--)
	{
		if (!IsAbilityValid(class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].AbilityName))
		{
			`LLOG("AbilityWeaponCategories entry references an invalid Ability:" @ class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].AbilityName @ ", removing");
			class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories.Remove(i, 1);
		}
	}

	for (i = class'AbilityToSlotReassignmentLib'.default.MandatoryAbilities.Length - 1; i >= 0; i--)
	{
		if (!IsAbilityValid(class'AbilityToSlotReassignmentLib'.default.MandatoryAbilities[i].AbilityName))
		{
			`LLOG("MandatoryAbilities entry references an invalid Ability:" @ class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].AbilityName @ ", removing");
			class'AbilityToSlotReassignmentLib'.default.MandatoryAbilities.Remove(i, 1);
		}
	}	
}

static private function bool IsAbilityValid(const name TemplateName)
{
	local X2AbilityTemplateManager Mgr;
	local X2AbilityTemplate AbilityTemplate;
	local string DummyString;

	Mgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	AbilityTemplate = Mgr.FindAbilityTemplate(TemplateName);

	return AbilityTemplate != none && AbilityTemplate.ValidateTemplate(DummyString);
}


// Latest default config in ASR has a lot of typos and other issues, this fixes them.
static private function FixDefaultConfigEntries()
{
	local int i;
	local int j;

	for (i = 0; i < class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories.Length; i++)
	{
		// Long Watch
		if (class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].AbilityName == 'LongWatch' &&
			class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].WeaponCategorySetName == 'SiperRifles')
		{
			class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].WeaponCategorySetName = 'PrecisionRifles';
		}

		// Rapid Fire
		if (class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].AbilityName == 'RapidFire' &&
			class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].WeaponCategorySetName == 'Rifles')
		{
			class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].WeaponCategorySetName = 'AllMainWeapons';
		}

		// Sharpshooter Aim
		if (class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].AbilityName == 'SharpshooterAim' &&
			class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].WeaponCategorySetName == 'PrecisionRifles')
		{
			class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].WeaponCategorySetName = 'AllMainWeapons';
		}

		// Serial (InTheZone)
		if (class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].AbilityName == 'InTheZone' &&
			class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].WeaponCategorySetName == 'PrecisionRifles')
		{
			class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].WeaponCategorySetName = 'AllMainWeapons';
		}

		// Demolition. Celatid Turrets' weapon is "rifle", so this will fix Demolition being removed from them.
		if (class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].AbilityName == 'Demolition' &&
			class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].WeaponCategorySetName == 'Cannon')
		{
			class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].WeaponCategorySetName = 'AllMainWeapons';
		}
	}

	// Replace 'psionicrepeater' with 'psionicReaper'
	for (i = 0; i < class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets.Length; i++)
	{	
		for (j = class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets[i].WeaponCategories.Length - 1; j >= 0; j--)
		{
			if (class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets[i].WeaponCategories[j] == 'psionicrepeater')
			{
				class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets[i].WeaponCategories[j] = 'psionicReaper';
			}
		}
	}
}

// This function in ASR that gets a list of weapon categories available for a certain weapon set works on the Find() basis,
// so it's not possible to have multiple WeaponCategorySets entries that mention the same SetName, 
// only the first one will be read, and the rest will be ignored.
/*
public static function array<name> GetWeaponCategoriesFromSet(name WeaponCategorySetName)
{
	local int Index;
	local array<name> EmptyArray;

	Index = default.WeaponCategorySets.Find('WeaponCategorySetName', WeaponCategorySetName);
	if (Index != INDEX_NONE)
	{
		return default.WeaponCategorySets[Index].WeaponCategories;
	}

	EmptyArray.Length = 0;
	return EmptyArray;
}
*/
// To address the issue, I compile all WeaponCategorySets entries to make sure each unique SetName appears only once, 
// and Weapon Categories entries from other entries with the matching SetName are added into it.
static private function CompileWeaponCategorySets()
{
	local name SetName;
	local name WeaponCat;
	local int i;
	local int j;

	for (i = 0; i < class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets.Length; i++)
	{	
		SetName = class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets[i].WeaponCategorySetName;

		// The i-th member of the list will now serve as the "primary" WeaponCategorySets entry for this SetName.
		// Compile all other entries with this SetName into i-th one.
				
		for (j = class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets.Length - 1; j >= 0; j--)
		{
			if (class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets[j].WeaponCategorySetName != SetName)
				continue;

			if (i == j)
				continue;

			// If we're here, then this j-th entry has the same SetName as the i-th one.
			foreach class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets[j].WeaponCategories(WeaponCat)
			{
				if (class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets[i].WeaponCategories.Find(WeaponCat) != INDEX_NONE)
					continue;

				class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets[i].WeaponCategories.AddItem(WeaponCat);
			}

			class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets.Remove(j, 1);
		}

		// At this point the list should contain only one entry with this SetName.
	}
}

// Similar issue exists for AbilityWeaponCategories config array, where a single Ability Template can belong only to one weapon set.
/*
ConfigIndex = default.AbilityWeaponCategories.Find('AbilityName', SetupData[Index].TemplateName);
*/
// To address this, I collect all AbilityWeaponCategories for each unique AbilityName,
// and create a new WeaponSet, with a new SetName unique to this ability.
// The new WeaponSet will contain weapon categories from all Sets assigned to this AbilityName.
static private function CompileAbilityWeaponCategories()
{	
	local name AbilityName;
	local name SetName;
	local array<name> SetNamesToCompile;
	local int i;
	local int j;

	for (i = 0; i < class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories.Length; i++)
	{
		AbilityName = class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].AbilityName;

		SetNamesToCompile.Length = 0;
		SetName = class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].WeaponCategorySetName;
		SetNamesToCompile.AddItem(SetName);

		for (j = class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories.Length - 1; j >= 0; j--)
		{
			if (class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[j].AbilityName != AbilityName)
				continue;

			// Skip perfect duplicates, I guess
			if (class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].WeaponCategorySetName == class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[j].WeaponCategorySetName)
				continue;
			
			if (i == j)
				continue;

			// If we're here, we found an additional entry for this Ability Template.
			SetName = class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[j].WeaponCategorySetName;
			SetNamesToCompile.AddItem(SetName);

			class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories.Remove(j, 1);
		}

		if (SetNamesToCompile.Length > 1)
		{
			class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].WeaponCategorySetName = CompileWeaponSetsForAbility(AbilityName, SetNamesToCompile);
		}
	}
}

static private function name CompileWeaponSetsForAbility(const name AbilityName, const array<name> SetNamesToCompile)
{
	local array<name> CompiledWeaponCategories;
	local name WeaponCat;
	local name SetName;
	local int Index;

	// Gather all Weapon Categories from all SetNamesToCompile
	foreach SetNamesToCompile(SetName)
	{
		Index = class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets.Find('WeaponCategorySetName', SetName);
		if (Index == INDEX_NONE)
			continue;

		foreach class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets[Index].WeaponCategories(WeaponCat)
		{	
			if (CompiledWeaponCategories.Find(WeaponCat) == INDEX_NONE)
			{
				CompiledWeaponCategories.AddItem(WeaponCat);
			}
		}
	}

	// Put them all into a new Weapon Set.
	Index = class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets.Length;
	class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets.Add(1);
	class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets[Index].WeaponCategorySetName = name(AbilityName $ "_SetName");
	class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets[Index].WeaponCategories = CompiledWeaponCategories;

	return class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets[Index].WeaponCategorySetName;
}

static private function UpdateAbilityLocalization()
{
	local X2AbilityTemplateManager	Mgr;
	local X2AbilityTemplate			AbilityTemplate;
	local name						AbilityName;
	local int i;

	Mgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	for (i = class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories.Length - 1; i >= 0; i--)
	{
		AbilityName = class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].AbilityName;
		if (default.AbilitiesWithUpdatedLocalization.Find(AbilityName) == INDEX_NONE)
		{
			AbilityTemplate = Mgr.FindAbilityTemplate(AbilityName);

			if (AbilityTemplate != none)
			{
				AbilityTemplate.LocLongDescription $= "\n" $ GetLocalizedCategoriesFromWeaponSet(class'AbilityToSlotReassignmentLib'.default.AbilityWeaponCategories[i].WeaponCategorySetName);
			}

			// Make sure localization is updated for each ability only once.
			default.AbilitiesWithUpdatedLocalization.AddItem(AbilityName);
		}
	}
}

static private function string GetLocalizedCategoriesFromWeaponSet(const name WeaponCategorySetName)
{
	local string ReturnString;
	local int i;
	local int j;

	for (i = 0; i < class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets.Length; i++)
	{
		if (class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets[i].WeaponCategorySetName == WeaponCategorySetName)
		{
			for (j = 0; j < class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets[i].WeaponCategories.Length; j++)
			{
				// Add a comma before a new weapon cat entry if this is not a first weapon cat being added.
				if (ReturnString != "")
				{
					ReturnString $= ", ";
				}
				ReturnString $= Locs(GetFriendlyNameForWeaponCat(class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets[i].WeaponCategories[j]));
			}
			// WeaponCategorySetName entries should be unique at this point.
			break;
		}
	}
	return class'UIUtilities_Text'.static.GetColoredText(ReturnString, eUIState_Warning); // Yellow color.
}

static private function string GetFriendlyNameForWeaponCat(const name WeaponCat)
{
	local X2ItemTemplateManager		ItemMgr;
	local X2WeaponTemplate			WeaponTemplate;
	local X2DataTemplate			DataTemplate;
	local X2ItemTemplate			ItemTemplate;
	local string					LocCat;

	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	// Use in-game item localization for unlocalized base game weapon cats.
	switch (WeaponCat)
	{
		case 'utility':
			return class'UIArmory_Loadout'.default.m_strInventoryLabels[eInvSlot_Utility];
		case 'heavy':
			return class'UIArmory_Loadout'.default.m_strInventoryLabels[eInvSlot_HeavyWeapon];
		case 'grenade_launcher':
			ItemTemplate = ItemMgr.FindItemTemplate('GrenadeLauncher_CV');
			if (ItemTemplate != none)
				return ItemTemplate.FriendlyName;
			break;
		case 'gremlin':
			ItemTemplate = ItemMgr.FindItemTemplate('Gremlin_CV');
			if (ItemTemplate != none)
				return ItemTemplate.FriendlyName;
			break;
		case 'vektor_rifle':
			ItemTemplate = ItemMgr.FindItemTemplate('VektorRifle_CV');
			if (ItemTemplate != none)
				return ItemTemplate.FriendlyName;
			break;
		//case 'bullpup':
		//	ItemTemplate = ItemMgr.FindItemTemplate('Bullpup_CV'); 
		//	if (ItemTemplate != none)
		//		return ItemTemplate.FriendlyName; "Kal-7 Bullpup" ugh
		//	break;
		case 'sparkrifle':
			ItemTemplate = ItemMgr.FindItemTemplate('SparkRifle_CV');
			if (ItemTemplate != none)
				return ItemTemplate.FriendlyName; // "Heavy Autocannon"
			break;
		case 'claymore':
			ItemTemplate = ItemMgr.FindItemTemplate('Reaper_Claymore');
			if (ItemTemplate != none)
				return ItemTemplate.FriendlyName;
			break;
		case 'rifle':
			ItemTemplate = ItemMgr.FindItemTemplate('AssaultRifle_CV');
			if (ItemTemplate != none)
				return ItemTemplate.FriendlyName;
			break;
		case 'shotgun':
			ItemTemplate = ItemMgr.FindItemTemplate('Shotgun_CV');
			if (ItemTemplate != none)
				return ItemTemplate.FriendlyName;
			break;
		case 'pistol':
			ItemTemplate = ItemMgr.FindItemTemplate('Pistol_CV');
			if (ItemTemplate != none)
				return ItemTemplate.FriendlyName;
			break;
		case 'cannon':
			ItemTemplate = ItemMgr.FindItemTemplate('Sword_CV');
			if (ItemTemplate != none)
				return ItemTemplate.FriendlyName;
			break;
		case 'sword':
			ItemTemplate = ItemMgr.FindItemTemplate('WristBlade_CV');
			if (ItemTemplate != none)
				return ItemTemplate.FriendlyName;
			break;
		case 'sniper_rifle':
			ItemTemplate = ItemMgr.FindItemTemplate('SniperRifle_CV');
			if (ItemTemplate != none)
				return ItemTemplate.FriendlyName;
			break;
		case 'wristblade':
			ItemTemplate = ItemMgr.FindItemTemplate('WristBlade_CV');
			if (ItemTemplate != none)
				return ItemTemplate.FriendlyName;
			break;
		case 'gauntlet':
			ItemTemplate = ItemMgr.FindItemTemplate('ShardGauntlet_CV');
			if (ItemTemplate != none)
				return ItemTemplate.FriendlyName; // "Shard Gauntlets"
			break;
		case 'sparkbit':
			ItemTemplate = ItemMgr.FindItemTemplate('SparkBit_CV');
			if (ItemTemplate != none)
				return ItemTemplate.FriendlyName; // "SPARK BIT"
			break;
		case 'psiamp':
			ItemTemplate = ItemMgr.FindItemTemplate('PsiAmp_CV');
			if (ItemTemplate != none)
				return ItemTemplate.FriendlyName; // "Psi Amp"
			break;
		case 'sidearm':
			ItemTemplate = ItemMgr.FindItemTemplate('Sidearm_CV');
			if (ItemTemplate != none)
				return ItemTemplate.FriendlyName; // "Psi Amp"
			break;
		default:
			break;
	}

	// For mod-added categories, search for the first weapon template with that category,
	// and use its GetLocalizedCategoryMethod, which will trigger a CHL event.
	foreach ItemMgr.IterateTemplates(DataTemplate)
	{
		WeaponTemplate = X2WeaponTemplate(DataTemplate);
		if (WeaponTemplate != none && WeaponTemplate.WeaponCat == WeaponCat)
		{
			LocCat = WeaponTemplate.GetLocalizedCategory();
			break;
		}
	}
	// If all else fails, default to weapon category itself.
	if (LocCat == class'XGLocalizedData'.default.WeaponCatUnknown)
	{	
		return Repl(string(WeaponCat), "_", " ");
	}
	return LocCat;
}

// ============================================================================================================
//			DUPLICATE ABILITIES FIX
// ------------------------------------------------------------------------------------------------------------

// Caching cuz GetClassByName is intense.
static private function CacheCDOs()
{
	local X2DLCInfo_WOTCMusashiModFixes CDO;

	CDO = X2DLCInfo_WOTCMusashiModFixes(class'XComEngine'.static.GetClassDefaultObject(class'X2DLCInfo_WOTCMusashiModFixes'));
	if (CDO != none)
	{
		CDO.DLCInfo_TPS = class<X2DownloadableContentInfo>(class'XComEngine'.static.GetClassByName('X2DownloadableContentInfo_TruePrimarySecondaries'));
		CDO.DLCInfo_RPGO = class<X2DownloadableContentInfo>(class'XComEngine'.static.GetClassByName('X2DownloadableContentInfo_XCOM2RPGOverhaul'));
	}
}

static function bool CanAddItemToInventory_CH_Improved(out int bCanAddItem, const EInventorySlot Slot, const X2ItemTemplate ItemTemplate, int Quantity, XComGameState_Unit UnitState, optional XComGameState CheckGameState, optional out string DisabledReason, optional XComGameState_Item ItemState)
{
	local bool	OverrideNormalBehavior;
    local bool	DoNotOverrideNormalBehavior;
	local int	bCanAddItem_Local;

	OverrideNormalBehavior = CheckGameState != none;
    DoNotOverrideNormalBehavior = CheckGameState == none;   

	// We're called by state code
	if (CheckGameState != none)
	{
		bCanAddItem_Local = bCanAddItem;

		// Function wants to override base game behavior
		if (default.DLCInfo_TPS != none && default.DLCInfo_TPS.static.CanAddItemToInventory_CH_Improved(bCanAddItem_Local, Slot, ItemTemplate, Quantity, UnitState, CheckGameState, DisabledReason, ItemState))
		{
			// If the hook was about to allow equipping an item into an already occupied slot
			if (bCanAddItem_Local > 0 && UnitState.GetItemInSlot(Slot, CheckGameState) != none)
			{
				// Forbid it, and override behavior before that function can be called. Bad boy!
				bCanAddItem = 0;
				return OverrideNormalBehavior;
			}
		}

		bCanAddItem_Local = bCanAddItem;
		if (default.DLCInfo_RPGO != none && default.DLCInfo_RPGO.static.CanAddItemToInventory_CH_Improved(bCanAddItem_Local, Slot, ItemTemplate, Quantity, UnitState, CheckGameState, DisabledReason, ItemState))
		{
			if (bCanAddItem_Local > 0 && UnitState.GetItemInSlot(Slot, CheckGameState) != none)
			{
				bCanAddItem = 0;
				return OverrideNormalBehavior;
			}
		}
	}
	return DoNotOverrideNormalBehavior;
}

static event OnLoadedSavedGame()
{
	local XComGameState_HeadquartersXCom	XComHQ;
	local StateObjectReference				UnitRef;
	local StateObjectReference				ItemRef;
	local XComGameState_Item				ItemState;
	local XComGameState_Item				EquippedItemState;
	local XComGameState_Unit				UnitState;
	local XComGameState						NewGameState;
	local XComGameStateHistory				History;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ(true);
	if (XComHQ == none)
		return;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Fix Extra Item");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(XComHQ.Class, XComHQ.ObjectID));

	foreach XComHQ.Crew(UnitRef)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
		if (UnitState == none)
			continue;

		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
		foreach UnitState.InventoryItems(ItemRef)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemRef.ObjectID));
			if (ItemState == none)
				continue;

			if (!class'CHItemSlot'.static.SlotIsMultiItem(ItemState.InventorySlot))
			{
				EquippedItemState = UnitState.GetItemInSlot(ItemState.InventorySlot);
				if (EquippedItemState != none && EquippedItemState.ObjectID != ItemState.ObjectID)
				{
					if (UnitState.RemoveItemFromInventory(ItemState, NewGameState))
					{
						XComHQ.PutItemInInventory(NewGameState, ItemState);
					}
				}
			}
		}
	}

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		History.AddGameStateToHistory(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}


// ============================================================================================================
//			HELPERS
// ------------------------------------------------------------------------------------------------------------

static private final function bool IsModActive(name ModName)
{
    local XComOnlineEventMgr    EventManager;
    local int                   Index;

    EventManager = `ONLINEEVENTMGR;

    for (Index = EventManager.GetNumDLC() - 1; Index >= 0; Index--) 
    {
        if (EventManager.GetDLCNames(Index) == ModName) 
        {
            return true;
        }
    }
    return false;
}

static private function PrintWeaponSets(string printMessage)
{
	local name WeaponCat;
	local int i;

	`LOG(printMessage,, 'IRITEST');

	for (i = 0; i < class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets.Length; i++)
	{
		`LOG("SET NAME:" @ class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets[i].WeaponCategorySetName,, 'IRITEST');
		foreach class'AbilityToSlotReassignmentLib'.default.WeaponCategorySets[i].WeaponCategories(WeaponCat)
		{
			`LOG("---" @ WeaponCat,, 'IRITEST');
		}
		
	}
	`LOG("------------------------- FINISHED -----------------------------",, 'IRITEST');
}
