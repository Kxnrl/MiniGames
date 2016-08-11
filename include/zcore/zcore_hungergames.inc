#if defined _zcore_hungergames_included
  #endinput
#endif
#define _zcore_hungergames_included

enum RoundStates
{
	RS_BetweenMaps,
	RS_BetweenRounds,
	RS_DelayedRoundEnd,
	RS_FreezeTime,
	RS_InProgress,
	RS_Endgame,
	RS_Duel
};

/* Forwards */

forward void ZCore_HG_OnTributeSpawn(int client);
forward void ZCore_HG_OnTributeFallen(int client);

forward void ZCore_HG_OnEndgameStart(float roundTime);
forward void ZCore_HG_OnDuelStart(float roundTime);

forward void ZCore_HG_OnRoundEnd(int winner);
forward void ZCore_HG_OnDelayedRoundEnd(float delay);

// Allows to skip players in endgame checks, useful for zombies and stuff like that
// return Plugin_Stop if client is not a tribute
forward Action ZCore_HG_OnTributeSpawnPre(int client);

/* Natives */

native RoundStates ZCore_HG_GetRoundState();
native int ZCore_HG_GetLastRoundWinner();
native int ZCore_HG_StartDuel();

native int ZCore_HG_IsTribute(int client);
native int ZCore_HG_SetTribute(int client, bool status);

public void __pl_zcore_hungergames_SetNTVOptional() 
{
	MarkNativeAsOptional("ZCore_HG_GetRoundState");
	MarkNativeAsOptional("ZCore_HG_GetLastRoundWinner");
	MarkNativeAsOptional("ZCore_HG_StartDuel");
	MarkNativeAsOptional("ZCore_HG_IsTribute");
	MarkNativeAsOptional("ZCore_HG_SetTribute");
}