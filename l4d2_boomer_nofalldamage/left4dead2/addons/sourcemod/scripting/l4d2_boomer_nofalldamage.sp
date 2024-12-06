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
	if (IsBoomer(client) && (damagetype & DMG_FALL))
		return Plugin_Handled;
	return Plugin_Continue;
}

public bool IsBoomer(int client)  
{
	return (client > 0 &&
			client <= MaxClients &&
			IsClientInGame(client) &&
			GetClientTeam(client) == 3 &&
			GetEntProp(client, Prop_Send, "m_zombieClass") == 2);
}