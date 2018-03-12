#pragma semicolon 1
#pragma newdecls required

#define PI_NAME     "MiniGames - Cheater Punisher"
#define PI_AUTHOR   "Kyle 'Kxnrl' Frankiss"
#define PI_DESC     "DARLING in the FRANXX"
#define PI_VERSION  "1.0+git<commit_counts>"
#define PI_URL      "https://kxnrl.com/git/MiniGames"

#define DMG_FROM_RIFLE (1 << 1)
#define DMG_FROM_NADES (1 << 6)
#define DMG_FROM_KNIFE (1 << 12)

public Plugin myinfo = 
{
    name        = PI_NAME,
    author      = PI_AUTHOR,
    description = PI_DESC,
    version     = PI_VERSION,
    url         = PI_URL
};

bool g_bCheater[MAXPLAYERS+1];
ArrayList g_aCheaters;

public void OnPluginStart()
{
    g_aCheaters = new ArrayList(ByteCountToCells(32));
    
    RegConsoleCmd("sm_cheater", Command_Cheater);
    
    PushCheatersToArrayList();
}

public Action Command_Cheater(int client, int args)
{
    if(!client)
        return Plugin_Handled;
    
    for(int x = 1; x <= MaxClients; ++x)
        if(IsClientInGame(x))
            if(g_bCheater[x])
                PrintToConsole(client, "%d.%d  %N was marked as cheater.", x, GetClientUserId(x), x);
            
    PrintToChat(client, "Check your console output");
    
    return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
    // bot or gotv
    if(IsFakeClient(client) || IsClientSourceTV(client))
        return;
    
    // handle damage
    SDKHookEx(client, SDKHook_TraceAttack, Hook_HandleTraceAttackAction);

    char steamid[32];
    GetClientAuthId(client, AuthId_Steam64ID, steamid, 32, true);
    
    g_bCheater[client] = (g_aCheaters.FindString(steamid) != -1);
}

public void OnClientDisconnect(int client)
{
    // if client is not fully in-game
    if(!IsClientInGame(client))
        return;
    
    g_bCheater[client] = false;
    SDKUnhook(client, SDKHook_TraceAttack, Hook_HandleTraceAttackAction);
}

public Action Hook_HandleTraceAttackAction(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
    if(damage <= 0.0 || !attacker || !g_bCheater[attacker])
        return Plugin_Continue;
    
    // headshot?
    if(hitbox == 1 || hitgroup == 1)
    {
        // force no headshot. xD
        damage *= 0.1;
        return Plugin_Changed;
    }

    // checking damage
    damageType dmgType = UTIL_GetDamageType(damagetype);
    
    // inferno grenade knife or taser
    if(ammotype == -1)
    {
        // knife
        if(dmgType == DMG_KNIFE)
        {
            // remove slash
            if(damage > 35.0)
            {
                damage = 35.0;
                return Plugin_Changed;
            }
            
            damage = 20.0
            return Plugin_Changed;
        }
        
        // checking entity classname
        char classname[32];
        GetEdictClassname(inflictor, classname, 32);
        
        // if inferno
        if(strcmp(classname, "inferno") == 0)
        {
            // force damage
            damage = 1.0;
            return Plugin_Changed;
        }
        
        // if hegrenade
        if(dmgType == DMG_FROM_NADES)
        {
            // force damage
            damage = 2.0;
            return Plugin_Changed;
        }
        
        // decrease other damage
        damage *= 0.5
        return Plugin_Changed;
    }
    
    // by rifles?
    if(dmgType == DMG_FROM_RIFLE)
    {
        // decrease damage
        damage *= 0.35;
        return Plugin_Changed;
    }
    
    // ignore others
    return Plugin_Continue;
}

static damageType UTIL_GetDamageType(int damagetype)
{
    if(damagetype & DMG_FROM_RIFLE)
        return DMG_RIFLE;
    
    if(damagetype & DMG_FROM_NADES)
        return DMG_NADES;

    if(damagetype & DMG_FROM_KNIFE)
        return DMG_KNIFE;

    return DMG_OTHER;
}

static void PushCheatersToArrayList()
{
    g_aCheaters.PushString("76561198360323854");
    g_aCheaters.PushString("76561198345576604");
    g_aCheaters.PushString("76561198381452231");
}