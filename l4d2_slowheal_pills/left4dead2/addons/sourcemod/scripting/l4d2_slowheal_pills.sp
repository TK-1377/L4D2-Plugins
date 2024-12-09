#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

#define CVAR_FLAGS		FCVAR_NOTIFY

bool PillSlowHeal = true, AdrenalineSlowHeal = true;
int PillHealHealth = 1, AdrenalineHealHealth = 1;
float PillHealInterval = 0.1, AdrenalineHealInterval = 0.2;
int PillHealAmount = 50, AdrenalineHealAmount = 25;

ConVar Cvar_PillSlowHeal;
ConVar Cvar_PillHealHealth;
ConVar Cvar_PillHealInterval;
ConVar Cvar_PillHealAmount;

ConVar Cvar_AdrenalineSlowHeal;
ConVar Cvar_AdrenalineHealHealth;
ConVar Cvar_AdrenalineHealInterval;
ConVar Cvar_AdrenalineHealAmount;

ConVar Cvar_Pain_Pills_Health_Value;
ConVar Cvar_Adrenaline_Health_Buffer;

int AlreadyHealHP[32];
int HealHPAmount[32];
int HealAmount[32];

int Origin_PillHealValue, Origin_AdrenalineHealValue;

Handle HealTimer[32];

public void OnPluginStart()
{
	Cvar_Pain_Pills_Health_Value		= FindConVar("pain_pills_health_value");
	Cvar_Adrenaline_Health_Buffer		= FindConVar("adrenaline_health_buffer");

	Cvar_PillSlowHeal					=  CreateConVar("l4d2_pills_hot",
														"1",
														"启用止痛药回复随时间增加生命值. (0 = 禁用, 1 = 启用)",
														CVAR_FLAGS, true, 0.0, true, 1.0);
	Cvar_PillHealInterval				=  CreateConVar("l4d2_pills_hot_interval",
														"0.1",
														"止痛药多少秒回复一次生命值",
														CVAR_FLAGS, true, 0.01);
	Cvar_PillHealHealth					=  CreateConVar("l4d2_pills_hot_increment",
														"1",
														"止痛药一次回复多少生命值",
														CVAR_FLAGS, true, 1.0);
	Cvar_PillHealAmount					=  CreateConVar("l4d2_pills_hot_total",
														"50",
														"止痛药总共回复多少生命值",
														CVAR_FLAGS, true, 1.0);
	Cvar_AdrenalineSlowHeal				=  CreateConVar("l4d2_adrenaline_hot",
														"1",
														"启用肾上腺素回复随时间增加生命值. (0 = 禁用, 1 = 启用)",
														CVAR_FLAGS, true, 0.0, true, 1.0);
	Cvar_AdrenalineHealInterval			=  CreateConVar("l4d2_adrenaline_hot_interval",
														"0.2",
														"肾上腺素多少秒回复一次生命值",
														CVAR_FLAGS, true, 0.01);
	Cvar_AdrenalineHealHealth			=  CreateConVar("l4d2_adrenaline_hot_increment",
														"1",
														"肾上腺素一次回复多少生命值",
														CVAR_FLAGS, true, 1.0);
	Cvar_AdrenalineHealAmount			=  CreateConVar("l4d2_adrenaline_hot_total",
														"25",
														"肾上腺素总共回复多少生命值",
														CVAR_FLAGS, true, 1.0);

	Cvar_PillSlowHeal.AddChangeHook(ConVarChanged);
	Cvar_PillHealInterval.AddChangeHook(ConVarChanged);
	Cvar_PillHealHealth.AddChangeHook(ConVarChanged);
	Cvar_PillHealAmount.AddChangeHook(ConVarChanged);
	Cvar_AdrenalineSlowHeal.AddChangeHook(ConVarChanged);
	Cvar_AdrenalineHealInterval.AddChangeHook(ConVarChanged);
	Cvar_AdrenalineHealHealth.AddChangeHook(ConVarChanged);
	Cvar_AdrenalineHealAmount.AddChangeHook(ConVarChanged);

	HookEvent("round_start",			Event_RoundStart,		EventHookMode_PostNoCopy);
	HookEvent("round_end",				Event_RoundEnd,			EventHookMode_PostNoCopy);
	HookEvent("adrenaline_used",		Event_AdrenalineUsed);
	HookEvent("pills_used",				Event_PillsUsed);

	SaveOriginValues();
	CheckCvars();

	AutoExecConfig(true, "l4d2_slowheal_pills");
}

