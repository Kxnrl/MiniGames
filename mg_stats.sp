#include <cstrike>
#include <clientprefs>
#include <maoling>
#include <store>
#include <emitsoundany>
#include <cg_core>

#undef REQUIRE_EXTENSIONS
#tryinclude <steamworks>

#pragma newdecls required

#define HIDE_RADAR 1 << 12
#define PREFIX "[\x0CCG\x01]  "
#define PREFIX_STORE "\x01 \x04[Store]  "

enum STAT_TYPES
{
	Kills,
	Deaths,
	Suicides,
	Taser,
	Knife,
	Score,
	Onlines
}

STAT_TYPES g_eStatistical[MAXPLAYERS+1][STAT_TYPES];
STAT_TYPES g_eSession[MAXPLAYERS+1][STAT_TYPES];

int g_iBombRing;
int g_iHalo;
int g_iBettingTotalCT;
int g_iBettingTotalTE;
int g_iTagType;
bool g_bRandomTeam;
bool g_bEnable;
bool g_bEndGame;
bool g_bBetting;
bool g_bBetTimeout;
bool g_bWarmup;
bool g_bMapCredits;
bool g_bRoundEnding;
float g_fBhopSpeed;

int g_iRoundKill[MAXPLAYERS+1];
int g_iRank[MAXPLAYERS+1];
int g_iAuthId[MAXPLAYERS+1];
int g_iBetPot[MAXPLAYERS+1];
int g_iBetTeam[MAXPLAYERS+1];
bool g_bOnDB[MAXPLAYERS+1];
bool g_bOnGround[MAXPLAYERS+1];
char g_szSignature[MAXPLAYERS+1][256];
float g_fKD[MAXPLAYERS+1];

Handle g_hDB;
Handle g_tBeacon;
Handle g_tWarmup;
Handle g_tBurn;

Handle CAVR_CT_MELEE
Handle CVAR_CT_PRIMARY;
Handle CVAR_CT_SECONDARY;
Handle CAVR_TE_MELEE
Handle CVAR_TE_PRIMARY;
Handle CVAR_TE_SECONDARY;
Handle CVAR_BHOPSPEED;
Handle CVAR_AUTOBHOP;
Handle CVAR_CHANGED;
Handle CVAR_AUTOBURN;
Handle CVAR_BURNDELAY;
Handle CVAR_AUTOJUMP;

ArrayList array_players;

#include "stats/cvars.sp"
#include "stats/event.sp"
#include "stats/stock.sp"
#include "stats/timer.sp"

public Plugin myinfo = 
{
	name		= "[MG] - Analytics",
	author		= "Kyle",
	description	= "Ex",
	version		= "2.3 - 2017/02/11",
	url			= "http://steamcommunity.com/id/_xQy_/"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_rank", Cmd_Rank);
	RegConsoleCmd("sm_top", Cmd_Top);
	RegConsoleCmd("sm_kill", Cmd_killme); 
	RegConsoleCmd("kill", Cmd_killme);
	RegConsoleCmd("sm_bc", Cmd_Bet);

	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	HookEvent("cs_win_panel_match", Event_WinPanel, EventHookMode_Post);

	ConVar_OnPluginStart();

	array_players = CreateArray();

	AutoExecConfig(true, "mg_core");
}

public void OnPluginEnd()
{
	for(int client=1; client<=MaxClients; ++client)
		if(IsClientInGame(client))
			SavePlayer(client);
}

