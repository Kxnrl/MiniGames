#pragma dynamic 131072
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>
#include <maoling>
#include <store>
#include <emitsoundany>
#include <cg_core>

#define PLUGIN_VERSION "1.8 - 2016/10/02"
#define PLUGIN_PREFIX "[\x0EPlaneptune\x01]  "
#define PLUGIN_PREFIX_CREDITS "\x01 \x04[Store]  "

#define sndBeacon "maoling/mg/beacon.mp3"
#define sndOverall "maoling/mg/roundbestoverall.mp3"
#define sndBeatting "maoling/ninja/ninjawin.mp3"
#define VMT_BOMBRING "materials/sprites/bomb_planted_ring.vmt"
#define VMT_HALO "materials/sprites/halo.vmt"

#define HIDE_RADAR 1 << 12

enum STAT_TYPES
{
	Kills,
	Deaths,
	Suicides,
	Taser,
	Knife,
	Score,
	Onlines
}

STAT_TYPES g_eStatistical[MAXPLAYERS+1][STAT_TYPES];
STAT_TYPES g_eSession[MAXPLAYERS+1][STAT_TYPES];

bool g_bOnDB[MAXPLAYERS+1];
bool g_bIsPA[MAXPLAYERS+1];
bool g_bAutoBhop[MAXPLAYERS+1];
bool g_bOnGround[MAXPLAYERS+1];
bool g_bClientRoundEach[MAXPLAYERS+1][MAXPLAYERS+1];

bool g_bRandomTeam;
bool g_bEnable;
bool g_bEndGame;
bool g_bBetting;
bool g_bBetTimeout;
bool g_bEndDelay;
bool g_bWarmup;

Handle g_hDB;
char g_szSignature[MAXPLAYERS+1][256];
char g_szHitName[8][32] = {"身体", "头", "胸", "肚子", "左手", "右手", "左腿", "右腿"};
char g_szClientHit[MAXPLAYERS+1][1024];
char g_szHitClient[MAXPLAYERS+1][1024];
int g_iRANK[MAXPLAYERS+1];
int g_iPAID[MAXPLAYERS+1];
int g_iClientBetPot[MAXPLAYERS+1];
int g_iClientBetTeam[MAXPLAYERS+1];
int g_iClientRoundEach[MAXPLAYERS+1];
int g_iClientRoundKill[MAXPLAYERS+1];
int g_iClientRoundScore[MAXPLAYERS+1];
int g_iClientRoundDamage[MAXPLAYERS+1];
int g_iClientRoundAssists[MAXPLAYERS+1];
int g_iClientFirstKill;
int g_iBombRing;
int g_iHalo;
int g_iReconnectDB;
int g_iBettingTotalCT;
int g_iBettingTotalTE;
int g_iCTcounts;
int g_iCThp;
int g_iTEcounts;
int g_iTEhp;
int g_iTagType;
float g_fBhopSpeed;
float g_fKD[MAXPLAYERS+1];
Handle CAVR_CT_MELEE
Handle CVAR_CT_PRIMARY;
Handle CVAR_CT_SECONDARY;
Handle CAVR_TE_MELEE
Handle CVAR_TE_PRIMARY;
Handle CVAR_TE_SECONDARY;
Handle CVAR_BHOPSPEED;
Handle CVAR_AUTOBHOP;
Handle CVAR_CHANGED;
Handle g_hTimerBeacon;
ArrayList array_players;

public Plugin myinfo = 
{
	name = " [MG] - Analytics ",
	author = "maoling ( xQy )",
	description = "Ex",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/_xQy_/"
};

public void OnPluginStart()
{
	ConnectSQL();
	
	RegConsoleCmd("sm_rank", Cmd_Rank);
	RegConsoleCmd("sm_top", Cmd_Top);
	RegConsoleCmd("sm_autojump", Cmd_Jump)
	RegConsoleCmd("sm_kill", Cmd_killme); 
	RegConsoleCmd("kill", Cmd_killme);
	RegConsoleCmd("sm_bc", Cmd_Bet);
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	
	CAVR_CT_MELEE = FindConVar("mp_ct_default_melee");
	CVAR_CT_PRIMARY = FindConVar("mp_ct_default_primary");
	CVAR_CT_SECONDARY = FindConVar("mp_ct_default_secondary");
	CAVR_TE_MELEE = FindConVar("mp_t_default_melee");
	CVAR_TE_PRIMARY = FindConVar("mp_t_default_melee");
	CVAR_TE_SECONDARY = FindConVar("mp_t_default_secondary");
	CVAR_AUTOBHOP = CreateConVar("mg_autobhop", "1", "enable bhop speed");
	CVAR_BHOPSPEED = CreateConVar("mg_bhopspeed", "250.0", "bhop sped limit");
	CVAR_CHANGED = CreateConVar("mg_randomteam", "1", "scrable team");
	
	HookConVarChange(CAVR_CT_MELEE, OnSettingChanged);
	HookConVarChange(CVAR_CT_PRIMARY, OnSettingChanged);
	HookConVarChange(CVAR_CT_SECONDARY, OnSettingChanged);
	HookConVarChange(CAVR_TE_MELEE, OnSettingChanged);
	HookConVarChange(CVAR_TE_PRIMARY, OnSettingChanged);
	HookConVarChange(CVAR_TE_SECONDARY, OnSettingChanged);
	HookConVarChange(CVAR_AUTOBHOP, OnSettingChanged);
	HookConVarChange(CVAR_BHOPSPEED, OnSettingChanged);
	HookConVarChange(CVAR_CHANGED, OnSettingChanged);
	
	array_players = new ArrayList();
	
	AutoExecConfig(true, "mg_core");
}

public void OnPluginEnd()
{
	for (int client=1; client<=MaxClients; ++client)
		if(IsClientInGame(client) && !IsFakeClient(client))
			SavePlayer(client);
}

public void OnConfigsExecuted()
{
	SetConVarInt(FindConVar("sv_damage_print_enable"), 0);
	SetConVarInt(FindConVar("sv_staminamax"), 0);
	SetConVarInt(FindConVar("sv_staminajumpcost"), 0);
	SetConVarInt(FindConVar("sv_staminalandcost"), 0);
	SetConVarInt(FindConVar("sv_staminarecoveryrate"), 0);
	SetConVarInt(FindConVar("sv_airaccelerate"), 9999);
	SetConVarInt(FindConVar("sv_accelerate_use_weapon_speed"), 0);
	SetConVarInt(FindConVar("sv_maxvelocity"), 3500);
	SetConVarInt(FindConVar("sv_full_alltalk"), 1);
	SetConVarString(CAVR_CT_MELEE, "", true, false);
	SetConVarString(CVAR_CT_PRIMARY, "", true, false);
	SetConVarString(CVAR_CT_SECONDARY, "", true, false);
	SetConVarString(CAVR_TE_MELEE, "", true, false);
	SetConVarString(CVAR_TE_PRIMARY, "", true, false);
	SetConVarString(CVAR_TE_SECONDARY, "", true, false);
	SetConVarInt(FindConVar("sv_enablebunnyhopping"), GetConVarInt(CVAR_AUTOBHOP));
	g_fBhopSpeed = GetConVarFloat(CVAR_BHOPSPEED);
	g_bRandomTeam = view_as<bool>(GetConVarInt(CVAR_CHANGED));
	
	if(g_bRandomTeam)
		SetConVarInt(FindConVar("mp_autoteambalance"), 0);
	else
		SetConVarInt(FindConVar("mp_autoteambalance"), 1);
}

