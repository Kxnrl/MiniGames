/******************************************************************/
/*                                                                */
/*                         MiniGames Core                         */
/*                                                                */
/*                                                                */
/*  File:          games.sp                                       */
/*  Description:   MiniGames Game Mod.                            */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2018  Kyle                                      */
/*  2018/03/05 16:51:01                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/


static int  t_iWallHackCD = -1;
static int  iLastSpecTarget[MAXPLAYERS+1];
static bool bLastDisplayHud[MAXPLAYERS+1];
static bool bVACHudPosition[MAXPLAYERS+1];
static Handle t_hHudSync[4] = null;
static Handle t_tRoundTimer = null;


static Handle t_kOCookies[kOptions];

static char t_szSpecHudContent[MAXPLAYERS+1][256];

void Games_OnPluginStart()
{
    for(int i = 0; i < view_as<int>(kOptions); ++i)
    {
        char cookieName[16];
        FormatEx(cookieName, 16, "MiniGames_Options_%d", i);
        t_kOCookies[view_as<kOptions>(i)] = RegClientCookie(cookieName, cookieName, CookieAccess_Private);
    }

    RegConsoleCmd("sm_mg",      Command_Main);
    RegConsoleCmd("sm_options", Command_Options);
}

public Action Command_Main(int client, int args)
{
    if(!client || !IsClientInGame(client))
        return Plugin_Handled;
    
    char line[32];

    Menu main = new Menu(MenuHandler_MenuMain);
    
    // sasusi
    
    FormatEx(line, 32, "%T", "main title", client);
    main.SetTitle("[MG]  %s\n ", line);

    FormatEx(line, 32, "%T", "main rank", client);
    main.AddItem("s", line);
    
    FormatEx(line, 32, "%T", "main stats", client);
    main.AddItem("a", line);
    
    FormatEx(line, 32, "%T", "main options", client);
    main.AddItem("s", line);
    
    FormatEx(line, 32, "%T", "main mapmusic", client);
    main.AddItem("u", line);
    
    FormatEx(line, 32, "%T", "main ampmusic", client);
    main.AddItem("s", line);
    
    FormatEx(line, 32, "%T", "main store", client);
    main.AddItem("i", line);
    
    main.ExitButton = true;
    main.ExitBackButton = false;
    
    main.Display(client, 15);

    return Plugin_Handled;
}

public int MenuHandler_MenuMain(Menu menu, MenuAction action, int client, int slot)
{
    if(action == MenuAction_End)
        delete menu;
    else if(action == MenuAction_Select)
    {
        switch(slot)
        {
            case 0: Command_Rank(   client, slot);
            case 1: Command_Stats(  client, slot);
            case 2: Command_Options(client, slot);
            case 3: FakeClientCommandEx(client, "sm_mapmusic");
            case 4: FakeClientCommandEx(client, "sm_music");
            case 5: FakeClientCommandEx(client, "sm_store");
        }
    }
}

public Action Command_Options(int client, int args)
{
    if(!client || !IsClientInGame(client))
        return Plugin_Handled;
    
    char line[32];

    Menu options = new Menu(MenuHandler_MenuOptions);

    // sasusi

    FormatEx(line, 32, "%T", "options title", client);
    options.SetTitle("[MG]  %s\n ", line);
    
    FormatEx(line, 32, "%T:  %T", "options hudspec", client, t_kOptions[client][kO_HudSpec] ? "menu item Off" : "menu item On", client);
    options.AddItem("s", line);
    
    FormatEx(line, 32, "%T:  %T", "options hudvac", client, t_kOptions[client][kO_HudVac] ? "menu item Off" : "menu item On", client);
    options.AddItem("a", line);
    
    FormatEx(line, 32, "%T:  %T", "options hudspeed", client, t_kOptions[client][kO_HudSpeed] ? "menu item Off" : "menu item On", client);
    options.AddItem("s", line);
    
    FormatEx(line, 32, "%T:  %T", "options hudhurt", client, t_kOptions[client][kO_HudHurt] ? "menu item Off" : "menu item On", client);
    options.AddItem("u", line);

    FormatEx(line, 32, "%T:  %T", "options hudchat", client, t_kOptions[client][kO_HudChat] ? "menu item Off" : "menu item On", client);
    options.AddItem("s", line);
    
    FormatEx(line, 32, "%T:  %T", "options hudtext", client, t_kOptions[client][kO_HudText] ? "menu item Off" : "menu item On", client);
    options.AddItem("o", line);

    options.ExitButton = false;
    options.ExitBackButton = true;
    
    options.Display(client, 15);
    
    return Plugin_Handled;
}

public int MenuHandler_MenuOptions(Menu menu, MenuAction action, int client, int slot)
{
    if(action == MenuAction_End)
        delete menu;
    else if(action == MenuAction_Cancel && slot == MenuCancel_ExitBack)
        Command_Main(client, slot);
    else if(action == MenuAction_Select)
    {
        kOptions options = view_as<kOptions>(slot);
        t_kOptions[client][options] = !t_kOptions[client][options];
        SetClientCookie(client, t_kOCookies[options], t_kOptions[client][options] ? "1" : "0");
        Command_Options(client, 0);
    }
}

void Games_OnMapStart()
{
    // init hud synchronizer ...
    if(t_hHudSync[0] == null)
        t_hHudSync[0] = CreateHudSynchronizer();
    
    if(t_hHudSync[1] == null)
        t_hHudSync[1] = CreateHudSynchronizer();
    
    if(t_hHudSync[2] == null)
        t_hHudSync[2] = CreateHudSynchronizer();
    
    if(t_hHudSync[3] == null)
        t_hHudSync[3] = CreateHudSynchronizer();

    // timer to update hud
    CreateTimer(1.0, Games_UpdateGameHUD, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Games_UpdateGameHUD(Handle timer)
{
    // spec hud
    for(int client = 1; client <= MaxClients; ++client)
        if(IsClientInGame(client) && !IsFakeClient(client) && !IsClientSourceTV(client) && !IsPlayerAlive(client))
        {
            // client is in - menu?
            if(GetClientMenu(client, null) != MenuSource_None)
            {
                iLastSpecTarget[client] = 0;
                if(bLastDisplayHud[client])
                    ClearSyncHud(client, t_hHudSync[0]);
                continue;
            }

            // free look
            if(!(4 <= GetEntProp(client, Prop_Send, "m_iObserverMode") <= 5))
            {
                iLastSpecTarget[client] = 0;
                if(bLastDisplayHud[client])
                    ClearSyncHud(client, t_hHudSync[0]);
                continue;
            }

            int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
            
            // target is valid?
            if(iLastSpecTarget[client] == target || target < 1 || target > MaxClients || !IsClientInGame(target))
                continue;

            bLastDisplayHud[client] = true;
            iLastSpecTarget[client] = target;

            char message[512];
            FormatEx(message, 512, "【Lv.%d】 %N\n%T\n%s", Ranks_GetLevel(target), target, "spec hud", client, Ranks_GetRank(target), Stats_GetKills(target), Stats_GetDeaths(target), Stats_GetAssists(target), float(Stats_GetKills(target))/float(Stats_GetDeaths(target)+1), Stats_GetHSP(target), Stats_GetTotalScore(target), t_szSpecHudContent[target]);
            ReplaceString(message, 512, "#", "＃");

            // setup hud
            SetHudTextParamsEx(0.01, 0.35, 200.0, {175,238,238,255}, {135,206,235,255}, 0, 10.0, 5.0, 5.0);
            ShowSyncHudText(client, t_hHudSync[0], message);
        }

    // countdown wallhack
    static bool needClear;
    if(t_iWallHackCD > 0)
    {
        needClear = true;
        SetHudTextParams(-1.0, 0.975, 2.0, 9, 255, 9, 255, 0, 1.2, 0.0, 0.0);
        for(int client = 1; client <= MaxClients; ++client)
            if(!bVACHudPosition[client] && IsClientInGame(client) && !IsFakeClient(client) && !IsClientSourceTV(client))
                ShowSyncHudText(client, t_hHudSync[1], "%T", "vac timer", client, t_iWallHackCD);

        SetHudTextParams(-1.0, 0.000, 2.0, 9, 255, 9, 255, 0, 1.2, 0.0, 0.0);
        for(int client = 1; client <= MaxClients; ++client)
            if(bVACHudPosition[client] && IsClientInGame(client) && !IsFakeClient(client) && !IsClientSourceTV(client))
                ShowSyncHudText(client, t_hHudSync[1], "%T", "vac timer", client, t_iWallHackCD);
    }
    else if(t_iWallHackCD != -1)
    {
        needClear = true;
        SetHudTextParams(-1.0, 0.975, 2.0, 238, 9, 9, 255, 0, 10.0, 0.0, 0.0);
        for(int client = 1; client <= MaxClients; ++client)
            if(!bVACHudPosition[client] && IsClientInGame(client) && !IsFakeClient(client) && !IsClientSourceTV(client))
                ShowSyncHudText(client, t_hHudSync[1], "%T", "vac activated", client);
            
        SetHudTextParams(-1.0, 0.000, 2.0, 238, 9, 9, 255, 0, 10.0, 0.0, 0.0);
        for(int client = 1; client <= MaxClients; ++client)
            if(bVACHudPosition[client] && IsClientInGame(client) && !IsFakeClient(client) && !IsClientSourceTV(client))
                ShowSyncHudText(client, t_hHudSync[1], "%T", "vac activated", client);
    }
    else if(needClear || t_iWallHackCD == -2)
    {
        needClear = false;
        for(int client = 1; client <= MaxClients; ++client)
            if(IsClientInGame(client) && !IsFakeClient(client) && !IsClientSourceTV(client))
                ClearSyncHud(client, t_hHudSync[1]);
    }

    return Plugin_Continue;
}

void Games_OnMapEnd()
{
    //free all
    
    if(t_hHudSync[0] != null)
        CloseHandle(t_hHudSync[0]);
    t_hHudSync[0] = null;

    if(t_hHudSync[1] != null)
        CloseHandle(t_hHudSync[1]);
    t_hHudSync[1] = null;
    
    if(t_hHudSync[2] != null)
        CloseHandle(t_hHudSync[1]);
    t_hHudSync[2] = null;
    
    if(t_hHudSync[3] != null)
        CloseHandle(t_hHudSync[1]);
    t_hHudSync[3] = null;

    if(t_tRoundTimer != null)
        KillTimer(t_tRoundTimer);
    t_tRoundTimer = null;
}

// reset ammo and slay.
void Games_OnEquipPost(DataPack pack)
{
    pack.Reset();
    int client = pack.ReadCell();
    int weapon = EntRefToEntIndex(pack.ReadCell());
    delete pack;

    if(!IsValidEdict(weapon))
        return;

    // get item defindex
    int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
    
    // ignore knife, grenade and special item
    if(500 <= index <= 515 || 42 < index < 50 || index == 0)
        return;

    char classname[32];
    GetWeaponClassname(weapon, index, classname, 32);

    // ignore taser
    if(StrContains(classname, "taser", false) != -1)
        return;

    // restrict AWP
    if(mg_restrictawp.BoolValue && strcmp(classname, "weapon_awp") == 0)
    {
        Chat(client, "%T", "restrict awp", client);
        
        if(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == weapon)
        {
            int knife = GetPlayerWeaponSlot(client, 2);
            if(knife != -1)
                SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", knife);
        }

        RemovePlayerItem(client, weapon);
        AcceptEntityInput(weapon, "KillHierarchy");

        return;
    }

    // force slay player who uses gaygun
    if(mg_slaygaygun.BoolValue && (strcmp(classname, "weapon_scar20") == 0 || strcmp(classname, "weapon_g3sg1") == 0))
    {
        ChatAll("%t", "slay gaygun", client, classname[7]);

        RemovePlayerItem(client, weapon);
        AcceptEntityInput(weapon, "KillHierarchy");
        ForcePlayerSuicide(client);

        return;
    }

    // fix ammo */1
    int amtype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");

    if(amtype == -1)
        return;

    SetEntProp(client, Prop_Send, "m_iAmmo", 233, _, amtype);
}

