#include <sendproxy>
#include <sdktools>
#include <sdkhooks>

bool g_bGod[MAXPLAYERS+1];

public Plugin myinfo =
{
	name		= "your mother car crash",
	author		= "Kyle",
	description	= "",
	version		= "1.0", 
	url			= "http://steamcommunity.com/id/_xQy_/"
};

public void OnPluginStart()
{
	AddCommandListener(Command_FuckYourMonther, "god");
}

public Action Command_FuckYourMonther(int client, const char[] command, int argc)
{
	g_bGod[client] = !g_bGod[client];
	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	g_bGod[client] = false;
	SendProxy_Hook(client, "m_ArmorValue", Prop_Int, SendProp_YourMotherFucker);
	SendProxy_Hook(client, "m_bHasHelmet", Prop_Int, SendProp_YourMotherCarCrash);
	SDKHook(client, SDKHook_OnTakeDamage, OnYourMotherCarCrash);
}

public Action SendProp_YourMotherFucker(int entity, const char[] propname, int &iValue, int element) 
{ 
	if(g_bGod[entity])
	{
		iValue = 100;
		return Plugin_Changed;
	}
	else	
		return Plugin_Continue;
}

public Action SendProp_YourMotherCarCrash(int entity, const char[] propname, int &iValue, int element) 
{ 
	if(g_bGod[entity])
	{
		iValue = 1;
		return Plugin_Changed;
	}
	else	
		return Plugin_Continue;
}

public Action OnYourMotherCarCrash(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(g_bGod[victim])
		return Plugin_Handled;
	else
		return Plugin_Continue;
}