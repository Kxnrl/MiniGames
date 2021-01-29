#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <minigames>

#undef REQUIRE_PLUGIN
#include <fys.pupd>
#define REQUIRE_PLUGIN

#define PI_NAME     "MiniGames - Button locker"
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

#define MAX_BUTTONS 32

enum struct button_t
{
    int m_HammerId;
    int m_Cooldown;
    int m_LastUsed;
    char m_Name[32];
}

int g_iButtons;
button_t g_sButtons[MAX_BUTTONS];

public void Pupd_OnCheckAllPlugins()
{
    Pupd_CheckPlugin(false, "https://build.kxnrl.com/updater/MiniGames/");
}

public void OnConfigsExecuted()
{
    g_iButtons = 0;

    LoadConfigs();
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (g_iButtons > 0 && strcmp(classname, "func_button") == 0)
        SDKHook(entity, SDKHook_SpawnPost, Event_ButtonCreated);
}

public void Event_ButtonCreated(int button)
{
    SDKUnhook(button, SDKHook_SpawnPost, Event_ButtonCreated);

    if (!IsValidEdict(button))
        return;

    int index = FindIndexByButton(GetHammerId(button));
    if (index == -1)
        return;

    HookSingleEntityOutput(button, "OnPressed", Event_OnPressed);
    SDKHook(button, SDKHook_Use, Event_ButtonUse);
}

public void Event_OnPressed(const char[] output, int button, int client, float delay)
{
    if (g_iButtons <= 0)
        return;

    if (!IsValidEdict(button))
        return;

    int index = FindIndexByButton(GetHammerId(button));
    if (index == -1)
        return;

    g_sButtons[index].m_LastUsed = GetTime();
}

public Action Event_ButtonUse(int button, int client, int caller, UseType type, float value)
{
    if (g_iButtons <= 0)
        return Plugin_Continue;

    if (!IsValidEdict(button) || !IsValid(client))
        return Plugin_Handled;

    int iOffset = FindDataMapInfo(button, "m_bLocked");

    if (iOffset != -1 && GetEntData(button, iOffset, 1))
        return Plugin_Handled;

    int index = FindIndexByButton(GetHammerId(button));

    if (index == -1)
        return Plugin_Continue;

    int time = GetTime();
    int ends = g_sButtons[index].m_LastUsed + g_sButtons[index].m_Cooldown;
    int diff = ends - time;
    if (diff > 0)
    {
        Text(client, "<font color='#39c5bb'>%s</font> 已被锁定 (剩余<font color='#ff0000'> %d </font>秒)", g_sButtons[index].m_Name, diff);
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

void LoadConfigs()
{
    char path[128];
    BuildPath(Path_SM, path, 128, "configs/buttonlocker.kv");

    if (!FileExists(path))
        return;

    KeyValues kv = new KeyValues("Locker");
    if (!kv.ImportFromFile(path))
    {
        delete kv;
        return;
    }

    char map[128];
    GetCurrentMap(map, 128);

    if (!kv.JumpToKey(map, false))
    {
        delete kv;
        return;
    }

    if (kv.GotoFirstSubKey(true))
    {
        do
        {
            g_sButtons[g_iButtons].m_HammerId = kv.GetNum("HammerId");
            g_sButtons[g_iButtons].m_Cooldown = kv.GetNum("Cooldown");
            g_sButtons[g_iButtons].m_LastUsed = 0;
            kv.GetString("Name", g_sButtons[g_iButtons].m_Name, 32);

            g_iButtons++;
        }
        while (kv.GotoNextKey(true));
    }

    kv.Rewind();
    delete kv;

    LogMessage("Load %d buttons for %s", g_iButtons, map);
}

int GetHammerId(int entity)
{
    return GetEntProp(entity, Prop_Data, "m_iHammerID");
}

int FindIndexByButton(int hammerid)
{
    for (int i = 0; i < g_iButtons; i++)
    if (g_sButtons[i].m_HammerId == hammerid)
        return i;
    return -1;
}

bool IsValid(int client, bool alive = true)
{
    if (!(1 <= client <= MaxClients))
        return false;

    if (!IsClientInGame(client))
        return false;

    if (alive && !IsPlayerAlive(client))
        return false;

    return true;
}

void Text(int client, const char[] buffer, any ...)
{
    char msg[256];
    VFormat(msg, 256, buffer, 3);

    Protobuf TextMsg = view_as<Protobuf>(StartMessageOne("TextMsg", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));
    if (TextMsg == null)
    {
        LogError("StartMessageOne -> TextMsg is null");
        return;
    }

    char text[384];
    TextMsg.SetInt("msg_dst", 4);
    TextMsg.AddString("params", "#SFUI_ContractKillStart");
    Format(text, 2048, "</font>%s                                                                                                                                                                                                                                                                ", msg);
    TextMsg.AddString("params", text);
    TextMsg.AddString("params", "");
    TextMsg.AddString("params", "");
    TextMsg.AddString("params", "");
    TextMsg.AddString("params", "");

    EndMessage();
}