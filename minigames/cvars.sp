
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
static ConVar sv_staminamax;
static ConVar sv_staminajumpcost;
static ConVar sv_staminalandcost;
static ConVar sv_staminarecoveryrate;
static ConVar sv_autobunnyhopping;

static bool  t_LastEBhop;
static bool  t_LastABhop;
static float t_LastSpeed;

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
    mg_wallhack_delay   = CreateConVar("mg_wallhack_delay", "150.0", "how many seconds wallhack all after round start", _, true, 60.0, true, 150.0);

    mp_ct_default_melee     = FindConVar("mp_ct_default_melee");
    mp_ct_default_primary   = FindConVar("mp_ct_default_primary");
    mp_ct_default_secondary = FindConVar("mp_ct_default_secondary");
    mp_t_default_melee      = FindConVar("mp_t_default_melee");
    mp_t_default_primary    = FindConVar("mp_t_default_primary");
    mp_t_default_secondary  = FindConVar("mp_t_default_secondary");
    mp_warmuptime           = FindConVar("mp_warmuptime");

    sv_tags                = FindConVar("sv_tags");
    sv_enablebunnyhopping  = FindConVar("sv_enablebunnyhopping");
    sv_autobunnyhopping    = FindConVar("sv_autobunnyhopping");
    sv_staminamax          = FindConVar("sv_staminamax");
    sv_staminajumpcost     = FindConVar("sv_staminajumpcost");
    sv_staminalandcost     = FindConVar("sv_staminalandcost");
    sv_staminarecoveryrate = FindConVar("sv_staminarecoveryrate");

    mp_ct_default_melee.AddChangeHook(Cvars_OnSettingChanged);
    mp_ct_default_primary.AddChangeHook(Cvars_OnSettingChanged);
    mp_ct_default_secondary.AddChangeHook(Cvars_OnSettingChanged);
    mp_t_default_melee.AddChangeHook(Cvars_OnSettingChanged);
    mp_t_default_primary.AddChangeHook(Cvars_OnSettingChanged);
    mp_t_default_secondary.AddChangeHook(Cvars_OnSettingChanged);
    
    sv_autobunnyhopping.AddChangeHook(Cvars_OnSettingChanged);

    AutoExecConfig(true, "minigames");
    
    if(!DirExists("cfg/sourcemod/map-configs"))
    {
        LogMessage("Create cfg/sourcemod/map-configs");
        CreateDirectory("cfg/sourcemod/map-configs", 511);
    }
    
    // you need add these to bspcvar_whitelist.cfg
    
    // Bhop
    RegServerCmd("mg_setbhop_allow", Command_SetBhopAllow);
    RegServerCmd("mg_setbhop_auto",  Command_SetBhopAuto);
    RegServerCmd("mg_setbhop_speed", Command_SetBhopSpeed);
    
    // Cvar
    RegServerCmd("mg_setcvar", Command_SetCvar);
    
    HookEvent("server_cvar", MuteConVarChanged, EventHookMode_Pre);
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

    if(sv_autobunnyhopping.IntValue == 1)
    {
        sv_staminamax.SetInt(0, true, false);
        sv_staminajumpcost.SetInt(0, true, false);
        sv_staminalandcost.SetInt(0, true, false);
        sv_staminarecoveryrate.SetInt(0, true, false);
    }
    else
    {
        sv_staminamax.SetFloat(100.0, true, false);
        sv_staminajumpcost.SetFloat(0.10, true, false);
        sv_staminalandcost.SetFloat(0.05, true, false);
        sv_staminarecoveryrate.SetFloat(100.0, true, false);
    }
}

static void Cvars_SetCvarDefault()
{
    FindConVar("phys_pushscale").SetInt(3, true, false);
    FindConVar("phys_timescale").SetInt(1, true, false);
    FindConVar("sv_damage_print_enable").SetInt(1, true, false);
    FindConVar("sv_airaccelerate").SetInt(9999, true, false);
    FindConVar("sv_accelerate_use_weapon_speed").SetInt(0, true, false);
    FindConVar("sv_maxvelocity").SetInt(3500, true, false);
    FindConVar("sv_full_alltalk").SetInt(1, true, false);
    FindConVar("mp_limitteams").SetInt(0, true, false);
    FindConVar("mp_autoteambalance").SetInt(0, true, false);

    sv_staminamax.SetFloat(100.0, true, false);
    sv_staminajumpcost.SetFloat(0.16, true, false);
    sv_staminalandcost.SetFloat(0.10, true, false);
    sv_staminarecoveryrate.SetFloat(50.0, true, false);

    sv_autobunnyhopping.SetInt(0, true, false);
}

void Cvars_OnAutoConfigsBuffered()
{
    // set default convars
    Cvars_SetCvarDefault();
    Cvars_EnforceOptions();
    
    // load map config
    char mapconfig[256];
    GetCurrentMap(mapconfig, 256);
    LogMessage("Searching %s.cfg", mapconfig);
    Format(mapconfig, 256, "sourcemod/map-configs/%s.cfg", mapconfig);

    char path[256];
    Format(path, 256, "cfg/%s", mapconfig);

    if(!FileExists(path))
    {
        GenerateMapConfigs(path);
        LogMessage("[%s] does not exists, Auto-generated.", mapconfig);
        return;
    }

    ServerCommand("exec %s", mapconfig);
    LogMessage("Executed %s", mapconfig);
}

