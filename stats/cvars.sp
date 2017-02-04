void ConVar_OnPluginStart()
{
	CAVR_CT_MELEE = FindConVar("mp_ct_default_melee");
	CVAR_CT_PRIMARY = FindConVar("mp_ct_default_primary");
	CVAR_CT_SECONDARY = FindConVar("mp_ct_default_secondary");
	CAVR_TE_MELEE = FindConVar("mp_t_default_melee");
	CVAR_TE_PRIMARY = FindConVar("mp_t_default_melee");
	CVAR_TE_SECONDARY = FindConVar("mp_t_default_secondary");
	CVAR_AUTOJUMP = FindConVar("sv_autobunnyhopping");
	CVAR_AUTOBHOP = CreateConVar("mg_autobhop", "1", "enable bhop speed", _, true, 0.0, true, 1.0);
	CVAR_BHOPSPEED = CreateConVar("mg_bhopspeed", "250.0", "bhop sped limit", _, true, 200.0, true, 3500.0);
	CVAR_CHANGED = CreateConVar("mg_randomteam", "1", "scrable team", _, true, 0.0, true, 1.0);
	CVAR_AUTOBURN = CreateConVar("mg_autoburn", "1", "burn all client", _, true, 0.0, true, 1.0);
	CVAR_BURNDELAY = CreateConVar("mg_burndelay", "120.0", "burn delay after round start", _, true, 60.0, true, 600.0);

	HookConVarChange(CAVR_CT_MELEE, OnSettingChanged);
	HookConVarChange(CVAR_CT_PRIMARY, OnSettingChanged);
	HookConVarChange(CVAR_CT_SECONDARY, OnSettingChanged);
	HookConVarChange(CAVR_TE_MELEE, OnSettingChanged);
	HookConVarChange(CVAR_TE_PRIMARY, OnSettingChanged);
	HookConVarChange(CVAR_TE_SECONDARY, OnSettingChanged);
	HookConVarChange(CVAR_AUTOBHOP, OnSettingChanged);
	HookConVarChange(CVAR_BHOPSPEED, OnSettingChanged);
	HookConVarChange(CVAR_CHANGED, OnSettingChanged);
	HookConVarChange(CVAR_AUTOJUMP, OnSettingChanged);
}

void ConVar_OnMapStart()
{
	SetConVarInt(FindConVar("sv_damage_print_enable"), 0);
	SetConVarInt(FindConVar("sv_staminamax"), 0);
	SetConVarInt(FindConVar("sv_staminajumpcost"), 0);
	SetConVarInt(FindConVar("sv_staminalandcost"), 0);
	SetConVarInt(FindConVar("sv_staminarecoveryrate"), 0);
	SetConVarInt(FindConVar("sv_airaccelerate"), 9999);
	SetConVarInt(FindConVar("sv_accelerate_use_weapon_speed"), 0);
	SetConVarInt(FindConVar("sv_maxvelocity"), 3500);
	SetConVarInt(FindConVar("sv_full_alltalk"), 1);
	SetConVarInt(FindConVar("sv_enablebunnyhopping"), 1);
	SetConVarInt(FindConVar("sv_autobunnyhopping"), 1);
	SetConVarString(FindConVar("sv_tags"), "CG,MG,MiniGames,MultiGames,Store", false, false);
}

public void OnConfigsExecuted()
{
	SetConVarInt(FindConVar("sv_damage_print_enable"), 0);
	SetConVarInt(FindConVar("sv_staminamax"), 0);
	SetConVarInt(FindConVar("sv_staminajumpcost"), 0);
	SetConVarInt(FindConVar("sv_staminalandcost"), 0);
	SetConVarInt(FindConVar("sv_staminarecoveryrate"), 0);
	SetConVarInt(FindConVar("sv_airaccelerate"), 9999);
	SetConVarInt(FindConVar("sv_accelerate_use_weapon_speed"), 0);
	SetConVarInt(FindConVar("sv_maxvelocity"), 3500);
	SetConVarInt(FindConVar("sv_full_alltalk"), 1);
	SetConVarInt(FindConVar("sv_enablebunnyhopping"), 1);
	//SetConVarInt(FindConVar("sv_autobunnyhopping"), 1);
	SetConVarString(CAVR_CT_MELEE, "", true, false);
	SetConVarString(CVAR_CT_PRIMARY, "", true, false);
	SetConVarString(CVAR_CT_SECONDARY, "", true, false);
	SetConVarString(CAVR_TE_MELEE, "", true, false);
	SetConVarString(CVAR_TE_PRIMARY, "", true, false);
	SetConVarString(CVAR_TE_SECONDARY, "", true, false);
	g_fBhopSpeed = GetConVarFloat(CVAR_BHOPSPEED);
	g_bRandomTeam = GetConVarBool(CVAR_CHANGED);
	
	if(g_bRandomTeam)
		SetConVarInt(FindConVar("mp_autoteambalance"), 0);
	else
		SetConVarInt(FindConVar("mp_autoteambalance"), 1);
}

public void OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	SetConVarString(CAVR_CT_MELEE, "", true, false);
	SetConVarString(CVAR_CT_PRIMARY, "", true, false);
	SetConVarString(CVAR_CT_SECONDARY, "", true, false);
	SetConVarString(CAVR_TE_MELEE, "", true, false);
	SetConVarString(CVAR_TE_PRIMARY, "", true, false);
	SetConVarString(CVAR_TE_SECONDARY, "", true, false);
	SetConVarInt(FindConVar("sv_enablebunnyhopping"), 1);
	if(convar == CVAR_AUTOBHOP)
		SetConVarInt(CVAR_AUTOJUMP, StringToInt(newValue));
	if(convar == CVAR_AUTOJUMP)
		SetConVarInt(CVAR_AUTOJUMP, GetConVarInt(CVAR_AUTOBHOP));
	if(convar == CVAR_BHOPSPEED)
		g_fBhopSpeed = StringToFloat(newValue);
	if(convar == CVAR_CHANGED)
	{
		g_bRandomTeam = GetConVarBool(CVAR_CHANGED);

		if(g_bRandomTeam)
			SetConVarInt(FindConVar("mp_autoteambalance"), 0);
		else
			SetConVarInt(FindConVar("mp_autoteambalance"), 1);
	}
}