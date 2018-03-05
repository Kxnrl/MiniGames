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
#define PI_VERSION  "1.0+git<commit_counts>"
#define PI_URL      "https://kxnrl.com/git/sourcepawn/MiniGames"

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

// vars
Database g_hMySQL  = null;
Handle   g_tWarmup = null;

int g_iTeam[MAXPLAYERS+1];
int g_iUId[MAXPLAYERS+1];

int g_offsetNoBlock = -1;

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
    Handle SayText2 = StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
    if(SayText2 == null)
    {
        LogError("StartMessageOne -> SayText2 is null");
        return;
    }

    char msg[256];
    VFormat(msg, 256, buffer, 2);
    Format(msg, 256, "[\x04MG\x01]   %s", msg);

    Protobuf pb = UserMessageToProtobuf(SayText2);
    pb.SetInt("ent_idx", client);
    pb.SetBool("chat", true); // force trigger sound
    pb.SetString("msg_name", msg);
    pb.AddString("params", "");
    pb.AddString("params", "");
    pb.AddString("params", "");
    pb.AddString("params", "");
    EndMessage();
}

stock void ChatAll(const char[] buffer, any ...)
{
    Handle SayText2 = StartMessageAll("SayText2", USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
    if(SayText2 == null)
    {
        LogError("StartMessageAll -> SayText2 is null");
        return;
    }
    
    char msg[256];
    VFormat(msg, 256, buffer, 2);
    Format(msg, 256, "[\x04MG\x01]   %s", msg);

    Protobuf pb = UserMessageToProtobuf(SayText2);
    pb.SetInt("ent_idx", 0);
    pb.SetBool("chat", true); // force trigger sound
    pb.SetString("msg_name", msg);
    pb.AddString("params", "");
    pb.AddString("params", "");
    pb.AddString("params", "");
    pb.AddString("params", "");
    EndMessage();
}

stock void GetWeaponClassname(int weapon, int index, char[] classname, int maxLen)
{
    GetEdictClassname(weapon, classname, maxLen);
    switch(index)
    {
        case 60: strcopy(classname, maxLen, "weapon_m4a1_silencer");
        case 61: strcopy(classname, maxLen, "weapon_usp_silencer");
        case 63: strcopy(classname, maxLen, "weapon_cz75a");
        case 64: strcopy(classname, maxLen, "weapon_revolver");
    }
}

stock int RandomArray(ArrayList array)
{
    int x = array.Length - 1;

    if(x < 0)
        return -1;

    return RandomInt(0, x);
}

stock int RandomInt(int min, int max)
{
    int random = GetURandomInt();
    
    if(random == 0)
        random++;

    return RoundToCeil(float(random) / (float(2147483647) / float(max - min + 1))) + min - 1;
}