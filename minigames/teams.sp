/******************************************************************/
/*                                                                */
/*                         MiniGames Core                         */
/*                                                                */
/*                                                                */
/*  File:          teams.sp                                       */
/*  Description:   MiniGames Game Mod.                            */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2018  Kyle                                      */
/*  2018/03/05 16:51:01                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/

#define TEAM_US 0
#define TEAM_OB 1
#define TEAM_TE 2
#define TEAM_CT 3

static int t_iNextTeam[MAXPLAYERS+1];
static int t_iSwitchCD = -1;

void Teams_OnMapStart()
{
    AddToStringTable(FindStringTable("soundprecache"), "*maoling/faceit_match_found_tune.mp3");
    AddFileToDownloadsTable("sound/maoling/faceit_match_found_tune.mp3");
}

void Teams_OnClientConnected(int client)
{
    t_iNextTeam[client] = TEAM_US;
}

void Teams_OnPlayerConnected(int userid)
{
    CreateTimer(10.0, Timer_FullConnected, userid, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_FullConnected(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if(!ClientValid(client) || g_iTeam[client] > TEAM_OB)
        return Plugin_Stop;

    int newteam = Teams_GetAllowTeam();
    Chat(client, "%T %T", "switch team on full connected", client, newteam == TEAM_CT ? "color team ct" : "color team te", client);
    ChangeClientTeam(client, newteam);

    return Plugin_Stop;
}

void Teams_OnRoundStart()
{
    t_iSwitchCD = -1;

    // reset all player
    for(int i = 0; i <= MaxClients; ++i)
        t_iNextTeam[i] = TEAM_US;
}

void Teams_OnRoundEnd()
{
    t_iSwitchCD = -1;

    // timer to delay random team
    if(mg_randomteam.BoolValue)
        CreateTimer(1.5, Teams_RandomTeam, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Teams_RandomTeam(Handle timer)
{
    if(g_tWarmup != null)
        return Plugin_Stop;

    if(GetTeamClientCount(TEAM_TE) <= 1 && GetTeamClientCount(TEAM_CT) <= 1)
    {
        ChatAll("%t", "cancel random team");
        return Plugin_Stop;
    }

    ArrayList array_players = new ArrayList();

    // push all client to random pool
    for(int x = 1; x <= MaxClients; ++x)
        if(ClientValid(x) && GetClientTeam(x) > TEAM_OB)
        {
            t_iNextTeam[x] = TEAM_CT;
            array_players.Push(x);
        }

    int counts = array_players.Length/2;

    bool block = false;
    Call_StartForward(g_fwdOnRandomTeam);
    Call_PushCell(counts);
    Call_PushCell(array_players.Length - counts);
    Call_Finish(block);
    if(block)
    {
        delete array_players;
        
        for(int x = 1; x <= MaxClients; ++x)
            t_iNextTeam[x] = TEAM_US;

        return Plugin_Stop;
    }

    while(counts-- > 0)
    {
        int random = RandomInt(0, array_players.Length-1);
        int client = array_players.Get(random);
        array_players.Erase(random);
        t_iNextTeam[client] = TEAM_TE;
    }

    delete array_players;

    // timer countdown
    t_iSwitchCD = 3;
    CreateTimer(1.0, Timer_ChangeTeam, _, TIMER_REPEAT);
    ChatAll("%t", "broadcast random team chat");
    TextAll("%t", "broadcast random team text", t_iSwitchCD);

    return Plugin_Stop;
}

public Action Timer_ChangeTeam(Handle timer)
{
    if(t_iSwitchCD < 0)
        return Plugin_Stop;

    // countdown
    if(--t_iSwitchCD == 0)
    {
        for(int x = 1; x <= MaxClients; ++x)
            if(ClientValid(x) && t_iNextTeam[x] > TEAM_US)
            {
                if(g_iTeam[x] == t_iNextTeam[x])
                {
                    t_iNextTeam[x] = TEAM_US;
                    Text(x, "%T", "self random not change text", x);
                    continue;
                }

                CS_SwitchTeam(x, t_iNextTeam[x]);
                t_iNextTeam[x] = TEAM_US;
                Text(x, "%T", "self random team text", x, (t_iNextTeam[x] == TEAM_CT) ? "0066CC" : "FF0000", (t_iNextTeam[x] == TEAM_CT) ? "team ct" : "team te", x);
            }

        t_iSwitchCD = -1;
        EmitSoundToAll("*maoling/faceit_match_found_tune.mp3");

        return Plugin_Stop;
    }

    TextAll("%t", "broadcast random team text", t_iSwitchCD);

    return Plugin_Continue;
}

public Action Command_Jointeam(int client, const char[] command, int argc)
{
    if(!ClientValid(client) || argc < 1)
        return Plugin_Handled;

    char arg[4];
    GetCmdArg(1, arg, 4);
    int newteam = StringToInt(arg);
    int oldteam = GetClientTeam(client);

    // if client join game at the moment.
    if(oldteam <= TEAM_OB)
    {
        ChangeClientTeam(client, Teams_GetAllowTeam());
        return Plugin_Handled;
    }

    // team?
    if(newteam == oldteam)
        return Plugin_Handled;

    // in random team processing
    if(t_iNextTeam[client] != TEAM_US)
    {
        ChangeClientTeam(client, t_iNextTeam[client]);
        t_iNextTeam[client] = TEAM_US;
        Chat(client, "%T", "processing team switching", client);
        return Plugin_Handled;
    }

    // force change
    if(IsPlayerAlive(client) || newteam == 1)
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
    if(cts == tes)
        return RandomInt(TEAM_TE, TEAM_CT);

    // force t side
    if(cts > tes)
        return TEAM_TE;

    // ct side
    return TEAM_CT;
}