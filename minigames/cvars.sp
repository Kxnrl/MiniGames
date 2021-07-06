/******************************************************************/
/*                                                                */
/*                         MiniGames Core                         */
/*                                                                */
/*                                                                */
/*  File:          cvars.sp                                       */
/*  Description:   MiniGames Game Mod.                            */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2020  Kyle                                      */
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
static ConVar sv_staminamax;
static ConVar sv_staminajumpcost;
static ConVar sv_staminalandcost;
static ConVar sv_staminarecoveryrate;
static ConVar sv_autobunnyhopping;
static ConVar sv_timebetweenducks;
static ConVar phys_pushscale;
static ConVar cs_enable_player_physics_box;
static ConVar sv_standable_normal;
static ConVar sv_turbophysics;
static ConVar sv_disable_radar;
static ConVar sv_gameinstructor_disable;
static ConVar sv_fistpunch_damage_to_player_multiplier;
static ConVar mp_taser_recharge_time;
static ConVar sv_competitive_official_5v5;

static ConVar sv_teamid_overhead_always_prohibit;
static ConVar sv_show_team_equipment_prohibit;
static ConVar sv_teamid_overhead;
static ConVar mp_playerid;

static ConVar mp_join_grace_time;
static ConVar mp_freezetime;

static bool  t_LastEBhop;
static bool  t_LastABhop;
static float t_LastSpeed;

