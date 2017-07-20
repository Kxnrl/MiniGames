#include <sdktools>
#include <sdkhooks>
#include <cg_core>
#include <cstrike>

#pragma newdecls required

ConVar mg_restrictawp;
ConVar mg_slaygaygun;
ConVar mg_spawn_knife;
ConVar mg_spawn_pistol;

bool g_bRestrictAwp = false;
bool g_bSlayGaygun = true;
bool g_bNeedFixArms = false;

public Plugin myinfo =
{
	name = " MG Weapon ",
	author = "Kyle",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/_xQy_/"
};

public void OnPluginStart()
{
	RegAdminCmd("giveak47", Cmd_GiveAK47, ADMFLAG_ROOT);
	RegAdminCmd("givem4a1", Cmd_GiveM4A1, ADMFLAG_ROOT);
	RegAdminCmd("givem4a4", Cmd_GiveM4A4, ADMFLAG_ROOT);
	RegAdminCmd("giveknife", Cmd_GiveKnife, ADMFLAG_UNBAN);
	RegAdminCmd("giveusp", Cmd_GiveUSP, ADMFLAG_ROOT);
	RegAdminCmd("giveawp", Cmd_GiveAWP, ADMFLAG_ROOT);

	mg_restrictawp = CreateConVar("mg_restrictawp", "0");
	mg_slaygaygun = CreateConVar("mg_slaygaygun", "1");
	mg_spawn_knife = CreateConVar("mg_spawn_knife", "0");
	mg_spawn_pistol = CreateConVar("mg_spawn_pistol", "0");

	HookConVarChange(mg_restrictawp, OnSettingChanged);
	HookConVarChange(mg_slaygaygun, OnSettingChanged);

	for(int i = 1; i <= MaxClients; ++i)
		if(IsClientInGame(i))
			OnClientPutInServer(i);
}

public void OnPluginEnd()
{
	for(int i = 1; i <= MaxClients; ++i)
		if(IsClientInGame(i))
			OnClientDisconnect(i);
}

public void OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_bSlayGaygun = GetConVarBool(mg_slaygaygun);
	g_bRestrictAwp = GetConVarBool(mg_restrictawp);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquip);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_WeaponEquipPost, OnWeaponEquip);
}

public void OnMapStart()
{
	g_bNeedFixArms = false;
	CreateTimer(3.0, Timer_CheckWarmup, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_CheckWarmup(Handle timer)
{
	if(GameRules_GetProp("m_bWarmupPeriod") != 1)
		return Plugin_Stop;

	for(int x = MaxClients+1; x <= 2048; ++x)
	{
		if(!IsValidEdict(x))
			continue;
		
		char classname[32];
		GetEdictClassname(x, classname, 32);
		if(StrContains(classname, "weapon_") != 0)
			continue;
	
		if(GetEntProp(x, Prop_Send, "m_hPrevOwner") <= 0)
			continue;

		if(GetEntPropEnt(x, Prop_Send, "m_hOwnerEntity") > 0)
			continue;

		AcceptEntityInput(x, "Kill");
	}

	return Plugin_Continue;
}

public void CG_OnClientSpawn(int client)
{
	//RequestFrame(OnClientSpawn, client);
	CreateTimer(0.1, OnClientSpawn, client);
}

public void CG_OnRoundEnd(int winner)
{
    if(g_bNeedFixArms)
        CreateTimer(11.5, Timer_ClearWeapon);
}

public Action Timer_Slay(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(IsValidClient(client) && CG_ClientGetPId(client) != 1)
	{
		ForcePlayerSuicide(client);
		PrintToChatAll("[\x04MG\x01]  \x0B%N\x01使用\x09连狙\x01时遭遇天谴", client);
	}
}

public Action Timer_Slay2(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(IsValidClient(client))
	{
		ForcePlayerSuicide(client);
		PrintToChatAll("[\x04MG\x01]  \x0B%N\x01使用\x09某种不可描述的东西\x01时遭遇天谴", client);
	}
}

//public void OnClientSpawn(int client)
public Action OnClientSpawn(Handle timer, int client)
{
	if(!IsClientInGame(client))
		return;

	if(!IsPlayerAlive(client))
		return;
	
	SetEntProp(client, Prop_Send, "m_bHasHeavyArmor", 0);
	SetEntProp(client, Prop_Send, "m_ArmorValue", 0, 1);
	SetEntProp(client, Prop_Send, "m_bHasHelmet", 0);

	if(GetPlayerWeaponSlot(client, 2) == -1)
	{
		if(mg_spawn_knife.BoolValue)
			GivePlayerItem(client, "weapon_knife");
		else if(g_bNeedFixArms)
		{
			int decoy = GivePlayerItem(client, "weapon_decoy");
			//PrintToChat(client, "Give weapon_decoy [%d]", decoy);
			CreateTimer(0.3, Timer_RemoveKnife, EntIndexToEntRef(decoy));
		}
	}

	if(mg_spawn_pistol.BoolValue && GetPlayerWeaponSlot(client, 1) == -1)
	{
		if(GetClientTeam(client) == 2)
			GivePlayerItem(client, "weapon_glock");
		
		if(GetClientTeam(client) == 3)
			GivePlayerItem(client, "weapon_hkp2000");
	}
}

public Action CS_OnBuyCommand(int client, const char[] weapon)
{
	if(CG_ClientGetPId(client) == 1)
		return Plugin_Continue;
	
	if(StrContains(weapon, "flash", false) == -1)
		return Plugin_Continue;
	
	CreateTimer(GetRandomFloat(1.0, 3.0), Timer_Slay2, GetClientUserId(client));
	
	return Plugin_Continue;
}

public void OnWeaponEquip(int client, int weapon)
{
	if(!IsValidEdict(weapon))
		return;
	
	char classname[32];
	GetEdictClassname(weapon, classname, 32);

	if(g_bRestrictAwp && StrEqual(classname, "weapon_awp"))
	{
		PrintToChat(client, "[\x04MG\x01]  \x07当前地图限制Awp的使用");
		RequestFrame(RemoveRestriceWeapon, weapon);
	}
	
	if(g_bSlayGaygun && (StrEqual(classname, "weapon_scar20") || StrEqual(classname, "weapon_g3sg1")))
	{
		RequestFrame(RemoveRestriceWeapon, weapon);
		CreateTimer(GetRandomFloat(1.0, 3.0), Timer_Slay, GetClientUserId(client));
	}
}

public void CheckWeaponEquip(int entity)
{
	if(!IsValidEdict(entity))
		return;

	char entname[64];
	GetEntPropString(entity, Prop_Data, "m_iName", entname, 64);
	if(!StrEqual(entname, ""))
		return;

	if(GetEntProp(entity, Prop_Send, "m_hPrevOwner") != -1)
		return;

	if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") != -1)
		return;

	AcceptEntityInput(entity, "Kill");
}

public void RemoveRestriceWeapon(int entity)
{
	if(!IsValidEdict(entity))
		return;
	
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(IsValidClient(client))
		RemovePlayerItem(client, entity);

	AcceptEntityInput(entity, "Kill");
} 

public Action Cmd_GiveKnife(int client, int args)
{
	if(IsPlayerAlive(client))
		GivePlayerItem(client, "weapon_knife");
}

public Action Cmd_GiveAK47(int client, int args)
{
	if(IsPlayerAlive(client))
		GivePlayerItem(client, "weapon_ak47");
}

public Action Cmd_GiveM4A1(int client, int args)
{
	if(IsPlayerAlive(client))
		GivePlayerItem(client, "weapon_m4a1_silencer");
}

public Action Cmd_GiveM4A4(int client, int args)
{
	if(IsPlayerAlive(client))
		GivePlayerItem(client, "weapon_m4a1");
}

public Action Cmd_GiveUSP(int client, int args)
{
	if(IsPlayerAlive(client))
		GivePlayerItem(client, "weapon_hkp2000");
}

public Action Cmd_GiveAWP(int client, int args)
{
	if(IsPlayerAlive(client))
		GivePlayerItem(client, "weapon_awp");
}

bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client)) ? true : false;
}

