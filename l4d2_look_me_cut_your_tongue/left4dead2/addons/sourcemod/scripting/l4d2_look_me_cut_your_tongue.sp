#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <l4d2util>
#include <colors>

public void OnPluginStart()
{
	HookEvent("tongue_pull_stopped",		Event_TonguePullStopped);
}

public void Event_TonguePullStopped(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!CIsValidSurvivor(attacker))
		return;

	int victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (!CIsValidSurvivor(victim))
		return;

	int smoker = GetClientOfUserId(GetEventInt(event, "smoker"));

	if (!CIsSmoker(smoker) || !IsPlayerAlive(smoker))
		return;

	if (GetEventInt(event, "release_type") != 4)
		return;

	char weapon_name[64];
	GetClientWeapon(attacker, weapon_name, sizeof(weapon_name));
	int wepid = WeaponNameToId(weapon_name);

	if (wepid != 19 && wepid != 20)
		return;

	CPrintToChatAll("{orange}★ {blue}%N {olive}砍断了 {blue}%N {default}的舌头.", attacker, smoker);
}

public bool CIsInGameClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

public bool CIsValidSurvivor(int client)
{
	return CIsInGameClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

public bool CIsSmoker(int client)
{
	return CIsInGameClient(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 1;
}