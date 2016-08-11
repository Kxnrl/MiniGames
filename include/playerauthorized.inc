#if defined _PlayerAuthorized_included
	#endinput
#endif
#define _PlayerAuthorized_included

public void __pl_PlayerAuthorized_SetNTVOptional()
{
	MarkNativeAsOptional("PA_GetGroupID");
	MarkNativeAsOptional("PA_GetGroupName");
	MarkNativeAsOptional("PA_GetLevel");
	MarkNativeAsOptional("PA_GivePlayerExp");
	MarkNativeAsOptional("PA_SetTempAuthorized");
}

/**********************************************************************
 * 获得玩家GroupIndex[需要PA_OnClientLoaded]
 * *
 * @param		client		The client index of the player that has been loaded
 * @return 		GroupIndex	返回数值是Int(0~9999)
 **********************************************************************/
native int PA_GetGroupID(int client);

/**********************************************************************
 * Retrieves the GroupName of a client.
 *
 * @param client			The slot number of the client.
 * @param buffer			Destination buffer, will be empty if the client is not authorized.
 * @param maxLen			Destination buffer length.
 * @noreturn
 **********************************************************************/
native int PA_GetGroupName(int client, char[] buffer, int maxLen);

/**********************************************************************
 * 获得玩家等级[需要PA_OnClientLoaded]
 * *
 * @param		client		The client index of the player that has been loaded
 * @return		Level		返回数值是Int(0~9999)
 **********************************************************************/
native int PA_GetLevel(int client);

/**********************************************************************
 * 给玩家增加经验值[需要PA_OnClientLoaded]
 * *
 * @param         client        The client index of the player that has been loaded
 * @param          Exp          The amount of u want to give Exp to client
 * @noreturn
 **********************************************************************/
native int PA_GivePlayerExp(int client, int Exp);

/**********************************************************************
 * 设置玩家临时认证
 * *
 * @param         client        The client index of the player that has been loaded
 * @param         GroupID       GroupIndex
 * @param          Time         Duration
 * @noreturn
 **********************************************************************/
native bool PA_SetTempAuthorized(int client, int GroupID, int Time);

/**********************************************************************
 * 玩家数据加载完毕
 * *
 * @param         client        The client index of the player that has been loaded
 * @noreturn
 **********************************************************************/
forward void PA_OnClientLoaded(int client);