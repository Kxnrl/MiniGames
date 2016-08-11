#include <sdktools>

stock bool IsClientShAna(int client)
{
	char SteamID[32];
	GetClientAuthId(client, AuthId_Steam2, SteamID, 32);
	if(StrEqual(SteamID, "STEAM_1:1:44083262"))
		return true;
	return false;
}

stock bool IsClientBot(int client)
{
	if (client == 0 || IsFakeClient(client))
		return true;

	char SteamID[32];
	GetClientAuthId(client, AuthId_Steam2, SteamID, 32);

	if (StrEqual(SteamID, "BOT", false))
		return true;

	return false;
}

stock bool IsValidClient(int client, bool checkBOT=true)
{
	if(client > MaxClients || client < 1)
		return false;

	if(!IsClientInGame(client) || IsFakeClient(client))
		return false;
	
	if(checkBOT)
	{
		char SteamID[64];
		GetClientAuthId(client, AuthId_Steam2, SteamID, 32);

		if(StrEqual(SteamID, "BOT", false))
		return false;
	}
	
	return true;
}

stock CPrintToChat(client, const char[] szMessage, any:...)
{
	if(client <= 0 || client > MaxClients)
		ThrowError("Invalid client index %d", client);

	if(!IsClientInGame(client))
		ThrowError("Client %d is not in game", client);

	char szBuffer[256];
	char szCMessage[256];

	SetGlobalTransTarget(client);

	Format(szBuffer, 256, "%s", szMessage);
	VFormat(szCMessage, 256, szBuffer, 3);

	ReplaceString(szCMessage, 256, "{default}", "\x01", false);
	ReplaceString(szCMessage, 256, "{white}", "\x01", false);
	ReplaceString(szCMessage, 256, "{darkred}", "\x02", false);
	ReplaceString(szCMessage, 256, "{pink}", "\x03", false);
	ReplaceString(szCMessage, 256, "{green}", "\x04", false);
	ReplaceString(szCMessage, 256, "{lime}", "\x05", false);
	ReplaceString(szCMessage, 256, "{lightgreen}", "\x06", false);
	ReplaceString(szCMessage, 256, "{red}", "\x07", false);
	ReplaceString(szCMessage, 256, "{lightred}", "\x07", false);
	ReplaceString(szCMessage, 256, "{gray}", "\x08", false);
	ReplaceString(szCMessage, 256, "{grey}", "\x08", false);
	ReplaceString(szCMessage, 256, "{olive}", "\x09", false);
	ReplaceString(szCMessage, 256, "{orange}", "\x10", false);
	ReplaceString(szCMessage, 256, "{purple}", "\x0E", false);
	ReplaceString(szCMessage, 256, "{lightblue}", "\x0B", false);
	ReplaceString(szCMessage, 256, "{blue}", "\x0C");

	PrintToChat(client, szCMessage);
}

stock CPrintToChatAll(const char[] szMessage, any:...)
{
	char szBuffer[256];
	char szCMessage[256];

	Format(szBuffer, 256, "%s", szMessage);
	VFormat(szCMessage, 256, szBuffer, 2);

	ReplaceString(szCMessage, 256, "{default}", "\x01", false);
	ReplaceString(szCMessage, 256, "{white}", "\x01", false);
	ReplaceString(szCMessage, 256, "{darkred}", "\x02", false);
	ReplaceString(szCMessage, 256, "{pink}", "\x03", false);
	ReplaceString(szCMessage, 256, "{green}", "\x04", false);
	ReplaceString(szCMessage, 256, "{lime}", "\x05", false);
	ReplaceString(szCMessage, 256, "{lightgreen}", "\x06", false);
	ReplaceString(szCMessage, 256, "{red}", "\x07", false);
	ReplaceString(szCMessage, 256, "{gray}", "\x08", false);
	ReplaceString(szCMessage, 256, "{grey}", "\x08", false);
	ReplaceString(szCMessage, 256, "{olive}", "\x09", false);
	ReplaceString(szCMessage, 256, "{orange}", "\x10", false);
	ReplaceString(szCMessage, 256, "{purple}", "\x0E", false);
	ReplaceString(szCMessage, 256, "{lightblue}", "\x0B", false);
	ReplaceString(szCMessage, 256, "{blue}", "\x0C");

	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			SetGlobalTransTarget(i);
			PrintToChat(i, "%s", szCMessage);
		}
	}
}

