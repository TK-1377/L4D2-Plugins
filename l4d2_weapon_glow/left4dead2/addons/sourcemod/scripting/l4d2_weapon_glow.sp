#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <l4d2util>

#define CVAR_FLAGS		FCVAR_NOTIFY

int
	GTPISTOL[3]			= {128, 128, 128},
	GTSMG[3]			= {  0,   0, 255},
	GTSHOTGUN[3]		= {255, 255,   0},
	GTMELEE[3]			= {255,   0,   0},
	GTAUTOSHOTGUN[3]	= {208,   0, 208},
	GTAIDKIT[3]			= {  0, 255,   0},
	GTDEFIB[3]			= {  0, 255, 255},
	GTPILLS[3]			= {  0, 128,   0},
	GTRIFLE[3]			= {164, 192, 240},
	GTSNIPER[3]			= {255,   0, 255},
	GTAWPSCOUT[3]		= {  0, 128, 128},
	GTUPAMMO[3]			= {160, 160, 164},
	GTMISSILE[3]		= {128, 128,   0},
	GTCHAINSAW[3]		= {128,   0,   0},
	GTLAUNCHER[3]		= {192, 192, 192};

int Glow_Range = 600;
bool IsFalshing = true;

ConVar GGlow_Range, GIsFalshing;
ConVar GPISTOL, GSMG, GSHOTGUN, GMELEE, GAUTOSHOTGUN, GAIDKIT, GDEFIB, GPILLS;
ConVar GRIFLE, GSNIPER, GAWPSCOUT, GUPAMMO, GMISSILE, GCHAINSAW, GLAUNCHER;

