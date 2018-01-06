public void CG_OnGlobalTimer()
{
    for(int client = 1; client <= MaxClients; ++client)
    {
        if(!IsClientInGame(client))
            continue;
        
        //Client_SetClientTag(client);
        //Mutators_OnGlobalTimer(client);
    }
}

public void CG_OnClientSpawn(int client)
{
    Stats_OnClientSpawn(client);
    RequestFrame(Client_SpawnPost, client);
}

public void CG_OnClientDeath(int client, int attacker, int assister, bool headshot, const char[] weapon)
{
    if(g_tWarmup != INVALID_HANDLE)
        return;
    
    Bets_CheckAllow();
    Client_ClearGreenHat(client);
    Stats_OnClientDeath(client, attacker, assister, headshot, weapon);
    //Mutators_OnClientDeath(client);
}

public void CG_OnClientHurted(int client, int attacker, int damage, int health, int hitgroup, const char[] weapon)
{
    if(!IsValidClient(attacker))
        return;

    char log[256];
    FormatEx(log, 256, "%N damaged to %N with %s [dmg %d] [hit %s]", attacker, client, weapon, damage, g_szHitGroup[hitgroup]);
    PrintToConsole(client, log);
    PrintToConsole(attacker, log);
}

public Action Event_PlayerDisconnect(Handle event, const char[] name, bool dontBroadcast)
{
    SetEventBroadcast(event, true);
    return Plugin_Changed;
}

public void CG_OnRoundStart()
{
    Button_OnRoundStart();
    Bets_OnRoundStart();
    Client_OnRoundStart();
    //Mutators_OnRoundStart();
}

public void CG_OnRoundEnd(int winner)
{
    CreateTimer(10.0, Stats_OnRoundEnd, _, TIMER_FLAG_NO_MAPCHANGE);
    Bets_OnRoundEnd(winner);
    Client_OnRoundEnd();
    //Mutators_OnRoundEnd();
}

public void Event_WinPanel(Handle event, const char[] name, bool dontBroadcast)
{
    for(int client = 1; client <= MaxClients; ++client)
        if(IsClientInGame(client))
            SavePlayer(client);
}

public void Event_AnnouncePhaseEnd(Handle event, const char[] name, bool dontBroadcast)
{
    if(StartMessageAll("ServerRankRevealAll") != INVALID_HANDLE)
        EndMessage();
}

public void Hook_OnThinkPost(int iEnt)
{
    static int Offset = -1;
    if(Offset == -1)
        Offset = FindSendPropInfo("CCSPlayerResource", "m_iCompetitiveRanking");

    SetEntDataArray(iEnt, Offset, g_iLvls, MAXPLAYERS+1, _, true);
}
