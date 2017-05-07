void ThirdPerson_Init()
{
	g_Mutators = Game_ThirdPerson;
	SetConVarInt(FindConVar("sv_allow_thirdperson"), 1);
	PrintToChatAll(" \x02突变因子: \x07第三视角");
	PrintToChatAll("本局你将无法使用第一人称视角");
	CreateTimer(1.0, Timer_ThirdPerson, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CG_ShowGameTextAll("突变因子: 第三视角\n本局你将无法使用第一人称视角", "10.0", "57 197 187", "-1.0", "-1.0");
}

public Action Timer_ThirdPerson(Handle timer)
{
	if(g_Mutators != Game_ThirdPerson)
	{
		SetAllClientFP();
		return Plugin_Stop;
	}
	
	SetAllClientTP();
	
	return Plugin_Continue;
}

void SetAllClientFP()
{
	for(int client = 1; client <= MaxClients; ++client)
	{
		if(!IsClientInGame(client))
			continue;
		
		ClientCommand(client, "firstperson");
	}
}

void SetAllClientTP()
{
	for(int client = 1; client <= MaxClients; ++client)
	{
		if(!IsClientInGame(client))
			continue;
		
		ClientCommand(client, IsPlayerAlive(client) ? "thirdperson" : "firstperson");
	}
}