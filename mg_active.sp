#include <sourcemod>
#include <cstrike>


char g_sMap[128];
char logFile[128];
bool g_bEnable;

Handle CVAR_TIMELIMIT;


public OnPluginStart()
{
	BuildPath(Path_SM, logFile, sizeof(logFile), "logs/mg_active.log");
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	
	CVAR_TIMELIMIT = FindConVar("mp_timelimit");
	
	HookConVarChange(CVAR_TIMELIMIT, OnSettingChanged);
}

public OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(g_bEnable && !StrEqual(newValue, "45"))
		SetConVarString(CVAR_TIMELIMIT, "45", true, false);
}

public OnMapStart()
{
	g_bEnable = false;
	
	GetCurrentMap(g_sMap, 128);
	if( StrEqual(g_sMap, "mg_hype2_v2c") ||
		StrEqual(g_sMap, "mg_mikis_multigames") ||
		StrEqual(g_sMap, "mg_randomizer_reborn_v1") ||
		StrEqual(g_sMap, "mg_swag_multigames_v6_2") ||
		StrEqual(g_sMap, "mg_warmcup_headshot_csgo3") ||
		StrEqual(g_sMap, "mg_galaxy_multigames_v3") ||
		StrEqual(g_sMap, "mg_50arenas_v2"))
	{
		char sTime[128];
		FormatTime(sTime, 128, "%Y.%m.%d %H:%M:%S", GetTime());
	
		//if(StrContains(sTime, "19:", false) != -1 || StrContains(sTime, "20:", false) != -1 || StrContains(sTime, "21:", false) != -1 || StrContains(sTime, "22:", false) != -1)
		//{
			LogToFileEx(logFile, "START============[%s]============START", g_sMap);
			LogToFileEx(logFile, "Time: %s", sTime);
			
			g_bEnable = true;
		//}
	}
}

public OnMapEnd()
{
	LogToFileEx(logFile, "END==============[%s]==============END", g_sMap);
	
	g_bEnable = false;
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if(!g_bEnable)
		return;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client < 1 || client > MaxClients || IsFakeClient(client))
		return;
	
	PrintToChat(client, "[\x04娱\x07乐\x0E休\x10闲\x01]  \x04当前的地图为刷分竞赛地图,努力刷分赢取奖品吧");
	PrintToChat(client, "[\x04娱\x07乐\x0E休\x10闲\x01]  \x04当前的地图为刷分竞赛地图,努力刷分赢取奖品吧");
	PrintToChat(client, "[\x04娱\x07乐\x0E休\x10闲\x01]  \x04当前的地图为刷分竞赛地图,努力刷分赢取奖品吧");
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if(!g_bEnable)
		return;
	
	
	int timeLeft;
	GetMapTimeLeft(timeLeft);
	
	if(timeLeft > 10)
		return;
	
	int Score = -1;
	int Client = -1;
	int iScore = -1;
	
	for(int client = 1; client <= MaxClients; ++client)
	{
		if(IsClientInGame(client) && !IsFakeClient(client))
		{
			iScore = CS_GetClientContributionScore(client);
			if(iScore > Score)
			{
				Score = iScore;
				Client = client;
			}
		}
	}
	
	if(Client != -1 && Score != -1)
	{
		LogToFileEx(logFile, "Player: %N", Client);
		LogToFileEx(logFile, "Score: %d", Score);
		LogToFileEx(logFile, "Frags: %d", GetClientFrags(Client));
		LogToFileEx(logFile, "Deaths: %d", GetClientDeaths(Client));
		LogToFileEx(logFile, "Assists: %d", CS_GetClientAssists(Client));
	}
}














