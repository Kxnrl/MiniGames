/******************************************************************/
/*                                                                */
/*                         MiniGames Core                         */
/*                                                                */
/*                                                                */
/*  File:          stats.sp                                       */
/*  Description:   MiniGames Game Mod.                            */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2018  Kyle                                      */
/*  2018/03/05 16:51:01                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/


static any t_Session[MAXPLAYERS+1][Analytics];
static any t_StatsDB[MAXPLAYERS+1][Analytics];

static bool t_bLoaded[MAXPLAYERS+1];
static bool t_bEnabled = false;


void Stats_OnPluginStart()
{
    RegConsoleCmd("sm_stats", Command_Stats);
}

public Action Command_Stats(int client, int args)
{
    if(!client)
        return Plugin_Handled;
    
    if(!t_bLoaded[client])
    {
        Chat(client, "%T", "stats loading", client);
        return Plugin_Handled;
    }

    char username[32];
    GetClientName(client, username, 32);
    
    DataPack pack = new DataPack();
    for(int i = 0; i < view_as<int>(Analytics); ++i)
        pack.WriteCell(t_Session[client][i] + t_StatsDB[client][i]);
    
    DisplayRankDetails(client, username, pack);
    
    return Plugin_Handled;
}

void Stats_OnPluginEnd()
{
    for(int client = 1; client <= MaxClients; ++ client)
        if(IsClientInGame(client) && !IsFakeClient(client))
            Stats_OnClientDisconnect(client);
}

void Stats_OnWinPanel()
{
    for(int client = 1; client <= MaxClients; ++ client)
        if(IsClientInGame(client) && !IsFakeClient(client))
            Stats_OnClientConnected(client);
}

void Stats_OnMapStart()
{
    // disallow tracking
    t_bEnabled = false;
}

void Stats_OnWarmupEnd()
{
    // check tracking
    t_bEnabled = (GetClientCount(true) >= 6 && g_tWarmup == null);
}

void Stats_OnClientConnected(int client)
{
    // init client
    
    for(int i = 0; i < view_as<int>(Analytics); ++i)
    {
        t_Session[client][i] = 0;
        t_StatsDB[client][i] = 0;
    }

    t_bLoaded[client] = false;
    
    t_Session[client][iTotalOnline] = GetTime();
}

void Stats_OnClientPutInServer(int client)
{
    // check tracking
    t_bEnabled = (GetClientCount(true) >= 6 && g_tWarmup == null);

    // ignore bot and gotv
    if(IsFakeClient(client) || IsClientSourceTV(client))
        return;

    // load client data
    Stats_LoadClient(client);
}

void Stats_OnClientDisconnect(int client)
{
    t_bEnabled = (GetClientCount(true) >= 6 && g_tWarmup == null);

    if(!IsClientInGame(client))
        return;

    Stats_PublicMessage(client, true);

    // saving data - session
    FormatEx(m_szQuery, 1024,  "INSERT INTO `k_minigames_s` VALUES      \
                                (                                       \
                                    DEFAULT,                            \
                                    %d,                                 \
                                    '%s',                               \
                                    '%s',                               \
                                    %d,                                 \
                                    %d,                                 \
                                    %d,                                 \
                                    %d,                                 \
                                    %d,                                 \
                                    %d,                                 \
                                    %d,                                 \
                                    %d,                                 \
                                    %d,                                 \
                                    %d,                                 \
                                    %d,                                 \
                                    %d,                                 \
                                    %d,                                 \
                                    %d,                                 \
                                    %d,                                 \
                                    %d                                  \
                                );                                      \
                                ",
                                g_iUId[client],
                                g_szA2STicket[client],
                                g_szMap,
                                t_Session[client][iKills],
                                t_Session[client][iDeaths],
                                t_Session[client][iAssists],
                                t_Session[client][iHits],
                                t_Session[client][iShots],
                                t_Session[client][iHeadshots],
                                t_Session[client][iKnifeKills],
                                t_Session[client][iTaserKills],
                                t_Session[client][iGrenadeKills],
                                t_Session[client][iMolotovKills],
                                t_Session[client][iTotalDamage],
                                t_Session[client][iSurvivals],
                                t_Session[client][iPlayRounds],
                                t_Session[client][iTotalScores],
                                GetTime() - t_Session[client][iTotalOnline],
                                GetTime()
                                );
}

/*******************************************************/
/******************** Database Handle ******************/
/*******************************************************/
static void Stats_LoadClient(int client)
{
    char steamid[32];
    GetClientAuthId(client, AuthId_SteamID64, steamid, 32, true);

    char m_szQuery[128];
    FormatEx(m_szQuery, 128, "SELECT * FROM `k_minigames` WHERE `steamid` = '%s';", steamid);
    g_hMySQL.Query(LoadUserCallback, m_szQuery, GetClientUserId(client));
}

