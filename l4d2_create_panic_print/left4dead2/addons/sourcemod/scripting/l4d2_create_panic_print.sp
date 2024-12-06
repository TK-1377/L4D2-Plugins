#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <colors>

char SearchString[5][18] =
{
	"m_tongueOwner",
	"m_pounceAttacker",
	"m_carryAttacker",
	"m_pummelAttacker",
	"m_jockeyAttacker"
};

char PinnedText[6][6] =
{
	"拖拽",
	"呕吐",
	"扑倒",
	"烫伤",
	"骑乘",
	"撞中"
};

public void OnPluginStart()
{
	HookEvent("triggered_car_alarm",		Event_TriggeredCarAlarm);
}

public void Event_TriggeredCarAlarm(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsSurvivor(client) || !IsPlayerAlive(client))
		return;

	int zombie = GetPinnedFrom(client);

	if (zombie == 0)
		CPrintToChatAll("{olive}[Car Alarm] {blue}%N {default}触发了警报车.", client);
	else
	{
		int ZombieClass = GetEntProp(zombie, Prop_Send, "m_zombieClass");
		CPrintToChatAll("{olive}[Car Alarm] {blue}%N {default}因被 {orange}%N {olive}%s {default}而触发了警报车",
						client, zombie, PinnedText[ZombieClass - 1]);
	}
}

public int GetPinnedFrom(int survivor)
{
	int zombie;
	for (int i = 0; i < 5 ; i++)
	{
		zombie = GetEntPropEnt(survivor, Prop_Send, SearchString[i]);
		if (IsInfected(zombie) && IsPlayerAlive(zombie))
			return zombie;
	}
	return 0;
}

public bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

public bool IsInfected(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3;
}