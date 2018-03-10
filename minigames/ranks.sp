/******************************************************************/
/*                                                                */
/*                         MiniGames Core                         */
/*                                                                */
/*                                                                */
/*  File:          ranks.sp                                       */
/*  Description:   MiniGames Game Mod.                            */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2018  Kyle                                      */
/*  2018/03/05 16:51:01                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/


static ArrayList t_aRankCache = null;
static Menu t_RankMenu = null;
static int t_iCompLevel[MAXPLAYERS+1];
static int t_iRank[MAXPLAYERS+1];
static int cs_player_manager = -1;


void Ranks_OnPluginStart()
{
    t_aRankCache = new ArrayList(ByteCountToCells(32));
    
    RegConsoleCmd("sm_top",  Command_Rank);
    RegConsoleCmd("sm_rank", Command_Rank);

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
    g_hMySQL.Query(RankCacheCallback, "SELECT `uid`,`username`,`kills`,`deaths`,`score` FROM `dxg_minigames` WHERE `score` >= 0 ORDER BY `score` DESC;");
}

public void RankCacheCallback(Database db, DBResultSet results, const char[] error, any data)
{
    if(results == null || error[0])
    {
        LogError("RankCacheCallback -> SQL Error: %s", error);
        return;
    }

    if(results.RowCount > 0)
    {
        t_aRankCache.Clear();
        t_aRankCache.PushString("This is First Line in Array");

        if(t_RankMenu != null)
            delete t_RankMenu;

        t_RankMenu = new Menu(MenuHandler_RankingTop);
        t_RankMenu.SetTitle("[MG] Top - 100\n ");

        char name[32], pidstr[16], buffer[128];
        int index, iKill, iDeath, iScore;
        while(results.FetchRow())
        {
            index++;
            int pid = results.FetchInt(0);
            results.FetchString(1, name, 32);
            t_aRankCache.Push(pid);

            if(index > 100)
                continue;

            iKill = results.FetchInt(2);
            iDeath = results.FetchInt(3);
            iScore = results.FetchInt(4);
            float KD = (float(iKill) / float(iDeath+1));

            IntToString(pid, pidstr, 16);
            FormatEx(buffer, 128, "#%d - %s [K/D%.2f 得分%d]", index, name, KD, iScore);
            t_RankMenu.AddItem(pidstr, buffer);
        }
    }
}

public int MenuHandler_RankingTop(Menu menu, MenuAction action, int param1, int param2)
{
    if(action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param2, info, 32);
        char m_szQuery[128];
        FormatEx(m_szQuery, 128, "SELECT * FROM dxg_minigames WHERE uid = '%d';", StringToInt(info));
        g_hMySQL.Query(RankDetailsCallback, m_szQuery, GetClientUserId(param1));
    }
}

public void RankDetailsCallback(Database db, DBResultSet results, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);
    if(!client)
        return;
    
    if(results == null || error[0])
    {
        LogError("RankDetailsCallback -> %L -> %s", client, error);
        Chat(client, "加载排行榜发生异常错误 \x07Code:000");
        Command_Rank(client, 0);
        return;
    }
    
    if(results.RowCount == 0 || !results.FetchRow())
    {
        Chat(client, "加载排行榜发生异常错误 \x07Code:001");
        Command_Rank(client, 0);
        return;
    }
    
    DataPack pack = new DataPack();
    for(int i = 0; i < view_as<int>(Analytics); ++i)
        pack.WriteCell(results.FetchInt(i+2));

    char username[32];
    results.FetchString(1, username, 32);
    
    DisplayRankDetails(client, username, pack);
}

void DisplayRankDetails(int client, const char[] username, DataPack pack)
{
    pack.Reset();
    
    any data[Analytics];
    for(int i = 0; i < view_as<int>(Analytics); ++i)
        data[i] = pack.ReadCell();
    
    delete pack;

    char buffer[128];

    Panel panel = new Panel();
    
    panel.SetTitle("▽ Ranking ▽");
    panel.DrawText("    ");
    panel.DrawText(username);
    panel.DrawText("    ");

    FormatEx(buffer, 128, "杀敌: %d  |  死亡: %d  |  助攻: %d", data[iKills], data[iDeaths], data[iAssists]);panel.DrawText(buffer);
    FormatEx(buffer, 128, "开火: %d  |  命中: %d  |  爆头: %d  |  总伤害: %d", data[iShots], data[iHits], data[iHeadshots], data[iTotalDamage]);panel.DrawText(buffer);
    FormatEx(buffer, 128, "杀亡比: %.2f  |  爆头率: %.2f%%  |  命中率: %.2f%%", float(data[iKills])/float(data[iDeaths]+1), float(data[iHeadshots] * 100)/float(data[iKills] - data[iKnifeKills] - data[iTaserKills]), float(data[iHits])/float(data[iShots]+1));panel.DrawText(buffer);
    FormatEx(buffer, 128, "刀杀: %d  |  电死: %d  |  雷杀: %d  |  烧死: %d", data[iKnifeKills], data[iTaserKills], data[iGrenadeKills], data[iMolotovKills]);panel.DrawText(buffer);
    FormatEx(buffer, 128, "回合: %d  |  存活: %d  ", data[iPlayRounds], data[iSurvivals]);panel.DrawText(buffer);
    FormatEx(buffer, 128, "得分: %d  |  在线: %d小时  ", data[iTotalScores], data[iTotalOnline] / 3600);panel.DrawText(buffer);
    panel.DrawText("    ");
    panel.DrawText("    ");
    panel.DrawText("    ");
    panel.DrawItem("返回");
    panel.DrawItem("退出");
    panel.Send(client, MenuHandler_RankDetails, 15);
}

public int MenuHandler_RankDetails(Menu menu, MenuAction action, int param1, int param2)
{
    if(action == MenuAction_End)
        delete menu;
    else if(action == MenuAction_Select && param2 == 0)
        t_RankMenu.Display(param1, 60);
}

public Action Command_Rank(int client, int args)
{
    if(!client || t_RankMenu == null)
        return Plugin_Handled;
    
    Chat(client, "要查看自己的统计数据,请输入\x04!stats");

    t_RankMenu.Display(client, 60);
    
    return Plugin_Handled;
}

void Ranks_OnMapStart()
{
    cs_player_manager = FindEntityByClassname(MaxClients+1, "cs_player_manager");
    if(cs_player_manager != -1)
        if(!SDKHookEx(cs_player_manager, SDKHook_ThinkPost, Hook_OnThinkPost))
            LogMessage("Ranks_OnMapStart -> Hook cs_player_manager failed!");
}

public void Hook_OnThinkPost(int entity)
{
    static int Offset = -1;
    if(Offset == -1)
        Offset = FindSendPropInfo("CCSPlayerResource", "m_iCompetitiveRanking");

    SetEntDataArray(entity, Offset, t_iCompLevel, MAXPLAYERS+1, _, true);
}

void Ranks_OnMapEnd()
{
    if(cs_player_manager != -1)
    {
        SDKUnhook(cs_player_manager, SDKHook_ThinkPost, Hook_OnThinkPost);
        cs_player_manager = -1;
    }
}

void Ranks_OnClientPutInServer(int client)
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
    if(!(buttons & IN_SCORE))
        return;
    
    if(GetEntProp(client, Prop_Data, "m_nOldButtons") & IN_SCORE)
        return;

    if(StartMessageOne("ServerRankRevealAll", client) != null)
        EndMessage();
}

void Ranks_OnClientLoaded(int client)
{
    int rank = t_aRankCache.FindValue(g_iUId[client]);
    if(rank == -1)
        t_iRank[client] = t_aRankCache.Length + 1;
    else
        t_iRank[client] = rank;

    int score = Stats_GetTotalScore(client);

    if(score >= 204800)
        t_iCompLevel[client] = 18;
    else if(score >= 153600)
        t_iCompLevel[client] = 17;
    else if(score >= 120000)
        t_iCompLevel[client] = 16;
    else if(score >= 86400)
        t_iCompLevel[client] = 15;
    else if(score >= 64800)
        t_iCompLevel[client] = 14;
    else if(score >= 51200)
        t_iCompLevel[client] = 13;
    else if(score >= 38400)
        t_iCompLevel[client] = 12;
    else if(score >= 25600)
        t_iCompLevel[client] = 11;
    else if(score >= 12800)
        t_iCompLevel[client] = 10;
    else if(score >= 6400)
        t_iCompLevel[client] = 9;
    else if(score >= 3200)
        t_iCompLevel[client] = 8;
    else if(score >= 1600)
        t_iCompLevel[client] = 7;
    else if(score >= 800)
        t_iCompLevel[client] = 6;
    else if(score >= 400)
        t_iCompLevel[client] = 5;
    else if(score >= 200)
        t_iCompLevel[client] = 4;
    else if(score >= 100)
        t_iCompLevel[client] = 3;
    else if(score >= 50)
        t_iCompLevel[client] = 2;
    else if(score >= 25)
        t_iCompLevel[client] = 1;

    Stats_WelcomMessage(client);
}

int Ranks_GetClientRank(int client)
{
    return t_iRank[client];
}