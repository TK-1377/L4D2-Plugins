#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <dhooks>

#define CVAR_FLAGS		FCVAR_NOTIFY

float Incap_Lost_Interval = 0.2;
int Incap_lost_Health = 1;
bool TankInPlayNoLost = true;
bool SurvivorIsBeingRevived[32];
ConVar GIncap_Lost_Interval;
ConVar GIncap_lost_Health;
ConVar GTankInPlayNoLost;

public void OnPluginStart()
{
	GIncap_lost_Health		=  CreateConVar("l4d2_flhi_lost_health",
											"1",
											"倒地每次流失血量的值.", CVAR_FLAGS, true, 1.0);
	GIncap_Lost_Interval	=  CreateConVar("l4d2_flhi_lost_interval",
											"0.2",
											"倒地流失血量的时间间隔.", CVAR_FLAGS, true, 0.1);
	GTankInPlayNoLost		=  CreateConVar("l4d2_flhi_have_tank_no_lost",
											"1",
											"启用克局倒地不流失生命值. (0 = 禁用, 1 = 启用)", CVAR_FLAGS, true, 0.0, true, 1.0);

	GIncap_lost_Health.AddChangeHook(ConVarChanged);
	GIncap_Lost_Interval.AddChangeHook(ConVarChanged);
	GTankInPlayNoLost.AddChangeHook(ConVarChanged);

	HookEvent("player_incapacitated",		Event_PlayerIncap);
	HookEvent("player_ledge_grab",			Event_PlayerLedge);
	HookEvent("revive_begin",				Event_ReviveBegin);
	HookEvent("revive_end",					Event_ReviveEnd);

	FindConVar("survivor_incap_decay_rate").SetInt(0);

	AutoExecConfig(true, "l4d2_fast_lost_health_incap");
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
	Incap_lost_Health	= GIncap_lost_Health.IntValue;
	Incap_Lost_Interval	= GIncap_Lost_Interval.FloatValue;
	TankInPlayNoLost	= GTankInPlayNoLost.BoolValue;
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

public void Event_PlayerIncap(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsSurvivor(client) || !IsPlayerAlive(client) || !IsPlayerFallen(client))
		return;
	
	SurvivorIsBeingRevived[client] = false;
	CreateTimer(Incap_Lost_Interval, CT, client, TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_PlayerLedge(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsSurvivor(client) || !IsPlayerAlive(client) || !IsPlayerFalling(client))
		return;
	
	SurvivorIsBeingRevived[client] = false;
	CreateTimer(Incap_Lost_Interval, CT, client, TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_ReviveBegin(Event event, const char[] name, bool dontBroadcast)
{
	int subject = GetClientOfUserId(event.GetInt("subject"));

	if (!IsSurvivor(subject) || !IsPlayerAlive(subject))
		return;
	
	SurvivorIsBeingRevived[subject] = true;
}

public void Event_ReviveEnd(Event event, const char[] name, bool dontBroadcast)
{
	int subject = GetClientOfUserId(event.GetInt("subject"));

	if (!IsSurvivor(subject) || !IsPlayerAlive(subject))
		return;

	SurvivorIsBeingRevived[subject] = false;
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

// 创建计时器
public Action CT(Handle timer, int client)
{
	if (IsSurvivor(client) && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_isIncapacitated"))
		CreateTimer(Incap_Lost_Interval, FastLost, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

// 血量加速流失
public Action FastLost(Handle timer, int client)
{
	if (TankInPlayNoLost && IsHasAliveTank())
		return Plugin_Continue;
	
	if (SurvivorIsBeingRevived[client])
		return Plugin_Continue;

	if (IsSurvivor(client) && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_isIncapacitated"))
	{
		int NowHP = GetClientHealth(client);
		if (NowHP > Incap_lost_Health)
			SetEntProp(client, Prop_Send, "m_iHealth", NowHP - Incap_lost_Health);
		else
		{
			ForcePlayerSuicide(client);
			return Plugin_Stop;
		}
	}
	else
		return Plugin_Stop;

	return Plugin_Continue;
}





// ====================================================================================================
// bool
// ====================================================================================================

public bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

public bool IsHasAliveTank()
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) &&
			GetClientTeam(i) == 3 &&
			IsPlayerAlive(i) &&
			GetEntProp(i, Prop_Send, "m_zombieClass") == 8)
		{
			return true;
		}
	}
	return false;
}

public bool IsPlayerFallen(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

public bool IsPlayerFalling(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") && GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}