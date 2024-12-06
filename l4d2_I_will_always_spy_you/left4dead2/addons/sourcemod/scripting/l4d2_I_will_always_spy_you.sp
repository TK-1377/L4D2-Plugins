#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <sdktools>

int ObserverTarget[32];
bool RoundEnd = true;
float DisplayTime[32];
Handle ObserverTargetCheckTimer;

public void OnPluginStart()
{
	HookEvent("round_start",			Event_RoundStart,			EventHookMode_PostNoCopy);
	HookEvent("round_end",				Event_RoundEnd,				EventHookMode_PostNoCopy);
	HookEvent("player_team",			Event_PlayerTeam);
}

public void OnMapEnd()
{
	if (ObserverTargetCheckTimer != null)
		delete ObserverTargetCheckTimer;
	RoundEnd = true;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	RoundEnd = false;
	for (int i = 1; i <= MaxClients ; i++)
		DisplayTime[i] = -30.0;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	OnMapEnd();
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	if (RoundEnd)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsValidClient(client) || IsFakeClient(client))
		return;

	int oldteam = event.GetInt("oldteam");
	int newteam = event.GetInt("team");

	if (oldteam == newteam)
		return;

	if (oldteam == 1)
	{
		ObserverTarget[client] = 0;
		return;
	}

	if (ObserverTargetCheckTimer != null && GetSpectatorNumber() == 0)
		delete ObserverTargetCheckTimer;

	if (newteam != 1)
		return;

	if (ObserverTargetCheckTimer == null)
		ObserverTargetCheckTimer = CreateTimer(0.5, ContinueCheckPlayer, _, TIMER_REPEAT);
	
	ObserverTarget[client] = 0;
	CreateTimer(0.5, DealyCheckPlayer, client);
}

public Action ContinueCheckPlayer(Handle timer)
{
	if (RoundEnd)
		return Plugin_Continue;

	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 1)
			CheckPlayer(i);
	}
	return Plugin_Continue;
}

public Action DealyCheckPlayer(Handle timer, int client)
{
	if (RoundEnd)
		return Plugin_Continue;

	if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != 1)
		return Plugin_Continue;

	CheckPlayer(client);
	return Plugin_Continue;
}

public void CheckPlayer(int client)
{
	int mode	= GetEntProp(client, Prop_Send, "m_iObserverMode");
	int target	= GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");

	if (target == -1 || (mode != 4 && mode != 5))
	{
		ObserverTarget[client] = 0;
		return;
	}

	if (target == client || target == ObserverTarget[client])
		return;

	ObserverTarget[client] = target;

	if (!IsValidClient(target))
		return;
	
	PrintHintText(client, "你正在视奸 %N", target);

	if (IsFakeClient(target))
		return;

	float GameTime = GetGameTime();

	if (GameTime - DisplayTime[target] <= 30.0)
		return;

	DisplayTime[target] = GameTime;
	PrintToChat(target, "\x04[Observer] \x03%N \x05正在视奸你.", client);
}

public int GetSpectatorNumber()
{
	int num = 0;
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 1)
			num ++;
	}
	return num;
}

public bool IsValidClientIndex(int client)
{
	return client > 0 && client <= MaxClients;
}

public bool IsValidClient(int client)
{
	return IsValidClientIndex(client) && IsClientInGame(client);
}