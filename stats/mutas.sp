enum Mutators
{
	Game_None,
	Game_ThirdPerson,
	Game_CrabWalk,
	Game_OnPunch,
	Game_Neurotoxin,
	Game_ChickenBoom,
	Game_Wallhack,
	Game_Duck,
	Game_Jump
}

bool g_bCamp[MAXPLAYERS+1];
bool g_bSlap[MAXPLAYERS+1];
Mutators g_Mutators = Game_None;

#include "mutators/thirdperson.sp"
#include "mutators/crabwalk.sp"
#include "mutators/onpunch.sp"
#include "mutators/neurotoxin.sp"
#include "mutators/wallhack.sp"
#include "mutators/duck.sp"
#include "mutators/jump.sp"

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
	
	if(GetRandomInt(0, 10000) > 1000)
		return;

	PrintToChatAll(" \x02突变因子正在重组基因...");
	CG_ShowGameTextAll("突变因子正在重组基因...", "5.0", "57 197 187", "-1.0", "-1.0");
	CreateTimer(5.0, Timer_RandomMutator, _, TIMER_FLAG_NO_MAPCHANGE);
}

void Mutators_OnRoundEnd()
{
	g_Mutators = Game_None;
}

public Action Timer_RandomMutator(Handle timer)
{
	switch(GetRandomInt(1, 7))
	{
		case 1: ThirdPerson_Init();	// 第三人称视角
		case 2: CrabWalk_Init();	// 螃蟹走路
		case 3: OnPunch_Init();		// 勇往直前
		case 4: Neurotoxin_Init();	// 神经毒素
		case 5: Wallhack_Init();	// 透视
		case 6: Duck_Init();		// 强制蹲
		case 7: Jump_Init();
		//case 6: ChickenBoom_Init();	// 小鸡快跑
	}
}

public void Mutators_RunCmd(int client, int &buttons, float vel[3])
{
	if(g_Mutators == Game_None)
		return;
	
	g_bCamp[client] = (GetVectorLength(vel) < 125.0) ? true : false;

	Duck_RunCmd(buttons);
	Jump_RunCmd(buttons);
	CrabWald_RunCmd(buttons, vel);
	OnPunch_RunCmd(client, buttons, vel);
	Neurotoxin_RunCmd(client, buttons, vel);
}

public Action Command_Mutators(int client, int args)
{
	PrintToChatAll(" \x02突变因子正在重组基因...");
	CG_ShowGameTextAll("突变因子正在重组基因...", "5.0", "57 197 187", "-1.0", "-1.0");
	CreateTimer(5.0, Timer_RandomMutator, _, TIMER_FLAG_NO_MAPCHANGE);
}

void Mutators_OnClientDeath(int client)
{
	g_bCamp[client] = false;
}

void Mutators_OnGlobalTimer(int client)
{
	if(g_Mutators == Game_None)
		return;

	if(!g_bCamp[client])
		return;
	
	if(!g_bSlap[client])
	{
		g_bSlap[client] = true;
		return;
	}
	
	g_bSlap[client] = false;

	PrintCenterText(client, "突变因子: 你现在处于蹲坑状态!\n    遭遇了天谴");

	if(g_iAuth[client] == 9999)
	{
		int hp = GetClientHealth(client);
		if(hp - 3 > 0)
			SetEntityHealth(client, hp-3);
		else
			SetEntityHealth(client, 1);
	}
	else
		SlapPlayer(client, 5, true);
}