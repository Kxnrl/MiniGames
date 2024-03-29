/******************************************************************/
/*                                                                */
/*                 MiniGames - Input 'Kill' hotfix                */
/*                                                                */
/*                                                                */
/*  File:          inputkill_hotfix.sp                            */
/*  Description:   MiniGames Game Mod.                            */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2023  Kyle                                      */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <minigames>
#include <dhooks>

#undef REQUIRE_PLUGIN
#include <fys.pupd>
#define REQUIRE_PLUGIN

#define PI_NAME     "MiniGames - Input 'Kill' hotfix"
#define PI_AUTHOR   "Kyle 'Kxnrl' Frankiss"
#define PI_DESC     "MiniGames Game Mod"
#define PI_VERSION  "2.2." ... MYBUILD
#define PI_URL      "https://github.com/Kxnrl/MiniGames"

public Plugin myinfo = 
{
    name        = PI_NAME,
    author      = PI_AUTHOR,
    description = PI_DESC,
    version     = PI_VERSION,
    url         = PI_URL
};

Handle AcceptInput = null;

int g_HookId[MAXPLAYERS+1] = {-1, ...};

public void OnPluginStart()
{
    GameData conf = new GameData("sdktools.games");
    if (conf == null)
        SetFailState("Failed to load gamedata.");

    int offset = conf.GetOffset("AcceptInput"); delete conf;
    if (offset == -1)
        SetFailState("Failed to get offset of \"AcceptInput\".");

    AcceptInput = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity);
    if (AcceptInput == null)
        SetFailState("Failed to DHook \"AcceptInput\".");

    delete conf;

    DHookAddParam(AcceptInput, HookParamType_CharPtr);
    DHookAddParam(AcceptInput, HookParamType_CBaseEntity);
    DHookAddParam(AcceptInput, HookParamType_CBaseEntity);
    DHookAddParam(AcceptInput, HookParamType_Object, 20);
    DHookAddParam(AcceptInput, HookParamType_Int);
}

public void Pupd_OnCheckAllPlugins()
{
    Pupd_CheckPlugin(false, "https://build.kxnrl.com/updater/MiniGames/");
}

public void OnClientPutInServer(int client)
{
    if (IsFakeClient(client))
        return;

    g_HookId[client] = DHookEntity(AcceptInput, false, client, _, Event_AcceptInput);
}

public void OnClientDisconnect(int client)
{
    if (g_HookId[client] != -1)
    {
        DHookRemoveHookID(g_HookId[client]);
        g_HookId[client] = -1;
    }
}

public MRESReturn Event_AcceptInput(int pThis, Handle hReturn, Handle hParams)
{
    if (!IsValidEntity(pThis))
        return MRES_Ignored;

    char command[128];
    DHookGetParamString(hParams, 1, command, 128);

    if (strncmp(command, "kill", 4, false) == 0)
    {
        DHookSetReturn(hReturn, false);
        return MRES_Supercede;
    }

    return MRES_Ignored;
}