#if defined _zcore_lootspawner_included
  #endinput
#endif
#define _zcore_lootspawner_included

#define TYPE_NONE -1

/* Forwards */

forward bool ZCore_LootSpawner_OnPlayerLoot(int client, int entity, int type);

/* Natives */

native int ZCore_LootSpawner_RegisterLootType(char name[32], char model[256], int weight, int roundStartWeight, int maxSpawned);

native int ZCore_LootSpawner_WipeEntitysAll();
native int ZCore_LootSpawner_WipeEntitysByType(int type);

public void __pl_zcore_lootspawner_SetNTVOptional() 
{
	MarkNativeAsOptional("ZCore_LootSpawner_RegisterLootType");
	MarkNativeAsOptional("ZCore_LootSpawner_WipeEntitysAll");
	MarkNativeAsOptional("ZCore_LootSpawner_WipeEntitysByType");
}