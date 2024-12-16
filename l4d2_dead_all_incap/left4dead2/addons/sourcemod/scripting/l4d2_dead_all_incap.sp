#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <dhooks>

public void OnPluginStart()
{
	HookEvent("player_incapacitated",	Event_IncapCheck);
	HookEvent("player_death",			Event_IncapCheck);
}

public void Event_IncapCheck(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!client || !IsClientInGame(client) || GetClientTeam(client)!= 2)
		return;
	
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !GetEntProp(i, Prop_Send, "m_isIncapacitated"))
			return;
	}

	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			ForcePlayerSuicide(i);
	}
}