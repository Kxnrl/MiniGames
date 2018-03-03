void Teams_OnRoundEnd()
{
    if(mg_randomteam.BoolValue)
        CreateTimer(3.0, Teams_RandomTeam, _, TIMER_FLAG_NO_MAPCHANGE);
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
    LogMessage("Starting Random Team -> %d : %d", counts, array_players.Length - counts);
    while((random = RandomArray(array_players)) != -1)
    {
        int client = array_players.Get(random);
        array_players.Erase(random);

        if(counts > 0)
        {
            counts--;

            if(g_iTeam[client] != 2 && GetEntProp(client, Prop_Send, "m_iPendingTeamNum") != 2)
            {
                //CS_SwitchTeam(client, 2);
                SetEntProp(client, Prop_Send, "m_iPendingTeamNum", 2);
                LogMessage("%N switch to CS_TEAM_TE", client);
                PrintCenterText(client, "当前地图已经开启随机组队\n 你已被移动到 <font color='#FF0000' size='20'>恐怖分子");
            }
            else
                LogMessage("%N stay in CS_TEAM_TE", client);
        }
        else
        {
            if(g_iTeam[client] != 3 && GetEntProp(client, Prop_Send, "m_iPendingTeamNum") != 3)
            {
                //CS_SwitchTeam(client, 3);
                SetEntProp(client, Prop_Send, "m_iPendingTeamNum", 3);
                LogMessage("%N switch to CS_TEAM_CT", client);
                PrintCenterText(client, "当前地图已经开启随机组队\n 你已被移动到 <font color='#0066CC' size='20'>反恐精英");
            }
            else
                LogMessage("%N stay in CS_TEAM_CT", client);
        }
    }

    delete array_players;

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

int Teams_GetAllowTeam()
{
	return (GetTeamClientCount(2) > GetTeamClientCount(3)) ? 3 : 2;
}