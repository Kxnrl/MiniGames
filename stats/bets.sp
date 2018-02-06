
void Bets_OnPluginStart()
{
    g_hBetMenu = CreateMenu(MenuHandler_BetSelectTeam);
    SetMenuTitleEx(g_hBetMenu, "[MG]   菠菜");
    SetMenuExitButton(g_hBetMenu, true);
    AddMenuItemEx(g_hBetMenu, ITEMDRAW_DISABLED, "", "现在请你选择可能获胜的队伍");
    AddMenuItemEx(g_hBetMenu, ITEMDRAW_SPACER, "", "");
    AddMenuItemEx(g_hBetMenu, ITEMDRAW_SPACER, "", "");
    AddMenuItemEx(g_hBetMenu, ITEMDRAW_SPACER, "", "");
    AddMenuItemEx(g_hBetMenu, ITEMDRAW_DEFAULT, "3", "我选择CT获胜");
    AddMenuItemEx(g_hBetMenu, ITEMDRAW_DEFAULT, "2", "我选择TE获胜");

    g_hGetMenu = CreateMenu(MenuHandler_BetSelectPot);
    SetMenuTitleEx(g_hGetMenu, "[MG]   菠菜\n 现在请你选择下注金额 \n ");
    SetMenuExitBackButton(g_hGetMenu, true)
    SetMenuExitButton(g_hGetMenu, true);
    AddMenuItemEx(g_hGetMenu, ITEMDRAW_DEFAULT, "200", "200 G");
    AddMenuItemEx(g_hGetMenu, ITEMDRAW_DEFAULT, "300", "300 G");
    AddMenuItemEx(g_hGetMenu, ITEMDRAW_DEFAULT, "500", "500 G");
    AddMenuItemEx(g_hGetMenu, ITEMDRAW_DEFAULT, "1000", "1000 G");
    AddMenuItemEx(g_hGetMenu, ITEMDRAW_DEFAULT, "5000", "5000 G");
    AddMenuItemEx(g_hGetMenu, ITEMDRAW_DEFAULT, "10000", "10000 G");
}

public int MenuHandler_BetSelectTeam(Handle menu, MenuAction action, int client, int itemNum) 
{
    if(action == MenuAction_Select) 
    {
        if(!g_bBetting)
        {
            PrintToChat(client, "%s  你现在不能下注了", PREFIX);
            return;
        }

        if(IsPlayerAlive(client))
        {
            PrintToChat(client, "%s  活人不能下注", PREFIX);
            return;
        }

        if(g_bTimeout)
        {
            PrintToChat(client, "%s  下注时间已过,现在不能下注了", PREFIX);
            return;
        }

        char info[32];
        GetMenuItem(menu, itemNum, info, 32);

        g_iBetTeam[client] = StringToInt(info);

        if(g_iBetTeam[client] > 1)
            DisplayMenu(g_hGetMenu, client, 8);
    }
    else if(action == MenuAction_Cancel)
    {
        if(IsClientInGame(client))
            PrintToChat(client, "%s  输入!bc可以重新打开菠菜菜单", PREFIX);
    }
}

