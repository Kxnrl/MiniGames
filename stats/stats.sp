enum STAT_TYPES
{
	Kills,
	Deaths,
	Assists,
	Headshots,
	Taser,
	Knife,
	Survival,
	Round,
	Score,
	Onlines
}

STAT_TYPES g_eStatistical[MAXPLAYERS+1][STAT_TYPES];
STAT_TYPES g_eSession[MAXPLAYERS+1][STAT_TYPES];

Handle g_RankArray;
Handle g_hTopMenu;

bool g_bTracking;

bool g_bLoaded[MAXPLAYERS+1];

void BuildRankCache()
{
	if(g_RankArray == INVALID_HANDLE)
		g_RankArray = CreateArray(ByteCountToCells(32));

	ClearArray(g_RankArray);
	PushArrayString(g_RankArray, "This is First Line in Array");
	
	if(g_hDatabase == INVALID_HANDLE)
	{
		CreateTimer(5.0, Timer_RebuildCache, _, TIMER_FLAG_NO_MAPCHANGE);
		return;
	}

	char m_szQuery[128];
	Format(m_szQuery, 128, "SELECT `steamid`,`name`,`kills`,`deaths`,`score` FROM `rank_mg` WHERE `score` >= 0 ORDER BY `score` DESC;");
	SQL_TQuery(g_hDatabase, SQL_RankCallback, m_szQuery);
}

public Action Timer_RebuildCache(Handle timer)
{
	BuildRankCache();
	return Plugin_Stop;
}

public void SQL_RankCallback(Handle owner, Handle hndl, const char[] error, any unuse)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("[MG-Stats] Build Rank cache failed: %s", error);
		return;
	}

	if(SQL_GetRowCount(hndl))
	{
		char auth[32], name[32], menu[128];
		int iKill, iDeath, iScore;
		
		if(g_hTopMenu != INVALID_HANDLE)
			CloseHandle(g_hTopMenu);
		
		g_hTopMenu = CreateMenu(MenuHandler_MenuTopPlayers);
		SetMenuTitleEx(g_hTopMenu, "[MG] Top - 50");
		SetMenuExitButton(g_hTopMenu, true);
		SetMenuExitBackButton(g_hTopMenu, false);

		int index;
		while(SQL_FetchRow(hndl))
		{
			index++;
			SQL_FetchString(hndl, 0, auth, 32);
			SQL_FetchString(hndl, 1, name, 32);
			PushArrayString(g_RankArray, auth);
	
			if(index > 50)
				continue;

			iKill = SQL_FetchInt(hndl, 2);
			iDeath = SQL_FetchInt(hndl, 3);
			iScore = SQL_FetchInt(hndl, 4);
			float KD = (float(iKill) / float(iDeath));
			if(index < 10)
				Format(menu, 128, "#  %d - %s [K/D%.2f 得分%d]", index, name, KD, iScore);
			else Format(menu, 128, "#%d - %s [K/D%.2f 得分%d]", index, name, KD, iScore);
			AddMenuItemEx(g_hTopMenu, ITEMDRAW_DISABLED, "", menu);
		}
	}
}

void LoadPlayer(int client)
{
	g_eSession[client][Kills] = 0;
	g_eSession[client][Deaths] = 0;
	g_eSession[client][Assists] = 0;
	g_eSession[client][Headshots] = 0;
	g_eSession[client][Knife] = 0;
	g_eSession[client][Taser] = 0;
	g_eSession[client][Survival] = 0;
	g_eSession[client][Round] = 0;
	g_eSession[client][Score] = 0;
	g_eSession[client][Onlines] = GetTime();

	g_eStatistical[client][Kills] = 0;
	g_eStatistical[client][Deaths] = 0;
	g_eStatistical[client][Assists] = 0;
	g_eStatistical[client][Headshots] = 0;
	g_eStatistical[client][Knife] = 0;
	g_eStatistical[client][Taser] = 0;
	g_eStatistical[client][Survival] = 0;
	g_eStatistical[client][Round] = 0;
	g_eStatistical[client][Score] = 0;
	g_eStatistical[client][Onlines] = 0;

	char m_szAuth[32], m_szQuery[512];
	GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
	Format(m_szQuery, 128, "SELECT * FROM `rank_mg` WHERE steamid='%s';", m_szAuth);
	SQL_TQuery(g_hDatabase, SQL_LoadCallback, m_szQuery, GetClientUserId(client));
}