void Cvars_OnPluginStart()
{
    // Configs file
    AutoExecConfig_SetCreateDirectory(true);
    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("com.kxnrl.minigames");

    // Version convar
    AutoExecConfig_CreateConVar("minigames_version", PI_VERSION, "Current MiniGames version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

    mg_restrict_awp         = AutoExecConfig_CreateConVar("mg_restrict_awp",        "0",        "Restrict use AWP",                                                 _, true, 0.0,   true, 1.0);
    mg_restrict_machinegun  = AutoExecConfig_CreateConVar("mg_restrict_machinegun", "0",        "Restrict use machine gun",                                         _, true, 0.0,   true, 1.0);
    mg_slaygaygun           = AutoExecConfig_CreateConVar("mg_slaygaygun",          "1",        "Slay player who uses gaygun",                                      _, true, 0.0,   true, 1.0);
    mg_spawn_knife          = AutoExecConfig_CreateConVar("mg_spawn_knife",         "0",        "Give knife On player spawn",                                       _, true, 0.0,   true, 1.0);
    mg_spawn_pistol         = AutoExecConfig_CreateConVar("mg_spawn_pistol",        "0",        "Give pistol On player spawn",                                      _, true, 0.0,   true, 1.0);
    mg_spawn_kevlar         = AutoExecConfig_CreateConVar("mg_spawn_kevlar",        "0",        "Give kevlar On player spawn",                                      _, true, 0.0,   true, 100.0);
    mg_spawn_helmet         = AutoExecConfig_CreateConVar("mg_spawn_helmet",        "0",        "Give helmet On player spawn",                                      _, true, 0.0,   true, 1.0);
    mg_bhopspeed            = AutoExecConfig_CreateConVar("mg_bhopspeed",           "250.0",    "Max bunnyhopping speed(requires sv_enablebunnyhopping set to 1)",  _, true, 200.0, true, 3500.0);
    mg_randomteam           = AutoExecConfig_CreateConVar("mg_randomteam",          "1",        "Scramble Team after Round End",                                    _, true, 0.0,   true, 1.0);
    mg_wallhack_delay       = AutoExecConfig_CreateConVar("mg_wallhack_delay",      "150.0",    "VAC WALLHACK timer (Seconds)",                                     _, true, 60.0,  true, 180.0);
    mg_transmitblock        = AutoExecConfig_CreateConVar("mg_transmitblock",       "1",        "Allow client hide teammate.",                                      _, true, 0.0,   true, 1.0);
    mg_geoiplanguage        = AutoExecConfig_CreateConVar("mg_geoiplanguage",       "en",       "Language of GeoIP2-City. \nList of language: \nBrazilian Portuguese (pt-BR), English (en), French (fr), German (de), Japanese (ja), Russian (ru), Simplified Chinese (zh-CN), and Spanish (es)");
    mg_render_player        = AutoExecConfig_CreateConVar("mg_render_player",       "0",        "Allow render player model color.",                                 _, true, 0.0,   true, 1.0);
    mg_block_keybind_cj     = AutoExecConfig_CreateConVar("mg_block_keybind_cj",    "1",        "Block keybind crouch jump.",                                       _, true, 0.0,   true, 1.0);
    mg_button_watcher       = AutoExecConfig_CreateConVar("mg_button_watcher",      "1",        "Print button usage info.",                                         _, true, 0.0,   true, 1.0);
    mg_broadcast_leave      = AutoExecConfig_CreateConVar("mg_broadcast_leave",     "0",        "Broadcast on client disconnect.",                                  _, true, 0.0,   true, 1.0);
    mg_slap_after_vac       = AutoExecConfig_CreateConVar("mg_slap_after_vac",      "1",        "Slap player after vac timer elapsed.",                             _, true, 0.0,   true, 1.0);
    mg_rank_skillgroups     = AutoExecConfig_CreateConVar("mg_rank_skillgroups",    "1",        "Display skill groups on scoreboard.",                              _, true, 0.0,   true, 1.0);

    mg_bonus_kill_via_gun     = AutoExecConfig_CreateConVar("mg_bonus_kill_via_gun",       "3", "How many credits to earn when player kill enemy with gun",                _, true, 0.0, true, 1000.0);
    mg_bonus_kill_via_gun_hs  = AutoExecConfig_CreateConVar("mg_bonus_kill_via_gun_hs",    "4", "How many credits to earn when player kill enemy with gun and headshot",   _, true, 0.0, true, 1000.0);
    mg_bonus_kill_via_knife   = AutoExecConfig_CreateConVar("mg_bonus_kill_via_knife",     "3", "How many credits to earn when player kill enemy with knife",              _, true, 0.0, true, 1000.0);
    mg_bonus_kill_via_taser   = AutoExecConfig_CreateConVar("mg_bonus_kill_via_taser",     "5", "How many credits to earn when player kill enemy with taser",              _, true, 0.0, true, 1000.0);
    mg_bonus_kill_via_inferno = AutoExecConfig_CreateConVar("mg_bonus_kill_via_inferno",   "3", "How many credits to earn when player kill enemy with molotov/incendiary", _, true, 0.0, true, 1000.0);
    mg_bonus_kill_via_grenade = AutoExecConfig_CreateConVar("mg_bonus_kill_via_grenade",   "3", "How many credits to earn when player kill enemy with HE grenade",         _, true, 0.0, true, 1000.0);
    mg_bonus_kill_via_dodge   = AutoExecConfig_CreateConVar("mg_bonus_kill_via_dodge",     "5", "How many credits to earn when player kill enemy with Dodge ball",         _, true, 0.0, true, 1000.0);
    mg_bonus_survival         = AutoExecConfig_CreateConVar("mg_bonus_survival",           "2", "How many credits to earn when player survive",                            _, true, 0.0, true, 1000.0);
    mg_bonus_assist           = AutoExecConfig_CreateConVar("mg_bonus_assist",             "1", "How many credits to earn when player assist kills",                       _, true, 0.0, true, 1000.0);
    mg_bonus_requires_players = AutoExecConfig_CreateConVar("mg_bonus_requires_players",   "8", "How many player requires to enable bouns",                                _, true, 1.0, true,   64.0);
    mg_bonus_max_round_credits= AutoExecConfig_CreateConVar("mg_bonus_max_round_credits",  "5", "Max credtis can be earned per round",                                     _, true, 0.0, true, 1000.0);

    mp_ct_default_melee         = FindConVar("mp_ct_default_melee");
    mp_ct_default_primary       = FindConVar("mp_ct_default_primary");
    mp_ct_default_secondary     = FindConVar("mp_ct_default_secondary");
    mp_t_default_melee          = FindConVar("mp_t_default_melee");
    mp_t_default_primary        = FindConVar("mp_t_default_primary");
    mp_t_default_secondary      = FindConVar("mp_t_default_secondary");
    sv_tags                     = FindConVar("sv_tags");
    sv_enablebunnyhopping       = FindConVar("sv_enablebunnyhopping");
    sv_autobunnyhopping         = FindConVar("sv_autobunnyhopping");
    sv_timebetweenducks         = FindConVar("sv_timebetweenducks");
    sv_staminamax               = FindConVar("sv_staminamax");
    sv_staminajumpcost          = FindConVar("sv_staminajumpcost");
    sv_staminalandcost          = FindConVar("sv_staminalandcost");
    sv_staminarecoveryrate      = FindConVar("sv_staminarecoveryrate");
    sv_standable_normal         = FindConVar("sv_standable_normal");
    sv_disable_radar            = FindConVar("sv_disable_radar");
    mp_join_grace_time          = FindConVar("mp_join_grace_time");
    mp_freezetime               = FindConVar("mp_freezetime");
    mp_damage_headshot_only     = FindConVar("mp_damage_headshot_only");
    mp_taser_recharge_time      = FindConVar("mp_taser_recharge_time");
    mp_teammates_are_enemies    = FindConVar("mp_teammates_are_enemies");
    sv_competitive_official_5v5 = FindConVar("sv_competitive_official_5v5");

    sv_gameinstructor_disable                = FindConVar("sv_gameinstructor_disable");
    sv_fistpunch_damage_to_player_multiplier = FindConVar("sv_fistpunch_damage_to_player_multiplier");

    sv_teamid_overhead_always_prohibit = FindConVar("sv_teamid_overhead_always_prohibit");
    sv_show_team_equipment_prohibit    = FindConVar("sv_show_team_equipment_prohibit");
    sv_teamid_overhead                 = FindConVar("sv_teamid_overhead");
    mp_playerid                        = FindConVar("mp_playerid");

    phys_pushscale               = FindConVar("phys_pushscale");
    cs_enable_player_physics_box = FindConVar("cs_enable_player_physics_box");
    sv_turbophysics              = FindConVar("sv_turbophysics");

    mp_ct_default_melee.AddChangeHook(Cvars_OnSettingChanged);
    mp_ct_default_primary.AddChangeHook(Cvars_OnSettingChanged);
    mp_ct_default_secondary.AddChangeHook(Cvars_OnSettingChanged);
    mp_t_default_melee.AddChangeHook(Cvars_OnSettingChanged);
    mp_t_default_primary.AddChangeHook(Cvars_OnSettingChanged);
    mp_t_default_secondary.AddChangeHook(Cvars_OnSettingChanged);
    sv_autobunnyhopping.AddChangeHook(Cvars_OnSettingChanged);
    sv_enablebunnyhopping.AddChangeHook(Cvars_OnSettingChanged);

    mp_teammates_are_enemies.AddChangeHook(Cvars_OnFFAChanged);

    mp_join_grace_time.AddChangeHook(Cvars_OnLateSpawnChanged);
    mp_freezetime.AddChangeHook(Cvars_OnLateSpawnChanged);

    if (!DirExists("cfg/sourcemod/map-configs"))
    {
        CreateDirectory("cfg/sourcemod/map-configs", 511);
        LogMessage("Created cfg/sourcemod/map-configs");
    }

    // AutoExec
    AutoExecConfig_ExecuteFile();

    // Bhop
    RegServerCmd("mg_setbhop_allow", Command_SetBhopAllow);
    RegServerCmd("mg_setbhop_auto",  Command_SetBhopAuto);
    RegServerCmd("mg_setbhop_speed", Command_SetBhopSpeed);

    // Vac
    RegServerCmd("mg_add_vac_timer", Command_VacTimer);

    // Cvar
    RegServerCmd("mg_setcvar", Command_SetCvar);

    HookEvent("server_cvar", MuteConVarChanged, EventHookMode_Pre);

    // GENERATE CONFIG
    CreateAllMapConfigs();
}

public void Cvars_OnFFAChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    Hooks_UpdateState();
}

