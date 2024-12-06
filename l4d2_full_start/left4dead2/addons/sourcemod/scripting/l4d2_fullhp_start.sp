#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>

public void OnPluginStart()
{}

public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client)
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			SetEntProp(i, Prop_Send, "m_iHealth", 100);
			SetEntPropFloat(i, Prop_Send, "m_healthBufferTime", GetGameTime());
			SetEntPropFloat(i, Prop_Send, "m_healthBuffer", 0.0);
		}
	}
}