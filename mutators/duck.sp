void Duck_Init()
{
    g_Mutators = Game_Duck;
    PrintToChatAll(" \x02突变因子: \x07蹲着走");
    CG_ShowGameTextAll("突变因子: 蹲着走\n本局你将无法站立", "10.0", "57 197 187", "-1.0", "-1.0");
}

public void Duck_RunCmd(int &buttons)
{
    if(g_Mutators != Game_Duck)
        return;

    if(!(buttons & IN_DUCK))
    {
        buttons |= IN_DUCK;
    }
}