public void Cvars_OnSettingChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    mp_ct_default_melee.SetString("", true, false);
    mp_ct_default_primary.SetString("", true, false);
    mp_ct_default_secondary.SetString("", true, false);
    mp_t_default_melee.SetString("", true, false);
    mp_t_default_primary.SetString("", true, false);
    mp_t_default_secondary.SetString("", true, false);
    sv_tags.SetString("MG,MiniGames,Shop,Store,Skin", true, true);

    if (sv_enablebunnyhopping.BoolValue)
    {
        sv_staminamax.SetInt(0, true, false);
        sv_staminajumpcost.SetInt(0, true, false);
        sv_staminalandcost.SetInt(0, true, false);
        sv_staminarecoveryrate.SetInt(0, true, false);
    }
    else
    {
        sv_staminamax.SetFloat(100.0, true, false);
        sv_staminajumpcost.SetFloat(0.08, true, false);
        sv_staminalandcost.SetFloat(0.04, true, false);
        sv_staminarecoveryrate.SetFloat(60.0, true, false);
    }

    if (g_extMovementManager)
    {
        ConVar_Easy_SetInt("sm_movement_unlocker_ct", sv_enablebunnyhopping.BoolValue ? 2 : 0, true, false);
        ConVar_Easy_SetInt("sm_movement_unlocker_te", sv_enablebunnyhopping.BoolValue ? 2 : 0, true, false);
    }
}