public void OnConfigsExecuted()
{
	g_bSlayGaygun = GetConVarBool(mg_slaygaygun);
	g_bRestrictAwp = GetConVarBool(mg_restrictawp);

	char map[128];
	GetCurrentMap(map, 128);
	
	char path[128];
	Format(path, 128, "maps/%s.kv", map);
	
	Handle kv = CreateKeyValues(map);

	FileToKeyValues(kv, path);
	
	if(KvJumpToKey(kv, "t_models", false))
	{
		if(KvGotoFirstSubKey(kv, false))
		{
			char kvalue[128];
			KvGetSectionName(kv, kvalue, 128);
			if(StrContains(kvalue, "tm_anarchist") != -1 || StrContains(kvalue, "ctm_sas") != -1 || StrContains(kvalue, "ctm_fbi") != -1 || StrContains(kvalue, "ctm_swat") != -1)
			{
				g_bNeedFixArms = true;
				LogMessage("Found Kv -> %s", kvalue);
			}
		}
	}
	KvRewind(kv);

	if(KvJumpToKey(kv, "ct_models", false))
	{
		if(KvGotoFirstSubKey(kv, false))
		{
			char kvalue[128];
			KvGetSectionName(kv, kvalue, 128);
			if(StrContains(kvalue, "tm_anarchist") != -1 || StrContains(kvalue, "ctm_sas") != -1 || StrContains(kvalue, "ctm_fbi") != -1 || StrContains(kvalue, "ctm_swat") != -1)
			{
				g_bNeedFixArms = true;
				LogMessage("Found Kv -> %s", kvalue);
			}
		}
	}
	
	LogMessage("Current Maps %s -> %s Need Fix Arms", map, !g_bNeedFixArms ? "NOT" : "");

	CloseHandle(kv);
}

public Action Timer_RemoveKnife(Handle timer, int iRef)
{
	int knife = EntRefToEntIndex(iRef);
	if(!IsValidEdict(knife))
		return Plugin_Stop;
	
	int client = GetEntPropEnt(knife, Prop_Send, "m_hOwnerEntity");
	
	if(IsValidClient(client) && IsPlayerAlive(client))
		CS_DropWeapon(client, knife, true, true);
	
	AcceptEntityInput(knife, "Kill");
	
	return Plugin_Stop;
}

public Action Timer_ClearWeapon(Handle timer)
{
    char classname[32];
    for(int weapon = MaxClients+1; weapon <= 2048; ++weapon)
    {
        if(!IsValidEdict(weapon))
            continue;
        
        if(!GetEdictClassname(weapon, classname, 32))
            continue;
        
        if(StrContains(classname, "weapon_") != 0)
            continue;

        int client = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	
        if(IsValidClient(client) && IsPlayerAlive(client))
            CS_DropWeapon(client, weapon, true, true);

        AcceptEntityInput(weapon, "Kill");
    }
    
    return Plugin_Stop;
}