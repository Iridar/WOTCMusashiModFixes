//-----------------------------------------------------------
//	Class:	LoadoutApiInterface
//	Author: Musashi
//	DO NOT MAKE ANY CHANGES TO THIS CLASS
//-----------------------------------------------------------


interface LoadoutApiInterface;

static function bool HasPrimaryMeleeOrPistolEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState);
static function bool HasMeleeAndPistolEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState);
static function bool HasPrimaryMeleeEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState);
static function bool HasPrimaryPistolEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState);
static function bool HasSecondaryMeleeEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState);
static function bool HasSecondaryPistolEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState);
static function bool HasShieldEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState);
static function bool HasDualPistolEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState);
static function bool HasDualMeleeEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState);
static function bool HasSecondaryPrimaryEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState);
static function bool IsPrimaryPistolItem(XComGameState_Item ItemState, optional bool bUseTemplateForSlotCheck = false);
static function bool IsPrimaryMeleeItem(XComGameState_Item ItemState, optional bool bUseTemplateForSlotCheck = false);
static function bool IsPrimaryMainWeaponItem(XComGameState_Item ItemState, optional bool bUseTemplateForSlotCheck = false);
static function bool IsSecondaryPistolItem(XComGameState_Item ItemState, optional bool bUseTemplateForSlotCheck = false);
static function bool IsSecondaryMeleeItem(XComGameState_Item ItemState, optional bool bUseTemplateForSlotCheck = false);
static function bool IsSecondaryMainWeaponItem(XComGameState_Item ItemState, optional bool bUseTemplateForSlotCheck = false);
static function bool IsPistolItem(XComGameState_Item ItemState, optional EInventorySlot InventorySlot = eInvSlot_SecondaryWeapon, optional bool bUseTemplateForSlotCheck = false);
static function bool IsMeleeItem(XComGameState_Item ItemState, optional EInventorySlot InventorySlot = eInvSlot_SecondaryWeapon, optional bool bUseTemplateForSlotCheck = false);
static function bool IsMainWeaponItem(XComGameState_Item ItemState, optional EInventorySlot InventorySlot = eInvSlot_SecondaryWeapon, optional bool bUseTemplateForSlotCheck = false);
static function bool IsMeleeWeaponTemplate(X2WeaponTemplate WeaponTemplate);
static function bool IsPistolWeaponTemplate(X2WeaponTemplate WeaponTemplate);
static function bool IsMainWeaponTemplate(X2WeaponTemplate WeaponTemplate);
