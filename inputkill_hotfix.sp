#pragma semicolon 1
#pragma newdecls required

#include <minigames>
#include <dhooks>

#define PI_NAME     "MiniGames - Input 'Kill' hotfix"
#define PI_AUTHOR   "Kyle 'Kxnrl' Frankiss"
#define PI_DESC     "DARLING in the FRANXX"
#define PI_VERSION  "1.6." ... MYBUILD
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
    Handle GameConf = LoadGameConfigFile("sdktools.games\\engine.csgo");

    if(GameConf == null)
    {
        SetFailState("Why not has gamedata?");
        return;
    }

    int offset = GameConfGetOffset(GameConf, "AcceptInput");
    AcceptInput = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, Event_AcceptInput);
    if(AcceptInput == null)
    {
        SetFailState("Failed to DHook \"AcceptInput\".");
        return;
    }

    delete GameConf;

    DHookAddParam(AcceptInput, HookParamType_CharPtr);
    DHookAddParam(AcceptInput, HookParamType_CBaseEntity);
    DHookAddParam(AcceptInput, HookParamType_CBaseEntity);
    DHookAddParam(AcceptInput, HookParamType_Object, 20);
    DHookAddParam(AcceptInput, HookParamType_Int);
}

public void OnClientPutInServer(int client)
{
    if(IsFakeClient(client))
        return;

    DHookEntity(AcceptInput, false, client);
}

public void OnClientDisconnect(int client)
{
    if(g_HookId[client] != -1)
    {
        DHookRemoveHookID(g_HookId[client]);
        g_HookId[client] = -1;
    }
}

public MRESReturn Event_AcceptInput(int pThis, Handle hReturn, Handle hParams)
{
    if(!IsValidEntity(pThis))
        return MRES_Ignored;

    char command[128];
    DHookGetParamString(hParams, 1, command, 128);

    if(strcmp(command, "Kill", false) == 0 || strcmp(command, "KillHierarchy", false) == 0)
    {
        DHookSetReturn(hReturn, false);
        return MRES_Supercede;
    }

    return MRES_Ignored;
}