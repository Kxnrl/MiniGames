#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

ConVar CVAR_EnableEnd;

bool g_bEnableEnd;
bool g_bWeaponCanUse;

public void OnPluginStart()
{
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	HookEvent("round_prestart", Event_RountStart, EventHookMode_Pre);

	CVAR_EnableEnd = CreateConVar("mg_roundendfix", "1");
	g_bEnableEnd = GetConVarBool(CVAR_EnableEnd);
	HookConVarChange(CVAR_EnableEnd, OnSettingChanged);
	
	for(int i = 1; i <= MaxClients; ++i)
		if(IsClientInGame(i))
			OnClientPutInServer(i);
}

public void OnPluginEnd()
{
	for(int i = 1; i <= MaxClients; ++i)
		if(IsClientInGame(i))
			OnClientDisconnect(i);
}

public int OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar == CVAR_EnableEnd)
		g_bEnableEnd = view_as<bool>(StringToInt(newValue));
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public Action Event_RountStart(Handle event, const char[] name, bool dontBroadcast)
{
	g_bWeaponCanUse = true;
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if(!g_bEnableEnd)
		return;

	CreateTimer(GetConVarFloat(FindConVar("mp_round_restart_delay"))-1.0, Timer_RoundEnd, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_RoundEnd(Handle timer)
{
	for(int client=1; client<=MaxClients; ++client)
		if(IsClientInGame(client))
			if(IsPlayerAlive(client))
				RemoveAllWeapon(client);

	g_bWeaponCanUse = false;
}

public Action OnWeaponCanUse(int client, int weapon)
{
	if(!g_bEnableEnd)
		return Plugin_Continue;

	if(g_bWeaponCanUse)
		return Plugin_Continue;

	if(!IsValidClient(client))
		return Plugin_Continue;
	
	return Plugin_Handled;
}

stock void RemoveAllWeapon(int client)
{
	RemoveWeaponBySlot(client, 0);
	RemoveWeaponBySlot(client, 1);
	while(RemoveWeaponBySlot(client, 2)){}
	while(RemoveWeaponBySlot(client, 3)){}
	while(RemoveWeaponBySlot(client, 4)){}
	
	SetEntProp(client, Prop_Send, "m_iAmmo", 0, _, 14);
	SetEntProp(client, Prop_Send, "m_iAmmo", 0, _, 15);
	SetEntProp(client, Prop_Send, "m_iAmmo", 0, _, 16);
	SetEntProp(client, Prop_Send, "m_iAmmo", 0, _, 17);
	SetEntProp(client, Prop_Send, "m_iAmmo", 0, _, 18);
}

stock bool RemoveWeaponBySlot(int client, int slot)
{
	int iWeapon = GetPlayerWeaponSlot(client, slot);

	if(IsValidEdict(iWeapon))
	{
		RemovePlayerItem(client, iWeapon);
		AcceptEntityInput(iWeapon, "Kill");
		return true;
	}

	return false;
}

stock bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client)) ? true : false;
}