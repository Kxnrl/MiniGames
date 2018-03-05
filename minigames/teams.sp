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


static t_iNextTeam[MAXPLAYERS+1];

void Teams_OnClientConnected(int client)
{
    t_iNextTeam[client] = 0;
}

void Teams_OnRoundEnd()
{
    if(mg_randomteam.BoolValue)
        CreateTimer(2.0, Teams_RandomTeam, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Teams_RandomTeam(Handle timer)
{
    if(g_tWarmup != null)
        return Plugin_Stop;
    
    ArrayList array_players = new ArrayList();

    for(int x = 1; x <= MaxClients; ++x)
        if(IsClientInGame(x) && !IsFakeClient(x) && g_iTeam[x] > 1)
            array_players.Push(x);

    int random = -1;
    int counts = RoundToNearest(array_players.Length*0.5);
    while((random = RandomArray(array_players)) != -1)
    {
        int client = array_players.Get(random);
        array_players.Erase(random);

        if(counts > 0)
        {
            counts--;

            if(g_iTeam[client] != 2)
            {
                t_iNextTeam[client] = 2;
                PrintCenterText(client, "<font color='#0066CC' size='25'>你将在3s后切换到新的队伍!");
                CreateTimer(3.0, Timer_ChangeClientTeam, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
            }
        }
        else
        {
            if(g_iTeam[client] != 3 /*&& GetEntProp(client, Prop_Send, "m_iPendingTeamNum") != 3*/)
            {
                t_iNextTeam[client] = 3;
                PrintCenterText(client, "<font color='#0066CC' size='25'>你将在3s后切换到新的队伍!");
                CreateTimer(3.0, Timer_ChangeClientTeam, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }
    
    ChatAll("\x04当前地图已开启随机组队,新的队伍已经分配...");

    delete array_players;

    return Plugin_Stop;
}

public Action Timer_ChangeClientTeam(Handle timer, int userid)
{
    int client = GetClientOfUserId(client);
    if(!client || !IsClientInGame(client))
        return Plugin_Stop;

    if(t_iNextTeam[client] == g_iTeam[client])
    {
        t_iNextTeam[client] = 0;
        return Plugin_Stop;
    }

    CS_SwitchTeam(client, t_iNextTeam[client]);
    
    if(t_iNextTeam[client] == 3)
        PrintCenterText(client, "当前地图已经开启随机组队\n 你已被随机到 <font color='#0066CC' size='20'>反恐精英");
    else
        PrintCenterText(client, "当前地图已经开启随机组队\n 你已被随机到 <font color='#FF0000' size='20'>恐怖分子");
    
    t_iNextTeam[client] = 0;

    return Plugin_Stop;
}

public Action Command_Jointeam(int client, const char[] command, int argc)
{
    if(!client || !IsClientInGame(client) || argc < 1)
        return Plugin_Handled;

    char arg[4];
    GetCmdArg(1, arg, 4);
    int newteam = StringToInt(arg);
    int oldteam = GetClientTeam(client);
    
    if(t_iNextTeam[client] != 0)
    {
        ChangeClientTeam(client, t_iNextTeam[client]);
        Chat(client, "\x02随机组队切换队伍中...");
        return Plugin_Handled;
    }

    if(newteam == oldteam)
        return Plugin_Handled;

    if(oldteam <= 1)
    {
        ChangeClientTeam(client, Teams_GetAllowTeam());
        return Plugin_Handled;
    }

    if(IsPlayerAlive(client))
    {
        Chat(client, "\x02活着的时候不能切换队伍");
        return Plugin_Handled;
    }

    if(newteam == 1)
    {
        ChangeClientTeam(client, 1);
        return Plugin_Handled;
    }

    return Plugin_Handled;
}

static int Teams_GetAllowTeam()
{
	return (GetTeamClientCount(2) > GetTeamClientCount(3)) ? 3 : 2;
}