Handle CAVR_CT_MELEE
Handle CVAR_CT_PRIMARY;
Handle CVAR_CT_SECONDARY;
Handle CAVR_TE_MELEE
Handle CVAR_TE_PRIMARY;
Handle CVAR_TE_SECONDARY;
Handle CVAR_BHOPSPEED;
Handle CVAR_BUNNYHOP;
Handle CVAR_AUTOJUMP;
Handle CVAR_BHOPTYPE;

void ConVar_OnPluginStart()
{
	CAVR_CT_MELEE = FindConVar("mp_ct_default_melee");
	CVAR_CT_PRIMARY = FindConVar("mp_ct_default_primary");
	CVAR_CT_SECONDARY = FindConVar("mp_ct_default_secondary");
	CAVR_TE_MELEE = FindConVar("mp_t_default_melee");
	CVAR_TE_PRIMARY = FindConVar("mp_t_default_melee");
	CVAR_TE_SECONDARY = FindConVar("mp_t_default_secondary");
	CVAR_AUTOJUMP = FindConVar("sv_autobunnyhopping");
	CVAR_BUNNYHOP = FindConVar("sv_enablebunnyhopping");
	CVAR_BHOPSPEED = CreateConVar("mg_bhopspeed", "250.0", "bhop speed limit", _, true, 200.0, true, 3500.0);
	CVAR_BHOPTYPE = CreateConVar("mg_bhop_limit_advanced", "1", "bhop speed limit type", _, true, 0.0, true, 1.0);

	CreateConVar("mg_randomteam", "1", "scrable team", _, true, 0.0, true, 1.0);
	CreateConVar("mg_autoburn", "1", "burn all client", _, true, 0.0, true, 1.0);
	CreateConVar("mg_burndelay", "120.0", "burn delay after round start", _, true, 60.0, true, 600.0);

	HookConVarChange(CAVR_CT_MELEE, OnSettingChanged);
	HookConVarChange(CVAR_CT_PRIMARY, OnSettingChanged);
	HookConVarChange(CVAR_CT_SECONDARY, OnSettingChanged);
	HookConVarChange(CAVR_TE_MELEE, OnSettingChanged);
	HookConVarChange(CVAR_TE_PRIMARY, OnSettingChanged);
	HookConVarChange(CVAR_TE_SECONDARY, OnSettingChanged);
	HookConVarChange(CVAR_BHOPSPEED, OnSettingChanged);
	HookConVarChange(CVAR_AUTOJUMP, OnSettingChanged);
	HookConVarChange(CVAR_BUNNYHOP, OnSettingChanged);
	
	AutoExecConfig(true, "mg_core");
}

void ConVar_OnMapStart()
{
	LockConVar();
	SetConVarString(FindConVar("sv_tags"), "CG,MG,MiniGames,MultiGames,Store,Talent", false, false);
}

public void OnConfigsExecuted()
{
	LockConVar();
}

public void OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	LockConVar();
}

void LockConVar()
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
	SetConVarInt(FindConVar("mp_limitteams"), 2);
	SetConVarInt(FindConVar("mp_autoteambalance"), 1);
	SetConVarString(CAVR_CT_MELEE, "", true, false);
	SetConVarString(CVAR_CT_PRIMARY, "", true, false);
	SetConVarString(CVAR_CT_SECONDARY, "", true, false);
	SetConVarString(CAVR_TE_MELEE, "", true, false);
	SetConVarString(CVAR_TE_PRIMARY, "", true, false);
	SetConVarString(CVAR_TE_SECONDARY, "", true, false);
	SetConVarInt(CVAR_AUTOJUMP, 1);
	g_fBhopSpeed = GetConVarFloat(CVAR_BHOPSPEED);
	g_bRealBHop = GetConVarBool(CVAR_BHOPTYPE);
	SetConVarInt(CVAR_BUNNYHOP, g_bRealBHop ? 1 : 0);
}