#include <sdktools>
#pragma newdecls required

ConVar CVAR_KNIFE;
ConVar CVAR_PISTOL;

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("item_purchase", Event_Purchase, EventHookMode_Post);

	RegAdminCmd("giveak47", Cmd_GiveAK47, ADMFLAG_ROOT);
	RegAdminCmd("givem4a1", Cmd_GiveM4A1, ADMFLAG_ROOT);
	RegAdminCmd("givem4a4", Cmd_GiveM4A4, ADMFLAG_ROOT);
	RegAdminCmd("giveknife", Cmd_GiveKnife, ADMFLAG_UNBAN);
	RegAdminCmd("giveusp", Cmd_GiveUSP, ADMFLAG_ROOT);
	RegAdminCmd("giveawp", Cmd_GiveAWP, ADMFLAG_ROOT);

	CVAR_KNIFE = CreateConVar("mg_spawn_knife", "0");
	CVAR_PISTOL = CreateConVar("mg_spawn_pistol", "0");
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.1, Timer_SpawnPost, client);
}

public Action Event_Purchase(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	char weapon[32];
	GetEventString(event, "weapon", weapon, 32);

	if(StrContains(weapon, "g3sg1", false) != -1 || StrContains(weapon, "scar20", false) != -1)
		CreateTimer(GetRandomFloat(3.0, 5.0), Timer_Slay, GetClientUserId(client));
}

public Action Timer_Slay(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client) && IsPlayerAlive(client))
	{
		ForcePlayerSuicide(client);
		PrintToChatAll("[\x04MG\x01]  \x0B%N\x01使用\x09连狙\x01时遭遇天谴[\x07100HP\x01]", client);
	}
}

public Action Timer_SpawnPost(Handle timer, int client)
{
	if(!IsClientInGame(client))
		return;
	
	if(!IsPlayerAlive(client))
		return;
	
	if(CVAR_KNIFE.BoolValue && GetPlayerWeaponSlot(client, 2) == -1)
		GivePlayerItem(client, "weapon_knife");
	
	if(CVAR_PISTOL.BoolValue && GetPlayerWeaponSlot(client, 1) == -1)
	{
		if(GetClientTeam(client) == 2)
			GivePlayerItem(client, "weapon_glock");
		
		if(GetClientTeam(client) == 3)
			GivePlayerItem(client, "weapon_hkp2000");
	}
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