public void OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	SetConVarString(CAVR_CT_MELEE, "", true, false);
	SetConVarString(CVAR_CT_PRIMARY, "", true, false);
	SetConVarString(CVAR_CT_SECONDARY, "", true, false);
	SetConVarString(CAVR_TE_MELEE, "", true, false);
	SetConVarString(CVAR_TE_PRIMARY, "", true, false);
	SetConVarString(CVAR_TE_SECONDARY, "", true, false);
	if(convar == CVAR_AUTOBHOP)
		SetConVarInt(FindConVar("sv_enablebunnyhopping"), StringToInt(newValue));
	if(convar == CVAR_BHOPSPEED)
		g_fBhopSpeed = StringToFloat(newValue);
	if(convar == CVAR_CHANGED)
	{
		g_bRandomTeam = view_as<bool>(GetConVarInt(CVAR_CHANGED));
		
		if(g_bRandomTeam)
			SetConVarInt(FindConVar("mp_autoteambalance"), 0);
		else
			SetConVarInt(FindConVar("mp_autoteambalance"), 1);
	}
}

public void OnMapStart()
{
	CreateTimer(0.2, Timer_SetClientData, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	PrecacheSoundAny(sndBeacon);
	PrecacheSoundAny(sndOverall);
	PrecacheSoundAny(sndBeatting);
	AddFileToDownloadsTable("sound/maoling/mg/beacon.mp3");
	AddFileToDownloadsTable("sound/maoling/mg/roundbestoverall.mp3");
	AddFileToDownloadsTable("sound/maoling/ninja/ninjawin.mp3");
	g_iBombRing = PrecacheModel(VMT_BOMBRING);
	g_iHalo = PrecacheModel(VMT_HALO);

	SetConVarInt(FindConVar("sv_damage_print_enable"), 0);
	SetConVarInt(FindConVar("sv_staminamax"), 0);
	SetConVarInt(FindConVar("sv_staminajumpcost"), 0);
	SetConVarInt(FindConVar("sv_staminalandcost"), 0);
	SetConVarInt(FindConVar("sv_staminarecoveryrate"), 0);
	SetConVarInt(FindConVar("sv_airaccelerate"), 9999);
	SetConVarInt(FindConVar("sv_accelerate_use_weapon_speed"), 0);
	SetConVarInt(FindConVar("sv_maxvelocity"), 3500);
	SetConVarInt(FindConVar("sv_full_alltalk"), 1);
	SetConVarString(FindConVar("sv_tags"), "CG,MG,MiniGames,MultiGames,Store", false, false);
	
	g_iTagType = 0;
	
	g_bWarmup = true;
	CreateTimer(GetConVarFloat(FindConVar("mp_warmuptime"))-1.0, Timer_Waruup, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Waruup(Handle timer)
{
	g_bWarmup = false;
	CheckPlayerCount();
}

public void OnMapEnd()
{
	if(g_hTimerBeacon != INVALID_HANDLE)
	{
		KillTimer(g_hTimerBeacon);
		g_hTimerBeacon = INVALID_HANDLE;
	}
}

public void CG_OnClientLoaded(int client)
{
	g_fKD[client] = 0.0;
	g_iClientBetPot[client] = 0;
	g_iClientBetTeam[client] = 0;

	CheckPlayerCount();
	
	if(g_hDB != INVALID_HANDLE && client)
		LoadPlayer(client);
}

public void OnClientDisconnect(int client)
{
	if(g_hDB != INVALID_HANDLE && client)
		SavePlayer(client);

	CheckPlayerCount();
	
	for(int i = 1; i <= MaxClients; ++i)
		g_bClientRoundEach[client][i] = false;

	g_iClientRoundEach[client] = 0;
	g_iClientRoundKill[client] = 0;
	g_iClientRoundScore[client] = 0;
	g_iClientRoundDamage[client] = 0;
	g_iClientRoundAssists[client] = 0;
}

public Action Event_PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	if(!g_bEnable)
		return;

	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(attacker < 1 || attacker > MaxClients)
		return;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(attacker == client || client < 1 || client > MaxClients)
		return;

	if(!g_bClientRoundEach[attacker][client])
	{
		g_bClientRoundEach[attacker][client] = true;
		g_iClientRoundEach[attacker]++;
		g_iClientRoundScore[attacker]++;
	}
	
	int damage = GetEventInt(event, "dmg_health");
	int hitgroup = GetEventInt(event, "hitgroup");
	char szWeapon[32];
	GetEventString(event, "weapon", szWeapon, 64);
	ReplaceString(szWeapon, 32, "weapon_", "", false);

	g_iClientRoundDamage[attacker] += damage;


	if(StrContains(szWeapon, "knife", false) != -1 && damage > 65)
	{
		Format(g_szHitClient[attacker], 1024, "%s\n  #受害者[%N], 伤害[%d], 部位[背刺], 武器[%s]", g_szHitClient[attacker], client, damage, szWeapon);
		Format(g_szClientHit[client], 1024, "%s\n #攻击者[%N], 伤害[%d], 部位[背刺], 武器[%s]", g_szClientHit[client], attacker, damage, szWeapon);
		
		int reqid = CG_GetReqID(attacker);
		if(reqid == 211 && damage >= 100)
		{
			CG_SetReqRate(attacker, CG_GetReqRate(attacker)+1);
			CG_CheckReq(attacker);	
		}
	}
	else
	{
		if(g_iPAID[client] == 9999)
			damage /= 2;
		Format(g_szHitClient[attacker], 1024, "%s\n  #受害者[%N], 伤害[%d], 部位[%s], 武器[%s]", g_szHitClient[attacker], client, damage, g_szHitName[hitgroup], szWeapon);
		Format(g_szClientHit[client], 1024, "%s\n  #攻击者[%N], 伤害[%d], 部位[%s], 武器[%s]", g_szClientHit[client], attacker, damage, g_szHitName[hitgroup], szWeapon);
	}
}


public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if(!g_bEnable)
		return;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsClientInGame(client))
		return;

	for(int i = 1; i <= MaxClients; ++i)
	{
		if(!IsClientInGame(i))
			continue;
		
		g_bClientRoundEach[client][i] = false;

	}
	
	g_iClientRoundEach[client] = 0;
	g_iClientRoundKill[client] = 0;
	g_iClientRoundScore[client] = 0;
	g_iClientRoundDamage[client] = 0;
	g_iClientRoundAssists[client] = 0;
	
	Format(g_szHitClient[client], 1024, "##########本局造成的伤害##########");
	Format(g_szClientHit[client], 1024, "##########本局所受的伤害##########");
	
	CreateTimer(1.0, RemoveRadar, client);
}