static void Stats_SaveClient(int client)
{
    if(!t_bLoaded[client])
        return;

    t_bLoaded[client] = false;

    char name[32], ename[64], m_szQuery[1024];
    GetClientName(client, name, 32);
    g_hMySQL.Escape(name, ename, 64);

    // saving data - stats
    FormatEx(m_szQuery, 1024,  "UPDATE `k_minigames` SET           \
                                   `username` = '%s',                \
                                   `kills` = `kills` + '%d',         \
                                   `deaths` = `deaths` + '%d',       \
                                   `assists` = `assists` + '%d',     \
                                   `hits` = `hits` + '%d',           \
                                   `shots` = `shots` + '%d',         \
                                   `headshots` = `headshots` + '%d', \
                                   `knife` = `knife` + '%d',         \
                                   `taser` = `taser` + '%d',         \
                                   `grenade` = `grenade` + '%d',     \
                                   `molotov` = `molotov` + '%d',     \
                                   `damage` = `damage` + '%d',       \
                                   `survivals` = `survivals` + '%d', \
                                   `rounds` = `rounds` + '%d',       \
                                   `score` = `score` + '%d',         \
                                   `online` = `online` + '%d'        \
                                WHERE `uid` = '%d';                  \
                                ",
                                ename,
                                t_Session[client][iKills],
                                t_Session[client][iDeaths],
                                t_Session[client][iAssists],
                                t_Session[client][iHits],
                                t_Session[client][iShots],
                                t_Session[client][iHeadshots],
                                t_Session[client][iKnifeKills],
                                t_Session[client][iTaserKills],
                                t_Session[client][iGrenadeKills],
                                t_Session[client][iMolotovKills],
                                t_Session[client][iTotalDamage],
                                t_Session[client][iSurvivals],
                                t_Session[client][iPlayRounds],
                                t_Session[client][iTotalScores],
                                GetTime() - t_Session[client][iTotalOnline],
                                g_iUId[client]);

    MySQL_VoidQuery(m_szQuery);
}

static void Stats_TraceClient(int killer, int assister, int victim, bool headshot, const char[] weapon);
{
    char model[192];
    GetClientModel(client, model, 192);
    
    char m_szQuery[1024];
    FormatEx(m_szQuery, 1024,  "INSERT INTO `k_minigames_k` VALUES      \
                                (                                       \
                                    DEFAULT,                            \
                                    %d,                                 \
                                    %d,                                 \
                                    %d,                                 \
                                    '%s',                               \
                                    %d,                                 \
                                    '%.3f',                             \
                                    '%s',                               \
                                    %b,                                 \
                                    '%s',                               \
                                    %d                                  \
                                )                                       \
                                ",
                                g_iUId[killer],
                                g_iUId[assister],
                                g_iUId[victim],
                                g_szMap,
                                Games_GetRoundNumber(),
                                Games_GetRoundTime(),
                                weapon,
                                headshot,
                                model,
                                GetTime()
                                );
    MySQL_VoidQuery(m_szQuery);
}

