stock AddInFrontOf(Float:vecOrigin[3], Float:vecAngle[3], Float:units, Float:output[3])
{
	new Float:vecView[3];
	GetViewVector(vecAngle, vecView);

	output[0] = vecView[0] * units + vecOrigin[0];
	output[1] = vecView[1] * units + vecOrigin[1];
	output[2] = vecView[2] * units + vecOrigin[2];
}

stock GetViewVector(Float:vecAngle[3], Float:output[3])
{
	output[0] = Cosine(vecAngle[1] / (180 / FLOAT_PI));
	output[1] = Sine(vecAngle[1] / (180 / FLOAT_PI));
	output[2] = -Sine(vecAngle[0] / (180 / FLOAT_PI));
}

public bool:TraceFilterAllEntities(entity, contentsMask, any:client)
{
	if(entity == client){
		return false;
	}
	
	if(entity > MaxClients){
		return false;
	}
	
	if(!IsClientInGame(entity)){
		return false;
	}
	
	if(!IsPlayerAlive(entity)){
		return false;
	}
	
	return true;
}

stock GetClientAimTargetPos(client, Float:pos[3]) 
{
	if(client < 1) 
	{
		return -1;
	}
	
	decl Float:vAngles[3], Float:vOrigin[3];
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceFilterAllEntities, client);
	
	TR_GetEndPosition(pos, trace);
	
	new entity = TR_GetEntityIndex(trace);
	
	CloseHandle(trace);
	
	return entity;
}

stock GetCircuitPos(Float:center[3], Float:radius, Float:angle, Float:output[3], bool:rotate = false, bool:horizontal = false)
{
	new Float:sin=Sine(DegToRad(angle))*radius;
	new Float:cos=Cosine(DegToRad(angle))*radius;
	
	if(horizontal){
		output[0] = center[0]+sin;
		output[1] = center[1]+cos;
		output[2] = center[2];
	}
	else{
		if(rotate){
			output[0] = center[0]+sin;
			output[1] = center[1];
			output[2] = center[2]+cos;
		}
		else{
			output[0] = center[0];
			output[1] = center[1]+sin;
			output[2] = center[2]+cos;
		}
	}
}

native int ZE_GetCommander();
forward Action ZE_OnCommanderSet(client);
forward Action ZE_OnCommanderDown(client);