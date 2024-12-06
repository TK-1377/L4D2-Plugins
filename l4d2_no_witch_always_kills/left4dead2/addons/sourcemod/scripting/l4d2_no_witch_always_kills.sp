#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>

public void OnPluginStart()
{}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!IsWitch(attacker))
		return Plugin_Continue;

	if (!IsSurvivor(client) || !IsPlayerAlive(client) || !IsPlayerState(client))
		return Plugin_Continue;
	
	if (damage < float(GetSurvivorHP(client)))
		return Plugin_Continue;

	SDKHooks_TakeDamage(client, 0, 0, damage);
	return Plugin_Handled;
}

public int GetSurvivorHP(int client)
{
	if (IsPlayerAlive(client))
		return GetClientHealth(client) + GetPlayerTempHealth(client);
	return 0;
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

public bool IsWitch(int entity)
{
	if (entity > MaxClients && IsValidEdict(entity))
	{
		static char classname[6];
		GetEdictClassname(entity, classname, sizeof(classname));
		return strcmp(classname, "witch") == 0;
	}
	return false;
}