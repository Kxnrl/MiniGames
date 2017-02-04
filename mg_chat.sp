public Plugin myinfo =
{
	name		= "MG - Funny Chat",
	author		= "Kyle",
	description	= "",
	version		= "1.0", 
	url			= "http://steamcommunity.com/id/_xQy_/"
};


int g_iTarget;

public void OnPluginStart()
{
	RegAdminCmd("sm_fakesay", Command_FakeSay, ADMFLAG_ROOT);
}

public void OnClientDisconnect_Post(int client)
{
	if(g_iTarget == client)
		g_iTarget = 0;
}

public Action Command_FakeSay(int client, int args)
{
	Handle menu = CreateMenu(MenuHandler_SelectTarget);
	SetMenuTitle(menu, "Select a target");
	for(int target = 1; target <= MaxClients; ++target)
		if(IsClientInGame(target) && target != client)
		{
			char info[4], name[32];
			GetClientName(target, name, 32);
			IntToString(target, info, 4);
			AddMenuItem(menu, info, name);
		}
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_SelectTarget(Handle menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, param2, info, 32);
		g_iTarget = StringToInt(info);
		if(!IsClientInGame(g_iTarget))
			g_iTarget = 0;
		
		PrintToChat(client, "[\x04FakeSay\x01]  \x04Target is \x05%N", g_iTarget);
	}
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if(!client || !g_iTarget || !(GetUserFlagBits(client) & ADMFLAG_ROOT) || !IsClientInGame(g_iTarget))
		return Plugin_Continue;
	
	if(sArgs[0] != '.')
		return Plugin_Continue;
	
	FakeClientCommand(g_iTarget, "say %s", sArgs[1]);
	
	return Plugin_Stop;
}