public void OnMapStart()
{
	CheckDatabaseAvaliable();
	CreateTimer(0.2, Timer_SetClientData, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	PrecacheSoundAny("maoling/mg/beacon.mp3");
	PrecacheSoundAny("maoling/ninja/ninjawin.mp3");
	AddFileToDownloadsTable("sound/maoling/mg/beacon.mp3");
	AddFileToDownloadsTable("sound/maoling/ninja/ninjawin.mp3");
	
	g_iBombRing = PrecacheModel("materials/sprites/bomb_planted_ring.vmt");
	g_iHalo = PrecacheModel("materials/sprites/halo.vmt");
	
	ConVar_OnMapStart();

	g_iTagType = 0;
	g_bWarmup = true;
	g_bMapCredits = true;
	g_bRoundEnding = false;

	ClearTimer(g_tWarmup);
	g_tWarmup = CreateTimer(GetConVarFloat(FindConVar("mp_warmuptime"))+1.0, Timer_Warmup);
}

public void OnMapEnd()
{
	ClearTimer(g_tBurn);
	ClearTimer(g_tBeacon);
}

public void CG_OnClientLoaded(int client)
{
	g_bOnDB[client] = false;
	g_fKD[client] = 0.0;
	g_iBetPot[client] = 0;
	g_iBetTeam[client] = 0;
	g_iAuthId[client] = CG_GetClientGId(client);

	CheckPlayerCount();

	if(g_hDB != INVALID_HANDLE)
		LoadPlayer(client);
}

public void OnClientDisconnect(int client)
{
	if(g_hDB != INVALID_HANDLE)
		SavePlayer(client);

	CheckPlayerCount();
}

void LoadPlayer(int client)
{
	g_eSession[client][Kills] = 0;
	g_eSession[client][Deaths] = 0;
	g_eSession[client][Suicides] = 0;
	g_eSession[client][Knife] = 0;
	g_eSession[client][Taser] = 0;
	g_eSession[client][Score] = 0;
	g_eSession[client][Onlines] = GetTime();

	g_eStatistical[client][Kills] = 0;
	g_eStatistical[client][Deaths] = 0;
	g_eStatistical[client][Suicides] = 0;
	g_eStatistical[client][Knife] = 0;
	g_eStatistical[client][Taser] = 0;
	g_eStatistical[client][Score] = 0;
	g_eStatistical[client][Onlines] = 0;

	char m_szAuth[32], m_szQuery[512];
	GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
	Format(m_szQuery, 128, "SELECT * FROM `rank_mg` WHERE steamid='%s' ORDER BY `id` ASC LIMIT 1;", m_szAuth);
	SQL_TQuery(g_hDB, SQL_LoadPlayerCallback, m_szQuery, GetClientUserId(client));
}

void SavePlayer(int client)
{
	if(!g_bOnDB[client])
		return;

	char m_szName[32], m_szEname[64], m_szAuth[32], m_szQuery[512];
	GetClientName(client, m_szName, 32);
	SQL_EscapeString(g_hDB, m_szName, m_szEname, 64);
	GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
	
	g_eStatistical[client][Kills] += g_eSession[client][Kills];
	g_eStatistical[client][Deaths] += g_eSession[client][Deaths];
	g_eStatistical[client][Suicides] += g_eSession[client][Suicides];
	g_eStatistical[client][Taser] += g_eSession[client][Taser];
	g_eStatistical[client][Knife] += g_eSession[client][Knife];
	g_eStatistical[client][Score] = ((g_eStatistical[client][Kills]*3)+(g_eStatistical[client][Taser]*2)+(g_eStatistical[client][Knife]*2)-(g_eStatistical[client][Suicides]*10));
	g_eStatistical[client][Onlines] = GetTime() - g_eSession[client][Onlines] + g_eStatistical[client][Onlines];

	Format(m_szQuery, 512, "UPDATE `rank_mg` SET name='%s', kills=kills+'%d', deaths=deaths+'%d', suicides=suicides+'%d', taser=taser+'%d', knife='%d', score='%d', onlines='%d' WHERE steamid='%s';",
							m_szEname,
							g_eSession[client][Kills],
							g_eSession[client][Deaths],
							g_eSession[client][Suicides],
							g_eSession[client][Taser],
							g_eSession[client][Knife],
							g_eStatistical[client][Score],
							g_eStatistical[client][Onlines],
							m_szAuth);

	SQL_TQuery(g_hDB, SQL_SaveCallback, m_szQuery, GetClientUserId(client), DBPrio_High);

	g_bOnDB[client] = false;
}

public void SQL_LoadPlayerCallback(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!client)
		return;

	if(hndl == INVALID_HANDLE)
	{
		LogError("[MG-Stats] Load Player Fail: client:%N error:%s", client, error);
		return;
	}

	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		g_eStatistical[client][Kills] = SQL_FetchInt(hndl, 3);
		g_eStatistical[client][Deaths] = SQL_FetchInt(hndl, 4);
		g_eStatistical[client][Suicides] = SQL_FetchInt(hndl, 5);
		g_eStatistical[client][Taser] = SQL_FetchInt(hndl, 6);
		g_eStatistical[client][Knife] = SQL_FetchInt(hndl, 7);
		g_eStatistical[client][Score] = SQL_FetchInt(hndl, 8);
		g_eStatistical[client][Onlines] = SQL_FetchInt(hndl, 9);
		
		GetPlayerRank(client);
		
		g_bOnDB[client] = true;
	}
	else
	{
		char m_szAuth[32], m_szQuery[128];
		GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
		Format(m_szQuery, 128, "INSERT INTO `rank_mg` (steamid) VALUES ('%s')", m_szAuth);
		SQL_TQuery(g_hDB, SQL_NothingCallback , m_szQuery, GetClientUserId(client), DBPrio_High);
	}
}

