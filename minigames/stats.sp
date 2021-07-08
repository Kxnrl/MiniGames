/******************************************************************/
/*                                                                */
/*                         MiniGames Core                         */
/*                                                                */
/*                                                                */
/*  File:          stats.sp                                       */
/*  Description:   MiniGames Game Mod.                            */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2021  Kyle                                      */
/*  2018/03/05 16:51:01                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/


static stats_t t_Session[MAXPLAYERS+1];
static stats_t t_StatsDB[MAXPLAYERS+1];

static bool t_Spawned[MAXPLAYERS+1];
static bool t_bLoaded[MAXPLAYERS+1];
static bool t_bEnabled = false;
static  int t_iRoundCredits[MAXPLAYERS+1];


void Stats_OnPluginStart()
{
    RegConsoleCmd("sm_stats", Command_Stats);
}

public Action Command_Stats(int client, int args)
{
    if (!client)
        return Plugin_Handled;

    if (!t_bLoaded[client])
    {
        Chat(client, "%T", "stats loading", client);
        return Plugin_Handled;
    }

    char username[32];
    GetClientName(client, username, 32);

    stats_t pack;
    pack.m_iKills        = t_Session[client].m_iKills        + t_StatsDB[client].m_iKills;
    pack.m_iDeaths       = t_Session[client].m_iDeaths       + t_StatsDB[client].m_iDeaths;
    pack.m_iAssists      = t_Session[client].m_iAssists      + t_StatsDB[client].m_iAssists;
    pack.m_iHits         = t_Session[client].m_iHits         + t_StatsDB[client].m_iHits;
    pack.m_iShots        = t_Session[client].m_iShots        + t_StatsDB[client].m_iShots;
    pack.m_iHeadshots    = t_Session[client].m_iHeadshots    + t_StatsDB[client].m_iHeadshots;
    pack.m_iKnifeKills   = t_Session[client].m_iKnifeKills   + t_StatsDB[client].m_iKnifeKills;
    pack.m_iTaserKills   = t_Session[client].m_iTaserKills   + t_StatsDB[client].m_iTaserKills;
    pack.m_iGrenadeKills = t_Session[client].m_iGrenadeKills + t_StatsDB[client].m_iGrenadeKills;
    pack.m_iMolotovKills = t_Session[client].m_iMolotovKills + t_StatsDB[client].m_iMolotovKills;
    pack.m_iTotalDamage  = t_Session[client].m_iTotalDamage  + t_StatsDB[client].m_iTotalDamage;
    pack.m_iSurvivals    = t_Session[client].m_iSurvivals    + t_StatsDB[client].m_iSurvivals;
    pack.m_iPlayRounds   = t_Session[client].m_iPlayRounds   + t_StatsDB[client].m_iPlayRounds;
    pack.m_iTotalScores  = t_Session[client].m_iTotalScores  + t_StatsDB[client].m_iTotalScores;

    // fixes
    pack.m_iTotalOnline  = GetTime() - t_Session[client].m_iTotalOnline + t_StatsDB[client].m_iTotalOnline;

    DisplayRankDetails(client, username, pack);

    return Plugin_Handled;
}

void Stats_OnPluginEnd()
{
    for(int client = 1; client <= MaxClients; ++ client)
        if (ClientValid(client))
            Stats_OnClientDisconnect(client);
}

void Stats_OnWinPanel()
{
    for(int client = 1; client <= MaxClients; ++ client)
        if (ClientValid(client))
            Stats_SaveClient(client);
}

void Stats_OnMapStart()
{
    // disallow tracking
    t_bEnabled = false;
}

void Stats_OnClientConnected(int client)
{
    // init client

    t_Session[client].Reset();
    t_StatsDB[client].Reset();

    t_bLoaded[client] = false;
    t_Spawned[client] = false;

    t_Session[client].m_iTotalOnline = GetTime();
}

void Stats_OnClientPostAdminCheck(int client)
{
    // ignore bot and gotv
    if (IsFakeClient(client) || IsClientSourceTV(client))
        return;

    // load client data
    Stats_LoadClient(client);
}

void Stats_OnClientDisconnect(int client)
{
    if (!IsClientInGame(client))
        return;

    if (mg_broadcast_leave.BoolValue)
    {
        // disconnect message
        Stats_PublicMessage(client, true);
    }
    
    Stats_SaveClient(client);
}

/*******************************************************/
/******************** Database Handle ******************/
/*******************************************************/
static void Stats_LoadClient(int client)
{
    char steamid[32];
    if (!GetClientAuthId(client, AuthId_SteamID64, steamid, 32, true))
    {
        LogError("Failed to get steamid for %L", client);
        return;
    }

    char m_szQuery[128];
    FormatEx(m_szQuery, 128, "SELECT * FROM `k_minigames` WHERE `steamid` = '%s';", steamid);
    g_hMySQL.Query(LoadUserCallback, m_szQuery, GetClientUserId(client));
}

