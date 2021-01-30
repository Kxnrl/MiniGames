#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <sdkhooks>
#include <minigames>

#undef REQUIRE_PLUGIN
#include <fys.pupd>
#define REQUIRE_PLUGIN

#define PI_NAME     "MiniGames - BSP Cvars"
#define PI_AUTHOR   "Kyle 'Kxnrl' Frankiss"
#define PI_DESC     "DARLING in the FRANXX"
#define PI_VERSION  "2.1." ... MYBUILD
#define PI_URL      "https://github.com/Kxnrl/MiniGames"

Handle g_AcceptInput;
ArrayList g_CvarList;

public Plugin myinfo = 
{
    name        = PI_NAME,
    author      = PI_AUTHOR,
    description = PI_DESC,
    version     = PI_VERSION,
    url         = PI_URL
};

public void OnPluginStart()
{
    GameData conf = new GameData("sdktools.games\\engine.csgo");
    if (conf == null)
        SetFailState("Failed to load gamedata.");

    int offset = conf.GetOffset("AcceptInput"); delete conf;
    if (offset == -1)
        SetFailState("Failed to get offset of \"AcceptInput\".");

    g_AcceptInput = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity);
    if (g_AcceptInput == null)
        SetFailState("Failed to DHook \"AcceptInput\".");

    DHookAddParam(g_AcceptInput, HookParamType_CharPtr);
    DHookAddParam(g_AcceptInput, HookParamType_CBaseEntity);
    DHookAddParam(g_AcceptInput, HookParamType_CBaseEntity);
    DHookAddParam(g_AcceptInput, HookParamType_Object, 20);
    DHookAddParam(g_AcceptInput, HookParamType_Int);

    g_CvarList = new ArrayList(ByteCountToCells(128));
    InitCvars();
}

public void Pupd_OnCheckAllPlugins()
{
    Pupd_CheckPlugin(false, "https://build.kxnrl.com/updater/MiniGames/");
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (strcmp(classname, "point_servercommand", false) == 0)
        DHookEntity(g_AcceptInput, false, entity, _, Event_AcceptInput);
}

public MRESReturn Event_AcceptInput(int pThis, Handle hReturn, Handle hParams)
{
    if (!IsValidEntity(pThis))
        return MRES_Ignored;

    char input[32];
    DHookGetParamString(hParams, 1, input, 32);

    if (strcmp(input, "Command", false) != 0)
    {
        // 忽略
        return MRES_Ignored;
    }

    if (DHookGetParamObjectPtrVar(hParams, 4, 16,ObjectValueType_Int) != 2)
    {
        // wrong input type;
        return MRES_Ignored;
    }

    char command[256];
    DHookGetParamObjectPtrString(hParams, 4, 0, ObjectValueType_String, command, 256);

    if (StrContains(command, "echo", false) == 0)
    {
        // echo command
        return MRES_Ignored;
    }

    if (StrContains(command, "acts", false) == 0)
    {
        ServerCommand("%s", command);
        DHookSetReturn(hReturn, false);
        return MRES_Supercede;
    }

    if (StrContains(command, "say", false) == 0)
    {
        // override
        ServerCommand("%s", command);
        DHookSetReturn(hReturn, false);
        return MRES_Supercede;
    }

    if (StrContains(command, "sm_say", false) == 0)
    {
        // override
        ReplaceString(command, 256, "sm_say", "say", false);
        ServerCommand("%s", command);
        DHookSetReturn(hReturn, false);
        return MRES_Supercede;
    }

    if (StrContains(command, "sm", false) == 0)
    {
        LogMessage("[BSP CVAR]  Blocked sm command [%s]", command);
        DHookSetReturn(hReturn, false);
        return MRES_Supercede;
    }

    if (StrContains(command, "sv_", false) == 0)
    {
        char whitelist[128]; bool isWhiteList = false;
        for(int index = 0; index < g_CvarList.Length; index++)
        {
            g_CvarList.GetString(index, whitelist, 128);
            if (StrContains(command, whitelist, false) != -1)
            {
                isWhiteList = true;
                break;
            }
        }

        if (!isWhiteList)
        {
            LogMessage("[BSP CVAR]  Blocked sv convar [%s]", command);
            DHookSetReturn(hReturn, false);
            return MRES_Supercede;
        }
    }

    if (StrContains(command, "ammo_", false) == 0)
    {
        PrintToServer("[BSP CVAR]  Blocked ammo convar [%s]", command);
        DHookSetReturn(hReturn, false);
        return MRES_Supercede;
    }

    char values[4][32];
    int split = ExplodeString(command, " ", values, 4, 32);
    if (split == 2)
    {
        if (strcmp(values[0], "mp_startmoney") == 0 || strcmp(values[0], "mp_freezetime") == 0 || strcmp(values[0], "mp_flashlight") == 0 || strcmp(values[0], "host_timescale") == 0)
        {
            DHookSetReturn(hReturn, false);
            return MRES_Supercede;
        }

        PrintToConsoleAll("[地图参数]  修改 [%s] 值: %s", values[0], values[1]);
        ServerCommand("mg_setcvar %s %s", values[0], values[1]);
    }
    else
    {
        PrintToConsoleAll("[地图参数]   %s", command);
        ServerCommand("%s", command);
    }

    DHookSetReturn(hReturn, false);
    return MRES_Supercede;
}

void InitCvars()
{
    g_CvarList.PushString("sv_friction");
    g_CvarList.PushString("sv_waterfriction");

    g_CvarList.PushString("sv_accelerate");
    g_CvarList.PushString("sv_airaccelerate");
    g_CvarList.PushString("sv_wateraccelerate");

    g_CvarList.PushString("sv_disable_show_team_select_menu");
    g_CvarList.PushString("sv_disable_radar");
    g_CvarList.PushString("sv_force_reflections");
    g_CvarList.PushString("sv_gravity");

    g_CvarList.PushString("sv_health_approach_enabled");
    g_CvarList.PushString("sv_health_approach_speed");

    g_CvarList.PushString("sv_hegrenade_damage_multiplier");
    g_CvarList.PushString("sv_hegrenade_radius_multiplier");
    
    g_CvarList.PushString("sv_knife_attack_extend_from_player_aabb");
}