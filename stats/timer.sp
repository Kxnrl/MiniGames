public Action Timer_Warmup(Handle timer)
{
	g_tWarmup = INVALID_HANDLE;
	g_bWarmup = false;
	CheckPlayerCount();

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

public Action CheckClientKD(Handle timer, int client)
{
	if(IsValidClient(client) && IsPlayerAlive(client) && g_iAuthId[client] != 9999)
	{
		if(g_iRoundKill[client] >= 8)
		{
			ForcePlayerSuicide(client);
			tPrintToChatAll("%s  \x07%N\x04因为屠虐萌新,被雷神劈死了...", PREFIX, client);
		}
		else if(g_eSession[client][Kills] >= 10)
		{
			float k = float(g_eSession[client][Kills]);
			float d = float(g_eSession[client][Deaths]);

			if(d == 0.0) d = 1.0;

			if(k/d >= 6.0)
			{
				ForcePlayerSuicide(client);
				tPrintToChatAll("%s  \x07%N\x04因为屠虐萌新,被雷神劈死了...", PREFIX, client);
			}
		}
	}
	
	g_iRoundKill[client] = 0;
	
	return Plugin_Stop;
}

public Action Timer_RoundEndDelay(Handle timer)
{	
	ClearArray(array_players);
	
	int teams[MAXPLAYERS+1];

	for(int x = 1; x <= MaxClients; ++x)
		if(IsClientInGame(x))
		{
			teams[x] = GetClientTeam(x);
			if(teams[x] <= 1)
				continue;
			PushArrayCell(array_players, x);
		}


	int client, number, team, counts = RoundToNearest(GetArraySize(array_players)*0.5);
	while((number = RandomArray()) != -1)
	{
		client = GetArrayCell(array_players, number);

		char buffer[128];
		if(counts > 0)
		{
			team = 2;
			counts--;
			Format(buffer, 128, "当前地图已经开启随机组队\n 你已被移动到 <font color='#FF0000' size='20'>恐怖分子");
		}
		else
		{
			team = 3;
			Format(buffer, 128, "当前地图已经开启随机组队\n 你已被移动到 <font color='#0066CC' size='20'>反恐精英");
		}

		if(IsPlayerAlive(client))
			CS_SwitchTeam(client, team);
		else
			ChangeClientTeam(client, team);

		if(teams[client] != team)
			PrintCenterText(client, buffer);
		else
			Store_ResetPlayerArms(client);

		RemoveFromArray(array_players, number);
	}

	ClearArray(array_players);
	
	CreateTimer(0.1, Timer_CleanWeapon);
	
	return Plugin_Stop;
}

public Action Timer_CleanWeapon(Handle timer)
{
	char classname[32];
	for(int entity = MaxClients+1; entity <= 2048; ++entity)
		if(IsValidEdict(entity) && GetEdictClassname(entity, classname, 32))
			if(StrContains(classname, "weapon_", false) == 0)
				AcceptEntityInput(entity, "Kill");
}

public Action Timer_ReConnect(Handle timer)
{
	CheckDatabaseAvaliable();
	
	return Plugin_Stop;
}

public Action Timer_Timeout(Handle timer)
{
	g_bBetTimeout = true;
	
	return Plugin_Stop;
}

public Action Timer_Beacon(Handle timer)
{
	CreateBeacons();

	g_tBeacon = g_bEndGame ? CreateTimer(2.0, Timer_Beacon) : INVALID_HANDLE;
	
	return Plugin_Stop;
}

public void CG_OnGlobalTimer()
{
	char tag[32];
	for(int client = 1; client <= MaxClients; ++client)
	{
		if(!IsClientInGame(client))
			continue;
		
		switch(g_iTagType)
		{
			case 0: CG_GetClientGName(client, tag, 32);
			case 1: {if(!g_iRank[client]) Format(tag, 32, "Top - NORANK", g_iRank[client]); else Format(tag, 32, "Top - %d", g_iRank[client]);}
			case 2: Format(tag, 32, "K/D  %.2f", g_fKD[client]);
			case 3: MG_GetRankName(client, tag, 32);
		}

		CS_SetClientClanTag(client, tag);
	}
}

public Action Timer_SetClientData(Handle timer)
{
	for(int client = 1; client <= MaxClients; ++client)
	{
		if(!IsClientInGame(client))
			continue;

		int target = GetClientAimTarget(client);

		if(IsValidClient(target) && IsPlayerAlive(target))
		{
			char buffer[512], m_szAuth[64], m_szSigature[256];

			CG_GetClientSignature(target, m_szSigature, 256);
			ReplaceString(m_szSigature, 512, "{白}", "");
			ReplaceString(m_szSigature, 512, "{红}", "");
			ReplaceString(m_szSigature, 512, "{粉}", "");
			ReplaceString(m_szSigature, 512, "{绿}", "");
			ReplaceString(m_szSigature, 512, "{黄}", "");
			ReplaceString(m_szSigature, 512, "{亮绿}", "");
			ReplaceString(m_szSigature, 512, "{亮红}", "");
			ReplaceString(m_szSigature, 512, "{灰}", "");
			ReplaceString(m_szSigature, 512, "{褐}", "");
			ReplaceString(m_szSigature, 512, "{橙}", "");
			ReplaceString(m_szSigature, 512, "{紫}", "");
			ReplaceString(m_szSigature, 512, "{亮蓝}", "");
			ReplaceString(m_szSigature, 512, "{蓝}", "");

			CG_GetClientGName(target, m_szAuth, 64);
			Format(m_szAuth, 64, "<font color='#%s'>%s", g_iAuthId[target] == 9999 ? "39C5BB" : "FF8040", m_szAuth);

			Format(buffer, 512, "<font color='#0066CC' size='20'>%N</font>\n认证: %s</font>   排名:<font color='#0000FF'> %d</font>   K/D:<font color='#FF0000'> %.2f</font>\n签名: <font color='#796400'>%s", target, m_szAuth, g_iRank[target], g_fKD[target], m_szSigature);

			Handle pb = StartMessageOne("HintText", client);
			PbSetString(pb, "text", buffer);
			EndMessage();
		}
	}
}

public Action Timer_BurnAll(Handle timer)
{
	g_tBurn = INVALID_HANDLE;
	for(int client = 1; client <= MaxClients; ++client)
		if(IsClientInGame(client))
			if(IsPlayerAlive(client))
				if(g_iAuthId[client] != 9999)
					IgniteEntity(client, 120.0);
				
	return Plugin_Stop;
}