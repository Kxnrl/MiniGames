public Action Timer_Waruup(Handle timer)
{
	g_tWarmup = INVALID_HANDLE;
	g_bWarmup = false;
	CheckPlayerCount();

	if(GameRules_GetProp("m_bWarmupPeriod") == 1)
		ServerCommand("mp_warmup_end");
}

public Action RemoveRadar(Handle timer, int client)
{
	if(IsValidClient(client))
		SetEntProp(client, Prop_Send, "m_iHideHUD", HIDE_RADAR);
}

public Action Timer_RoundEndDelay(Handle timer)
{	
	ClearArray(array_players);

	for(int x = 1; x <= MaxClients; ++x)
		if(IsClientInGame(x) && GetClientTeam(x) >= 2)
			PushArrayCell(array_players, x);

	int client, number, team, counts = RoundToNearest(GetArraySize(array_players)*0.5);
	while((number = RandomArray()) != -1)
	{
		client = GetArrayCell(array_players, number);

		char buffer[128];
		if(counts > 0)
		{
			team = 2;
			counts--;
			PrintToChat(client, "%s 你已被移动到\x07恐怖分子", PREFIX);
			Format(buffer, 128, "当前地图已经开启随机组队\n 你已被移动到 <font color='#FF0000' size='20'>恐怖分子");
		}
		else
		{
			team = 3;
			PrintToChat(client, "%s 你已被移动到\x0B反恐精英", PREFIX);
			Format(buffer, 128, "当前地图已经开启随机组队\n 你已被移动到 <font color='#0066CC' size='20'>反恐精英");
		}
		
		if(IsPlayerAlive(client))
			CS_SwitchTeam(client, team);
		else
			ChangeClientTeam(client, team);
		
		Handle pb = StartMessageOne("HintText", client);
		PbSetString(pb, "text", buffer);
		EndMessage();

		RemoveFromArray(array_players, number);
	}

	ClearArray(array_players);
}

public Action Timer_ReConnect(Handle timer)
{
	CheckDatabaseAvaliable();
}

public Action Timer_Timeout(Handle timer)
{
	g_bBetTimeout = true;
}

public Action Timer_Beacon(Handle timer)
{
	CreateBeacons();

	if(g_bEndGame)
		g_tBeacon = CreateTimer(2.0, Timer_Beacon);
	else
		g_tBeacon = INVALID_HANDLE;
}

public Action Timer_SetClientData(Handle timer)
{
	for(int client = 1; client <= MaxClients; ++client)
	{
		if(!IsClientInGame(client))
			continue;

		char tag[32];
		
		switch(g_iTagType)
		{
			case 0: PA_GetGroupName(client, tag, 32);
			case 1: {if(!g_iRank[client]) Format(tag, 32, "Top - NORANK", g_iRank[client]); else Format(tag, 32, "Top - %d", g_iRank[client]);}
			case 2: Format(tag, 32, "K/D  %.2f", g_fKD[client]);
			case 3: MG_GetRankName(client, tag, 32);
		}

		CS_SetClientClanTag(client, tag);

		int target = GetClientAimTarget(client);

		if(target > 0 && target <= MaxClients && IsClientInGame(target) && IsPlayerAlive(target))
		{
			char buffer[1024], m_szName[64], m_szAuth[64], m_szSigature[256];
			
			GetClientName(target, m_szName, 64);
			ReplaceString(m_szName, 64, "<", "〈");
			ReplaceString(m_szName, 64, ">", "〉");
			
			CG_GetSignature(target, m_szSigature, 256);
			ReplaceString(m_szSigature, 1024, "{白}", "");
			ReplaceString(m_szSigature, 1024, "{红}", "");
			ReplaceString(m_szSigature, 1024, "{粉}", "");
			ReplaceString(m_szSigature, 1024, "{绿}", "");
			ReplaceString(m_szSigature, 1024, "{黄}", "");
			ReplaceString(m_szSigature, 1024, "{亮绿}", "");
			ReplaceString(m_szSigature, 1024, "{亮红}", "");
			ReplaceString(m_szSigature, 1024, "{灰}", "");
			ReplaceString(m_szSigature, 1024, "{褐}", "");
			ReplaceString(m_szSigature, 1024, "{橙}", "");
			ReplaceString(m_szSigature, 1024, "{紫}", "");
			ReplaceString(m_szSigature, 1024, "{亮蓝}", "");
			ReplaceString(m_szSigature, 1024, "{蓝}", "");
			
			PA_GetGroupName(target, m_szAuth, 64);
			if(PA_GetGroupID(target) == 9999)
				Format(m_szAuth, 64, "<font color='#FF00FF'>%s", m_szAuth);
			else
				Format(m_szAuth, 64, "<font color='#FF8040'>%s", m_szAuth);
			
			Format(buffer, 1024, "<font color='#0066CC' size='20'>%s</font>\n认证: %s</font>   排名:<font color='#0000FF'> %d</font>   K/D:<font color='#FF0000'> %.2f</font>\n签名: <font color='#796400'>%s", m_szName, m_szAuth, g_iRank[target], g_fKD[target], m_szSigature);
	
			Handle pb = StartMessageOne("HintText", client);
			PbSetString(pb, "text", buffer);
			EndMessage();
		}
	}
}