/******************************************************************/
/*                                                                */
/*                         MiniGames Core                         */
/*                                                                */
/*                                                                */
/*  File:          global.h.inc                                   */
/*  Description:   MiniGames Game Mod.                            */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2020  Kyle                                      */
/*  2018/03/05 16:51:01                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/


#define PI_NAME     "MiniGames - Core"
#define PI_AUTHOR   "Kyle 'Kxnrl' Frankiss"
#define PI_DESC     "DARLING in the FRANXX"
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

#define TEAM_US 0
#define TEAM_OB 1
#define TEAM_TE 2
#define TEAM_CT 3

#define HUD_CHANNEL_MARKER 0
#define HUD_CHANNEL_VAC    1
#define HUD_CHANNEL_SPEED  2
#define HUD_CHANNEL_SPEC   5

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

enum Collision_Group_t
{
    COLLISION_GROUP_NONE,
    COLLISION_GROUP_DEBRIS,                     // Collides with nothing but world and static stuff
    COLLISION_GROUP_DEBRIS_TRIGGER,             // Same as debris, but hits triggers
    COLLISION_GROUP_INTERACTIVE_DEBRIS,         // Collides with everything except other interactive debris or debris
    COLLISION_GROUP_INTERACTIVE,                // Collides with everything except interactive debris or debris
    COLLISION_GROUP_PLAYER,
    COLLISION_GROUP_BREAKABLE_GLASS,
    COLLISION_GROUP_VEHICLE,
    COLLISION_GROUP_PLAYER_MOVEMENT,            // For HL2, same as Collision_Group_Player, for
                                                // TF2, this filters out other players and CBaseObjects
    COLLISION_GROUP_NPC,                        // Generic NPC group
    COLLISION_GROUP_IN_VEHICLE,                 // for any entity inside a vehicle
    COLLISION_GROUP_WEAPON,                     // for any weapons that need collision detection
    COLLISION_GROUP_VEHICLE_CLIP,               // vehicle clip brush to restrict vehicle movement
    COLLISION_GROUP_PROJECTILE,                 // Projectiles!
    COLLISION_GROUP_DOOR_BLOCKER,               // Blocks entities not permitted to get near moving doors
    COLLISION_GROUP_PASSABLE_DOOR,              // Doors that the player shouldn't collide with
    COLLISION_GROUP_DISSOLVING,                 // Things that are dissolving are in this group
    COLLISION_GROUP_PUSHAWAY,                   // Nonsolid on client and server, pushaway in player code

    COLLISION_GROUP_NPC_ACTOR,                  // Used so NPCs in scripts ignore the player.
    COLLISION_GROUP_NPC_SCRIPTED,               // USed for NPCs in scripts that should not collide with each other

    LAST_SHARED_COLLISION_GROUP
};

// staic var
char g_szBlockRadio[][] = {"resetteam", "spectate", "kill", "explode", "coverme", "takepoint", "holdpos", "regroup", "followme", "takingfire", "go", "fallback", "sticktog", "getinpos", "stormfront", "report", "roger", "enemyspot", "needbackup", "sectorclear", "inposition", "reportingin","getout", "negative", "enemydown", "cheer", "thanks", "nice", "compliment", "player_ping"};

// library 
bool g_smxStore;
bool g_smxMapMuisc;
bool g_extGeoIP2;
bool g_extA2SFirewall;
bool g_extTransmitManager;

// forwards
GlobalForward g_fwdOnRandomTeam;
GlobalForward g_fwdOnVacElapsed;
GlobalForward g_fwdOnVacEnabled;
GlobalForward g_fwdOnRenderModelColor;

// options
enum
{
    kO_HudSpec = 0,
    kO_HudVac,
    kO_HudSpeed,
    kO_HudHurt,
    kO_HudChat,
    kO_HudText,
    kO_Transmit,
    kO_MaxOptions
}
bool g_kOptions[MAXPLAYERS+1][kO_MaxOptions];

// temp
native bool A2SFirewall_IsClientChecked(int client);
native void A2SFirewall_GetClientTicket(int client, char[] ticket, int maxLen);

char g_szTicket[MAXPLAYERS+1][32];

// SDKCall
Handle g_hWeaponSwitch;

// vars
Database g_hMySQL  = null;

int g_iTeam[MAXPLAYERS+1];
int g_iNext[MAXPLAYERS+1];
int g_iUId[MAXPLAYERS+1];

int g_offsetNoBlock = -1;
int g_GamePlayers = 0;

char g_szMap[128];

// convars
ConVar mg_geoiplanguage             = null;
ConVar mg_transmitblock             = null;
ConVar mg_block_keybind_cj          = null;
ConVar mg_button_watcher            = null;

ConVar sv_enablebunnyhopping        = null;
ConVar mp_damage_headshot_only      = null;
ConVar mp_teammates_are_enemies     = null;

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
ConVar mg_broadcast_leave           = null;
ConVar mg_slap_after_vac            = null;
ConVar mg_rank_skillgroups          = null;

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
ConVar mg_bonus_max_round_credits   = null;

static char g_PlaceHolder[] = "                                                                                                                                                                                                                                                                ";

// stock functions
stock bool IsWarmup()
{
    return GameRules_GetProp("m_bWarmupPeriod") == 1;
}
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
        case 503: return strcopy(classname, maxLen, "weapon_knife_css");
        case 505: return strcopy(classname, maxLen, "weapon_knife_flip");
        case 506: return strcopy(classname, maxLen, "weapon_knife_gut");
        case 507: return strcopy(classname, maxLen, "weapon_knife_karambit");
        case 508: return strcopy(classname, maxLen, "weapon_knife_m9_bayonet");
        case 509: return strcopy(classname, maxLen, "weapon_knife_tactical");
        case 512: return strcopy(classname, maxLen, "weapon_knife_falchion");
        case 514: return strcopy(classname, maxLen, "weapon_knife_survival_bowie");
        case 515: return strcopy(classname, maxLen, "weapon_knife_butterfly");   
        case 516: return strcopy(classname, maxLen, "weapon_knife_push");
        case 517: return strcopy(classname, maxLen, "weapon_knife_cord");
        case 518: return strcopy(classname, maxLen, "weapon_knife_canis");
        case 519: return strcopy(classname, maxLen, "weapon_knife_ursus");
        case 520: return strcopy(classname, maxLen, "weapon_knife_gypsy_jackknife");
        case 521: return strcopy(classname, maxLen, "weapon_knife_outdoor");
        case 522: return strcopy(classname, maxLen, "weapon_knife_stiletto");
        case 523: return strcopy(classname, maxLen, "weapon_knife_widowmaker");
        case 525: return strcopy(classname, maxLen, "weapon_knife_skeleton");
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

    char text[384];
    TextMsg.SetInt("msg_dst", 4);
    TextMsg.AddString("params", "#SFUI_ContractKillStart");
    Format(text, 2048, "</font>%s%s", msg, g_PlaceHolder);
    TextMsg.AddString("params", text);
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

            char text[384];
            TextMsg.SetInt("msg_dst", 4);
            TextMsg.AddString("params", "#SFUI_ContractKillStart");
            Format(text, 2048, "</font>%s%s", msg, g_PlaceHolder);
            TextMsg.AddString("params", text);
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
            if (g_iTeam[client] == TEAM_CT)
                ct++;
            else if (g_iTeam[client] == TEAM_TE)
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

stock void EntFire(const char[] target, const char[] action, const char[] value, const float delay = 0.0)
{
    char buffer[512];
    FormatEx(buffer, 512, "OnUser1 %s:%s:%s:%.2f:1", target, action, value, delay);

    int dummy = CreateEntityByName("info_target");

    if (dummy == -1)
    {
        LogError("Failed to create entity to do ent_fire with [%s].", buffer);
        return;
    }

    DispatchSpawn(dummy);
    ActivateEntity(dummy);

    SetVariantString(buffer);
    AcceptEntityInput(dummy, "AddOutput");

    SetVariantString("OnUser2 !self:Kill::0.1:1");
    AcceptEntityInput(dummy, "AddOutput");

    AcceptEntityInput(dummy, "FireUser1");
    AcceptEntityInput(dummy, "FireUser2");
}

stock void ValidateTeamPlayers(int &cts, int &tes, int skip = -1)
{
    cts = 0, tes = 0;
    for (int i = 1; i <= MaxClients; i++) if (IsClientInGame(i) && i != skip)
    {
        switch (GetClientTeam(i))
        {
            case TEAM_CT: cts++;
            case TEAM_TE: tes++;
        }
    }
}

stock void ShuffleArray(ArrayList array)
{
    ArrayList dummy = new ArrayList();

    while (array.Length > 0)
    {
        int random = RandomInt(0, array.Length - 1);
        dummy.Push(array.Get(random));
        array.Erase(random);
    }

    while (dummy.Length > 0)
    {
        array.Push(dummy.Get(0));
        dummy.Erase(0);
    }

    delete dummy;
}

stock void PrepareSDKCalls()
{
    GameData conf = new GameData("sdkhooks.games");
    if (conf == null)
        SetFailState("Could not find sdkhooks.games gamedata");

    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "Weapon_Switch");
    // success
    PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
    // weapon
    PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
    // viewmodel
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    if ((g_hWeaponSwitch = EndPrepSDKCall()) == null)
        SetFailState("Failed to prepare SDKCall.");
}

stock void WeaponSwitchFixes(int client)
{
    int size = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
    int count = 0;

    for (int i = 0; i < size; i++)
    {
        if (GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i) != INVALID_ENT_REFERENCE)
        {
            // counting
            count++;
        }
    }

    if (count != 1)
        return;

    int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (weapon != INVALID_ENT_REFERENCE)
    {
        SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", INVALID_ENT_REFERENCE);
        SDKCall(g_hWeaponSwitch, client, weapon, 0);
    }
}

stock void ClearHudByChannel(int client, int channel)
{
    SetHudTextParams(0.0, 0.0, 0.01, 0, 0, 0, 0, 0, 0.0, 0.0, 0.0);
    ShowHudText(client, channel, "");
}