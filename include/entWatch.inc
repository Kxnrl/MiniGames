//----------------------------------------------------------------------------------------------------
// Purpose: SMLib
//----------------------------------------------------------------------------------------------------
stock Entity_GetTargetName(entity, String:buffer[], size)
{
	return GetEntPropString(entity, Prop_Data, "m_iName", buffer, size);
}

//----------------------------------------------------------------------------------------------------
// Purpose: SMLib
//----------------------------------------------------------------------------------------------------
stock Entity_GetParentName(entity, String:buffer[], size)
{
	return GetEntPropString(entity, Prop_Data, "m_iParent", buffer, size);
}

//----------------------------------------------------------------------------------------------------
// Purpose: SMLib
//----------------------------------------------------------------------------------------------------
stock Entity_GetHammerID(entity)
{
	return GetEntProp(entity, Prop_Data, "m_iHammerID");
}

native bool ZE_IsClientTakeEnt(int client);
native int ZE_BanClienEnt(int client, bool ban, bool temporary); //return -1 if set stats failed, else return 0;

forward void ZE_OnEntPickUp(int weapon, int button, int client, int ent_mode, int ent_uses, int ent_maxuses, int ent_cooldown, int ent_cooldowntime, char[] ent_name);
forward void ZE_OnEntDrop(int weapon, int button, int client, int ent_mode, int ent_uses, int ent_maxuses, int ent_cooldown, int ent_cooldowntime, char[] ent_name);
forward Action ZE_OnEntUse(int weapon, int button, int client, int ent_mode, int ent_uses, int ent_maxuses, int ent_cooldown, int ent_cooldowntime, char[] ent_name);
forward void ZE_OnEntBan(int client, int target, bool ban, bool temporary);

