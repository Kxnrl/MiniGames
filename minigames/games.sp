/******************************************************************/
/*                                                                */
/*                         MiniGames Core                         */
/*                                                                */
/*                                                                */
/*  File:          games.sp                                       */
/*  Description:   MiniGames Game Mod.                            */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2020  Kyle                                      */
/*  2018/03/05 16:51:01                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/

enum /* scoreboard_t */
{
    SB_Kill,
    SB_Death,
    SB_Assist,
    SB_MaxAttributes
}

static StringMap t_Storage;

static int  t_iWallHackCD = -1;
static int  iLastSpecTarget[MAXPLAYERS+1];
static bool bLastDisplayHud[MAXPLAYERS+1];
static bool bVACHudPosition[MAXPLAYERS+1];
static Handle t_tRoundTimer = null;
static float t_fRoundStart = -1.0;
static int t_iRoundNumber = 0;
static bool t_bRoundEnding = false;
static bool t_bPressed[2048];
static bool bBombPlanted;

static int t_iScoreBoard[MAXPLAYERS][SB_MaxAttributes];

static Handle t_kOCookies[kO_MaxOptions];
static char   t_szCookies[kO_MaxOptions][] = {
    "MG.HudSpec.Disabled",
    "MG.HudVac.Disabled",
    "MG.HudSpeed.Disabled",
    "MG.HudHurt.Disabled",
    "MG.HudChat.Disabled",
    "MG.HudText.Disabled",
    // !!! transmit disabled by default
    "MG.Transmit.Enabled"
};

static char t_szSpecHudContent[MAXPLAYERS+1][256];

void Games_OnPluginStart()
{
    RegConsoleCmd("sm_mg",      Command_Main);
    RegConsoleCmd("sm_menu",    Command_Main);
    RegConsoleCmd("buyammo2",   Command_Main);
    RegConsoleCmd("sm_hide",    Command_Hide);
    RegConsoleCmd("sm_options", Command_Options);

    t_Storage = new StringMap();
}

void Games_RegisterCookies()
{
    for(int i = 0; i < kO_MaxOptions; ++i)
    {
        t_kOCookies[i] = RegClientCookie(t_szCookies[i], t_szCookies[i], CookieAccess_Private);
    }
}

static Action Command_Main(int client, int args)
{
    if (!ClientValid(client))
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

    if (g_smxMapMuisc)
    {
        FormatEx(line, 32, "%T", "main mapmusic", client);
        main.AddItem("u", line);
    }

    FormatEx(line, 32, "%T", "main store", client);
    main.AddItem("i", line);

    main.ExitButton = true;
    main.ExitBackButton = false;
    main.Display(client, 15);

    return Plugin_Handled;
}

static int MenuHandler_MenuMain(Menu menu, MenuAction action, int client, int slot)
{
    if (action == MenuAction_End)
        delete menu;
    else if (action == MenuAction_Select)
    {
        switch(slot)
        {
            case 0: FakeClientCommandEx(client, "sm_rank");
            case 1: FakeClientCommandEx(client, "sm_stats");
            case 2: Command_Options(client, slot);
            case 3: FakeClientCommandEx(client, "sm_mapmusic");
            case 4: FakeClientCommandEx(client, "sm_store");
        }
    }
    return 0;
}

