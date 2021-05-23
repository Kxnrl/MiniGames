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
#define PI_VERSION  "2.2." ... MYBUILD
#define PI_URL      "https://github.com/Kxnrl/MiniGames"

Handle g_AcceptInput;
ArrayList g_CvarList;
ConVar cs_enable_player_physics_box;

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

    cs_enable_player_physics_box = FindConVar("cs_enable_player_physics_box");
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

    if (StrContains(command, "mg_", false) == 0)
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

    // special convar
    // cs_enable_player_physics_box
    if (StrContains(command, "cs_enable_player_physics_box", false) > -1)
    {
        cs_enable_player_physics_box.BoolValue = true;
        PrintToConsoleAll("[BspConVar]  cs_enable_player_physics_box enabled");
        DHookSetReturn(hReturn, false);
        return MRES_Supercede;
    }

    if (StrContains(command, "sm", false) == 0)
    {
        LogMessage("[BspConVar]  Blocked sm command [%s]", command);
        DHookSetReturn(hReturn, false);
        return MRES_Supercede;
    }

    if (StrContains(command, "ammo_", false) == 0)
    {
        PrintToServer("[BspConVar]  Blocked ammo convar [%s]", command);
        DHookSetReturn(hReturn, false);
        return MRES_Supercede;
    }

    if (StrContains(command, "phys_", false) == 0)
    {
        PrintToServer("[BspConVar]  Blocked physics convar [%s]", command);
        DHookSetReturn(hReturn, false);
        return MRES_Supercede;
    }

    char values[2][32];
    int split = ExplodeString(command, " ", values, 2, 32);
    if (split == 2)
    {
        /*
        char whitelist[128]; bool isWhiteList = false;
        for(int index = 0; index < g_CvarList.Length; index++)
        {
            g_CvarList.GetString(index, whitelist, 128);
            if (strcmp(values[0], whitelist, false) == 0)
            {
                isWhiteList = true;
                break;
            }
        }

        if (!isWhiteList)
        {
            LogMessage("[BspConVar]  Blocked non-whitelist convar [%s]", command);
            DHookSetReturn(hReturn, false);
            return MRES_Supercede;
        }
        */

        if (g_CvarList.FindString(values[0]) == -1)
        {
            LogMessage("[BspConVar]  Blocked non-whitelist convar [%s]", command);
            DHookSetReturn(hReturn, false);
            return MRES_Supercede;
        }

        PrintToConsoleAll("[BspConVar]  [%s] -> [%s]", values[0], values[1]);
        ServerCommand("mg_setcvar %s %s", values[0], values[1]);

    }

    PrintToServer("[BspConVar]  Blocked unknow command [%s]", command);
    DHookSetReturn(hReturn, false);
    return MRES_Supercede;
}

void InitCvars()
{
    //SV
    g_CvarList.PushString("sv_friction");
    g_CvarList.PushString("sv_waterfriction");
    g_CvarList.PushString("sv_accelerate");
    g_CvarList.PushString("sv_airaccelerate");
    g_CvarList.PushString("sv_air_pushaway_dist");
    g_CvarList.PushString("sv_wateraccelerate");
    g_CvarList.PushString("sv_disable_show_team_select_menu");
    g_CvarList.PushString("sv_disable_radar");
    g_CvarList.PushString("sv_force_reflections");
    g_CvarList.PushString("sv_gravity");
    g_CvarList.PushString("sv_falldamage_scale");
    g_CvarList.PushString("sv_falldamage_to_below_player_multiplier");
    g_CvarList.PushString("sv_falldamage_to_below_player_ratio");
    g_CvarList.PushString("sv_health_approach_enabled");
    g_CvarList.PushString("sv_health_approach_speed");
    g_CvarList.PushString("sv_hegrenade_damage_multiplier");
    g_CvarList.PushString("sv_hegrenade_radius_multiplier");
    g_CvarList.PushString("sv_knife_attack_extend_from_player_aabb");
    g_CvarList.PushString("sv_buy_status_override");
    g_CvarList.PushString("sv_disable_immunity_alpha");
    g_CvarList.PushString("sv_disable_radar");
    g_CvarList.PushString("sv_env_entity_makers_enabled");
    g_CvarList.PushString("sv_extract_ammo_from_dropped_weapons");
    g_CvarList.PushString("sv_hide_roundtime_until_seconds");
    g_CvarList.PushString("sv_highlight_distance");
    g_CvarList.PushString("sv_highlight_duration");
    g_CvarList.PushString("sv_outofammo_indicator");
    g_CvarList.PushString("sv_staminajumpcost");
    g_CvarList.PushString("sv_staminalandcost");
    g_CvarList.PushString("sv_water_movespeed_multiplier");
    g_CvarList.PushString("sv_water_swim_mode");
    g_CvarList.PushString("sv_wateraccelerate");
    g_CvarList.PushString("sv_waterfriction");
    //sv_enablebunnyhopping

    // MP
    g_CvarList.PushString("mp_buy_anywhere");
    g_CvarList.PushString("mp_buytime");
    g_CvarList.PushString("mp_c4timer");
    g_CvarList.PushString("mp_damage_headshot_only");
    g_CvarList.PushString("mp_damage_scale_ct_body");
    g_CvarList.PushString("mp_damage_scale_ct_head");
    g_CvarList.PushString("mp_damage_scale_t_body");
    g_CvarList.PushString("mp_damage_scale_t_head");
    g_CvarList.PushString("mp_damage_vampiric_amount");
    g_CvarList.PushString("mp_falldamage");
    g_CvarList.PushString("mp_free_armor");
    g_CvarList.PushString("mp_max_armor");
    g_CvarList.PushString("mp_molotovusedelay");
    g_CvarList.PushString("mp_plant_c4_anywhere");
    g_CvarList.PushString("mp_respawn_on_death_ct");
    g_CvarList.PushString("mp_respawn_on_death_t");
    g_CvarList.PushString("mp_respawnwavetime");
    g_CvarList.PushString("mp_respawnwavetime_ct");
    g_CvarList.PushString("mp_respawnwavetime_t");
    g_CvarList.PushString("mp_roundtime");
    g_CvarList.PushString("mp_shield_speed_deployed");
    g_CvarList.PushString("mp_weapons_allow_map_placed");
    g_CvarList.PushString("mp_weapons_glow_on_ground");
    g_CvarList.PushString("healthshot_healthboost_damage_multiplier");
    g_CvarList.PushString("healthshot_healthboost_speed_multiplier");
    g_CvarList.PushString("healthshot_healthboost_time");
    g_CvarList.PushString("molotov_throw_detonate_time");
    g_CvarList.PushString("mp_anyone_can_pickup_c4");
    g_CvarList.PushString("mp_defuser_allocation");
    g_CvarList.PushString("mp_give_player_c4");
    g_CvarList.PushString("mp_global_damage_per_second");
    g_CvarList.PushString("mp_tagging_scale");
    g_CvarList.PushString("mp_taser_recharge_time");
    g_CvarList.PushString("mp_teammates_are_enemies");
    g_CvarList.PushString("mp_weapon_self_inflict_amount");
}