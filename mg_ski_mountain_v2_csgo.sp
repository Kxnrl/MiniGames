#pragma semicolon 1
#include <sdktools>

float g_fVelocity[MAXPLAYERS+1][3];

public void OnMapStart()
{
	char map[128];
	GetCurrentMap(map, 128);
	if(StrContains(map, "ski_m", false) == -1)
		ServerCommand("sm plugins unload mg_ski_mountain_v2_csgo.smx");
	else
		HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	g_fVelocity[client][0] = 0.0;
	g_fVelocity[client][1] = 0.0;
	g_fVelocity[client][2] = 0.0;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(!IsPlayerAlive(client))
		return Plugin_Continue;
	
	if(buttons & IN_BACK)
		return Plugin_Continue;
	
	float fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);

	float currentspeed = SquareRoot(Pow(fVelocity[0], 2.0) + Pow(fVelocity[1], 2.0));
	float oldspeed = SquareRoot(Pow(g_fVelocity[client][0],2.0)+Pow(g_fVelocity[client][1],2.0));

	if(currentspeed - oldspeed < -100.0 && currentspeed <= 30.0)
	{
		float fOrigin[3];
		GetClientAbsOrigin(client, fOrigin);
		fOrigin[2] += 5.0;

		TeleportEntity(client, fOrigin, NULL_VECTOR, g_fVelocity[client]);

		
		if(CheckIfPlayerIsStuck(client))
		{
			fOrigin[2] -= 5.0;
			TeleportEntity(client, fOrigin, NULL_VECTOR, g_fVelocity[client]);
		}

		PrintToChat(client, "[\x04MG\x01] \x05DEBUG \x0C>>> \x0AFix Stuck...");
	}
	
	PrintHintText(client, "Current Speed: %.2f\nNearest Speed: %.2f", currentspeed, oldspeed);

	g_fVelocity[client][0] = fVelocity[0];
	g_fVelocity[client][1] = fVelocity[1];
	g_fVelocity[client][2] = fVelocity[2];

	return Plugin_Continue;
}

stock bool CheckIfPlayerIsStuck(int iClient)
{
    float vecMin[3]; 
    float vecMax[3];
    float vecOrigin[3];
    
    GetClientMins(iClient, vecMin);
    GetClientMaxs(iClient, vecMax);
    GetClientAbsOrigin(iClient, vecOrigin);
    
    TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_SOLID, TraceEntityFilterSolid);
    return TR_DidHit();    // head in wall ?
}

public bool TraceEntityFilterSolid(int entity, int contentsMask) 
{
    return entity > 1;
}