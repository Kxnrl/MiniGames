#include <cstrike>
#include <clientprefs>
#include <maoling>
#include <emitsoundany>
#include <sdkhooks>

#include <MagicGirl.NET>
#include <MagicGirl/user>
#include <MagicGirl/shop>
#include "stats/global.h"

#pragma newdecls required

#define PREFIX "[\x04MG\x01]  "
#define PREFIX_STORE "[\x04Shop\x01]  "

#include "stats/bets.sp"
#include "stats/button.sp"
#include "stats/client.sp"
#include "stats/cvars.sp"
#include "stats/event.sp"
#include "stats/stats.sp"

public Plugin myinfo = 
{
    name        = "MiniGames",
    author      = "Kyle",
    description = "Ex",
    version     = "4.0 - 2018/02/05",
    url         = "https://steamcommunity.com/id/Kxnrl/"
};

public void OnPluginStart()
{
    Button_OnPluginStart();
    ConVar_OnPluginStart();
    Bets_OnPluginStart();

    RegConsoleCmd("sm_rank", Command_Rank);
    RegConsoleCmd("sm_stats", Command_Rank);
    RegConsoleCmd("sm_top", Command_Top);
    RegConsoleCmd("sm_bc", Command_Bet);
    RegConsoleCmd("sm_bet", Command_Bet);

    for(int x; x < 27; ++x)
        AddCommandListener(Command_BlockCmd, g_szBlockCmd[x]);
    
    HookEventEx("round_start", Event_RoundStart, EventHookMode_Post);
    HookEventEx("round_end", Event_RoundEnd, EventHookMode_Post);
    
    HookEventEx("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    HookEventEx("player_death", Event_PlayerDeath, EventHookMode_Post);
    HookEventEx("player_hurt",  Event_PlayerHurts, EventHookMode_Post);

    HookEventEx("player_team", Event_dontBroadcast, EventHookMode_Pre);
    HookEventEx("player_disconnect", Event_dontBroadcast, EventHookMode_Pre);
    
    HookEventEx("cs_win_panel_match", Event_WinPanel, EventHookMode_Post);
    HookEventEx("announce_phase_end", Event_AnnouncePhaseEnd, EventHookMode_Post);
}

public void OnPluginEnd()
{
    for(int client=1; client<=MaxClients; ++client)
        if(IsClientInGame(client))
            SavePlayer(client);
}

public void OnMapStart()
{
    g_hDatabase = MG_MySQL_GetDatabase();
    if(g_hDatabase == INVALID_HANDLE)
        CreateTimer(1.0, Timer_ReConnect);
    
    cs_player_manager = FindEntityByClassname(MaxClients+1, "cs_player_manager");
    if(cs_player_manager != -1)
        SDKHookEx(cs_player_manager, SDKHook_ThinkPost, Hook_OnThinkPost);

    BuildRankCache();

    PrecacheSoundAny("maoling/mg/beacon.mp3");
    AddFileToDownloadsTable("sound/maoling/mg/beacon.mp3");

    g_iRing = PrecacheModel("materials/sprites/bomb_planted_ring.vmt");
    g_iHalo = PrecacheModel("materials/sprites/halo.vmt");

    Button_OnMapStart();
    ConVar_OnMapStart();

    ClearTimer(g_tWarmup);
    g_tWarmup = CreateTimer(GetConVarFloat(FindConVar("mp_warmuptime")), Timer_Warmup);
    CreateTimer(1.0, Timer_CheckWeapon, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void MG_MySQL_OnConnected(Database db)
{
    g_hDatabase = db;
}

public void OnMapEnd()
{
    ClearTimer(g_tWallHack);
    
    g_smPunishList.Clear();
    
    if(cs_player_manager != -1)
    {
        SDKUnhook(cs_player_manager, SDKHook_ThinkPost, Hook_OnThinkPost);
        cs_player_manager = -1;
    }
}

public void OnClientConnected(int client)
{
    g_bLoaded[client] = false;
    g_fKDA[client] = 0.0;
    g_fHSP[client] = 0.0;
    g_iBetPot[client] = 0;
    g_iBetTeam[client] = 0;
    g_iRoundKill[client] = 0;
    g_iRank[client] = 0;
    g_iBetPot[client] = 0;
    g_iBetTeam[client] = 0;
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquip);
    IntToString(GetSteamAccountID(client), g_szAccount[client], 32);
}

public void OnClientDataChecked(int client)
{
    g_bTracking = (GetClientCount(true) >= 6) ?  true : false;

    if(g_hDatabase != INVALID_HANDLE)
        LoadPlayer(client);
}

public void OnClientDisconnect(int client)
{
    if(!IsClientInGame(client))
        return;

    if(g_hDatabase != INVALID_HANDLE)
        SavePlayer(client);

    g_iLvls[client] = 0;
    g_bTracking = (GetClientCount(true) >= 6) ?  true : false;
    SDKUnhook(client, SDKHook_WeaponEquipPost, OnWeaponEquip);
    
    if(g_bPunished[client])
    {
        int count = 0;
        g_smPunishList.GetValue(g_szAccount[client], count);
        g_smPunishList.SetValue(g_szAccount[client], ++count, true);
        g_bPunished[client] = false;
    }
}

public Action CS_OnBuyCommand(int client, const char[] weapon)
{
    if(strcmp(weapon, "scar20") == 0 || strcmp(weapon, "g3sg1") == 0)
    {
        RequestFrame(Frame_SlayGaygun, client);
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

void Frame_SlayGaygun(int client)
{
    if(IsValidClient(client))
    {
        ForcePlayerSuicide(client);
        PrintToChatAll("[\x04MG\x01]  \x0B%N\x01使用\x09连狙\x01时遭遇天谴", client);
    }
}

public void OnWeaponEquip(int client, int weapon)
{
    if(!IsValidEdict(weapon))
        return;

    char classname[32];
    GetEdictClassname(weapon, classname, 32);

    if(mg_restrictawp.BoolValue && StrEqual(classname, "weapon_awp"))
    {
        PrintToChat(client, "[\x04MG\x01]  \x07当前地图限制Awp的使用");
        AcceptEntityInput(weapon, "Kill");
    }

    if(mg_slaygaygun.BoolValue && (StrEqual(classname, "weapon_scar20") || StrEqual(classname, "weapon_g3sg1")))
    {
        AcceptEntityInput(weapon, "Kill");
        RequestFrame(Frame_SlayGaygun, client);
    }
}

public Action Timer_ReConnect(Handle timer)
{
    g_hDatabase = MG_MySQL_GetDatabase();
    if(g_hDatabase == INVALID_HANDLE)
        CreateTimer(1.0, Timer_ReConnect);

    return Plugin_Stop;
}

public Action Timer_Warmup(Handle timer)
{
    g_tWarmup = INVALID_HANDLE;
    g_bTracking = (GetClientCount(true) >= 6) ?  true : false;

    CreateTimer(5.0, Timer_CheckWarmup, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    
    return Plugin_Stop;
}

public Action Timer_CheckWarmup(Handle timer)
{
    if(GameRules_GetProp("m_bWarmupPeriod") != 1)
        return Plugin_Stop;

    ServerCommand("mp_warmup_end");

    return Plugin_Continue;
}

public Action Command_Rank(int client, int args)
{
    if(!g_bLoaded[client])
        return Plugin_Handled;

    PrintToChat(client, "-------------------[\x04娱乐休闲数据统计\x01]-------------------");
    PrintToChat(client, "\x01 \x04KDA: \x07%.2f  \x04HSP: \x07%.2f%%", g_fKDA[client], g_fHSP[client]);
    PrintToChat(client, "\x01 \x04杀敌: \x07%d  \x04死亡: \x07%d", g_eStatistical[client][Kills], g_eStatistical[client][Deaths]);
    PrintToChat(client, "\x01 \x04爆头: \x07%d  \x04助攻: \x07%d", g_eStatistical[client][Headshots], g_eStatistical[client][Assists]);
    PrintToChat(client, "\x01 \x04电击: \x07%d  \x04刀杀: \x07%d", g_eStatistical[client][Taser], g_eStatistical[client][Knife]);
    PrintToChat(client, "\x01 \x04局数: \x07%d  \x04存活: \x07%d", g_eStatistical[client][Round], g_eStatistical[client][Survival]);
    PrintToChat(client, "\x01 \x04得分: \x07%d  \x04排名: \x07%d", g_eStatistical[client][Score], g_iRank[client]);
    
    return Plugin_Handled;
}

public Action Command_Top(int client, int args)
{
    if(g_hTopMenu == INVALID_HANDLE)
        return Plugin_Handled;
    
    DisplayMenu(g_hTopMenu, client, 0);

    return Plugin_Handled;
}

public int MenuHandler_MenuTopPlayers(Handle menu, MenuAction action, int param1, int param2)
{

}

public Action Command_BlockCmd(int client, const char[] command, int args)
{
    return Plugin_Handled;
}

public Action Command_Bet(int client, int args)
{
    ShowBettingMenu(client);

    return Plugin_Handled;
}

void PrintToDeath(const char[] chat, any ...)
{
    char vm[256];
    VFormat(vm, 256, chat, 2);
    for(int client = 1; client <= MaxClients; ++client)
        if(IsClientInGame(client) && !IsPlayerAlive(client))
            PrintToChat(client, vm);
}

void UTIL_Scoreboard(int client, int buttons)
{
    if(!(buttons & IN_SCORE))
        return;
    
    if(GetEntProp(client, Prop_Data, "m_nOldButtons") & IN_SCORE)
        return;

    if(StartMessageOne("ServerRankRevealAll", client) != INVALID_HANDLE)
        EndMessage();
}

public Action Timer_CheckWeapon(Handle timer)
{
    if(GameRules_GetProp("m_bWarmupPeriod") != 1)
        return Plugin_Stop;

    for(int x = MaxClients+1; x <= 2048; ++x)
    {
        if(!IsValidEdict(x))
            continue;
        
        char classname[32];
        GetEdictClassname(x, classname, 32);
        if(StrContains(classname, "weapon_") != 0)
            continue;
    
        if(GetEntProp(x, Prop_Send, "m_hPrevOwner") <= 0)
            continue;

        if(GetEntPropEnt(x, Prop_Send, "m_hOwnerEntity") > 0)
            continue;

        AcceptEntityInput(x, "Kill");
    }

    return Plugin_Continue;
}