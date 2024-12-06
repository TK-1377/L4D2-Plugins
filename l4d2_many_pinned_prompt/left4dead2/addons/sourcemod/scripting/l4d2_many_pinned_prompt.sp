#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>

char Number_Text[15][6] =
{
	"双",
	"三",
	"四",
	"五",
	"六",
	"七",
	"八",
	"九",
	"十",
	"十一",
	"十二",
	"十三",
	"十四",
	"十五",
	"十六"
};

public void OnPluginStart()
{
	HookEvent("tongue_grab",			Event_TongueGrab,			EventHookMode_PostNoCopy);
	HookEvent("choke_start",			Event_SurvivorPinned,		EventHookMode_PostNoCopy);
	HookEvent("lunge_pounce",			Event_SurvivorPinned,		EventHookMode_PostNoCopy);
	HookEvent("jockey_ride",			Event_SurvivorPinned,		EventHookMode_PostNoCopy);
	HookEvent("charger_carry_start",	Event_SurvivorPinned,		EventHookMode_PostNoCopy);
	HookEvent("charger_pummel_start",	Event_SurvivorPinned,		EventHookMode_PostNoCopy);
}

public void Event_TongueGrab(Handle event, const char[] name, bool dontBroadcast)
{
	CreateTimer(1.1, DealyCheck, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_SurvivorPinned(Handle event, const char[] name, bool dontBroadcast)
{
	CheckPinnedNumber();
}

public Action DealyCheck(Handle timer)
{
	CheckPinnedNumber();
	return Plugin_Continue;
}

public void CheckPinnedNumber()
{
	int pinned_number = 0;
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) &&
			GetClientTeam(i) == 2 &&
			IsPlayerAlive(i) &&
			(GetEntPropEnt(i, Prop_Send, "m_tongueOwner") > 0 ||
			GetEntPropEnt(i, Prop_Send, "m_pounceAttacker") > 0 ||
			GetEntPropEnt(i, Prop_Send, "m_carryAttacker") > 0 ||
			GetEntPropEnt(i, Prop_Send, "m_pummelAttacker") > 0 ||
			GetEntPropEnt(i, Prop_Send, "m_jockeyAttacker") > 0))
		{
			pinned_number ++;
		}
	}

	if (pinned_number < 2)
		return;

	PrintToChatAll("\x04[提示] \x03%s控 \x05达成.", Number_Text[pinned_number - 2]);
}