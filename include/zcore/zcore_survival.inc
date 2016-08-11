#if defined _zcore_survival_included
  #endinput
#endif
#define _zcore_survival_included

/* Natives */

native int ZCore_Survival_IsSurvivor(int client);
native int ZCore_Survival_SetSurvivor(int client, bool status);

native float ZCore_Survival_GetHunger(int client, float &value);
native float ZCore_Survival_SetHunger(int client, float value);
native float ZCore_Survival_AddHunger(int client, float value);
native float ZCore_Survival_ResetHunger(int client);

native float ZCore_Survival_GetEnergy(int client, float &value);
native float ZCore_Survival_SetEnergy(int client, float value);
native float ZCore_Survival_AddEnergy(int client, float value);
native float ZCore_Survival_ResetEnergy(int client);

native float ZCore_Survival_GetThirst(int client, float &value);
native float ZCore_Survival_SetThirst(int client, float value);
native float ZCore_Survival_AddThirst(int client, float value);
native float ZCore_Survival_ResetThirst(int client);

native float ZCore_Survival_GetStamina(int client, float &value);
native float ZCore_Survival_SetStamina(int client, float value);
native float ZCore_Survival_AddStamina(int client, float value);
native float ZCore_Survival_ResetStamina(int client);

public void __pl_zcore_survival_SetNTVOptional() 
{
	MarkNativeAsOptional("ZCore_Survival_IsSurvivor");
	MarkNativeAsOptional("ZCore_Survival_SetSurvivor");
	
	MarkNativeAsOptional("ZCore_Survival_GetHunger");
	MarkNativeAsOptional("ZCore_Survival_SetHunger");
	MarkNativeAsOptional("ZCore_Survival_AddHunger");
	MarkNativeAsOptional("ZCore_Survival_ResetHunger");
	
	MarkNativeAsOptional("ZCore_Survival_GetEnergy");
	MarkNativeAsOptional("ZCore_Survival_SetEnergy");
	MarkNativeAsOptional("ZCore_Survival_AddEnergy");
	MarkNativeAsOptional("ZCore_Survival_ResetEnergy");
	
	MarkNativeAsOptional("ZCore_Survival_GetThirst");
	MarkNativeAsOptional("ZCore_Survival_SetThirst");
	MarkNativeAsOptional("ZCore_Survival_AddThirst");
	MarkNativeAsOptional("ZCore_Survival_ResetThirst");
	
	MarkNativeAsOptional("ZCore_Survival_GetStamina");
	MarkNativeAsOptional("ZCore_Survival_SetStamina");
	MarkNativeAsOptional("ZCore_Survival_AddStamina");
	MarkNativeAsOptional("ZCore_Survival_ResetStamina");
}