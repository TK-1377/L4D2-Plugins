#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>

#define CVAR_FLAGS		FCVAR_NOTIFY

int HealAmount = 1;
float HealTime = 0.2;

int AlreadyHealHP[32];
int HealHPAmount[32];

ConVar Cvar_Heal_Amount;
ConVar Cvar_Heal_Time;

Handle HealTimer[32];

public void OnPluginStart()
{
	Cvar_Heal_Amount	=  CreateConVar("l4d2_first_aid_kit_heal_amount",
										"1",
										"医疗包每次缓慢回复的生命值.",
										CVAR_FLAGS, true, 1.0);
	Cvar_Heal_Time		=  CreateConVar("l4d2_first_aid_kit_heal_time",
										"0.2",
										"医疗包回复生命值的时间间隔.",
										CVAR_FLAGS, true, 0.1, true, 5.0);

	HookEvent("round_start",			Event_RoundStart,		EventHookMode_PostNoCopy);
	HookEvent("round_end",				Event_RoundEnd,			EventHookMode_PostNoCopy);
	HookEvent("heal_success",			HealSuccess);

	Cvar_Heal_Amount.AddChangeHook(ConVarChanged);
	Cvar_Heal_Time.AddChangeHook(ConVarChanged);

	AutoExecConfig(true, "l4d2_aidkithots");
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	HealAmount		= Cvar_Heal_Amount.IntValue;
	HealTime		= Cvar_Heal_Time.FloatValue;
}

public void OnPluginEnd()
{
	DeleteAllTimers();
}

public void OnMapEnd()
{
	DeleteAllTimers();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	DeleteAllTimers();
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	DeleteAllTimers();
}

public void HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int subject		= GetClientOfUserId(event.GetInt("subject"));

	if (!IsSurvivor(subject) || !IsPlayerAlive(subject) || !IsPlayerState(subject))
		return;

	int HealHP = event.GetInt("health_restored");

	SetEntProp(subject, Prop_Send, "m_iHealth", GetClientHealth(subject) - HealHP);
	AlreadyHealHP[subject] = 0;
	HealHPAmount[subject] = HealHP;

	if (HealTimer[subject] != null)
		delete HealTimer[subject];
	
	HealTimer[subject] = CreateTimer(HealTime, GiveSurHP, subject, TIMER_REPEAT);
}

public Action GiveSurHP(Handle timer, int client)
{
	if (!IsSurvivor(client) || !IsPlayerAlive(client) || !IsPlayerState(client) || AlreadyHealHP[client] >= HealHPAmount[client])
	{
		HealTimer[client] = null;
		return Plugin_Stop;
	}
	int RemainingHealAmount = HealHPAmount[client] - AlreadyHealHP[client];
	int ToHealHP = RemainingHealAmount < HealAmount ? RemainingHealAmount : HealAmount;
	ToGiveSurvivorHealth(client, ToHealHP);
	AlreadyHealHP[client] += ToHealHP;
	return Plugin_Continue;
}

public void ToGiveSurvivorHealth(int survivor, int HealHP)
{
	int iHealth = GetClientHealth(survivor);
	int tHealth = GetPlayerTempHealth(survivor);

	if (tHealth == -1)
		tHealth = 0;
	
	if (iHealth + tHealth + HealHP > 100)
	{
		float overhealth, fakehealth;
		overhealth = float(iHealth + tHealth + HealHP - 100);
		fakehealth = tHealth < overhealth ? 0.0 : tHealth - overhealth;
		SetEntPropFloat(survivor, Prop_Send, "m_healthBufferTime", GetGameTime());
		SetEntPropFloat(survivor, Prop_Send, "m_healthBuffer", fakehealth);
	}

	int HealAfterHP = iHealth + HealHP;
	SetEntProp(survivor, Prop_Send, "m_iHealth", HealAfterHP < 100 ? HealAfterHP : (iHealth > 100 ? iHealth : 100));
}

public void DeleteAllTimers()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (HealTimer[i] != null)
			delete HealTimer[i];
	}
}

public int GetPlayerTempHealth(int client)
{
	static ConVar Cvar_Pain_Pills_Decay_Rate = null;

	if (Cvar_Pain_Pills_Decay_Rate == null)
	{
		Cvar_Pain_Pills_Decay_Rate = FindConVar("pain_pills_decay_rate");
		if (Cvar_Pain_Pills_Decay_Rate == null)
			return -1;
	}

	float Buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	float BufferTimer = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
	int TempHealth = RoundToCeil(Buffer - ((GetGameTime() - BufferTimer) * Cvar_Pain_Pills_Decay_Rate.FloatValue)) - 1;
	return TempHealth < 0 ? 0 : TempHealth;
}

public bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

public bool IsPlayerState(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated") && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}