public void SQL_NothingCallback(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);

	if(hndl == INVALID_HANDLE)
	{	
		LogError("[MG-Stats] INSERT Fail: client:%N ERROR:%s", client, error);
		return;
	}

	g_bOnDB[client] = true;
}

public void SQL_SaveCallback(Handle owner, Handle hndl, const char[] error, int userid)
{
	if(hndl == INVALID_HANDLE)
	{
		int client = GetClientOfUserId(userid);
		LogError("[MG-Stats] Save Player Fail:client:%N  error:%s", client, error);
		return;
	}
}

public void SQL_RankCallback(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!client)
		return;
	
	if(hndl == INVALID_HANDLE)
	{
		LogError("[MG-Stats] RankCallback:client:%N  error:%s", client, error);
		return;
	}

	if(SQL_GetRowCount(hndl))
	{
		char szSteamID[32], mySteamID[32];
		GetClientAuthId(client, AuthId_Steam2, mySteamID, 32, true);
		int iIndex;
		while(SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, szSteamID, 32);
			iIndex++;

			if(StrEqual(szSteamID ,mySteamID))
			{
				g_iRank[client] = iIndex;
				CG_GetClientSignature(client, g_szSignature[client], 256);
				g_fKD[client] = (g_eStatistical[client][Kills]*1.0)/(g_eStatistical[client][Deaths]*1.0);
				
				CheckClientLocation(client);
				
				break;
			}
		}
	}
}

public int OnGetClientIpLocation(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int client)
{
	if (!bFailure && bRequestSuccessful && eStatusCode == k_EHTTPStatusCode200OK)
	{
		SteamWorks_GetHTTPResponseBodyCallback(hRequest, APIWebResponse, client);
	}
	else if(IsValidClient(client))
	{
		APIWebResponse("未知错误", client);
	}
	
	delete(hRequest);
}

public int APIWebResponse(char[] szLoc, int client)
{
	if(!IsValidClient(client))
		return;
	
	ReplaceString(szLoc, 256, "中国中国", "");

	char AuthoirzedName[32], m_szMsg[512];
	CG_GetClientGName(client, AuthoirzedName, 32);
	Format(m_szMsg, 512, "%s \x04%N\x01进入了游戏 \x0B认证\x01[\x0C%s\x01]  \x01排名\x04%d  \x0CK/D\x04%.2f \x0C得分\x04%d \x0C来自\x01: \x05%s  \x01签名: \x07%s", 
							PREFIX, 
							client, 
							AuthoirzedName, 
							g_iRank[client], 
							g_fKD[client],
							g_eStatistical[client][Score],
							szLoc,
							g_szSignature[client]
							);
	ReplaceString(m_szMsg, 512, "{白}", "\x01");
	ReplaceString(m_szMsg, 512, "{红}", "\x02");
	ReplaceString(m_szMsg, 512, "{粉}", "\x03");
	ReplaceString(m_szMsg, 512, "{绿}", "\x04");
	ReplaceString(m_szMsg, 512, "{黄}", "\x05");
	ReplaceString(m_szMsg, 512, "{亮绿}", "\x06");
	ReplaceString(m_szMsg, 512, "{亮红}", "\x07");
	ReplaceString(m_szMsg, 512, "{灰}", "\x08");
	ReplaceString(m_szMsg, 512, "{褐}", "\x09");
	ReplaceString(m_szMsg, 512, "{橙}", "\x10");
	ReplaceString(m_szMsg, 512, "{紫}", "\x0E");
	ReplaceString(m_szMsg, 512, "{亮蓝}", "\x0B");
	ReplaceString(m_szMsg, 512, "{蓝}", "\x0C");

	if(!g_iRank[client])
		PrintToChatAll("%s 欢迎萌新\x04%N\x01来到CG娱乐休闲服务器", PREFIX, client);
	else
		PrintToChatAll(m_szMsg);
}

