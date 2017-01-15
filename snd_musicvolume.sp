public void OnMapStart()
{
	CreateTimer(240.0, Timer_Check, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Check(Handle timer)
{
	for(int client = 1; client <= MaxClients; ++client)
		if(IsClientInGame(client))
			QueryClientConVar(client, "snd_musicvolume", view_as<ConVarQueryFinished>(OnGetClientCVAR), client);
}

public void OnGetClientCVAR(QueryCookie cookie, int client, ConVarQueryResult result, char [] cvarName, char [] cvarValue)
{
	if(StringToFloat(cvarValue) <= 0.0 && IsClientInGame(client))
	{
		PrintToChat(client, " \x04在控制台中输入[\x0Csnd_musicvolume 1\x04]让你的游戏更激情");
	}
}