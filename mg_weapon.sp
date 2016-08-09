#include <sourcemod>
#include <sdktools>

public void OnPluginStart()
{
	RegAdminCmd("giveak47", Cmd_GiveAK47, ADMFLAG_ROOT);
	RegAdminCmd("givem4a1", Cmd_GiveM4A1, ADMFLAG_ROOT);
	RegAdminCmd("givem4a4", Cmd_GiveM4A4, ADMFLAG_ROOT);
	RegAdminCmd("giveknife", Cmd_GiveKnife, ADMFLAG_UNBAN);
	RegAdminCmd("giveusp", Cmd_GiveUSP, ADMFLAG_ROOT);
	RegAdminCmd("giveawp", Cmd_GiveAWP, ADMFLAG_ROOT);
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