public void SQL_TopCallback(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	if(!client || !IsClientInGame(client))
		return;
	
	if(hndl == INVALID_HANDLE)
	{
		LogError("[MG-Stats] TopCallback:client:%N  error:%s", client, error);
		return;
	}

	int iIndex, iKill, iDeath, iScore;
	char sName[32];
	if(SQL_GetRowCount(hndl))
	{
		Handle hPack = CreateDataPack();
		WritePackCell(hPack, iIndex);
		while(SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, sName, sizeof(sName));
			iKill = SQL_FetchInt(hndl, 1);
			iDeath = SQL_FetchInt(hndl, 2);
			iScore = SQL_FetchInt(hndl, 3);

			WritePackString(hPack, sName);
			WritePackCell(hPack, iKill);
			WritePackCell(hPack, iDeath);
			WritePackCell(hPack, iScore);

			iIndex++;
		}

		ResetPack(hPack);
		WritePackCell(hPack, iIndex);
		CreateTopMenu(client, hPack);
	}
	else
		PrintToChat(client, "%s 服务器当前无RANK排行 :3", PREFIX);
}

public Action Cmd_Rank(int client, int args)
{
	if(!client)
		return Plugin_Handled;
		
	PrintToChat(client, "-------------------[\x04娱乐休闲数据统计\x01]-------------------");
	PrintToChat(client, "\x01 \x04杀敌: \x07%i  \x04死亡: \x07%i  \x04自杀: \x07%i", g_eStatistical[client][Kills]+g_eSession[client][Kills], g_eStatistical[client][Deaths]+g_eSession[client][Deaths], g_eStatistical[client][Suicides]+g_eSession[client][Suicides]);
	PrintToChat(client, "\x01 \x04电死: \x07%i  \x04刀杀: \x07%i", g_eStatistical[client][Taser]+g_eSession[client][Taser], g_eStatistical[client][Knife]+g_eSession[client][Knife]);
	PrintToChat(client, "\x01 \x04得分: \x07%i  \x04K/D: \x07%.2f  \x04排名: \x07%i", g_eStatistical[client][Score]+g_eSession[client][Score], g_fKD[client], g_iRank[client]);
	PrintToChat(client, "-------------------[\x04娱乐休闲数据统计\x01]-------------------");
	
	return Plugin_Handled;
}

public Action Cmd_Top(int client, int args)
{
	if(!client)
		return Plugin_Handled;
	
	char sQuery[512];
	FormatEx(sQuery, sizeof(sQuery), "SELECT `name`,`kills`,`deaths`,`score` FROM `rank_mg` WHERE `onlines` > 0 ORDER BY `score` DESC LIMIT 50;");
	SQL_TQuery(g_hDB, SQL_TopCallback, sQuery, GetClientUserId(client));

	return Plugin_Handled;
}

public Action Cmd_killme(int client, int args)
{   
	if(!client)
		return Plugin_Handled;
	
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "%s  你已经嗝屁了,还想自杀?", PREFIX);
		return Plugin_Handled;
	}

	ForcePlayerSuicide(client);
	g_eSession[client][Suicides] += 1;
	g_eSession[client][Score] -= 10;
	PrintToChat(client, "%s 你自杀了,扣除了\x0710\x04Score", PREFIX);
	PrintToChatAll("%s \x04%N\x07自爆菊花...", PREFIX, client);

	return Plugin_Handled;        
}

public void GetPlayerRank(int client)
{
	char m_szQuery[128];
	FormatEx(m_szQuery, 128, "SELECT `steamid`,`score` FROM `rank_mg` WHERE `score` >= 0 ORDER BY `score` DESC;");
	SQL_TQuery(g_hDB, SQL_RankCallback, m_szQuery, GetClientUserId(client));
}

public int MenuHandler_MenuTopPlayers(Handle menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
	}
}

void SetupBeacon()
{
	g_tBeacon = CreateTimer(2.0, Timer_Beacon);
}

public void CG_OnServerLoaded()
{
	CheckDatabaseAvaliable();
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(!IsPlayerAlive(client))
		return Plugin_Continue;	
	
	if(GetEntityFlags(client) & FL_ONGROUND)
		g_bOnGround[client]=true;
	else
		g_bOnGround[client]=false;

	SpeedCap(client);

	return Plugin_Continue;
}

