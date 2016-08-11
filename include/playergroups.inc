#if defined _playergroups_included
  #endinput
#endif
#define _playergroups_included


public __pl_PlayerAuthorized_SetNTVOptional()
{
	MarkNativeAsOptional("PA_GetGroupID");
}

/*********************************************************
 * Get the GroupID of a player on the DataBase.
 *
 * @param client	The client index of the player to get the GroupID
 * @return		The GroupID of the client
 *********************************************************/
native PA_GetGroupID(client);

/**********************************************************************
 * When a player has been loaded.
 * *
 * @param         client        The client index of the player that has been loaded
 * @noreturn
 **********************************************************************/
forward Action:PA_OnClientLoaded(client);