public void LoadUserCallback(Database db, DBResultSet results, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);
    if(!client)
        return;

    if(results == null || error[0])
    {
        LogError("LoadUserCallback -> %L -> %s", client, error);
        CreateTimer(1.0, Stats_ReloadClientData, userid, TIMER_FLAG_NO_MAPCHANGE);
        return;
    }
    
    if(results.RowCount == 0)
    {
        Stats_CreateClient(client);
        return;
    }

    if(!results.FetchRow())
    {
        LogError("LoadUserCallback -> %L -> Can not fetch row.", client);
        CreateTimer(1.0, Stats_ReloadClientData, userid, TIMER_FLAG_NO_MAPCHANGE);
        return;
    }
    
    g_iUId[client] = results.FetchInt(0);

    for(int i = 0; i < view_as<int>(Analytics); ++i)
        t_StatsDB[client][i] = results.FetchInt(i+3);

    t_bLoaded[client] = true;
    
    Ranks_OnClientLoaded(client);
}

public Action Stats_ReloadClientData(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if(!client)
        return Plugin_Stop;
    
    Stats_OnClientPutInServer(client);

    return Plugin_Stop;
}

static void Stats_CreateClient(int client)
{
    char steamid[32];
    GetClientAuthId(client, AuthId_SteamID64, steamid, 32, true);
    
    char m_szQuery[128];
    FormatEx(m_szQuery, 128, "INSERT INTO `k_minigames` (`uid`, `steamid`) VALUES (DEFAULT, '%s');", steamid);
    g_hMySQL.Query(CreateClientCallback, m_szQuery, GetClientUserId(client), DBPrio_High);
}

public void CreateClientCallback(Database db, DBResultSet results, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);
    if(!client)
        return;

    if(results == null || error[0])
    {
        LogError("CreateClientCallback -> %L -> %s", client, error);
        CreateTimer(1.0, Stats_ReloadClientData, userid, TIMER_FLAG_NO_MAPCHANGE);
        return;
    }
    
    if(results.AffectedRows == 0)
    {
        LogError("CreateClientCallback -> %L -> no affected rows...", client);
        CreateTimer(1.0, Stats_ReloadClientData, userid, TIMER_FLAG_NO_MAPCHANGE);
        return;
    }
    
    t_bLoaded[client] = true;

    Ranks_OnClientLoaded(client);
}

