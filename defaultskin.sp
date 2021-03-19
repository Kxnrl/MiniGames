#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <store>
#include <minigames>

#undef REQUIRE_PLUGIN
#include <fys.pupd>
#define REQUIRE_PLUGIN

#define PI_NAME     "MiniGames - Default player skins"
#define PI_AUTHOR   "Kyle 'Kxnrl' Frankiss"
#define PI_DESC     "DARLING in the FRANXX"
#define PI_VERSION  "2.1." ... MYBUILD
#define PI_URL      "https://github.com/Kxnrl/MiniGames"

public Plugin myinfo = 
{
    name        = PI_NAME,
    author      = PI_AUTHOR,
    description = PI_DESC,
    version     = PI_VERSION,
    url         = PI_URL
};

char g_szDefaultSkin[] = "models/player/custom_player/fys/loligh/loligh_v4.mdl";
char g_szDefaultArms[] = "models/player/custom_player/fys/loligh/loligh_arms_fbi.mdl";

public void Pupd_OnCheckAllPlugins()
{
    Pupd_CheckPlugin(false, "https://build.kxnrl.com/updater/MiniGames/");
}

public void OnMapStart()
{
    PrecacheModel(g_szDefaultSkin, false);
    PrecacheModel(g_szDefaultArms, false);
}

// Terriorst/Zombie = 0; Counter-Terriorst/Human = 1;
public bool Store_OnPlayerSkinDefault(int client, int team, char[] skin, int skinLen, char[] arms, int armsLen)
{
    strcopy(arms, armsLen, g_szDefaultArms);
    strcopy(skin, skinLen, g_szDefaultSkin);

    RefreshRender(client);

    return true;
}

public Action MG_OnRenderModelColor(int client)
{
    char model[128];
    GetClientModel(client, model, 128);

    if (strcmp(model, g_szDefaultSkin) == 0)
    {
        RefreshRender(client);
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}

void RefreshRender(int client)
{
    switch (GetClientTeam(client))
    {
        case 2: SetEntityRenderColor(client, 255, 0, 0, 255);
        case 3: SetEntityRenderColor(client, 0, 0, 255, 255);
    }
}