public void Cvars_OnLateSpawnChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (convar == mp_freezetime)
    {
        float newVal = StringToFloat(newValue);
        if (newVal < 3.0)
        {
            newVal = 3.0;
            ConVar_Easy_SetFlo("mp_freezetime", newVal, true, false);
        }

        ConVar_Easy_SetFlo("mp_join_grace_time", newVal, true, false);
    }
    else if (convar == mp_join_grace_time)
    {
        float newVal = StringToFloat(newValue);
        if (newVal != mp_freezetime.FloatValue)
        {
            ConVar_Easy_SetFlo("mp_join_grace_time", mp_freezetime.FloatValue, true, false);
        }
    }
}

static void Cvars_SetCvarDefault()
{
    ConVar_Easy_SetInt("mp_autokick",                       0, true, false);
    ConVar_Easy_SetInt("mp_buytime",                       60, true, false);
    ConVar_Easy_SetInt("mp_roundtime_hostage",              0, true, false);
    ConVar_Easy_SetInt("mp_roundtime_defuse",               0, true, false);
    ConVar_Easy_SetInt("mp_death_drop_defuser",             0, true, false);
    ConVar_Easy_SetInt("mp_death_drop_grenade",             1, true, false);
    ConVar_Easy_SetInt("mp_death_drop_gun",                 1, true, false);
    ConVar_Easy_SetInt("mp_defuser_allocation",             0, true, false);
    ConVar_Easy_SetInt("mp_playercashawards",               0, true, false);
    ConVar_Easy_SetInt("mp_teamcashawards",                 0, true, false);
    ConVar_Easy_SetInt("mp_weapons_allow_zeus",             1, true, false);
    ConVar_Easy_SetInt("mp_weapons_allow_map_placed",       1, true, false);
    ConVar_Easy_SetInt("mp_friendlyfire",                   0, true, false);
    ConVar_Easy_SetInt("mp_autoteambalance",                0, true, false);
    ConVar_Easy_SetInt("mp_limitteams",                     0, true, false);
    ConVar_Easy_SetInt("mp_force_pick_time",               15, true, false);
    ConVar_Easy_SetInt("mp_display_kill_assists",           1, true, false);
    ConVar_Easy_SetInt("mp_maxrounds",                      0, true, false);
    ConVar_Easy_SetInt("mp_halftime",                       0, true, false);
    ConVar_Easy_SetInt("mp_match_can_clinch",               0, true, false);
    ConVar_Easy_SetInt("phys_timescale",                    1, true, false);
    ConVar_Easy_SetInt("sv_damage_print_enable",            0, true, false);
    ConVar_Easy_SetInt("sv_airaccelerate",               9999, true, false);
    ConVar_Easy_SetInt("sv_accelerate_use_weapon_speed",    0, true, false);
    ConVar_Easy_SetInt("sv_maxvelocity",                 3500, true, false);
    ConVar_Easy_SetInt("sv_allow_votes",                    0, true, false);
    ConVar_Easy_SetInt("sv_full_alltalk",                   1, true, false);
    ConVar_Easy_SetInt("sv_talk_enemy_living",              1, true, false);
    ConVar_Easy_SetInt("sv_talk_enemy_dead",                1, true, false);
    ConVar_Easy_SetInt("sv_clamp_unsafe_velocities",        1, true, false); // github.com/Kxnrl/sm-ext-MovementManager
    ConVar_Easy_SetInt("sv_friction",                       5, true, false);
    ConVar_Easy_SetInt("sv_ignoregrenaderadio",             1, true, false);
    ConVar_Easy_SetInt("sv_infinite_ammo",                  0, true, false);
    ConVar_Easy_SetInt("sv_teamid_overhead_maxdist",     1500, true, false);
    ConVar_Easy_SetInt("weapon_reticle_knife_show",         1, true, false);
    ConVar_Easy_SetInt("mp_equipment_reset_rounds",         1, true, false);

    sv_timebetweenducks.SetFloat(0.4, true, false);

    sv_gameinstructor_disable.BoolValue = true;
    sv_fistpunch_damage_to_player_multiplier.FloatValue = 0.0;

    sv_staminamax.SetFloat(         100.0, true, false);
    sv_staminajumpcost.SetFloat(     0.08, true, false);
    sv_staminalandcost.SetFloat(     0.04, true, false);
    sv_staminarecoveryrate.SetFloat( 60.0, true, false);

    sv_teamid_overhead_always_prohibit.SetBool(true,  true, false);
    sv_show_team_equipment_prohibit.SetBool   (true,  true, false);
    sv_teamid_overhead.SetBool                (true,  true, false);
    mp_playerid.SetInt                        (2,     true, false);

    phys_pushscale.SetInt              ( 24, true, true);
    cs_enable_player_physics_box.SetInt(  0, true, true);
    sv_turbophysics.SetInt             (  0, true, true);

    sv_autobunnyhopping.SetInt(0, true, false);

    mp_join_grace_time.SetInt(  3, true, false);
    mp_freezetime.SetInt(       3, true, false);

    sv_tags.SetString("MG,MiniGames,FUN,Skin", false, false);
}

