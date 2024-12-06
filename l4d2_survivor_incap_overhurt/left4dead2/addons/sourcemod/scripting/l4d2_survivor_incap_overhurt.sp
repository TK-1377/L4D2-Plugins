#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>

#define CVAR_FLAGS		FCVAR_NOTIFY

int Incap_Health[32];

int Incap_BaseHP = 10;
int Incap_StartHP = 250;
int Incap_EndHP = 50;

ConVar GIncap_BaseHP;
ConVar GIncap_StartHP;
ConVar GIncap_EndHP;

ConVar GSurvivor_Incap_Health;
ConVar GSurvivor_Revive_Health;

public void OnPluginStart()
{
	GIncap_BaseHP		=  CreateConVar("l4d2_survivor_overhurt_incap_base_health",
										"10",
										"幸存者倒地被救起来能获取的基础生命值.", CVAR_FLAGS, true, 1.0, true, 30.0);
	GIncap_StartHP		=  CreateConVar("l4d2_survivor_overhurt_incap_start_health",
										"250",
										"幸存者倒地被救起来时生命值高于等于多少时不进行削减?", CVAR_FLAGS, true, 1.0);
	GIncap_EndHP		=  CreateConVar("l4d2_survivor_overhurt_incap_end_health",
										"50",
										"幸存者倒地被救起来时生命值低于等于多少时会将生命值全部削减?", CVAR_FLAGS, true, 1.0);

	GIncap_BaseHP.AddChangeHook(ConVarChanged);
	GIncap_StartHP.AddChangeHook(ConVarChanged);
	GIncap_EndHP.AddChangeHook(ConVarChanged);

	HookEvent("revive_begin",			Event_ReviveBegin);											// 开始救起幸存者
	HookEvent("revive_success",			Event_ReviveSuccess);										// 救起幸存者
	HookEvent("player_spawn",			Event_PlayerSpawn);											// 玩家复活
	HookEvent("player_bot_replace",		Event_PlayerBotReplace);									// Bot替换Player
	HookEvent("bot_player_replace",		Event_BotPlayerReplace);									// Player替换Bot

	GSurvivor_Revive_Health = FindConVar("survivor_revive_health");
	GSurvivor_Incap_Health = FindConVar("survivor_incap_health");

	//生成指定文件名的CFG
	AutoExecConfig(true, "l4d2_survivor_incap_overhurt");
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
	Incap_BaseHP	= GIncap_BaseHP.IntValue;
	Incap_StartHP	= GIncap_StartHP.IntValue;
	Incap_EndHP		= GIncap_EndHP.IntValue;

	if (Incap_StartHP < Incap_EndHP)
		Incap_StartHP = Incap_EndHP;
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

// 开始救起幸存者
public void Event_ReviveBegin(Event event, const char[] name, bool dontBroadcast)
{
	int subject = GetClientOfUserId(event.GetInt("subject"));

	if (!IsSurvivor(subject) || !IsPlayerAlive(subject) || !IsPlayerFallen(subject))
		return;

	Incap_Health[subject] = GetClientHealth(subject);
}

// 救起幸存者
public void Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	if (Incap_BaseHP >= GSurvivor_Revive_Health.IntValue)
		return;

	int subject = GetClientOfUserId(event.GetInt("subject"));

	if (!IsSurvivor(subject) || !IsPlayerAlive(subject) || !IsPlayerState(subject))
		return;

	if (event.GetBool("ledge_hang"))
		return;

	if (Incap_Health[subject] >= Incap_StartHP)
		return;
	else if (Incap_Health[subject] <= Incap_EndHP)
	{
		SetEntPropFloat(subject, Prop_Send, "m_healthBufferTime", GetGameTime());
		SetEntPropFloat(subject, Prop_Send, "m_healthBuffer", float(Incap_BaseHP));
	}
	else
	{
		int Incap_AddHP = (GSurvivor_Revive_Health.IntValue - Incap_BaseHP) *
						(Incap_Health[subject] - Incap_EndHP) / (Incap_StartHP - Incap_EndHP);
		SetEntPropFloat(subject, Prop_Send, "m_healthBufferTime", GetGameTime());
		SetEntPropFloat(subject, Prop_Send, "m_healthBuffer", float(Incap_BaseHP + Incap_AddHP));
	}
}

// 玩家复活
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsSurvivor(client))
		return;
	
	Incap_Health[client] = GSurvivor_Incap_Health.IntValue;
}

// Bot替换Player
public void Event_PlayerBotReplace(Event event, char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(event.GetInt("bot"));

	if (!IsSurvivor(bot) || !IsPlayerAlive(bot) || !IsPlayerFallen(bot))
		return;

	int player = GetClientOfUserId(event.GetInt("player"));

	Incap_Health[bot] = Incap_Health[player];
	Incap_Health[player] = 0;
}

// Player替换Bot
public void Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(event.GetInt("player"));

	if (!IsSurvivor(player) || !IsPlayerAlive(player) || !IsPlayerFallen(player))
		return;

	int bot = GetClientOfUserId(event.GetInt("bot"));

	Incap_Health[player] = Incap_Health[bot];
	Incap_Health[bot] = 0;
}





// ====================================================================================================
// bool
// ====================================================================================================

public bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

public bool IsPlayerState(int client)
{
    return !GetEntProp(client, Prop_Send, "m_isIncapacitated") && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

public bool IsPlayerFallen(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}