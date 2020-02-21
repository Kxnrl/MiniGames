/******************************************************************/
/*                                                                */
/*                         MiniGames Core                         */
/*                                                                */
/*                                                                */
/*  File:          global.h.inc                                   */
/*  Description:   MiniGames Game Mod.                            */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2018  Kyle                                      */
/*  2018/03/05 16:51:01                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/


#define PI_NAME     "MiniGames - Core"
#define PI_AUTHOR   "Kyle 'Kxnrl' Frankiss"
#define PI_DESC     "DARLING in the FRANXX"
#define PI_VERSION  "1.9." ... MYBUILD
#define PI_URL      "https://github.com/Kxnrl/MiniGames"

public Plugin myinfo = 
{
    name        = PI_NAME,
    author      = PI_AUTHOR,
    description = PI_DESC,
    version     = PI_VERSION,
    url         = PI_URL
};

// enum
enum struct stats_t
{
    int m_iKills;
    int m_iDeaths;
    int m_iAssists;
    int m_iHits;
    int m_iShots;
    int m_iHeadshots;
    int m_iKnifeKills;
    int m_iTaserKills;
    int m_iGrenadeKills;
    int m_iMolotovKills;
    int m_iTotalDamage;
    int m_iSurvivals;
    int m_iPlayRounds;
    int m_iTotalScores;
    int m_iTotalOnline;

    void Reset()
    {
        this.m_iKills         = 0;
        this.m_iDeaths        = 0;
        this.m_iAssists       = 0;
        this.m_iHits          = 0;
        this.m_iShots         = 0;
        this.m_iHeadshots     = 0;
        this.m_iKnifeKills    = 0;
        this.m_iTaserKills    = 0;
        this.m_iGrenadeKills  = 0;
        this.m_iMolotovKills  = 0;
        this.m_iTotalDamage   = 0;
        this.m_iSurvivals     = 0;
        this.m_iPlayRounds    = 0;
        this.m_iTotalScores   = 0;
        this.m_iTotalOnline   = 0;
    }
}

// staic var
char g_szBlockRadio[27][16] = {"kill", "explode", "coverme", "takepoint", "holdpos", "regroup", "followme", "takingfire", "go", "fallback", "sticktog", "getinpos", "stormfront", "report", "roger", "enemyspot", "needbackup", "sectorclear", "inposition", "reportingin","getout", "negative", "enemydown", "cheer", "thanks", "nice", "compliment"};

// library 
bool g_smxStore;
bool g_smxMapMuisc;
bool g_extGeoIP2;
bool g_extA2SFirewall;

// forwards
GlobalForward g_fwdOnRandomTeam;
GlobalForward g_fwdOnVacEnabled;
GlobalForward g_fwdOnRandomTeamPlayer;
GlobalForward g_fwdOnRenderModelColor;

// options
enum kOptions
{
    kO_HudSpec = 0,
    kO_HudVac,
    kO_HudSpeed,
    kO_HudHurt,
    kO_HudChat,
    kO_HudText,
    kO_Transmit,
}
#define kO_MaxOptions 7
bool g_kOptions[MAXPLAYERS+1][kO_MaxOptions];

// temp
native bool A2SFirewall_IsClientChecked(int client);
native void A2SFirewall_GetClientTicket(int client, char[] ticket, int maxLen);

char g_szTicket[MAXPLAYERS+1][32];

int g_iMoveChild[2048];

// vars
Database g_hMySQL  = null;

int g_iTeam[MAXPLAYERS+1];
int g_iUId[MAXPLAYERS+1];

int g_offsetNoBlock = -1;
int g_GamePlayers = 0;

char g_szMap[128];

// convars
ConVar mg_geoiplanguage             = null;
ConVar mg_transmitblock             = null;

ConVar sv_enablebunnyhopping        = null;
ConVar mp_damage_headshot_only      = null;

ConVar mg_bhopspeed                 = null;
ConVar mg_restrictawp               = null;
ConVar mg_slaygaygun                = null;
ConVar mg_spawn_knife               = null;
ConVar mg_spawn_pistol              = null;
ConVar mg_spawn_kevlar              = null;
ConVar mg_spawn_helmet              = null;
ConVar mg_randomteam                = null;
ConVar mg_wallhack_delay            = null;
ConVar mg_render_player             = null;

ConVar mg_bonus_kill_via_gun        = null;
ConVar mg_bonus_kill_via_gun_hs     = null;
ConVar mg_bonus_kill_via_knife      = null;
ConVar mg_bonus_kill_via_taser      = null;
ConVar mg_bonus_kill_via_inferno    = null;
ConVar mg_bonus_kill_via_grenade    = null;
ConVar mg_bonus_kill_via_dodge      = null;
ConVar mg_bonus_survival            = null;
ConVar mg_bonus_assist              = null;
ConVar mg_bonus_requires_players    = null;

ConVar phys_pushscale               = null;
ConVar cs_enable_player_physics_box = null;


// stock functions
stock void Chat(int client, const char[] buffer, any ...)
{
    if (g_kOptions[client][kO_HudChat])
        return;

    char msg[256];
    VFormat(msg, 256, buffer, 3);
    ProcessColorString(msg, 256);

    Protobuf SayText2 = view_as<Protobuf>(StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));
    if (SayText2 == null)
    {
        LogError("StartMessageAll -> SayText2 is null");
        return;
    }

    SayText2.SetInt("ent_idx", 0);
    SayText2.SetBool("chat", true); // force trigger sound and console log
    SayText2.SetString("msg_name", msg);
    SayText2.AddString("params", "");
    SayText2.AddString("params", "");
    SayText2.AddString("params", "");
    SayText2.AddString("params", "");
    EndMessage();
}

stock void ChatAll(const char[] buffer, any ...)
{
    char msg[256];
    for(int client = 1; client <= MaxClients; ++client)
        if (ClientValid(client) && !g_kOptions[client][kO_HudChat])
        {
            SetGlobalTransTarget(client);
            VFormat(msg, 256, buffer, 2);
            ProcessColorString(msg, 256);

            Protobuf SayText2 = view_as<Protobuf>(StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));
            if (SayText2 == null)
            {
                LogError("StartMessageOne -> SayText2 is null");
                continue;
            }

            SayText2.SetInt("ent_idx", 0);
            SayText2.SetBool("chat", true);
            SayText2.SetString("msg_name", msg);
            SayText2.AddString("params", "");
            SayText2.AddString("params", "");
            SayText2.AddString("params", "");
            SayText2.AddString("params", "");
            EndMessage();
        }

    SetGlobalTransTarget(LANG_SERVER);
}

stock int ProcessColorString(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{normal}",      "\x01", false);
    ReplaceString(message, maxLen, "{default}",     "\x01", false);
    ReplaceString(message, maxLen, "{white}",       "\x01", false);
    ReplaceString(message, maxLen, "{darkred}",     "\x02", false);
    ReplaceString(message, maxLen, "{pink}",        "\x03", false);
    ReplaceString(message, maxLen, "{green}",       "\x04", false);
    ReplaceString(message, maxLen, "{lime}",        "\x05", false);
    ReplaceString(message, maxLen, "{yellow}",      "\x05", false);
    ReplaceString(message, maxLen, "{lightgreen}",  "\x06", false);
    ReplaceString(message, maxLen, "{lightred}",    "\x07", false);
    ReplaceString(message, maxLen, "{red}",         "\x07", false);
    ReplaceString(message, maxLen, "{gray}",        "\x08", false);
    ReplaceString(message, maxLen, "{grey}",        "\x08", false);
    ReplaceString(message, maxLen, "{olive}",       "\x09", false);
    ReplaceString(message, maxLen, "{orange}",      "\x10", false);
    ReplaceString(message, maxLen, "{silver}",      "\x0A", false);
    ReplaceString(message, maxLen, "{lightblue}",   "\x0B", false);
    ReplaceString(message, maxLen, "{blue}",        "\x0C", false);
    ReplaceString(message, maxLen, "{purple}",      "\x0E", false);
    ReplaceString(message, maxLen, "{darkorange}",  "\x0F", false);

    return Format(message, maxLen, "[\x04MG\x01]   %s", message);
}

stock int GetWeaponClassname(int weapon, int index, char[] classname, int maxLen)
{
    GetEdictClassname(weapon, classname, maxLen);
    switch(index)
    {
        case 42 : return strcopy(classname, maxLen, "weapon_knife");
        case 59 : return strcopy(classname, maxLen, "weapon_knife_t");
        case 60 : return strcopy(classname, maxLen, "weapon_m4a1_silencer");
        case 61 : return strcopy(classname, maxLen, "weapon_usp_silencer");
        case 63 : return strcopy(classname, maxLen, "weapon_cz75a");
        case 64 : return strcopy(classname, maxLen, "weapon_revolver");
        case 500: return strcopy(classname, maxLen, "weapon_bayonet");
        case 506: return strcopy(classname, maxLen, "weapon_knife_gut");
        case 505: return strcopy(classname, maxLen, "weapon_knife_flip");
        case 508: return strcopy(classname, maxLen, "weapon_knife_m9_bayonet");
        case 507: return strcopy(classname, maxLen, "weapon_knife_karambit");
        case 509: return strcopy(classname, maxLen, "weapon_knife_tactical");
        case 515: return strcopy(classname, maxLen, "weapon_knife_butterfly");
        case 512: return strcopy(classname, maxLen, "weapon_knife_falchion");
        case 516: return strcopy(classname, maxLen, "weapon_knife_push");
        case 514: return strcopy(classname, maxLen, "weapon_knife_survival_bowie");
    }

    return strlen(classname);
}

stock void Text(int client, const char[] buffer, any ...)
{
    if (g_kOptions[client][kO_HudText])
        return;

    char msg[256];
    VFormat(msg, 256, buffer, 3);

    Protobuf TextMsg = view_as<Protobuf>(StartMessageOne("TextMsg", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));
    if (TextMsg == null)
    {
        LogError("StartMessageOne -> TextMsg is null");
        return;
    }

    TextMsg.SetInt("msg_dst", 4);
    TextMsg.AddString("params", msg);
    TextMsg.AddString("params", "");
    TextMsg.AddString("params", "");
    TextMsg.AddString("params", "");
    TextMsg.AddString("params", "");

    EndMessage();
}

stock void TextAll(const char[] buffer, any ...)
{
    char msg[256];
    for(int client = 1; client <= MaxClients; ++client)
        if (ClientValid(client) && !g_kOptions[client][kO_HudText])
        {
            SetGlobalTransTarget(client);
            VFormat(msg, 256, buffer, 2);

            Protobuf TextMsg = view_as<Protobuf>(StartMessageOne("TextMsg", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));
            if (TextMsg == null)
            {
                LogError("StartMessageOne -> TextMsg is null");
                continue;
            }

            TextMsg.SetInt("msg_dst", 4);
            TextMsg.AddString("params", msg);
            TextMsg.AddString("params", "");
            TextMsg.AddString("params", "");
            TextMsg.AddString("params", "");
            TextMsg.AddString("params", "");

            EndMessage();
        }

    SetGlobalTransTarget(LANG_SERVER);
}

stock int RandomInt(int min, int max)
{
    int random = GetURandomInt();

    if (random == 0)
        random++;

    return RoundToCeil(float(random) / (float(2147483647) / float(max - min + 1))) + min - 1;
}

stock void ConVar_Easy_SetInt(const char[] name, int val, bool replicate = true, bool notify = false)
{
    ConVar cvar = FindConVar(name);
    if (cvar != null)
    {
        cvar.SetInt(val, replicate, notify);
    }
}

stock void ConVar_Easy_SetFlo(const char[] name, float val, bool replicate = true, bool notify = false)
{
    ConVar cvar = FindConVar(name);
    if (cvar != null)
    {
        cvar.SetFloat(val, replicate, notify);
    }
}

stock void ConVar_Easy_SetStr(const char[] name, const char[] val, bool replicate = true, bool notify = false)
{
    ConVar cvar = FindConVar(name);
    if (cvar != null)
    {
        cvar.SetString(val, replicate, notify);
    }
}

stock bool IsWeaponKnife(const char[] weapon)
{
    return (StrContains(weapon, "knife", false) != -1 || StrContains(weapon, "bayonet", false) != -1);
}

stock bool IsWeaponTaser(const char[] weapon)
{
    return (StrContains(weapon, "taser", false) != -1);
}

stock bool IsWeaponInferno(const char[] weapon)
{
    return (StrContains(weapon, "inferno", false) != -1 || StrContains(weapon, "molotov", false) != -1 || StrContains(weapon, "incendiary", false) != -1);
}

stock bool IsWeaponGrenade(const char[] weapon)
{
    return (StrContains(weapon, "hegrenade", false) != -1);
}

stock bool IsWeaponDodgeBall(const char[] weapon)
{
    return (StrContains(weapon, "decoy", false) != -1 || StrContains(weapon, "smokegrenade", false) != -1);
}

stock void GetAlives(int &tt, int &te, int &ct)
{
    tt = 0;
    ct = 0;
    te = 0;

    for(int client = 1; client <= MaxClients; ++client)
        if (ClientValid(client) && IsPlayerAlive(client))
        {
            tt++;
            if (g_iTeam[client] == 3)
                ct++;
            else if (g_iTeam[client] == 2)
                te++;
        }
}

stock void ScopeValue(int &val, int max, int min)
{
    if (val > max) val = max;
    if (val < min) val = min;
}

stock void ResetValue(int &val, int reset, int critical)
{
    if (val == critical)
        val = reset;
}

stock bool ClientValid(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client) && !IsClientSourceTV(client));
}
