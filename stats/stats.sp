

void BuildRankCache()
{
    PrintToServer("Build Rank Cacahe ...");
    
    if(g_RankArray == INVALID_HANDLE)
        g_RankArray = CreateArray(ByteCountToCells(32));

    ClearArray(g_RankArray);
    PushArrayString(g_RankArray, "This is First Line in Array");
    
    if(g_hDatabase == null)
    {
        CreateTimer(5.0, Timer_RebuildCache, _, TIMER_FLAG_NO_MAPCHANGE);
        return;
    }

    g_hDatabase.Query(SQL_RankCallback, "SELECT `pid`,`name`,`kills`,`deaths`,`score` FROM `rank_mg` WHERE `score` >= 0 ORDER BY `score` DESC;");
}

public Action Timer_RebuildCache(Handle timer)
{
    BuildRankCache();
    return Plugin_Stop;
}

public void SQL_RankCallback(Database db, DBResultSet results, const char[] error, any unuse)
{
    PrintToServer("SQL_RankCallback ...");

    if(results == null)
    {
        LogError("[MG-Stats] Build Rank cache failed: %s", error);
        return;
    }

    if(results.RowCount > 0)
    {
        char name[32], menu[128];
        int iKill, iDeath, iScore;
        
        if(g_hTopMenu != INVALID_HANDLE)
            CloseHandle(g_hTopMenu);

        g_hTopMenu = CreateMenu(MenuHandler_MenuTopPlayers);
        SetMenuTitleEx(g_hTopMenu, "[MG] Top - 50");
        SetMenuExitButton(g_hTopMenu, true);
        SetMenuExitBackButton(g_hTopMenu, false);

        int index;
        while(results.FetchRow())
        {
            index++;
            int pid = results.FetchInt(0);
            results.FetchString(1, name, 32);
            PushArrayCell(g_RankArray, pid);
    
            if(index > 50)
                continue;

            iKill = results.FetchInt(2);
            iDeath = results.FetchInt(3);
            iScore = results.FetchInt(4);
            float KD = (float(iKill) / float(iDeath));
            if(index < 10)
                FormatEx(menu, 128, "#  %d - %s [K/D%.2f 得分%d]", index, name, KD, iScore);
            else FormatEx(menu, 128, "#%d - %s [K/D%.2f 得分%d]", index, name, KD, iScore);
            AddMenuItemEx(g_hTopMenu, ITEMDRAW_DISABLED, "", menu);
        }
    }
}

void LoadPlayer(int client)
{
    if(IsFakeClient(client))
        return;
    
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

    char m_szQuery[512];
    Format(m_szQuery, 128, "SELECT * FROM `rank_mg` WHERE pid='%d';", MG_Users_UserIdentity(client));
    g_hDatabase.Query(SQL_LoadCallback, m_szQuery, GetClientUserId(client));
}

public void SQL_LoadCallback(Database db, DBResultSet results, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);
    
    if(!IsValidClient(client))
        return;

    if(results == null)
    {
        LogError("[MG-Stats] Load %N Failed: %s", client, error);
        return;
    }

    if(results.FetchRow())
    {
        g_bLoaded[client] = true;

        g_eStatistical[client][Kills] = results.FetchInt(2);
        g_eStatistical[client][Deaths] = results.FetchInt(3);
        g_eStatistical[client][Assists] = results.FetchInt(4);
        g_eStatistical[client][Headshots] = results.FetchInt(5);
        g_eStatistical[client][Taser] = results.FetchInt(6);
        g_eStatistical[client][Knife] = results.FetchInt(7);
        g_eStatistical[client][Survival] = results.FetchInt(8);
        g_eStatistical[client][Round] = results.FetchInt(9);
        g_eStatistical[client][Score] = results.FetchInt(10);
        g_eStatistical[client][Onlines] = results.FetchInt(11);

        GetPlayerRank(client);
    }
    else
    {
        char m_szQuery[128];
        FormatEx(m_szQuery, 128, "INSERT INTO `rank_mg` (pid) VALUES ('%d')", MG_Users_UserIdentity(client));
        g_hDatabase.Query(SQL_InsertCallback , m_szQuery, GetClientUserId(client));
    }
}