public Action RemoveRadar(Handle timer, any client)
{
	if(IsValidClient(client))
		SetEntProp(client, Prop_Send, "m_iHideHUD", HIDE_RADAR);
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	if(!g_bEnable)
		return;

	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsClientInGame(client))
		return;

	g_eSession[client][Deaths]++;
	//PrintToChat(client, "%s  \x0C国庆活动-火力全开 \x07>>> \x04被杀不计", PLUGIN_PREFIX);
	
	int assister = GetClientOfUserId(GetEventInt(event, "assister"));
	if(assister <= MaxClients && assister > 0 && IsClientInGame(assister))
	{
		g_iClientRoundAssists[assister]++;
		g_iClientRoundScore[assister]++;
	}

	if(client == attacker || attacker == 0)
		return;
	
	char weapon[64];
	GetEventString(event, "weapon", weapon, 64);

	g_eSession[attacker][Kills] += 1;
	g_eSession[attacker][Score] += 3;
	
	g_iClientRoundKill[attacker]++;
	g_iClientRoundScore[attacker] += 2;
	
	if(g_iClientFirstKill == 0)
		g_iClientFirstKill = attacker;


	if(StrContains(weapon, "negev", false) != -1 || StrContains(weapon, "m249", false) != -1 || StrContains(weapon, "p90", false) != -1 || StrContains(weapon, "hegrenade", false) != -1)
	{

	}
	else
	{
		Store_SetClientCredits(attacker, Store_GetClientCredits(attacker)+1, "MG-击杀玩家");
		PrintToChat(attacker, "%s \x10你击杀\x07 %N \x10获得了\x04 1 Credits", PLUGIN_PREFIX_CREDITS, client);
		
		//if(GetRandomInt(1, 100) <= 10)
		//{
		//	int iCredits = GetRandomInt(25, 100);
		//	Store_SetClientCredits(attacker, Store_GetClientCredits(attacker)+iCredits, "MG-国庆节活动");
		//	PrintToChatAll("%s \x0C国庆活动-Copycat \x07>>> \x10%N\x04击杀\x10%N\x04获得了\x0F%d\x04Credits", PLUGIN_PREFIX, attacker, client, iCredits);
		//}
	}

	if(StrContains(weapon, "knife", false) != -1)
	{
		g_eSession[attacker][Knife] += 1;
		g_eSession[attacker][Score] += 2;
	}
	if(StrContains(weapon, "taser", false) != -1)
	{
		g_eSession[attacker][Taser] += 1;
		g_eSession[attacker][Score] += 2;
		
		int reqid = CG_GetReqID(attacker);
		if(reqid == 221)
		{
			CG_SetReqRate(attacker, CG_GetReqRate(attacker)+1);
			CG_CheckReq(attacker);	
		}
	}
	
	Format(g_szHitClient[attacker], 1024, "%s\n  #你杀死了[%N], 武器[%s]", g_szHitClient[attacker], client, weapon);
	Format(g_szClientHit[client], 1024, "%s\n  #你被[%N]杀死了, 武器[%s]", g_szClientHit[client], attacker, weapon);


	if(g_bEnable && !g_bEndGame && !g_bBetting && !g_bEndDelay)
	{
		g_iCTcounts = 0;
		g_iTEcounts = 0;
		g_iCThp = 0;
		g_iTEhp = 0;
	
		for(int i = 1; i <= MaxClients; ++i)
		{
			if(IsValidClient(i))
			{
				if(IsPlayerAlive(i))
				{
					if(GetClientTeam(i) == 2)
					{
						g_iTEcounts++;
						g_iTEhp += GetClientHealth(i);
					}
	
					if(GetClientTeam(i) == 3)
					{
						g_iCTcounts++;
						g_iCThp += GetClientHealth(i);
					}
				}
			}
		}

		if(g_iTEcounts == 1 || g_iCTcounts == 1 || (g_iCTcounts == 2 && g_iTEcounts == 2))
		{
			PrintToChatAll("%s \x0F基佬相爱相杀的时刻到了\x01...", PLUGIN_PREFIX);
			g_bEndGame = true;
			g_bBetting = true;
			g_bBetTimeout = false;
			CreateTimer(15.0, Timer_Timeout);
			SetupBeacon();
			SetupBetting();
		}
	}
	
	ShowDamageAnalytics(client);
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	g_bEndGame = false;
	g_bEndDelay = true;
	
	if(g_hTimerBeacon != INVALID_HANDLE)
	{
		KillTimer(g_hTimerBeacon);
		g_hTimerBeacon = INVALID_HANDLE;
	}
	
	int winner = GetEventInt(event, "winner");
	
	if(g_bBetting && winner >= 2)
		SettlementBetting(winner);

	if(g_bRandomTeam)
		CreateTimer(2.0, Timer_RoundEndDelay, _, TIMER_FLAG_NO_MAPCHANGE);
	
	if(g_bEnable)
		CreateTimer(4.0, Timer_Delay);
	
	for(int client = 1; client <= MaxClients; ++client)
	{
		if(IsClientInGame(client))
		{
			if(IsPlayerAlive(client))
				ShowDamageAnalytics(client);
			
			int reqid = CG_GetReqID(client);
			if(reqid == 201)
			{
				CG_SetReqRate(client, CG_GetReqRate(client)+1);
				CG_CheckReq(client);	
			}
			else if(reqid == 231 && g_iClientRoundKill[client] >= 10)
			{
				CG_SetReqRate(client, 10);
				CG_CheckReq(client);
			}
		}
	}
}

public Action Timer_RoundEndDelay(Handle timer)
{	
	array_players.Clear();

	int counts;
	for(int x = 1; x <= MaxClients; ++x)
	{
		if(IsClientInGame(x))
		{
			if(GetClientTeam(x) >= 2)
			{
				counts++;
				array_players.Push(x);
			}
		}
	}
	
	if(counts <= 2)
		return;
	
	counts = RoundToNearest(counts*0.5);
	
	int client, number, team;
	while((number = RandomArray()) != -1)
	{
		client = array_players.Get(number);
		
		char buffer[128];
		if(counts > 0)
		{
			team = 2;
			counts--;
			PrintToChat(client, "%s 你已被移动到\x07恐怖分子", PLUGIN_PREFIX);
			Format(buffer, 128, "当前地图已经开启随机组队\n 你已被移动到 <font color='#FF0000' size='20'>恐怖分子");
		}
		else
		{
			team = 3;
			PrintToChat(client, "%s 你已被移动到\x0B反恐精英", PLUGIN_PREFIX);
			Format(buffer, 128, "当前地图已经开启随机组队\n 你已被移动到 <font color='#0066CC' size='20'>反恐精英");
		}
		
		if(IsPlayerAlive(client))
			CS_SwitchTeam(client, team);
		else
			ChangeClientTeam(client, team);
		
		Handle pb = StartMessageOne("HintText", client);
		PbSetString(pb, "text", buffer);
		EndMessage();
		
		RemoveFromArray(array_players, number);
	}
	
	array_players.Clear();
}

stock bool CheckTeamBalancer()
{
	int ct, t, i;
	for(int x = 1; x <= MaxClients; ++x)
	{
		if(IsClientInGame(x))
		{
			if(GetClientTeam(x) == 2)
				t++;
			
			if(GetClientTeam(x) == 3)
				ct++;
		}
	}
	
	i = ct - t;
	
	if(-1 <= i <= 1)
		return true;
	else
		return false;
}

stock RandomArray()
{
	int x = GetArraySize(array_players);
	
	if(x == 0)
		return -1;
	
	return GetRandomInt(0, x-1);
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	g_bEndGame = false;
	
	if(g_hTimerBeacon != INVALID_HANDLE)
	{
		KillTimer(g_hTimerBeacon);
		g_hTimerBeacon = INVALID_HANDLE;
	}
	
	g_bBetting = false;
	g_bBetTimeout = true;
	g_bEndDelay = false;
	g_iClientFirstKill = 0;
	g_iTagType++;
	if(g_iTagType > 3)
		g_iTagType = 0;
}

public Action Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
	SetEventBroadcast(event, true);
	
	return Plugin_Changed;
}

public Action Event_PlayerDisconnect(Handle event, const char[] name, bool dontBroadcast)
{
	SetEventBroadcast(event, true);

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	char AuthoirzedName[32], m_szMsg[512];
	PA_GetGroupName(client, AuthoirzedName, 32);
	FormatEx(m_szMsg, 512, "%s \x04%N\x01离开了游戏 \x0B认证\x01[\x0C%s\x01]  \x01排名\x04%i  \x0CK/D\x04%.2f \x0C得分\x04%i  \x01签名: \x07%s", 
							PLUGIN_PREFIX, 
							client, 
							AuthoirzedName, 
							g_iRANK[client], 
							g_fKD[client],
							g_eStatistical[client][Score],
							g_szSignature[client]
							);
	ReplaceString(m_szMsg, 512, "{白}", "\x01");
	ReplaceString(m_szMsg, 512, "{红}", "\x02");
	ReplaceString(m_szMsg, 512, "{粉}", "\x03");
	ReplaceString(m_szMsg, 512, "{绿}", "\x04");
	ReplaceString(m_szMsg, 512, "{黄}", "\x05");
	ReplaceString(m_szMsg, 512, "{亮绿}", "\x06");
	ReplaceString(m_szMsg, 512, "{亮红}", "\x07");
	ReplaceString(m_szMsg, 512, "{灰}", "\x08");
	ReplaceString(m_szMsg, 512, "{褐}", "\x09");
	ReplaceString(m_szMsg, 512, "{橙}", "\x10");
	ReplaceString(m_szMsg, 512, "{紫}", "\x0E");
	ReplaceString(m_szMsg, 512, "{亮蓝}", "\x0B");
	ReplaceString(m_szMsg, 512, "{蓝}", "\x0C");

	if(g_iRANK[client] == 0)
		PrintToChatAll("%s 萌新\x04%N\x01离开了游戏", PLUGIN_PREFIX, client);
	else
		PrintToChatAll(m_szMsg);
}

