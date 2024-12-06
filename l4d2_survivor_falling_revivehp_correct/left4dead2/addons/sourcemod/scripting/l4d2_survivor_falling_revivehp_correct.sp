#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

int Player_FallenHP[32] = {100, ...};
bool PlayerIsFalling[32] = {false, ...};

public void OnPluginStart()
{
	HookEvent("player_ledge_grab",				Event_PlayerLedgeGrab);
	HookEvent("revive_success",					Event_ReviveSuccess);
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

public void Event_PlayerLedgeGrab(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsAliveSurvivor(client) || !IsPlayerFalling(client))
		return;
	
	PlayerIsFalling[client] = true;
}

public void Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int subject = GetClientOfUserId(event.GetInt("subject"));

	if (!IsAliveSurvivor(subject) || !PlayerIsFalling[subject])
		return;

	PlayerIsFalling[subject] = false;
	CreateTimer(0.1, SetHP, subject);
}





// ====================================================================================================
// Game Action
// ====================================================================================================

public Action L4D_OnLedgeGrabbed(int client)
{
	if (!IsAliveSurvivor(client) || !IsPlayerState(client))
		return Plugin_Continue;

	Player_FallenHP[client] = GetClientHealth(client);
	return Plugin_Continue;
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

public Action SetHP(Handle timer, int client)
{
	if (!IsAliveSurvivor(client) || !IsPlayerState(client))
		return Plugin_Continue;

	int NowHP = GetClientHealth(client);
	int NowTHP = GetPlayerTempHealth(client);

	int GetTHP = Player_FallenHP[client] - NowHP;
	if (GetTHP < 1)
		return Plugin_Continue;
	
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", float(NowTHP + GetTHP + 1));
	Player_FallenHP[client] = NowHP;
	return Plugin_Continue;
}





// ====================================================================================================
// int
// ====================================================================================================

public int GetPlayerTempHealth(int client)
{
	static Handle painPillsDecayCvar = null;
	if (painPillsDecayCvar == null)
	{
		painPillsDecayCvar = FindConVar("pain_pills_decay_rate");
		if (painPillsDecayCvar == null)
			return -1;
	}

	float Buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	float BufferTimer = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
	float Gfloat = GetConVarFloat(painPillsDecayCvar);
	int tempHealth = RoundToCeil(Buffer - ((GetGameTime() - BufferTimer) * Gfloat)) - 1;
	return tempHealth < 0 ? 0 : tempHealth;
}





// ====================================================================================================
// bool
// ====================================================================================================

public bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

public bool IsAliveSurvivor(int client)
{
	return	IsSurvivor(client) && IsPlayerAlive(client);
}

public bool IsPlayerState(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated") && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

public bool IsPlayerFalling(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") && GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}