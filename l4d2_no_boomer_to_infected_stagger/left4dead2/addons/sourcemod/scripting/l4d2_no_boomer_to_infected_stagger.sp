#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>

public void OnPluginStart()
{
}

public Action L4D2_OnStagger(int target, int source)
{
	if (IsBoomer(source) && (IsInfected(target) || IsPinned(target)))
		return Plugin_Handled;
	return Plugin_Continue;
}

public bool IsPinned(int client)
{
	if (!IsSurvivor(client))
		return false;
	return (GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0 ||
		GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0 ||
		GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0 ||
		GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0 ||
		GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0);
}

public bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

public bool IsInfected(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3;
}

public bool IsBoomer(int client)
{
	return IsInfected(client) && (GetEntProp(client, Prop_Send, "m_zombieClass") == 2);
}