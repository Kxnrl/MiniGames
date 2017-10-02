enum Patch_Type
{
    Patch_A = 0,
    Patch_B = 1,
    Patch_C = 2,
    Patch_D = 3,
    Patch_E
}
#define PF_HD "[\x0ECG②周年\x01]  "
#define SIZE_OF_INT 2147483647
stock int UTIL_GetRandomInt(int min, int max)
{
    int random = GetURandomInt();
    
    if(random == 0)
        random++;

    return RoundToCeil(float(random) / (float(SIZE_OF_INT) / float(max - min + 1))) + min - 1;
}

native bool CG_GiveClientPatch(int client, Patch_Type patch);
native int CG_GetPlayerType(int client);