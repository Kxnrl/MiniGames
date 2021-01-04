#if defined _MovementManager_included
  #endinput
#endif
#define _MovementManager_included

// 设置玩家速度Buff
// factor   -> 1.1为提速10%
// expiry   -> 持续时间, 每次player_spawn重置
// override -> 强制覆盖设置, 如果不为true但是lifetime没到时间, 会设置失败
native bool  MovementManager_SetMaxSpeed(int client, float factor = 1.0, float expiry = 10.0, bool override = false);
native float MovementManager_GetMaxSpeed(int client);

native bool  MovementManager_SetBasicSpeed(int client, float factor);
native float MovementManager_GetBasicSpeed(int client);

/**
 * _________________Do not edit below this line!_______________________
 */
public Extension __ext_movement = 
{
	name = "MovementManager",
	file = "MovementManager.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};
