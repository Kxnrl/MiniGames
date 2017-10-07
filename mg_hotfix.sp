#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <cg_core>

float g_fAngles[MAXPLAYERS+1][3];
float g_fOrigin[MAXPLAYERS+1][3];

int g_iHealth[MAXPLAYERS+1];

ConVar cs_enable_player_physics_box;
ConVar phys_pushscale;
ConVar sv_infinite_ammo;
ConVar phys_timescale;

bool football;

public void OnPluginStart()
{
	cs_enable_player_physics_box = FindConVar("cs_enable_player_physics_box");
	if(cs_enable_player_physics_box == INVALID_HANDLE)
		SetFailState("Unable to find cs_enable_player_physics_box");
	HookConVarChange(cs_enable_player_physics_box, OnSettingChanged);

	phys_pushscale = FindConVar("phys_pushscale");
	if(phys_pushscale == INVALID_HANDLE)
		SetFailState("Unable to find phys_pushscale");
	HookConVarChange(phys_pushscale, OnSettingChanged);

	phys_timescale = FindConVar("phys_timescale");
	if(phys_timescale == INVALID_HANDLE)
		SetFailState("Unable to find phys_timescale");

	sv_infinite_ammo = FindConVar("sv_infinite_ammo");
	if(sv_infinite_ammo == INVALID_HANDLE)
		SetFailState("Unable to find sv_infinite_ammo");
	HookConVarChange(sv_infinite_ammo, OnSettingChanged);
}

public void OnConfigsExecuted()
{
	SetConVarInt(phys_pushscale, 900);
	SetConVarInt(sv_infinite_ammo, 0);
	SetConVarInt(phys_timescale, 1);
	SetConVarInt(cs_enable_player_physics_box, 0);
}

public void OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	SetConVarInt(phys_pushscale, 900);
	SetConVarInt(sv_infinite_ammo, 0);
    SetConVarInt(phys_timescale, 1);
	SetConVarInt(cs_enable_player_physics_box, football ? 1 : 0);
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if(football)
        return;

    if(strcmp(classname, "prop_physics_override") == 0 || strcmp(classname, "prop_physics") == 0)
        SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawned);
}

public void OnEntitySpawned(int entity)
{
    if(football)
        return;

    SDKUnhook(entity, SDKHook_SpawnPost, OnEntitySpawned);

    char model[128];
    GetEntPropString(entity, Prop_Data, "m_ModelName", model, 128);
    if(strcmp(model, "models/forlix/soccer/soccerball.mdl") == 0)
    {
        football = true;
		SetConVarInt(phys_timescale, 1);
		SetConVarInt(cs_enable_player_physics_box, 1);
		CreateTimer(0.0, Timer_RespawnPlayer);
		SetAllMoveNone();
    }
}

public Action Timer_RespawnPlayer(Handle timer)
{
	for(int client = 1; client <= MaxClients; ++client)
	{
		if(!IsClientInGame(client) || !IsPlayerAlive(client))
			continue;

		GetClientEyeAngles(client, g_fAngles[client]);
		GetClientAbsOrigin(client, g_fOrigin[client]);
		g_iHealth[client] = GetClientHealth(client);
		CS_RespawnPlayer(client);
		RequestFrame(TeleportClient, client);
	}

	CreateTimer(1.0, Timer_CleanWeapon, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Stop;
}

void TeleportClient(int client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	TeleportEntity(client, g_fOrigin[client], g_fAngles[client], view_as<float>({0.0, 0.0, 0.0}));
	CreateTimer(0.5, Timer_HealthAndWeapon, client);
}

public Action Timer_HealthAndWeapon(Handle timere, int client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	
	SetEntityHealth(client, g_iHealth[client]);
	GivePlayerItem(client, "weapon_knife");
	
	return Plugin_Stop;
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

void SetAllMoveNone()
{
	for(int client = 1; client <= MaxClients; ++client)
	{
		if(!IsClientInGame(client) || !IsPlayerAlive(client))
			continue;

		SetEntityMoveType(client, MOVETYPE_NONE);
	}
}