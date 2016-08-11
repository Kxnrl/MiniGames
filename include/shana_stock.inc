#define LoopIngamePlayers(%1) for(new %1=1;%1<=MaxClients;++%1)\
								if(IsClientInGame(%1) && !IsFakeClient(%1))

#define LoopAlivePlayers(%1) for(new %1=1;%1<=MaxClients;++%1)\
								if(IsClientInGame(%1) && IsPlayerAlive(%1))

#define LoopIngameClients(%1) for(new %1=1;%1<=MaxClients;++%1)\
								if(IsClientInGame(%1))

#define DEBUG_PREFIX "[\x02Debug-Info\x01] "


new String:g_FlagNames[FLAG_STRINGS][20] =
{
	"res",
	"admin",
	"kick",
	"ban",
	"unban",
	"slay",
	"map",
	"cvars",
	"cfg",
	"chat",
	"vote",
	"pass",
	"rcon",
	"cheat"
};

stock FlagsToString(String:buffer[], maxlength, flags)
{
	char joins[FLAG_STRINGS+1][32];
	new total;

	for (new i=0; i<FLAG_STRINGS; i++)
	{
		if (flags & (1<<i))
		{
			strcopy(joins[total++], 32, g_FlagNames[i]);
		}
	}
	
	char custom_flags[32];
	if (CustomFlagsToString(custom_flags, sizeof(custom_flags), flags))
	{
		Format(joins[total++], 32, "custom(%s)", custom_flags);
	}

	ImplodeStrings(joins, total, ", ", buffer, maxlength);
}

stock CustomFlagsToString(String:buffer[], maxlength, flags)
{
	char joins[6][6];
	new total;
	
	for (new i=_:Admin_Custom1; i<=_:Admin_Custom6; i++)
	{
		if (flags & (1<<i))
		{
			IntToString(i - _:Admin_Custom1 + 1, joins[total++], 6);
		}
	}
	
	ImplodeStrings(joins, total, ",", buffer, maxlength);
	
	return total;
}


stock bool:IsClientShAna(int client)
{
	char SteamID[64];
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	if(StrEqual(SteamID, "STEAM_1:1:44083262"))
		return true;
	return false;
}


stock bool:IsClientBot(int client)
{
	if (client == 0 || IsFakeClient(client))
		return true;

	char SteamID[64];
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));

	if (StrEqual(SteamID, "BOT", false))
		return true;

	return false;
}

stock ClearTimer(&Handle:timer)
{
	if(timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}
}

stock GetClientBySteamID(String:steamid[])
{
	new String:authid[32];
	new String:legacy[32];
	for(new client=1;client<=MaxClients;++client)
	{
		if(!IsClientInGame(client))
			continue;
		
		if(!IsClientAuthorized(client))
			continue;
		
		GetClientAuthId(client, AuthId_Steam2, authid, sizeof(authid));
		GetClientAuthId(client, AuthId_Steam2, legacy, sizeof(legacy));
		
		if(strcmp(legacy[8], steamid[8])==0 || strcmp(authid, steamid)==0)
			return client;
	}
	return 0;
}

stock bool:GetSteam64ID(String:AuthID[], String:FriendID[], size)
{
	if(strlen(AuthID) < 11 || AuthID[0]!='S' || AuthID[6]=='I')
	{
		FriendID[0] = 0;
		return false;
	}
	new iUpper = 765611979;
	new iFriendID = StringToInt(AuthID[10])*2 + 60265728 + AuthID[8]-48;
	new iDiv = iFriendID/100000000;
	new iIdx = 9-(iDiv?iDiv/10+1:0);
	iUpper += iDiv;
	IntToString(iFriendID, FriendID[iIdx], size-iIdx);
	iIdx = FriendID[9];
	IntToString(iUpper, FriendID, size);
	FriendID[9] = iIdx;
	return true;
}