#include <sourcemod>
#include <sdktools>

public OnPluginStart()
{
	HookEvent("weapon_fire", Event_FireNade, EventHookMode_Post);
	HookEvent("item_purchase", Event_Purchase, EventHookMode_Post);}

public Action Event_FireNade(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client < 1 || client > MaxClients)
		return;
	
	if(!IsClientInGame(client))
		return;
	
	if(!IsPlayerAlive(client))
		return;
	
	char weapon[32];
	GetEventString(event, "weapon", weapon, 32);
	
	if(GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		if(StrContains(weapon, "hegrenade", false) != -1)
			CreateTimer(0.5, Timer_HE, client);
		
		if(StrContains(weapon, "molotov", false) != -1)
			CreateTimer(0.5, Timer_MV, client);
	}
	
	if(StrContains(weapon, "flashbang", false) != -1)
	{
		int rdm;
		int vol;
		
		char map[128];
		GetCurrentMap(map, 128);
		
		if(GetUserFlagBits(client) & ADMFLAG_ROOT)
			rdm = GetRandomInt(1, 35);
		else
			rdm = GetRandomInt(1, 100);
		
		if(StrEqual(map, "mg_super_tower_v4", false))
			vol = 55;
		else
			vol = 35
		
		if(rdm > vol)
		{
			PrintToChatAll("[\x0EPlaneptune\x01]  \x0B%N\x01使用\x09闪光弹\x01时遭遇天谴[\x07100HP\x01][rdm随机数:\x07  %d]", client, rdm);
			ForcePlayerSuicide(client);
		}
		else
			PrintToChatAll("[\x0EPlaneptune\x01]  \x0B%N\x01使用\x09闪光弹\x01[rdm随机数:\x07 %d]", client, rdm);
	}	
}

public Action Timer_HE(Handle timer, int client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
		GivePlayerItem(client, "weapon_hegrenade");
}

public Action Timer_MV(Handle timer, int client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
		GivePlayerItem(client, "weapon_molotov");
}

public Action Event_Purchase(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client < 1 || client > MaxClients)
		return;
	
	if(!IsClientInGame(client))
		return;
	
	if(!IsPlayerAlive(client))
		return;

	char weapon[32];
	GetEventString(event, "weapon", weapon, 32);
	
	if(StrContains(weapon, "g3sg1", false) != -1 || StrContains(weapon, "scar20", false) != -1)
		CreateTimer(GetRandomFloat(5.0, 10.0), Timer_Slay, GetClientUserId(client));
}

public Action Timer_Slay(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		ForcePlayerSuicide(client);
		PrintToChatAll("[\x0EPlaneptune\x01]  \x0B%N\x01使用\x09连狙\x01时遭遇天谴[\x07100HP\x01]", client);
	}
}