public void SQL_LoadCallback(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!IsValidClient(client))
		return;

	if(hndl == INVALID_HANDLE)
	{
		LogError("[MG-Stats] Load %N Failed: %s", client, error);
		return;
	}

	if(SQL_FetchRow(hndl))
	{
		g_bLoaded[client] = true;

		g_eStatistical[client][Kills] = SQL_FetchInt(hndl, 2);
		g_eStatistical[client][Deaths] = SQL_FetchInt(hndl, 3);
		g_eStatistical[client][Assists] = SQL_FetchInt(hndl, 4);
		g_eStatistical[client][Headshots] = SQL_FetchInt(hndl, 5);
		g_eStatistical[client][Taser] = SQL_FetchInt(hndl, 6);
		g_eStatistical[client][Knife] = SQL_FetchInt(hndl, 7);
		g_eStatistical[client][Survival] = SQL_FetchInt(hndl, 8);
		g_eStatistical[client][Round] = SQL_FetchInt(hndl, 9);
		g_eStatistical[client][Score] = SQL_FetchInt(hndl, 10);
		g_eStatistical[client][Onlines] = SQL_FetchInt(hndl, 11);

		GetPlayerRank(client);
	}
	else
	{
		char m_szAuth[32], m_szQuery[128];
		GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
		Format(m_szQuery, 128, "INSERT INTO `rank_mg` (steamid) VALUES ('%s')", m_szAuth);
		SQL_TQuery(g_hDatabase, SQL_InsertCallback , m_szQuery, GetClientUserId(client));
	}
}

public void SQL_InsertCallback(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);

	if(!IsValidClient(client))
		return;

	if(hndl == INVALID_HANDLE)
	{	
		LogError("[MG-Stats] INSERT %N Failed: %s", client, error);
		return;
	}

	g_bLoaded[client] = true;
}

void GetPlayerRank(int client)
{
	char steamid[32];
	GetClientAuthId(client, AuthId_Steam2, steamid, 32, true);
	int rank = FindStringInArray(g_RankArray, steamid);
	if(rank > 0)
		g_iRank[client] = rank;

	CG_GetClientSignature(client, g_szSignature[client], 256);
	g_fKDA[client] = (g_eStatistical[client][Kills]*1.0)/((g_eStatistical[client][Deaths]+1)*1.0);
	g_fHSP[client] = float(g_eStatistical[client][Headshots]*100)/float((g_eStatistical[client][Kills]-g_eStatistical[client][Knife]-g_eStatistical[client][Taser])+1);

	PrintWellcomeMessage(client);
}

void SavePlayer(int client)
{
	if(!g_bLoaded[client])
		return;

	char m_szName[32], m_szEname[64], m_szAuth[32], m_szQuery[512];
	GetClientName(client, m_szName, 32);
	SQL_EscapeString(g_hDatabase, m_szName, m_szEname, 64);
	GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);

	Format(m_szQuery, 512, "UPDATE `rank_mg` SET name='%s', kills=kills+%d, deaths=deaths+%d, assists=assists+%d, headshots=headshots+%d, taser=taser+%d, knife=knife+%d, survival=survival+%d, round=round+%d, score=score+%d, onlines=onlines+%d WHERE steamid='%s';",
							m_szEname,
							g_eSession[client][Kills],
							g_eSession[client][Deaths],
							g_eSession[client][Assists],
							g_eSession[client][Headshots],	
							g_eSession[client][Taser],
							g_eSession[client][Knife],
							g_eSession[client][Survival],
							g_eSession[client][Round],
							g_eSession[client][Score],
							GetTime() - g_eSession[client][Onlines],
							m_szAuth);

	Handle pack = CreateDataPack();
	WritePackString(pack, m_szQuery);
	ResetPack(pack);
	SQL_TQuery(g_hDatabase, SQL_SaveCallback, m_szQuery, pack);

	g_bLoaded[client] = false;
}

public void SQL_SaveCallback(Handle owner, Handle hndl, const char[] error, Handle pack)
{
	if(hndl == INVALID_HANDLE)
	{
		char m_szQuery[512];
		ReadPackString(pack, m_szQuery, 512);
		LogError("[MG-Stats] Save Player Failed: %s\nSQL Query: %s", error, m_szQuery);
		return;
	}
	
	CloseHandle(pack);
}

