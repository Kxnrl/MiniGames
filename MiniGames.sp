/******************************************************************/
/*                                                                */
/*                         MiniGames Core                         */
/*                                                                */
/*                                                                */
/*  File:          MiniGames.sp                                   */
/*  Description:   MiniGames Game Mod.                            */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2020  Kyle                                      */
/*  2018/03/02 04:19:06                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/


#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

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
#include <store>             //https://github.com/Kxnrl/Store
#include <mapmusic>          //https://github.com/Kxnrl/MapMusic-API
#include <updater>           //https://forums.alliedmods.net/showthread.php?t=169095
#include <fys.pupd>          //https://git.kxnrl.com/fys-update-service
#define REQUIRE_PLUGIN

// extensions
#undef REQUIRE_EXTENSIONS
#include <geoip2>            //https://github.com/Kxnrl/GeoIP2
#include <TransmitManager>   //https://github.com/Kxnrl/sm-ext-TransmitManager
#include <MovementManager>   //https://github.com/Kxnrl/sm-ext-Movement
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

    // Transmit Manager
    MarkNativeAsOptional("TransmitManager_AddEntityHooks");
    MarkNativeAsOptional("TransmitManager_SetEntityOwner");
    MarkNativeAsOptional("TransmitManager_SetEntityState");
    
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
    g_fwdOnRandomTeam = new GlobalForward("MG_OnRandomTeam", ET_Event,  Param_Cell, Param_Cell, Param_Cell);
    g_fwdOnVacElapsed = new GlobalForward("MG_OnVacElapsed", ET_Event,  Param_Cell, Param_Cell);
    g_fwdOnVacEnabled = new GlobalForward("MG_OnVacEnabled", ET_Ignore, Param_Cell, Param_Cell);

    g_fwdOnRenderModelColor = new GlobalForward("MG_OnRenderModelColor", ET_Hook, Param_Cell);

    // Database
    ConnectToDatabase(0);

    // fire to module
    Games_OnPluginStart();
    Cvars_OnPluginStart();
    Ranks_OnPluginStart();
    Stats_OnPluginStart();

    // block radio
    for(int x; x < sizeof(g_szBlockRadio); ++x)
    AddCommandListener(Command_BlockRadio, g_szBlockRadio[x]);

    // team controller
    AddCommandListener(Command_Jointeam, "jointeam");

    // fix HDR/LDR crash.
    AddCommandListener(Command_MapChange, "changelevel");
    AddCommandListener(Command_MapChange, "map");

    // ent_fire global
    RegAdminCmd("sm_ef", Command_EntFire, ADMFLAG_CONVARS);

    // usermessage events
    HookUserMessage(GetUserMessageId("TextMsg"), Event_TextMsg, true);

    // entity output
    HookEntityOutput("func_button", "OnPressed", Event_OnPressed);

    // weapon fix
    PrepareSDKCalls();

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
    HookEventEx("grenade_thrown",       EventHook_Grenaded,     EventHookMode_Post);

    // for noblock
    g_offsetNoBlock = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
    if (g_offsetNoBlock == -1)
        SetFailState("NoBlock offset -> not found.");

    // global tick timer
    CreateTimer(0.1, Timer_Tick,     _, TIMER_REPEAT);
    CreateTimer(1.0, Timer_Interval, _, TIMER_REPEAT);

    LoadTranslations("com.kxnrl.minigames.translations");
}

public void OnAllPluginsLoaded()
{
    // check library
    g_extGeoIP2 = LibraryExists("GeoIP2");
    g_extA2SFirewall = LibraryExists("A2SFirewall");
    g_smxStore = LibraryExists("store");
    g_smxMapMuisc = LibraryExists("MapMusic");
    g_extTransmitManager = LibraryExists("TransmitManager");

    if (LibraryExists("updater"))
    {
        ConVar_Easy_SetInt("sm_updater", 2);
        Updater_AddPlugin("https://build.kxnrl.com/MiniGames/updater/release.txt");
    }
}

public void Pupd_OnCheckAllPlugins()
{
    Pupd_CheckPlugin(false, "https://build.kxnrl.com/updater/MiniGames/");
    Pupd_CheckTranslation("com.kxnrl.minigames.translations.txt", "https://build.kxnrl.com/updater/MiniGames/translation/");
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
    else if (strcmp(name, "TransmitManager") == 0)
        g_extTransmitManager = true;
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
        g_extGeoIP2 = false;
    else if (strcmp(name, "TransmitManager") == 0)
        g_extTransmitManager = false;
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
    if      (SQL_CheckConfig("minigames")) strcopy(config, 16, "minigames");
    else if (SQL_CheckConfig("kxnrl"))     strcopy(config, 16, "kxnrl");
    else if (SQL_CheckConfig("csgo"))      strcopy(config, 16, "csgo");
    else                                   strcopy(config, 16, "default");

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
    if (!g_hMySQL.SetCharset("utf8mb4"))
        LogError("Failed to set mysql charset.");

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

    // check message for TransmitManager
    if (!g_extTransmitManager)
    {
        static bool print_tm = false;
        if (!print_tm)
        {
            print_tm = true;
            LogMessage("TransmitManager not install! -> For hide teammate feature, please install TransmitManager.ext! please contact 'https://steamcommunity.com/profiles/76561198048432253' or Download from 'https://github.com/Kxnrl/sm-ext-TransmitManager'.");
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
    Ranks_OnClientConnected(client);
}

public void OnClientPutInServer(int client)
{
    // refresh players
    g_GamePlayers = GetClientCount(true);

    // hook this to check weapon
    SDKHook(client, SDKHook_WeaponEquipPost, Hook_OnPostWeaponEquip);

    // hook this to set transmit
    TransmitManager_AddEntityHooks(client);
}

public void OnClientPostAdminCheck(int client)
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
        }
    }

    // fire to module
    Stats_OnClientPostAdminCheck(client);
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

    // unhook
    SDKUnhook(client, SDKHook_WeaponEquipPost, Hook_OnPostWeaponEquip);

    // if client is not passed.
    if (g_extA2SFirewall && !A2SFirewall_IsClientChecked(client))
        return;

    // fire to module
    Ranks_OnClientDisconnect(client);
    Stats_OnClientDisconnect(client);
}

public void  OnClientDisconnect_Post(int client)
{
    Stats_OnClientDisconnectPost();
}

public void OnEntityCreated(int entity, const char[] classname)
{
    Games_OnEntityCreated(entity);
    Hooks_OnEntityCreated(entity, classname);
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

public void Store_OnHatsCreated(int client, int entity, int slot)
{
    HookTransmit(entity, client);
}

public void Store_OnTrailsCreated(int client, int entity)
{
    HookTransmit(entity, client);
}

public void Store_OnParticlesCreated(int client, int entity)
{
    HookTransmit(entity, client);
}

public void Store_OnNeonCreated(int client, int entity)
{
    HookTransmit(entity, client);
}

public void Store_OnPetsCreated(int client, int entity)
{
    HookTransmit(entity, client);
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
    Games_OnPlayerRunCmd(client, buttons);
    Ranks_OnPlayerRunCmd(client, buttons);

    return Plugin_Continue;
}

public Action Event_TextMsg(UserMsg msg_id, Protobuf msg, const int[] players, int playersNum, bool reliable, bool init)
{
    static char blocks[][] = 
    {
        "#Player_Cash_Award_Killed_Enemy",
        "#Team_Cash_Award_Win_Hostages_Rescue",
        "#Team_Cash_Award_Win_Defuse_Bomb",
        "#Team_Cash_Award_Win_Time",
        "#Team_Cash_Award_Elim_Bomb",
        "#Team_Cash_Award_Elim_Hostage",
        "#Team_Cash_Award_T_Win_Bomb",
        "#Player_Point_Award_Assist_Enemy_Plural",
        "#Player_Point_Award_Assist_Enemy",
        "#Player_Point_Award_Killed_Enemy_Plural",
        "#Player_Point_Award_Killed_Enemy",
        "#Player_Cash_Award_Kill_Hostage",
        "#Player_Cash_Award_Damage_Hostage",
        "#Player_Cash_Award_Get_Killed",
        "#Player_Cash_Award_Respawn",
        "#Player_Cash_Award_Interact_Hostage",
        "#Player_Cash_Award_Killed_Enemy",
        "#Player_Cash_Award_Rescued_Hostage",
        "#Player_Cash_Award_Bomb_Defused",
        "#Player_Cash_Award_Bomb_Planted",
        "#Player_Cash_Award_Killed_Enemy_Generic",
        "#Player_Cash_Award_Killed_VIP",
        "#Player_Cash_Award_Kill_Teammate",
        "#Team_Cash_Award_Win_Hostage_Rescue",
        "#Team_Cash_Award_Loser_Bonus",
        "#Team_Cash_Award_Loser_Zero",
        "#Team_Cash_Award_Rescued_Hostage",
        "#Team_Cash_Award_Hostage_Interaction",
        "#Team_Cash_Award_Hostage_Alive",
        "#Team_Cash_Award_Planted_Bomb_But_Defused",
        "#Team_Cash_Award_CT_VIP_Escaped",
        "#Team_Cash_Award_T_VIP_Killed",
        "#Team_Cash_Award_no_income",
        "#Team_Cash_Award_Generic",
        "#Team_Cash_Award_Custom",
        "#Team_Cash_Award_no_income_suicide",
        "#Player_Cash_Award_ExplainSuicide_YouGotCash",
        "#Player_Cash_Award_ExplainSuicide_TeammateGotCash",
        "#Player_Cash_Award_ExplainSuicide_EnemyGotCash",
        "#Player_Cash_Award_ExplainSuicide_Spectators",
        "#Chat_SavePlayer_Savior",
        "#Chat_SavePlayer_Saved",
        "#Chat_SavePlayer_Spectator",
    };

    char text[64];
    msg.ReadString("params", text, 64, 0);
    for (int i = 0; i < sizeof(blocks); i++)
    if (strcmp(text, blocks[i]) == 0)
    {
        // block this
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

public void Event_OnPressed(const char[] output, int entity, int client, float delay)
{
    Games_OnButtonPressed(entity, client);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int userid = event.GetInt("userid");
    int client = GetClientOfUserId(userid);

    Stats_OnClientSpawn(client);

    CreateTimer(0.1, Games_OnClientSpawn, userid);

    // for no block
    SetEntData(client, g_offsetNoBlock, COLLISION_GROUP_DEBRIS_TRIGGER, 4, true);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int assister = GetClientOfUserId(event.GetInt("assister"));
    bool headshot = event.GetBool("headshot");
    char weapon[32];
    event.GetString("weapon", weapon, 32, "");

    Stats_OnClientDeath(client, attacker, assister, headshot, weapon);
    Hooks_UpdateState();
}

public void Event_PlayerHurts(Event event, const char[] name, bool dontBroadcast)
{
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
    if (dontBroadcast || event.GetBool("disconnect"))
    {
        // skip
        return Plugin_Continue;
    }

    int newteam = event.GetInt("team");
    int oldteam = event.GetInt("oldteam");
    int client  = GetClientOfUserId(event.GetInt("userid"));
    
    g_iTeam[client] = newteam;

    if (newteam == CS_TEAM_SPECTATOR && oldteam > CS_TEAM_SPECTATOR && IsPlayerAlive(client))
    {
        // force suicide
        ForcePlayerSuicide(client);
    }

    event.SetBool("silent", true);
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

public void EventHook_Grenaded(Event event, const char[] name, bool dontBroadcast)
{
    CreateTimer(0.3, Timer_FixWeapon, event.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);
}

public Action CS_OnCSWeaponDrop(int client, int weapon)
{
    char classname[32];
    GetWeaponClassname(weapon, -1, classname, 32);
    if (strcmp(classname, "weapon_taser") != 0)
        return Plugin_Continue;

    return Cvars_AllowDropTaser() ? Plugin_Continue : Plugin_Stop;
}

public Action Command_MapChange(int client, const char[] command, int args)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientConnected(i) || IsFakeClient(i))
            continue;

        ClientCommand(i , "retry");
    }
    return Plugin_Continue;
}

public Action Timer_Tick(Handle timer)
{
    Hooks_UpdateState();

    return Plugin_Continue;
}

public Action Timer_Interval(Handle timer)
{
    Stats_CheckStatus();
    Games_RanderColor();

    return Plugin_Continue;
}

public Action Command_EntFire(int client, int args)
{
    if (args < 2 || args > 4)
    {
        ReplyToCommand(client, "Usage: sm_ef <target> <action> [value] [delay]");
        return Plugin_Handled;
    }

    char target[32];
    GetCmdArg(1, target, 32);

    char action[32];
    GetCmdArg(2, action, 32);

    char value[32];
    if (args >= 3)
    {
        GetCmdArg(3, value, 32);
    }

    float delay = 0.0;
    if (args >= 4)
    {
        char buffer[8];
        GetCmdArg(4, buffer, 8);
        delay = StringToFloat(buffer);
    }

    EntFire(target, action, value, delay);
    ReplyToCommand(client, "EntFire done.");
    return Plugin_Handled;
}

void HookTransmit(int entity, int client)
{
    if (!g_extTransmitManager)
        return;

    TransmitManager_AddEntityHooks(entity);
    TransmitManager_SetEntityOwner(entity, client);
}

void Hooks_UpdateState()
{
    if (!g_extTransmitManager)
        return;

    if (!mg_transmitblock.BoolValue || mp_teammates_are_enemies.BoolValue)
    {
        // force all transmit state
        for(int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i) || IsFakeClient(i))
                continue;

            for (int j = 1; j <= MaxClients; j++) if (IsClientInGame(j) && !IsFakeClient(j))
            {
                TransmitManager_SetEntityState(i, j, true);
            }
        }
        return;
    }

    for (int client = 1; client <= MaxClients; client++) if (IsClientInGame(client) && !IsFakeClient(client))
    {
        bool state = true;
        if (IsPlayerAlive(client))
        {
            state = g_kOptions[client][kO_Transmit];

            if (!state && GetClientButtons(client) & IN_ATTACK2)
                state = true;
        }

        for (int entity = 1; entity <= MaxClients; entity++) if (IsClientInGame(entity) && !IsFakeClient(entity))
        {
            // transmit entity
            TransmitManager_SetEntityState(entity, client, (g_iTeam[entity] != g_iTeam[client] || state));
        }
    }
}

// Fix dodgeball~~
// by Kyle
void Hooks_OnEntityCreated(int entity, const char[] classname)
{
    if (StrContains(classname, "_projectile") > 0)
        SDKHook(entity, SDKHook_SpawnPost, Hooks_OnEntitySpawnedPost);
}

void Hooks_OnEntitySpawnedPost(int entity)
{
    SDKUnhook(entity, SDKHook_SpawnPost, Hooks_OnEntitySpawnedPost);

    if (!IsValidEdict(entity))
        return;

    int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
    if (client == -1)
        return;

    // mark last used grenade to prevent weaon stack;
    g_iNext[client] = GetTime() + 1;

    char model[128];
    GetEntPropString(entity, Prop_Data, "m_ModelName", model, 128);

    float fPos[3];
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fPos);

    float fAgl[3];
    GetEntPropVector(entity, Prop_Send, "m_angRotation", fAgl);

    int trigger_multiple = CreateEntityByName("trigger_multiple");
    if (trigger_multiple == -1)
        return;

    SetEntPropEnt(trigger_multiple, Prop_Send, "m_hOwnerEntity", client);

    DispatchKeyValueVector(trigger_multiple, "origin",  fPos);
    DispatchKeyValueVector(trigger_multiple, "angles",  fAgl);

    DispatchKeyValue(trigger_multiple, "model", model);
    DispatchKeyValue(trigger_multiple, "spawnflags", "1");

    DispatchSpawn(trigger_multiple);

    TeleportEntity(trigger_multiple, fPos, fAgl, NULL_VECTOR);

    SetVariantString("!activator");
    AcceptEntityInput(trigger_multiple, "SetParent", entity, trigger_multiple, 0);

    SetVariantString("OnUser4 !self:Kill::5.0:1");
    AcceptEntityInput(trigger_multiple, "AddOutput");
    AcceptEntityInput(trigger_multiple, "FireUser4");
}

// Fix grenade stack...
// by Kyle & PerfectLaugh
public Action Timer_FixWeapon(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client && IsPlayerAlive(client))
    {
        // Check weapons
        WeaponSwitchFixes(client);
    }
    return Plugin_Stop;
}