public __pl_Ninja_SetNTVOptional()
{
	MarkNativeAsOptional("Ninja_IsGaming");
	MarkNativeAsOptional("Ninja_IsClientNinja");
	MarkNativeAsOptional("Ninja_IsClientGuard");
	MarkNativeAsOptional("Ninja_IsClientBOSS");
	MarkNativeAsOptional("Ninja_IsClientVIP");
	MarkNativeAsOptional("Ninja_GameType");
}

native bool Ninja_IsGaming(); //If Game Start return true
native bool Ninja_IsClientNinja(client);
native bool Ninja_IsClientGuard(client);
native bool Ninja_IsClientBOSS(client);
native bool Ninja_IsClientVIP(client);
native int Ninja_GameType(); //Normal=0,BOSS=1,VIP=2,GUESS=3

forward Action Ninja_OnGameReady(); //On Game Ready , Ninja in Freeze Time
forward Action Ninja_OnGameStart(); //On Game Start
forward Action Ninja_OnVIPDown(client);
forward Action Ninja_OnBossDown(client);
forward Action Ninja_OnClientBurnWithNormalNinja(client);
forward Action Ninja_OnClientBurnWithBossNinja(client);
forward Action Ninja_OnClientBurnWithNormalGuard(client);
forward Action Ninja_OnClientBurnWithVIPGuard(client);