public void OnPluginStart()
{
	GGlow_Range		=  CreateConVar("l4d2_weapon_glow_a_range",
									"600",
									"武器发光距离.",
									CVAR_FLAGS, true, 0.0);
	GIsFalshing		=  CreateConVar("l4d2_weapon_glow_b_falsh",
									"1",
									"启用武器发光闪烁. (0 = 禁用, 1 = 启用)",
									CVAR_FLAGS, true, 0.0, true, 1.0);
	GPISTOL			=  CreateConVar("l4d2_weapon_glow_c_pistol",
									"128 128 128",
									"手枪 的发光颜色. (R G B)",
									CVAR_FLAGS);
	GSMG			=  CreateConVar("l4d2_weapon_glow_d_smg",
									"0 0 255",
									"冲锋枪 的发光颜色. (R G B)",
									CVAR_FLAGS);
	GSHOTGUN		=  CreateConVar("l4d2_weapon_glow_e_shotgun",
									"255 255 0",
									"单喷 的发光颜色. (R G B)",
									CVAR_FLAGS);
	GMELEE			=  CreateConVar("l4d2_weapon_glow_j_melee",
									"255 0 0",
									"近战武器 的发光颜色. (R G B)",
									CVAR_FLAGS);
	GAUTOSHOTGUN	=  CreateConVar("l4d2_weapon_glow_g_autoshotgun",
									"208 0 208",
									"连喷 的发光颜色. (R G B)",
									CVAR_FLAGS);
	GAIDKIT			=  CreateConVar("l4d2_weapon_glow_m_aidkit",
									"0 255 0",
									"医疗包 的发光颜色. (R G B)",
									CVAR_FLAGS);
	GDEFIB			=  CreateConVar("l4d2_weapon_glow_n_defibrillator",
									"0 255 255",
									"电击器 的发光颜色. (R G B)",
									CVAR_FLAGS);
	GPILLS			=  CreateConVar("l4d2_weapon_glow_o_pills_and_adrenaline",
									"0 128 0",
									"止痛药/肾上腺素 的发光颜色. (R G B)",
									CVAR_FLAGS);
	GRIFLE			=  CreateConVar("l4d2_weapon_glow_f_rifle",
									"164 192 240",
									"步枪 (包括M60) 的发光颜色. (R G B)",
									CVAR_FLAGS);
	GSNIPER			=  CreateConVar("l4d2_weapon_glow_h_sniper",
									"255 0 255",
									"连狙 的发光颜色. (R G B)",
									CVAR_FLAGS);
	GAWPSCOUT		=  CreateConVar("l4d2_weapon_glow_i_awp_and_scout",
									"0 128 128",
									"栓狙 的发光颜色. (R G B)",
									CVAR_FLAGS);
	GUPAMMO			=  CreateConVar("l4d2_weapon_glow_p_up_ammo",
									"160 160 164",
									"燃烧子弹包/高爆子弹包 的发光颜色. (R G B)",
									CVAR_FLAGS);
	GMISSILE		=  CreateConVar("l4d2_weapon_glow_q_missile",
									"128 128 0",
									"投掷物 的发光颜色. (R G B)",
									CVAR_FLAGS);
	GCHAINSAW		=  CreateConVar("l4d2_weapon_glow_k_chainsaw",
									"128 0 0",
									"电锯 的发光颜色. (R G B)",
									CVAR_FLAGS);
	GLAUNCHER		=  CreateConVar("l4d2_weapon_glow_l_grenade_launcher",
									"192 192 192",
									"榴弹发射器 的发光颜色. (R G B)",
									CVAR_FLAGS);

	GGlow_Range.AddChangeHook(ConVarChanged);
	GIsFalshing.AddChangeHook(ConVarChanged);
	GPISTOL.AddChangeHook(ConVarChanged);
	GSMG.AddChangeHook(ConVarChanged);
	GSHOTGUN.AddChangeHook(ConVarChanged);
	GMELEE.AddChangeHook(ConVarChanged);
	GAUTOSHOTGUN.AddChangeHook(ConVarChanged);
	GAIDKIT.AddChangeHook(ConVarChanged);
	GDEFIB.AddChangeHook(ConVarChanged);
	GPILLS.AddChangeHook(ConVarChanged);
	GRIFLE.AddChangeHook(ConVarChanged);
	GSNIPER.AddChangeHook(ConVarChanged);
	GAWPSCOUT.AddChangeHook(ConVarChanged);
	GUPAMMO.AddChangeHook(ConVarChanged);
	GMISSILE.AddChangeHook(ConVarChanged);
	GCHAINSAW.AddChangeHook(ConVarChanged);
	GLAUNCHER.AddChangeHook(ConVarChanged);

	//生成指定文件名的CFG.
	AutoExecConfig(true, "l4d2_weapon_glow");
}





// ====================================================================================================
// ConVar Changed
// ====================================================================================================

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	Glow_Range = GGlow_Range.IntValue;
	IsFalshing = GIsFalshing.BoolValue;
	Setting_Glow();
}

public void Setting_Glow()
{
	Get_Glow_RGB(GTPILLS, GPILLS);
	Get_Glow_RGB(GTSMG, GSMG);
	Get_Glow_RGB(GTSHOTGUN, GSHOTGUN);
	Get_Glow_RGB(GTMELEE, GMELEE);
	Get_Glow_RGB(GTAUTOSHOTGUN, GAUTOSHOTGUN);
	Get_Glow_RGB(GTAIDKIT, GAIDKIT);
	Get_Glow_RGB(GTDEFIB, GDEFIB);
	Get_Glow_RGB(GTPILLS, GPILLS);
	Get_Glow_RGB(GTRIFLE, GRIFLE);
	Get_Glow_RGB(GTSNIPER, GSNIPER);
	Get_Glow_RGB(GTAWPSCOUT, GAWPSCOUT);
	Get_Glow_RGB(GTUPAMMO, GUPAMMO);
	Get_Glow_RGB(GTMISSILE, GMISSILE);
	Get_Glow_RGB(GTCHAINSAW, GCHAINSAW);
	Get_Glow_RGB(GTLAUNCHER, GLAUNCHER);
}