public LoadPlayer(client)
{
	g_bOnDB[client]=false;

	g_eSession[client][Kills] = 0;
	g_eSession[client][Deaths] = 0;
	g_eSession[client][Suicides] = 0;
	g_eSession[client][Knife] = 0;
	g_eSession[client][Taser] = 0;
	g_eSession[client][Score] = 0;
	g_eSession[client][Onlines] = GetTime();

	g_eStatistical[client][Kills] = 0;
	g_eStatistical[client][Deaths] = 0;
	g_eStatistical[client][Suicides] = 0;
	g_eStatistical[client][Knife] = 0;
	g_eStatistical[client][Taser] = 0;
	g_eStatistical[client][Score] = 0;
	g_eStatistical[client][Onlines] = 0;

	char auth[64];
	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));

	char query[512];
	Format(query,sizeof(query), "SELECT * FROM `rank_mg` WHERE steamid='%s' ORDER BY `id` ASC LIMIT 1;", auth);

	if(g_hDB != INVALID_HANDLE)
		SQL_TQuery(g_hDB, SQL_LoadPlayerCallback, query, GetClientUserId(client));
}

public SavePlayer(client)
{
	if(IsFakeClient(client)) 
		return;
	
	if(!g_bOnDB[client])
		return;
	
	char auth[64];
	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
	char name[64];
	GetClientName(client, name, sizeof(name));
	char sEscapeName[129];
	SQL_EscapeString(g_hDB, name, sEscapeName, sizeof(sEscapeName));
	
	g_eStatistical[client][Kills] += g_eSession[client][Kills];
	g_eStatistical[client][Deaths] += g_eSession[client][Deaths];
	g_eStatistical[client][Suicides] += g_eSession[client][Suicides];
	g_eStatistical[client][Taser] += g_eSession[client][Taser];
	g_eStatistical[client][Knife] += g_eSession[client][Knife];
	g_eStatistical[client][Score] = ((g_eStatistical[client][Kills]*3)+(g_eStatistical[client][Taser]*2)+(g_eStatistical[client][Knife]*2)-(g_eStatistical[client][Suicides]*10));
	g_eStatistical[client][Onlines] = GetTime() - g_eSession[client][Onlines] + g_eStatistical[client][Onlines];

	char query[1024];
	Format(query,sizeof(query), "UPDATE `rank_mg` SET name='%s', kills='%i', deaths='%i', suicides='%i', taser='%i', knife='%i', score='%i', onlines='%i' WHERE steamid='%s';",
								sEscapeName,
								g_eStatistical[client][Kills],
								g_eStatistical[client][Deaths],
								g_eStatistical[client][Suicides],
								g_eStatistical[client][Taser],
								g_eStatistical[client][Knife],
								g_eStatistical[client][Score],
								g_eStatistical[client][Onlines],
								auth);

	SQL_TQuery(g_hDB, SQL_SaveCallback, query, GetClientUserId(client), DBPrio_High);
	
	g_bOnDB[client] = false;
}

public SQL_LoadPlayerCallback(Handle owner, Handle hndl, const char[] error, any userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!client)
		return;
	
	if(hndl == INVALID_HANDLE)
	{
		LogError("[MG-Stats] Load Player Fail: client:%N error:%s", client, error);
		return;
	}
	
	if(!IsClientInGame(client))
		return;

	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		g_eStatistical[client][Kills] = SQL_FetchInt(hndl, 3);
		g_eStatistical[client][Deaths] = SQL_FetchInt(hndl, 4);
		g_eStatistical[client][Suicides] = SQL_FetchInt(hndl, 5);
		g_eStatistical[client][Taser] = SQL_FetchInt(hndl, 6);
		g_eStatistical[client][Knife] = SQL_FetchInt(hndl, 7);
		g_eStatistical[client][Score] = SQL_FetchInt(hndl, 8);
		g_eStatistical[client][Onlines] = SQL_FetchInt(hndl, 9);
		
		GetPlayerRank(client);
		
		g_bOnDB[client] = true;
	}
	else
	{
		char query[512];
		char name[64];
		GetClientName(client, name, sizeof(name));
		char auth[64];
		GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
		char sEscapeName[129];
		SQL_EscapeString(g_hDB, name, sEscapeName, sizeof(sEscapeName));

		Format(query, sizeof(query), "INSERT INTO `rank_mg` (steamid) VALUES ('%s')", auth);
		SQL_TQuery(g_hDB, SQL_NothingCallback , query, GetClientUserId(client), DBPrio_High);
	}
}

public SQL_NothingCallback(Handle owner, Handle hndl, const char[] error, any userid)
{
	int client = GetClientOfUserId(userid);

	if(hndl == INVALID_HANDLE)
	{	
		LogError("[MG-Stats] INSERT Fail: client:%N ERROR:%s", client, error);
		return;
	}
	
	g_bOnDB[client] = true;
}

public SQL_SaveCallback(Handle owner, Handle hndl, const char[] error, any userid)
{
	if(hndl == INVALID_HANDLE)
	{
		int client = GetClientOfUserId(userid);
		LogError("[MG-Stats] Save Player Fail:client:%N  error:%s", client, error);
		return;
	}
}

public SQL_RankCallback(Handle owner, Handle hndl, const char[] error, any userid)
{
	int client = GetClientOfUserId(userid);
	if(hndl == INVALID_HANDLE)
	{
		LogError("[MG-Stats] RankCallback:client:%N  error:%s", client, error);
		return;
	}

	if(SQL_GetRowCount(hndl))
	{
		char szSteamID[32], mySteamID[32];
		GetClientAuthId(client, AuthId_Steam2, mySteamID, 32);
		int iIndex;
		while(SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, szSteamID, 32);
			iIndex++;

			if(StrEqual(szSteamID ,mySteamID))
			{
				g_iRANK[client] = iIndex;
				CG_GetSignature(client, g_szSignature[client], 256);
				g_fKD[client] = (g_eStatistical[client][Kills]*1.0)/(g_eStatistical[client][Deaths]*1.0);
				char AuthoirzedName[32], m_szMsg[512];
				PA_GetGroupName(client, AuthoirzedName, 32);
				FormatEx(m_szMsg, 512, "%s \x04%N\x01进入了游戏 \x0B认证\x01[\x0C%s\x01]  \x01排名\x04%i  \x0CK/D\x04%.2f \x0C得分\x04%i  \x01签名: \x07%s", 
										PLUGIN_PREFIX, 
										client, 
										AuthoirzedName, 
										g_iRANK[client], 
										g_fKD[client],
										g_eStatistical[client][Score],
										g_szSignature[client]
										);
				ReplaceString(m_szMsg, 512, "{白}", "\x01");
				ReplaceString(m_szMsg, 512, "{红}", "\x02");
				ReplaceString(m_szMsg, 512, "{粉}", "\x03");
				ReplaceString(m_szMsg, 512, "{绿}", "\x04");
				ReplaceString(m_szMsg, 512, "{黄}", "\x05");
				ReplaceString(m_szMsg, 512, "{亮绿}", "\x06");
				ReplaceString(m_szMsg, 512, "{亮红}", "\x07");
				ReplaceString(m_szMsg, 512, "{灰}", "\x08");
				ReplaceString(m_szMsg, 512, "{褐}", "\x09");
				ReplaceString(m_szMsg, 512, "{橙}", "\x10");
				ReplaceString(m_szMsg, 512, "{紫}", "\x0E");
				ReplaceString(m_szMsg, 512, "{亮蓝}", "\x0B");
				ReplaceString(m_szMsg, 512, "{蓝}", "\x0C");

				if(g_iRANK[client] == 0)
					PrintToChatAll("%s 欢迎萌新\x04%N\x01来到CG娱乐休闲服务器", PLUGIN_PREFIX, client);
				else
					PrintToChatAll(m_szMsg);
				
				break;
			}
		}
	}
}

