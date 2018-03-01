void ConVar_OnPluginStart()
{
    mg_restrictawp = CreateConVar("mg_restrictawp", "0", "", _, true, 0.0, true, 1.0);
    mg_slaygaygun = CreateConVar("mg_slaygaygun", "1", "", _, true, 0.0, true, 1.0);
    mg_spawn_knife = CreateConVar("mg_spawn_knife", "0", "", _, true, 0.0, true, 1.0);
    mg_spawn_pistol = CreateConVar("mg_spawn_pistol", "0", "", _, true, 0.0, true, 1.0);
    mg_spawn_kevlar = CreateConVar("mg_spawn_kevlar", "0", "", _, true, 0.0, true, 100.0);
    mg_spawn_helmet = CreateConVar("mg_spawn_helmet", "0", "", _, true, 0.0, true, 1.0);

    mp_ct_default_melee = FindConVar("mp_ct_default_melee");
    mp_ct_default_primary = FindConVar("mp_ct_default_primary");
    mp_ct_default_secondary = FindConVar("mp_ct_default_secondary");
    mp_t_default_melee = FindConVar("mp_t_default_melee");
    mp_t_default_primary = FindConVar("mp_t_default_primary");
    mp_t_default_secondary = FindConVar("mp_t_default_secondary");
    sv_autobunnyhopping = FindConVar("sv_autobunnyhopping");
    sv_enablebunnyhopping = FindConVar("sv_enablebunnyhopping");
    mg_bhopspeed = CreateConVar("mg_bhopspeed", "250.0", "bhop speed limit", _, true, 200.0, true, 3500.0);

    mg_randomteam = CreateConVar("mg_randomteam", "1", "scrable team", _, true, 0.0, true, 1.0);
    mg_wallhack_delay = CreateConVar("mg_wallhack_delay", "150.0", "how many seconds wallhack all after round start", _, true, 60.0, true, 600.0);

    HookConVarChange(mp_ct_default_melee, OnSettingChanged);
    HookConVarChange(mp_ct_default_primary, OnSettingChanged);
    HookConVarChange(mp_ct_default_secondary, OnSettingChanged);
    HookConVarChange(mp_t_default_melee, OnSettingChanged);
    HookConVarChange(mp_t_default_primary, OnSettingChanged);
    HookConVarChange(mp_t_default_secondary, OnSettingChanged);

    AutoExecConfig(true, "minigames");
}

public void OnSettingChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    LockConVar();
}

void SetConVarDefault()
{
    FindConVar("phys_pushscale").SetInt(3);
    FindConVar("phys_timescale").SetInt(1);
    FindConVar("sv_damage_print_enable").SetInt(0);
    FindConVar("sv_staminamax").SetInt(0);
    FindConVar("sv_staminajumpcost").SetInt(0);
    FindConVar("sv_staminalandcost").SetInt(0);
    FindConVar("sv_staminarecoveryrate").SetInt(0);
    FindConVar("sv_airaccelerate").SetInt(9999);
    FindConVar("sv_accelerate_use_weapon_speed").SetInt(0);
    FindConVar("sv_maxvelocity").SetInt(3500);
    FindConVar("sv_full_alltalk").SetInt(1);
    FindConVar("mp_limitteams").SetInt(0);
    FindConVar("mp_autoteambalance").SetInt(0);
}

void LockConVar()
{
    mp_ct_default_melee.SetString("", true, false);
    mp_ct_default_primary.SetString("", true, false);
    mp_ct_default_secondary.SetString("", true, false);
    mp_t_default_melee.SetString("", true, false);
    mp_t_default_primary.SetString("", true, false);
    mp_t_default_secondary.SetString("", true, false);
    FindConVar("sv_tags").SetString("MG,MiniGames,MultiGames,Shop,Talent", false, false);
}