static void Cvars_EnforceOptions()
{
    // network
    ConVar_Easy_SetInt("sv_maxrate",             0, true, false); 
    ConVar_Easy_SetInt("sv_minrate",        128000, true, false); 
    ConVar_Easy_SetInt("sv_minupdaterate",     128, true, false);
    ConVar_Easy_SetInt("sv_mincmdrate",        128, true, false);

    // optimized
    ConVar_Easy_SetInt("net_splitrate",             2, true, false);
    ConVar_Easy_SetInt("sv_parallel_send",          1, true, false);
    ConVar_Easy_SetInt("sv_parallel_packentities",  1, true, false);
    ConVar_Easy_SetInt("sv_parallel_sendsnapshot",  1, true, false); 
    ConVar_Easy_SetInt("sv_enable_delta_packing",   1, true, false); 
    ConVar_Easy_SetFlo("sv_maxunlag", 0.07, true, false);

    // phys
    ConVar_Easy_SetInt("phys_enable_experimental_optimizations", 1, true, false);

    // 
    ConVar_Easy_SetInt("sv_server_verify_blood_on_player", 0, true, false);

    // sv var
    ConVar_Easy_SetInt("sv_alternateticks",         1, true, false);
    ConVar_Easy_SetInt("sv_forcepreload",           0, true, false);
    ConVar_Easy_SetInt("sv_force_transmit_players", 0, true, false);
    ConVar_Easy_SetInt("sv_force_transmit_ents",    0, true, false);
    ConVar_Easy_SetInt("sv_occlude_players",        1, true, false);

    // store module
    ConVar_Easy_SetInt("store_thirdperson_enabled", 0, true, false);
}

void Cvars_OnConfigsExecuted()
{
    // set default convars
    Cvars_SetCvarDefault();
    Cvars_EnforceOptions();
    Cvars_LoadMapConfigs();
    Cvars_CheckMapRadars();
}

static void CreateAllMapConfigs()
{
    DirectoryListing dir = OpenDirectory("maps");
    if (dir == null)
    {
        LogError("CreateAllMapConfigs -> Failed to open maps.");
        return;
    }

    FileType type = FileType_Unknown;
    char map[128], path[256];
    while(dir.GetNext(map, 128, type))
    {
        if (type != FileType_File || StrContains(map, ".bsp", false) == -1)
            continue;

        int c = FindCharInString(map, '.', true);
        map[c] = '\0';

        if (!IsMapValid(map))
        {
            LogError("CreateAllMapConfigs -> %s is invalid map.", map);
            continue;
        }

        FormatEx(path, 128, "cfg/sourcemod/map-configs/%s.cfg", map);

        if (!FileExists(path))
        {
            GenerateMapConfigs(map, path);
            LogMessage("[%s] does not exists, Auto-generated.", path);
        }
    }
    delete dir;
}