public void SQL_InsertCallback(Database db, DBResultSet results, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);

    if(!IsValidClient(client))
        return;

    if(results == null)
    {    
        LogError("[MG-Stats] INSERT %N Failed: %s", client, error);
        return;
    }

    g_bLoaded[client] = true;
}

void GetPlayerRank(int client)
{
    int rank = FindValueInArray(g_RankArray, MG_Users_UserIdentity(client));
    if(rank > 0)
        g_iRank[client] = rank;
    else
        g_iRank[client] = GetArraySize(g_RankArray);

    if(g_eStatistical[client][Score] >= 204800)
    {
        g_iLvls[client] = 18;
    }
    else if(g_eStatistical[client][Score] >= 153600)
    {
        g_iLvls[client] = 17;
    }
    else if(g_eStatistical[client][Score] >= 120000)
    {
        g_iLvls[client] = 16;
    }
    else if(g_eStatistical[client][Score] >= 86400)
    {
        g_iLvls[client] = 15;
    }
    else if(g_eStatistical[client][Score] >= 64800)
    {
        g_iLvls[client] = 14;
    }
    else if(g_eStatistical[client][Score] >= 51200)
    {
        g_iLvls[client] = 13;
    }
    else if(g_eStatistical[client][Score] >= 38400)
    {
        g_iLvls[client] = 12;
    }
    else if(g_eStatistical[client][Score] >= 25600)
    {
        g_iLvls[client] = 11;
    }
    else if(g_eStatistical[client][Score] >= 12800)
    {
        g_iLvls[client] = 10;
    }
    else if(g_eStatistical[client][Score] >= 6400)
    {
        g_iLvls[client] = 9;
    }
    else if(g_eStatistical[client][Score] >= 3200)
    {
        g_iLvls[client] = 8;
    }
    else if(g_eStatistical[client][Score] >= 1600)
    {
        g_iLvls[client] = 7;
    }
    else if(g_eStatistical[client][Score] >= 800)
    {
        g_iLvls[client] = 6;
    }
    else if(g_eStatistical[client][Score] >= 400)
    {
        g_iLvls[client] = 5;
    }
    else if(g_eStatistical[client][Score] >= 200)
    {
        g_iLvls[client] = 4;
    }
    else if(g_eStatistical[client][Score] >= 100)
    {
        g_iLvls[client] = 3;
    }
    else if(g_eStatistical[client][Score] >= 50)
    {
        g_iLvls[client] = 2;
    }
    else if(g_eStatistical[client][Score] >= 25)
    {
        g_iLvls[client] = 1;
    }
    else
    {
        g_iLvls[client] = 0;
    }

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

    Format(m_szQuery, 512, "UPDATE `rank_mg` SET name='%s', kills=kills+%d, deaths=deaths+%d, assists=assists+%d, headshots=headshots+%d, taser=taser+%d, knife=knife+%d, survival=survival+%d, round=round+%d, score=score+%d, onlines=onlines+%d WHERE pid='%d';",
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
                            MG_Users_UserIdentity(client));

    Handle pack = CreateDataPack();
    WritePackString(pack, m_szQuery);
    ResetPack(pack);
    g_hDatabase.Query(SQL_SaveCallback, m_szQuery, pack);

    g_bLoaded[client] = false;
}

public void SQL_SaveCallback(Database owner, DBResultSet results, const char[] error, Handle pack)
{
    if(results == null)
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
    char m_szMsg[512];
    FormatEx(m_szMsg, 512, "%s \x04%N\x01进入了游戏  \x01排名\x04%d  \x0CKDA\x04%.2f  \x0CHSP\x04%.2f \x0C得分\x04%d", 
                            PREFIX, 
                            client, 
                            g_iRank[client], 
                            g_fKDA[client],
                            g_fHSP[client],
                            g_eStatistical[client][Score]
                            );

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
        MG_Shop_ClientEarnMoney(attacker, 2, "MG-击杀玩家");
        PrintToChat(attacker, "%s \x10你击杀\x07 %N \x10获得了\x04 1 G", PREFIX_STORE, client);
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

    return (k/d > 5.0);
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