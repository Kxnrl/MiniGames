#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <cg_core>

ConVar cs_enable_player_physics_box;
ConVar phys_pushscale;
ConVar phys_timescale;
ConVar sv_infinite_ammo;
ConVar mp_teammates_are_enemies;

ArrayList g_aEntityIndex;
ArrayList g_aEntityTouch;

public void OnPluginStart()
{
    g_aEntityIndex = new ArrayList();
    g_aEntityTouch = new ArrayList();
    
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
    
    mp_teammates_are_enemies = FindConVar("mp_teammates_are_enemies");
    if(mp_teammates_are_enemies == INVALID_HANDLE)
        SetFailState("Unable to find mp_teammates_are_enemies");
}

public void OnConfigsExecuted()
{
    SetConVarInt(phys_pushscale, 900);
    SetConVarInt(sv_infinite_ammo, 0);
    SetConVarInt(phys_timescale, 1);
    SetConVarInt(cs_enable_player_physics_box, 0);
    SetConVarInt(mp_teammates_are_enemies, 0);
}

public void OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
    SetConVarInt(phys_pushscale, 900);
    SetConVarInt(sv_infinite_ammo, 0);
    SetConVarInt(phys_timescale, 1);
    SetConVarInt(cs_enable_player_physics_box, 0);
}

public void CG_OnRoundStart()
{
    g_aEntityIndex.Clear();
    g_aEntityTouch.Clear();
    
    if(mp_teammates_are_enemies.IntValue == 1)
        mp_teammates_are_enemies.SetInt(0);
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if(strcmp(classname, "prop_physics_override") == 0 || strcmp(classname, "prop_physics") == 0)
        SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawned);
}

public void OnEntitySpawned(int entity)
{
    SDKUnhook(entity, SDKHook_SpawnPost, OnEntitySpawned);

    char model[128];
    GetEntPropString(entity, Prop_Data, "m_ModelName", model, 128);

    if(strcmp(model, "models/forlix/soccer/soccerball.mdl", false) == 0)
    {
        g_aEntityIndex.Push(entity);
        g_aEntityTouch.Push(0);
        mp_teammates_are_enemies.SetInt(1);
        SDKHook(entity, SDKHook_StartTouch, OnEntityTouched);
        SDKHook(entity, SDKHook_OnTakeDamage, OnEntityDamaged);
    }
}

public Action OnEntityTouched(int entity, int client)
{
    if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Continue;
    
    int index = g_aEntityIndex.FindValue(entity);
    
    if(index == -1)
        return Plugin_Continue;
    
    float VelVec[3], AbsVelVec[3];
    GetEntPropVector(entity, Prop_Data, "m_vecVelocity", VelVec);
    GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", AbsVelVec);

    PrintCenterTextAll("Football Speed: \n%f | %f", GetVectorLength(VelVec), GetVectorLength(AbsVelVec));

    int attacker = g_aEntityTouch.Get(index);

    if(attacker == 0 || !IsClientInGame(attacker) || attacker == client)
        ForcePlayerSuicide(client);
    else
        SDKHooks_TakeDamage(client, entity, attacker, 100.0, 32, GetPlayerWeaponSlot(attacker, 2), NULL_VECTOR, NULL_VECTOR);

    return Plugin_Continue;
}

public Action OnEntityDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if(!(1 <= attacker <= MaxClients) || !IsClientInGame(attacker) || !IsPlayerAlive(attacker))
        return Plugin_Continue;
    
    int index = g_aEntityIndex.FindValue(victim);
    
    if(index == -1)
        return Plugin_Continue;
    
    g_aEntityTouch.Set(index, attacker);

    PrintToChatAll("%N touched football.%d", attacker, index);

    return Plugin_Continue;
}