void Games_OnClientConnected(int client)
{
    t_szSpecHudContent[client][0] = '\0';
    
    for(int i = 0; i < view_as<int>(kOptions); ++i)
        t_kOptions[client][view_as<kOptions>(i)] = false;
}

void Games_OnClientCookiesCached(int client)
{
    char buffer[4];
    for(int i = 0; i < view_as<int>(kOptions); ++i)
    {
        GetClientCookie(client, t_kOCookies[view_as<kOptions>(i)], buffer, 4);
        t_kOptions[client][view_as<kOptions>(i)] = (StringToInt(buffer) == 1);
    }
}

void Games_OnPlayerRunCmd(int client)
{
    if(!IsPlayerAlive(client))
        return;

    if(!sv_enablebunnyhopping.BoolValue)
        return;
    
    float CurVelVec[3];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", CurVelVec);
    
    // show speed hud
    Games_ShowCurrentSpeed(client, SquareRoot(Pow(CurVelVec[0], 2.0) + Pow(CurVelVec[1], 2.0)));

    // limit pref speed
    Games_LimitPreSpeed(client, view_as<bool>(GetEntityFlags(client) & FL_ONGROUND), CurVelVec);
}

// code from KZTimer by 1NutWunDeR -> https://github.com/1NutWunDeR/KZTimerOffical
static void Games_LimitPreSpeed(int client, bool bOnGround, float curVelvec[3])
{
    static bool IsOnGround[MAXPLAYERS+1];

    if(bOnGround)
    {
        if(!IsOnGround[client])
        {
            float speedlimit = mg_bhopspeed.FloatValue;

            IsOnGround[client] = true;    
            if(GetVectorLength(curVelvec) > speedlimit)
            {
                NormalizeVector(curVelvec, curVelvec);
                ScaleVector(curVelvec, speedlimit);
                TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, curVelvec);
            }
        }
    }
    else
        IsOnGround[client] = false;
}