void Stats_PublicMessage(int client, bool disconnected = false)
{
    // public message
    ChatAll("%t", "public message",
            client, 
            disconnected ? "disconnect" : "join",
            Ranks_GetRank(client), 
            Stats_GetKDA(client),
            Stats_GetHSP(client),
            t_StatsDB[client][iTotalScores],
            t_StatsDB[client][iTotalOnline]/3600
           );

    // private message
    if(!disconnected)
    CreateTimer(6.88, Stats_PrivateMessage, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Stats_PrivateMessage(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if(!client || !IsClientInGame(client))
        return Plugin_Stop;

    Chat(client, "\x04*****************************************");
    Chat(client, "\x04%T", "private message line 1", client);
    Chat(client, "\x05%T", "private message line 2", client, PI_VERSION, PI_AUTHOR);
    Chat(client, "\x05%T", "private message line 3", client);
    Chat(client, "\x05%T", "private message line 4", client, PI_URL);

    return Plugin_Stop;
}

/*******************************************************/
/******************** Event to Track *******************/
/*******************************************************/
void Stats_OnClientSpawn(int client)
{
    if(!t_bEnabled)
        return;

    t_Session[client][iPlayRounds]++;
}

void Stats_OnClientDeath(int victim, int attacker, int assister, bool headshot, const char[] weapon)
{
    if(!t_bEnabled)
        return;
    
    Stats_TraceClient(attacker, assister, victim, headshot, weapon);
    
    t_Session[victim][iDeaths]++;
    
    if(assister != 0)
    {
        t_Session[assister][iAssists]++;
        t_Session[assister][iTotalScores]++;
        
        if(g_smxStore && mg_bonus_assist.IntValue > 0)
        {
            Store_SetClientCredits(assister, Store_GetClientCredits(assister)+mg_bonus_assist.IntValue, "[MiniGames] - Assist kill");
            Chat(assister, "%T", "store bonus assist", assister, victim, mg_bonus_assist.IntValue);
        }
    }
    
    if(attacker == victim || attacker == 0)
        return;
    
    t_Session[attacker][iKills]++;
    t_Session[attacker][iTotalScores]+=3;
    
    if(mp_damage_headshot_only.BoolValue)
    {
        if(IsWeaponKnife(weapon))
        {
            if(g_smxStore && mg_bonus_kill_via_knife.IntValue > 0)
            {
                Store_SetClientCredits(attacker, Store_GetClientCredits(attacker)+mg_bonus_kill_via_knife.IntValue, "[MiniGames] - Knife kill");
                Chat(attacker, "%T", "store bonus knife", attacker, victim, mg_bonus_kill_via_knife.IntValue);
            }
            t_Session[attacker][iKnifeKills]++;
        }
        else
        {
            if(g_smxStore && mg_bonus_kill_via_gun.IntValue > 0)
            {
                Store_SetClientCredits(attacker, Store_GetClientCredits(attacker)+mg_bonus_kill_via_gun.IntValue, "[MiniGames] - normal kill");
                Chat(attacker, "%T", "store bonus kill", attacker, victim, mg_bonus_kill_via_gun.IntValue);
            }
            t_Session[attacker][iHeadshots]++;
        }
        return;
    }

    if(headshot)
    {
        if(g_smxStore && mg_bonus_kill_via_gun_hs.IntValue > 0)
        {
            Store_SetClientCredits(attacker, Store_GetClientCredits(attacker)+mg_bonus_kill_via_gun_hs.IntValue, "[MiniGames] - Headshot kill");
            Chat(attacker, "%T", "store bonus headshot", attacker, victim, mg_bonus_kill_via_gun_hs.IntValue);
        }
        t_Session[attacker][iHeadshots]++;
        t_Session[attacker][iTotalScores]+=2;
        return;
    }

    if(IsWeaponKnife(weapon))
    {
        if(g_smxStore && mg_bonus_kill_via_knife.IntValue > 0)
        {
            Store_SetClientCredits(attacker, Store_GetClientCredits(attacker)+mg_bonus_kill_via_knife.IntValue, "[MiniGames] - Knife kill");
            Chat(attacker, "%T", "store bonus knife", attacker, victim, mg_bonus_kill_via_knife.IntValue);
        }
        t_Session[attacker][iKnifeKills]++;
        return;
    }
    
    if(IsWeaponDodgeBall(weapon))
    {
        if(g_smxStore && mg_bonus_kill_via_dodge.IntValue > 0)
        {
            Store_SetClientCredits(attacker, Store_GetClientCredits(attacker)+mg_bonus_kill_via_dodge.IntValue, "[MiniGames] - Dodgeball kill");
            Chat(attacker, "%T", "store bonus dodgeball", attacker, victim, mg_bonus_kill_via_dodge.IntValue);
        }
        return;
    }
    
    if(IsWeaponTaser(weapon))
    {
        if(g_smxStore && mg_bonus_kill_via_taser.IntValue > 0)
        {
            Store_SetClientCredits(attacker, Store_GetClientCredits(attacker)+mg_bonus_kill_via_taser.IntValue, "[MiniGames] - Taser kill");
            Chat(attacker, "%T", "store bonus taser", attacker, victim, mg_bonus_kill_via_taser.IntValue);
        }
        t_Session[attacker][iTaserKills]++;
        return;
    }

    if(IsWeaponInferno(weapon))
    {
        if(g_smxStore && mg_bonus_kill_via_inferno.IntValue > 0)
        {
            Store_SetClientCredits(attacker, Store_GetClientCredits(attacker)+mg_bonus_kill_via_inferno.IntValue, "[MiniGames] - Inferno kill");
            Chat(attacker, "%T", "store bonus inferno", attacker, victim, mg_bonus_kill_via_inferno.IntValue);
        }
        t_Session[attacker][iMolotovKills]++;
        return;
    }

    if(IsWeaponGrenade(weapon))
    {
        if(g_smxStore && mg_bonus_kill_via_grenade.IntValue > 0)
        {
            Store_SetClientCredits(attacker, Store_GetClientCredits(attacker)+mg_bonus_kill_via_grenade.IntValue, "[MiniGames] - Grenade kill");
            Chat(attacker, "%T", "store bonus grenade", attacker, victim, mg_bonus_kill_via_grenade.IntValue);
        }
        t_Session[attacker][iGrenadeKills]++;
        return;
    }
    
    if(g_smxStore && mg_bonus_kill_via_gun.IntValue > 0)
    {
        Store_SetClientCredits(attacker, Store_GetClientCredits(attacker)+mg_bonus_kill_via_gun.IntValue, "[MiniGames] - normal kill");
        Chat(attacker, "%T", "store bonus kill", attacker, victim, mg_bonus_kill_via_gun.IntValue);
    }
}

void Stats_PlayerHurts(int victim, int attacker, int damage, const char[] weapon)
{
    if(!t_bEnabled || victim == attacker || attacker == 0)
        return;

    t_Session[attacker][iTotalDamage] += damage;
    
    if(IsWeaponKnife(weapon) || IsWeaponInferno(weapon))
        return;

    t_Session[attacker][iHits]++;
}

void Stats_OnWeaponFire(int attacker, const char[] weapon)
{
    if(IsWeaponKnife(weapon) || IsWeaponInferno(weapon) || IsWeaponDodgeBall(weapon))
        return;

    t_Session[attacker][iShots]++;
}

void Stats_OnRoundEnd()
{
    if(!t_bEnabled)
        return;
    
    for(int client = 1; client <= MaxClients; ++client)
        if(IsClientInGame(client) && IsPlayerAlive(client))
        {
            t_Session[client][iSurvivals]++;
            if(g_smxStore && mg_bonus_survival.IntValue > 0)
            {
                Store_SetClientCredits(client, Store_GetClientCredits(client)+mg_bonus_survival.IntValue, "[MiniGames] - Survival");
                Chat(client, "%T", "store bonus survival", client, mg_bonus_survival.IntValue);
            }
        }
}

static void MySQL_VoidQuery(const char[] m_szQuery)
{
    DataPack pack = new DataPack();
    pack.WriteCell(strlen(m_szQuery)+1);
    pack.WriteString(m_szQuery);
    pack.Reset();

    g_hMySQL.Query(MySQL_VoidQueryCallback, m_szQuery, _, DBPrio_Low);
}

public void MySQL_VoidQueryCallback(Database db, DBResultSet results, const char[] error, DataPack pack)
{
    if(results == null || error[0])
    {
        int maxLen = pack.ReadCell();
        char[] m_szQuery = new char[maxLen];
        pack.ReadString(m_szQuery, maxLen);
        
        char path[256];
        BuildPath(Path_SM, path, 256, "log/MySQL_VoidQueryError.log");

        LogToFileEx(path, "----------------------------------------------------------------");
        LogToFileEx(path, "Query: %s", m_szQuery);
        LogToFileEx(path, "Error: %s", error);
    }
    delete pack;
}

/*******************************************************/
/********************** Local API **********************/
/*******************************************************/
int Stats_GetTotalScore(int client)
{
    return t_Session[client][iTotalScores] + t_StatsDB[client][iTotalScores];
}

int Stats_GetKills(int client)
{
    return t_Session[client][iKills] + t_StatsDB[client][iKills];
}

int Stats_GetAssists(int client)
{
    return t_Session[client][iAssists] + t_StatsDB[client][iAssists];
}

int Stats_GetDeaths(int client)
{
    return t_Session[client][iDeaths] + t_StatsDB[client][iDeaths];
}

float Stats_GetKDA(int client)
{
    return float(Stats_GetKills(client))/float(Stats_GetDeaths(client)+1);
}

int Stats_GetHeadShots(int client)
{
    return t_Session[client][iHeadshots] + t_StatsDB[client][iHeadshots];
}

int Stats_GetKnifeKills(int client)
{
    return t_Session[client][iKnifeKills] + t_StatsDB[client][iKnifeKills];
}

int Stats_GetTaserKills(int client)
{
    return t_Session[client][iTaserKills] + t_StatsDB[client][iTaserKills];
}

float Stats_GetHSP(int client)
{
    int totalKill = Stats_GetKills(client) - Stats_GetKnifeKills(client) - Stats_GetTaserKills(client);
    return (Stats_GetHeadShots(client) > 0 && totalKill > 0) ? float(Stats_GetHeadShots(client) * 100) / float(totalKill) : 0.0;
}