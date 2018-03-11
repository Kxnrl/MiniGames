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
static Handle t_hHudSync[2] = null;
static Handle t_tRoundTimer = null;

void Games_OnMapStart()
{
    // init hud synchronizer ...
    if(t_hHudSync[0] == null)
        t_hHudSync[0] = CreateHudSynchronizer();
    
    if(t_hHudSync[1] == null)
        t_hHudSync[1] = CreateHudSynchronizer();

    // timer to update hud
    CreateTimer(1.0, Games_UpdateGameHUD, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Games_UpdateGameHUD(Handle timer)
{
    // spec hud
    for(int client = 1; client <= MaxClients; ++client)
        if(IsClientInGame(client) && !IsPlayerAlive(client) && !IsFakeClient(client) && !IsClientSourceTV(client))
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
            if(iLastSpecTarget[client] == target || target == -1 || !IsClientInGame(target))
                continue;

            bLastDisplayHud[client] = true;
            iLastSpecTarget[client] = target;

            char message[512];
            FormatEx(message, 512, "【Lv.%d】 %N\n总排名: %d\n杀敌数: %d\n死亡数: %d\n助攻数: %d\n杀亡比: %.2f\n爆头率: %.2f%%\n得分: %d", Ranks_GetRank(target), target, Stats_GetKills(target), Stats_GetDeaths(target), Stats_GetAssists(target), float(Stats_GetKills(target))/float(Stats_GetDeaths(target)+1), Stats_GetHSP(target), Stats_GetTotalScore(target));
            ReplaceString(message, 512, "#", "＃");
            
            // setup hud
            SetHudTextParamsEx(0.01, 0.35, 200.0, {255,130,171,255}, {255,165,0,255}, 0, 10.0, 5.0, 5.0);
            ShowSyncHudText(client, t_hHudSync[0], message);
        }
    
    // countdown wallhack
    static bool needClear;
    if(t_iWallHackCD > 0)
    {
        needClear = true;
        SetHudTextParams(-1.0, 0.785, 2.0, 9, 255, 9, 255, 0, 30.0, 0.0, 0.0);
        for(int client = 1; client <= MaxClients; ++client)
            if(IsClientInGame(client) && !IsFakeClient(client) && !IsClientSourceTV(client))
                ShowSyncHudText(client, t_hHudSync[1], ">>>距离VAC还有%d秒<<<", t_iWallHackCD);
    }
    else if(t_iWallHackCD != -1)
    {
        needClear = true;
        SetHudTextParams(-1.0, 0.785, 15.0, 9, 255, 9, 255, 0, 30.0, 0.0, 0.0);
        for(int client = 1; client <= MaxClients; ++client)
            if(IsClientInGame(client) && !IsFakeClient(client) && !IsClientSourceTV(client))
                ShowSyncHudText(client, t_hHudSync[1], "*** VAC已激活 ***");
    }
    else if(needClear)
    {
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
        Chat(client, "\x07当前地图限制Awp的使用");
        RemovePlayerItem(client, weapon);
        AcceptEntityInput(weapon, "Kill");
        return;
    }

    // force slay player who uses gaygun
    if(mg_slaygaygun.BoolValue && (strcmp(classname, "weapon_scar20") == 0 || strcmp(classname, "weapon_g3sg1") == 0))
    {
        ForcePlayerSuicide(client);
        ChatAll("\x0B%N\x01使用\x09连狙\x01时遭遇天谴", client);
        AcceptEntityInput(weapon, "Kill");
        return;
    }

    // fix ammo */1
    int amtype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");

    if(amtype == -1)
        return;

    SetEntProp(client, Prop_Send, "m_iAmmo", 233, _, amtype);
}

void Games_OnPlayerRunCmd(int client)
{
    if(!IsPlayerAlive(client))
        return;

    if(!sv_enablebunnyhopping.BoolValue)
        return;

    // limit pref speed
    Games_LimitPreSpeed(client, view_as<bool>(GetEntityFlags(client) & FL_ONGROUND));
}

// code from KZTimer by 1NutWunDeR -> https://github.com/1NutWunDeR/KZTimerOffical
static void Games_LimitPreSpeed(int client, bool bOnGround)
{
    static bool IsOnGround[MAXPLAYERS+1];

    if(bOnGround)
    {
        if(!IsOnGround[client])
        {
            float CurVelVec[3];
            GetEntPropVector(client, Prop_Data, "m_vecVelocity", CurVelVec);
            
            float speedlimit = mg_bhopspeed.FloatValue;

            IsOnGround[client] = true;    
            if(GetVectorLength(CurVelVec) > speedlimit)
            {
                NormalizeVector(CurVelVec, CurVelVec);
                ScaleVector(CurVelVec, speedlimit);
                TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, CurVelVec);
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

void Games_OnRoundStart()
{
    t_iWallHackCD = RoundToCeil(mg_wallhack_delay.FloatValue);

    // init round timer
    if(t_tRoundTimer != null)
        KillTimer(t_tRoundTimer);
    t_tRoundTimer = CreateTimer(1.0, Games_RoundTimer, _, TIMER_REPEAT);
}

public Action Games_RoundTimer(Handle timer)
{
    // wallhack timer
    if(t_iWallHackCD > 0)
    {
        t_iWallHackCD--;
        if(t_iWallHackCD == 0)
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