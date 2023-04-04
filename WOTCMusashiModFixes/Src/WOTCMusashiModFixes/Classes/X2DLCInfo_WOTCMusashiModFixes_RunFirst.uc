class X2DLCInfo_WOTCMusashiModFixes_RunFirst extends X2DownloadableContentInfo;

// This fixes a bug with AtSR where if Launch Grenade is Mandatory, it is added just to the grenade launcher,
// but to work properly, there must be one launch grenade entry per each non-merged grenade item, which will specify that grenade as source ammo.

static function FinalizeUnitAbilitiesForInit(XComGameState_Unit UnitState, out array<AbilitySetupData> SetupData, optional XComGameState StartState, optional XComGameState_Player PlayerState, optional bool bMultiplayerDisplay)
{
	local AbilitySetupData			NewData;
	local array<XComGameState_Item>	CurrentInventory;
	local XComGameState_Item		InventoryItem;
	local array<XComGameState_Item>	FoundItems;
	local XComGameState_Item		FoundItem;
	local X2AbilityTemplateManager	AbilityMgr;
	local array<name>				WeaponCategories;
	local name						WeaponCategory;
	local int Index;
	local int j;

	if (!IsModActive('AbilityToSlotReassignment'))
		return;

	// Don't process if the unit already has Launch Grenade, then base game ability init will handle it.
	if (!IsLaunchGrenadeMandatory() || UnitState.HasAbilityFromAnySource('LaunchGrenade'))
		return;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	NewData.TemplateName = 'LaunchGrenade';
	NewData.Template = AbilityMgr.FindAbilityTemplate(NewData.TemplateName);
	if (NewData.Template == none)
		return;

	CurrentInventory = UnitState.GetAllInventoryItems(StartState);

	// #1. Cycle through each instance of Launch Grenade in the Mandatory Abilities array.
	for (Index = class'AbilityToSlotReassignmentLib'.default.MandatoryAbilities.Length - 1; Index >= 0; Index--)
	{	
		if (class'AbilityToSlotReassignmentLib'.default.MandatoryAbilities[Index].AbilityName == 'LaunchGrenade')
		{
			// #2. Get weapon categories from that Mandatory Ability array entry, cycle through each weapon category.
			WeaponCategories = class'AbilityToSlotReassignmentLib'.static.GetWeaponCategoriesFromSet(class'AbilityToSlotReassignmentLib'.default.MandatoryAbilities[Index].WeaponCategorySetName);
			foreach WeaponCategories(WeaponCategory)
			{	
				// #3. Get all items of that weapon category on the unit.
				FoundItems = class'AbilityToSlotReassignmentLib'.static.GetInventoryItemsForCategory(UnitState, WeaponCategory, StartState);
				foreach FoundItems(FoundItem)
				{
					// Create a Launch Grenade entry for each item.
					NewData.SourceWeaponRef = FoundItem.GetReference();

					// Then create a Setup Data entry for each non-merged grenade item.
					foreach CurrentInventory(InventoryItem)
					{
						if (InventoryItem.bMergedOut)
							continue;

						if (X2GrenadeTemplate(InventoryItem.GetMyTemplate()) != none)
						{
							NewData.SourceAmmoRef = InventoryItem.GetReference();
							SetupData.AddItem(NewData);

							// Also remove instances of Throw Grenade associated with that grenade.
							for (j = SetupData.Length - 1; j >= 0; j--)
							{
								if (SetupData[j].TemplateName == 'ThrowGrenade' && SetupData[j].SourceWeaponRef.ObjectID == NewData.SourceAmmoRef.ObjectID)
								{	
									SetupData.Remove(j, 1);
									break;
								}
							}
						}
					}
				}
			}
		}
	}
}


static private function bool IsLaunchGrenadeMandatory()
{
	local int i;

	for (i = class'AbilityToSlotReassignmentLib'.default.MandatoryAbilities.Length - 1; i >= 0; i--)
	{	
		if (class'AbilityToSlotReassignmentLib'.default.MandatoryAbilities[i].AbilityName == 'LaunchGrenade')
			return true;
	}
	return false;
}

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