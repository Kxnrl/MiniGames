void Jump_Init()
{
    g_Mutators = Game_Jump;
    PrintToChatAll(" \x02突变因子: \x07吃了炫迈");
    PrintToChatAll("本局你将一直跳跃停不下来");
    CG_ShowGameTextAll("突变因子: 吃了炫迈\n本局你将一直跳跃停不下来", "10.0", "57 197 187", "-1.0", "-1.0");
}

public void Jump_RunCmd(int &buttons)
{
    if(g_Mutators != Game_Jump)
        return;

    if(!(buttons & IN_JUMP))
    {
        buttons |= IN_JUMP;
    }
}