public void SpeedCap(int client)
{
	static bool IsOnGround[MAXPLAYERS+1]; 

	if(g_bOnGround[client])
	{
		if(!IsOnGround[client])
		{
			float CurVelVec[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", CurVelVec);
			
			float speedlimit = g_fBhopSpeed;

			if(g_iAuthId[client] == 9999)
				speedlimit *= 1.15;

			IsOnGround[client] = true;    
			if(GetVectorLength(CurVelVec) > speedlimit)
			{
				IsOnGround[client] = true;
				NormalizeVector(CurVelVec, CurVelVec);
				ScaleVector(CurVelVec, speedlimit);
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, CurVelVec);
			}
		}
	}
	else
		IsOnGround[client] = false;	
}

public Action Cmd_Bet(int client, int args)
{
	if(!g_bBetting)
	{
		PrintToChat(client, "%s  你现在不能下注了", PREFIX);
		return Plugin_Handled;
	}
	
	if(g_iBetPot[client] > 0)
	{
		PrintToChat(client, "%s  你已经下注了", PREFIX);
		return Plugin_Handled;
	}
	
	if(Store_GetClientCredits(client) <= 2000)
	{
		PrintToChat(client, "%s  你的Credits不足", PREFIX);
		return Plugin_Handled;
	}
	
	if(IsPlayerAlive(client))
	{
		PrintToChat(client, "%s  活人不能下注", PREFIX);
		return Plugin_Handled;
	}
	
	if(g_bBetTimeout)
	{
		PrintToChat(client, "%s  下注时间已过,现在不能下注了", PREFIX);
		return Plugin_Handled;
	}
	
	ShowBettingMenu(client);

	return Plugin_Handled;
}

void SetupBetting()
{
	g_iBettingTotalCT = 0;
	g_iBettingTotalTE = 0;

	for(int client = 1; client <= MaxClients; ++client)
	{
		if(IsClientInGame(client) && !IsPlayerAlive(client))
		{
			if(Store_GetClientCredits(client) > 2000)
				ShowBettingMenu(client);
			else
				PrintToChat(client, "%s  你的信用点不足2000,不能参与菠菜", PREFIX);
		}
	}

	EmitSoundToAllAny("maoling/ninja/ninjawin.mp3", SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
}

void ShowBettingMenu(int client)
{
	Handle menu = CreateMenu(MenuHandler_BetSelectTeam);

	SetMenuTitleEx(menu, "[MG]   菠菜");
	
	AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "现在请你选择可能获胜的队伍");
	AddMenuItemEx(menu, ITEMDRAW_SPACER, "", "");
	AddMenuItemEx(menu, ITEMDRAW_SPACER, "", "");
	AddMenuItemEx(menu, ITEMDRAW_SPACER, "", "");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "3", "我选择CT获胜");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "2", "我选择TE获胜");

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 10);

	PrintToChat(client, "%s  输入!bc可以重新打开菠菜菜单", PREFIX);
}

public int MenuHandler_BetSelectTeam(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		if(!g_bBetting)
		{
			PrintToChat(client, "%s  你现在不能下注了", PREFIX);
			return;
		}

		if(IsPlayerAlive(client))
		{
			PrintToChat(client, "%s  活人不能下注", PREFIX);
			return;
		}

		if(g_bBetTimeout)
		{
			PrintToChat(client, "%s  下注时间已过,现在不能下注了", PREFIX);
			return;
		}

		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		g_iBetTeam[client] = StringToInt(info);
		
		if(g_iBetTeam[client] > 1)
			ShowPotMenu(client);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Cancel)
	{
		if(IsClientInGame(client))
			PrintToChat(client, "%s  输入!bc可以重新打开菠菜菜单", PREFIX);
	}
}

void ShowPotMenu(int client)
{
	Handle menu = CreateMenu(MenuHandler_BetSelectPot);

	SetMenuTitleEx(menu, "[MG]   菠菜\n 现在请你选择下注金额 \n ");

	AddMenuItem(menu, "200", "200 信用点");
	AddMenuItem(menu, "300", "300 信用点");
	AddMenuItem(menu, "500", "500 信用点");
	AddMenuItem(menu, "1000", "1000 信用点");
	AddMenuItem(menu, "5000", "5000 信用点");
	AddMenuItem(menu, "10000", "10000 信用点");

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 5);
}