stock ClearTimer(&Handle:timer)
{
	if(timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}
}

stock GetClientBySteamID(char[] steamid)
{
	new String:authid[32];
	new String:legacy[32];
	for(new client=1;client<=MaxClients;++client)
	{
		if(!IsClientInGame(client))
			continue;
		
		if(!IsClientAuthorized(client))
			continue;
		
		GetClientAuthId(client, AuthId_Steam2, authid, 32);
		GetClientAuthId(client, AuthId_Steam2, legacy, 32);
		
		if(strcmp(legacy[8], steamid[8])==0 || strcmp(authid, steamid)==0)
			return client;
	}
	return 0;
}

stock void MissionHint(char[] caption, int color1, int color2, int color3, char[] icon)
{
	int instrHintEnt;  
	char color[32];
	instrHintEnt = CreateEntityByName("env_instructor_hint");
	FormatEx(color, sizeof(color), "%d %d %d", color1, color2, color3);
	
	DispatchKeyValue(instrHintEnt, "hint_range", "999999");
	DispatchKeyValue(instrHintEnt, "hint_color", color);
	DispatchKeyValue(instrHintEnt, "hint_caption", caption);
	DispatchKeyValue(instrHintEnt, "hint_icon_onscreen", icon);
	DispatchKeyValue(instrHintEnt, "hint_timeout", "5.0");

	DispatchSpawn(instrHintEnt);
	AcceptEntityInput(instrHintEnt, "ShowHint");
	AcceptEntityInput(instrHintEnt, "kill");
}
/*
stock void DisplayInstructorHint(int iTargetEntity, float fTime, float fHeight, float fRange, bool bFollow, bool bShowOffScreen, char[] sIconOnScreen, char[] sIconOffScreen, char[] sCmd, bool bShowTextAlways, int iColor[3], char sText[256])
{
    int iEntity = CreateEntityByName("env_instructor_hint");
    
    if(iEntity <= 0)
        return;
        
    char sBuffer[32];
    FormatEx(sBuffer, sizeof(sBuffer), "%d", iTargetEntity);
    
    // Target
    DispatchKeyValue(iTargetEntity, "targetname", sBuffer);
    DispatchKeyValue(iEntity, "hint_target", sBuffer);
    
    // Static
    FormatEx(sBuffer, sizeof(sBuffer), "%d", !bFollow);
    DispatchKeyValue(iEntity, "hint_static", sBuffer);
    
    // Timeout
    FormatEx(sBuffer, sizeof(sBuffer), "%d", RoundToFloor(fTime));
    DispatchKeyValue(iEntity, "hint_timeout", sBuffer);
    if(fTime > 0.0)
        RemoveEntity(iEntity, fTime);
    
    // Height
    FormatEx(sBuffer, sizeof(sBuffer), "%d", RoundToFloor(fHeight));
    DispatchKeyValue(iEntity, "hint_icon_offset", sBuffer);
    
    // Range
    FormatEx(sBuffer, sizeof(sBuffer), "%d", RoundToFloor(fRange));
    DispatchKeyValue(iEntity, "hint_range", sBuffer);
    
    // Show off screen
    FormatEx(sBuffer, sizeof(sBuffer), "%d", !bShowOffScreen);
    DispatchKeyValue(iEntity, "hint_nooffscreen", sBuffer);
    
    // Icons
    DispatchKeyValue(iEntity, "hint_icon_onscreen", sIconOnScreen);
    DispatchKeyValue(iEntity, "hint_icon_offscreen", sIconOffScreen);
    
    // Command binding
    DispatchKeyValue(iEntity, "hint_binding", sCmd);
    
    // Show text behind walls
    FormatEx(sBuffer, sizeof(sBuffer), "%d", bShowTextAlways);
    DispatchKeyValue(iEntity, "hint_forcecaption", sBuffer);
    
    // Text color
    FormatEx(sBuffer, sizeof(sBuffer), "%d %d %d", iColor[0], iColor[1], iColor[2]);
    DispatchKeyValue(iEntity, "hint_color", sBuffer);
    
    //Text
    ReplaceString(sText, sizeof(sText), "\n", " ");
    DispatchKeyValue(iEntity, "hint_caption", sText);
    
    DispatchSpawn(iEntity);
    AcceptEntityInput(iEntity, "ShowHint");
	
	###icons###
    "icon_bulb"
    "icon_caution"
    "icon_alert"
    "icon_alert_red"
    "icon_tip"
    "icon_skull"
    "icon_no"
    "icon_run"
    "icon_interact"
    "icon_button"
    "icon_door"
    "icon_arrow_plain"
    "icon_arrow_plain_white_dn"
    "icon_arrow_plain_white_up"
    "icon_arrow_up"
    "icon_arrow_right"
    "icon_fire"
    "icon_present"
    "use_binding"
}

stock void RemoveEntity(entity, float time = 0.0)
{
	if (time == 0.0)
	{
		if (IsValidEntity(entity))
		{
			char edictname[32];
			GetEdictClassname(entity, edictname, 32);

			if (!StrEqual(edictname, "player"))
				AcceptEntityInput(entity, "kill");
		}
	}
	else if(time > 0.0)
		CreateTimer(time, RemoveEntityTimer, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
}

public Action RemoveEntityTimer(Handle Timer, any entityRef)
{
    int entity = EntRefToEntIndex(entityRef);
    if (entity != INVALID_ENT_REFERENCE)
        RemoveEntity(entity);
    
    return (Plugin_Stop);
}
*/
stock SetClientHealth(client, counts)
{
	SetEntityHealth(client, counts);
}

