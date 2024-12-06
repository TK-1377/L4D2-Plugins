#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <left4dhooks>

#define CVAR_FLAGS		FCVAR_NOTIFY

int MyRidePlayer[32];
int MyRideDamage[32];
int IsRideEndIncap[32];
float IncapRideDamageMultiple = 1.0;

ConVar GIncapRideDamageMultiple;

ConVar GSurvivor_Max_Incapacitated_Count;
ConVar GSurvivor_Incap_Health;

public void OnPluginStart()
{
	GIncapRideDamageMultiple	=  CreateConVar("l4d2_jockey_lethal_ride_incap_dmg_multiple",
												"1.0",
												"Jockey骑乘对倒地(伪)幸存者伤害倍数.",
												CVAR_FLAGS, true, 0.01);
											
	GIncapRideDamageMultiple.AddChangeHook(ConVarChanged);

	HookEvent("round_start",			Event_RoundStart,			EventHookMode_PostNoCopy);
	HookEvent("jockey_ride",			Event_JockeyRide);
	HookEvent("jockey_ride_end",		Event_JockeyRideEnd);
	HookEvent("player_hurt",			Event_PlayerHurt);
	HookEvent("player_incapacitated",	Event_PlayerIncap);
	HookEvent("player_bot_replace",		Event_PlayerBotReplace);
	HookEvent("bot_player_replace",		Event_BotPlayerReplace);
	HookEvent("player_disconnect",		Event_PlayerDisconnect,		EventHookMode_Pre);

	GSurvivor_Max_Incapacitated_Count	= FindConVar("survivor_max_incapacitated_count");
	GSurvivor_Incap_Health				= FindConVar("survivor_incap_health");

	AutoExecConfig(true, "l4d2_jockey_lethal_ride");
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
	IncapRideDamageMultiple		= GIncapRideDamageMultiple.FloatValue;
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		MyRidePlayer[i] = 0;
		MyRideDamage[i] = 0;
		IsRideEndIncap[i] = 0;
	}
}

public void Event_JockeyRide(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("userid"));

	if (!IsJockey(attacker) || !IsPlayerAlive(attacker))
		return;

	int client = GetClientOfUserId(event.GetInt("victim"));
	
	if (!IsSurvivor(client) || !IsPlayerAlive(client) || !IsPlayerState(client))
		return;

	if (GetEntProp(client, Prop_Send, "m_currentReviveCount") >= GSurvivor_Max_Incapacitated_Count.IntValue)
		return;

	CreateTimer(0.2, ToRideSurvivor, client, TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_JockeyRideEnd(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("userid"));

	if (!IsJockey(attacker))
		return;

	int client = GetClientOfUserId(event.GetInt("victim"));

	if (!IsSurvivor(client))
		return;
	
	if (MyRidePlayer[attacker] == client && MyRideDamage[attacker] > 0 && IsPlayerAlive(client))
	{
		int Ride_Dmg = MyRideDamage[attacker];
		MyRideDamage[attacker] = 0;
		int HP = GetClientHealth(client) + GetPlayerTempHealth(client);
		if (Ride_Dmg >= HP)
			IsRideEndIncap[client] = Ride_Dmg - HP + 1;
		SDKHooks_TakeDamage(client, 0, 0, float(Ride_Dmg));
	}
	MyRidePlayer[attacker] = 0;
	MyRideDamage[attacker] = 0;
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsSurvivor(client) || !IsPlayerAlive(client) || !IsPlayerState(client))
		return;

	if (GetEntProp(client, Prop_Send, "m_currentReviveCount") >= GSurvivor_Max_Incapacitated_Count.IntValue)
		return;
	
	int jockey = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");

	if (!IsJockey(jockey) || !IsPlayerAlive(jockey) || MyRidePlayer[jockey] != client)
		return;

	int attacker	= GetClientOfUserId(event.GetInt("attacker"));
	int entity		= event.GetInt("attackerentid");

	//if ((!IsInfected(attacker) || !IsPlayerAlive(attacker)) && !IsCommonInfected(entity) && !IsWitch(entity))
	if ((!IsInfected(attacker) ||
		!IsPlayerAlive(attacker) ||
		GetEntProp(attacker, Prop_Send, "m_zombieClass") == 8)
		&& !IsWitch(entity))
	{
		return;
	}

	int iDmg		= event.GetInt("dmg_health");

	int NowHP = GetClientHealth(client);
	SetEntProp(client, Prop_Send, "m_iHealth", NowHP + iDmg);

	bool SurvivorIsIncap = false;

	if (MyRideDamage[jockey] >= (NowHP + GetPlayerTempHealth(client)))
		SurvivorIsIncap = true;

	if (jockey == attacker && SurvivorIsIncap)
		MyRideDamage[jockey] += RoundToNearest(iDmg * IncapRideDamageMultiple);
	else
		MyRideDamage[jockey] += iDmg;

	if ((IsTheLastStateSurvivor(client) && SurvivorIsIncap) ||
		MyRideDamage[jockey] >= (NowHP + GetPlayerTempHealth(client) + GSurvivor_Incap_Health.IntValue))
	{
		MyRideDamage[jockey] = 0;
		ForcePlayerSuicide(client);
	}
}

