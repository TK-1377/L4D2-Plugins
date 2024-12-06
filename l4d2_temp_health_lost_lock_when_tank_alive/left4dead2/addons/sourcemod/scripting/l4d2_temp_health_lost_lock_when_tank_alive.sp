#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>

bool TempHP_Lost_LOCK;
int Survivor_HP_Record[32];

ConVar GTankLockTempHP;

public void OnPluginStart()
{
	GTankLockTempHP = CreateConVar("l4d2_tank_lock_temp_health",		"1",			"Lock TeampHp");

	GTankLockTempHP.IntValue = 1;

	HookEvent("round_start",	Event_RoundStart,	EventHookMode_PostNoCopy);	// 回合开始
	HookEvent("player_death",	Event_PlayerDeath);								// 玩家死亡
	HookEvent("tank_spawn",		Event_TankSpawn);								// Tank生成
}






// ====================================================================================================
// Hook Event
// ====================================================================================================

// 回合开始
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	TempHP_Lost_LOCK = false;
	FindConVar("pain_pills_decay_rate").SetFloat(0.34);
	PlayerHP_Record(-1);
}

// 玩家死亡
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (GTankLockTempHP.IntValue == 0)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (IsTank(client) && TempHP_Lost_LOCK)
		CreateTimer(1.5, CheckTankAlive, false);
}

// Tank生成
public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	if (GTankLockTempHP.IntValue == 0)
		return;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsTank(client) && !TempHP_Lost_LOCK)
		CreateTimer(1.0, CheckTankAlive, true);
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

//检查Tank是否生成/死亡
public Action CheckTankAlive(Handle Timer, bool AliveCheck)
{
	if (AliveCheck)
	{
		if (!TempHP_Lost_LOCK && IsHaveTank())
		{
			TempHP_Lost_LOCK = true;
			PlayerHP_Record(0);
			FindConVar("pain_pills_decay_rate").SetFloat(0.0);
			PrintToChatAll("\x03------- Tank生成, 生还者虚血自然流逝已锁定 -------");
			SetPlayerHP();
		}
	}
	else
	{
		if (TempHP_Lost_LOCK && !IsHaveTank())
		{
			TempHP_Lost_LOCK = false;
			PlayerHP_Record(0);
			FindConVar("pain_pills_decay_rate").SetFloat(0.34);
			PrintToChatAll("\x03------- Tank死亡, 生还者虚血自然流逝已恢复 -------");
			SetPlayerHP();
		}
	}
	return Plugin_Continue;
}





// ====================================================================================================
// void
// ====================================================================================================

public void PlayerHP_Record(int Record_Type)
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsPlayerState(i))
			Survivor_HP_Record[i] = (Record_Type == -1)?-1:GetPlayerTempHealth(i);
	}
}

public void SetPlayerHP()
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) &&
			GetClientTeam(i) == 2 &&
			IsPlayerAlive(i) &&
			IsPlayerState(i) &&
			Survivor_HP_Record[i] > 0)
		{
			SetEntPropFloat(i, Prop_Send, "m_healthBufferTime", GetGameTime());
			SetEntPropFloat(i, Prop_Send, "m_healthBuffer", float(Survivor_HP_Record[i]));
		}
	}
}





// ====================================================================================================
// int
// ====================================================================================================

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
	int tempHealth = RoundToCeil(Buffer - ((GetGameTime() - BufferTimer) * GetConVarFloat(painPillsDecayCvar))) - 1;
	return tempHealth < 0 ? 0 : tempHealth;
}





// ====================================================================================================
// bool
// ====================================================================================================

public bool IsTank(int client)
{
	return (client > 0 &&
			client <= MaxClients &&
			IsClientInGame(client) &&
			GetClientTeam(client) == 3 &&
			GetEntProp(client, Prop_Send, "m_zombieClass") == 8);
}

public bool IsHaveTank()
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && GetEntProp(i, Prop_Send, "m_zombieClass") == 8 && IsPlayerAlive(i))
		{
			return true;
		}
	}
	return false;
}

public bool IsPlayerState(int client)
{
    return !GetEntProp(client, Prop_Send, "m_isIncapacitated") && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}