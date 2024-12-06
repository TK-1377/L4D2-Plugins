#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define KillSound		"level/bell_normal.wav"

public void OnPluginStart()
{
	HookEvent("player_death",		Event_PlayerDeath);
}

public void OnMapStart()
{
	PrecacheSound(KillSound, true);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (!IsInGameClient(attacker) || GetClientTeam(attacker) != 2 || IsFakeClient(attacker) || !IsPlayerAlive(attacker))
		return;

	int victim = GetClientOfUserId(event.GetInt("userid"));

	if (!IsInGameClient(victim) || GetClientTeam(victim) != 3)
		return;
	
	int ZombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");

	if (ZombieClass < 1 || ZombieClass > 6)
		return;

	char weapon[32];
	event.GetString("weapon", weapon, sizeof(weapon));

	if (strcmp(weapon, "pipe_bomb") == 0 || strcmp(weapon, "inferno") == 0)
		return;

	EmitSoundToClient(attacker, KillSound, _, SNDCHAN_AUTO, SNDLEVEL_CONVO, _, SNDVOL_NORMAL);
}

public bool IsInGameClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}