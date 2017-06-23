#define HIDE_RADAR 1 << 12

int g_iRoundKill[MAXPLAYERS+1];
bool g_bOnGround[MAXPLAYERS+1];

int g_iTagType;
Handle g_tBurn;
float g_fBhopSpeed;

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(!IsPlayerAlive(client))
		return Plugin_Continue;

	Mutators_RunCmd(client, buttons, vel);
	
	if(!g_bRealBHop)
		return Plugin_Continue;

	if(GetEntityFlags(client) & FL_ONGROUND)
		g_bOnGround[client]=true;
	else
		g_bOnGround[client]=false;

	SpeedCap(client);

	return Plugin_Continue;
}

void SpeedCap(int client)
{
	static bool IsOnGround[MAXPLAYERS+1]; 

	if(g_bOnGround[client])
	{
		if(!IsOnGround[client])
		{
			float CurVelVec[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", CurVelVec);
			
			float speedlimit = g_fBhopSpeed;

			if(g_iAuth[client] == 9999)
				speedlimit *= 1.15;

			IsOnGround[client] = true;    
			if(GetVectorLength(CurVelVec) > speedlimit)
			{
				NormalizeVector(CurVelVec, CurVelVec);
				ScaleVector(CurVelVec, speedlimit);
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, CurVelVec);
			}
		}
	}
	else
		IsOnGround[client] = false;	
}
/*
void Client_SetClientTag(int client)
{
	char tag[32];
	
	switch(g_iTagType)
	{
		case 0: CG_GetClientGName(client, tag, 32);
		case 1: {if(!g_iRank[client]) Format(tag, 32, "Top - NORANK", g_iRank[client]); else Format(tag, 32, "Top - %d", g_iRank[client]);}
		case 2: Format(tag, 32, "K/D  %.2f", g_fKDA[client]);
		case 3: Client_GetRankName(client, tag, 32);
	}

	CS_SetClientClanTag(client, tag);
}

void Client_GetRankName(int client, char[] buffer, int maxLen)
{
	if(g_iRank[client] == 1)
		FormatEx(buffer, maxLen, "娱乐TOP1");
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
*/
public Action Client_CenterText(Handle timer)
{
	for(int client = 1; client <= MaxClients; ++client)
	{
		if(!IsClientInGame(client))
			continue;

		int target = GetClientAimTarget(client);

		if(IsValidClient(target) && IsPlayerAlive(target))
		{
			char buffer[512], m_szAuth[64];

			CG_GetClientGName(target, m_szAuth, 64);
			Format(m_szAuth, 64, "<font color='#%s'>%s", g_iAuth[target] == 9999 ? "39C5BB" : "FF8040", m_szAuth);

			Format(buffer, 512, "<font color='#0066CC' size='20'>%N</font>\n认证: %s</font>   排名:<font color='#0000FF'> %d</font>   K/D:<font color='#FF0000'> %.2f</font>\n签名: <font color='#796400'>%s", target, m_szAuth, g_iRank[target], g_fKDA[target], g_szSignature[target]);

			Handle pb = StartMessageOne("HintText", client);
			PbSetString(pb, "text", buffer);
			EndMessage();
		}
	}
}

public Action Client_BurnAll(Handle timer)
{
	g_tBurn = INVALID_HANDLE;
	for(int client = 1; client <= MaxClients; ++client)
		if(IsClientInGame(client))
			if(IsPlayerAlive(client))
				if(g_iAuth[client] != 9999)
					IgniteEntity(client, 120.0);
				
	return Plugin_Stop;
}

void Client_SpawnPost(int client)
{
	if(!IsValidClient(client))
		return;
	
	SetEntProp(client, Prop_Send, "m_iHideHUD", HIDE_RADAR);
	SetEntPropFloat(client, Prop_Send, "m_flDetectedByEnemySensorTime", 0.0);
	
	if(!IsPlayerAlive(client) || g_iAuth[client] == 9999)
		return;
	
	if(g_iRoundKill[client] >= 8 || Stats_AllowScourgeClient(client))
	{
		if(GetRandomInt(1, 100) > 50)
		{
			ForcePlayerSuicide(client);
			tPrintToChatAll("%s  \x07%N\x04因为屠虐萌新,被雷神劈死了...", PREFIX, client);
		}
		else
		{
			SetEntPropFloat(client, Prop_Send, "m_flDetectedByEnemySensorTime", 99999.0);
			tPrintToChatAll("%s  \x07%N\x04因为屠虐萌新,强制被透视...", PREFIX, client);
		}
	}

	g_iRoundKill[client] = 0;
}

public Action Client_RandomTeam(Handle timer)
{
	ArrayList array_players = CreateArray();
	
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
	while((number = RandomArray(array_players)) != -1)
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

	CloseHandle(array_players);

	return Plugin_Stop;
}

int RandomArray(ArrayList array)
{
	int x = GetArraySize(array);
	
	if(x == 0)
		return -1;
	
	return GetRandomInt(0, x-1);
}

void Client_OnRoundStart()
{
	g_iTagType = (g_iTagType == 3) ? 0 : g_iTagType+1;

	if(GetConVarBool(FindConVar("mg_autoburn")))
	{
		ClearTimer(g_tBurn);
		g_tBurn = CreateTimer(GetConVarFloat(FindConVar("mg_burndelay")), Client_BurnAll);
	}
}

void Client_OnRoundEnd()
{
	if(g_tBurn == INVALID_HANDLE)
	{
		for(int client = 1; client <= MaxClients; ++client)
			if(IsClientInGame(client))
				if(IsPlayerAlive(client))
					if(g_iAuth[client] != 9999)
						ExtinguishEntity(client);
	}
	else
	{
		KillTimer(g_tBurn);
		g_tBurn = INVALID_HANDLE;
	}

	if(GetConVarBool(FindConVar("mg_randomteam")))
		CreateTimer(2.0, Client_RandomTeam, _, TIMER_FLAG_NO_MAPCHANGE);
}