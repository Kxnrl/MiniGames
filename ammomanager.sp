#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>
#include <minigames>

#define PI_NAME     "Ammo Manager - Lite for MiniGames"
#define PI_AUTHOR   "Kyle 'Kxnrl' Frankiss + PerfectLaugh"
#define PI_DESC     "DARLING in the FRANXX"
#define PI_VERSION  "1.9." ... MYBUILD
#define PI_URL      "https://github.com/Kxnrl/MiniGames"

public Plugin myinfo = 
{
    name        = PI_NAME,
    author      = PI_AUTHOR,
    description = PI_DESC,
    version     = PI_VERSION,
    url         = PI_URL
};

// windows only
#define OFFSET_GetReserveAmmoMax        355
#define SIGOFFSET_SetReserveAmmoCount   9
#define SIGNATURE_SetReserveAmmoCount   "\x55\x8B\xEC\x51\x8B\x45\x14\x53\x56"

#define MAX_RESERVE_AMMO_MAX       416

Handle SDKCall_SetReserveAmmoCount;
Handle DHook_GetReserveAmmoMax;

public void OnPluginStart()
{
    DHook_GetReserveAmmoMax = DHookCreate(OFFSET_GetReserveAmmoMax, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity);
    DHookAddParam(DHook_GetReserveAmmoMax, HookParamType_Int);

    StartPrepSDKCall(SDKCall_Entity);
    if (!PrepSDKCall_SetSignature(SDKLibrary_Server, SIGNATURE_SetReserveAmmoCount, SIGOFFSET_SetReserveAmmoCount))
        SetFailState("PrepSDKCall_SetSignature(SDKLibrary_Server, SIGNATURE, len) failed!");
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
    SDKCall_SetReserveAmmoCount = EndPrepSDKCall();

    int entity = INVALID_ENT_REFERENCE; char classname[32];
    while ((entity = FindEntityByClassname(entity, "weapon_*")) != INVALID_ENT_REFERENCE)
    {
        GetWeaponClassname(entity, -1, classname, 32);
        OnEntityCreated(entity, classname);
    }

    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client))
            OnClientPutInServer(client);
    }
}

public void OnClientPutInServer(int client)
{
    if (IsFakeClient(client))
        return;

    SDKHook(client, SDKHook_SpawnPost, Event_PlayerSpawnPost);
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (strncmp(classname, "weapon_", 7) == 0)
    {
        DHookEntity(DHook_GetReserveAmmoMax, false, entity, _, Event_GetReserveAmmoMax);
        SDKHook(entity, SDKHook_SpawnPost, Event_WeaponCreated);
    }
}

public void Event_WeaponCreated(int entity)
{
    SDKUnhook(entity, SDKHook_SpawnPost, Event_WeaponCreated);
    SDKCall(SDKCall_SetReserveAmmoCount, entity, 1, MAX_RESERVE_AMMO_MAX, true, -1);
}

public void Event_PlayerSpawnPost(int client)
{
    if (!IsPlayerAlive(client))
        return;

    for (int i = 0; i < 64; i++)
    {
        int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
        if (weapon == -1)
            break;

        Event_WeaponCreated(weapon);
    }
}

public MRESReturn Event_GetReserveAmmoMax(int pThis, Handle hReturn, Handle hParams)
{
    DHookSetReturn(hReturn, MAX_RESERVE_AMMO_MAX);
    return MRES_Supercede;
}

//https://www.unknowncheats.me/wiki/Counter_Strike_Global_Offensive:Economy_Weapon_IDs
int GetWeaponClassname(int weapon, int index = -1, char[] classname, int maxLen)
{
    if (!GetEdictClassname(weapon, classname, maxLen))
        return -1;

    if (index == -1)
        index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");

    switch(index)
    {
        case 23 : return strcopy(classname, maxLen, "weapon_mp5sd");
        case 60 : return strcopy(classname, maxLen, "weapon_m4a1_silencer");
        case 61 : return strcopy(classname, maxLen, "weapon_usp_silencer");
        case 63 : return strcopy(classname, maxLen, "weapon_cz75a");
        case 64 : return strcopy(classname, maxLen, "weapon_revolver");
        case 500: return strcopy(classname, maxLen, "weapon_bayonet");
        case 506: return strcopy(classname, maxLen, "weapon_knife_gut");
        case 505: return strcopy(classname, maxLen, "weapon_knife_flip");
        case 508: return strcopy(classname, maxLen, "weapon_knife_m9_bayonet");
        case 507: return strcopy(classname, maxLen, "weapon_knife_karambit");
        case 509: return strcopy(classname, maxLen, "weapon_knife_tactical");
        case 515: return strcopy(classname, maxLen, "weapon_knife_butterfly");
        case 512: return strcopy(classname, maxLen, "weapon_knife_falchion");
        case 516: return strcopy(classname, maxLen, "weapon_knife_push");
        case 514: return strcopy(classname, maxLen, "weapon_knife_survival_bowie");
    }

    return strlen(classname);
}