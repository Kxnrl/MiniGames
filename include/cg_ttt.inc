/**********************************************************************
 * When Player has been Seleccion
 * *
 * @noreturn
 **********************************************************************/
forward Action:CG_TTT_OnSeleccion();

/**********************************************************************
 * When Round End
 * *
 * @noreturn
 **********************************************************************/
forward Action:CG_TTT_OnRoundEnd();

/**********************************************************************
 * When Player has been Seleccion , Get Player ID.
 * *
 * @param         client        The client index of the player that has been loaded
 * @return I=1 T=2 D=3 U=0
 **********************************************************************/
native CG_TTT_GetEquipo(client);

/**********************************************************************
 * When Player has been Seleccion , Give Money
 * *
 * @param         client        The client index of the player that has been loaded
 * @param          args         The amount of u want to give money to client
 * @noreturn
 **********************************************************************/
native CG_TTT_GiveMoney(client, int Money);

/**********************************************************************
 * When Player has been Seleccion , Give team credits
 * *
 * @param         client        The client index of the player that has been loaded
 * @param          args         The amount of u want to give team credits to client
 * @noreturn
 **********************************************************************/
native CG_TTT_GiveTeamCredits(client, int teamcredits);

/**********************************************************************
 * When Player has been Seleccion , Give Karma
 * *
 * @param         client        The client index of the player that has been loaded
 * @param          args         The amount of u want to give team credits to client
 * @noreturn
 **********************************************************************/
native CG_TTT_GiveKarma(client, int karma);

/**********************************************************************
 * When Player has been loaded , Get Player Karma.
 * *
 * @param         client        The client index of the player that has been loaded
 * @return  		Int
 **********************************************************************/
native CG_TTT_GetKarma(client);