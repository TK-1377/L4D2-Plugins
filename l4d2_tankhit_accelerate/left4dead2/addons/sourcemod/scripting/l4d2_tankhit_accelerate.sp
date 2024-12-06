#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>

#define CVAR_FLAGS		FCVAR_NOTIFY

float TankHit_ACFloat = 1.5;
float TankHit_ACTimer = 3.0;
int TankHit_ACNum[32];

ConVar GTankHit_ACFloat;
ConVar GTankHit_ACTimer;

public void OnPluginStart()
{
	GTankHit_ACFloat	=  CreateConVar("l4d2_tank_hit_accelerate_float",
										"1.5",
										"被Tank攻击后的加速倍率.", CVAR_FLAGS, true, 0.01);
	GTankHit_ACTimer	=  CreateConVar("l4d2_tank_hit_accelerate_time",
										"3.0",
										"被Tank攻击后的加速时间.", CVAR_FLAGS, true, 0.1);

	GTankHit_ACFloat.AddChangeHook(ConVarChanged);
	GTankHit_ACTimer.AddChangeHook(ConVarChanged);

	
	HookEvent("round_start",		Event_RoundStart,		EventHookMode_PostNoCopy);
	HookEvent("player_hurt",		Event_PlayerHurt);

	AutoExecConfig(true, "l4d2_tankhit_accelerate");
}





// ====================================================================================================
// ConVar Changed
// ====================================================================================================

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

public void GetCvars()
{
	TankHit_ACFloat	= GTankHit_ACFloat.FloatValue;
	TankHit_ACTimer	= GTankHit_ACTimer.FloatValue;
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		TankHit_ACNum[i] = 0;
		if (IsClientInGame(i) && GetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue") > 1.0)
			SetSpeed(i, 1.0);
	}
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (TankHit_ACFloat <= 1.0)
		return;

	int client		= GetClientOfUserId(event.GetInt("userid"));

	if (!IsValidSurvivor(client))
		return;

	int attacker	= GetClientOfUserId(event.GetInt("attacker"));

	if (!IsTank(attacker))
		return;

	SetSpeed(client, TankHit_ACFloat);
	TankHit_ACNum[client] ++;
	CreateTimer(TankHit_ACTimer, ReSpeed, client, TIMER_FLAG_NO_MAPCHANGE);
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

public Action ReSpeed(Handle timer, int client)
{
	if (TankHit_ACNum[client] > 0)
		TankHit_ACNum[client] --;
	
	if (TankHit_ACNum[client] <= 0)
	{
		if (IsClientInGame(client))
			SetSpeed(client, 1.0);
	}
	return Plugin_Continue;
}





// ====================================================================================================
// void
// ====================================================================================================

public void SetSpeed(int client, float speed)
{
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", speed);
}





// ====================================================================================================
// bool
// ====================================================================================================

public bool IsValidSurvivor(int client)
{
	return (client > 0 &&
			client <= MaxClients &&
			IsClientInGame(client) &&
			GetClientTeam(client) == 2 &&
			IsPlayerAlive(client) &&
			IsPlayerState(client));
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