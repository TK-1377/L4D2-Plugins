#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <l4d2util>

bool EmptySwitchTo[32][5];
bool ReplaceSwitchTo[32][5];
bool WeaponIsDroping[32][5];
bool IsHoldWeaponDrop[32][5];

public void OnPluginStart()
{
	HookEvent("round_start",			Event_RoundStart,			EventHookMode_PostNoCopy);
	HookEvent("player_death",			Event_PlayerDeath);
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients ; i++)
		ResetClient(i);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2)
		return;
	
	ResetClient(client);
}





// ====================================================================================================
// SDKHook
// ====================================================================================================

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponEquip, WeaponEquip);
	SDKHook(client, SDKHook_WeaponDrop, WeaponDrop);
	SDKHook(client, SDKHook_WeaponCanSwitchTo, WeaponCanSwitchTo);
}

public void OnClientDisconnect_Post(int client)
{
	SDKUnhook(client, SDKHook_WeaponEquip, WeaponEquip);
	SDKUnhook(client, SDKHook_WeaponDrop, WeaponDrop);
	SDKUnhook(client, SDKHook_WeaponCanSwitchTo, WeaponCanSwitchTo);
}





// ====================================================================================================
// Game Action
// ====================================================================================================

public Action WeaponEquip(int client, int weapon)
{
	if (!CIsValidSurvivor(client))
		return Plugin_Continue;

	if (!IsValidEntity(weapon) || IdentifyWeapon(weapon) <= 0)
		return Plugin_Continue;

	int wepid			= IdentifyWeapon(weapon);
	int wep_slot		= GetSlotFromWeaponId(wepid);

	if (wep_slot < 0 || wep_slot > 4)
		return Plugin_Continue;

	int player_weapon	= GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	int player_wepid	= IdentifyWeapon(player_weapon);

	if ((wepid == 1 && player_wepid != 32) || (wepid == 32 && player_wepid != 1))
	{
		WeaponIsDroping[client][wep_slot] = true;
		CreateTimer(0.1, ReCold_WeaponIsDroping, (client * 10 + wep_slot), TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Continue;
	}

	if (IsHoldWeaponDrop[client][wep_slot])
		return Plugin_Continue;

	if (WeaponIsDroping[client][wep_slot])
	{
		ReplaceSwitchTo[client][wep_slot] = true;
		CreateTimer(0.1, ReCold_ReplaceSwitchTo, (client * 10 + wep_slot), TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		EmptySwitchTo[client][wep_slot] = true;
		CreateTimer(0.1, ReCold_EmptySwitchTo, (client * 10 + wep_slot), TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action WeaponDrop(int client, int weapon)
{
	if (!CIsValidSurvivor(client))
		return Plugin_Continue;

	if (!IsValidEntity(weapon) || IdentifyWeapon(weapon) <= 0)
		return Plugin_Continue;
	
	int wepid			= IdentifyWeapon(weapon);
	int wep_slot		= GetSlotFromWeaponId(wepid);

	if (wep_slot < 0 || wep_slot > 4)
		return Plugin_Continue;

	int player_weapon	= GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	int player_wepid	= IdentifyWeapon(player_weapon);
	int player_slot		= GetSlotFromWeaponId(player_wepid);

	if (wep_slot == player_slot)
	{
		IsHoldWeaponDrop[client][wep_slot] = true;
		CreateTimer(0.1, ReCold_IsHoldWeaponDrop, (client * 10 + wep_slot), TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Continue;
	}

	if (wep_slot == 1 && WeaponIsDroping[client][wep_slot])
	{
		ReplaceSwitchTo[client][wep_slot] = !IsHoldWeaponDrop[client][wep_slot];
		CreateTimer(0.1, ReCold_ReplaceSwitchTo, (client * 10 + wep_slot), TIMER_FLAG_NO_MAPCHANGE);
	}

	WeaponIsDroping[client][wep_slot] = true;
	CreateTimer(0.1, ReCold_WeaponIsDroping, (client * 10 + wep_slot), TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action WeaponCanSwitchTo(int client, int weapon)
{
	if (!CIsValidSurvivor(client))
		return Plugin_Continue;

	if (!IsValidEntity(weapon) || IdentifyWeapon(weapon) <= 0)
		return Plugin_Continue;

	int wepid			= IdentifyWeapon(weapon);
	int wep_slot		= GetSlotFromWeaponId(wepid);

	if (wep_slot < 0 || wep_slot > 4)
		return Plugin_Continue;

	if (EmptySwitchTo[client][wep_slot])
	{
		if (wep_slot > 1)
			return Plugin_Stop;
		return Plugin_Continue;
	}
	else
	{
		if (ReplaceSwitchTo[client][wep_slot])
			return Plugin_Stop;
		return Plugin_Continue;
	}
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

public Action ReCold_EmptySwitchTo(Handle timer, int client_and_slot)
{
	int slot = client_and_slot % 10;
	int client = client_and_slot / 10;
	EmptySwitchTo[client][slot] = false;
	return Plugin_Continue;
}

public Action ReCold_ReplaceSwitchTo(Handle timer, int client_and_slot)
{
	int slot = client_and_slot % 10;
	int client = client_and_slot / 10;
	ReplaceSwitchTo[client][slot] = false;
	return Plugin_Continue;
}

public Action ReCold_WeaponIsDroping(Handle timer, int client_and_slot)
{
	int slot = client_and_slot % 10;
	int client = client_and_slot / 10;
	WeaponIsDroping[client][slot] = false;
	return Plugin_Continue;
}

public Action ReCold_IsHoldWeaponDrop(Handle timer, int client_and_slot)
{
	int slot = client_and_slot % 10;
	int client = client_and_slot / 10;
	IsHoldWeaponDrop[client][slot] = false;
	return Plugin_Continue;
}





// ====================================================================================================
// void
// ====================================================================================================

public void ResetClient(int client)
{
	for (int i = 0; i < 5 ; i++)
	{
		EmptySwitchTo[client][i] = false;
		ReplaceSwitchTo[client][i] = false;
		WeaponIsDroping[client][i] = false;
		IsHoldWeaponDrop[client][i] = false;
	}
}





// ====================================================================================================
// bool
// ====================================================================================================

public bool CIsAliveSurvivor(int client)
{
	return (client > 0 &&
			client <= MaxClients &&
			IsClientInGame(client) &&
			GetClientTeam(client) == 2 &&
			IsPlayerAlive(client));
}

public bool CIsValidSurvivor(int client)
{
	return CIsAliveSurvivor(client) && !IsFakeClient(client);
}