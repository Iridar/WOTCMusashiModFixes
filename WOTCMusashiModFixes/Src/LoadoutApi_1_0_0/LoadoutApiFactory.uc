//-----------------------------------------------------------
//	Class:	LoadoutApiFactory
//	Author: Musashi
//	DO NOT MAKE ANY CHANGES TO THIS CLASS
//-----------------------------------------------------------


class LoadoutApiFactory extends Object config (Fake);

struct LoadoutApiInstance
{
	var LoadoutApiInterface ApiInstance;
};

// fake singleton
var config LoadoutApiInstance LoadoutApi;

static function LoadoutApiInterface GetLoadoutApi()
{
	local object CDO;
	local LoadoutApiInstance Instance;
	
	if (default.LoadoutApi.ApiInstance == none)
	{
		CDO = class'XComEngine'.static.GetClassDefaultObjectByName('LoadoutApiLib');
		Instance.ApiInstance = LoadoutApiInterface(CDO);
		default.LoadoutApi = Instance;
	}

	return default.LoadoutApi.ApiInstance;
}