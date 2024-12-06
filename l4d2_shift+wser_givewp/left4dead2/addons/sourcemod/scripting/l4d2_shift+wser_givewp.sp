#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

bool IsShould[32] = {true, ...};
bool LeftSafeArea;

public void OnPluginStart()
{
	HookEvent("round_start",			Event_RoundStart,		EventHookMode_PostNoCopy);
}

public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client)
{
	LeftSafeArea = true;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	LeftSafeArea = false;
	for (int i = 1; i <= MaxClients ; i++)
		IsShould[i] = true;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (LeftSafeArea)
		return Plugin_Continue;
	
	if (!IsInGameClient(client) || IsFakeClient(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
		return Plugin_Continue;
	
	if (!IsShould[client])
		return Plugin_Continue;
	
	if ((buttons & IN_SPEED) && (buttons & (IN_USE | IN_RELOAD | IN_FORWARD | IN_BACK)))
	{
		IsShould[client] = false;
		CreateTimer(1.0, ReCold_GiveWeapon, client);
		L4D_RemoveWeaponSlot(client, view_as<L4DWeaponSlot>(0));
		if (buttons & IN_USE)
			Give_Client_WP(client, 1);
		else if (buttons & IN_RELOAD)
			Give_Client_WP(client, 2);
		else if (buttons & IN_FORWARD)
			Give_Client_WP(client, 3);
		else if (buttons & IN_BACK)
			Give_Client_WP(client, 4);
	}
	return Plugin_Continue;
}

public Action ReCold_GiveWeapon(Handle timer, int client)
{
	IsShould[client] = true;
	return Plugin_Continue;
}

public void Give_Client_WP(int client, int wp_type)
{
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	switch (wp_type)
	{
		case 1 :
			FakeClientCommand(client, "give smg");
		case 2 :
			FakeClientCommand(client, "give smg_silenced");
		case 3 :
			FakeClientCommand(client, "give pumpshotgun");
		case 4 :
			FakeClientCommand(client, "give shotgun_chrome");
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}

public bool IsInGameClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}