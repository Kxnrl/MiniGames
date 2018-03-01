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
	AddCommandListener(Command_AntiKill, "kill");
	AddCommandListener(Command_AntiKill, "explode");
	AddCommandListener(Command_AntiKill, "sm_kill");
}

public Action Command_AntiKill(int client, const char[] command, int argc)
{
	if(GetUserFlagBits(client) & ADMFLAG_ROOT)
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action Command_Jointeam(int client, const char[] command, int argc)
{
	if(!IsValidClient(client) || argc < 1)
		return Plugin_Handled;

	char arg[4];
	GetCmdArg(1, arg, 4);
	int newteam = StringToInt(arg);
	int oldteam = GetClientTeam(client);

	if(IsPlayerAlive(client))
	{
		PrintToChat(client, " \x02活着的时候不能切换队伍");
		return Plugin_Handled;
	}
    
    //int pending = GetEntProp(client, Prop_Send, "m_iPendingTeamNum");
    //if(pending == 2 || pending == 3)
    //{
    //    PrintToChat(client, " \x02交换队伍时不允许切换队伍");
	//	return Plugin_Handled;
    //}

	if(oldteam == TEAM_UNASSIGNED)
	{
		newteam = GetAllowTeam();
		ChangeClientTeam(client, newteam);
		return Plugin_Handled;
	}

	if(newteam == oldteam)
		return Plugin_Handled;

	if(oldteam > TEAM_SPECTATE)
	{
        newteam = GetAllowTeam();
        ChangeClientTeam(client, newteam);
        return Plugin_Handled;
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