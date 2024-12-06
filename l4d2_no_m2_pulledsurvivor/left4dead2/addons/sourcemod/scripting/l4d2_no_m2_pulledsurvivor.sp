#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

bool SurvivorCanShove[32];

public void OnPluginStart()
{
	for (int i = 1; i <= MaxClients ; i++)
		SurvivorCanShove[i] = true;

	HookEvent("tongue_grab",		Event_TongueGrab);
}

public void Event_TongueGrab(Handle event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (!IsSurvivor(victim))
		return;
	
	SurvivorCanShove[victim] = false;
	CreateTimer(1.0, ReCold_SurvivorCanShove, victim);
}

public Action ReCold_SurvivorCanShove(Handle timer, int client)
{
	SurvivorCanShove[client] = true;
	return Plugin_Continue;
}

public Action L4D_OnShovedBySurvivor(int shover, int shovee, const float vector[3])
{
	if (!IsSurvivor(shover))
		return Plugin_Continue;
	
	if (IsSurvivor(shovee) && GetEntProp(shovee, Prop_Send, "m_tongueOwner") > 0 && !SurvivorCanShove[shovee])
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action L4D2_OnEntityShoved(int shover, int shovee_ent, int weapon, float vector[3], bool bIsHunterDeadstop)
{
	if (!IsSurvivor(shover))
		return Plugin_Continue;
	
	if (IsSurvivor(shovee_ent) && GetEntProp(shovee_ent, Prop_Send, "m_tongueOwner") > 0 && !SurvivorCanShove[shovee_ent])
		return Plugin_Handled;

	return Plugin_Continue;
}

public bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}