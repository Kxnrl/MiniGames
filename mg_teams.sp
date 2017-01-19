#include <sdktools_functions>
#pragma newdecls required

#define TEAM_UNASSIGNED 0
#define TEAM_SPECTATE   1
#define TEAM_TE         2
#define TEAM_CT         3

public Plugin myinfo =
{
	name = " MG Team ",
	author = "Kyle",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/_xQy_/"
};

public void OnPluginStart() 
{
	AddCommandListener(Command_Jointeam, "jointeam");
}

public Action Command_Jointeam(int client, const char[] command, int argc)
{
	if(!IsValidClient(client) || argc < 1)
		return Plugin_Handled;

	char arg[4];
	GetCmdArg(1, arg, 4);
	int newteam = StringToInt(arg);
	int oldteam = GetClientTeam(client);

	if(oldteam == TEAM_UNASSIGNED)
	{
		newteam = GetAllowTeam();
		ChangeClientTeam(client, newteam);
		return Plugin_Handled;
	}
	
	if(newteam == oldteam)
		return Plugin_Handled;

	if(oldteam >= TEAM_SPECTATE)
	{
		if(newteam <= TEAM_SPECTATE)
		{
			newteam = TEAM_SPECTATE;
			ChangeClientTeam(client, TEAM_SPECTATE);
			return Plugin_Handled;
		}
		return GetConVarBool(FindConVar("mg_randomteam")) ? Plugin_Handled : Plugin_Continue;
	}

	ChangeClientTeam(client, TEAM_SPECTATE);

	return Plugin_Handled;
}

bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client)) ? true : false;
}

int GetAllowTeam()
{
	return (GetTeamClientCount(TEAM_TE) > GetTeamClientCount(TEAM_CT)) ? TEAM_CT : TEAM_TE;
}