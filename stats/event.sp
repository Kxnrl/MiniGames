public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    Stats_OnClientSpawn(client);
    CreateTimer(0.1, Client_SpawnPost, client)
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if(g_tWarmup != INVALID_HANDLE)
        return;
    
    int client = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int assister = GetClientOfUserId(event.GetInt("assister"));
    bool headshot = event.GetBool("headshot");
    char weapon[32];
    event.GetString("weapon", weapon, 32, "");
    
    Bets_CheckAllow();
    Stats_OnClientDeath(client, attacker, assister, headshot, weapon);
}

public void Event_PlayerHurts(Event event, const char[] name, bool dontBroadcast)
{
    if(g_tWarmup != INVALID_HANDLE)
        return;

    int client = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int damage = event.GetInt("dmg_health");
    int hitgroup = event.GetInt("hitgroup");
    char weapon[32];
    event.GetString("weapon", weapon, 32, "");
    
    if(!IsValidClient(attacker))
        return;

    char log[256];
    FormatEx(log, 256, "%N damaged to %N with %s [dmg %d] [hit %s]", attacker, client, weapon, damage, g_szHitGroup[hitgroup]);
    PrintToConsole(client, log);
    PrintToConsole(attacker, log);
}

public Action Event_dontBroadcast(Event event, const char[] name, bool dontBroadcast)
{
    SetEventBroadcast(event, true);
    return Plugin_Changed;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    Button_OnRoundStart();
    Bets_OnRoundStart();
    Client_OnRoundStart();
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    int winner = event.GetInt("winner");
    
    CreateTimer(10.0, Stats_OnRoundEnd, _, TIMER_FLAG_NO_MAPCHANGE);
    Bets_OnRoundEnd(winner);
    Client_OnRoundEnd();
}

public void Event_WinPanel(Event event, const char[] name, bool dontBroadcast)
{
    for(int client = 1; client <= MaxClients; ++client)
        if(IsClientInGame(client))
            SavePlayer(client);
}

public void Event_AnnouncePhaseEnd(Event event, const char[] name, bool dontBroadcast)
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