void PrintWellcomeMessage(int client)
{
	char AuthoirzedName[32], m_szMsg[512];
	CG_GetClientGName(client, AuthoirzedName, 32);
	Format(m_szMsg, 512, "%s \x04%N\x01进入了游戏 \x0B认证\x01[\x0C%s\x01]  \x01排名\x04%d  \x0CKDA\x04%.2f  \x0CHSP\x04%.2f \x0C得分\x04%d  \x01签名: \x07%s", 
							PREFIX, 
							client, 
							AuthoirzedName, 
							g_iRank[client], 
							g_fKDA[client],
							g_fHSP[client],
							g_eStatistical[client][Score],
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

	ReplaceString(g_szSignature[client], 256, "{白}", "");
	ReplaceString(g_szSignature[client], 256, "{红}", "");
	ReplaceString(g_szSignature[client], 256, "{粉}", "");
	ReplaceString(g_szSignature[client], 256, "{绿}", "");
	ReplaceString(g_szSignature[client], 256, "{黄}", "");
	ReplaceString(g_szSignature[client], 256, "{亮绿}", "");
	ReplaceString(g_szSignature[client], 256, "{亮红}", "");
	ReplaceString(g_szSignature[client], 256, "{灰}", "");
	ReplaceString(g_szSignature[client], 256, "{褐}", "");
	ReplaceString(g_szSignature[client], 256, "{橙}", "");
	ReplaceString(g_szSignature[client], 256, "{紫}", "");
	ReplaceString(g_szSignature[client], 256, "{亮蓝}", "");
	ReplaceString(g_szSignature[client], 256, "{蓝}", "");

	if(!g_iRank[client])
		PrintToChatAll("%s 欢迎萌新\x04%N\x01来到CG娱乐休闲服务器", PREFIX, client);
	else
		PrintToChatAll(m_szMsg);
}

void Stats_OnClientDeath(int client, int attacker, int assister, bool headshot, const char[] weapon)
{
	if(!g_bTracking)
		return;

	g_eSession[client][Deaths]++;
	g_eStatistical[client][Deaths]++;

	g_fKDA[client] = (g_eStatistical[client][Kills]*1.0)/((g_eStatistical[client][Deaths]+1)*1.0);

	if(IsValidClient(assister))
	{
		g_eSession[assister][Assists]++;
		g_eStatistical[assister][Assists]++;
	}

	if(client == attacker || !IsValidClient(attacker))
		return;

	g_iRoundKill[attacker]++;

	g_eSession[attacker][Kills] += 1;
	g_eSession[attacker][Score] += 3;
	g_eStatistical[attacker][Kills] += 1;
	g_eStatistical[attacker][Score] += 3;

	if(StrContains(weapon, "negev", false) == -1 && StrContains(weapon, "m249", false) == -1 && StrContains(weapon, "p90", false) == -1 && StrContains(weapon, "hegrenade", false) == -1)
	{
		Store_SetClientCredits(attacker, Store_GetClientCredits(attacker)+1, "MG-击杀玩家");
		PrintToChat(attacker, "%s \x10你击杀\x07 %N \x10获得了\x04 1 信用点", PREFIX_STORE, client);
	}

	if(StrContains(weapon, "knife", false) != -1)
	{
		g_eSession[attacker][Knife] += 1;
		g_eSession[attacker][Score] += 2;
		g_eStatistical[attacker][Knife] += 1;
		g_eStatistical[attacker][Score] += 2;
	}
	else if(StrContains(weapon, "taser", false) != -1)
	{
		g_eSession[attacker][Taser] += 1;
		g_eSession[attacker][Score] += 2;
		g_eStatistical[attacker][Taser] += 1;
		g_eStatistical[attacker][Score] += 2;
	}
	
	if(headshot)
	{
		g_eSession[attacker][Score]++;
		g_eSession[attacker][Headshots]++;
		g_eStatistical[attacker][Score]++;
		g_eStatistical[attacker][Headshots]++;
		
		g_fHSP[attacker] = float(g_eStatistical[attacker][Headshots]*100)/float((g_eStatistical[attacker][Kills]-g_eStatistical[attacker][Knife]-g_eStatistical[attacker][Taser])+1);
	}
	
	g_fKDA[attacker] = (g_eStatistical[attacker][Kills]*1.0)/((g_eStatistical[attacker][Deaths]+1)*1.0);
}

bool Stats_AllowScourgeClient(int client)
{
	float k = float(g_eSession[client][Kills]);
	float d = float(g_eSession[client][Deaths]);
	
	if(k <= 10.0)
		return false;

	if(d == 0.0) d = 1.0;

	if(k/d >= 6.0)
		return true;
	
	return false;
}

void Stats_OnClientSpawn(int client)
{
	if(!g_bTracking || g_tWarmup != INVALID_HANDLE)
		return;
	
	g_eSession[client][Round]++;
	g_eStatistical[client][Round]++;
}

public Action Stats_OnRoundEnd(Handle timer)
{
	if(!g_bTracking || g_tWarmup != INVALID_HANDLE)
		return;
	
	for(int client = 1; client <= MaxClients; ++client)
	{
		if(!IsClientInGame(client))
			continue;
		
		if(!IsPlayerAlive(client))
			continue;
		
		g_eSession[client][Survival]++;
		g_eStatistical[client][Survival]++;
	}
}