static void Cvars_LoadMapConfigs()
{
    // load map config
    char map[128], mapconfig[256], path[256];
    GetCurrentMap(map, 256);
    LogMessage("Searching %s.cfg", map);
    FormatEx(mapconfig, 256, "sourcemod/map-configs/%s.cfg", map);
    FormatEx(path, 256, "cfg/%s", mapconfig);

    if (!FileExists(path))
    {
        GenerateMapConfigs(map, path);
        LogMessage("[%s] does not exists, Auto-generated.", mapconfig);
        return;
    }

    ServerCommand("exec %s", mapconfig);
    LogMessage("Executed %s", mapconfig);
}

static void GenerateMapConfigs(const char[] map, const char[] path)
{
    File file = OpenFile(path, "w+");

    if (file == null)
    {
        LogError("Failed to create [%s]", path);
        return;
    }

    file.WriteLine("// This file was auto-generated by %s (v%s) (https://github.com/Kxnrl/MiniGames)", PI_NAME, PI_VERSION);
    file.WriteLine("// ConVars for map \"%s\"", map);

    file.WriteLine("");
    file.WriteLine("");

    //Round Time
    file.WriteLine("// 设置回合时间(分钟)");
    file.WriteLine("// Set Round Time(Minutes)");
    file.WriteLine("mp_roundtime \"5.0\"");
    file.WriteLine("");

    //Time limit
    file.WriteLine("// 地图时间(分钟)");
    file.WriteLine("// Set Map Timelimit(Minutes)");
    file.WriteLine("mp_timelimit \"40\"");
    file.WriteLine("");

    //Auto bunnyhopping
    file.WriteLine("// 自动连跳开关(按住空格连跳)");
    file.WriteLine("// Auto bunnyhopping(Hold +jump)");
    file.WriteLine("sv_autobunnyhopping \"1\"");
    file.WriteLine("");

    //Allow bunnyhopping
    file.WriteLine("// BHOP限制类型(允许超过250低速)");
    file.WriteLine("// Allow bunnyhopping(Landing speed > 250)");
    file.WriteLine("sv_enablebunnyhopping \"0\"");
    file.WriteLine("");

    //Bhop max speed
    file.WriteLine("// BHOP地速上限(需要sv_enablebunnyhopping设置为1)");
    file.WriteLine("// Max bunnyhopping speed(requires sv_enablebunnyhopping set to 1)");
    file.WriteLine("mg_bhopspeed \"300.0\"");
    file.WriteLine("");

    //Max flashbang
    file.WriteLine("// 最大携带闪光");
    file.WriteLine("// How many flashbangs for each player can carry");
    file.WriteLine("ammo_grenade_limit_flashbang \"1\"");
    file.WriteLine("");

    //Man grenade
    file.WriteLine("// 最大携带手雷(个)");
    file.WriteLine("// How many grenade for each player can carry");
    file.WriteLine("ammo_grenade_limit_total \"1\"");
    file.WriteLine("");

    //Gravity
    file.WriteLine("// 重力(单位)");
    file.WriteLine("// Gravity");
    file.WriteLine("sv_gravity \"790\"");
    file.WriteLine("");

    //Random switch team
    file.WriteLine("// 随机组队");
    file.WriteLine("// Scramble Team after Round End");
    file.WriteLine("mg_randomteam \"1\"");
    file.WriteLine("");

    //Give pistol on spawn
    file.WriteLine("// 出生发手枪");
    file.WriteLine("// Give pistol On player spawn");
    file.WriteLine("mg_spawn_pistol \"0\"");
    file.WriteLine("");

    //Give knife on spawn
    file.WriteLine("// 出生发刀");
    file.WriteLine("// Give knife On player spawn");
    file.WriteLine("mg_spawn_knife \"0\"");
    file.WriteLine("");

    //Give kevlar on spawn
    file.WriteLine("// 出生护甲(数值0~100)");
    file.WriteLine("// Give kevlar On player spawn (value 0~100)");
    file.WriteLine("mg_spawn_kevlar \"0\"");
    file.WriteLine("");

    //Give helmet on spawn
    file.WriteLine("// 出生头盔");
    file.WriteLine("// Give helmet On player spawn");
    file.WriteLine("mg_spawn_helmet \"0\"");
    file.WriteLine("");

    //Taser recharge time
    file.WriteLine("// 电击枪充电时间(秒)");
    file.WriteLine("// Determines recharge time for taser (Seconds)");
    file.WriteLine("mp_taser_recharge_time \"15\"");
    file.WriteLine("");

    //Restrict AWP
    file.WriteLine("// 禁止使用AWP(1为启用)");
    file.WriteLine("// Restrict use AWP");
    file.WriteLine("mg_restrict_awp \"0\"");
    file.WriteLine("");

    //Restrict Mahine gun
    file.WriteLine("// 禁止使用机枪(1为启用)");
    file.WriteLine("// Restrict use Machine gun");
    file.WriteLine("mg_restrict_machinegun \"0\"");
    file.WriteLine("");

    //Slay player who uses gaygun
    file.WriteLine("// 处死使用连狙玩家(默认1,1为启用)");
    file.WriteLine("// Slay player who uses gaygun");
    file.WriteLine("mg_slaygaygun \"1\"");
    file.WriteLine("");

    //VAC timer
    file.WriteLine("// 开局多久后透视全体玩家(秒,默认120[范围60~180])");
    file.WriteLine("// VAC WALLHACK timer (Seconds)");
    file.WriteLine("mg_wallhack_delay \"120\"");

    file.Close();
}