static Action Command_Options(int client, int args)
{
    if (!ClientValid(client))
        return Plugin_Handled;

    char line[32];

    Menu options = new Menu(MenuHandler_MenuOptions);

    // sasusi

    FormatEx(line, 32, "%T", "options title", client);
    options.SetTitle("[MG]  %s\n ", line);

    FormatEx(line, 32, "%T:  %d", "options mapmusic volume", client, g_smxMapMuisc ? MapMusic_GetVolume(client) : 100);
    options.AddItem("yukiim", line, g_smxMapMuisc ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

    FormatEx(line, 32, "%T:  %T", "options hudspec", client, g_kOptions[client][kO_HudSpec] ? "menu item Off" : "menu item On", client);
    options.AddItem("s", line);

    FormatEx(line, 32, "%T:  %T", "options hudvac", client, g_kOptions[client][kO_HudVac] ? "menu item Off" : "menu item On", client);
    options.AddItem("a", line);

    FormatEx(line, 32, "%T:  %T", "options hudspeed", client, g_kOptions[client][kO_HudSpeed] ? "menu item Off" : "menu item On", client);
    options.AddItem("s", line);

    FormatEx(line, 32, "%T:  %T", "options hudhurt", client, g_kOptions[client][kO_HudHurt] ? "menu item Off" : "menu item On", client);
    options.AddItem("u", line);

    FormatEx(line, 32, "%T:  %T", "options hudchat", client, g_kOptions[client][kO_HudChat] ? "menu item Off" : "menu item On", client);
    options.AddItem("s", line);

    FormatEx(line, 32, "%T:  %T", "options hudtext", client, g_kOptions[client][kO_HudText] ? "menu item Off" : "menu item On", client);
    options.AddItem("o", line);

    FormatEx(line, 32, "%T:  %T", "options transmit", client, g_kOptions[client][kO_Transmit] ? "menu item On" : "menu item Off", client);
    options.AddItem("yukiim", line);

    options.ExitButton = false;
    options.ExitBackButton = true;
    options.Display(client, 15);

    return Plugin_Handled;
}

static int MenuHandler_MenuOptions(Menu menu, MenuAction action, int client, int slot)
{
    if (action == MenuAction_End)
        delete menu;
    else if (action == MenuAction_Cancel && slot == MenuCancel_ExitBack)
        Command_Main(client, slot);
    else if (action == MenuAction_Select)
    {
        switch (slot)
        {
            case 0: 
            {
                int volume = MapMusic_GetVolume(client) - 10;
                ScopeValue(volume, 100, 0);
                ResetValue(volume, 100, 0);
                MapMusic_SetVolume(client, volume);
            }
            default: Games_SetOptions(client, slot-1);
        }
        FakeClientCommandEx(client, "sm_options");
    }
    return 0;
}

static void Games_SetOptions(int client, int option)
{
    g_kOptions[client][option] = !g_kOptions[client][option];

    if (g_smxCookies)
    {
        Opts_SetOptBool(client, t_szCookies[option], g_kOptions[client][option]);
    }
    else if (g_extCookies)
    {
        SetClientCookie(client, t_kOCookies[option], g_kOptions[client][option] ? "1" : "0");
    }

    if (option == kO_Transmit)
    {
        // immed refresh state
        Hooks_UpdateState();

        Chat(client, "%T", g_kOptions[client][option] ? "transmit on" : "transmit off", client);
    }
}

static Action Command_Hide(int client, int args)
{
    Games_SetOptions(client, kO_Transmit);
    return Plugin_Handled;
}

void Games_OnMapStart()
{
    // timer to update hud
    CreateTimer(0.2, Games_TickInterval, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

static Action Games_TickInterval(Handle timer)
{
    Games_UpdateGameHUD();
    Games_CleanupWeapon();
    return Plugin_Continue;
}

// prevent EngineError no free edict...
static void Games_CleanupWeapon()
{
    static int tick = 0;
    if (++tick % 5 != 0)
        return;

    bool cleanMapWeapon = false;
    int edicts = -1;

    if (!IsWarmup())
    {
        for (int i = 1; i < 2048; i++) if (IsValidEdict(i))
        {
            // counting
            edicts++;
        }

        if (edicts < 1800)
        {
            // we have enough free edict slot
            return;
        }

        cleanMapWeapon = edicts >= 2000;
    }
    else
    {
        // we clean all
        cleanMapWeapon = true;
    }

    if (edicts > -1)
    LogMessage("Clean Weapons -> cleanMapWeapon = %s | edicts = %d", cleanMapWeapon ? "true" : "false", edicts);

    int entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "weapon_*")) != INVALID_ENT_REFERENCE)
    {
        int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");

        // if have owner client
        if (client > 0)
            continue;

        // ignore map weapons/grenades?
        if (!cleanMapWeapon && GetEntProp(entity, Prop_Data, "m_iHammerID") > -1)
            continue;

        // direct kill
        AcceptEntityInput(entity, "KillHierarchy");
    }
}

