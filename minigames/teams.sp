/******************************************************************/
/*                                                                */
/*                         MiniGames Core                         */
/*                                                                */
/*                                                                */
/*  File:          teams.sp                                       */
/*  Description:   MiniGames Game Mod.                            */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2020  Kyle                                      */
/*  2018/03/05 16:51:01                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/

#define TEAM_US 0
#define TEAM_OB 1
#define TEAM_TE 2
#define TEAM_CT 3

static int t_iSwitchCD = -1;

void Teams_OnMapStart()
{
    AddToStringTable(FindStringTable("soundprecache"), "*maoling/faceit_match_found_tune.mp3");
    AddFileToDownloadsTable("sound/maoling/faceit_match_found_tune.mp3");
}

void Teams_OnPlayerConnected(int userid)
{
    CreateTimer(10.0, Timer_FullConnected, userid, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_FullConnected(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (!ClientValid(client) || g_iTeam[client] > TEAM_OB)
        return Plugin_Stop;

    int newteam = Teams_GetAllowTeam();
    Chat(client, "%T %T", "switch team on full connected", client, newteam == TEAM_CT ? "color team ct" : "color team te", client);
    ChangeClientTeam(client, newteam);

    return Plugin_Stop;
}

void Teams_OnRoundStart()
{
    t_iSwitchCD = -1;
}

void Teams_OnRoundEnd()
{
    t_iSwitchCD = -1;

    // timer to delay random team
    if (mg_randomteam.BoolValue)
        CreateTimer(1.5, Teams_RandomTeam, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Teams_RandomTeam(Handle timer)
{
    if (GetTeamClientCount(TEAM_TE) <= 1 && GetTeamClientCount(TEAM_CT) <= 1)
    {
        ChatAll("%t", "cancel random team");
        return Plugin_Stop;
    }

    // timer countdown
    t_iSwitchCD = 3;
    CreateTimer(1.0, Timer_ChangeTeam, _, TIMER_REPEAT);
    ChatAll("%t", "broadcast random team chat");
    TextAll("%t", "broadcast random team text", t_iSwitchCD);

    return Plugin_Stop;
}

public Action Timer_ChangeTeam(Handle timer)
{
    if (t_iSwitchCD < 0)
        return Plugin_Stop;

    // countdown
    if (--t_iSwitchCD == 0)
    {
        Teams_ChangeTeam();
        return Plugin_Stop;
    }

    TextAll("%t", "broadcast random team text", t_iSwitchCD);

    Hooks_UpdateState();

    return Plugin_Continue;
}

public Action Command_Jointeam(int client, const char[] command, int argc)
{
    if (!ClientValid(client) || argc < 1)
        return Plugin_Handled;

    char arg[4];
    GetCmdArg(1, arg, 4);
    int newteam = StringToInt(arg);
    int oldteam = GetClientTeam(client);

    // if client join game at the moment.
    if (oldteam <= TEAM_OB)
    {
        if (newteam == Teams_GetAllowTeam())
        {
            // same ?
            return Plugin_Continue;
        }

        ChangeClientTeam(client, Teams_GetAllowTeam());
        return Plugin_Handled;
    }

    // team?
    if (newteam == oldteam)
        return Plugin_Handled;

    // in random team processing
    if (t_iSwitchCD >= 0)
    {
        Chat(client, "%T", "processing team switching", client);
        return Plugin_Handled;
    }

    // force change
    if (IsPlayerAlive(client) || newteam == TEAM_OB)
    {
        ChangeClientTeam(client, newteam);
        return Plugin_Handled;
    }

    return Plugin_Handled;
}

static int Teams_GetAllowTeam()
{
    // allow team.
    int cts = GetTeamClientCount(TEAM_CT);
    int tes = GetTeamClientCount(TEAM_TE);

    // random t or ct
    if (cts == tes)
        return RandomInt(TEAM_TE, TEAM_CT);

    // force t side
    if (cts > tes)
        return TEAM_TE;

    // ct side
    return TEAM_CT;
}

static void Teams_ChangeTeam()
{
    ArrayList array_players = new ArrayList(sizeof(team_t));
    ArrayList array_buffers = new ArrayList();

    // push all client to random pool
    int players = 0;
    for(int x = 1; x <= MaxClients; ++x)
        if (ClientValid(x) && GetClientTeam(x) > TEAM_OB)
        {
            // push to buffer
            array_buffers.Push(x);
        }

    // CT always same/more of TE
    int numCTs = RoundToCeil(array_buffers.Length * 0.5); 
    int numTEs = array_buffers.Length - numCTs; 
    
    // store
    players = numCTs;

    while (array_buffers.Length > 0)
    {
        int random = RandomInt(0, array_buffers.Length-1);
        int client = array_buffers.Get(random);
        array_buffers.Erase(random);

        team_t t;
        t.currentTeam = GetClientTeam(client);
        t.nextTeam = (--players >= 0) ? TEAM_CT : TEAM_TE;
        t.client = client;
        array_players.PushArray(t, sizeof(t));
    }

    bool block = false;

    Call_StartForward(g_fwdOnRandomTeam);
    Call_PushCell(numCTs);
    Call_PushCell(numTEs);
    Call_PushCell(array_players);
    Call_Finish(block);

    if (block)
    {
        delete array_buffers;
        delete array_players;
        return;
    }

    numCTs = 0;
    numTEs = 0;
    for (int i = 0; i < array_players.Length; i++)
    {
        team_t t;
        array_players.GetArray(i, t, sizeof(team_t));

        if (IsPlayerAlive(t.client) && t.nextTeam > TEAM_OB)
        {
            RenderPlayerColor(t.client);
            CS_SwitchTeam(t.client, t.nextTeam);
        }
        else
        {
            ChangeClientTeam(t.client, t.nextTeam);
        }

        if (t.nextTeam == GetClientTeam(t.client))
        {
            // not changed
            Text(t.client, "%T", "self random not change text", t.client);
        }
        else
        {
            // notify
            Text(t.client, "%T", "self random team text", t.client, (t.nextTeam == TEAM_CT) ? "0066CC" : "FF0000", (t.nextTeam == TEAM_CT) ? "team ct" : "team te", t.client);
        }
    }

    delete array_buffers;
    delete array_players;

    t_iSwitchCD = -1;
    EmitSoundToAll("*maoling/faceit_match_found_tune.mp3");
}