public int MenuHandler_BetSelectPot(Handle menu, MenuAction action, int client, int itemNum) 
{
    if(action == MenuAction_Select) 
    {
        if(!g_bBetting)
        {
            PrintToChat(client, "%s  你现在不能下注了", PREFIX);
            return;
        }

        if(IsPlayerAlive(client))
        {
            PrintToChat(client, "%s  活人不能下注", PREFIX);
            return;
        }
        
        if(g_bTimeout)
        {
            PrintToChat(client, "%s  下注时间已过,现在不能下注了", PREFIX);
            return;
        }

        char info[32];
        GetMenuItem(menu, itemNum, info, 32);
        
        int icredits = StringToInt(info);
        
        if(MG_Shop_GetClientMoney(client) > icredits)
            g_iBetPot[client] = icredits
        else
        {
            PrintToChat(client, "%s  你的钱不够", PREFIX);
            return;
        }

        MG_Shop_ClientCostMoney(client, g_iBetPot[client], "MG-Bet下注");
        
        if(g_iBetTeam[client] == 2)
        {
            g_iBettingTotalTE += g_iBetPot[client];
            PrintToDeath("%s  \x10%N\x01已下注\x07恐怖分子\x01[\x04%d\x01G]|[奖金池:\x10%dG]", PREFIX, client, g_iBetPot[client], g_iBettingTotalTE);
        }

        if(g_iBetTeam[client] == 3)
        {
            g_iBettingTotalCT += g_iBetPot[client];
            PrintToDeath("%s  \x10%N\x01已下注\x0B反恐精英\x01[\x04%d\x01G]|[奖金池:\x10%dG]", PREFIX, client, g_iBetPot[client], g_iBettingTotalCT);
        }
    }
    else if(action == MenuAction_Cancel)
    {
        if(itemNum == MenuCancel_ExitBack)
            DisplayMenu(g_hBetMenu, client, 10);
        else
            PrintToChat(client, "%s  下注时间已过,现在不能下注了", PREFIX);
    }
}

void Bets_CheckAllow()
{
    if(g_bRoundEnding)
        return;

    if(g_bBetting)
        return;
    
    int ct, te;

    for(int i = 1; i <= MaxClients; ++i)
        if(IsClientInGame(i) && IsPlayerAlive(i))
        {
            if(GetClientTeam(i) == 2)
                if(++te > 2)
                    return;
                
            if(GetClientTeam(i) == 3)
                if(++ct > 2)
                    return;
        }

    if(ct == te && (ct == 1 || ct == 2))
    {
        g_bBetting = true;
        g_bTimeout = false;
        CreateTimer(20.0, Timer_Timeout);
        CreateTimer(2.0, Timer_Beacon, _, TIMER_REPEAT);
        SetupBetting();
    }
}

void SetupBetting()
{
    g_iBettingTotalCT = 0;
    g_iBettingTotalTE = 0;

    for(int client = 1; client <= MaxClients; ++client)
        if(IsClientInGame(client) && !IsPlayerAlive(client))
            ShowBettingMenu(client);

    //EmitSoundToAllAny("maoling/ninja/ninjawin.mp3", SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
}

void ShowBettingMenu(int client)
{
    if(!g_bBetting)
    {
        PrintToChat(client, "%s  当前没有菠菜开盘", PREFIX);
        return;
    }
    
    if(g_iBetPot[client] > 0)
    {
        PrintToChat(client, "%s  你已经下注了", PREFIX);
        return;
    }

    if(MG_Shop_GetClientMoney(client) <= 2000)
    {
        PrintToChat(client, "%s  你的G不足2000", PREFIX);
        return;
    }
    
    if(IsPlayerAlive(client))
    {
        PrintToChat(client, "%s  活人不能下注", PREFIX);
        return;
    }

    if(g_bTimeout)
    {
        PrintToChat(client, "%s  下注时间已过,现在不能下注了", PREFIX);
        return;
    }

    DisplayMenu(g_hBetMenu, client, 12);

    PrintToChat(client, "%s  输入!bc可以重新打开菠菜菜单", PREFIX);
}

