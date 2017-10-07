ArrayList g_aButtonArray;

void Button_OnPluginStart()
{
    HookEntityOutput("func_button", "OnPressed", Button_OnButtonPressed);
    
    g_aButtonArray = new ArrayList();
}

void Button_OnMapStart()
{
    g_aButtonArray.Clear();
}

void Button_OnRoundStart()
{
    //int button = -1;
    //while((button = FindEntityByClassname(button, "func_button")) != -1)
    //{
    //    SDKHookEx(button, SDKHook_Use, Button_OnButtonUse);
    //}
    
    if(GetArraySize(g_aButtonArray) > 3)
        g_aButtonArray.Erase(0);
}

public void Button_OnButtonPressed(const char[] output, int caller, int client, float delay)
{
    if(!(1 <= client <= MaxClients))
        return;

    char name[32];
    GetEntPropString(caller, Prop_Data, "m_iName", name, 32)
    PrintToChatAll("[\x0CCG\x01]   \x04%N\x01按下了[\x04按钮%04d\x01(\x10%s\x01)]", client, caller, name);
}

public Action Button_OnButtonUse(int button, int activator, int caller, UseType type, float value)
{
    if(!IsValidEdict(button) || !IsValidClient(activator))
        return Plugin_Continue;

    int iOffset = FindDataMapInfo(button, "m_bLocked");

    if(iOffset != -1 && GetEntData(button, iOffset, 1))
        return Plugin_Handled;
    
    int m_iHammerID = GetEntProp(caller, Prop_Data, "m_iHammerID");
    
    int index = FindValueInArray(g_aButtonArray, m_iHammerID);
    
    if(index != -1)
    {
        ClientCommand(activator, "play buttons/button11.wav");
        PrintCenterTextAll("<font color='#993300' size='25'>当前服务器不允许连续重复选图");
        return Plugin_Handled;
    }
    
    g_aButtonArray.Push(m_iHammerID);

    return Plugin_Continue;
}