static void Games_UpdateGameHUD()
{
    // spec hud
    for(int client = 1; client <= MaxClients; ++client)
        if (ClientValid(client) && IsClientObserver(client))
        {
            // client is in - menu? || client check scoreboard
            if (GetClientMenu(client, null) != MenuSource_None || GetClientButtons(client) & IN_SCORE)
            {
                iLastSpecTarget[client] = 0;
                if (bLastDisplayHud[client])
                {
                    bLastDisplayHud[client] = false;
                    ClearHudByChannel(client, HUD_CHANNEL_SPEC);
                }
                continue;
            }

            // disabled by client options
            if (g_kOptions[client][kO_HudSpec])
                continue;

            // free look
            if (!(4 <= GetEntProp(client, Prop_Send, "m_iObserverMode") <= 5))
            {
                iLastSpecTarget[client] = 0;
                if (bLastDisplayHud[client])
                {
                    bLastDisplayHud[client] = false;
                    ClearHudByChannel(client, HUD_CHANNEL_SPEC);
                }
                continue;
            }

            int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
            
            // target is valid?
            if (iLastSpecTarget[client] == target || !ClientValid(target))
                continue;

            bLastDisplayHud[client] = true;
            iLastSpecTarget[client] = target;

            char message[512];

            if (mg_display_rating.BoolValue)
            {
                FormatEx(message, 512, "%N\n%T\n%s", target, "spec hud rating", client, Ranks_GetRank(target), Stats_GetKills(target), Stats_GetHSP(target), Stats_GetRating(target), Stats_GetTotalScore(target), t_szSpecHudContent[target]);
            }
            else
            {
                FormatEx(message, 512, "%N\n%T\n%s", target, "spec hud", client, Ranks_GetRank(target), Stats_GetKills(target), Stats_GetDeaths(target), Stats_GetAssists(target), float(Stats_GetKills(target))/float(Stats_GetDeaths(target)+1), Stats_GetHSP(target), Stats_GetTotalScore(target), t_szSpecHudContent[target]);
            }
            ReplaceString(message, 512, "#", "＃");

            // setup hud
            SetHudTextParamsEx(0.01, 0.35, 200.0, {175,238,238,255}, {135,206,235,255}, 0, 10.0, 5.0, 5.0);
            ShowHudText(client, HUD_CHANNEL_SPEC, message);
        }

    if (g_bHnS)
    {
        // we dont need vac in HnS
        return;
    }

    // countdown wallhack
    static bool needClear;
    if (t_iWallHackCD > 0)
    {
        needClear = true;
        SetHudTextParams(-1.0, 0.975, 2.0, 9, 255, 9, 255, 0, 1.2, 0.0, 0.0);
        for(int client = 1; client <= MaxClients; ++client)
            if (!bVACHudPosition[client] && ClientValid(client) && !g_kOptions[client][kO_HudVac])
                ShowHudText(client, HUD_CHANNEL_VAC, "%T", "vac timer", client, t_iWallHackCD);

        SetHudTextParams(-1.0, 0.000, 2.0, 9, 255, 9, 255, 0, 1.2, 0.0, 0.0);
        for(int client = 1; client <= MaxClients; ++client)
            if (bVACHudPosition[client] && ClientValid(client) && !g_kOptions[client][kO_HudVac])
                ShowHudText(client, HUD_CHANNEL_VAC, "%T", "vac timer", client, t_iWallHackCD);
    }
    else if (t_iWallHackCD != -1)
    {
        needClear = true;
        SetHudTextParams(-1.0, 0.975, 2.0, 238, 9, 9, 255, 0, 10.0, 0.0, 0.0);
        for(int client = 1; client <= MaxClients; ++client)
            if (!bVACHudPosition[client] && ClientValid(client) && !g_kOptions[client][kO_HudVac])
                ShowHudText(client, HUD_CHANNEL_VAC, "%T", "vac activated", client);

        SetHudTextParams(-1.0, 0.000, 2.0, 238, 9, 9, 255, 0, 10.0, 0.0, 0.0);
        for(int client = 1; client <= MaxClients; ++client)
            if (bVACHudPosition[client] && ClientValid(client) && !g_kOptions[client][kO_HudVac])
                ShowHudText(client, HUD_CHANNEL_VAC, "%T", "vac activated", client);
    }
    else if (needClear || t_iWallHackCD == -2)
    {
        needClear = false;
        for(int client = 1; client <= MaxClients; ++client)
            if (ClientValid(client))
                ClearHudByChannel(client, HUD_CHANNEL_VAC);
    }
}

