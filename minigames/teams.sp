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


static int t_iNextTeam[MAXPLAYERS+1];
static int t_iSwitchCD = -1;

void Teams_OnClientConnected(int client)
{
    t_iNextTeam[client] = 0;
}

void Teams_OnRoundStart()
{
    t_iSwitchCD = -1;
    for(int i = 0; i <= MaxClients; ++i)
        t_iNextTeam[i] = 0;
}

void Teams_OnRoundEnd()
{
    t_iSwitchCD = -1;
    if(mg_randomteam.BoolValue)
        CreateTimer(1.5, Teams_RandomTeam, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Teams_RandomTeam(Handle timer)
{
    if(g_tWarmup != null)
        return Plugin_Stop;
    
    ArrayList array_players = new ArrayList();

    for(int x = 1; x <= MaxClients; ++x)
        if(IsClientInGame(x) && !IsFakeClient(x) && g_iTeam[x] > 1)
            array_players.Push(x);

    int change = 0;
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
                change++;
                PrintCenterText(client, "<font color='#0066CC' size='25'>你将在4s后切换到新的队伍!");
            }
        }
        else
        {
            if(g_iTeam[client] != 3)
            {
                t_iNextTeam[client] = 3;
                change++;
                PrintCenterText(client, "<font color='#0066CC' size='25'>你将在4s后切换到新的队伍!");
            }
        }
    }

    if(change > 0)
    {
        ChatAll("\x04当前地图已开启随机组队,新的队伍已经分配...");
        t_iSwitchCD = 3;
        CreateTimer(1.0, Timer_ChangeTeam, _, TIMER_REPEAT);
    }

    delete array_players;

    return Plugin_Stop;
}

public Action Timer_ChangeTeam(Handle timer)
{
    if(t_iSwitchCD < 0)
        return Plugin_Stop;
    
    if(t_iSwitchCD > 0)
    {
        for(int x = 1; x <= MaxClients; ++x)
            if(IsClientInGame(x) && !IsFakeClient(x) && t_iNextTeam[x] > 0)
                PrintCenterText(x, "<font color='#0066CC' size='25'>你将在%ds后切换到新的队伍!", t_iSwitchCD);
    }
    else
    {
        for(int x = 1; x <= MaxClients; ++x)
            if(IsClientInGame(x) && !IsFakeClient(x) && t_iNextTeam[x] > 0)
            {
                if(t_iNextTeam[x] == g_iTeam[x])
                {
                    t_iNextTeam[x] = 0;
                    continue;
                }
                
                CS_SwitchTeam(x, t_iNextTeam[x]);
                
                if(t_iNextTeam[x] == 3)
                    PrintCenterText(x, "当前地图已经开启随机组队\n 你已被随机到 <font color='#0066CC' size='20'>反恐精英");
                else
                    PrintCenterText(x, "当前地图已经开启随机组队\n 你已被随机到 <font color='#FF0000' size='20'>恐怖分子");
            
                t_iNextTeam[x] = 0;
            }
    }

    t_iSwitchCD--;
    
    return Plugin_Continue;
}

public Action Command_Jointeam(int client, const char[] command, int argc)
{
    if(!client || !IsClientInGame(client) || argc < 1)
        return Plugin_Handled;

    char arg[4];
    GetCmdArg(1, arg, 4);
    int newteam = StringToInt(arg);
    int oldteam = GetClientTeam(client);
    
    if(oldteam <= 1)
    {
        ChangeClientTeam(client, Teams_GetAllowTeam());
        return Plugin_Handled;
    }
    
    if(newteam == oldteam)
        return Plugin_Handled;
    
    if(t_iNextTeam[client] != 0)
    {
        ChangeClientTeam(client, t_iNextTeam[client]);
        t_iNextTeam[client] = 0;
        Chat(client, "\x02随机组队切换队伍中...");
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