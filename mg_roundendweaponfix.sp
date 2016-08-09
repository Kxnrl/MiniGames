#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <store>

#define EF_NODRAW 32

int g_iFakeWeaponRef[MAXPLAYERS + 1];

ConVar CVAR_EnableFix;
ConVar CVAR_EnableEnd;

bool g_bWarmTime;
bool g_bEnableFix;
bool g_bEnableEnd;
bool g_bTempDisable;
bool g_bWeaponCanUse;

public void OnPluginStart()
{
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	HookEvent("round_prestart", Event_RountStart, EventHookMode_Pre);
	
	RegAdminCmd("sm_mgfix", Cmd_Fix, ADMFLAG_BAN);
	
	CVAR_EnableFix = CreateConVar("mg_noweaponfix", "1");
	CVAR_EnableEnd = CreateConVar("mg_roundendfix", "1");
	g_bEnableFix = GetConVarBool(CVAR_EnableFix);
	g_bEnableEnd = GetConVarBool(CVAR_EnableEnd);
	HookConVarChange(CVAR_EnableFix, OnSettingChanged);
	HookConVarChange(CVAR_EnableEnd, OnSettingChanged);
	
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(IsValidClient(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public OnMapStart()
{
	g_bWarmTime = true;
	g_bWeaponCanUse = true;
	CreateTimer(91.0, Timer_End, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_End(Handle timer)
{
	g_bWarmTime = false;
	ServerCommand("mp_warmup_end");
	if(GetConVarInt(CVAR_EnableEnd) == 1)
		g_bEnableEnd = true;
}

public Action Cmd_Fix(int client, int args)
{
	if(g_bEnableFix)
	{
		g_bEnableFix = false;
		g_bTempDisable = true;
		
		PrintToChatAll("[SM]  修复人物躺地已临时禁用");
		
		for(int i = 1; i <= MaxClients; ++i)
		{
			if(IsValidClient(i))
			{
				int iEntity = EntRefToEntIndex(g_iFakeWeaponRef[client]);
				if(iEntity > MaxClients && iEntity != INVALID_ENT_REFERENCE)
				{
					RemovePlayerItem(client, iEntity);
					AcceptEntityInput(iEntity, "Kill");
				}
			}
		}
	}
	else
	{
		g_bEnableFix = true;
		g_bTempDisable = false;
		PrintToChatAll("[SM]  修复人物躺地已启用");
	}
}

public OnPluginEnd()
{
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(IsValidClient(i))
		{
			OnClientDisconnect(i);
		}
	}
}

public int OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar == CVAR_EnableFix)
		g_bEnableFix = view_as<bool>(StringToInt(newValue));
	if(convar == CVAR_EnableEnd)
		g_bEnableEnd = view_as<bool>(StringToInt(newValue));
}

public OnClientPutInServer(client)
{
	if(IsValidClient(client))
	{
		SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
		SDKHook(client, SDKHook_WeaponEquip, WeaponSwitch);
		SDKHook(client, SDKHook_WeaponDrop, WeaponDrop);

		g_iFakeWeaponRef[client] = 0;
	}
}

public OnClientDisconnect(client)
{
	if(IsValidClient(client))
	{
		SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
		SDKUnhook(client, SDKHook_WeaponEquip, WeaponSwitch);
		SDKUnhook(client, SDKHook_WeaponDrop, WeaponDrop);
	}
}

public Action WeaponSwitch(int client, int weapon)
{
	int iEntity = EntRefToEntIndex(g_iFakeWeaponRef[client]);
	if(IsValidEntity(weapon) && weapon != iEntity && iEntity > MaxClients && iEntity != INVALID_ENT_REFERENCE)
	{
		RemovePlayerItem(client, iEntity);
		AcceptEntityInput(iEntity, "Kill");
	}
	return Plugin_Continue;
}

public Action WeaponDrop(int client, int weapon)
{
	int iEntity = EntRefToEntIndex(g_iFakeWeaponRef[client]);
	if(IsValidEntity(weapon) && weapon == iEntity)
		AcceptEntityInput(iEntity, "Kill");
	
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(!g_bEnableFix || !IsPlayerAlive(client))
		return Plugin_Continue;
	
	if(Store_HasClientPlayerSkin(client))
		return Plugin_Continue;
	
	int iEntity = EntRefToEntIndex(g_iFakeWeaponRef[client]);
	if (iEntity > MaxClients)
	{
		float fUnlockTime = GetGameTime() + 0.5;
		
		SetEntProp(client, Prop_Data, "m_bDrawViewmodel", 0);
		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", fUnlockTime);
		SetEntPropFloat(iEntity, Prop_Send, "m_flNextPrimaryAttack", fUnlockTime);
	}
	else SetEntProp(client, Prop_Data, "m_bDrawViewmodel", 1);
	
	if(weapon <= 0)
		weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if(weapon <= 0 && iEntity <= 0)
	{
		int iWeapon = GivePlayerItem(client, "weapon_decoy");
		
		float fUnlockTime = GetGameTime() + 0.5;
		
		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", fUnlockTime);
		SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", fUnlockTime);
	
		g_iFakeWeaponRef[client] = EntIndexToEntRef(iWeapon);
		return Plugin_Continue;
	}

  	return Plugin_Continue;
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if(!g_bEnableEnd)
		return;
	
	CreateTimer(9.0, Timer_RoundEnd);
}

public Action Timer_RoundEnd(Handle tiemr)
{
	for(int client=1; client<=MaxClients; ++client)
	{
		if(IsValidClient(client))
		{
			if(IsPlayerAlive(client))
			{
				DropPlayerWeaponOnSlot(client, 0);
				DropPlayerWeaponOnSlot(client, 1);
				DropPlayerWeaponOnSlot(client, 2);
				DropPlayerWeaponOnSlot(client, 3);
				DropPlayerWeaponOnSlot(client, 3);
			}
		}
	}
	
	g_bWeaponCanUse = false;
}

public Action Event_RountStart(Handle event, const char[] name, bool dontBroadcast)
{
	g_bWeaponCanUse = true;
	
	if(g_bTempDisable)
	{
		g_bEnableFix = true;
		g_bTempDisable = false;
	}
}

public Action OnWeaponCanUse(client, weapon)
{
	if(!g_bEnableEnd)
	{
		return Plugin_Continue;
	}
	
	if(g_bWarmTime)
	{
		return Plugin_Continue;
	}
	
	if(g_bWeaponCanUse)
	{
		return Plugin_Continue;
	}
	
	if(IsValidClient(client) && IsValidEdict(weapon))
	{
		char szWeapon[32];
		GetEdictClassname(weapon, szWeapon, 32);
		if(StrEqual(szWeapon, "weapon_decoy", false))
			return Plugin_Continue;

		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

stock DropPlayerWeaponOnSlot(client, slot)
{
	int weapon_index=-1;
	if((weapon_index = GetPlayerWeaponSlot(client, slot)) != -1)
	{
		RemovePlayerItem(client, weapon_index);
		AcceptEntityInput(weapon_index, "Kill");
	}
}

bool IsValidClient(client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client)) ? true : false;
}