public int MenuHandler_BetSelectPot(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		if(!g_bBetting)
		{
			PrintToChat(client, "%s  你现在不能下注了", PREFIX);
			return;
		}

		if(IsPlayerAlive(client))
		{
			PrintToChat(client, "%s  活人不能下注", PREFIX);
			return;
		}
		
		if(g_bBetTimeout)
		{
			PrintToChat(client, "%s  下注时间已过,现在不能下注了", PREFIX);
			return;
		}

		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		int icredits = StringToInt(info);
		
		if(Store_GetClientCredits(client) > icredits)
			g_iBetPot[client] = icredits
		else
		{
			PrintToChat(client, "%s  你的钱不够", PREFIX);
			return;
		}

		Store_SetClientCredits(client, Store_GetClientCredits(client)-g_iBetPot[client], "MG-Bet下注");
		
		if(g_iBetTeam[client] == 2)
		{
			g_iBettingTotalTE += g_iBetPot[client];
			PrintToChatAll("%s  \x10%N\x01已下注\x07恐怖分子\x01[\x04%d\x01信用点]|[奖金池:\x10%d信用点]", PREFIX, client, g_iBetPot[client], g_iBettingTotalTE);
		}

		if(g_iBetTeam[client] == 3)
		{
			g_iBettingTotalCT += g_iBetPot[client];
			PrintToChatAll("%s  \x10%N\x01已下注\x0B反恐精英\x01[\x04%d\x01信用点]|[奖金池:\x10%d信用点]", PREFIX, client, g_iBetPot[client], g_iBettingTotalCT);
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Cancel)
	{
		if(IsClientInGame(client))
			PrintToChat(client, "%s  下注时间已过,现在不能下注了", PREFIX);
	}
}

void SettlementBetting(int winner)
{
	if(g_iBettingTotalTE == 0 || g_iBettingTotalCT == 0 || !(2 <= winner <= 3))
	{
		for(int i=1;i<=MaxClients;++i)
		{
			if(IsClientInGame(i) && g_iBetPot[i])
				Store_SetClientCredits(i, Store_GetClientCredits(i)+g_iBetPot[i], "MG-菠菜-结算退还");
			g_iBetPot[i] = 0;
			g_iBetTeam[i] = 0;
		}

		g_bBetting = false;
	
		g_iBettingTotalCT = 0;
		g_iBettingTotalTE = 0;
	
		PrintToChatAll("%s  \x10本局菠菜无效,信用点已返还", PREFIX);

		return;
	}

	float m_fMultiplier;
	int vol,totalcredits,maxclient,maxcredits,icredits;
	
	if(winner == 2)
	{
		vol = g_iBettingTotalTE;
		totalcredits = RoundToFloor(g_iBettingTotalCT*0.8);
	}

	if(winner == 3)
	{
		vol = g_iBettingTotalCT;
		totalcredits = RoundToFloor(g_iBettingTotalTE*0.8);
	}

	for(int i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && g_iBetPot[i] > 0)
		{
			if(winner == g_iBetTeam[i])
			{
				m_fMultiplier = float(g_iBetPot[i])/float(vol);
				icredits = g_iBetPot[i]+RoundToFloor(totalcredits*m_fMultiplier);
				Store_SetClientCredits(i, Store_GetClientCredits(i)+icredits, "MG-菠菜-结算");
				PrintToChat(i, "%s \x10你菠菜赢得了\x04 %d 信用点", PREFIX_STORE, icredits);
				
				if(icredits > maxcredits)
				{
					maxcredits = icredits;
					maxclient = i;
				}
			}
			else
				PrintToChat(i, "%s \x10你菠菜输了\x04 %d 信用点", PREFIX_STORE, g_iBetPot[i]);

			g_iBetPot[i] = 0;
			g_iBetTeam[i] = 0;
		}
	}
	
	if(IsValidClient(maxclient) && maxcredits > 0)
		PrintToChatAll("%s  \x10本次菠菜\x04%N\x10吃了猫屎,赢得了\x04 %d 信用点", PREFIX, maxclient, maxcredits);
	
	g_bBetting = false;

	g_iBettingTotalCT = 0;
	g_iBettingTotalTE = 0;
}

void RemoveRadar(int client)
{
	if(IsValidClient(client))
	{
		SetEntProp(client, Prop_Send, "m_iHideHUD", HIDE_RADAR);
		SetEntPropFloat(client, Prop_Send, "m_flDetectedByEnemySensorTime", 0.0);
	}
}