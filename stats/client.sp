#define HIDE_RADAR 1 << 12

int g_iRoundKill[MAXPLAYERS+1];
bool g_bOnGround[MAXPLAYERS+1];

int g_iTagType;
Handle g_tBurn;
float g_fBhopSpeed;

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
    UTIL_Scoreboard(client, buttons);
    
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

			CG_ClientGetGroupName(target, m_szAuth, 64);
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
		SetEntPropFloat(client, Prop_Send, "m_flDetectedByEnemySensorTime", 99999.0);
		tPrintToChatAll("%s  \x07%N\x04因为屠虐萌新,强制被透视...", PREFIX, client);
	}

	g_iRoundKill[client] = 0;
}

public Action Client_RandomTeam(Handle timer)
{
	ArrayList array_players = CreateArray();
	
	int teams[MAXPLAYERS+1];
    int waifu[MAXPLAYERS+1];

	for(int x = 1; x <= MaxClients; ++x)
		if(IsClientInGame(x))
		{
			teams[x] = GetClientTeam(x);
			if(teams[x] <= 1)
				continue;
			PushArrayCell(array_players, x);
            waifu[x] = CG_CouplesGetPartnerIndex(x);
		}

	char buffer[128];
	int client, target, number, tindex, team, counts = RoundToNearest(GetArraySize(array_players)*0.5);
	while((number = RandomArray(array_players)) != -1)
	{
		client = GetArrayCell(array_players, number);
        RemoveFromArray(array_players, number);

        target = waifu[client];
        if(waifu[client] > 0 && (tindex = FindValueInArray(array_players, waifu[client])) != -1)
        {
            RemoveFromArray(array_players, tindex);

            if(counts > 1)
            {
                counts -= 2;
                CS_SwitchTeam(client, 2);
                CS_SwitchTeam(target, 2);
                Format(buffer, 128, "当前地图已经开启随机组队\n 你和你老婆已被移动到 <font color='#FF0000' size='20'>恐怖分子");
            }
            else
            {
                CS_SwitchTeam(client, 3);
                CS_SwitchTeam(target, 3);
                Format(buffer, 128, "当前地图已经开启随机组队\n 你和你老婆已被移动到 <font color='#0066CC' size='20'>反恐精英");
            }

            if(teams[target] != team)
                PrintCenterText(target, buffer);
            else
                Store_ResetPlayerArms(target);
        }
        else
        {
            if(counts > 0)
            {
                counts--;
                CS_SwitchTeam(client, 2);
                Format(buffer, 128, "当前地图已经开启随机组队\n 你已被移动到 <font color='#FF0000' size='20'>恐怖分子");
            }
            else
            {
                CS_SwitchTeam(client, 3);
                Format(buffer, 128, "当前地图已经开启随机组队\n 你已被移动到 <font color='#0066CC' size='20'>反恐精英");
            }
        }

		if(teams[client] != team)
			PrintCenterText(client, buffer);
		else
            Store_ResetPlayerArms(client);
        
        if(target < -1)
            PrintToChat(client, "[\x0ECP\x01]   你没有老婆,不能享受CP的随机组队优选");
        else if(target == -1)
            PrintToChat(client, "[\x0ECP\x01]   你老婆离线,不能享受CP的随机组队优选");
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