void SettlementBetting(int winner)
{
    if(g_iBettingTotalTE == 0 || g_iBettingTotalCT == 0 || !(2 <= winner <= 3))
    {
        for(int i = 1; i <= MaxClients; ++i)
        {
            if(IsClientInGame(i) && g_iBetPot[i])
                MG_Shop_ClientEarnMoney(i, g_iBetPot[i], "MG-菠菜-结算退还");
            g_iBetPot[i] = 0;
            g_iBetTeam[i] = 0;
        }

        g_bBetting = false;
    
        g_iBettingTotalCT = 0;
        g_iBettingTotalTE = 0;
    
        PrintToChatAll("%s  \x10本局菠菜无效,G已返还", PREFIX);

        return;
    }

    float m_fMultiplier;
    int vol,totalcredits,maxclient,maxcredits,icredits;
    
    if(winner == 2)
    {
        vol = g_iBettingTotalTE;
        totalcredits = RoundToFloor(g_iBettingTotalCT*0.8);
    }

    if(winner == 3)
    {
        vol = g_iBettingTotalCT;
        totalcredits = RoundToFloor(g_iBettingTotalTE*0.8);
    }

    for(int i = 1; i <= MaxClients; ++i)
    {
        if(IsClientInGame(i) && g_iBetPot[i] > 0)
        {
            if(winner == g_iBetTeam[i])
            {
                m_fMultiplier = float(g_iBetPot[i])/float(vol);
                icredits = g_iBetPot[i]+RoundToFloor(totalcredits*m_fMultiplier);
                MG_Shop_ClientEarnMoney(i, icredits, "MG-菠菜-结算");
                PrintToChat(i, "%s \x10你菠菜赢得了\x04 %d G", PREFIX_STORE, icredits);
                
                if(icredits > maxcredits)
                {
                    maxcredits = icredits;
                    maxclient = i;
                }
            }
            else
                PrintToChat(i, "%s \x10你菠菜输了\x04 %d G", PREFIX_STORE, g_iBetPot[i]);

            g_iBetPot[i] = 0;
            g_iBetTeam[i] = 0;
        }
    }

    if(IsValidClient(maxclient) && maxcredits > 0)
        PrintToChatAll("%s  \x10本次菠菜\x04%N\x10吃了猫屎,赢得了\x04 %d G", PREFIX, maxclient, maxcredits);
    
    g_bBetting = false;

    g_iBettingTotalCT = 0;
    g_iBettingTotalTE = 0;
}

public Action Timer_Beacon(Handle timer)
{
    if(!g_bBetting || g_bRoundEnding)
        return Plugin_Stop;
    
    for(int i = 1; i <= MaxClients; ++i)
    {
        if(!IsClientInGame(i))
            continue;
        
        if(!IsPlayerAlive(i))
            continue;

        float fPos[3];
        GetClientAbsOrigin(i, fPos);
        fPos[2] += 8;

        if(MG_Users_UserIdentity(i) == 1)
        {
            int[] Clients = new int[MaxClients];
            int index = 0;
            for(int target = 1; target <=MaxClients; ++target)
            {
                if(IsClientInGame(target) && !IsPlayerAlive(target))
                {
                    Clients[index] = target;
                    index++;
                }
            }
            TE_SetupBeamRingPoint(fPos, 10.0, 750.0, g_iRing, g_iHalo, 0, 10, 0.6, 10.0, 0.5, {255, 75, 75, 255}, 5, 0);
            TE_Send(Clients, index);
            EmitSoundToAllAny("maoling/mg/beacon.mp3", i);
        }
        else
        {
            SetEntPropFloat(i, Prop_Send, "m_flDetectedByEnemySensorTime", 99999.0);

            TE_SetupBeamRingPoint(fPos, 10.0, 750.0, g_iRing, g_iHalo, 0, 10, 0.6, 10.0, 0.5, {255, 75, 75, 255}, 5, 0);
            TE_SendToAll();
            EmitSoundToAllAny("maoling/mg/beacon.mp3", i);
        }
    }
    
    return Plugin_Continue;
}

public Action Timer_Timeout(Handle timer)
{
    g_bTimeout = true;
    
    return Plugin_Stop;
}

void Bets_OnRoundStart()
{
    g_bRoundEnding = false;
    g_bBetting = false;
    g_bTimeout = true;
}

void Bets_OnRoundEnd(int winner)
{
    g_bRoundEnding = true;
    
    if(g_bBetting)
    {
        SettlementBetting(winner);
    }
}
