//-----------------------------------------------------------
//	Class:	WOTCMusashiModFixes_MCMScreenListener
//	Author: Iridar
//	
//-----------------------------------------------------------

class WOTCMusashiModFixes_MCMScreenListener extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local WOTCMusashiModFixes_MCMScreen MCMScreen;

	if (ScreenClass==none)
	{
		if (MCM_API(Screen) != none)
			ScreenClass=Screen.Class;
		else return;
	}

	MCMScreen = new class'WOTCMusashiModFixes_MCMScreen';
	MCMScreen.OnInit(Screen);
}

defaultproperties
{
    ScreenClass = none;
}