void Games_OnMapEnd()
{
    delete t_tRoundTimer;

    t_Storage.Clear();
}

// reset ammo and slay.
void Games_OnEquipPost(DataPack pack)
{
    pack.Reset();
    int client = pack.ReadCell();
    int weapon = EntRefToEntIndex(pack.ReadCell());
    delete pack;

    if (!IsValidEdict(weapon))
        return;

    // get item defindex
    int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");

    // ignore knife, grenade and special item
    if (500 <= index <= 520 || 42 < index < 50 || index == 0)
        return;

    char classname[32];
    GetWeaponClassname(weapon, index, classname, 32);

    // ignore taser
    if (StrContains(classname, "taser", false) != -1)
        return;

    // restrict AWP
    if (mg_restrict_awp.BoolValue && strcmp(classname, "weapon_awp") == 0)
    {
        Chat(client, "%T", "restrict awp", client);
        RemoveAndSwitch(client, weapon);
        return;
    }

    // restrict Mahine gun
    if (mg_restrict_machinegun.BoolValue && (strcmp(classname, "weapon_m249") == 0 || strcmp(classname, "weapon_negev") == 0))
    {
        Chat(client, "%T", "restrict machine gun", client);
        RemoveAndSwitch(client, weapon);
        return;
    }

    // force slay player who uses gaygun
    if (mg_restrict_autosniper.BoolValue && (strcmp(classname, "weapon_scar20") == 0 || strcmp(classname, "weapon_g3sg1") == 0))
    {
        Chat(client, "%T", "restrict autosniper", client);
        RemoveAndSwitch(client, weapon);
        return;
    }

    // Do.?
}

// reset addons
void Games_OnPostThinkPost(int client)
{
    if (!bBombPlanted)
        return;

    int m_iAddonBits = GetEntProp(client, Prop_Send, "m_iAddonBits");

    if (m_iAddonBits & ADDON_DEFUSER)
    {
        // remove that
        SetEntProp(client, Prop_Send, "m_iAddonBits", m_iAddonBits & ~ADDON_DEFUSER);
    }
}

void Games_OnClientConnected(int client)
{
    t_szSpecHudContent[client][0] = '\0';

    for (int i = 0; i < SB_MaxAttributes; i++)
        t_iScoreBoard[client][i] = 0;

    for(int i = 0; i < kO_MaxOptions; ++i)
        g_kOptions[client][i] = false;
}

void Games_OnClientCookiesLoaded(int client)
{
    for(int i = 0; i < kO_MaxOptions; ++i)
    {
        g_kOptions[client][i] = Opts_GetOptBool(client, t_szCookies[i], false);
    }

    char steamid[20];
    if (!GetClientAuthId(client, AuthId_SteamID64, steamid, 20))
        return;

    t_Storage.GetArray(steamid, t_iScoreBoard[client], sizeof(t_iScoreBoard[]));
}

void Games_OnClientCookiesCached(int client)
{
    // don't override
    if (g_smxCookies)
        return;

    char buffer[4];
    for(int i = 0; i < kO_MaxOptions; ++i)
    {
        GetClientCookie(client, t_kOCookies[i], buffer, 4);
        g_kOptions[client][i] = (StringToInt(buffer) == 1);
    }

    char steamid[20];
    if (!GetClientAuthId(client, AuthId_SteamID64, steamid, 20))
        return;

    t_Storage.GetArray(steamid, t_iScoreBoard[client], sizeof(t_iScoreBoard[]));
}