static void Stats_SaveClient(int client)
{
    if (!t_bLoaded[client])
        return;

    t_bLoaded[client] = false;

    if (t_Session[client].m_iTotalOnline < 123456789)
    {
        LogError("WTF? somthing went wrong. :(");
        return;
    }

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
                                t_Session[client].m_iKills,
                                t_Session[client].m_iDeaths,
                                t_Session[client].m_iAssists,
                                t_Session[client].m_iHits,
                                t_Session[client].m_iShots,
                                t_Session[client].m_iHeadshots,
                                t_Session[client].m_iKnifeKills,
                                t_Session[client].m_iTaserKills,
                                t_Session[client].m_iGrenadeKills,
                                t_Session[client].m_iMolotovKills,
                                t_Session[client].m_iTotalDamage,
                                t_Session[client].m_iSurvivals,
                                t_Session[client].m_iPlayRounds,
                                t_Session[client].m_iTotalScores,
                                GetTime() - t_Session[client].m_iTotalOnline,
                                g_iUId[client]);
    MySQL_VoidQuery(m_szQuery);

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
                                )                                       \
                                ",
                                g_iUId[client],
                                g_szTicket[client],
                                g_szMap,
                                t_Session[client].m_iKills,
                                t_Session[client].m_iDeaths,
                                t_Session[client].m_iAssists,
                                t_Session[client].m_iHits,
                                t_Session[client].m_iShots,
                                t_Session[client].m_iHeadshots,
                                t_Session[client].m_iKnifeKills,
                                t_Session[client].m_iTaserKills,
                                t_Session[client].m_iGrenadeKills,
                                t_Session[client].m_iMolotovKills,
                                t_Session[client].m_iTotalDamage,
                                t_Session[client].m_iSurvivals,
                                t_Session[client].m_iPlayRounds,
                                t_Session[client].m_iTotalScores,
                                GetTime() - t_Session[client].m_iTotalOnline,
                                GetTime());
    MySQL_VoidQuery(m_szQuery);
}

static void Stats_TraceClient(int killer, int assister, int victim, bool headshot, const char[] weapon)
{
    char model[192];
    GetClientModel(victim, model, 192);

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
                                GetTime());
    MySQL_VoidQuery(m_szQuery);
}

public void LoadUserCallback(Database db, DBResultSet results, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);
    if (!client)
        return;

    if (results == null || error[0])
    {
        LogError("LoadUserCallback -> %L -> %s", client, error);
        CreateTimer(1.0, Stats_ReloadClientData, userid, TIMER_FLAG_NO_MAPCHANGE);
        return;
    }

    if (results.RowCount == 0)
    {
        Stats_CreateClient(client);
        return;
    }

    if (!results.FetchRow())
    {
        LogError("LoadUserCallback -> %L -> Can not fetch row.", client);
        CreateTimer(1.0, Stats_ReloadClientData, userid, TIMER_FLAG_NO_MAPCHANGE);
        return;
    }

    g_iUId[client] = results.FetchInt(0);

    t_StatsDB[client].m_iKills         = results.FetchInt( 3);
    t_StatsDB[client].m_iDeaths        = results.FetchInt( 4);
    t_StatsDB[client].m_iAssists       = results.FetchInt( 5);
    t_StatsDB[client].m_iHits          = results.FetchInt( 6);
    t_StatsDB[client].m_iShots         = results.FetchInt( 7);
    t_StatsDB[client].m_iHeadshots     = results.FetchInt( 8);
    t_StatsDB[client].m_iKnifeKills    = results.FetchInt( 9);
    t_StatsDB[client].m_iTaserKills    = results.FetchInt(10);
    t_StatsDB[client].m_iGrenadeKills  = results.FetchInt(11);
    t_StatsDB[client].m_iMolotovKills  = results.FetchInt(12);
    t_StatsDB[client].m_iTotalDamage   = results.FetchInt(13);
    t_StatsDB[client].m_iSurvivals     = results.FetchInt(14);
    t_StatsDB[client].m_iPlayRounds    = results.FetchInt(15);
    t_StatsDB[client].m_iTotalScores   = results.FetchInt(16);
    t_StatsDB[client].m_iTotalOnline   = results.FetchInt(17);

    t_bLoaded[client] = true;

    Ranks_OnClientLoaded(client);
}

