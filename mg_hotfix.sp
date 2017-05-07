#include <sdktools>
#include <cstrike>
#include <cg_core>

float g_fAngles[MAXPLAYERS+1][3];
float g_fOrigin[MAXPLAYERS+1][3];
float g_fVector[MAXPLAYERS+1][3];

ConVar cs_enable_player_physics_box;

bool football;

public void OnPluginStart()
{
	cs_enable_player_physics_box = FindConVar("cs_enable_player_physics_box");
	HookConVarChange(cs_enable_player_physics_box, OnSettingChanged);
	SetConVarInt(cs_enable_player_physics_box, 0);
}

public void OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(football)
		return;

	SetConVarInt(cs_enable_player_physics_box, 0);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if(client)
		return Plugin_Continue;

	if( StrContains(sArgs, "football", false) != -1 ||
		StrContains(sArgs, "KILLER BALLS", false) != -1)
	{
		football = true;
		SetConVarInt(cs_enable_player_physics_box, 1);
		CreateTimer(5.0, Timer_RespawnPlayer);
		PrintToChatAll("[\x04DEBUG\x01]  Finding Physics Engine...");
	}

	return Plugin_Continue;
}

public Action Timer_RespawnPlayer(Handle timer)
{
	for(int client = 1; client <= MaxClients; ++client)
	{
		if(!IsClientInGame(client) || !IsPlayerAlive(client))
			continue;
		
		GetClientAbsAngles(client, g_fAngles[client]);
		GetClientAbsOrigin(client, g_fOrigin[client]);
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", g_fVector[client]);
		
		CS_RespawnPlayer(client);
		RequestFrame(TeleportClient, client);
	}
	
	CreateTimer(5.0, Timer_CleanWeapon, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Stop;
}

void TeleportClient(int client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return;
	
	TeleportEntity(client, g_fOrigin[client], g_fAngles[client], g_fVector[client]);
	GivePlayerItem(client, "weapon_knife");
}

public void CG_OnRoundStart()
{
	football = false;
	SetConVarInt(cs_enable_player_physics_box, 0);
}

public void CG_OnRoundEnd(int winner)
{
	football = false;
	SetConVarInt(cs_enable_player_physics_box, 0);
}

public Action Timer_CleanWeapon(Handle timer)
{
	if(!football)
		return Plugin_Stop;
	
	for(int x = MaxClients+1; x <= 2048; ++x)
	{
		if(!IsValidEdict(x))
			continue;
		
		char classname[32];
		GetEdictClassname(x, classname, 32);
		if(StrContains(classname, "weapon_") != 0)
			continue;

		if(GetEntPropEnt(x, Prop_Send, "m_hOwnerEntity") > 0)
			continue;

		AcceptEntityInput(x, "Kill");
	}
	
	return Plugin_Continue;
}