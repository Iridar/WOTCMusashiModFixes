class X2EventListener_BallisticShieldsFix extends X2EventListener;

var localized string strDummy; // Needed for Localize() to work.

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(GetLocalizedCategory_Template());

	return Templates;
}

static function CHEventListenerTemplate GetLocalizedCategory_Template()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'X2EventListener_Shields_GetLocalizedCategory');

	Template.RegisterInTactical = true;
	Template.RegisterInStrategy = true;

	// Lower priority to run after the listener in Ballistic Shields.
	Template.AddCHEvent('GetLocalizedCategory', ListenerEventFunction, ELD_Immediate, 40);

	return Template;
}

static function EventListenerReturn ListenerEventFunction(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
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
