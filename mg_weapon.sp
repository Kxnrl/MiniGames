#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

ConVar mg_restrictawp;
ConVar mg_slaygaygun;
ConVar mg_dropweaponfix;
ConVar mg_roundendfix;
ConVar mg_spawn_knife;
ConVar mg_spawn_pistol;

bool g_bRestrictAwp = false;
bool g_bSlayGaygun = true;
bool g_bDropWeaponFix = true;
bool g_bRoundEndFix = true;
bool g_bWeaponCanUse = true;

public void OnPluginStart()
{
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	HookEvent("round_prestart", Event_RountStart, EventHookMode_Pre);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);

	RegAdminCmd("giveak47", Cmd_GiveAK47, ADMFLAG_ROOT);
	RegAdminCmd("givem4a1", Cmd_GiveM4A1, ADMFLAG_ROOT);
	RegAdminCmd("givem4a4", Cmd_GiveM4A4, ADMFLAG_ROOT);
	RegAdminCmd("giveknife", Cmd_GiveKnife, ADMFLAG_UNBAN);
	RegAdminCmd("giveusp", Cmd_GiveUSP, ADMFLAG_ROOT);
	RegAdminCmd("giveawp", Cmd_GiveAWP, ADMFLAG_ROOT);

	mg_restrictawp = CreateConVar("mg_restrictawp", "0");
	mg_slaygaygun = CreateConVar("mg_slaygaygun", "1");
	mg_dropweaponfix = CreateConVar("mg_dropweaponfix", "1");
	mg_roundendfix = CreateConVar("mg_roundendfix", "1");
	mg_spawn_knife = CreateConVar("mg_spawn_knife", "0");
	mg_spawn_pistol = CreateConVar("mg_spawn_pistol", "0");

	HookConVarChange(mg_restrictawp, OnSettingChanged);
	HookConVarChange(mg_slaygaygun, OnSettingChanged);
	HookConVarChange(mg_dropweaponfix, OnSettingChanged);
	HookConVarChange(mg_roundendfix, OnSettingChanged);
	
	for(int i = 1; i <= MaxClients; ++i)
		if(IsClientInGame(i))
			OnClientPostAdminCheck(i);
}

public void OnPluginEnd()
{
	for(int i = 1; i <= MaxClients; ++i)
		if(IsClientInGame(i))
			OnClientDisconnect(i);
}

public int OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar == mg_roundendfix)
		g_bRoundEndFix = view_as<bool>(StringToInt(newValue));
	else if(convar == mg_dropweaponfix)
		g_bDropWeaponFix = view_as<bool>(StringToInt(newValue));
	else if(convar == mg_slaygaygun)
		g_bSlayGaygun = view_as<bool>(StringToInt(newValue));
	else if(convar == mg_restrictawp)
		g_bRestrictAwp = view_as<bool>(StringToInt(newValue));
}

public void OnClientPostAdminCheck(int client)
{
	if(IsFakeClient(client))
		return;

	SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquip);
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public void OnClientDisconnect(int client)
{
	if(IsFakeClient(client))
		return;

	SDKUnhook(client, SDKHook_WeaponEquipPost, OnWeaponEquip);
	SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public Action Event_RountStart(Handle event, const char[] name, bool dontBroadcast)
{
	g_bWeaponCanUse = true;
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if(!g_bRoundEndFix)
		return;

	CreateTimer(GetConVarFloat(FindConVar("mp_round_restart_delay"))-1.0, Timer_RoundEnd, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	RequestFrame(OnClientSpawn, GetClientOfUserId(GetEventInt(event, "userid")));
}

public Action Timer_Slay(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(IsValidClient(client))
	{
		ForcePlayerSuicide(client);
		PrintToChatAll("[\x04MG\x01]  \x0B%N\x01使用\x09连狙\x01时遭遇天谴[\x07100HP\x01]", client);
	}
}

public void OnClientSpawn(int client)
{
	if(!IsClientInGame(client))
		return;

	if(!IsPlayerAlive(client))
		return;

	if(mg_spawn_knife.BoolValue && GetPlayerWeaponSlot(client, 2) == -1)
		GivePlayerItem(client, "weapon_knife");

	if(mg_spawn_pistol.BoolValue && GetPlayerWeaponSlot(client, 1) == -1)
	{
		if(GetClientTeam(client) == 2)
			GivePlayerItem(client, "weapon_glock");
		
		if(GetClientTeam(client) == 3)
			GivePlayerItem(client, "weapon_hkp2000");
	}
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
	if(g_bRoundEndFix && !g_bWeaponCanUse)
		return Plugin_Handled;

	if(!g_bDropWeaponFix)
		return Plugin_Continue;

	RequestFrame(CheckWeaponEquip, weapon);
	
	return Plugin_Continue;
}

public void OnWeaponEquip(int client, int weapon)
{
	if(!IsValidEdict(weapon))
		return;
	
	if(!g_bSlayGaygun && !g_bRestrictAwp)
		return;
	
	char classname[32];
	GetEdictClassname(weapon, classname, 32);
	
	if(g_bRestrictAwp && StrEqual(classname, "weapon_awp"))
	{
		PrintToChat(client, "[\x04MG\x01]  \x07当前地图限制Awp的使用");
		RequestFrame(RemoveRestriceWeapon, weapon);
		return;
	}

	if(StrEqual(classname, "weapon_scar20") || StrEqual(classname, "weapon_g3sg1"))
	{
		RequestFrame(RemoveRestriceWeapon, weapon);
		if(g_bSlayGaygun)
			CreateTimer(GetRandomFloat(1.0, 3.0), Timer_Slay, GetClientUserId(client));
	}
}

public void CheckWeaponEquip(int entity)
{
	if(!IsValidEdict(entity))
		return;

	char entname[64];
	GetEntPropString(entity, Prop_Data, "m_iName", entname, sizeof(entname));
	if(!StrEqual(entname, ""))
		return;

	if(GetEntProp(entity, Prop_Send, "m_hPrevOwner") != -1)
		return;

	if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") != -1)
		return;

	AcceptEntityInput(entity, "Kill");
}

public void RemoveRestriceWeapon(int entity)
{
	if(!IsValidEdict(entity))
		return;
	
	AcceptEntityInput(entity, "Kill");
} 

public Action Cmd_GiveKnife(int client, int args)
{
	if(IsPlayerAlive(client))
		GivePlayerItem(client, "weapon_knife");
}

public Action Cmd_GiveAK47(int client, int args)
{
	if(IsPlayerAlive(client))
		GivePlayerItem(client, "weapon_ak47");
}

public Action Cmd_GiveM4A1(int client, int args)
{
	if(IsPlayerAlive(client))
		GivePlayerItem(client, "weapon_m4a1_silencer");
}

public Action Cmd_GiveM4A4(int client, int args)
{
	if(IsPlayerAlive(client))
		GivePlayerItem(client, "weapon_m4a1");
}

public Action Cmd_GiveUSP(int client, int args)
{
	if(IsPlayerAlive(client))
		GivePlayerItem(client, "weapon_hkp2000");
}

public Action Cmd_GiveAWP(int client, int args)
{
	if(IsPlayerAlive(client))
		GivePlayerItem(client, "weapon_awp");
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