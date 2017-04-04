#include <cg_core>
#include <sdktools>

public void CG_OnClientLoaded(int client)
{
	if(CG_GetClientGId(client) == 1290)
		CreateTimer(3.0, Timer_Repeat, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Repeat(Handle timer, int client)
{
	SetClientName(client, "Mr.庞麦郎大鸽");
}