public SQL_TopCallback(Handle owner, Handle hndl, const char[] error, any userid)
{
	int client = GetClientOfUserId(userid);
	if(!client || !IsClientInGame(client))
		return;
	
	if(hndl == INVALID_HANDLE)
	{
		LogError("[MG-Stats] TopCallback:client:%N  error:%s", client, error);
		return;
	}

	int iIndex, iKill, iDeath, iScore;
	char sName[32];
	if(SQL_GetRowCount(hndl))
	{
		Handle hPack = CreateDataPack();
		WritePackCell(hPack, iIndex);
		while(SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, sName, sizeof(sName));
			iKill = SQL_FetchInt(hndl, 1);
			iDeath = SQL_FetchInt(hndl, 2);
			iScore = SQL_FetchInt(hndl, 3);

			WritePackString(hPack, sName);
			WritePackCell(hPack, iKill);
			WritePackCell(hPack, iDeath);
			WritePackCell(hPack, iScore);

			iIndex++;
		}

		ResetPack(hPack);
		WritePackCell(hPack, iIndex);
		CreateTopMenu(client, hPack);
	}
	else
		PrintToChat(client, "%s 服务器当前无RANK排行 :3", PLUGIN_PREFIX);
}

public Action Cmd_Rank(int client, int args)
{
	if(!client)
		return Plugin_Handled;
		
	PrintToChat(client, "-------------------[\x04娱乐休闲数据统计\x01]-------------------");
	PrintToChat(client, "\x01 \x04杀敌: \x07%i  \x04死亡: \x07%i  \x04自杀: \x07%i", g_eStatistical[client][Kills]+g_eSession[client][Kills], g_eStatistical[client][Deaths]+g_eSession[client][Deaths], g_eStatistical[client][Suicides]+g_eSession[client][Suicides]);
	PrintToChat(client, "\x01 \x04电死: \x07%i  \x04刀杀: \x07%i", g_eStatistical[client][Taser]+g_eSession[client][Taser], g_eStatistical[client][Knife]+g_eSession[client][Knife]);
	PrintToChat(client, "\x01 \x04得分: \x07%i  \x04K/D: \x07%.2f  \x04排名: \x07%i", g_eStatistical[client][Score]+g_eSession[client][Score], g_fKD[client], g_iRANK[client]);
	PrintToChat(client, "-------------------[\x04娱乐休闲数据统计\x01]-------------------");
	
	return Plugin_Handled;
}

public Action Cmd_Jump(int client, int args)
{
	if(!client)
		return Plugin_Handled;
		
	if(g_bAutoBhop[client])
	{
		g_bAutoBhop[client] = false;
		PrintToChat(client, "%s  自动连跳\x07已关闭", PLUGIN_PREFIX);
	}
	else
	{
		g_bAutoBhop[client] = true;
		PrintToChat(client, "%s  自动连跳\x04已开启", PLUGIN_PREFIX);
	}
	return Plugin_Handled;
}

public Action Cmd_Top(int client, int args)
{
	if(!client)
		return Plugin_Handled;
	
	char sQuery[512];
	FormatEx(sQuery, sizeof(sQuery), "SELECT `name`,`kills`,`deaths`,`score` FROM `rank_mg` WHERE `onlines` > 0 ORDER BY `score` DESC LIMIT 50;");
	SQL_TQuery(g_hDB, SQL_TopCallback, sQuery, GetClientUserId(client));

	return Plugin_Handled;
}

public Action Cmd_killme(int client, int args)
{   
	if(!client)
		return Plugin_Handled;
	
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "%s  你已经嗝屁了,还想自杀?", PLUGIN_PREFIX);
		return Plugin_Handled;
	}

	ForcePlayerSuicide(client);
	g_eSession[client][Suicides] += 1;
	g_eSession[client][Score] -= 10;
	PrintToChat(client, "%s 你自杀了,扣除了\x0710\x04Score", PLUGIN_PREFIX);
	PrintToChatAll("%s \x04%N\x07自爆菊花...", PLUGIN_PREFIX, client);

	return Plugin_Handled;        
}


public CheckPlayerCount()
{
	if(GetCurrentPlayers() < 6)
		g_bEnable = false;
	else
		g_bEnable = true;
	
	if(g_bWarmup)
		g_bEnable = false;
}

public GetCurrentPlayers()
{
	int count;
	for(int i=1;i<=MaxClients;i++)
		if(IsClientInGame(i) && !IsFakeClient(i))
			count++;
		
	return count;
}

public GetPlayerRank(client)
{
	char sQuery[512];
	FormatEx(sQuery, sizeof(sQuery), "SELECT `steamid`,`score` FROM `rank_mg` WHERE `score` >= 0 ORDER BY `score` DESC;");
	SQL_TQuery(g_hDB, SQL_RankCallback, sQuery, GetClientUserId(client));
}

CreateTopMenu(client, Handle pack)
{
	char sBuffer[256], sName[32];
	Handle hMenu = CreateMenu(MenuHandler_MenuTopPlayers);

	FormatEx(sBuffer, 256, "[CG] 娱乐休闲 Top50");
	SetMenuTitle(hMenu, sBuffer);
	
	SetMenuPagination(hMenu, 10);
	
	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, false);

	ResetPack(pack);
	int iCount = ReadPackCell(pack);
	for(int i = 0; i < iCount; i++)
	{
		ReadPackString(pack, sName, sizeof(sName));
		int iKill = ReadPackCell(pack);
		int iDeath = ReadPackCell(pack);
		int iScore = ReadPackCell(pack);
		float KD = (float(iKill) / float(iDeath));
		FormatEx(sBuffer, 256, "#%d - %s [K/D%.2f 得分%d]", i + 1, sName, KD, iScore);
		AddMenuItem(hMenu, "", sBuffer, ITEMDRAW_DISABLED);
	}
	CloseHandle(pack);
	DisplayMenu(hMenu, client, 30);
}

public MenuHandler_MenuTopPlayers(Handle menu, MenuAction action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
	}
}

