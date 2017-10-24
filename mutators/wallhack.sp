void Wallhack_Init()
{
    g_Mutators = Game_Wallhack;
    PrintToChatAll(" \x02突变因子: \x07VAC");
    PrintToChatAll("本局你开启了透视作弊器");
    CreateTimer(3.0, Timer_Wallhack, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    CG_ShowGameTextAll("突变因子: VAC\n本局你开启了透视作弊器", "10.0", "57 197 187", "-1.0", "-1.0");
}

public Action Timer_Wallhack(Handle timer)
{
    if(g_Mutators != Game_Wallhack)
    {
        ResetAllClient();
        return Plugin_Stop;
    }
    
    GlowAllClient();
    
    return Plugin_Continue;
}

void ResetAllClient()
{
    for(int client = 1; client <= MaxClients; ++client)
        if(IsClientInGame(client))
            SetEntPropFloat(client, Prop_Send, "m_flDetectedByEnemySensorTime", 0.0);
}

void GlowAllClient()
{
    for(int client = 1; client <= MaxClients; ++client)
        if(IsClientInGame(client) && IsPlayerAlive(client) && g_iAuth[client] != 9999)
            SetEntPropFloat(client, Prop_Send, "m_flDetectedByEnemySensorTime", 9999.0);
}