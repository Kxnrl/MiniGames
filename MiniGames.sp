/******************************************************************/
/*                                                                */
/*                         MiniGames Core                         */
/*                                                                */
/*                                                                */
/*  File:          MiniGames.sp                                   */
/*  Description:   MiniGames Game Mod.                            */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2018  Kyle                                      */
/*  2018/03/02 04:19:06                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/


#pragma semicolon 1
#pragma newdecls required

// requires
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <clientprefs>
#include <autoexecconfig>

// myself
#include <minigames>

// plugin
#undef REQUIRE_PLUGIN
#include <store>
#include <mapmusic>
#include <updater>
#define REQUIRE_PLUGIN

// extensions
#undef REQUIRE_EXTENSIONS
#include <geoip2>  //https://github.com/Kxnrl/GeoIP2
#define REQUIRE_EXTENSIONS

// header
#include "minigames/global.h"

// module
#include "minigames/teams.sp"
#include "minigames/stats.sp"
#include "minigames/ranks.sp"
#include "minigames/cvars.sp"
#include "minigames/games.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("MiniGames");

    // Natives
    CreateNative("MG_SetSpecHudContent",    NativeCall_SetSpecHudContent);
    CreateNative("MG_GetTotalScores",       NativeCall_GetTotalScores);
    CreateNative("MG_GetTotalKills",        NativeCall_GetTotalKills);
    CreateNative("MG_GetTotalAssists",      NativeCall_GetTotalAssists);
    CreateNative("MG_GetTotalDeaths",       NativeCall_GetTotalDeaths);
    CreateNative("MG_GetTotalHeadshots",    NativeCall_GetTotalHeadshots);
    CreateNative("MG_GetTotalKnifeKills",   NativeCall_GetTotalKnifeKills);
    CreateNative("MG_GetTotalTaserKills",   NativeCall_GetTotalTaserKills);
    CreateNative("MG_GetRanks",             NativeCall_GetRanks);
    CreateNative("MG_GetLevel",             NativeCall_GetLevel);

    // Store
    MarkNativeAsOptional("Store_GetClientCredits");
    MarkNativeAsOptional("Store_SetClientCredits");

    // A2SFirewall
    MarkNativeAsOptional("A2SFirewall_GetClientTicket");
    MarkNativeAsOptional("A2SFirewall_IsClientChecked");

    // GeoIP2
    MarkNativeAsOptional("GeoIP2_Country");
    MarkNativeAsOptional("GeoIP2_City");

    // MapMusic-API
    MarkNativeAsOptional("MapMusic_GetStatus");
    MarkNativeAsOptional("MapMusic_SetStatus");
    MarkNativeAsOptional("MapMusic_GetVolume");
    MarkNativeAsOptional("MapMusic_SetVolume");

    // Updater
    MarkNativeAsOptional("Updater_AddPlugin");

    return APLRes_Success;
}

public int NativeCall_SetSpecHudContent(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    char buffer[256], vformat[256];
    GetNativeString(2, buffer, 256);
    FormatNativeString(0, 0, 3, 256, _, vformat, buffer);

    return Games_SetSpecHudContent(client, vformat);
}

public int NativeCall_GetTotalScores(Handle plugin, int numParams)
{
    return Stats_GetTotalScore(GetNativeCell(1));
}

public int NativeCall_GetTotalKills(Handle plugin, int numParams)
{
    return Stats_GetKills(GetNativeCell(1));
}

public int NativeCall_GetTotalAssists(Handle plugin, int numParams)
{
    return Stats_GetAssists(GetNativeCell(1));
}

public int NativeCall_GetTotalDeaths(Handle plugin, int numParams)
{
    return Stats_GetDeaths(GetNativeCell(1));
}

public int NativeCall_GetTotalHeadshots(Handle plugin, int numParams)
{
    return Stats_GetHeadShots(GetNativeCell(1));
}

public int NativeCall_GetTotalKnifeKills(Handle plugin, int numParams)
{
    return Stats_GetKnifeKills(GetNativeCell(1));
}

public int NativeCall_GetTotalTaserKills(Handle plugin, int numParams)
{
    return Stats_GetTaserKills(GetNativeCell(1));
}

public int NativeCall_GetRanks(Handle plugin, int numParams)
{
    return Ranks_GetLevel(GetNativeCell(1));
}

public int NativeCall_GetLevel(Handle plugin, int numParams)
{
    return Ranks_GetLevel(GetNativeCell(1));
}

public void OnPluginStart()
{
    if (GetEngineVersion() != Engine_CSGO)
        SetFailState("This plugin only for CSGO!");

    // Forwards
    g_fwdOnRandomTeam = CreateGlobalForward("MG_OnRandomTeam", ET_Event, Param_Cell, Param_Cell);
    g_fwdOnVacEnabled = CreateGlobalForward("MG_OnVacEnabled", ET_Event, Param_Cell, Param_Cell);

    // Database
    ConnectToDatabase(0);

    // fire to module
    Games_OnPluginStart();
    Cvars_OnPluginStart();
    Ranks_OnPluginStart();
    Stats_OnPluginStart();

    // block radio
    for(int x; x < 27; ++x)
    AddCommandListener(Command_BlockRadio, g_szBlockRadio[x]);

    // team controller
    AddCommandListener(Command_Jointeam, "jointeam");

    // game events
    HookEventEx("round_prestart",       Event_RoundStart,       EventHookMode_Post);
    HookEventEx("round_freeze_end",     Event_RoundStarted,     EventHookMode_Post);
    HookEventEx("round_end",            Event_RoundEnd,         EventHookMode_Post);
    HookEventEx("player_spawn",         Event_PlayerSpawn,      EventHookMode_Post);
    HookEventEx("player_death",         Event_PlayerDeath,      EventHookMode_Post);
    HookEventEx("player_hurt",          Event_PlayerHurts,      EventHookMode_Post);
    HookEventEx("player_team",          Event_PlayerTeams,      EventHookMode_Pre);
    HookEventEx("player_blind",         Event_PlayerBlind,      EventHookMode_Post);
    HookEventEx("player_disconnect",    Event_PlayerDisconnect, EventHookMode_Pre);
    HookEventEx("player_connect_full",  Event_PlayerConnected,  EventHookMode_Post);
    HookEventEx("weapon_fire",          Event_WeaponFire,       EventHookMode_Post);
    HookEventEx("cs_win_panel_match",   Event_WinPanel,         EventHookMode_Post);
    HookEventEx("announce_phase_end",   Event_AnnouncePhaseEnd, EventHookMode_Post);

    // for noblock
    g_offsetNoBlock = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
    if (g_offsetNoBlock == -1)
        SetFailState("NoBlock offset -> not found.");

    LoadTranslations("com.kxnrl.minigames.translations");
}

public void OnAllPluginsLoaded()
{
    // check library
    g_extGeoIP2 = LibraryExists("GeoIP2");
    g_extA2SFirewall = LibraryExists("A2SFirewall");
    g_smxStore = LibraryExists("store");
    g_smxMapMuisc = LibraryExists("MapMusic");

    if (LibraryExists("updater"))
    {
        ConVar_Easy_SetInt("sm_updater", 2);
        Updater_AddPlugin("https://build.kxnrl.com/MiniGames/updater/release.txt");
    }
}

public void OnPluginEnd()
{
    // save all when unload plugin
    Stats_OnPluginEnd();
}

public void Updater_OnPluginUpdated()
{
    ReloadPlugin();
}

public void OnLibraryAdded(const char[] name)
{
    if (strcmp(name, "A2SFirewall") == 0)
        g_extA2SFirewall = true;
    else if (strcmp(name, "GeoIP2") == 0)
        g_extGeoIP2 = true;
    else if (strcmp(name, "store") == 0)
        g_smxStore = true;
    else if (strcmp(name, "MapMusic") == 0)
        g_smxMapMuisc = true;
    else if (strcmp(name, "updater") == 0)
    {
        ConVar_Easy_SetInt("sm_updater", 2);
        Updater_AddPlugin("https://build.kxnrl.com/MiniGames/updater/release.txt");
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (strcmp(name, "A2SFirewall") == 0)
        g_extA2SFirewall = false;
    else if (strcmp(name, "GeoIP2") == 0)
    {
        g_extGeoIP2 = false;
        LogError("GeoIP2 removed");
    }
    else if (strcmp(name, "store") == 0)
        g_smxStore = false;
    else if (strcmp(name, "MapMusic") == 0)
        g_smxMapMuisc = false;
}

static void ConnectToDatabase(int retry)
{
    if (g_hMySQL != null)
        return;

    char config[16];
    if (SQL_CheckConfig("minigames")) strcopy(config, 16, "minigames");
    if (SQL_CheckConfig("kxnrl")) strcopy(config, 16, "kxnrl");
    if (SQL_CheckConfig("csgo")) strcopy(config, 16, "csgo");
    if (!config[0]) strcopy(config, 16, "default");

    // connect to database
    Database.Connect(Database_OnConnected, config, retry);
}

public void Database_OnConnected(Database db, const char[] error, int retry)
{
    // Exception
    if (db == null)
    {
        LogError("Database_OnConnected -> Connect failed -> %s", error);
        if (++retry <= 10)
            CreateTimer(3.0, Timer_ReconnectDB, retry);
        else
            SetFailState("connect to database failed! -> %s", error);
        return;
    }

    g_hMySQL = db;
    g_hMySQL.SetCharset("utf8");

    char m_szQuery[2048];
    FormatEx(m_szQuery, 2048, "CREATE TABLE IF NOT EXISTS `k_minigames` (               \
                              `uid` int(11) unsigned NOT NULL AUTO_INCREMENT,           \
                              `steamid` varchar(32) NOT NULL DEFAULT 'INVALID_STEAMID', \
                              `username` varchar(32) DEFAULT NULL,                      \
                              `kills` int(11) unsigned NOT NULL DEFAULT '0',            \
                              `deaths` int(11) unsigned NOT NULL DEFAULT '0',           \
                              `assists` int(11) unsigned NOT NULL DEFAULT '0',          \
                              `hits` int(11) unsigned NOT NULL DEFAULT '0',             \
                              `shots` int(11) unsigned NOT NULL DEFAULT '0',            \
                              `headshots` int(11) unsigned NOT NULL DEFAULT '0',        \
                              `knife` int(11) unsigned NOT NULL DEFAULT '0',            \
                              `taser` int(11) unsigned NOT NULL DEFAULT '0',            \
                              `grenade` int(11) unsigned NOT NULL DEFAULT '0',          \
                              `molotov` int(11) unsigned NOT NULL DEFAULT '0',          \
                              `damage` int(11) unsigned NOT NULL DEFAULT '0',           \
                              `survivals` int(11) unsigned NOT NULL DEFAULT '0',        \
                              `rounds` int(11) unsigned NOT NULL DEFAULT '0',           \
                              `score` int(11) unsigned NOT NULL DEFAULT '0',            \
                              `online` int(11) unsigned NOT NULL DEFAULT '0',           \
                              PRIMARY KEY (`uid`),                                      \
                              UNIQUE KEY `uk_steamid` (`steamid`)                       \
                            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;                    \
                            ");
    g_hMySQL.Query(Database_CreateTable, m_szQuery, 0, DBPrio_High);
}

public void Database_CreateTable(Database db, DBResultSet results, const char[] error, int step)
{
    if (results == null || error[0])
        SetFailState("Database_CreateTable -> %s -> %d", error, step);

    step++;

    switch(step)
    {
        case 1:
        {
            char m_szQuery[2048];
            FormatEx(m_szQuery, 2048, "CREATE TABLE IF NOT EXISTS `k_minigames_s` (             \
                                      `id` int(11) unsigned NOT NULL AUTO_INCREMENT,            \
                                      `uid` int(11) unsigned NOT NULL,                          \
                                      `ticket` varchar(32) DEFAULT NULL,                        \
                                      `map` varchar(32) DEFAULT NULL,                           \
                                      `kills` int(11) unsigned NOT NULL DEFAULT '0',            \
                                      `deaths` int(11) unsigned NOT NULL DEFAULT '0',           \
                                      `assists` int(11) unsigned NOT NULL DEFAULT '0',          \
                                      `hits` int(11) unsigned NOT NULL DEFAULT '0',             \
                                      `shots` int(11) unsigned NOT NULL DEFAULT '0',            \
                                      `headshots` int(11) unsigned NOT NULL DEFAULT '0',        \
                                      `knife` int(11) unsigned NOT NULL DEFAULT '0',            \
                                      `taser` int(11) unsigned NOT NULL DEFAULT '0',            \
                                      `grenade` int(11) unsigned NOT NULL DEFAULT '0',          \
                                      `molotov` int(11) unsigned NOT NULL DEFAULT '0',          \
                                      `damage` int(11) unsigned NOT NULL DEFAULT '0',           \
                                      `survivals` int(11) unsigned NOT NULL DEFAULT '0',        \
                                      `rounds` int(11) unsigned NOT NULL DEFAULT '0',           \
                                      `score` int(11) unsigned NOT NULL DEFAULT '0',            \
                                      `online` int(11) unsigned NOT NULL DEFAULT '0',           \
                                      `date` int(11) unsigned NOT NULL DEFAULT '0',             \
                                      PRIMARY KEY (`id`),                                       \
                                      UNIQUE KEY `uk_ticket` (`ticket`)                         \
                                    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;                    \
                                    ");
            g_hMySQL.Query(Database_CreateTable, m_szQuery, step, DBPrio_High);
        }
        case 2:
        {
            char m_szQuery[2048];
            FormatEx(m_szQuery, 2048, "CREATE TABLE IF NOT EXISTS `k_minigames_k` (             \
                                      `id` int(11) unsigned NOT NULL AUTO_INCREMENT,            \
                                      `killer` int(11) unsigned NOT NULL DEFAULT '0',           \
                                      `assister` int(11) unsigned NOT NULL DEFAULT '0',         \
                                      `victim` int(11) unsigned NOT NULL DEFAULT '0',           \
                                      `map` varchar(128) DEFAULT '0',                           \
                                      `round` tinyint(3) unsigned NOT NULL DEFAULT '0',         \
                                      `time` float(6,3) unsigned NOT NULL DEFAULT '0.000',      \
                                      `weapon` varchar(32) DEFAULT NULL,                        \
                                      `headshot` tinyint(2) unsigned NOT NULL DEFAULT '0',      \
                                      `victim_model` varchar(192) DEFAULT NULL,                 \
                                      `timestamp` int(11) unsigned NOT NULL DEFAULT '0',        \
                                      PRIMARY KEY (`id`)                                        \
                                    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;                    \
                                    ");
            g_hMySQL.Query(Database_CreateTable, m_szQuery, step, DBPrio_High);
        }
        default: Ranks_OnDBConnected();
    }
}

public Action Timer_ReconnectDB(Handle timer, int retry)
{
    // retry
    LogError("Timer_ReconnectDB -> Reconnect -> %d", retry);
    ConnectToDatabase(retry);
    return Plugin_Stop;
}

public void OnMapStart()
{
    // we only work on mg_ maps
    GetCurrentMap(g_szMap, 128);
    if (StrContains(g_szMap, "mg_", false) != 0)
        SetFailState("This plugin only for mg_ (MiniGames/MultiGames) map! -> %s", g_szMap);

    // fire to module
    Stats_OnMapStart();
    Games_OnMapStart();
    Ranks_OnMapStart();
    Teams_OnMapStart();
}

public void OnConfigsExecuted()
{
    // fire to module
    Cvars_OnConfigsExecuted();

    // set up warmup timer
    if (g_tWarmup != null)
        KillTimer(g_tWarmup);
    g_tWarmup = CreateTimer(mp_warmuptime.FloatValue + 0.5, Timer_WarmupEnd);
    
    // check message for A2SFirewall
    if (!g_extA2SFirewall)
    {
        static bool print_a2s = false;
        if (!print_a2s)
        {
            print_a2s = true;
            LogMessage("A2SFirewall not install! -> For A2S attack protection, please install A2SFirewall.ext! please contact 'https://steamcommunity.com/profiles/76561198048432253' or Download from 'https://build.kxnrl.com/_Raw/A2SFirewall'.");
        }
    }

    // check message for MapMusic
    if (!g_smxMapMuisc)
    {
        static bool print_mma = false;
        if (!print_mma)
        {
            print_mma = true;
            LogMessage("MapMusic-API not install -> For map music controller, we recommend that you install this plugin. -> 'https://github.com/Kxnrl/MapMusic-API'");
        }
    }

    // check message for GeoIP2
    if (!g_extGeoIP2)
    {
        static bool print_geo = false;
        if (!print_geo)
        {
            print_geo = true;
            LogMessage("GeoIP2 not install -> For GeoIP connection message, we recommend that you install this extension. -> 'https://github.com/Kxnrl/GeoIP2'");
        }
    }
}

public void OnMapEnd()
{
    // fire to module
    Games_OnMapEnd();
    Ranks_OnMapEnd();

    // clear timer
    if (g_tWarmup != null)
        KillTimer(g_tWarmup);
    g_tWarmup = null;
}

public void OnClientConnected(int client)
{
    // refresh players
    g_GamePlayers = GetClientCount(true);

    // reset client vars
    g_iUId [client] = 0;
    g_iTeam[client] = 0;

    // fire to module
    Games_OnClientConnected(client);
    Stats_OnClientConnected(client);
    Teams_OnClientConnected(client);
}

public void OnClientPutInServer(int client)
{
    // refresh players
    g_GamePlayers = GetClientCount(true);

    // Block Bot/GOTV
    if (!ClientValid(client))
        return;

    // checking cluent
    if (g_extA2SFirewall)
    {
        if (!A2SFirewall_IsClientChecked(client))
        {
            LogError("A2SFirewall -> \"%L\" -> failed to check ticket.");
            KickClient(client, "Something went wrong!\n Please reconnect to server!");
            return;
        }
        else
        {
            char ticket[32];
            A2SFirewall_GetClientTicket(client, ticket, 32);
            strcopy(g_szTicket[client], 32, ticket);
            Chat(client, "Your connection ticket is \x04 %s", ticket);
        }
    }

    // fire to module
    Ranks_OnClientPutInServer(client);
    Stats_OnClientPutInServer(client);

    // hook this to check weapon
    SDKHookEx(client, SDKHook_WeaponEquipPost, Hook_OnPostWeaponEquip);

    // hook this to set transmit
    SDKHookEx(client, SDKHook_SetTransmit, Hook_OnSetTransmit);
}

public void OnClientCookiesCached(int client)
{
    Games_OnClientCookiesCached(client);
}

public void OnClientDisconnect(int client)
{
    // refresh players
    g_GamePlayers = GetClientCount(true);

    // if client is not fully in-game
    if (!ClientValid(client))
        return;

    // if client is not passed.
    if (g_extA2SFirewall && !A2SFirewall_IsClientChecked(client))
        return;

    // fire to module
    Ranks_OnClientDisconnect(client);
    Stats_OnClientDisconnect(client);

    // unhook
    SDKUnhook(client, SDKHook_WeaponEquipPost, Hook_OnPostWeaponEquip);
    SDKUnhook(client, SDKHook_SetTransmit, Hook_OnSetTransmit);
}

public void Hook_OnPostWeaponEquip(int client, int weapon)
{
    if (!IsValidEdict(weapon))
        return;

    // we need check weapon when client fully equipped. 1 frame delay.
    DataPack pack = new DataPack();
    pack.WriteCell(client);
    pack.WriteCell(EntIndexToEntRef(weapon));
    RequestFrame(Games_OnEquipPost, pack);
}

public Action Hook_OnSetTransmit(int entity, int client)
{
    // Function not enabled.
    if (!mg_transmitblock.BoolValue)
        return Plugin_Continue;

    // Follo client's option
    if (!g_kOptions[client][kO_Transmit])
        return Plugin_Continue;

    // Set Transmit
    return (g_iTeam[client] == g_iTeam[entity]) ? Plugin_Handled : Plugin_Continue;
}

public Action Timer_WarmupEnd(Handle timer)
{
    g_tWarmup = null;
    Stats_OnWarmupEnd();

    // custom gamemode maybe cause WARMUPTIME 0:01
    CreateTimer(5.0, Timer_CheckWarmupEnd, _, TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Stop;
}

public Action Timer_CheckWarmupEnd(Handle timer)
{
    if (GameRules_GetProp("m_bWarmupPeriod") != 1)
        return Plugin_Stop;

    // force end warmup
    ServerCommand("mp_warmup_end");

    return Plugin_Stop;
}

public Action Command_BlockRadio(int client, const char[] command, int args)
{
    // block radio command
    return Plugin_Handled;
}

//public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    // fire to module
    Games_OnPlayerRunCmd(client);
    Ranks_OnPlayerRunCmd(client, buttons);

    return Plugin_Continue;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int userid = event.GetInt("userid");
    int client = GetClientOfUserId(userid);

    Stats_OnClientSpawn(client);

    CreateTimer(0.1, Games_OnClientSpawn, userid);

    // for no block
    SetEntData(client, g_offsetNoBlock, 2, 4, true);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if (g_tWarmup != null)
        return;

    int client = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int assister = GetClientOfUserId(event.GetInt("assister"));
    bool headshot = event.GetBool("headshot");
    char weapon[32];
    event.GetString("weapon", weapon, 32, "");

    Stats_OnClientDeath(client, attacker, assister, headshot, weapon);
}

public void Event_PlayerHurts(Event event, const char[] name, bool dontBroadcast)
{
    if (g_tWarmup != null)
        return;

    int client = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int damage = event.GetInt("dmg_health");
    int hitgroup = event.GetInt("hitgroup");
    char weapon[32];
    event.GetString("weapon", weapon, 32, "");

    Stats_PlayerHurts(client, attacker, damage, weapon);
    Games_PlayerHurts(attacker, hitgroup);
}

public Action Event_PlayerTeams(Event event, const char[] name, bool dontBroadcast)
{
    g_iTeam[GetClientOfUserId(event.GetInt("userid"))] = event.GetInt("team");

    event.BroadcastDisabled = true;
    return Plugin_Changed;
}

public void Event_PlayerBlind(Event event, const char[] name, bool dontBroadcast)
{
    // 1 frame delay
    DataPack pack = new DataPack();
    pack.WriteCell(event.GetInt("userid"));
    pack.WriteCell(event.GetInt("attacker"));
    pack.WriteFloat(event.GetFloat("blind_duration"));
    pack.Reset();

    RequestFrame(Games_OnPlayerBlind, pack);
}

public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    event.BroadcastDisabled = true;
    return Plugin_Changed;
}

public void Event_PlayerConnected(Event event, const char[] name, bool dontBroadcast)
{
    Teams_OnPlayerConnected(event.GetInt("userid"));
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    Cvars_OnRoundStart();
    Teams_OnRoundStart();
}

public void Event_RoundStarted(Event event, const char[] name, bool dontBroadcast)
{
    Games_OnRoundStarted();
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    //int winner = event.GetInt("winner");

    Stats_OnRoundEnd();
    Games_OnRoundEnd();
    Teams_OnRoundEnd();
}

public void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    char weapon[32];
    event.GetString("weapon", weapon, 32, "");

    Stats_OnWeaponFire(client, weapon);
}

public void Event_WinPanel(Event event, const char[] name, bool dontBroadcast)
{
    // save all ...
    Stats_OnWinPanel();
}

public void Event_AnnouncePhaseEnd(Event event, const char[] name, bool dontBroadcast)
{
    // scoreboard ranking
    if (StartMessageAll("ServerRankRevealAll") != null)
        EndMessage();
}

public Action CS_OnCSWeaponDrop(int client, int weapon)
{
    char classname[32];
    GetWeaponClassname(weapon, -1, classname, 32);

    return (strcmp(classname, "weapon_taser") == 0) ? Plugin_Stop : Plugin_Continue;
}
