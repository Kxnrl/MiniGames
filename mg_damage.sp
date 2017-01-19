#include <cg_core>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo =
{
	name = " MG Damage ",
	author = "Kyle",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/_xQy_/"
};

public void CG_OnClientLoaded(int client)
{
	if(PA_GetGroupID(client) == 9999)
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	if(PA_GetGroupID(client) == 9999)
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(damagetype & DMG_FALL)
	{
		damage *= 0.5;
		return Plugin_Changed;
	}
	
	if(attacker < 1 || attacker > MaxClients)
		return Plugin_Continue;

	if(IsValidEdict(inflictor))
	{
		char entityclass[32];
		GetEdictClassname(inflictor, entityclass, 32);
		if(StrEqual(entityclass, "hegrenade_projectile") || StrEqual(entityclass, "inferno"))
		{
			damage *= 0.5;
			return Plugin_Changed;
		}
	}
	
	if(IsValidEdict(weapon))
	{
		char classname[32];
		GetEdictClassname(weapon, classname, 32);
		if(StrEqual(classname, "weapon_taser"))
		{
			damage *= 0.5;
			return Plugin_Changed;
		}
		if(StrEqual(classname, "weapon_knife"))
		{
			if(damage > 65.0)
			{
				damage = 65.0;
				return Plugin_Changed;
			}
		}
		if(StrEqual(classname, "weapon_awp"))
		{
			if(damage > 400.0)
			{
				damage = 300.0;
				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}