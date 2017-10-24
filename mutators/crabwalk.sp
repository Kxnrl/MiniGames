void CrabWalk_Init()
{
    g_Mutators = Game_CrabWalk;
    PrintToChatAll(" \x02突变因子: \x07横着走");
    PrintToChatAll("本局你将无法使用+forward/+backward");
    CG_ShowGameTextAll("突变因子: 横着走\n本局你将无法使用+forward/+backward", "10.0", "57 197 187", "-1.0", "-1.0");
}

public void CrabWald_RunCmd(int &buttons, float vel[3])
{
    if(g_Mutators != Game_CrabWalk)
        return;

    vel[0] = 0.0;
    if(buttons & IN_FORWARD)
    {
        buttons &= ~IN_FORWARD;
    }
    
    if(buttons & IN_BACK)
    {
        buttons &= ~IN_BACK;
    }
}