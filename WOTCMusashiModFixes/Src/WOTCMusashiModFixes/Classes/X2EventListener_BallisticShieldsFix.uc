class X2EventListener_BallisticShieldsFix extends X2EventListener;

var localized string strDummy; // Needed for Localize() to work.

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(GetLocalizedCategory_Template());

	return Templates;
}

static private function CHEventListenerTemplate GetLocalizedCategory_Template()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'X2EventListener_Shields_GetLocalizedCategory');

	Template.RegisterInCampaignStart = true;
	Template.RegisterInTactical = true;
	Template.RegisterInStrategy = true;

	// Lower priority to run after the listener in Ballistic Shields.
	Template.AddCHEvent('GetLocalizedCategory', ListenerEventFunction, ELD_Immediate, 40);

	`LLOG("Running");

	if (class'X2DLCInfo_WOTCMusashiModFixes'.static.IsModActive('TruePrimarySecondaries'))
	{
		`LLOG("Registered");
		Template.AddCHEvent('PostSquaddieLoadoutApplied', OnPostSquaddieLoadoutApplied, ELD_Immediate, 40);
	}

	return Template;
}

static private function EventListenerReturn ListenerEventFunction(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local XComLWTuple Tuple;
	local X2WeaponTemplate Template;

	Tuple = XComLWTuple(EventData);
	Template = X2WeaponTemplate(EventSource);

	if (Tuple == none || Template == none)
		return ELR_NoInterrupt;

	// The original listener in Ballistic Shields is missing the "break" statement, so both regular and spark ballistic shields end up localized as spark shields.
	// This listener fixes it.

	switch (Template.WeaponCat)
	{
	case 'shield':
		Tuple.Data[0].s = Localize("XGLocalizedData_BallisticShields", "m_strShieldCategory", "WotCBallisticShields"); 
		break; 
	case 'spark_shield':
		Tuple.Data[0].s = Localize("XGLocalizedData_BallisticShields", "m_strSparkShieldCategory", "WotCBallisticShields"); 
		break;
	default:
		return ELR_NoInterrupt;
	}

	return ELR_NoInterrupt;
}

static private function EventListenerReturn OnPostSquaddieLoadoutApplied(Object EventData, Object EventSource, XComGameState NewGameState, Name EventID, Object CallbackObject)
{
    local XComGameState_Unit UnitState;
	local XComGameState_Unit NewUnitState;
    local XComLWTuple Tuple;
    local name LoadoutName;
	local name LoadoutItem;
    local array<name> LoadoutItems;
	local XComGameState_Item ItemState;
	local XComGameState_Item NewItemState;
	local X2WeaponTemplate	WeaponTemplate;
	local X2ItemTemplateManager ItemMgr;
	local bool bPrimarySecondaryLoadout;

    UnitState = XComGameState_Unit(EventSource);
    Tuple = XComLWTuple(EventData);

    LoadoutName = Tuple.Data[0].n;
    LoadoutItems = Tuple.Data[1].an;

	`LLOG("Running" @ UnitState.GetFullName());
	
	// #1. Check if the unit has a primary secondary in their loadout.
	foreach LoadoutItems(LoadoutItem)
	{
		if (InStr(LoadoutItem, "_Primary") == INDEX_NONE)
			continue;

		LoadoutItem = name(Repl(LoadoutItem, "_Primary", ""));
		bPrimarySecondaryLoadout = true;
		break;
	}
	if (!bPrimarySecondaryLoadout)
		return ELR_NoInterrupt;

	// #2. Check if the unit actually has it equipped. Exit early if yes.
	ItemState = UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, NewGameState, true);
	if (ItemState != none && LoadoutItem == ItemState.GetMyTemplateName())	
		return ELR_NoInterrupt;

	`LLOG(UnitState.GetFullName() @ "Has Primary Secondary loadout:" @ LoadoutName @ "with intended primary:" @ LoadoutItem);
	`LLOG("However, the unit has:" @ ItemState != none ? string(ItemState.GetMyTemplateName()) : "none" @ "equipped instead.");

	// #3. Get the latest Unit State.
	NewUnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(UnitState.ObjectID));
	if (NewUnitState == none)
	{
		NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
	}
	if (NewUnitState == none)
		return ELR_NoInterrupt;

	// #4. Get the template of the primary secondary the unit is supposed to have equipped.
	
	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	WeaponTemplate = X2WeaponTemplate(ItemMgr.FindItemTemplate(LoadoutItem));
	if (WeaponTemplate == none)
		return ELR_NoInterrupt;

	`LLOG("Found the Weapon Template for the intended primary weapon.");

	// #5. Create the new primary secondary item and replace with it whatever the unit has equipped in their primary weapon slot.
	if (ItemState == none || NewUnitState.RemoveItemFromInventory(ItemState, NewGameState))
	{
		NewItemState = WeaponTemplate.CreateInstanceFromTemplate(NewGameState);
		if (NewUnitState.AddItemToInventory(NewItemState, eInvSlot_PrimaryWeapon, NewGameState))
		{
			`LLOG("Successfully equipped the intended weapon.");

			// Nuke the old item.
			if (ItemState != none)
				NewGameState.PurgeGameStateForObjectID(ItemState.ObjectID);
		}
		else
		{
			// Nuke the PS item we failed to equip.
			NewGameState.PurgeGameStateForObjectID(NewItemState.ObjectID);
			
			// If we failed to equip the intended primary secondary for whatever reason, equip whatever fits from Avenger's inventory.
			NewUnitState.ApplyBestGearLoadout(NewGameState);
			NewItemState = NewUnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, NewGameState, true);

			if (NewItemState != none)
			{
				`LLOG("Failed to equip the intended PS weapon, applied best gear loadout instead:" @ NewItemState.GetMyTemplateName());
				// Nuke the old item.
				if (ItemState != none)
					NewGameState.PurgeGameStateForObjectID(ItemState.ObjectID);
			}
			else
			{
				`LLOG("Failed to do anything useful, equipping whatever the unit had equipped before.");
				// Nothing in the Avenger's inventory? Damn, at least equip whatever unit had before.
				if (ItemState != none)
					NewUnitState.AddItemToInventory(ItemState, eInvSlot_PrimaryWeapon, NewGameState);
			}
		}
	}

    return ELR_NoInterrupt;
}