void Cvars_EnforceOptions()
{
    //if(FileExists("cfg/options.cfg"))
    //{
    //    ServerCommand("exec options.cfg");
    //    LogMessage("Executed options.cfg");
    //    return;
    //}
    
    LogMessage("Executed advanced convar options");

    // network
    FindConVar("sv_maxrate").SetInt(128000, true, false); 
    FindConVar("sv_minrate").SetInt(128000, true, false); 
    FindConVar("sv_minupdaterate").SetInt(128, true, false);
    FindConVar("sv_mincmdrate").SetInt(128, true, false);
    
    // optimized
    FindConVar("net_splitrate").SetInt(2, true, false); 
    FindConVar("sv_parallel_sendsnapshot").SetInt(1, true, false); 
    FindConVar("sv_enable_delta_packing").SetInt(1, true, false); 
    FindConVar("sv_maxunlag").SetFloat(0.1, true, false);

    // phys
    FindConVar("phys_enable_experimental_optimizations").SetInt(1, true, false);
    
    // sv var
    FindConVar("sv_alternateticks").SetInt(1, true, false);
    FindConVar("sv_forcepreload").SetInt(1, true, false);
    FindConVar("sv_force_transmit_players").SetInt(0, true, false);
    FindConVar("sv_force_transmit_ents").SetInt(0, true, false);
    FindConVar("sv_occlude_players").SetInt(0, true, false);
}

void GenerateMapConfigs(const char[] path)
{
    File file = OpenFile(path, "w+");

    if(file == null)
    {
        LogError("Failed to create [%s]", path);
        return;
    }
    
    file.WriteLine("// This file was auto-generated by %s (v%s)", PI_NAME, PI_VERSION);
    
    char map[128];
    GetCurrentMap(map, 128);
    file.WriteLine("// ConVars for map \"%s\"", map);

    file.WriteLine("");
    file.WriteLine("");

    //Round Time
    file.WriteLine("//设置回合时间(分钟)");
    file.WriteLine("mp_roundtime \"5.0\"");
    file.WriteLine("");
    
    //Time limit
    file.WriteLine("//地图时间(分钟)");
    file.WriteLine("mp_timelimit \"40\"");
    file.WriteLine("");
    
    //Auto bunnyhopping
    file.WriteLine("//自动连跳开关(默认1,1为启用)");
    file.WriteLine("sv_autobunnyhopping \"1\"");
    file.WriteLine("");
    
    //Allow bunnyhopping
    file.WriteLine("//BHOP限制类型(设置为1则允许超过250低速)");
    file.WriteLine("sv_enablebunnyhopping \"0\"");
    file.WriteLine("");
    
    //Bhop max speed
    file.WriteLine("//BHOP地速上限(单位, 需要sv_enablebunnyhopping设置为1)");
    file.WriteLine("mg_bhopspeed \"300.0\"");
    file.WriteLine("");
    
    //Max flashbang
    file.WriteLine("//最大携带闪光(个)");
    file.WriteLine("ammo_grenade_limit_flashbang \"1\"");
    file.WriteLine("");
    
    //Man grenade
    file.WriteLine("//最大携带手雷(个)");
    file.WriteLine("ammo_grenade_limit_total \"1\"");
    file.WriteLine("");
    
    //Gravity
    file.WriteLine("//重力(单位)");
    file.WriteLine("sv_gravity \"790\"");
    file.WriteLine("");
    
    //Random switch team
    file.WriteLine("//随机组队(1为启用)");
    file.WriteLine("mg_randomteam \"1\"");
    file.WriteLine("");
    
    //Give pistol on spawn
    file.WriteLine("//出生发手枪(默认0,1为启用)");
    file.WriteLine("mg_spawn_pistol \"0\"");
    file.WriteLine("");
    
    //Give knife on spawn
    file.WriteLine("//出生发刀(默认0,1为启用)");
    file.WriteLine("mg_spawn_knife \"0\"");
    file.WriteLine("");
    
    //Give kevlar on spawn
    file.WriteLine("//出生护甲(具体数值0~100)");
    file.WriteLine("mg_spawn_kevlar \"0\"");
    file.WriteLine("");
    
    //Give helmet on spawn
    file.WriteLine("//出生头盔(0或1)");
    file.WriteLine("mg_spawn_helmet \"0\"");
    file.WriteLine("");
    
    //Taser recharge time
    file.WriteLine("//电击枪充电时间(秒)");
    file.WriteLine("mp_taser_recharge_time \"15\"");
    file.WriteLine("");
    
    //Restrict AWP
    file.WriteLine("//禁止使用AWP(1为启用)");
    file.WriteLine("mg_restrictawp \"0\"");
    file.WriteLine("");
    
    //Slay player who uses gaygun
    file.WriteLine("//处死使用连狙玩家(默认1,1为启用)");
    file.WriteLine("mg_slaygaygun \"1\"");
    file.WriteLine("");
    
    //VAC timer
    file.WriteLine("//开局多久后透视全体玩家(秒,默认120[范围60~180])");
    file.WriteLine("mg_wallhack_delay \"120\"");

    delete file;
}

