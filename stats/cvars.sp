void ConVar_OnPluginStart()
{
	CAVR_CT_MELEE = FindConVar("mp_ct_default_melee");
	CVAR_CT_PRIMARY = FindConVar("mp_ct_default_primary");
	CVAR_CT_SECONDARY = FindConVar("mp_ct_default_secondary");
	CAVR_TE_MELEE = FindConVar("mp_t_default_melee");
	CVAR_TE_PRIMARY = FindConVar("mp_t_default_melee");
	CVAR_TE_SECONDARY = FindConVar("mp_t_default_secondary");
	CVAR_AUTOBHOP = CreateConVar("mg_autobhop", "1", "enable bhop speed");
	CVAR_BHOPSPEED = CreateConVar("mg_bhopspeed", "250.0", "bhop sped limit");
	CVAR_CHANGED = CreateConVar("mg_randomteam", "1", "scrable team");
	
	HookConVarChange(CAVR_CT_MELEE, OnSettingChanged);
	HookConVarChange(CVAR_CT_PRIMARY, OnSettingChanged);
	HookConVarChange(CVAR_CT_SECONDARY, OnSettingChanged);
	HookConVarChange(CAVR_TE_MELEE, OnSettingChanged);
	HookConVarChange(CVAR_TE_PRIMARY, OnSettingChanged);
	HookConVarChange(CVAR_TE_SECONDARY, OnSettingChanged);
	HookConVarChange(CVAR_AUTOBHOP, OnSettingChanged);
	HookConVarChange(CVAR_BHOPSPEED, OnSettingChanged);
	HookConVarChange(CVAR_CHANGED, OnSettingChanged);
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
	SetConVarString(CAVR_CT_MELEE, "", true, false);
	SetConVarString(CVAR_CT_PRIMARY, "", true, false);
	SetConVarString(CVAR_CT_SECONDARY, "", true, false);
	SetConVarString(CAVR_TE_MELEE, "", true, false);
	SetConVarString(CVAR_TE_PRIMARY, "", true, false);
	SetConVarString(CVAR_TE_SECONDARY, "", true, false);
	SetConVarInt(FindConVar("sv_enablebunnyhopping"), GetConVarInt(CVAR_AUTOBHOP));
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
	if(convar == CVAR_AUTOBHOP)
		SetConVarInt(FindConVar("sv_enablebunnyhopping"), StringToInt(newValue));
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