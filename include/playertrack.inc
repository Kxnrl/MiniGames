/**********************************************************************
 * When Server has been loaded
 * *
 * @noreturn
 **********************************************************************/
forward Action:CG_OnServerLoaded();

/**********************************************************************
 * When a player has been Daily Sign.
 * *
 * @param         client        The client index of the player that has been loaded
 * @noreturn
 **********************************************************************/
forward Action:CG_OnClientDailySign(client);