static Action Command_SetBhopAllow(int args)
{
    if (args != 1)
    {
        LogError("Error trigger command mg_setbhop_allow!");
        return Plugin_Handled;
    }

    char buffer[16];
    GetCmdArg(1, buffer, 16);
    if (StringToInt(buffer) == 0 || 
       strcmp(buffer, "false", false) == 0 || 
       strcmp(buffer, "no", false) == 0 ||
       strcmp(buffer, "off", false) == 0)
    {
       t_LastEBhop = true;
       sv_enablebunnyhopping.SetInt(0, true, true);
       ChatAll("%t", "map config toggle", "bunnyhopping", "color disabled");
    }
    else if (StringToInt(buffer) == 1 || 
            strcmp(buffer, "true", false) == 0 || 
            strcmp(buffer, "yes", false) == 0 ||
            strcmp(buffer, "on", false) == 0)
    {
        t_LastEBhop = true;
        sv_enablebunnyhopping.SetInt(1, true, true);
        ChatAll("%t", "map config toggle", "bunnyhopping", "color enabled");
    }
    else
    {
        LogError("Error trigger command mg_setbhop_allow! arg[1]: %s", buffer);
    }

    if (g_extMovementManager)
    {
        ConVar_Easy_SetInt("sm_movement_unlocker_ct", sv_enablebunnyhopping.BoolValue ? 2 : 0, true, false);
        ConVar_Easy_SetInt("sm_movement_unlocker_te", sv_enablebunnyhopping.BoolValue ? 2 : 0, true, false);
    }

    return Plugin_Handled;
}

static Action Command_SetBhopAuto(int args)
{
    if (args != 1)
    {
        LogError("Error trigger command mg_setbhop_auto!");
        return Plugin_Handled;
    }

    char buffer[16];
    GetCmdArg(1, buffer, 16);
    if (StringToInt(buffer) == 0 || 
       strcmp(buffer, "false", false) == 0 || 
       strcmp(buffer, "no", false) == 0 ||
       strcmp(buffer, "off", false) == 0)
    {
       t_LastABhop = true;
       sv_autobunnyhopping.SetInt(0, true, true);
       ChatAll("%t", "map config toggle", "autobhop", "color disabled");
    }
    else if (StringToInt(buffer) == 1 || 
            strcmp(buffer, "true", false) == 0 || 
            strcmp(buffer, "yes", false) == 0 ||
            strcmp(buffer, "on", false) == 0)
    {
        t_LastABhop = true;
        sv_autobunnyhopping.SetInt(1, true, true);
        ChatAll("%t", "map config toggle", "autobhop", "color enabled");
    }
    else
    {
        LogError("Error trigger command mg_setbhop_auto! arg[1]: %s", buffer);
    }

    return Plugin_Handled;
}

static Action Command_SetBhopSpeed(int args)
{
    if (args != 1)
    {
        LogError("Error trigger command mg_setbhop_speed!");
        return Plugin_Handled;
    }

    char buffer[16];
    GetCmdArg(1, buffer, 16);

    float speed = StringToFloat(buffer);
    if (speed > 3500.0 || speed < 200.0)
    {
        LogError("Error trigger command mg_setbhop_speed! Wrong speed!");
        return Plugin_Handled;
    }

    t_LastSpeed = mg_bhopspeed.FloatValue;
    mg_bhopspeed.FloatValue = speed;

    ChatAll("%t", "map config changed float", "bhop speed", mg_bhopspeed.FloatValue);

    return Plugin_Handled;
}

