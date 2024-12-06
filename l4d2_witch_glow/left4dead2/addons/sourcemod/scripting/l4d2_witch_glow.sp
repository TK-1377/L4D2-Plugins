#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>

#define CVAR_FLAGS FCVAR_NOTIFY

int Glow_Range = 1000;
int Glow_Color[3] = {128, 0 , 128};
bool GlowFlash = true;

ConVar GGlow_Range;
ConVar GGlow_Color;
ConVar GGlowFlash;

public void OnPluginStart()
{
	GGlow_Range		=  CreateConVar("l4d2_witch_glow_range",
									"1000",
									"Witch发光距离.",
									CVAR_FLAGS, true, 1.0);
	GGlow_Color		=  CreateConVar("l4d2_witch_glow_color",
									"128 0 128",
									"Witch发光颜色.",
									CVAR_FLAGS);
	GGlowFlash		=  CreateConVar("l4d2_witch_glow_flash",
									"1",
									"Witch发光是否闪烁? (0 = 否, 1 = 是)",
									CVAR_FLAGS, true, 0.0, true, 1.0);

	HookEvent("witch_spawn",		Event_WitchSpawn);

	GGlow_Range.AddChangeHook(ConVarChanged);
	GGlow_Color.AddChangeHook(ConVarChanged);
	GGlowFlash.AddChangeHook(ConVarChanged);

	AutoExecConfig(true, "l4d2_witch_glow");
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	Glow_Range	= GGlow_Range.IntValue;
	GlowFlash	= GGlowFlash.BoolValue;

	char str_Glow_Color[12], Buffers[3][4];
	GGlow_Color.GetString(str_Glow_Color, sizeof(str_Glow_Color));
	TrimString(str_Glow_Color);
	ExplodeString(str_Glow_Color, " ", Buffers, sizeof(Buffers), sizeof(Buffers[]));
	for (int i = 0; i < 3 ; i++)
	{
		int value = StringToInt(Buffers[i]);
		if (value >= 0 && value <= 255)
			Glow_Color[i] = value;
	}
}

public void Event_WitchSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int witch = event.GetInt("witchid");

	if (IsValidEdict(witch))
		SetGlows(witch);
}

public void SetGlows(int entity)
{
	SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", GetColor(Glow_Color[0], Glow_Color[1], Glow_Color[2]));
	SetEntProp(entity, Prop_Send, "m_nGlowRange", Glow_Range);
	if (GlowFlash)
		SetEntProp(entity, Prop_Send, "m_bFlashing", 1, 1);
}

public int GetColor(int red, int green, int blue)
{
	return red + 256 * green + 65536 * blue;
}