public Action Stats_ReloadClientData(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (!client)
        return Plugin_Stop;

    Stats_OnClientPostAdminCheck(client);

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
    if (!client)
        return;

    if (results == null || error[0])
    {
        LogError("CreateClientCallback -> %L -> %s", client, error);
        CreateTimer(1.0, Stats_ReloadClientData, userid, TIMER_FLAG_NO_MAPCHANGE);
        return;
    }

    if (results.AffectedRows == 0)
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
    if (!disconnected)
    {
        // private message
        CreateTimer(6.88, Stats_PrivateMessage, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    }

    // skip admin print
    if (CheckCommandAccess(client, "sm_sh", ADMFLAG_ROOT, false))
        return;

    if (g_extGeoIP2)
    {
        char ip[16];
        GetClientIP(client, ip, 16, true);

        char lang[8];
        mg_geoiplanguage.GetString(lang, 8);

        char geo[2][16];
        GeoIP2_City   (ip, geo[1], 32, lang);
        GeoIP2_Country(ip, geo[0], 32, lang);

        // public message with geoip
        ChatAll("%t", "public message with geoip",
                client, 
                disconnected ? "disconnect" : "join",
                Ranks_GetRank(client), 
                Stats_GetKDA(client),
                Stats_GetHSP(client),
                t_StatsDB[client].m_iTotalScores,
                t_StatsDB[client].m_iTotalOnline/3600,
                geo[0],
                geo[1]
                );
    }
    else
    {
        // public message
        ChatAll("%t", "public message",
                client, 
                disconnected ? "disconnect" : "join",
                Ranks_GetRank(client), 
                Stats_GetKDA(client),
                Stats_GetHSP(client),
                t_StatsDB[client].m_iTotalScores,
                t_StatsDB[client].m_iTotalOnline/3600
                );
    }
}

public Action Stats_PrivateMessage(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (!ClientValid(client))
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
void Stats_OnRoundStart()
{
    // once check players
    t_bEnabled = (GetClientCount(true) >= 6 && !IsWarmup());

    for (int i = 1; i <= MaxClients; i++)
    {
        // mark client as not spawn...
        // for some maps, auto-respawn is enabled...
        t_Spawned[i] = false;
    }
}

void Stats_OnClientSpawn(int client)
{
    if (!t_bEnabled)
        return;

    // already spawn in this round...
    if (t_Spawned[client])
        return;

    t_Spawned[client] = true;

    t_Session[client].m_iPlayRounds++;
    t_iRoundCredits[client] = 0;
}

void Stats_OnClientDeath(int victim, int attacker, int assister, bool headshot, const char[] weapon)
{
    if (!t_bEnabled)
        return;

    Stats_TraceClient(attacker, assister, victim, headshot, weapon);

    t_Session[victim].m_iDeaths++;

    if (assister != 0)
    {
        t_Session[assister].m_iAssists++;
        t_Session[assister].m_iTotalScores++;

        GiveCredits(assister, mg_bonus_assist.IntValue, "[MiniGames] - Assist kill", "%T", "store bonus assist", assister, victim, mg_bonus_assist.IntValue);
    }

    if (attacker == victim || attacker == 0)
        return;

    t_Session[attacker].m_iKills++;
    t_Session[attacker].m_iTotalScores+=3;

    if (mp_damage_headshot_only.BoolValue)
    {
        if (IsWeaponKnife(weapon))
        {
            t_Session[attacker].m_iKnifeKills++;
            GiveCredits(attacker, mg_bonus_kill_via_knife.IntValue, "[MiniGames] - Knife kill", "%T", "store bonus knife", attacker, victim, mg_bonus_kill_via_knife.IntValue);
        }
        else
        {
            t_Session[attacker].m_iHeadshots++;
            GiveCredits(attacker, mg_bonus_kill_via_gun.IntValue, "[MiniGames] - normal kill", "%T", "store bonus kill", attacker, victim, mg_bonus_kill_via_gun.IntValue);
        }
        return;
    }

    if (headshot)
    {
        t_Session[attacker].m_iHeadshots++;
        t_Session[attacker].m_iTotalScores+=2;
        GiveCredits(attacker, mg_bonus_kill_via_gun_hs.IntValue, "[MiniGames] - Headshot kill", "%T", "store bonus headshot", attacker, victim, mg_bonus_kill_via_gun_hs.IntValue);
        return;
    }

    if (IsWeaponKnife(weapon))
    {
        t_Session[attacker].m_iKnifeKills++;
        GiveCredits(attacker, mg_bonus_kill_via_knife.IntValue, "[MiniGames] - Knife kill", "%T", "store bonus knife", attacker, victim, mg_bonus_kill_via_knife.IntValue);
        return;
    }

    if (IsWeaponDodgeBall(weapon))
    {
        GiveCredits(attacker, mg_bonus_kill_via_dodge.IntValue, "[MiniGames] - Dodgeball kill", "%T", "store bonus dodgeball", attacker, victim, mg_bonus_kill_via_dodge.IntValue);
        return;
    }

    if (IsWeaponTaser(weapon))
    {
        t_Session[attacker].m_iTaserKills++;
        GiveCredits(attacker, mg_bonus_kill_via_taser.IntValue, "[MiniGames] - Taser kill", "%T", "store bonus taser", attacker, victim, mg_bonus_kill_via_taser.IntValue);
        return;
    }

    if (IsWeaponInferno(weapon))
    {
        t_Session[attacker].m_iMolotovKills++;
        GiveCredits(attacker, mg_bonus_kill_via_inferno.IntValue, "[MiniGames] - Inferno kill", "%T", "store bonus inferno", attacker, victim, mg_bonus_kill_via_inferno.IntValue);
        return;
    }

    if (IsWeaponGrenade(weapon))
    {
        t_Session[attacker].m_iGrenadeKills++;
        GiveCredits(attacker, mg_bonus_kill_via_grenade.IntValue, "[MiniGames] - Grenade kill", "%T", "store bonus grenade", attacker, victim, mg_bonus_kill_via_grenade.IntValue);
        return;
    }

    GiveCredits(attacker, mg_bonus_kill_via_gun.IntValue, "[MiniGames] - normal kill", "%T", "store bonus kill", attacker, victim, mg_bonus_kill_via_gun.IntValue);
}

void Stats_PlayerHurts(int victim, int attacker, int damage, const char[] weapon)
{
    if (!t_bEnabled || victim == attacker || attacker == 0)
        return;

    t_Session[attacker].m_iTotalDamage += damage;

    if (IsWeaponKnife(weapon) || IsWeaponInferno(weapon))
        return;

    t_Session[attacker].m_iHits++;
}

void Stats_OnWeaponFire(int attacker, const char[] weapon)
{
    if (IsWeaponKnife(weapon) || IsWeaponInferno(weapon) || IsWeaponDodgeBall(weapon))
        return;

    t_Session[attacker].m_iShots++;
}

void Stats_OnRoundEnd()
{
    RequestFrame(Stats_RoundEndDelayed);
}

void Stats_RoundEndDelayed()
{
    if (!t_bEnabled)
        return;

    for(int client = 1; client <= MaxClients; ++client)
        if (ClientValid(client) && IsPlayerAlive(client))
        {
            t_Session[client].m_iSurvivals++;
            if (g_smxStore && mg_bonus_survival.IntValue > 0 && g_GamePlayers >= mg_bonus_requires_players.IntValue)
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
    if (results == null || error[0])
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

static void GiveCredits(int client, int credits, const char[] reason, const char[] chat, any ...)
{
    if (!g_smxStore || g_GamePlayers < mg_bonus_requires_players.IntValue || credits <= 0 || t_iRoundCredits[client] >= mg_bonus_max_round_credits.IntValue)
        return;

    t_iRoundCredits[client] += credits;
    Store_SetClientCredits(client, Store_GetClientCredits(client)+credits, reason);

    char message[256];
    VFormat(message, 256, chat, 5);
    Chat(client, message);
}

/*******************************************************/
/********************** Local API **********************/
/*******************************************************/
int Stats_GetTotalScore(int client)
{
    return t_Session[client].m_iTotalScores + t_StatsDB[client].m_iTotalScores;
}

int Stats_GetKills(int client)
{
    return t_Session[client].m_iKills + t_StatsDB[client].m_iKills;
}

int Stats_GetAssists(int client)
{
    return t_Session[client].m_iAssists + t_StatsDB[client].m_iAssists;
}

int Stats_GetDeaths(int client)
{
    return t_Session[client].m_iDeaths + t_StatsDB[client].m_iDeaths;
}

float Stats_GetKDA(int client)
{
    return float(Stats_GetKills(client))/float(Stats_GetDeaths(client)+1);
}

int Stats_GetHeadShots(int client)
{
    return t_Session[client].m_iHeadshots + t_StatsDB[client].m_iHeadshots;
}

int Stats_GetKnifeKills(int client)
{
    return t_Session[client].m_iKnifeKills + t_StatsDB[client].m_iKnifeKills;
}

int Stats_GetTaserKills(int client)
{
    return t_Session[client].m_iTaserKills + t_StatsDB[client].m_iTaserKills;
}

float Stats_GetHSP(int client)
{
    int totalKill = Stats_GetKills(client) - Stats_GetKnifeKills(client) - Stats_GetTaserKills(client);
    return (Stats_GetHeadShots(client) > 0 && totalKill > 0) ? float(Stats_GetHeadShots(client) * 100) / float(totalKill) : 0.0;
}
