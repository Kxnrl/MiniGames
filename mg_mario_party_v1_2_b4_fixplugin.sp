#include <sdktools>

public void OnMapStart()
{
	char szMapName[128];
	GetCurrentMap(szMapName, 128);
	if(StrContains(szMapName, "mario_party", false ) != -1)
	{
		HookEvent("round_start", Event_RoundStart);
	}
}

public void OnMapEnd()
{
	char szMapName[128];
	GetCurrentMap(szMapName, 128);
	if(StrContains(szMapName, "mario_party", false ) != -1)
	{
		UnhookEvent("round_start", Event_RoundStart);
	}
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	Handle mp_teammates_are_enemies = FindConVar("mp_teammates_are_enemies");
	SetConVarInt(mp_teammates_are_enemies, 0);
}