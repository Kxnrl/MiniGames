public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.0, RemoveRadar, GetClientOfUserId(GetEventInt(event, "userid")));
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	if(g_bWarmup || !g_bEnable)
		return;

	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	g_eSession[client][Deaths]++;

	if(client == attacker || !IsValidClient(attacker))
		return;

	char weapon[64];
	GetEventString(event, "weapon", weapon, 64);

	g_eSession[attacker][Kills] += 1;
	g_eSession[attacker][Score] += 3;

	if(StrContains(weapon, "negev", false) == -1 && StrContains(weapon, "m249", false) == -1 && StrContains(weapon, "p90", false) == -1 && StrContains(weapon, "hegrenade", false) == -1)
	{
		Store_SetClientCredits(attacker, Store_GetClientCredits(attacker)+1, "MG-击杀玩家");
		PrintToChat(attacker, "%s \x10你击杀\x07 %N \x10获得了\x04 1 信用点", PREFIX_STORE, client);
	}

	if(StrContains(weapon, "knife", false) != -1)
	{
		g_eSession[attacker][Knife] += 1;
		g_eSession[attacker][Score] += 2;
	}
	if(StrContains(weapon, "taser", false) != -1)
	{
		g_eSession[attacker][Taser] += 1;
		g_eSession[attacker][Score] += 2;
	}

	if(!g_bEndGame && !g_bBetting)
	{
		int ct, te;

		for(int i = 1; i <= MaxClients; ++i)
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				if(GetClientTeam(i) == 2)
					te++;
					
				if(GetClientTeam(i) == 3)
					ct++;
			}

		if(ct == te && (ct == 1 || ct == 2))
		{
			g_bEndGame = true;
			g_bBetting = true;
			g_bBetTimeout = false;
			CreateTimer(15.0, Timer_Timeout);
			SetupBeacon();
			SetupBetting();
		}
	}
}

public Action Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
	SetEventBroadcast(event, true);
	
	return Plugin_Changed;
}

public Action Event_PlayerDisconnect(Handle event, const char[] name, bool dontBroadcast)
{
	SetEventBroadcast(event, true);

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	char AuthoirzedName[32], m_szMsg[512];
	PA_GetGroupName(client, AuthoirzedName, 32);
	FormatEx(m_szMsg, 512, "%s  \x04%N\x01离开了游戏 \x0B认证\x01[\x0C%s\x01]  \x01排名\x04%d  \x0CK/D\x04%.2f \x0C得分\x04%d  \x01签名: \x07%s", 
							PREFIX, 
							client, 
							AuthoirzedName, 
							g_iRank[client], 
							g_fKD[client],
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

	if(!g_iRank[client])
		PrintToChatAll("%s  萌新\x04%N\x01离开了游戏", PREFIX, client);
	else
		PrintToChatAll(m_szMsg);
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	g_bEndGame = false;
	ClearTimer(g_tBeacon);
	
	g_bBetting = false;
	g_bBetTimeout = true;
	g_iTagType = (g_iTagType == 3) ? 0 : g_iTagType+1;
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	g_bEndGame = false;
	ClearTimer(g_tBeacon);

	if(g_bBetting)
		SettlementBetting(GetEventInt(event, "winner"));

	if(g_bRandomTeam)
		CreateTimer(2.0, Timer_RoundEndDelay, _, TIMER_FLAG_NO_MAPCHANGE);
}