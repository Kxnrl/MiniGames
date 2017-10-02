#include <cstrike>
#include <clientprefs>
#include <maoling>
#include <store>
#include <emitsoundany>
#include <cg_core>
#include <sdkhooks>
#include <huodong>

#pragma newdecls required

#define PREFIX "[\x0CCG\x01]  "
#define PREFIX_STORE "\x01 \x04[Store]  "

int cs_player_manager = -1;
int g_iLvls[MAXPLAYERS+1];
int g_iRank[MAXPLAYERS+1];
int g_iAuth[MAXPLAYERS+1];
char g_szSignature[MAXPLAYERS+1][256];
float g_fKDA[MAXPLAYERS+1];
float g_fHSP[MAXPLAYERS+1];

bool g_bRealBHop;

char g_szBlockCmd[27][16] = {"kill", "explode", "coverme", "takepoint", "holdpos", "regroup", "followme", "takingfire", "go", "fallback", "sticktog", "getinpos", "stormfront", "report", "roger", "enemyspot", "needbackup", "sectorclear", "inposition", "reportingin","getout", "negative", "enemydown", "cheer", "thanks", "nice", "compliment"};

Handle g_hDatabase;
Handle g_tWarmup;

#include "stats/bets.sp"
#include "stats/client.sp"
#include "stats/cvars.sp"
#include "stats/event.sp"
#include "stats/stats.sp"
#include "stats/mutas.sp"

public Plugin myinfo = 
{
	name		= "MG Server Core",
	author		= "Kyle",
	description	= "Ex",
	version		= "3.4.2 - 2017/10/02",
	url			= "http://steamcommunity.com/id/_xQy_/"
};

public void OnPluginStart()
{
	ConVar_OnPluginStart();
	Mutators_OnPluginStart();
	Bets_OnPluginStart();

	RegConsoleCmd("sm_rank", Command_Rank);
	RegConsoleCmd("sm_stats", Command_Rank);
	RegConsoleCmd("sm_top", Command_Top);
	RegConsoleCmd("sm_bc", Command_Bet);
	RegConsoleCmd("sm_bet", Command_Bet);

	for(int x; x < 27; ++x)
		AddCommandListener(Command_BlockCmd, g_szBlockCmd[x]);

	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	HookEvent("cs_win_panel_match", Event_WinPanel, EventHookMode_Post);
    HookEvent("announce_phase_end", Event_AnnouncePhaseEnd, EventHookMode_Post);
}

public void OnPluginEnd()
{
	for(int client=1; client<=MaxClients; ++client)
		if(IsClientInGame(client))
			SavePlayer(client);
}

public void OnMapStart()
{
	g_hDatabase = CG_DatabaseGetGames();
	if(g_hDatabase == INVALID_HANDLE)
		CreateTimer(1.0, Timer_ReConnect);
    
    cs_player_manager = FindEntityByClassname(MaxClients+1, "cs_player_manager");
	if(cs_player_manager != -1)
    {
        GameRules_SetProp("m_bIsValveDS", 1, 0, 0, true);
        SDKHookEx(cs_player_manager, SDKHook_ThinkPost, Hook_OnThinkPost);
    }

	BuildRankCache();
	//CreateTimer(0.25, Client_CenterText, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	PrecacheSoundAny("maoling/mg/beacon.mp3");
	AddFileToDownloadsTable("sound/maoling/mg/beacon.mp3");

	g_iRing = PrecacheModel("materials/sprites/bomb_planted_ring.vmt");
	g_iHalo = PrecacheModel("materials/sprites/halo.vmt");

	ConVar_OnMapStart();
	Mutators_OnMapStart();

	ClearTimer(g_tWarmup);
	g_tWarmup = CreateTimer(GetConVarFloat(FindConVar("mp_warmuptime")), Timer_Warmup);
}

public void CG_OnServerLoaded()
{
	g_hDatabase = CG_DatabaseGetGames();
	if(g_hDatabase == INVALID_HANDLE)
		CreateTimer(1.0, Timer_ReConnect);
}

public void OnMapEnd()
{
	ClearTimer(g_tBurn);
    
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
	g_bCamp[client] = false;
	g_iRoundKill[client] = 0;
	g_iRank[client] = 0;
	g_iAuth[client] = 0;
	g_bCamp[client] = false;
	g_bSlap[client] = false;
	g_iBetPot[client] = 0;
	g_iBetTeam[client] = 0;
}

public void CG_OnClientLoaded(int client)
{
	g_iAuth[client] = CG_ClientGetGId(client);

	g_bTracking = (GetClientCount(true) >= 6) ?  true : false;

	if(g_hDatabase != INVALID_HANDLE)
		LoadPlayer(client);
}

public void OnClientDisconnect(int client)
{
	if(g_hDatabase != INVALID_HANDLE)
		SavePlayer(client);

    g_iLvls[client] = 0;
	g_bTracking = (GetClientCount(true) >= 6) ?  true : false;
}

public Action Timer_ReConnect(Handle timer)
{
	g_hDatabase = CG_DatabaseGetGames();
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
	PrintToChat(client, "\x01 \x04爆头: \x07%d  \x04助攻: \x07%f", g_eStatistical[client][Headshots], g_eStatistical[client][Assists]);
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