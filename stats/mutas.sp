enum Mutators
{
	Game_None,
	Game_ThirdPerson,
	Game_CrabWalk,
	Game_OnPunch,
	Game_Neurotoxin,
	Game_ChickenBoom,
	Game_TitanWar
}

Mutators g_Mutators = Game_None;

#include "mutators/thirdperson.sp"
#include "mutators/crabwalk.sp"
#include "mutators/onpunch.sp"
#include "mutators/neurotoxin.sp"

Handle g_cvarMutators;

void Mutators_OnPluginStart()
{
	g_cvarMutators = CreateConVar("mg_mutators", "1", "enable mutators", _, true, 0.0, true, 1.0);

	RegAdminCmd("sm_mutators", Command_Mutators, ADMFLAG_ROOT);
}

void Mutators_OnMapStart()
{
	
}

void Mutators_OnRoundStart()
{
	g_Mutators = Game_None;

	if(!GetConVarBool(g_cvarMutators))
		return;
	
	if(GetRandomInt(0, 10000) > 666)
		return;

	PrintToChatAll(" \x02突变因子正在重组基因...");
	
	CreateTimer(5.0, Timer_RandomMutator, _, TIMER_FLAG_NO_MAPCHANGE);
}

void Mutators_OnRoundEnd()
{
	g_Mutators = Game_None;
}

public Action Timer_RandomMutator(Handle timer)
{
	switch(GetRandomInt(1, 4))
	{
		case 1: ThirdPerson_Init();	// 第三人称视角
		case 2: CrabWalk_Init();	// 螃蟹走路
		case 3: OnPunch_Init();		// 勇往直前
		case 4: Neurotoxin_Init();	// 神经毒素
		//case 6: ChickenBoom_Init();	// 小鸡快跑
	}
}

public void Mutators_RunCmd(int client, int &buttons, float vel[3])
{
	if(g_Mutators == Game_None)
		return;
	
	CrabWald_RunCmd(buttons, vel);
	OnPunch_RunCmd(client, buttons, vel);
	Neurotoxin_RunCmd(client, buttons, vel);
}

public Action Command_Mutators(int client, int args)
{
	PrintToChatAll(" \x02突变因子正在重组基因...");
	
	CreateTimer(8.0, Timer_RandomMutator, _, TIMER_FLAG_NO_MAPCHANGE);
}