public Action Games_OnClientSpawn(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    
    if(!client || !IsClientInGame(client))
        return Plugin_Stop;

    SetEntProp(client, Prop_Send, "m_iHideHUD",   1<<12);                       // hide radar
    SetEntProp(client, Prop_Send, "m_iAccount",   23333);                       // unlimit cash
    SetEntProp(client, Prop_Send, "m_ArmorValue", mg_spawn_kevlar.IntValue);    // apply kevlar
    SetEntProp(client, Prop_Send, "m_bHasHelmet", mg_spawn_helmet.IntValue);    // apply helmet
    
    SetEntPropFloat(client, Prop_Send, "m_flDetectedByEnemySensorTime", 0.0);   // disable wallhack
    
    // remove spec hud
    iLastSpecTarget[client] = 0;
    bLastDisplayHud[client] = false;
    ClearSyncHud(client, t_hHudSync[0]);

    // spawn weapon
    if(mg_spawn_knife.BoolValue  && GetPlayerWeaponSlot(client, 2) == -1)
        GivePlayerItem(client, "weapon_knife");

    if(mg_spawn_pistol.BoolValue && GetPlayerWeaponSlot(client, 1) == -1)
    {
        if(g_iTeam[client] == 2)
            GivePlayerItem(client, "weapon_glock");

        if(g_iTeam[client] == 3)
            GivePlayerItem(client, "weapon_hkp2000");
    }

    return Plugin_Stop;
}

