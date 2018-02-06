ConVar mp_ct_default_melee;
ConVar mp_ct_default_primary;
ConVar mp_ct_default_secondary;
ConVar mp_t_default_melee;
ConVar mp_t_default_primary;
ConVar mp_t_default_secondary;
ConVar mg_bhopspeed;
ConVar sv_enablebunnyhopping;
ConVar sv_autobunnyhopping;
ConVar mg_restrictawp;
ConVar mg_slaygaygun;
ConVar mg_spawn_knife;
ConVar mg_spawn_pistol;
ConVar mg_spawn_kevlar;
ConVar mg_spawn_helmet;
ConVar mg_randomteam;
ConVar mg_wallhack_delay;

int cs_player_manager = -1;
int g_iLvls[MAXPLAYERS+1];
int g_iRank[MAXPLAYERS+1];
float g_fKDA[MAXPLAYERS+1];
float g_fHSP[MAXPLAYERS+1];

char g_szBlockCmd[27][16] = {"kill", "explode", "coverme", "takepoint", "holdpos", "regroup", "followme", "takingfire", "go", "fallback", "sticktog", "getinpos", "stormfront", "report", "roger", "enemyspot", "needbackup", "sectorclear", "inposition", "reportingin","getout", "negative", "enemydown", "cheer", "thanks", "nice", "compliment"};
char g_szHitGroup[8][16] = {"Body", "Head", "Chest", "Stomach", "LeftHand", "RightHand", "LeftLeg", "RightLeg"};

Database g_hDatabase;
Handle g_tWarmup;

#define HIDE_RADAR 1 << 12

int g_iRoundKill[MAXPLAYERS+1];
bool g_bOnGround[MAXPLAYERS+1];

Handle g_tWallHack;
StringMap g_smPunishList;
char g_szAccount[MAXPLAYERS+1][32];
bool g_bPunished[MAXPLAYERS+1];


enum STAT_TYPES
{
    Kills,
    Deaths,
    Assists,
    Headshots,
    Taser,
    Knife,
    Survival,
    Round,
    Score,
    Onlines
}

STAT_TYPES g_eStatistical[MAXPLAYERS+1][STAT_TYPES];
STAT_TYPES g_eSession[MAXPLAYERS+1][STAT_TYPES];

Handle g_RankArray;
Handle g_hTopMenu;

bool g_bTracking;

bool g_bLoaded[MAXPLAYERS+1];

// Beacon model
int g_iRing;
int g_iHalo;

int g_iBettingTotalCT;
int g_iBettingTotalTE;

bool g_bBetting;
bool g_bTimeout;
bool g_bRoundEnding;

int g_iBetPot[MAXPLAYERS+1];
int g_iBetTeam[MAXPLAYERS+1];

Handle g_hBetMenu;
Handle g_hGetMenu;

ArrayList g_aButtonArray;