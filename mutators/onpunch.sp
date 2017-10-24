void OnPunch_Init()
{
    g_Mutators = Game_OnPunch;
    PrintToChatAll(" \x02突变因子: \x07一冲到底");
    PrintToChatAll("本局你将无法使用+moveleft/+moveright且速度加倍");
    CG_ShowGameTextAll("突变因子: 一冲到底\n本局你将无法使用+moveleft/+moveright且速度加倍", "10.0", "57 197 187", "-1.0", "-1.0");
}

public void OnPunch_RunCmd(int client, int &buttons, float vel[3])
{
    if(g_Mutators != Game_OnPunch)
        return;

    SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 2.0);

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