/******************************************************************/
/*                                                                */
/*                         MiniGames Core                         */
/*                                                                */
/*                                                                */
/*  File:          cvars.sp                                       */
/*  Description:   MiniGames Game Mod.                            */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2018  Kyle                                      */
/*  2018/03/05 16:51:01                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/


static ConVar mp_ct_default_melee;
static ConVar mp_ct_default_primary;
static ConVar mp_ct_default_secondary;
static ConVar mp_t_default_melee;
static ConVar mp_t_default_primary;
static ConVar mp_t_default_secondary;
static ConVar sv_tags;


void Cvars_OnPluginStart()
{
    mg_restrictawp      = CreateConVar("mg_restrictawp", "0", "", _, true, 0.0, true, 1.0);
    mg_slaygaygun       = CreateConVar("mg_slaygaygun", "1", "", _, true, 0.0, true, 1.0);
    mg_spawn_knife      = CreateConVar("mg_spawn_knife", "0", "", _, true, 0.0, true, 1.0);
    mg_spawn_pistol     = CreateConVar("mg_spawn_pistol", "0", "", _, true, 0.0, true, 1.0);
    mg_spawn_kevlar     = CreateConVar("mg_spawn_kevlar", "0", "", _, true, 0.0, true, 100.0);
    mg_spawn_helmet     = CreateConVar("mg_spawn_helmet", "0", "", _, true, 0.0, true, 1.0);
    mg_bhopspeed        = CreateConVar("mg_bhopspeed", "250.0", "bhop speed limit", _, true, 200.0, true, 3500.0);
    mg_randomteam       = CreateConVar("mg_randomteam", "1", "scrable team", _, true, 0.0, true, 1.0);
    mg_wallhack_delay   = CreateConVar("mg_wallhack_delay", "150.0", "how many seconds wallhack all after round start", _, true, 60.0, true, 600.0);

    mp_ct_default_melee         = FindConVar("mp_ct_default_melee");
    mp_ct_default_primary       = FindConVar("mp_ct_default_primary");
    mp_ct_default_secondary     = FindConVar("mp_ct_default_secondary");
    mp_t_default_melee          = FindConVar("mp_t_default_melee");
    mp_t_default_primary        = FindConVar("mp_t_default_primary");
    mp_t_default_secondary      = FindConVar("mp_t_default_secondary");
    mp_warmuptime               = FindConVar("mp_warmuptime");

    sv_tags                = FindConVar("sv_tags");
    sv_enablebunnyhopping  = FindConVar("sv_enablebunnyhopping");

    mp_ct_default_melee.AddChangeHook(Cvars_OnSettingChanged);
    mp_ct_default_primary.AddChangeHook(Cvars_OnSettingChanged);
    mp_ct_default_secondary.AddChangeHook(Cvars_OnSettingChanged);
    mp_t_default_melee.AddChangeHook(Cvars_OnSettingChanged);
    mp_t_default_primary.AddChangeHook(Cvars_OnSettingChanged);
    mp_t_default_secondary.AddChangeHook(Cvars_OnSettingChanged);

    AutoExecConfig(true, "minigames");
}

public void Cvars_OnSettingChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    Cvars_LockedConVar();
}

static void Cvars_LockedConVar()
{
    mp_ct_default_melee.SetString("", true, false);
    mp_ct_default_primary.SetString("", true, false);
    mp_ct_default_secondary.SetString("", true, false);
    mp_t_default_melee.SetString("", true, false);
    mp_t_default_primary.SetString("", true, false);
    mp_t_default_secondary.SetString("", true, false);
    sv_tags.SetString("MG,MiniGames,MultiGames,Shop", false, false);
}

static void Cvars_SetCvarDefault()
{
    FindConVar("phys_pushscale").SetInt(3);
    FindConVar("phys_timescale").SetInt(1);
    FindConVar("sv_damage_print_enable").SetInt(1);
    FindConVar("sv_staminamax").SetInt(0);
    FindConVar("sv_staminajumpcost").SetInt(0);
    FindConVar("sv_staminalandcost").SetInt(0);
    FindConVar("sv_staminarecoveryrate").SetInt(0);
    FindConVar("sv_airaccelerate").SetInt(9999);
    FindConVar("sv_accelerate_use_weapon_speed").SetInt(0);
    FindConVar("sv_maxvelocity").SetInt(3500);
    FindConVar("sv_full_alltalk").SetInt(1);
    FindConVar("mp_limitteams").SetInt(0);
    FindConVar("mp_autoteambalance").SetInt(0);

    Cvars_LockedConVar();
}

void Cvars_OnAutoConfigsBuffered()
{
    Cvars_SetCvarDefault();
    
    char mapconfig[256];

    GetCurrentMap(mapconfig, 256);
    LogMessage("Searching %s.cfg", mapconfig);
    Format(mapconfig, 256, "sourcemod/map-configs/%s.cfg", mapconfig);

    char path[256];
    Format(path, 256, "cfg/%s", mapconfig);

    if(!FileExists(path))
    {
        LogMessage("File does not exists %s", mapconfig);
        return;
    }

    ServerCommand("exec %s", mapconfig);
    LogMessage("Executed %s", mapconfig);
}