public Action Timer_SetClientData(Handle timer)
{
	for(int client = 1; client <= MaxClients; ++client)
	{
		if(!IsClientInGame(client))
			continue;

		char tag[32];
		
		if(g_iTagType == 1)
			if(g_iRANK[client] == 0)
				Format(tag, 32, "Top - NORANK", g_iRANK[client]);
			else
				Format(tag, 32, "Top - %d", g_iRANK[client]);
		else if(g_iTagType == 2)
			Format(tag, 32, "K/D  %.2f", g_fKD[client]);
		else if(g_iTagType == 0)
			PA_GetGroupName(client, tag, 32);
		else
			MG_GetRankName(client, tag, 32);

		CS_SetClientClanTag(client, tag);

		int target = GetClientAimTarget(client);

		if(target > 0 && target <= MaxClients && IsClientInGame(target) && IsPlayerAlive(target))
		{
			char buffer[1024], m_szName[64], m_szAuth[64], m_szSigature[256];
			
			GetClientName(target, m_szName, 64);
			ReplaceString(m_szName, 64, "<", "〈");
			ReplaceString(m_szName, 64, ">", "〉");
			
			CG_GetSignature(target, m_szSigature, 256);
			ReplaceString(m_szSigature, 1024, "{白}", "");
			ReplaceString(m_szSigature, 1024, "{红}", "");
			ReplaceString(m_szSigature, 1024, "{粉}", "");
			ReplaceString(m_szSigature, 1024, "{绿}", "");
			ReplaceString(m_szSigature, 1024, "{黄}", "");
			ReplaceString(m_szSigature, 1024, "{亮绿}", "");
			ReplaceString(m_szSigature, 1024, "{亮红}", "");
			ReplaceString(m_szSigature, 1024, "{灰}", "");
			ReplaceString(m_szSigature, 1024, "{褐}", "");
			ReplaceString(m_szSigature, 1024, "{橙}", "");
			ReplaceString(m_szSigature, 1024, "{紫}", "");
			ReplaceString(m_szSigature, 1024, "{亮蓝}", "");
			ReplaceString(m_szSigature, 1024, "{蓝}", "");
			
			PA_GetGroupName(target, m_szAuth, 64);
			if(PA_GetGroupID(target) == 9999)
				Format(m_szAuth, 64, "<font color='#FF00FF'>%s", m_szAuth);
			else
				Format(m_szAuth, 64, "<font color='#FF8040'>%s", m_szAuth);
			
			Format(buffer, 1024, "<font color='#0066CC' size='20'>%s</font>\n认证: %s</font>   排名:<font color='#0000FF'> %d</font>   K/D:<font color='#FF0000'> %.2f</font>\n签名: <font color='#796400'>%s", m_szName, m_szAuth, g_iRANK[target], g_fKD[target], m_szSigature);
	
			Handle pb = StartMessageOne("HintText", client);
			PbSetString(pb, "text", buffer);
			EndMessage();
		}
	}
}

public Action Timer_Beacon(Handle timer, any data)
{
	CreateBeacons();

	if(g_bEndGame)
		g_hTimerBeacon = CreateTimer(2.0, Timer_Beacon);
	else
		g_hTimerBeacon = INVALID_HANDLE;
}

public PA_OnClientLoaded(int client)
{
	g_iPAID[client] = PA_GetGroupID(client);
	if(g_iPAID[client] > 1 && g_iPAID[client] != 9000 && g_iPAID[client] != 9001)
		g_bIsPA[client] = true;
	else
		g_bIsPA[client] = false;
	
	if(g_iPAID[client] == 9000 || g_iPAID[client] == 9001)
		g_bAutoBhop[client] = false;
	else
		g_bAutoBhop[client] = true;
}

void SetupBeacon()
{
	g_hTimerBeacon = CreateTimer(2.0, Timer_Beacon);
}

void CreateBeacons()
{
	for(int i=1; i<=MaxClients; ++i)
	{
		if(!IsClientInGame(i))
			continue;
		
		if(!IsPlayerAlive(i))
			continue;

		float fPos[3];
		GetClientAbsOrigin(i, fPos);
		fPos[2] += 8;

		if(PA_GetGroupID(i) == 9999)
		{
			new Clients[MaxClients];
			int index = 0;
			for(int target = 1; target <=MaxClients; ++target)
			{
				if(IsClientInGame(target) && !IsPlayerAlive(target))
				{
					Clients[index] = target;
					index++;
				}
			}
			TE_SetupBeamRingPoint(fPos, 10.0, 750.0, g_iBombRing, g_iHalo, 0, 10, 0.6, 10.0, 0.5, {255, 75, 75, 255}, 5, 0);
			TE_Send(Clients, index);
			EmitSoundToAllAny(sndBeacon, i);
		}
		else
		{
			TE_SetupBeamRingPoint(fPos, 10.0, 750.0, g_iBombRing, g_iHalo, 0, 10, 0.6, 10.0, 0.5, {255, 75, 75, 255}, 5, 0);
			TE_SendToAll();
			EmitSoundToAllAny(sndBeacon, i);
		}
	}
}

void ConnectSQL()
{
	if(g_hDB != INVALID_HANDLE)
		CloseHandle(g_hDB);
	
	g_hDB = INVALID_HANDLE;
	
	if (SQL_CheckConfig("csgo"))
		SQL_TConnect(ConnectSQLCallback, "csgo");
	else
		SetFailState("Connect to Database Failed! Error: no config entry found for 'csgo' in databases.cfg");
}

public ConnectSQLCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == INVALID_HANDLE)
	{
		g_iReconnectDB++;
		
		LogError("Connection to SQL database has failed, Try %d, Reason: %s", g_iReconnectDB, error);
		
		if(g_iReconnectDB >= 100) 
			SetFailState("PLUGIN STOPPED - Reason: can not connect to database, retry 100! - PLUGIN STOPPED");
		else if(g_iReconnectDB > 5) 
			CreateTimer(5.0, Timer_ReConnect);
		else if(g_iReconnectDB > 3)
			CreateTimer(3.0, Timer_ReConnect);
		else
			CreateTimer(1.0, Timer_ReConnect);

		return;
	}

	g_hDB = CloneHandle(hndl);

	SQL_SetCharset(g_hDB, "utf8");
	
	PrintToServer("[MG-Stats] Connection to database successful!");

	g_iReconnectDB = 1;
	
	for(int client=1; client<=MaxClients; ++client)
	{
		if(IsClientInGame(client) && !IsFakeClient(client))
		{
			PA_OnClientLoaded(client);
			CG_OnClientLoaded(client);
		}
	}
	
	CheckPlayerCount();
}

public Action Timer_ReConnect(Handle timer, any data)
{
	ConnectSQL();
	return Plugin_Stop;
}

public Action OnPlayerRunCmd(client, &buttons, &impulse, float vel[3], float angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	if(!IsValidClient(client) || !IsPlayerAlive(client))
		return Plugin_Continue;	
	
	if (GetEntityFlags(client) & FL_ONGROUND)
		g_bOnGround[client]=true;
	else
		g_bOnGround[client]=false;

	SpeedCap(client);
	ServerSidedAutoBhop(client, buttons);

	return Plugin_Continue;
}

public ServerSidedAutoBhop(client,&buttons)
{
	if(!IsValidClient(client) || !g_bAutoBhop[client])
		return;

	if(buttons & IN_JUMP)
		if(!(g_bOnGround[client]))
			if(!(GetEntityMoveType(client) & MOVETYPE_LADDER))
				if(GetEntProp(client, Prop_Data, "m_nWaterLevel") <= 1)
					buttons &= ~IN_JUMP;
}

public SpeedCap(client)
{
	static bool IsOnGround[MAXPLAYERS+1]; 

	float CurVelVec[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", CurVelVec);
	
	float speedlimit = g_fBhopSpeed;
	
	if(CG_GetClientFaith(client) == 1)
	{
		if(PA_GetGroupID(client) == 9999)
			speedlimit *= 1.15;
		else
			speedlimit *= 1.1;
	}

	if(g_bOnGround[client])
	{
		if(!IsOnGround[client])
		{
			IsOnGround[client] = true;    
			if(GetVectorLength(CurVelVec) > speedlimit)
			{
				IsOnGround[client] = true;
				NormalizeVector(CurVelVec, CurVelVec);
				ScaleVector(CurVelVec, speedlimit);
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, CurVelVec);
			}
		}
	}
	else
		IsOnGround[client] = false;	
}