void Games_OnRoundStarted()
{
    t_iWallHackCD = RoundToCeil(mg_wallhack_delay.FloatValue);

    // init round timer
    if(t_tRoundTimer != null)
        KillTimer(t_tRoundTimer);
    t_tRoundTimer = CreateTimer(1.0, Games_RoundTimer, _, TIMER_REPEAT);
    
    for(int client = 1; client <= MaxClients; ++client)
        if(IsClientInGame(client) && !IsFakeClient(client) && !IsClientSourceTV(client))
            if(QueryClientConVar(client, "cl_hud_playercount_pos", Games_HudPosition, 0) == QUERYCOOKIE_FAILED)
                bVACHudPosition[client] = false;
}

public void Games_HudPosition(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
    int val = StringToInt(cvarValue);
    bVACHudPosition[client] = view_as<bool>(val);
}

public Action Games_RoundTimer(Handle timer)
{
    // wallhack timer
    if(t_iWallHackCD > 0 && --t_iWallHackCD == 0)
    {
        int tt, ct, te;
        GetAlives(tt, te, ct);

        bool block = false;
        Call_StartForward(g_fwdOnVacEnabled);
        Call_PushCell(te);
        Call_PushCell(ct);
        Call_Finish(block);
        if(block)
        {
            t_iWallHackCD = -2;
            return Plugin_Continue;
        }

        for(int client = 1; client <= MaxClients; ++client)
            if(IsClientInGame(client) && IsPlayerAlive(client))
                SetEntPropFloat(client, Prop_Send, "m_flDetectedByEnemySensorTime", 9999999.0);
    }

    return Plugin_Continue;
}

