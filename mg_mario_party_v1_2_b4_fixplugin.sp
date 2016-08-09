#include <sourcemod>

bool g_bIsMario;

public OnPluginStart()
{
	RegAdminCmd("sm_fix", Cmd_Fix, ADMFLAG_SLAY);
	HookEvent("round_start", Event_RoundStart);
	g_bIsMario = false;
}

public OnMapStart()
{
	new String:szMapName[128];
	GetCurrentMap(szMapName, 128);
	if(StrContains(szMapName, "mario_party", false ) != -1)
		g_bIsMario = true;
	else
		ServerCommand("sm plugins unload mg_mario_party_v1_2_b4_fixplugin.smx");
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bIsMario)
		FixBug();
}

public Action:Cmd_Fix(int client, int args)
{
	if(g_bIsMario)
		FixBug();
}

stock FixBug()
{
	Handle mp_teammates_are_enemies = FindConVar("mp_teammates_are_enemies");
	int CVAR = GetConVarInt(mp_teammates_are_enemies);
	if(CVAR == 1)
		ServerCommand("sm_cvar mp_teammates_are_enemies 0");
}