public void OnPluginEnd()
{
	PillHealControl(false);
	AdrenalineHealControl(false);
	DeleteAllTimers();
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
	PillSlowHeal			= Cvar_PillSlowHeal.BoolValue;
	PillHealInterval		= Cvar_PillHealInterval.FloatValue;
	PillHealHealth			= Cvar_PillHealHealth.IntValue;
	PillHealAmount			= Cvar_PillHealAmount.IntValue;
	AdrenalineSlowHeal		= Cvar_AdrenalineSlowHeal.BoolValue;
	AdrenalineHealInterval	= Cvar_AdrenalineHealInterval.FloatValue;
	AdrenalineHealHealth	= Cvar_AdrenalineHealHealth.IntValue;
	AdrenalineHealAmount	= Cvar_AdrenalineHealAmount.IntValue;

	CheckCvars();
}

public void CheckCvars()
{
	PillHealControl(PillSlowHeal);
	AdrenalineHealControl(AdrenalineSlowHeal);
}

public void SaveOriginValues()
{
	Origin_PillHealValue		= Cvar_Pain_Pills_Health_Value.IntValue;
	Origin_AdrenalineHealValue	= Cvar_Adrenaline_Health_Buffer.IntValue;
}

public void PillHealControl(bool Enable)
{
	Cvar_Pain_Pills_Health_Value.IntValue = Enable ? 0 : Origin_PillHealValue;
}

public void AdrenalineHealControl(bool Enable)
{
	Cvar_Adrenaline_Health_Buffer.IntValue = Enable ? 0 : Origin_AdrenalineHealValue;
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	DeleteAllTimers();
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	DeleteAllTimers();
}

public void Event_PillsUsed(Event event, const char[] name, bool dontBroadcast)
{
	if (!PillSlowHeal)
		return;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsValidSurvivor(client))
		return;

	if (HealTimer[client] != null)
		delete HealTimer[client];
	
	AlreadyHealHP[client] = 0;
	HealHPAmount[client] = PillHealAmount;
	HealAmount[client] = PillHealHealth;
	HealTimer[client] = CreateTimer(PillHealInterval, ToHealSurvivor, client, TIMER_REPEAT);
}

public void Event_AdrenalineUsed(Event event, const char[] name, bool dontBroadcast)
{
	if (!AdrenalineSlowHeal)
		return;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsValidSurvivor(client))
		return;

	if (HealTimer[client] != null)
		delete HealTimer[client];
	
	AlreadyHealHP[client] = 0;
	HealHPAmount[client] = AdrenalineHealAmount;
	HealAmount[client] = AdrenalineHealHealth;
	HealTimer[client] = CreateTimer(AdrenalineHealInterval, ToHealSurvivor, client, TIMER_REPEAT);
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

public Action ToHealSurvivor(Handle timer, int client)
{
	if (!IsValidSurvivor(client) || AlreadyHealHP[client] >= HealHPAmount[client])
	{
		HealTimer[client] = null;
		return Plugin_Stop;
	}
	int RemainingHealAmount = HealHPAmount[client] - AlreadyHealHP[client];
	int ToHealHP = RemainingHealAmount < HealAmount[client] ? RemainingHealAmount : HealAmount[client];
	GiveSurTHP(client, ToHealHP, 100);
	AlreadyHealHP[client] += ToHealHP;
	return Plugin_Continue;
}

public void GiveSurTHP(int client, int amount, int max)
{
	float hb = L4D_GetTempHealth(client) + amount;
	float overflow = hb + GetClientHealth(client) - max;
	if (overflow > 0.0)
		hb -= overflow;

	L4D_SetTempHealth(client, hb);
}

public void DeleteAllTimers()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (HealTimer[i] != null)
			delete HealTimer[i];
	}
}





// ====================================================================================================
// bool
// ====================================================================================================

public bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

public bool IsPlayerState(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated") && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

public bool IsValidSurvivor(int client)
{
	return IsSurvivor(client) && IsPlayerAlive(client) && IsPlayerState(client);
}