public Action Command_SetBhopAllow(int args)
{
    if(args != 1)
    {
        LogError("Error trigger command mg_setbhop_allow!");
        return Plugin_Handled;
    }

    char buffer[16];
    GetCmdArg(1, buffer, 16);
    if(StringToInt(buffer) == 0 || 
       strcmp(buffer, "false", false) == 0 || 
       strcmp(buffer, "no", false) == 0 ||
       strcmp(buffer, "off", false) == 0)
    {
       t_LastEBhop = true;
       sv_enablebunnyhopping.SetInt(0, true, true);
       ChatAll("\x0A地图已临时 \x07关闭\x0A \x0E连跳加速");
    }
    else if(StringToInt(buffer) == 1 || 
            strcmp(buffer, "true", false) == 0 || 
            strcmp(buffer, "yes", false) == 0 ||
            strcmp(buffer, "on", false) == 0)
    {
        t_LastEBhop = true;
        sv_enablebunnyhopping.SetInt(1, true, true);
        ChatAll("\x0A地图已临时 \x04开启\x0A \x0E连跳加速");
    }
    else
    {
        LogError("Error trigger command mg_setbhop_allow! arg[1]: %s", buffer);
    }
    
    return Plugin_Handled;
}

public Action Command_SetBhopAuto(int args)
{
    if(args != 1)
    {
        LogError("Error trigger command mg_setbhop_auto!");
        return Plugin_Handled;
    }

    char buffer[16];
    GetCmdArg(1, buffer, 16);
    if(StringToInt(buffer) == 0 || 
       strcmp(buffer, "false", false) == 0 || 
       strcmp(buffer, "no", false) == 0 ||
       strcmp(buffer, "off", false) == 0)
    {
       t_LastABhop = true;
       sv_autobunnyhopping.SetInt(0, true, true);
       ChatAll("\x0A地图已临时 \x07关闭\x0A \x0E自动连跳");
    }
    else if(StringToInt(buffer) == 1 || 
            strcmp(buffer, "true", false) == 0 || 
            strcmp(buffer, "yes", false) == 0 ||
            strcmp(buffer, "on", false) == 0)
    {
        t_LastABhop = true;
        sv_autobunnyhopping.SetInt(1, true, true);
        ChatAll("\x0A地图已临时 \x04开启\x0A \x0E自动连跳");
    }
    else
    {
        LogError("Error trigger command mg_setbhop_auto! arg[1]: %s", buffer);
    }
    
    return Plugin_Handled;
}

public Action Command_SetBhopSpeed(int args)
{
    if(args != 1)
    {
        LogError("Error trigger command mg_setbhop_speed!");
        return Plugin_Handled;
    }
    
    char buffer[16];
    GetCmdArg(1, buffer, 16);
    
    float speed = StringToFloat(buffer);
    if(speed > 3500.0 || speed < 200.0)
    {
        LogError("Error trigger command mg_setbhop_speed! Wrong speed!");
        return Plugin_Handled;
    }
    
    t_LastSpeed = mg_bhopspeed.FloatValue;
    mg_bhopspeed.FloatValue = speed;
    
    ChatAll("\x0A地图已临时 \x07更改\x0A \x0E地速上限 \x0A为 \x04%.1f", mg_bhopspeed.FloatValue);

    return Plugin_Handled;
}

void Cvars_OnRoundStart()
{
    if(t_LastABhop)
    {
        sv_autobunnyhopping.SetBool(!sv_autobunnyhopping.BoolValue, true, true);
        t_LastABhop = false;
    }
    
    if(t_LastEBhop)
    {
        sv_enablebunnyhopping.SetBool(!sv_enablebunnyhopping.BoolValue, true, true);
        t_LastEBhop = false;
    }
    
    if(t_LastSpeed > 0.0)
    {
        mg_bhopspeed.FloatValue = t_LastSpeed;
        t_LastSpeed = -1.0;
    }
}

public Action Command_SetCvar(int args)
{
    if(args != 2)
    {
        LogError("Error trigger command mg_setcvar! Wrong args!");
        return Plugin_Handled;
    }

    char cvr[128];
    GetCmdArg(1, cvr, 128);
    
    ConVar cvar = FindConVar(cvr);
    if(cvar == null)
    {
        LogError("Error trigger command mg_setcvar! Wrong convar name!");
        return Plugin_Handled;
    }

    char val[128];
    GetCmdArg(2, val, 128);
    
    cvar.SetString(val, true, false);

    //ChatAll("\x0A地图修改 \x04%s\x0A 为 \x10%s", cvr, val);
    LogMessage("Changed ConVar \"%s\" to \"%s\". ", cvr, val);

    return Plugin_Handled;
}

public Action MuteConVarChanged(Event event, const char[] name, bool dontBroadcast)
{
    event.BroadcastDisabled = true;
    return Plugin_Changed;
}