void Games_OnClientDisconnect(int client)
{
    char steamid[20];
    if (!GetClientAuthId(client, AuthId_SteamID64, steamid, 20))
        return;

    t_Storage.SetArray(steamid, t_iScoreBoard[client], sizeof(t_iScoreBoard[]));
}

void Games_OnPlayerRunCmd(int client, int& buttons, int tickcount)
{
    if (!IsPlayerAlive(client))
        return;

    // block keybind crouch jump
    Games_BlockKeybindCJ(client, buttons);

    float CurVelVec[3];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", CurVelVec);

    // show speed hud
    if (tickcount % 8 == 0)
    {
        // if 128tick, 16 calls per second.
        Games_ShowCurrentSpeed(client, SquareRoot(Pow(CurVelVec[0], 2.0) + Pow(CurVelVec[1], 2.0)));
    }

    // limit pref speed
    Games_LimitPreSpeed(client, view_as<bool>(GetEntityFlags(client) & FL_ONGROUND), CurVelVec);

    // Duck spaming
    Games_DuckSpam(client);
}

static void Games_BlockKeybindCJ(int client, int& buttons)
{
    if (!mg_block_keybind_cj.BoolValue)
        return;

    static bool m_bWasDucking[MAXPLAYERS+1], m_bJumping[MAXPLAYERS+1];

    bool newDuck = view_as<bool>((buttons & IN_DUCK));
    bool newJumping = view_as<bool>((buttons & IN_JUMP));
    bool newOnGround = view_as<bool>((GetEntityFlags(client) & FL_ONGROUND));

    if (!m_bJumping[client] && !m_bWasDucking[client] && newJumping && newOnGround && newDuck)
    {
        buttons &= ~IN_DUCK;
        Text(client, "%T", "block bind cj", client);
    }

    m_bWasDucking[client] = view_as<bool>((buttons & IN_DUCK));
    m_bJumping[client] = view_as<bool>((buttons & IN_JUMP));
}

static void Games_DuckSpam(int client)
{
    // fixes crouch spamming
    if (GetEntPropFloat(client, Prop_Data, "m_flDuckSpeed") < 4.0) // old 7
    {
        SetEntPropFloat(client, Prop_Send, "m_flDuckSpeed", 4.0);
    }
}

