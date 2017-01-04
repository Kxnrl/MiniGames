#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public void OnPluginStart()
{
	HookEvent("item_purchase", Event_Purchase, EventHookMode_Post);
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
		PrintToChatAll("[\x0EPlaneptune\x01]  \x0B%N\x01使用\x09连狙\x01时遭遇天谴[\x07100HP\x01]", client);
	}
}