stock SetClientFrags(client, counts)
{
	SetEntProp(client, Prop_Data, "m_iFrags", counts);
}

stock SetClientMVP(client, counts)
{
	CS_SetMVPCount(client, counts);
}

stock SetClientAssists(client, counts)
{
	CS_SetClientAssists(client, counts);
}

stock SetClientScore(client, counts)
{
	CS_SetClientContributionScore(client, counts);
}

stock SetClientDeaths(client, counts)
{
	SetEntProp(client, Prop_Data, "m_iDeaths", counts);
}

stock SetClientMoney(client, counts)
{
	SetEntProp(client, Prop_Send, "m_iAccount", counts);
}

stock SetClientBlind(client, counts)
{
	int targets[2];
	targets[0] = client;
	
	int duration = 1536;
	int holdtime = 1536;
	int flags;
	if(counts == 0)
	{
		flags = (0x0001 | 0x0010);
	}
	else
	{
		flags = (0x0002 | 0x0008);
	}
	
	int color[4] = { 0, 0, 0, 0 };
	color[3] = counts;
	
	Handle message = StartMessageEx(GetUserMessageId("Fade"), targets, 1);
	if(GetUserMessageType() == UM_Protobuf)
	{
		Protobuf pb = UserMessageToProtobuf(message);
		pb.SetInt("duration", duration);
		pb.SetInt("hold_time", holdtime);
		pb.SetInt("flags", flags);
		pb.SetColor("clr", color);
	}
	else
	{
		BfWrite bf = UserMessageToBfWrite(message);
		bf.WriteShort(duration);
		bf.WriteShort(holdtime);
		bf.WriteShort(flags);		
		bf.WriteByte(color[0]);
		bf.WriteByte(color[1]);
		bf.WriteByte(color[2]);
		bf.WriteByte(color[3]);
	}

	EndMessage();
}

Handle g_DrugTimers[MAXPLAYERS+1];
float g_DrugAngles[22] = {0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -30.0, -20.0, -15.0, -10.0, -5.0};

stock SetClientDrug(int target, bool create)
{
	if(create)
	{
		if(g_DrugTimers[target] == null)
		{
			CreateDrug(target);
		}	
	}
	else
	{
		if (g_DrugTimers[target] != null)
		{
			KillDrug(target);
		}
	}
}

