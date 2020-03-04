#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>
#include <minigames>

#undef REQUIRE_PLUGIN
#include <fys.pupd>
#define REQUIRE_PLUGIN

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
#define OFFSET_GetMaxClip1              352
#define OFFSET_GetReserveAmmoMax        356
#define SIGOFFSET_SetReserveAmmoCount   9
#define SIGNATURE_SetReserveAmmoCount   "\x55\x8B\xEC\x51\x8B\x45\x14\x53\x56"

#define MAX_RESERVE_AMMO_MAX       416

Handle SDKCall_SetReserveAmmoCount;
Handle SDKCall_GetMaxClip1;
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
    if ((SDKCall_SetReserveAmmoCount = EndPrepSDKCall()) == null)
        SetFailState("Failed to prepare SDKCall SDKCall_SetReserveAmmoCount.");

    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetVirtual(OFFSET_GetMaxClip1);
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
    if ((SDKCall_GetMaxClip1 = EndPrepSDKCall()) == null)
        SetFailState("Failed to prepare SDKCall SDKCall_GetMaxClip1.");
}

public void Pupd_OnCheckAllPlugins()
{
    Pupd_CheckPlugin(false, "https://build.kxnrl.com/updater/MiniGames/");
}

public void OnConfigsExecuted()
{
    FindConVar("ammo_338mag_max").SetInt(0);
    FindConVar("ammo_357sig_max").SetInt(0);
    FindConVar("ammo_357sig_min_max").SetInt(0);
    FindConVar("ammo_357sig_p250_max").SetInt(0);
    FindConVar("ammo_357sig_small_max").SetInt(0);
    FindConVar("ammo_45acp_max").SetInt(0);
    FindConVar("ammo_50AE_max").SetInt(0);
    FindConVar("ammo_556mm_box_max").SetInt(0);
    FindConVar("ammo_556mm_max").SetInt(0);
    FindConVar("ammo_556mm_small_max").SetInt(0);
    FindConVar("ammo_57mm_max").SetInt(0);
    FindConVar("ammo_762mm_max").SetInt(0);
    FindConVar("ammo_9mm_max").SetInt(0);
    FindConVar("ammo_buckshot_max").SetInt(0);
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (strncmp(classname, "weapon_", 7) == 0)
    {
        DHookEntity(DHook_GetReserveAmmoMax, false, entity, _, Event_GetReserveAmmoMax);
        SDKHook(entity, SDKHook_SpawnPost, Event_WeaponCreated);
    }

    if (strcmp(classname, "game_player_equip", false) == 0)
    {
        SDKHook(entity, SDKHook_UsePost, Event_OnUsePost);
    }
}

public void Event_WeaponCreated(int entity)
{
    SDKUnhook(entity, SDKHook_SpawnPost, Event_WeaponCreated);

    if (!IsValidEdict(entity))
        return;

    SDKCall(SDKCall_SetReserveAmmoCount, entity, 1, MAX_RESERVE_AMMO_MAX, true, -1);
}

public MRESReturn Event_GetReserveAmmoMax(int pThis, Handle hReturn, Handle hParams)
{
    if (!IsValidEdict(pThis))
        return MRES_Ignored;

    DHookSetReturn(hReturn, MAX_RESERVE_AMMO_MAX);

    return MRES_Supercede;
}

public void Event_OnUsePost(int entity, int client, int caller, UseType type, float value)
{
    if (!(0 < client <= MaxClients) || !IsPlayerAlive(client))
        return;

    char weapon[32];

    int size = GetEntPropArraySize(entity, Prop_Data, "m_weaponNames");
    int flag = GetEntProp(entity, Prop_Data, "m_spawnflags");

    for(int index; index < size; ++index)
    {
        GetEntPropString(entity, Prop_Data, "m_weaponNames", weapon, 32, index);
 
        if (strcmp(weapon, "weapon_usp_silencer", false) == 0)
            HandleUSP(client, flag);

        if (strcmp(weapon, "ammo_50AE", false) == 0)
            InfiniteAmmo(client);
    }
}

void HandleUSP(int client, int flags)
{
    int usp = GetPlayerWeaponSlot(client, 1);

    if (usp == -1)
    {
        RequestFrame(Utils_GivePlayerUsp, client);
        return;
    }

    if (flags & 2 || flags & 4)
    {
        RequestFrame(Utils_GivePlayerUsp, client);
        return;
    }
    else
    {
        char classname[32];
        if (GetWeaponClassname(usp, -1, classname, 32) > 0 && (strcmp(classname, "weapon_usp_silencer", false) == 0 || strcmp(classname, "weapon_hkp2000", false) == 0) && GetEntProp(usp, Prop_Send, "m_hPrevOwner") == -1)
            return;

        AcceptEntityInput(usp, "KillHierarchy");
    }

    Utils_GivePlayerUsp(client);
}

void Utils_GivePlayerUsp(int client)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return;

    GivePlayerItem(client, "weapon_usp_silencer");
}

void InfiniteAmmo(int client)
{
    ReserveAmmoClient(client, 0);
    ReserveAmmoClient(client, 1);
}

void ReserveAmmoClient(int client, int slot)
{
    int weapon = GetPlayerWeaponSlot(client, slot);

    if (weapon == -1)
        return;

    SetEntProp(weapon, Prop_Send, "m_iClip1", SDKCall(SDKCall_GetMaxClip1, weapon), 4, 0);
    SDKCall(SDKCall_SetReserveAmmoCount, weapon, 1, MAX_RESERVE_AMMO_MAX, true, -1);
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