public void Event_PlayerIncap(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (!IsSurvivor(client) || !IsPlayerAlive(client) || IsRideEndIncap[client] <= 0)
		return;

	SetEntProp(client, Prop_Send, "m_iHealth", GSurvivor_Incap_Health.IntValue + 1 - IsRideEndIncap[client]);
	IsRideEndIncap[client] = 0;
}

public void Event_PlayerBotReplace(Event event, char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(event.GetInt("bot"));

	if (!IsJockey(bot) || !IsPlayerAlive(bot))
		return;

	int player = GetClientOfUserId(event.GetInt("player"));

	if (MyRidePlayer[player] <= 0 || MyRideDamage[player] <= 0)
		return;

	MyRidePlayer[bot] = MyRidePlayer[player];
	MyRideDamage[bot] = MyRideDamage[player];
	MyRidePlayer[player] = 0;
	MyRideDamage[player] = 0;
}

public void Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(event.GetInt("player"));

	if (!IsJockey(player) || !IsPlayerAlive(player))
		return;

	int bot = GetClientOfUserId(event.GetInt("bot"));

	if (MyRidePlayer[bot] <= 0 || MyRideDamage[bot] <= 0)
		return;

	MyRidePlayer[player] = MyRidePlayer[bot];
	MyRideDamage[player] = MyRideDamage[bot];
	MyRidePlayer[bot] = 0;
	MyRideDamage[bot] = 0;
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsInfected(client) || !IsFakeClient(client))
		return;

	int victim = MyRidePlayer[client];
	
	if (IsSurvivor(victim) && IsPlayerAlive(victim) && MyRideDamage[client] > 0)
	{
		int Ride_Dmg = MyRideDamage[client];
		MyRideDamage[client] = 0;
		int HP = GetClientHealth(victim) + GetPlayerTempHealth(victim);
		if (Ride_Dmg >= HP)
			IsRideEndIncap[victim] = Ride_Dmg - HP + 1;
		SDKHooks_TakeDamage(victim, 0, 0, float(Ride_Dmg));
	}

	MyRidePlayer[client] = 0;
	MyRideDamage[client] = 0;
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

public Action ToRideSurvivor(Handle timer, int client)
{
	if (!IsSurvivor(client) || !IsPlayerAlive(client) || !IsPlayerState(client))
		return Plugin_Continue;

	int jockey = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");

	if (!IsJockey(jockey) || !IsPlayerAlive(jockey))
		return Plugin_Continue;

	if (GetEntProp(client, Prop_Send, "m_currentReviveCount") >= GSurvivor_Max_Incapacitated_Count.IntValue)
		return Plugin_Continue;

	MyRidePlayer[jockey] = client;
	MyRideDamage[jockey] = 0;
	return Plugin_Continue;
}





// ====================================================================================================
// int
// ====================================================================================================

public int GetPlayerTempHealth(int client)
{
	static Handle painPillsDecayCvar = null;
	if (painPillsDecayCvar == null)
	{
		painPillsDecayCvar = FindConVar("pain_pills_decay_rate");
		if (painPillsDecayCvar == null)
			return -1;
	}

	float Buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	float BufferTimer = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
	int tempHealth = RoundToCeil(Buffer - ((GetGameTime() - BufferTimer) * GetConVarFloat(painPillsDecayCvar))) - 1;
	return tempHealth < 0 ? 0 : tempHealth;
}





// ====================================================================================================
// bool
// ====================================================================================================

public bool IsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

public bool IsInfected(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3);
}

public bool IsPlayerState(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated") && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

public bool IsJockey(int client)
{
	return (IsInfected(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == 5);
}

/*public bool IsCommonInfected(int entity)
{
	if (!IsValidEdict(entity))
		return false;

	char classname[32];
	GetEdictClassname(entity, classname, sizeof(classname));
	return (strcmp(classname, "infected") == 0);
}*/

public bool IsWitch(int entity)
{
	if (entity <= MaxClients || !IsValidEdict(entity))
		return false;

	char classname[6];
	GetEdictClassname(entity, classname, sizeof(classname));
	return (strcmp(classname, "witch") == 0);
}

public bool IsTheLastStateSurvivor(int client)
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsPlayerState(i) && i != client)
			return false;
	}
	return true;
}