stock CreateDrug(client)
{
	g_DrugTimers[client] = CreateTimer(1.0, Timer_Drug, client, TIMER_REPEAT);	
}

stock KillDrug(client)
{
	KillDrugTimer(client);
	
	float angs[3];
	GetClientEyeAngles(client, angs);
	
	angs[2] = 0.0;
	
	TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);	
	
	new clients[2];
	clients[0] = client;

	new duration = 1536;
	new holdtime = 1536;
	new flags = (0x0001 | 0x0010);
	new color[4] = { 0, 0, 0, 0 };

	Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
	if (GetUserMessageType() == UM_Protobuf)
	{
		Protobuf pb = UserMessageToProtobuf(message);
		pb.SetInt("duration", duration);
		pb.SetInt("hold_time", holdtime);
		pb.SetInt("flags", flags);
		pb.SetColor("clr", color);
	}
	else
	{	
		BfWrite bf = UserMessageToBfWrite(message);
		bf.WriteShort(duration);
		bf.WriteShort(holdtime);
		bf.WriteShort(flags);
		bf.WriteByte(color[0]);
		bf.WriteByte(color[1]);
		bf.WriteByte(color[2]);
		bf.WriteByte(color[3]);
	}
	
	EndMessage();
}

stock KillDrugTimer(client)
{
	KillTimer(g_DrugTimers[client]);
	g_DrugTimers[client] = null;	
}

public Action Timer_Drug(Handle timer, any client)
{
	if (!IsClientInGame(client))
	{
		KillDrugTimer(client);

		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(client))
	{
		KillDrug(client);
		
		return Plugin_Handled;
	}
	
	float angs[3];
	GetClientEyeAngles(client, angs);
	
	angs[2] = g_DrugAngles[GetRandomInt(0,100) % 20];
	
	TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);
	
	new clients[2];
	clients[0] = client;	
	
	int duration = 255;
	int holdtime = 255;
	int flags = 0x0002;
	int color[4] = { 0, 0, 0, 128 };
	color[0] = GetRandomInt(0,255);
	color[1] = GetRandomInt(0,255);
	color[2] = GetRandomInt(0,255);

	Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
	if (GetUserMessageType() == UM_Protobuf)
	{
		Protobuf pb = UserMessageToProtobuf(message);
		pb.SetInt("duration", duration);
		pb.SetInt("hold_time", holdtime);
		pb.SetInt("flags", flags);
		pb.SetColor("clr", color);
	}
	else
	{
		BfWriteShort(message, duration);
		BfWriteShort(message, holdtime);
		BfWriteShort(message, flags);
		BfWriteByte(message, color[0]);
		BfWriteByte(message, color[1]);
		BfWriteByte(message, color[2]);
		BfWriteByte(message, color[3]);
	}
	
	EndMessage();
		
	return Plugin_Handled;
}


stock ShowOverlayToClient(client, const char[] overlaypath)
{
	ClientCommand(client, "r_screenoverlay \"%s\"", overlaypath);
}

stock ShowOverlayToAll(const char[] overlaypath)
{
	for(new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client))
		{
			ShowOverlayToClient(client, overlaypath);
		}
	}
}

stock FindSendPropOffsEx(const char[] serverClass, const char[] propName)
{
	int offset = FindSendPropInfo(serverClass, propName);

	if(offset <= 0)
	{
		SetFailState("Unable to find offset \"%s::%s\"!", serverClass, propName);
	}

	return offset;
}

stock GetClientAimTargetPos(client, float pos[3]) 
{
	if(client < 1) 
	{
		return -1;
	}
	
	float vAngles[3];
	float vOrigin[3];
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceFilterAllEntities, client);
	
	TR_GetEndPosition(pos, trace);
	
	int entity = TR_GetEntityIndex(trace);
	
	CloseHandle(trace);
	
	return entity;
}

public bool TraceFilterAllEntities(entity, contentsMask, any client)
{
	if(entity == client)
	{
		return false;
	}
	
	if(entity > MaxClients)
	{
		return false;
	}
	
	if(!IsClientInGame(entity))
	{
		return false;
	}
	
	if(!IsPlayerAlive(entity))
	{
		return false;
	}

	return true;
}