#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>

public void OnPluginStart()
{}

public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client)
{
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			FakeClientCommand(i, "give ammo");
	}
	SetCommandFlags("give", flags | FCVAR_CHEAT);
}