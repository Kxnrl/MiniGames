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


static int t_iWallHackCD = -1;
static Handle t_hndlHudSync = null;
static Handle t_tRoundTimer = null;

void Games_OnMapStart()
{
    if(t_hndlHudSync == null)
        t_hndlHudSync = CreateHudSynchronizer();

    CreateTimer(1.0, Games_UpdateGameHUD, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Games_UpdateGameHUD(Handle timer)
{
    static bool needClear;
    if(t_iWallHackCD > 0)
    {
        needClear = true;
        SetHudTextParams(-1.0, 0.785, 2.0, 9, 255, 9, 255, 0, 30.0, 0.0, 0.0);
        for(int client = 1; client <= MaxClients; ++client)
            if(IsClientInGame(client))
                ShowSyncHudText(client, t_hndlHudSync, ">>>距离VAC还有%d秒<<<", t_iWallHackCD);
    }
    else if(t_iWallHackCD != -1)
    {
        needClear = true;
        SetHudTextParams(-1.0, 0.785, 15.0, 9, 255, 9, 255, 0, 30.0, 0.0, 0.0);
        for(int client = 1; client <= MaxClients; ++client)
            if(IsClientInGame(client))
                ShowSyncHudText(client, t_hndlHudSync, "VAC-WH作弊器已激活");
    }
    else if(needClear)
    {
        for(int client = 1; client <= MaxClients; ++client)
            if(IsClientInGame(client))
                ClearSyncHud(client, t_hndlHudSync);
    }

    return Plugin_Continue;
}

void Games_OnMapEnd()
{
    if(t_hndlHudSync != null)
        CloseHandle(t_hndlHudSync);
    t_hndlHudSync = null;

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

    int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
    // ignore knife, grenade and special item
    if(500 <= index <= 515 || 42 < index < 50 || index == 0)
        return;

    char classname[32];
    GetWeaponClassname(weapon, index, classname, 32);
    // ignore taser
    if(StrContains(classname, "taser", false) != -1)
        return;

    if(mg_restrictawp.BoolValue && strcmp(classname, "weapon_awp") == 0)
    {
        Chat(client, "\x07当前地图限制Awp的使用");
        RemovePlayerItem(client, weapon);
        AcceptEntityInput(weapon, "Kill");
        return;
    }

    if(mg_slaygaygun.BoolValue && (strcmp(classname, "weapon_scar20") == 0 || strcmp(classname, "weapon_g3sg1") == 0))
    {
        ForcePlayerSuicide(client);
        ChatAll("\x0B%N\x01使用\x09连狙\x01时遭遇天谴", client);
        AcceptEntityInput(weapon, "Kill");
        return;
    }

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

    Games_LimitPreSpeed(client, view_as<bool>(GetEntityFlags(client) & FL_ONGROUND));
}

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

    SetEntProp(client, Prop_Send, "m_iHideHUD", 1<<12);
    SetEntProp(client, Prop_Send, "m_iAccount", 23333);
    SetEntPropFloat(client, Prop_Send, "m_flDetectedByEnemySensorTime", 0.0);

    if(!IsPlayerAlive(client))
        return Plugin_Stop;

    SetEntProp(client, Prop_Send, "m_ArmorValue", mg_spawn_kevlar.IntValue);
    SetEntProp(client, Prop_Send, "m_bHasHelmet", mg_spawn_helmet.IntValue);

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

    if(t_tRoundTimer != null)
        KillTimer(t_tRoundTimer);
    t_tRoundTimer = CreateTimer(1.0, Games_RoundTimer, _, TIMER_REPEAT);
}

public Action Games_RoundTimer(Handle timer)
{
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