public Action Cmd_Bet(int client, int args)
{
	if(!g_bBetting)
	{
		PrintToChat(client, "%s  你现在不能下注了", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	
	if(g_iClientBetPot[client] > 0)
	{
		PrintToChat(client, "%s  你已经下注了", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	
	if(Store_GetClientCredits(client) <= 2000)
	{
		PrintToChat(client, "%s  你的Credits不足", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	
	if(IsPlayerAlive(client))
	{
		PrintToChat(client, "%s  活人不能下注", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	
	if(g_bBetTimeout)
	{
		PrintToChat(client, "%s  下注时间已过,现在不能下注了", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	
	ShowBettingMenu(client);

	return Plugin_Handled;
}

void SetupBetting()
{
	for(int client = 1; client <= MaxClients; ++client)
	{
		if(IsClientInGame(client) && !IsPlayerAlive(client) && Store_GetClientCredits(client) > 2000)
			ShowBettingMenu(client);
	}
	
	//EmitSoundToAllAny(sndBeatting);
	EmitSoundToAllAny(sndBeatting, SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.6);
}

public Action Timer_Timeout(Handle timer)
{
	g_bBetTimeout = true;
}

void ShowBettingMenu(int client)
{
	Handle menu = CreateMenu(SelectTeamMenuHandler);
	char szItem[128];
	
	Format(szItem, 128, "[Planeptune]   Betting菜单\n ");
	SetMenuTitle(menu, szItem);
	
	Format(szItem, 128, "现在请你选择可能获胜的队伍");
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 128, "当前战局如下: ");
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 128, "TE[存活 %d 人 | 总HP: %d 点]", g_iTEcounts, g_iTEhp);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 128, "CT[存活 %d 人 | 总HP: %d 点]", g_iCTcounts, g_iCThp);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 128, "我选择CT获胜");
	AddMenuItem(menu, "3", szItem);
	
	Format(szItem, 128, "我选择TE获胜");
	AddMenuItem(menu, "2", szItem);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
	
	PrintToChat(client, "%s  输出!bc可以重新打开菠菜菜单", PLUGIN_PREFIX);
}

public int SelectTeamMenuHandler(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		if(!g_bBetting)
		{
			PrintToChat(client, "%s  你现在不能下注了", PLUGIN_PREFIX);
			return;
		}
		
		if(IsPlayerAlive(client))
		{
			PrintToChat(client, "%s  活人不能下注", PLUGIN_PREFIX);
			return;
		}
		
		if(g_bBetTimeout)
		{
			PrintToChat(client, "%s  下注时间已过,现在不能下注了", PLUGIN_PREFIX);
			return;
		}
		
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		g_iClientBetTeam[client] = StringToInt(info);
		
		if(g_iClientBetTeam[client] > 1)
			ShowPotMenu(client);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

void ShowPotMenu(int client)
{
	Handle menu = CreateMenu(SelectPotMenuHandler);

	SetMenuTitle(menu, "[Planeptune]   Betting菜单\n 现在请你选择下注金额 \n ");

	AddMenuItem(menu, "200", "200 Credits");
	AddMenuItem(menu, "300", "300 Credits");
	AddMenuItem(menu, "500", "500 Credits");
	AddMenuItem(menu, "1000", "1000 Credits");
	AddMenuItem(menu, "5000", "5000 Credits");
	AddMenuItem(menu, "10000", "10000 Credits");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 5);
}

public int SelectPotMenuHandler(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		if(!g_bBetting)
		{
			PrintToChat(client, "%s  你现在不能下注了", PLUGIN_PREFIX);
			return;
		}
		
		if(IsPlayerAlive(client))
		{
			PrintToChat(client, "%s  活人不能下注", PLUGIN_PREFIX);
			return;
		}
		
		if(g_bBetTimeout)
		{
			PrintToChat(client, "%s  下注时间已过,现在不能下注了", PLUGIN_PREFIX);
			return;
		}

		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		int icredits = StringToInt(info);
		
		if(Store_GetClientCredits(client) > icredits)
			g_iClientBetPot[client] = icredits
		else
		{
			PrintToChat(client, "%s  你的钱不够", PLUGIN_PREFIX);
			return;
		}

		Store_SetClientCredits(client, Store_GetClientCredits(client)-g_iClientBetPot[client], "MG-Bet下注");
		
		if(g_iClientBetTeam[client] == 2)
		{
			g_iBettingTotalTE += g_iClientBetPot[client];
			PrintToChatAll("%s  \x10%N\x01已下注\x07恐怖分子\x01[\x04%d\x01Credits]|[奖金池:\x10%dCredits]", PLUGIN_PREFIX, client, g_iClientBetPot[client], g_iBettingTotalTE);
		}

		if(g_iClientBetTeam[client] == 3)
		{
			g_iBettingTotalCT += g_iClientBetPot[client];
			PrintToChatAll("%s  \x10%N\x01已下注\x0B反恐精英\x01[\x04%d\x01Credits]|[奖金池:\x10%dCredits]", PLUGIN_PREFIX, client, g_iClientBetPot[client], g_iBettingTotalCT);
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public void SettlementBetting(int winner)
{
	if(g_iBettingTotalTE == 0 || g_iBettingTotalCT == 0 || !(2<=winner<=3))
	{
		for(new i=1;i<=MaxClients;++i)
		{
			if(IsClientInGame(i) && g_iClientBetPot[i])
				Store_SetClientCredits(i, Store_GetClientCredits(i)+g_iClientBetPot[i], "MG-菠菜");
			g_iClientBetPot[i] = 0;
			g_iClientBetTeam[i] = 0;
		}
		
		g_bBetting = false;
	
		g_iBettingTotalCT = 0;
		g_iBettingTotalTE = 0;
	
		PrintToChatAll("%s  \x10本局菠菜无效,Credits已返还", PLUGIN_PREFIX);
	
		return;
	}
	
	float m_fMultiplier;
	int vol,totalcredits,maxclient,maxcredits,icredits;
	
	if(winner == 2)
	{
		vol = g_iBettingTotalTE;
		totalcredits = RoundToFloor(g_iBettingTotalCT*0.85);
	}
		
	if(winner == 3)
	{
		vol = g_iBettingTotalCT;
		totalcredits = RoundToFloor(g_iBettingTotalTE*0.95);
	}

	for(int i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && g_iClientBetPot[i] > 0)
		{
			if(winner == g_iClientBetTeam[i])
			{
				m_fMultiplier = float(g_iClientBetPot[i])/float(vol);
				icredits = g_iClientBetPot[i]+RoundToFloor(totalcredits*m_fMultiplier);
				Store_SetClientCredits(i, Store_GetClientCredits(i)+icredits, "MG-菠菜");
				PrintToChat(i, "%s \x10你菠菜赢得了\x04 %d Credits", PLUGIN_PREFIX_CREDITS, icredits);
				
				if(icredits > maxcredits)
				{
					maxcredits = icredits;
					maxclient = i;
				}
			}
			else
			{
				PrintToChat(i, "%s \x10你菠菜输了\x04 %d Credits", PLUGIN_PREFIX_CREDITS, g_iClientBetPot[i]);
			}
			
			g_iClientBetPot[i] = 0;
			g_iClientBetTeam[i] = 0;
		}
	}
	
	if(maxcredits > 0)
		PrintToChatAll("%s  \x10本次菠菜\x04%N\x10吃了猫屎,赢得了\x04 %d Credits", PLUGIN_PREFIX, maxclient, maxcredits);
	
	g_bBetting = false;
	
	g_iBettingTotalCT = 0;
	g_iBettingTotalTE = 0;
}

public void ShowBestOverall()
{
	EmitSoundToAllAny(sndOverall);
	
	float fSort[MAXPLAYERS+1][2];
	
	char szItem[128];
	bool result;
	
	//处理技巧得分
	int iCount = 0;
	for(int i=1; i<= MaxClients;i++)
	{
		if (!IsClientInGame(i))
			continue;
		
		int team = GetClientTeam(i);
		
		if(team <= CS_TEAM_SPECTATOR) 
			continue;
		
		g_iClientRoundScore[i] += g_iClientRoundDamage[i]/100;

		fSort[iCount][0] = float(i); 
		fSort[iCount][1] = float(g_iClientRoundScore[i]);
		iCount++;
	}
	
	SortCustom2D(_:fSort, MAXPLAYERS+1, SortDataDesc_Float);
	
	int target = 0;
	iCount = 0;
	result = false;

	for(int i = 0; i <= MaxClients; i++)
	{
		target = RoundToFloor(fSort[iCount][0]);
		
		if(target == 0)
		{
			iCount++;
			continue;
		}
		
		iCount++;

		if(iCount >= 1)
		{
			if(target > 0 && target <= MaxClients)
				result = true;
			break;
		}
	}
	
	Handle menu = CreateMenu(OverallMenuHandler);
	Format(szItem, 128, "[Planeptune]   全场最佳 【%N】\n ", target);
	SetMenuTitle(menu, szItem);

	if(!result)
		Format(szItem, 128, "#最多得分 没人上榜\n ");
	else
		Format(szItem, 128, "#最多得分 %N [%dScore]\n ", target, g_iClientRoundScore[target]);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	if(g_iClientRoundScore[target] > 0 && IsValidClient(target))
	{
		Store_SetClientCredits(target, Store_GetClientCredits(target)+RoundToFloor(g_iClientRoundScore[target]*0.5), "MG-全场最佳");
		PrintToChatAll("%s   \x10全场最佳\x0C%N\x10获得了\x04%d Credits \x10奖励", PLUGIN_PREFIX, target, RoundToFloor(g_iClientRoundScore[target]*0.5));
	}
	
	target = g_iClientFirstKill;

	if(target != 0 && IsClientInGame(target))
		Format(szItem, 128, "#最先杀敌 %N\n ", target);
	else
		Format(szItem, 128, "#最先杀敌 没人上榜\n ");
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);

	//首先处理杀敌
	iCount = 0;
	for(int i=1; i<= MaxClients;i++)
	{
		if (!IsClientInGame(i))
			continue;
		
		int team = GetClientTeam(i);
		
		if(team <= CS_TEAM_SPECTATOR) 
			continue;
		
		fSort[iCount][0] = float(i); 
		fSort[iCount][1] = float(g_iClientRoundKill[i]);
		iCount++;
	}
	
	SortCustom2D(_:fSort, MAXPLAYERS+1, SortDataDesc_Float);
	
	target = 0;
	iCount = 0;

	for(int i = 0; i <= MaxClients; i++)
	{
		target = RoundToFloor(fSort[iCount][0]);
		
		if(target == 0)
		{
			iCount++;
			continue;
		}
		
		Format(szItem, 128, "#最多击杀 %N [%d杀]\n ", target, g_iClientRoundKill[target]);
		iCount++;

		if(iCount >= 1)
		{
			if(target > 0 && target <= MaxClients)
				result = true;
			break;
		}
	}

	if(!result)
		Format(szItem, 128, "#最多击杀 没人上榜\n ");
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	
	//处理攻击接触
	iCount = 0;
	for(int i=1; i<= MaxClients;i++)
	{
		if (!IsClientInGame(i))
			continue;
		
		int team = GetClientTeam(i);
		
		if(team <= CS_TEAM_SPECTATOR) 
			continue;
		
		fSort[iCount][0] = float(i); 
		fSort[iCount][1] = float(g_iClientRoundEach[i]);
		iCount++;
	}
	
	SortCustom2D(_:fSort, MAXPLAYERS+1, SortDataDesc_Float);
	
	target = 0;
	iCount = 0;
	result = false;

	for(int i = 0; i <= MaxClients; i++)
	{
		target = RoundToFloor(fSort[iCount][0]);
		
		if(target == 0)
		{
			iCount++;
			continue;
		}
		
		Format(szItem, 128, "#最多接触 %N [%d个]\n ", target, g_iClientRoundEach[target]);
		iCount++;

		if(iCount >= 1)
		{
			if(target > 0 && target <= MaxClients)
				result = true;
			break;
		}
	}

	if(!result)
		Format(szItem, 128, "#最多接触 没人上榜\n ");
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);

	
	//处理伤害输出
	iCount = 0;
	for(int i=1; i<= MaxClients;i++)
	{
		if (!IsClientInGame(i))
			continue;
		
		int team = GetClientTeam(i);
		
		if(team <= CS_TEAM_SPECTATOR) 
			continue;
		
		fSort[iCount][0] = float(i); 
		fSort[iCount][1] = float(g_iClientRoundDamage[i]);
		iCount++;
	}
	
	SortCustom2D(_:fSort, MAXPLAYERS+1, SortDataDesc_Float);
	
	target = 0;
	iCount = 0;
	result = false;

	for(int i = 0; i <= MaxClients; i++)
	{
		target = RoundToFloor(fSort[iCount][0]);
		
		if(target == 0)
		{
			iCount++;
			continue;
		}
		
		Format(szItem, 128, "#最多伤害 %N [%d点]\n ", target, g_iClientRoundDamage[target]);
		iCount++;

		if(iCount >= 1)
		{
			if(target > 0 && target <= MaxClients)
				result = true;
			break;
		}
	}

	if(!result)
		Format(szItem, 128, "#最多伤害 没人上榜\n ");
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);

	
	//处理助攻次数
	iCount = 0;
	for(int i=1; i<= MaxClients;i++)
	{
		if (!IsClientInGame(i))
			continue;
		
		int team = GetClientTeam(i);
		
		if(team <= CS_TEAM_SPECTATOR) 
			continue;
		
		fSort[iCount][0] = float(i); 
		fSort[iCount][1] = float(g_iClientRoundAssists[i]);
		iCount++;
	}
	
	SortCustom2D(_:fSort, MAXPLAYERS+1, SortDataDesc_Float);
	
	target = 0;
	iCount = 0;
	result = false;

	for(int i = 0; i <= MaxClients; i++)
	{
		target = RoundToFloor(fSort[iCount][0]);
		
		if(target == 0)
		{
			iCount++;
			continue;
		}
		
		Format(szItem, 128, "#最多助攻 %N [%d次]\n ", target, g_iClientRoundAssists[target]);
		iCount++;

		if(iCount >= 1)
		{
			if(target > 0 && target <= MaxClients)
				result = true;
			break;
		}
	}

	if(!result)
		Format(szItem, 128, "#最多助攻 没人上榜\n ");
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	

	for(int x=1; x<=MaxClients; ++x)
	{
		if(IsClientInGame(x))
		{
			SetMenuExitButton(menu, true);
			DisplayMenu(menu, x, 10);
			DisplayMenu(menu, x, 10);
		}
	}
}

public OverallMenuHandler(Handle menu, MenuAction action, client, param2)
{

}

public SortDataDesc_Float(x[], y[], array[][], Handle:data)
{
    if (Float:x[1] > Float:y[1])
        return -1;
    return Float:x[1] < Float:y[1];
}

public Action Timer_Delay(Handle timer)
{
	ShowBestOverall();
}

void ShowDamageAnalytics(client)
{
	if(!IsClientInGame(client))
		return;
	
	PrintToChat(client, "%s   你可以打开控制台查看本局你的伤害追踪", PLUGIN_PREFIX);
	PrintToConsole(client, "============================[Damage Analytics]============================");
	PrintToConsole(client, g_szClientHit[client]);
	PrintToConsole(client, g_szHitClient[client]);
	PrintToConsole(client, "==========================================================================");
}

stock void MG_GetRankName(int client, char[] buffer, int maxLen)
{
	if(g_iRANK[client] == 1)
		FormatEx(buffer, maxLen, "VAC");
	else if(g_iRANK[client] == 2)
		FormatEx(buffer, maxLen, "无敌挂逼");
	else if(g_iRANK[client] == 3)
		FormatEx(buffer, maxLen, "刷分Dog");
	else if(20 >= g_iRANK[client] > 3)
		FormatEx(buffer, maxLen, "进阶挂壁");
	else if(50 >= g_iRANK[client] > 20)
		FormatEx(buffer, maxLen, "娱乐老司机");
	else if(100 >= g_iRANK[client] > 50)
		FormatEx(buffer, maxLen, "灵车司机");
	else if(500 >= g_iRANK[client] > 100)
		FormatEx(buffer, maxLen, "初获驾照");
	else if(g_iRANK[client] == 0)
		FormatEx(buffer, maxLen, "初来乍到");
	else
		FormatEx(buffer, maxLen, "娱乐萌新");
}