void Games_OnRoundEnd()
{
    if(t_tRoundTimer != null)
        KillTimer(t_tRoundTimer);
    t_tRoundTimer = null;

    t_iWallHackCD = -1;
}

static void Games_ShowCurrentSpeed(int client, float speed)
{
    SetHudTextParams(-1.0, 0.785, 0.1, 0, 191, 255, 200, 0, 0.0, 0.0, 0.0);
    ShowSyncHudText(client, t_hHudSync[2], "%.3f", speed);
}

void Games_PlayerHurts(int client, int hitgroup)
{
    if(!client)
        return;
    
    static float lastDisplay[MAXPLAYERS+1];

    if(hitgroup == 1)
    {
        lastDisplay[client] = GetGameTime() + 0.66;
        SetHudTextParams(-1.0, -1.0, 0.66, 255, 0, 0, 128, 0, 0.3, 0.1, 0.3);
    }
    else
    {
        if(GetGameTime() < lastDisplay[client])
            return;

        SetHudTextParams(-1.0, -1.0, 0.25, 250, 128, 114, 128, 0, 0.125, 0.1, 0.125);
    }

    //ShowSyncHudText(client, t_hHudSync[3], "◞　◟\n◝　◜");
    ShowSyncHudText(client, t_hHudSync[3], "＼ ／\n／ ＼");
}

void Games_OnPlayerBlind(DataPack pack)
{
    int victim = GetClientOfUserId(pack.ReadCell());
    int client = GetClientOfUserId(pack.ReadCell());
    float time = pack.ReadFloat();
    
    if(!victim || !IsClientInGame(victim) || !client || !IsClientInGame(client))
        return;

    if(victim == client)
    {
        ChatAll("%t", "flashing self", victim);
        SlapPlayer(client, 1, true);
        return;
    }
    
    Chat(victim, "%T", "flashing notice victim",   victim, client, time);
    Chat(client, "%T", "flashing notice attacker", client, victim, time);

    // Anti Team flash, fucking idiot teammate. just fucking retarded.
    if(g_iTeam[victim] == g_iTeam[client])
    {
        SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.5);
        int damage = RoundToCeil(time * 10);
        ChatAll("%t", "flashing target", client, victim, damage);
        SlapPlayer(client, damage, true);
    }
}

/*******************************************************/
/********************** Local API **********************/
/*******************************************************/
int Games_SetSpecHudContent(int client, const char[] content)
{
    if(strlen(content) >= 255)
        return false;

    return strcopy(t_szSpecHudContent[client], 256, content);
}