stock void CheckDatabaseAvaliable()
{
	g_hDB = CG_GetGameDatabase();
	if(g_hDB == INVALID_HANDLE)
		CreateTimer(1.0, Timer_ReConnect);
}

stock int RandomArray()
{
	int x = GetArraySize(array_players);
	
	if(x == 0)
		return -1;
	
	return GetRandomInt(0, x-1);
}

stock void CheckClientLocation(int client)
{
	char m_szIpAdr[16], m_szUrl[128];
	GetClientIP(client, m_szIpAdr, 16);
	Format(m_szUrl, 128, "https://csgogamers.com/searchip/?ip=%s", m_szIpAdr);
	
	Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, m_szUrl);
	if(!hRequest || !SteamWorks_SetHTTPCallbacks(hRequest, OnGetClientIpLocation) || !SteamWorks_SetHTTPRequestContextValue(hRequest, client) || !SteamWorks_SendHTTPRequest(hRequest))
	{
		delete(hRequest);
	}
}

stock void CheckPlayerCount()
{
	if(GetCurrentPlayers() < 6)
		g_bEnable = false;
	else
		g_bEnable = true;
	
	if(g_bWarmup)
		g_bEnable = false;
}

stock int GetCurrentPlayers()
{
	int count;
	for(int i=1;i<=MaxClients;i++)
		if(IsClientInGame(i))
			count++;
		
	return count;
}

stock void CreateTopMenu(int client, Handle pack)
{
	char sBuffer[256], sName[32];
	Handle hMenu = CreateMenu(MenuHandler_MenuTopPlayers);

	FormatEx(sBuffer, 256, "[CG] 娱乐休闲 Top50");
	SetMenuTitle(hMenu, sBuffer);
	
	SetMenuPagination(hMenu, 10);
	
	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, false);

	ResetPack(pack);
	int iCount = ReadPackCell(pack);
	for(int i = 0; i < iCount; i++)
	{
		ReadPackString(pack, sName, sizeof(sName));
		int iKill = ReadPackCell(pack);
		int iDeath = ReadPackCell(pack);
		int iScore = ReadPackCell(pack);
		float KD = (float(iKill) / float(iDeath));
		FormatEx(sBuffer, 256, "#%d - %s [K/D%.2f 得分%d]", i + 1, sName, KD, iScore);
		AddMenuItem(hMenu, "", sBuffer, ITEMDRAW_DISABLED);
	}
	CloseHandle(pack);
	DisplayMenu(hMenu, client, 30);
}

stock void CreateBeacons()
{
	for(int i=1; i<=MaxClients; ++i)
	{
		if(!IsClientInGame(i))
			continue;
		
		if(!IsPlayerAlive(i))
			continue;

		float fPos[3];
		GetClientAbsOrigin(i, fPos);
		fPos[2] += 8;

		if(g_iAuthId[i] == 9999)
		{
			int[] Clients = new int[MaxClients];
			int index = 0;
			for(int target = 1; target <=MaxClients; ++target)
			{
				if(IsClientInGame(target) && !IsPlayerAlive(target))
				{
					Clients[index] = target;
					index++;
				}
			}
			TE_SetupBeamRingPoint(fPos, 10.0, 750.0, g_iBombRing, g_iHalo, 0, 10, 0.6, 10.0, 0.5, {255, 75, 75, 255}, 5, 0);
			TE_Send(Clients, index);
			EmitSoundToAllAny("maoling/mg/beacon.mp3", i);
		}
		else
		{
			TE_SetupBeamRingPoint(fPos, 10.0, 750.0, g_iBombRing, g_iHalo, 0, 10, 0.6, 10.0, 0.5, {255, 75, 75, 255}, 5, 0);
			TE_SendToAll();
			EmitSoundToAllAny("maoling/mg/beacon.mp3", i);
		}
	}
}

stock void MG_GetRankName(int client, char[] buffer, int maxLen)
{
	if(g_iRank[client] == 1)
		FormatEx(buffer, maxLen, "VAC");
	else if(g_iRank[client] == 2)
		FormatEx(buffer, maxLen, "无敌挂逼");
	else if(g_iRank[client] == 3)
		FormatEx(buffer, maxLen, "刷分Dog");
	else if(20 >= g_iRank[client] > 3)
		FormatEx(buffer, maxLen, "进阶挂壁");
	else if(50 >= g_iRank[client] > 20)
		FormatEx(buffer, maxLen, "娱乐老司机");
	else if(100 >= g_iRank[client] > 50)
		FormatEx(buffer, maxLen, "灵车司机");
	else if(500 >= g_iRank[client] > 100)
		FormatEx(buffer, maxLen, "初获驾照");
	else if(g_iRank[client] == 0)
		FormatEx(buffer, maxLen, "初来乍到");
	else
		FormatEx(buffer, maxLen, "娱乐萌新");
}