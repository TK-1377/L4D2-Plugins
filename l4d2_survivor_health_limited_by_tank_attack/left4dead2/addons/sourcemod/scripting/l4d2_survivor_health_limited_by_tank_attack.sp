#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>

#define CVAR_FLAGS		FCVAR_NOTIFY

bool IsTankAttack[32];
bool IsUsePills[32];

int HP_LOCK[32];
float UseTime[32];

public Plugin myinfo = 
{
	name 			= "l4d2_survivor_health_limited_by_tank_attack",
	author 			= "77",
	description 	= "幸存者被Tank攻击后将不再持续回血.",
	version 		= "1.0",
	url 			= "N/A"
}

public void OnPluginStart()
{
	HookEvent("round_start",		Event_RoundStart,		EventHookMode_PostNoCopy);		//回合开始.
	HookEvent("pills_used",			Event_PillsUsed);										//幸存者使用止痛药.
	HookEvent("adrenaline_used",	Event_AdrenalineUsed);									//幸存者使用肾上腺素.
	HookEvent("player_hurt",		Event_PlayerHurt);										//玩家受伤.
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

// 回合开始.
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 0; i < 32 ; i++)
	{
		IsTankAttack[i] = false;
		IsUsePills[i]   = false;
		UseTime[i]		= 0.0;
	}
}

// 幸存者使用止痛药.
public void Event_PillsUsed(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsSurvivor(client) || !IsPlayerAlive(client) || !IsPlayerState(client))
		return;
	
	CT(client);
}

// 幸存者使用肾上腺素.
public void Event_AdrenalineUsed(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsSurvivor(client) || !IsPlayerAlive(client) || !IsPlayerState(client))
		return;
	
	CT(client);
}

// 玩家受伤.
public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (IsSurvivor(client) && IsTank(attacker))
	{
		if (IsUsePills[client])
		{
			IsTankAttack[client] = true;
			HP_LOCK[client] = GetSurvivorHP(client);
		}
	}
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

public Action SHPCO(Handle timer, int client)
{
	if (GetGameTime() - UseTime[client] > 5.1)
	{
		IsTankAttack[client] = false;
		IsUsePills[client] = false;
		return Plugin_Stop;
	}

	if (IsSurvivor(client) && IsPlayerAlive(client) && IsPlayerState(client))
		Survivor_HP_Correct(client);
	else
	{
		IsTankAttack[client] = false;
		IsUsePills[client] = false;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}





// ====================================================================================================
// void
// ====================================================================================================

// 创建计时器
public void CT(int client)
{
	UseTime[client] = GetGameTime();
	IsUsePills[client] = true;
	CreateTimer(0.2, SHPCO, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

// 幸存者血量限制
public void Survivor_HP_Correct(int client)
{
	if (IsSurvivor(client) && IsPlayerAlive(client) && IsPlayerState(client) && IsTankAttack[client])
	{
		if (GetSurvivorHP(client) > HP_LOCK[client])
		{
			int player_hp = GetClientHealth(client);
			if (player_hp > HP_LOCK[client])
			{
				SetEntProp(client, Prop_Send, "m_iHealth", HP_LOCK[client]);
				SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
			}
			else
			{
				int set_player_thp = HP_LOCK[client] - player_hp;
				SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", float(set_player_thp));
			}
		}
	}
}





// ====================================================================================================
// int
// ====================================================================================================

// 获取幸存者总血量
public int GetSurvivorHP(int client)
{
	if (IsSurvivor(client) && IsPlayerAlive(client))
		return (GetClientHealth(client) + GetPlayerTempHealth(client));

	return 0;
}

// 获取虚血值
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
	float Gfloat = GetConVarFloat(painPillsDecayCvar);
	int tempHealth = RoundToCeil(Buffer - ((GetGameTime() - BufferTimer) * Gfloat)) - 1;
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

public bool IsTank(int client)
{
	return IsInfected(client) && (GetEntProp(client, Prop_Send, "m_zombieClass") == 8);
}

public bool IsPlayerState(int client)
{
    return !GetEntProp(client, Prop_Send, "m_isIncapacitated") && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}