/******************************************************************/
/*                                                                */
/*                         MiniGames Core                         */
/*                                                                */
/*                                                                */
/*  File:          ranks.sp                                       */
/*  Description:   MiniGames Game Mod.                            */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2020  Kyle                                      */
/*  2018/03/05 16:51:01                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/


static ArrayList t_aRankCache = null;
static Menu t_RankMenu = null;
static int t_iCompLevel[MAXPLAYERS+1];
static int t_iRank[MAXPLAYERS+1];


void Ranks_OnPluginStart()
{
    // arraylist to store rank list
    t_aRankCache = new ArrayList(ByteCountToCells(32));

    RegConsoleCmd("sm_top",  Command_Rank);
    RegConsoleCmd("sm_rank", Command_Rank);

    // we using timer to dump cache.
    CreateTimer(1200.0, Timer_RefreshRank, _, TIMER_REPEAT);
}

public Action Timer_RefreshRank(Handle timer)
{
    Ranks_BuildRankCache();
    return Plugin_Stop;
}

void Ranks_OnDBConnected()
{
    Ranks_BuildRankCache();
}

static void Ranks_BuildRankCache()
{
    PrintToServer("Building Rank Cache ...");
    g_hMySQL.Query(RankCacheCallback, "SELECT `uid`,`username`,`kills`,`deaths`,`score` FROM `k_minigames` WHERE `score` >= 0 ORDER BY `score` DESC;");
}

public void RankCacheCallback(Database db, DBResultSet results, const char[] error, any data)
{
    if (results == null || error[0])
    {
        LogError("RankCacheCallback -> SQL Error: %s", error);
        return;
    }

    // has row?
    if (results.RowCount > 0)
    {
        t_aRankCache.Clear();
        t_aRankCache.PushString("This is First Line in Array"); // array index start from 0.

        if (t_RankMenu != null)
            delete t_RankMenu;

        // rank menu.
        t_RankMenu = new Menu(MenuHandler_RankingTop);
        t_RankMenu.SetTitle("undef title");
        t_RankMenu.ExitButton = false;
        t_RankMenu.ExitBackButton = true;

        // process data
        char name[64], pidstr[16], buffer[128];
        int index, iKill, iDeath, iScore;
        while(results.FetchRow())
        {
            index++;
            int pid = results.FetchInt(0);
            results.FetchString(1, name, 64);
            Ranks_FilterName(name, 64);
            t_aRankCache.Push(pid);

            if (index > 100)
                continue;

            iKill = results.FetchInt(2);
            iDeath = results.FetchInt(3);
            iScore = results.FetchInt(4);
            float KD = (float(iKill) / float(iDeath+1));

            IntToString(pid, pidstr, 16);
            FormatEx(buffer, 128, " #%02d  %s  [K/D: %.2f (%dp)]", index, name, KD, iScore);
            t_RankMenu.AddItem(pidstr, buffer);
        }
    }
}

public int MenuHandler_RankingTop(Menu menu, MenuAction action, int param1, int param2)
{
    // loading details
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param2, info, 32);
        char m_szQuery[128];
        FormatEx(m_szQuery, 128, "SELECT * FROM `k_minigames` WHERE uid = '%d';", StringToInt(info));
        g_hMySQL.Query(RankDetailsCallback, m_szQuery, GetClientUserId(param1));
    }
    else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
        Command_Main(param1, param2);
}

public void RankDetailsCallback(Database db, DBResultSet results, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);
    if (!client)
        return;

    if (results == null || error[0])
    {
        LogError("RankDetailsCallback -> %L -> %s", client, error);
        Chat(client, "%T \x07Code:0x6B", "failed to load rank detail", client);
        Command_Rank(client, 0);
        return;
    }

    if (results.RowCount == 0 || !results.FetchRow())
    {
        Chat(client, "%T \x07Code:0x6A", "failed to load rank detail", client);
        Command_Rank(client, 0);
        return;
    }

    // using datapack instead of array
    stats_t pack;
    pack.m_iKills         = results.FetchInt( 3);
    pack.m_iDeaths        = results.FetchInt( 4);
    pack.m_iAssists       = results.FetchInt( 5);
    pack.m_iHits          = results.FetchInt( 6);
    pack.m_iShots         = results.FetchInt( 7);
    pack.m_iHeadshots     = results.FetchInt( 8);
    pack.m_iKnifeKills    = results.FetchInt( 9);
    pack.m_iTaserKills    = results.FetchInt(10);
    pack.m_iGrenadeKills  = results.FetchInt(11);
    pack.m_iMolotovKills  = results.FetchInt(12);
    pack.m_iTotalDamage   = results.FetchInt(13);
    pack.m_iSurvivals     = results.FetchInt(14);
    pack.m_iPlayRounds    = results.FetchInt(15);
    pack.m_iTotalScores   = results.FetchInt(16);
    pack.m_iTotalOnline   = results.FetchInt(17);

    char username[32];
    results.FetchString(1, username, 32);

    DisplayRankDetails(client, username, pack);
}

void DisplayRankDetails(int client, const char[] username, stats_t data)
{
    char buffer[128];

    // using panel instead of menu
    Panel panel = new Panel();

    FormatEx(buffer, 128, "▽ %T ▽", "ranking title", client);
    panel.SetTitle(buffer);

    panel.DrawText("    ");
    panel.DrawText(username);
    panel.DrawText("    ");

    FormatEx(buffer, 128, "%T", "ranking line 1", client, data.m_iKills, data.m_iDeaths, data.m_iAssists);                                                                                                                                             panel.DrawText(buffer);
    FormatEx(buffer, 128, "%T", "ranking line 2", client, data.m_iShots, data.m_iHits, data.m_iHeadshots, data.m_iTotalDamage);                                                                                                                         panel.DrawText(buffer);
    FormatEx(buffer, 128, "%T", "ranking line 3", client, float(data.m_iKills)/float(data.m_iDeaths+1), float(data.m_iHeadshots * 100)/float(data.m_iKills - data.m_iKnifeKills - data.m_iTaserKills +1), float(data.m_iHits)/float(data.m_iShots+1));      panel.DrawText(buffer);
    FormatEx(buffer, 128, "%T", "ranking line 4", client, data.m_iKnifeKills, data.m_iTaserKills, data.m_iGrenadeKills, data.m_iMolotovKills);                                                                                                          panel.DrawText(buffer);
    FormatEx(buffer, 128, "%T", "ranking line 5", client, data.m_iPlayRounds, data.m_iSurvivals);                                                                                                                                                     panel.DrawText(buffer);
    FormatEx(buffer, 128, "%T", "ranking line 6", client, data.m_iTotalScores, data.m_iTotalOnline / 3600);                                                                                                                                           panel.DrawText(buffer);

    panel.DrawText("    ");
    panel.DrawText("    ");
    panel.DrawText("    ");

    FormatEx(buffer, 128, "%T", "back", client); panel.DrawItem(buffer);
    FormatEx(buffer, 128, "%T", "exit", client); panel.DrawItem(buffer);

    // display 
    panel.Send(client, MenuHandler_RankDetails, 15);
}

public int MenuHandler_RankDetails(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_End)
        delete menu;
    else if (action == MenuAction_Select && param2 == 0)
    {
        t_RankMenu.SetTitle("%T\n ", "top 100 title", param1);
        t_RankMenu.Display(param1, 60);
    }
}

public Action Command_Rank(int client, int args)
{
    if (!client)
        return Plugin_Handled;

    Chat(client, "%T", "chat type stats", client);

    if (t_RankMenu == null)
    {
        Chat(client, "%T", "ranking unavailable", client);
        return Plugin_Handled;
    }

    t_RankMenu.SetTitle("%T\n ", "top 100 title", client);
    t_RankMenu.Display(client, 60);

    return Plugin_Handled;
}

void Ranks_OnMapStart()
{
    // hook scoreboard
    HookScoreboard(true);
}

void Ranks_OnMapEnd()
{
    // unhook scoreboard
    HookScoreboard(false);
}

void Ranks_OnClientConnected(int client)
{
    t_iCompLevel[client] = 0;
    t_iRank[client]      = 0;
}

void Ranks_OnClientDisconnect(int client)
{
    t_iCompLevel[client] = 0;
    t_iRank[client]      = 0;
}

void Ranks_OnPlayerRunCmd(int client, int buttons)
{
    // process competitive ranking

    static bool bLast[MAXPLAYERS+1];

    if (!(buttons & IN_SCORE))
    {
        bLast[client] = false;
        return;
    }

    if (bLast[client])
        return;

    bLast[client] = true;

    if (StartMessageOne("ServerRankRevealAll", client) != null)
        EndMessage();
}

void Ranks_OnClientLoaded(int client)
{
    // loading rank
    g_iTeam[client] = GetClientTeam(client);

    int rank = t_aRankCache.FindValue(g_iUId[client]);
    if (rank == -1)
        t_iRank[client] = t_aRankCache.Length + 1;
    else
        t_iRank[client] = rank;

    int score = Stats_GetTotalScore(client);

    if (score >= 204800)
        t_iCompLevel[client] = 18;
    else if (score >= 153600)
        t_iCompLevel[client] = 17;
    else if (score >= 120000)
        t_iCompLevel[client] = 16;
    else if (score >= 86400)
        t_iCompLevel[client] = 15;
    else if (score >= 64800)
        t_iCompLevel[client] = 14;
    else if (score >= 51200)
        t_iCompLevel[client] = 13;
    else if (score >= 38400)
        t_iCompLevel[client] = 12;
    else if (score >= 25600)
        t_iCompLevel[client] = 11;
    else if (score >= 12800)
        t_iCompLevel[client] = 10;
    else if (score >= 6400)
        t_iCompLevel[client] = 9;
    else if (score >= 3200)
        t_iCompLevel[client] = 8;
    else if (score >= 1600)
        t_iCompLevel[client] = 7;
    else if (score >= 800)
        t_iCompLevel[client] = 6;
    else if (score >= 400)
        t_iCompLevel[client] = 5;
    else if (score >= 200)
        t_iCompLevel[client] = 4;
    else if (score >= 100)
        t_iCompLevel[client] = 3;
    else if (score >= 50)
        t_iCompLevel[client] = 2;
    else if (score >= 25)
        t_iCompLevel[client] = 1;

    Stats_PublicMessage(client);
}

int Ranks_GetRank(int client)
{
    return t_iRank[client];
}

int Ranks_GetLevel(int client)
{
    return t_iCompLevel[client];
}

void HookScoreboard(bool hook)
{
    static int  cs_player_manager = -1;
    static bool bHook = false;
    cs_player_manager = GetPlayerResourceEntity();
    if (hook)
    {
        if (cs_player_manager == -1)
        {
            LogError("HookScoreboard -> %b -> cs_player_manager is not valid.");
            return;
        }

        bHook = SDKHookEx(cs_player_manager, SDKHook_ThinkPost, Hook_OnThinkPost);

        if (!bHook)
            LogError("HookScoreboard -> Hook cs_player_manager failed!");
    }
    else
    {
        if (cs_player_manager == -1)
        {
            LogError("HookScoreboard -> %b -> cs_player_manager is not valid.");
            return;
        }

        if (bHook)
        {
            SDKUnhook(cs_player_manager, SDKHook_ThinkPost, Hook_OnThinkPost);
            cs_player_manager = -1;
        }
    }
}

public void Hook_OnThinkPost(int entity)
{
    if (!mg_rank_skillgroups.BoolValue)
        return;

    static int Offset = -1;
    if (Offset == -1)
        Offset  = FindSendPropInfo("CCSPlayerResource", "m_iCompetitiveRanking");

    SetEntDataArray(entity, Offset, t_iCompLevel, MAXPLAYERS+1, _, true);
}

static void Ranks_FilterName(char[] buffer, int maxLen)
{
    ReplaceString(buffer, maxLen, "#", "＃");
    ReplaceString(buffer, maxLen, "\\", "＼");
    ReplaceString(buffer, maxLen, "/", "／");
    ReplaceString(buffer, maxLen, "     ", " ");
    ReplaceString(buffer, maxLen, "    ", " ");
    ReplaceString(buffer, maxLen, "   ", " ");
    ReplaceString(buffer, maxLen, "  ", " ");

    if (strlen(buffer) > 32)
        buffer[32] = '\0';
}