public void Get_Glow_RGB(int rgb[3], ConVar Grgb)
{
	char rgb_temp[30], buffers[3][10];
	Grgb.GetString(rgb_temp, sizeof(rgb_temp));

	ExplodeString(rgb_temp, " ", buffers, sizeof(buffers), sizeof(buffers[]));
	int temp;

	for (int i = 0; i < 3 ; i++)
	{
		temp = StringToInt(buffers[i]);
		if (temp < 0 || temp > 255)
			continue;
		else
			rgb[i] = temp;
	}
}





// ====================================================================================================
// Game void
// ====================================================================================================

// 创建实体
public void OnEntityCreated(int entity, const char[] sClassName)
{
	if (!IsValidEdict(entity))
		return;

	int wepid = IdentifyWeapon(entity);

	if (wepid <= 0 || wepid > 37)
		return;

	switch (wepid)
	{
		case 1, 32 :
			ResetGlows(entity, GTPISTOL[0], GTPISTOL[1], GTPISTOL[2]);
		case 2, 7, 33 :
			ResetGlows(entity, GTSMG[0], GTSMG[1], GTSMG[2]);
		case 3, 8 :
			ResetGlows(entity, GTSHOTGUN[0], GTSHOTGUN[1], GTSHOTGUN[2]);
		case 5, 9, 26, 34, 37 :
			ResetGlows(entity, GTRIFLE[0], GTRIFLE[1], GTRIFLE[2]);
		case 4, 11 :
			ResetGlows(entity, GTAUTOSHOTGUN[0], GTAUTOSHOTGUN[1], GTAUTOSHOTGUN[2]);
		case 6, 10 :
			ResetGlows(entity, GTSNIPER[0], GTSNIPER[1], GTSNIPER[2]);
		case 35, 36 :
			ResetGlows(entity, GTAWPSCOUT[0], GTAWPSCOUT[1], GTAWPSCOUT[2]);
		case 19 :
			ResetGlows(entity, GTMELEE[0], GTMELEE[1], GTMELEE[2]);
		case 20 :
			ResetGlows(entity, GTCHAINSAW[0], GTCHAINSAW[1], GTCHAINSAW[2]);
		case 21 :
			ResetGlows(entity, GTLAUNCHER[0], GTLAUNCHER[1], GTLAUNCHER[2]);
		case 12 :
			ResetGlows(entity, GTAIDKIT[0], GTAIDKIT[1], GTAIDKIT[2]);
		case 24 :
			ResetGlows(entity, GTDEFIB[0], GTDEFIB[1], GTDEFIB[2]);
		case 15, 23 :
			ResetGlows(entity, GTPILLS[0], GTPILLS[1], GTPILLS[2]);
		case 30, 31 :
			ResetGlows(entity, GTUPAMMO[0], GTUPAMMO[1], GTUPAMMO[2]);
		case 13, 14, 25 :
			ResetGlows(entity, GTMISSILE[0], GTMISSILE[1], GTMISSILE[2]);
	}
}

// 摧毁实体
public void OnEntityDestroyed(int entity)
{
	if (!IsValidEdict(entity))
		return;

	int wepid = IdentifyWeapon(entity);

	if (wepid <= 0 || wepid > 37)
		return;
	
	RemoveGlows(entity);
}





// ====================================================================================================
// Glow
// ====================================================================================================

public void ResetGlows(int entity, int n1, int n2, int n3)
{
	SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", GetColor(n1,n2,n3));
	SetEntProp(entity, Prop_Send, "m_nGlowRange", Glow_Range);
	if (IsFalshing)
		SetEntProp(entity, Prop_Send, "m_bFlashing", 1, 1);
}

public void RemoveGlows(int entity)
{
	SetEntProp(entity, Prop_Send, "m_iGlowType", 0);
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", 0);
	SetEntProp(entity, Prop_Send, "m_nGlowRange", 0);
	SetEntProp(entity, Prop_Send, "m_bFlashing", 0, 1);
}

public int GetColor(int a1,int a2,int a3)
{
	int color;
	color = a1;
	color += 256 * a2;
	color += 65536 * a3;
	return color;
}