static Action Command_VacTimer(int args)
{
    if (args != 1)
    {
        LogError("Error trigger command mg_add_vac_timer!");
        return Plugin_Handled;
    }

    char buffer[16];
    GetCmdArg(1, buffer, 16);
    Games_AddVacTimer(StringToInt(buffer));

    return Plugin_Handled;
}

void Cvars_OnRoundStart()
{
    if (t_LastABhop)
    {
        sv_autobunnyhopping.SetBool(!sv_autobunnyhopping.BoolValue, true, true);
        t_LastABhop = false;
    }

    if (t_LastEBhop)
    {
        sv_enablebunnyhopping.SetBool(!sv_enablebunnyhopping.BoolValue, true, true);
        t_LastEBhop = false;
    }

    if (t_LastSpeed > 0.0)
    {
        mg_bhopspeed.FloatValue = t_LastSpeed;
        t_LastSpeed = -1.0;
    }

    ConVar_Easy_SetInt("sv_full_alltalk",                   1, true, false);
    ConVar_Easy_SetInt("sv_talk_enemy_living",              1, true, false);
    ConVar_Easy_SetInt("sv_talk_enemy_dead",                1, true, false);

    // fixed
    // if ball game has been choosen, just insert change handled in stripper.
    phys_pushscale.IntValue = 24;
    
    // fix skate invoke
    sv_standable_normal.FloatValue = 0.7;

    // movement
    if (g_extMovementManager)
    {
        ConVar_Easy_SetInt("sm_movement_unlocker_ct", sv_enablebunnyhopping.BoolValue ? 2 : 0, true, false);
        ConVar_Easy_SetInt("sm_movement_unlocker_te", sv_enablebunnyhopping.BoolValue ? 2 : 0, true, false);
    }
}

public Action Command_SetCvar(int args)
{
    if (args != 2)
    {
        char cmd[128];
        GetCmdArgString(cmd, 128);
        LogError("Error trigger command mg_setcvar! Wrong args! -> [%s]", cmd);
        return Plugin_Handled;
    }

    char cvr[2][128];
    GetCmdArg(1, cvr[0], 128);
    GetCmdArg(2, cvr[1], 128);

    ConVar_Easy_SetStr(cvr[0], cvr[1], true, false);

    return Plugin_Handled;
}

public Action MuteConVarChanged(Event event, const char[] name, bool dontBroadcast)
{
    event.BroadcastDisabled = true;
    return Plugin_Changed;
}

bool Cvars_AllowDropTaser()
{
    return mp_taser_recharge_time.IntValue < 0;
}

static void Cvars_CheckMapRadars()
{
    char map[128];
    GetCurrentMap(map, 128);
    sv_disable_radar.BoolValue = !Cvars_FindMapRadar(map);
}

static bool Cvars_FindMapRadar(const char[] map)
{
    char txt[128];
    FormatEx(txt, 128, "resource/overviews/%s.txt", map);

    if (!FileExists(txt, true))
    {
        LogError("Failed to find [%s].", txt);
        return false;
    }
    
    KeyValues kv = new KeyValues(map);
    if (!kv.ImportFromFile(txt))
    {
        LogError("Failed to import [%s].", txt);
        delete kv;
        return false;
    }

    char material[128];
    kv.GetString("material", material, 128, map);

    char dds[128];
    FormatEx(dds, 128, "resource/%s.dds", material);

    if (FileExists(dds, true))
    {
        delete kv;
        return true;
    }

    FormatEx(dds, 128, "resource/overviews/%s_radar.dds", map);
    if (FileExists(dds, true))
    {
        delete kv;
        return true;
    }

    if (kv.JumpToKey("verticalsections", false))
    {
        if (kv.GotoFirstSubKey(true))
        {
            do
            {
                char name[32];
                kv.GetSectionName(name, 32);
                FormatEx(dds, 128, "resource/%s_%s_radar.dds", material, name);
                if (FileExists(dds, true))
                {
                    delete kv;
                    return true;
                }
            }
            while (kv.GotoNextKey(true));
        }
    }

    delete kv;
    return false;
}

void Cvars_FakeClientConVar(int client)
{
    if (!CheckCommandAccess(client, "sm_ban", ADMFLAG_BAN, false))
        return;

    // Enables Observer X-Ray...
    sv_competitive_official_5v5.ReplicateToClient(client, "1");
}