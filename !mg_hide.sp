#include <cg_core>
#include <sdkhooks>

bool g_bHideEnable[MAXPLAYERS+1];
int g_iClientTeam[MAXPLAYERS+1];

public void OnPluginStart()
{
	RegConsoleCmd("sm_hide", Command_Hide);
	CreateTimer(60.0, Timer_Broadcast, _, TIMER_REPEAT);
}

public Action Timer_Broadcast(Handle timer)
{
	PrintToChatAll("[\x04MG\x01]  输入\x07!hide\x01即可屏蔽队友");
}

public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	g_bHideEnable[client] = false;
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);
}

public void CG_OnClientTeam(int client)
{
	RequestFrame(OnClientTeam, client);
}

void OnClientTeam(int client)
{
	if(!IsClientInGame(client))
		return;

	g_iClientTeam[client] = GetClientTeam(client);
}

public Action Hook_SetTransmit(int entity, int client)
{
	if(!g_bHideEnable[client])
		return Plugin_Continue;
	
	if(!IsPlayerAlive(client))
		return Plugin_Continue;
	
	if(client == entity)
		return Plugin_Continue;
	
	if(g_iClientTeam[client] == g_iClientTeam[entity])
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action Command_Hide(int client, int args)
{
	g_bHideEnable[client] = !g_bHideEnable[client];
	PrintToChat(client, "[\x0CCG\x01]  你现在已经%s队友屏蔽", g_bHideEnable[client] ? "\x04开启\x01" : "\x07关闭\x01");
}