// code from KZTimer by 1NutWunDeR -> https://github.com/1NutWunDeR/KZTimerOffical
static void Games_LimitPreSpeed(int client, bool bOnGround, float curVelvec[3])
{
    if (!sv_enablebunnyhopping.BoolValue)
        return;

    static bool IsOnGround[MAXPLAYERS+1];

    if (bOnGround)
    {
        if (!IsOnGround[client])
        {
            float speedlimit = mg_bhopspeed.FloatValue;

            IsOnGround[client] = true;    
            if (GetVectorLength(curVelvec) > speedlimit)
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

Action Games_OnClientSpawn(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    
    if (!ClientValid(client))
        return Plugin_Stop;

    SetEntProp(client, Prop_Send, "m_iAccount",   23333);                       // unlimit cash
    SetEntProp(client, Prop_Send, "m_ArmorValue", mg_spawn_kevlar.IntValue);    // apply kevlar
    SetEntProp(client, Prop_Send, "m_bHasHelmet", mg_spawn_helmet.IntValue);    // apply helmet

    SetEntPropFloat(client, Prop_Send, "m_flDetectedByEnemySensorTime", 0.0);   // disable wallhack

    // warmup god mode
    SetEntProp(client, Prop_Data, "m_takedamage", IsWarmup() ? 0 : 2);

    // remove spec hud
    iLastSpecTarget[client] = 0;
    if (bLastDisplayHud[client])
    {
        bLastDisplayHud[client] = false;
        ClearHudByChannel(client, HUD_CHANNEL_SPEC);
    }

    // spawn knife
    if (GetPlayerWeaponSlot(client, CS_SLOT_KNIFE) == -1)
    {
        if (mg_spawn_knife.BoolValue)
        {
            GivePlayerItem(client, "weapon_knife");
        }
        else
        {
            int fists = GivePlayerItem(client, "weapon_fists");
            EquipPlayerWeapon(client, fists);
        }
    }

    // spawn pistol
    if (mg_spawn_pistol.BoolValue && GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == -1)
    {
        switch (g_iTeam[client])
        {
            case TEAM_CT: GivePlayerItem(client, "weapon_hkp2000");
            case TEAM_TE: GivePlayerItem(client, "weapon_glock");
        }
    }

    return Plugin_Stop;
}

void Games_OnClientDeath(int victim, int killer, int assister, bool headshot)
{
    t_iScoreBoard[victim][SB_Death]++;
    t_iScoreBoard[killer][SB_Kill]++;
    t_iScoreBoard[assister][SB_Assist]++;

    if (killer)
    AdjustKills(killer);
    if (victim)
    AdjustDeath(victim);
    if (assister)
    AdjustAssist(assister);

    if (mg_economy_system.IntValue == 1 && killer && victim == killer)
    {
        // give custom cash award
        SetEntProp(killer, Prop_Send, "m_iAccount", GetEntProp(killer, Prop_Send, "m_iAccount") + (headshot ? 500 : 300));
    }
}

void Games_OnRoundStarted()
{
    // mark
    t_bRoundEnding = false;
    bBombPlanted = false;

    // check warmup
    if (IsWarmup())
        return;

    // round count
    t_iRoundNumber++;

    // start time
    t_fRoundStart = GetGameTime();
    
    // calculate cooldown
    t_iWallHackCD = RoundToCeil(mg_wallhack_delay.FloatValue);

    // init round timer
    if (t_tRoundTimer != null)
        KillTimer(t_tRoundTimer);
    t_tRoundTimer = CreateTimer(1.0, Games_RoundTimer, _, TIMER_REPEAT);
    
    for(int client = 1; client <= MaxClients; ++client)
        if (ClientValid(client))
            if (QueryClientConVar(client, "cl_hud_playercount_pos", Games_HudPosition, 0) == QUERYCOOKIE_FAILED)
                bVACHudPosition[client] = false;

    // clear buttons
    for(int button = 1; button < 2048; button++)
        t_bPressed[button] = false;
}

static void Games_HudPosition(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
    int val = StringToInt(cvarValue);
    bVACHudPosition[client] = view_as<bool>(val);
}

static Action Games_RoundTimer(Handle timer)
{
    // wallhack timer
    if (t_iWallHackCD > 0 && --t_iWallHackCD == 0)
    {
        int tt, ct, te;
        GetAlives(tt, te, ct);

        bool block = false;
        Call_StartForward(g_fwdOnVacElapsed);
        Call_PushCell(te);
        Call_PushCell(ct);
        Call_Finish(block);
        if (block)
        {
            t_iWallHackCD = -2;
            return Plugin_Continue;
        }

        for(int client = 1; client <= MaxClients; ++client)
            if (ClientValid(client) && IsPlayerAlive(client))
                SetEntPropFloat(client, Prop_Send, "m_flDetectedByEnemySensorTime", 9999999.0);

        Call_StartForward(g_fwdOnVacEnabled);
        Call_PushCell(te);
        Call_PushCell(ct);
        Call_Finish();
    }
    // Slap player after vac timer elapsed
    else if (t_iWallHackCD == 0 && mg_slap_after_vac.BoolValue)
    {
        for(int client = 1; client <= MaxClients; ++client)
            if (ClientValid(client) && IsPlayerAlive(client))
            {
                int health = GetClientHealth(client) - 1;
                if (health < 1)
                {
                    // kill player
                    Call_StartForward(g_fwdOnVacClientSlain);
                    Call_PushCell(client);
                    Call_Finish();
                    ForcePlayerSuicide(client);
                }
                else
                {
                    // decrease health
                    SetEntityHealth(client, health);
                }
            }
    }

    return Plugin_Continue;
}

void Games_OnRoundEnd()
{
    if (t_tRoundTimer != null)
        KillTimer(t_tRoundTimer);
    t_tRoundTimer = null;

    t_iWallHackCD = -1;

    t_bRoundEnding = true;
    bBombPlanted = false;
}

void Games_OnBombPlanted(int client)
{
    bBombPlanted = true;

    if (mg_auto_defuser.BoolValue)
    {
        for(int i = 1; i <= MaxClients; ++i)
        if (ClientValid(i) && IsPlayerAlive(i))
        {
            // give defuser
            SetEntProp(i, Prop_Send, "m_bHasDefuser", true);
        }
    }

    if (mg_economy_system.IntValue == 1)
    {
        // give money custom
        SetEntProp(client, Prop_Send, "m_iAccount", GetEntProp(client, Prop_Send, "m_iAccount") + 500);
    }
}

void Games_OnEntityCreated(int entity)
{
    if (0 < entity < 2048)
        t_bPressed[entity] = false;
}

void Games_OnButtonPressed(int button, int client)
{
    if (!mg_button_watcher.BoolValue)
        return;

    if (!ClientValid(client))
        return;

    if (t_bPressed[button])
        return;

    t_bPressed[button] = true;

    char buffer[32];
    GetEntPropString(button, Prop_Data, "m_iName", buffer, 32);
    ChatAll("%t", "button pressed", client, button, GetEntProp(button, Prop_Data, "m_iHammerID"), buffer);
}

static void Games_ShowCurrentSpeed(int client, float speed)
{
    // disabled by client options
    if (g_kOptions[client][kO_HudSpeed])
        return;

    // if 64tick, we need 0.16s
    SetHudTextParams(-1.0, 0.785, 0.2, 0, 191, 255, 200, 0, 0.0, 0.0, 0.0);

    if (!sv_enablebunnyhopping.BoolValue)
    {
        // just current speed
        ShowHudText(client, HUD_CHANNEL_SPEED, "%.3f", speed);
    }
    else
    {
        // display max speed
        ShowHudText(client, HUD_CHANNEL_SPEED, "%d / %d", RoundToNearest(speed), mg_bhopspeed.IntValue);
    }
}

void Games_PlayerHurts(int client, int victim, int hitgroup)
{
    if (!client || g_kOptions[client][kO_HudHurt] || client == victim)
        return;

    static float lastDisplay[MAXPLAYERS+1];
    static   int lastTickNum[MAXPLAYERS+1];

    int currentTick = GetGameTickCount();

    // if headshot, always override
    if (hitgroup == 1)
    {
        lastDisplay[client] = GetGameTime() + 0.66;
        SetHudTextParams(-1.0, -1.0, 0.66, 255, 0, 0, 128, 0, 0.3, 0.1, 0.3);
    }
    else
    {
        // last headshot...
        if (GetGameTime() < lastDisplay[client])
            return;

        // same tick meaning bullet penetration, display the first only
        if (lastTickNum[client] == currentTick)
            return;

        SetHudTextParams(-1.0, -1.0, 0.25, 250, 128, 114, 128, 0, 0.125, 0.1, 0.125);
    }

    ShowHudText(client, HUD_CHANNEL_MARKER, "\n\n\n\n\n╳\n\n\n\n\n%N", victim);

    for (int target = 1; target <= MaxClients; ++target)
        if (client != target && ClientValid(target) && IsClientObserver(target) && !g_kOptions[target][kO_HudHurt])
            if (GetEntProp(target, Prop_Send, "m_iObserverMode") == 4)
                if (GetEntPropEnt(target, Prop_Send, "m_hObserverTarget") == client)
                    ShowHudText(target, HUD_CHANNEL_MARKER, "\n\n\n\n\n╳\n\n\n\n\n%N", victim);

    lastTickNum[client] = currentTick;
}

void Games_PlayerUnblind(int userid)
{
    int victim = GetClientOfUserId(userid);
    if (!ClientValid(victim))
        return;

    // no teamflash
    SetEntPropFloat(victim, Prop_Send, "m_flFlashMaxAlpha", 0.5);
}

void Games_OnPlayerBlind(DataPack pack)
{
    int victim = GetClientOfUserId(pack.ReadCell());
    int client = GetClientOfUserId(pack.ReadCell());
    float time = pack.ReadFloat();
    delete pack;
    
    if (!ClientValid(victim) || !IsPlayerAlive(victim) || !ClientValid(client))
        return;

    if (victim == client)
    {
        ChatAll("%t", "flashing self", victim);
        SDKHooks_TakeDamage(client, client, client, 1.0, DMG_PREVENT_PHYSICS_FORCE);
        return;
    }
    
    Chat(victim, "%T", "flashing notice victim",   victim, client, time);
    Chat(client, "%T", "flashing notice attacker", client, victim, time);

    // Anti Team flash, fucking idiot teammate. just fucking retarded.
    if (g_iTeam[victim] == g_iTeam[client])
    {
        if (GetEntPropFloat(victim, Prop_Send, "m_flFlashMaxAlpha") < 50.0)
            return;

        int damage = RoundToCeil(time * 5);
        //ChatAll("%t", "flashing target", client, victim, damage);

        // no teamflash
        SetEntPropFloat(victim, Prop_Send, "m_flFlashMaxAlpha", 0.5);

        if (IsPlayerAlive(client))
        {
            if (GetClientHealth(client) < damage)
            {
                // suicide
                ForcePlayerSuicide(client);
            }
            else
            {
                // take damage
                SDKHooks_TakeDamage(client, client, client, float(damage), DMG_PREVENT_PHYSICS_FORCE);
            }
        }
    }
}

void Games_RanderColor()
{
    for(int client = 1; client <= MaxClients; ++client)
    if (IsClientInGame(client) && IsPlayerAlive(client))
    {
        // render color
        RenderPlayerColor(client);
    }
}

void Games_ScoreBoards()
{
    for(int client = 1; client <= MaxClients; ++client)
    if (IsClientInGame(client))
    {
        AdjustKills(client);
        AdjustDeath(client);
        AdjustAssist(client);
    }
}

void RenderPlayerColor(int client)
{
    Action res = Plugin_Continue;
    Call_StartForward(g_fwdOnRenderModelColor);
    Call_PushCell(client);
    Call_Finish(res);

    if (res >= Plugin_Handled)
    {
        // blocked
        return;
    }

    if (mg_render_player.BoolValue)
    {
        switch (GetClientTeam(client))
        {
            case 2: SetEntityRenderColor(client, 255, 0, 0, 255);
            case 3: SetEntityRenderColor(client, 0, 0, 255, 255);
        }
    }
    else
    {
        // set to full-chain
        SetEntityRenderColor(client, 255, 255, 255, 255);
    }
}

void AdjustKills(int client)
{
    int old = GetEntProp(client, Prop_Data, "m_iFrags");
    if (old != t_iScoreBoard[client][SB_Kill])
        SetEntProp(client, Prop_Data, "m_iFrags", t_iScoreBoard[client][SB_Kill]);
}

void AdjustDeath(int client)
{
    int val = GetEntProp(client, Prop_Data, "m_iDeaths");

    if (val != t_iScoreBoard[client][SB_Death])
        SetEntProp(client, Prop_Data, "m_iDeaths", t_iScoreBoard[client][SB_Death]);
}

void AdjustAssist(int client)
{
    int val = CS_GetClientAssists(client);
    if (val != t_iScoreBoard[client][SB_Assist])
        CS_SetClientAssists(client, t_iScoreBoard[client][SB_Assist]);
}

/*******************************************************/
/********************** Local API **********************/
/*******************************************************/
int Games_SetSpecHudContent(int client, const char[] content)
{
    if (strlen(content) >= 255)
        return false;

    return strcopy(t_szSpecHudContent[client], 256, content);
}

float Games_GetRoundTime()
{
    return GetGameTime() - t_fRoundStart;
}

int Games_GetRoundNumber()
{
    return t_iRoundNumber;
}

void Games_AddVacTimer(int seconds)
{
    t_iWallHackCD += seconds;
}

bool Games_IsRoundEnding()
{
    return t_bRoundEnding;
}