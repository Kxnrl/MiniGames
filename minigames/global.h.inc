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
#define PI_VERSION  "1.4." ... MYBUILD
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
enum Analytics
{
    iKills,
    iDeaths,
    iAssists,
    iHits,
    iShots,
    iHeadshots,
    iKnifeKills,
    iTaserKills,
    iGrenadeKills,
    iMolotovKills,
    iTotalDamage,
    iSurvivals,
    iPlayRounds,
    iTotalScores,
    iTotalOnline
}

// staic var
char g_szBlockRadio[27][16] = {"kill", "explode", "coverme", "takepoint", "holdpos", "regroup", "followme", "takingfire", "go", "fallback", "sticktog", "getinpos", "stormfront", "report", "roger", "enemyspot", "needbackup", "sectorclear", "inposition", "reportingin","getout", "negative", "enemydown", "cheer", "thanks", "nice", "compliment"};

// library 
bool g_extA2SFirewall;

// temp
native bool A2SFirewall_IsClientChecked(int client);
native void A2SFirewall_GetClientTicket(int client, char[] ticket, int maxLen);

// vars
Database g_hMySQL  = null;
Handle   g_tWarmup = null;

int g_iTeam[MAXPLAYERS+1];
int g_iUId[MAXPLAYERS+1];

int g_offsetNoBlock = -1;

bool g_bLateLoad = false;

// convars
ConVar mp_warmuptime            = null;

ConVar mg_bhopspeed             = null;
ConVar mg_restrictawp           = null;
ConVar mg_slaygaygun            = null;
ConVar mg_spawn_knife           = null;
ConVar mg_spawn_pistol          = null;
ConVar mg_spawn_kevlar          = null;
ConVar mg_spawn_helmet          = null;
ConVar mg_randomteam            = null;
ConVar mg_wallhack_delay        = null;
ConVar sv_enablebunnyhopping    = null;



// stock functions
stock void Chat(int client, const char[] buffer, any ...)
{
    char msg[256];
    VFormat(msg, 256, buffer, 3);
    ProcessColorString(msg, 256);

    Protobuf SayText2 = view_as<Protobuf>(StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));
    if(SayText2 == null)
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
        if(IsClientInGame(client) && !IsFakeClient(client))
        {
            SetGlobalTransTarget(client);
            VFormat(msg, 256, buffer, 2);
            ProcessColorString(msg, 256);

            Protobuf SayText2 = view_as<Protobuf>(StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));
            if(SayText2 == null)
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

stock void ProcessColorString(char[] message, int maxLen)
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

    Format(message, maxLen, "[\x04MG\x01]   %s", message);
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
    char msg[256];
    VFormat(msg, 256, buffer, 3);
    
    Protobuf TextMsg = view_as<Protobuf>(StartMessageOne("TextMsg", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));
    if(TextMsg == null)
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
        if(IsClientInGame(client) && !IsFakeClient(client))
        {
            SetGlobalTransTarget(client);
            VFormat(msg, 256, buffer, 2);

            Protobuf TextMsg = view_as<Protobuf>(StartMessageOne("TextMsg", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));
            if(TextMsg == null)
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
    
    if(random == 0)
        random++;

    return RoundToCeil(float(random) / (float(2147483647) / float(max - min + 1))) + min - 1;
}

stock void ConVar_Easy_SetInt(const char[] name, int val, bool replicate = true, bool notify = false)
{
    ConVar cvar = FindConVar(name);
    if(cvar != null)
    {
        cvar.SetInt(val, replicate, notify);
    }
}

stock void ConVar_Easy_SetFlo(const char[] name, float val, bool replicate = true, bool notify = false)
{
    ConVar cvar = FindConVar(name);
    if(cvar != null)
    {
        cvar.SetFloat(val, replicate, notify);
    }
}

stock void ConVar_Easy_SetStr(const char[] name, const char[] val, bool replicate = true, bool notify = false)
{
    ConVar cvar = FindConVar(name);
    if(cvar != null)
    {
        cvar.SetString(val, replicate, notify);
    }
}