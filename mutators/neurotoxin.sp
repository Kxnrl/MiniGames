void Neurotoxin_Init()
{
	g_Mutators = Game_Neurotoxin;
	PrintToChatAll(" \x02突变因子: \x07神经毒素");
	PrintToChatAll("本局你将无法使用按键颠倒且视野嘿嘿嘿");
	CreateTimer(1.0, Timer_Neurotoxin, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CG_ShowGameTextAll("突变因子: 神经毒素\n本局你将无法使用按键颠倒且视野嘿嘿嘿", "10.0", "57 197 187", "-1.0", "-1.0");
}

public void Neurotoxin_RunCmd(int client, int &buttons, float vel[3])
{
	if(g_Mutators != Game_Neurotoxin)
		return;
	
	if(g_iAuth[client] == 9999)
		return;

	vel[1] = -vel[1];
	if(buttons & IN_MOVELEFT)
	{
		buttons &= ~IN_MOVELEFT;
		buttons |= IN_MOVERIGHT;
	}
	else if(buttons & IN_MOVERIGHT)
	{
		buttons &= ~IN_MOVERIGHT;
		buttons |= IN_MOVELEFT;
	}
	vel[0] = -vel[0];
	if(buttons & IN_FORWARD)
	{
		buttons &= ~IN_FORWARD;
		buttons |= IN_BACK;
	}
	else if(buttons & IN_BACK)
	{
		buttons &= ~IN_BACK;
		buttons |= IN_FORWARD;
	}
}

public Action Timer_Neurotoxin(Handle timer)
{
	if(g_Mutators != Game_Neurotoxin)
	{
		ResetScreenAll();
		return Plugin_Stop;
	}
	
	NeurotoxinToScreen();
	
	return Plugin_Continue;
}

void NeurotoxinToScreen()
{
	int color[4] = {0, 0, 0, 233};
	color[0] = GetRandomInt(0,255);
	color[1] = GetRandomInt(0,255);
	color[2] = GetRandomInt(0,255);

	Handle message = StartMessageAll("Fade");
	PbSetInt(message, "duration", 255);
	PbSetInt(message, "hold_time", 255);
	PbSetInt(message, "flags", (0x0002 | 0x0008 | 0x0010));
	PbSetColor(message, "clr", color);
	EndMessage();
}

void ResetScreenAll()
{
	Handle message = StartMessageAll("Fade");
	PbSetInt(message, "duration", 1536);
	PbSetInt(message, "hold_time", 1536);
	PbSetInt(message, "flags", (0x0001 | 0x0010));
	PbSetColor(message, "clr", {0, 0, 0, 0});
	EndMessage();
}