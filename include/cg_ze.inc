
public __pl_ZombieEscape_SetNTVOptional()
{
	MarkNativeAsOptional("ZE_GetPlayerOnlines");
	MarkNativeAsOptional("ZE_GetPlayerScores");
	MarkNativeAsOptional("ZE_GetPlayerPoints");
	MarkNativeAsOptional("ZE_GetPlayerRank");
	MarkNativeAsOptional("ZE_GetPlayerPass");
	MarkNativeAsOptional("ZE_GetPlayerDamage");
	MarkNativeAsOptional("ZE_SetPlayerPoints");
	MarkNativeAsOptional("ZE_StatsEnable");
	MarkNativeAsOptional("ZE_IsClientCommander");
	MarkNativeAsOptional("ZE_GetCommander");
	MarkNativeAsOptional("ZE_IsClientTerminator");
	MarkNativeAsOptional("ZE_GetTerminatorType");
}

native ZE_GetPlayerOnlines(client);
native ZE_GetPlayerScores(client);
native ZE_GetPlayerPoints(client);
native ZE_GetPlayerCredits(client);
native ZE_GetPlayerRank(client);
native ZE_GetPlayerPass(client);
native ZE_GetPlayerDamage(client);
native ZE_SetPlayerPoints(client, int Point);
native ZE_SetPlayerCredits(client, int Point);
native bool ZE_StatsEnable();
forward Action ZE_OnClientLoaded(client);
