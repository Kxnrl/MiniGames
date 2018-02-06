
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
    UTIL_Scoreboard(client, buttons);
    
    if(!IsPlayerAlive(client))
        return Plugin_Continue;

    if(!sv_enablebunnyhopping.BoolValue)
        return Plugin_Continue;

    if(GetEntityFlags(client) & FL_ONGROUND)
        g_bOnGround[client]=true;
    else
        g_bOnGround[client]=false;

    SpeedCap(client);

    return Plugin_Continue;
}

void SpeedCap(int client)
{
    static bool IsOnGround[MAXPLAYERS+1]; 

    if(g_bOnGround[client])
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

public Action Client_SpawnPost(Handle timer, int client)
{
    if(!IsValidClient(client))
        return Plugin_Stop;

    SetEntProp(client, Prop_Send, "m_iHideHUD", HIDE_RADAR);
    SetEntProp(client, Prop_Send, "m_iAccount", 10000);
    SetEntPropFloat(client, Prop_Send, "m_flDetectedByEnemySensorTime", 0.0);
    
    g_bPunished[client] = false;

    if(!IsPlayerAlive(client))
        return Plugin_Stop;
    
    SetEntProp(client, Prop_Send, "m_bHasHeavyArmor", 0);
    SetEntProp(client, Prop_Send, "m_ArmorValue", mg_spawn_kevlar.IntValue, 1);
    SetEntProp(client, Prop_Send, "m_bHasHelmet", mg_spawn_helmet.IntValue);

    if(mg_spawn_knife.BoolValue  && GetPlayerWeaponSlot(client, 2) == -1)
        GivePlayerItem(client, "weapon_knife");

    if(mg_spawn_pistol.BoolValue && GetPlayerWeaponSlot(client, 1) == -1)
    {
        if(GetClientTeam(client) == 2)
            GivePlayerItem(client, "weapon_glock");

        if(GetClientTeam(client) == 3)
            GivePlayerItem(client, "weapon_hkp2000");
    }

    if(MG_Users_UserIdentity(client) == 1)
        return Plugin_Stop;

    int count = 0;
    g_smPunishList.GetValue(g_szAccount[client], count);
    if(Client_Bepunished(client) || Stats_AllowScourgeClient(client) || count > 0)
    {
        g_bPunished[client] = true;
        SetEntityHealth(client, 30);
        SetEntProp(client, Prop_Data, "m_iMaxHealth", 30, 4, 0);
        tPrintToChatAll("%s  \x07%N\x04因为屠虐萌新,遭受天谴", PREFIX, client);
        if(--count > 0)
            g_smPunishList.SetValue(g_szAccount[client], count, true);
    }

    g_iRoundKill[client] = 0;
    
    return Plugin_Stop;
}

public Action Client_RandomTeam(Handle timer)
{
    ArrayList array_players = CreateArray();
    
    int teams[MAXPLAYERS+1];
    int waifu[MAXPLAYERS+1];

    for(int x = 1; x <= MaxClients; ++x)
        if(IsClientInGame(x))
        {
            teams[x] = GetClientTeam(x);
            if(teams[x] <= 1)
                continue;
            PushArrayCell(array_players, x);
            waifu[x] = -2; //CG_CouplesGetPartnerIndex(x);
        }

    char buffer[128];
    int client, target, number, tindex, team, counts = RoundToNearest(GetArraySize(array_players)*0.5);
    while((number = RandomArray(array_players)) != -1)
    {
        client = GetArrayCell(array_players, number);
        RemoveFromArray(array_players, number);

        target = waifu[client];
        if(waifu[client] > 0 && (tindex = FindValueInArray(array_players, waifu[client])) != -1)
        {
            RemoveFromArray(array_players, tindex);

            if(counts > 1)
            {
                counts -= 2;
                CS_SwitchTeam(client, 2);
                CS_SwitchTeam(target, 2);
                Format(buffer, 128, "当前地图已经开启随机组队\n 你和你老婆已被移动到 <font color='#FF0000' size='20'>恐怖分子");
            }
            else
            {
                CS_SwitchTeam(client, 3);
                CS_SwitchTeam(target, 3);
                Format(buffer, 128, "当前地图已经开启随机组队\n 你和你老婆已被移动到 <font color='#0066CC' size='20'>反恐精英");
            }

            if(teams[target] != team)
                PrintCenterText(target, buffer);
        }
        else
        {
            if(counts > 0)
            {
                counts--;
                CS_SwitchTeam(client, 2);
                Format(buffer, 128, "当前地图已经开启随机组队\n 你已被移动到 <font color='#FF0000' size='20'>恐怖分子");
            }
            else
            {
                CS_SwitchTeam(client, 3);
                Format(buffer, 128, "当前地图已经开启随机组队\n 你已被移动到 <font color='#0066CC' size='20'>反恐精英");
            }
        }

        if(teams[client] != team)
            PrintCenterText(client, buffer);

        //if(target < -1)
        //    PrintToChat(client, "[\x0ECP\x01]   你没有老婆,不能享受CP的随机组队优选");
        //else if(target == -1)
        //    PrintToChat(client, "[\x0ECP\x01]   你老婆离线,不能享受CP的随机组队优选");
    }

    CloseHandle(array_players);

    return Plugin_Stop;
}

int RandomArray(ArrayList array)
{
    int x = GetArraySize(array);
    
    if(x == 0)
        return -1;
    
    return GetRandomInt(0, x-1);
}

bool Client_Bepunished(int client)
{
    int req = GetTeamClientCount(GetClientTeam(client))/2;
    if(req < 5) req = 5;
    return (g_iRoundKill[client] >= req);
}

void Client_OnRoundStart()
{
    if(g_smPunishList == null)
        g_smPunishList = new StringMap();

    ClearTimer(g_tWallHack);
    g_tWallHack = CreateTimer(mg_wallhack_delay.FloatValue, Timer_Wallhack);
}

public Action Timer_Wallhack(Handle timer)
{
    g_tWallHack = INVALID_HANDLE;
    for(int client = 1; client <= MaxClients; ++client)
        if(IsClientInGame(client) && IsPlayerAlive(client) && MG_Users_UserIdentity(client) != 1)
            SetEntPropFloat(client, Prop_Send, "m_flDetectedByEnemySensorTime", 9999999.0);
    return Plugin_Stop;
}

void Client_OnRoundEnd()
{
    if(g_tWallHack != INVALID_HANDLE)
        KillTimer(g_tWallHack);
    g_tWallHack = INVALID_HANDLE;

    if(mg_randomteam.BoolValue)
        CreateTimer(2.0, Client_RandomTeam, _, TIMER_FLAG_NO_MAPCHANGE);
}