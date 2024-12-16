#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>

#define CVAR_FLAGS		FCVAR_NOTIFY

int Drag_Dmg = 5;
float Drag_Interval = 1.0;
bool IsDrag[32] = {false};
bool IsChoke[32] = {false};

Handle DragHurt[32];

ConVar Cvar_Drag_Dmg, Cvar_Drag_Interval;

public void OnPluginStart()
{
	Cvar_Drag_Dmg		= CreateConVar("l4d2_tongue_drag_damage",			"5",	"Smoker的拖拽伤害.", CVAR_FLAGS, true, 1.0);
	Cvar_Drag_Interval	= CreateConVar("l4d2_tongue_drag_damage_interval",	"1.0",	"Smoker拖拽伤害的时间间隔.", CVAR_FLAGS, true, 0.1);

	Cvar_Drag_Dmg.AddChangeHook(ConVarChanged);
	Cvar_Drag_Interval.AddChangeHook(ConVarChanged);

	HookEvent("round_end",					Event_RoundEnd,				EventHookMode_PostNoCopy);
	HookEvent("tongue_grab",				Event_TongueGrab);
	HookEvent("tongue_release",				Event_TongueRelease);
	HookEvent("choke_start",				Event_ChokeStart);
	HookEvent("choke_stopped",				Event_ChokeStop);
	HookEvent("player_spawn",				Event_PlayerSpawn);
	HookEvent("player_death",				Event_PlayerDeath);

	AutoExecConfig(true, "l4d2_tongue_drag_damage_fix");//生成指定文件名的CFG.
}





// ====================================================================================================
// ConVar Changed
// ====================================================================================================

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	Drag_Dmg		= Cvar_Drag_Dmg.IntValue;
	Drag_Interval	= Cvar_Drag_Interval.FloatValue;
}





// ====================================================================================================
// Game void
// ====================================================================================================

// 地图结束
public void OnMapEnd()
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (DragHurt[i] != null)
			delete DragHurt[i];
	}
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	OnMapEnd();
}

public void Event_TongueGrab(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsSmoker(attacker))
		return;

	int client = GetClientOfUserId(GetEventInt(event, "victim"));

	if (!IsSurvivor(client))
		return;

	TimerEnd(client);
	CreateTimer(1.0, CreateDragDamageTimer, client, TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_TongueRelease(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "victim"));

	if (!IsSurvivor(client))
		return;

	TimerEnd(client);
}

public void Event_ChokeStart(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "victim"));

	if (!IsSurvivor(client))
		return;

	IsDrag[client] = false;
	IsChoke[client] = true;
}

public void Event_ChokeStop(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "victim"));

	if (!IsSurvivor(client) || !IsPlayerAlive(client))
		return;

	IsChoke[client] = false;
}

public void Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsSurvivor(client))
		return;

	TimerEnd(client);
}

public void Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsSurvivor(client))
		return;

	TimerEnd(client);
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

public Action CreateDragDamageTimer(Handle timer, int client)
{
	if (!IsSurvivor(client) || !IsPlayerAlive(client) || IsChoke[client])
		return Plugin_Continue;

	int smoker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");

	if (!IsSmoker(smoker) || !IsPlayerAlive(smoker))
		return Plugin_Continue;

	IsDrag[client] = true;
	SDKHooks_TakeDamage(client, smoker, smoker, float(Drag_Dmg));
	if (DragHurt[client] == null)
		DragHurt[client] = CreateTimer(Drag_Interval, GiveDragDamage, client, TIMER_REPEAT);
	return Plugin_Continue;
}

public Action GiveDragDamage(Handle timer, int client)
{
	if (!IsSurvivor(client) || !IsPlayerAlive(client))
	{
		DragHurt[client] = null;
		return Plugin_Stop;
	}

	int smoker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");

	if (!IsSmoker(smoker) || !IsPlayerAlive(smoker))
	{
		DragHurt[client] = null;
		return Plugin_Stop;
	}

	if (!IsDrag[client] || IsChoke[client])
		return Plugin_Continue;

	SDKHooks_TakeDamage(client, smoker, smoker, float(Drag_Dmg));
	return Plugin_Continue;
}





// ====================================================================================================
// void
// ====================================================================================================

// 结束计时器
public void TimerEnd(int client)
{
	IsDrag[client] = false;
	IsChoke[client] = false;
	if (DragHurt[client] != null)
		delete DragHurt[client];
}





// ====================================================================================================
// bool
// ====================================================================================================

public bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

public bool IsSmoker(int client)
{
	return (client > 0 &&
			client <= MaxClients &&
			IsClientInGame(client) &&
			GetClientTeam(client) == 3 &&
			GetEntProp(client, Prop_Send, "m_zombieClass") == 1);
}