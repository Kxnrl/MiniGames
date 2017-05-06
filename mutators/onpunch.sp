void OnPunch_Init()
{
	g_Mutators = Game_OnPunch;
	PrintToChatAll(" \x02突变因子: \x07一冲到底");
	PrintToChatAll("本局你将无法使用+moveleft/+moveright且速度加倍");
}

public void OnPunch_RunCmd(int client, int &buttons, float vel[3])
{
	if(g_Mutators != Game_OnPunch)
		return;

	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.5);

	vel[1] = 0.0;
	if(buttons & IN_MOVELEFT)
	{
		buttons &= ~IN_MOVELEFT;
	}
	
	if(buttons & IN_MOVERIGHT)
	{
		buttons &= ~IN_MOVERIGHT;
	}
}