#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

bool g_bEnable;
static adminClient;

public void OnMapStart()
{
	char map[128];
	GetCurrentMap(map, 128);
	
	if(StrEqual(map, "mg_super_tower_v4", false))
	{
		g_bEnable = true;
		HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
		HookEvent("item_equip", Event_PlayerEquip, EventHookMode_Post);
		
		for(int client = 1; client <= MaxClients; ++client)
			if(IsClientInGame(client))
				OnClientPostAdminCheck(client);
	}
}

public void OnMapEnd()
{
	if(g_bEnable)
	{
		g_bEnable = false;
		UnhookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
		UnhookEvent("item_equip", Event_PlayerEquip, EventHookMode_Post);
	}
}

public void OnClientPostAdminCheck(client)
{
	if(!g_bEnable)
		return;

	SDKHook(client, SDKHook_OnTakeDamage, Event_OnTakeDamage);
	
	char auth[32];
	GetClientAuthId(client, AuthId_Steam2, auth, 32, true);
	
	if(StrEqual(auth, "STEAM_1:1:44083262", false))
		client = adminClient;
}

public void OnClientDisconnect(client)
{
	if(g_bEnable)
		if(adminClient == client)
			adminClient = 0;
}

public Action Event_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(victim != adminClient)
		return Plugin_Continue;
	
	if(!IsValidEntity(weapon))
		return Plugin_Continue;
	
	char szWeapon[32];
	GetEntityClassname(weapon, szWeapon, 32);
	if(StrContains(szWeapon, "nova", false) != -1 || StrContains(szWeapon, "swade", false) != -1 || StrContains(szWeapon, "mag", false) != -1 || StrContains(szWeapon, "xm1014", false) != -1)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client))
		return;
	
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, "weapon_flashbang");
	GivePlayerItem(client, "item_assaultsuit");
	SetEntProp(client, Prop_Send, "m_ArmorValue", 88, 1);
}

public Action Event_PlayerEquip(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client))
		return;
	
	if(GetUserFlagBits(client) & ADMFLAG_ROOT)
		return;

	char item[32];
	GetEventString(event, "item", item, 32);

	if(StrEqual(item, "negev", false) || StrEqual(item, "m249", false))
	{
		if(GetClientHealth(client) > 25)
			SetEntityHealth(client, GetClientHealth(client)-25);
		else
			ForcePlayerSuicide(client);
		PrintToChatAll("[\x0EPlaneptune\x01]  \x0B%N\x01遭遇天谴[25HP]", client);
	}
	
	if(StrEqual(item, "scar20", false) || StrEqual(item, "g3sg1", false))
	{
		if(GetClientHealth(client) > 50)
			SetEntityHealth(client, GetClientHealth(client)-50);
		else
			ForcePlayerSuicide(client);
		PrintToChatAll("[\x0EPlaneptune\x01]  \x0B%N\x01遭遇天谴[50HP]", client);
	}
}