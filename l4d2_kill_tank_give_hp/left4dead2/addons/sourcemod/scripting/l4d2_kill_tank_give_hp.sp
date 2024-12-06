#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>

#define CVAR_FLAGS		FCVAR_NOTIFY

float GiveHPFloat = 0.20;
int GiveHPBase = 10;
int GiveHPType = 0;

ConVar Cvar_GiveHPFloat;
ConVar Cvar_GiveHPBase;
ConVar Cvar_GiveHPType;

public void OnPluginStart()
{
	Cvar_GiveHPFloat	=  CreateConVar("l4d2_kill_tank_give_hp_float",
										"0.20",
										"击杀Tank根据已损失生命值的多少比例获取额外生命值.",
										CVAR_FLAGS, true, 0.00, true, 1.00);
	Cvar_GiveHPBase		=  CreateConVar("l4d2_kill_tank_give_hp_base",
										"10",
										"击杀Tank获取生命值的基础值.",
										CVAR_FLAGS, true, 0.0, true, 100.0);
	Cvar_GiveHPType		=  CreateConVar("l4d2_kill_tank_give_hp_type",
										"0",
										"击杀Tank获取生命值的种类. (0 = 实血, 1 = 虚血)",
										CVAR_FLAGS, true, 0.0, true, 1.0);

	Cvar_GiveHPFloat.AddChangeHook(ConVarChanged);
	Cvar_GiveHPBase.AddChangeHook(ConVarChanged);
	Cvar_GiveHPType.AddChangeHook(ConVarChanged);

	HookEvent("player_death",		Event_PlayerDeath);

	AutoExecConfig(true, "l4d2_kill_tank_give_hp"); //生成指定文件名的cfg
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	GiveHPFloat	= Cvar_GiveHPFloat.FloatValue;
	GiveHPBase	= Cvar_GiveHPBase.IntValue;
	GiveHPType	= Cvar_GiveHPType.IntValue;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (!IsSurvivor(attacker) || !IsPlayerAlive(attacker) || !IsPlayerState(attacker))
		return;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsTank(client))
		return;

	int Sur_NowHP = GetClientHealth(attacker) + GetPlayerTempHealth(attacker);

	if (Sur_NowHP >= 100)
		return;
	
	int LossHP = 100 - Sur_NowHP;
	int PerGiveHP = RoundToCeil(float(LossHP) * GiveHPFloat);
	int GiveHP = PerGiveHP + GiveHPBase;

	switch (GiveHPType)
	{
		case 0 :
		{
			if (GiveHP + GetClientHealth(attacker) > 100)
				GiveHP = 100 - GetClientHealth(attacker);
			ToGiveSurvivorHealth(attacker, GiveHP, true);
			PrintToChat(attacker, "\x04[提示] \x05你击杀了一只Tank, 获得了 \x03%d \x05点实血.", GiveHP);
		}
		case 1 :
		{
			if (GiveHP + Sur_NowHP > 100)
				GiveHP = 100 - Sur_NowHP;
			ToGiveSurvivorHealth(attacker, GiveHP, false);
			PrintToChat(attacker, "\x04[提示] \x05你击杀了一只Tank, 获得了 \x03%d \x05点虚血.", GiveHP);
		}
	}
}

public void ToGiveSurvivorHealth(int survivor, int RewardHP, bool IsGiveTrueHP)
{
	int iHealth = GetClientHealth(survivor);
	int tHealth = GetPlayerTempHealth(survivor);

	if (tHealth == -1)
		tHealth = 0;
	
	if (iHealth + tHealth + RewardHP > 100)
	{
		float overhealth, fakehealth;
		overhealth = float(iHealth + tHealth + RewardHP - 100);
		fakehealth = tHealth < overhealth ? 0.0 : tHealth - overhealth;
		SetEntPropFloat(survivor, Prop_Send, "m_healthBufferTime", GetGameTime());
		SetEntPropFloat(survivor, Prop_Send, "m_healthBuffer", fakehealth);
	}

	if (IsGiveTrueHP)
	{
		SetEntProp(survivor, Prop_Send, "m_iHealth",
				(iHealth + RewardHP) < 100 ? iHealth + RewardHP : (iHealth > 100 ? iHealth : 100));
	}
	else
	{
		float thp = GetEntPropFloat(survivor, Prop_Send, "m_healthBuffer") +
					float((iHealth + RewardHP) < 100 ? RewardHP : (100 - iHealth));
		SetEntPropFloat(survivor, Prop_Send, "m_healthBufferTime", GetGameTime());
		SetEntPropFloat(survivor, Prop_Send, "m_healthBuffer", thp);
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

public bool IsTank(int client)
{
	return (client > 0 &&
			client <= MaxClients &&
			IsClientInGame(client) &&
			GetClientTeam(client) == 3 &&
			GetEntProp(client, Prop_Send, "m_zombieClass") == 8);
}

public bool IsPlayerState(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated") && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}