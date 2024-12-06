#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>
#include <sdktools>

#define CVAR_FLAGS		FCVAR_NOTIFY

bool TankRun = false;
bool LeaveSafeArea = false;
bool CanSpawnTank = true;
int SpawnTimer = 30;
int TankNumber;
bool TankRunForce = false;

Handle SpawnTankTimer;

ConVar GTankRunSpawnConfig;
ConVar GTankRunSpawnTimer;
ConVar GTankRunForce;

int Origin_ConVarValue;
ConVar G_Z_Common_Limit;

public void OnPluginStart()
{
	GTankRunSpawnConfig		=  CreateConVar("l4d2_tank_run_spawn_config",
											"0",
											"启用Tank Run. (0 = 禁用, 1 = 启用)",
											CVAR_FLAGS, true, 0.0, true, 1.0);
	GTankRunSpawnTimer		=  CreateConVar("l4d2_tank_run_spawn_timer",
											"30",
											"Tank Run下生成Tank的时间间隔.",
											CVAR_FLAGS, true, 15.0, true, 180.0);
	GTankRunForce			=  CreateConVar("l4d2_tank_run_spawn_force",
											"0",
											"启用Tank Run下禁止其他特感和小丧尸生成. (0 = 禁用, 1 = 启用)",
											CVAR_FLAGS, true, 0.0, true, 1.0);

	G_Z_Common_Limit = FindConVar("z_common_limit");

	GTankRunSpawnConfig.AddChangeHook(ConVarChanged);
	GTankRunSpawnTimer.AddChangeHook(ConVarChanged);
	GTankRunForce.AddChangeHook(ConVarChanged);

	HookEvent("round_start",				Event_RoundStart,					EventHookMode_PostNoCopy);
	HookEvent("round_end",					Event_RoundEnd,						EventHookMode_PostNoCopy);
	HookEvent("player_left_safe_area",		Event_PlayerLeftSafeArea,			EventHookMode_PostNoCopy);
	HookEvent("player_spawn",				Event_PlayerSpawn);
	HookEvent("tank_spawn",					Event_TankSpawn);
	HookEvent("player_death",				Event_PlayerDeath);

	RegConsoleCmd("sm_tankrunoc",			Command_TankRun_OC,					"开启/关闭 Tank Run");
	RegConsoleCmd("sm_tankruntimer",		Command_TankRun_SetSpawnTimer,		"设置 Tank Run 刷克间隔");

	AutoExecConfig(true, "l4d2_tank_run_spawn_config");
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
	TankRun				= GTankRunSpawnConfig.BoolValue;
	SpawnTimer			= GTankRunSpawnTimer.IntValue;
	TankRunForce		= GTankRunForce.BoolValue;

	DeleteTankSpawnTimer();
	if (TankRun)
		CreateTankSpawnTimer();

	ZCL_Change();
}





// ====================================================================================================
// Game void
// ====================================================================================================

public void OnMapEnd()
{
	LeaveSafeArea = false;
	DeleteTankSpawnTimer();
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

public void Event_RoundStart(Event hEvent, const char[] name, bool dontBroadcast)
{
	CanSpawnTank = true;
	LeaveSafeArea = false;
	TankNumber = 0;
	DeleteTankSpawnTimer();
}

public void Event_RoundEnd(Event hEvent, const char[] name, bool dontBroadcast)
{
	OnMapEnd();
}

public void Event_PlayerLeftSafeArea(Event event, const char[] name, bool dontBroadcast)
{
	LeaveSafeArea = true;

	if (TankRun)
		CreateTankSpawnTimer();
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!TankRun)
		return;
	
	if (!TankRunForce)
		return;
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsInfected(client))
		return;
	
	int ZombieClass = GetEntProp(client, Prop_Send, "m_zombieClass");

	if (ZombieClass >= 1 && ZombieClass <= 6)
	{
		if (IsFakeClient(client))
			KickClient(client);
		else
			ForcePlayerSuicide(client);
	}
}

public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!TankRun)
		return;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsTank(client))
		return;

	CreateTimer(0.2, CheckTank, client);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!TankRun)
		return;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsTank(client))
		return;

	TankNumber --;
}





// ====================================================================================================
// Command Action
// ====================================================================================================

public Action Command_TankRun_OC(int client, int args)
{
	if (!bCheckClientAccess(client))
	{
		PrintToChat(client, "\x04[ERROR] \x03你无权使用该指令.");
		return Plugin_Handled;
	}

	if (TankRun)
	{
		TankRun = false;
		PrintToChatAll("\x04[提示] \x05已禁用Tank Run刷克模式.");
		DeleteTankSpawnTimer();
	}
	else
	{
		TankRun = true;
		PrintToChatAll("\x04[提示] \x05已启用Tank Run刷克模式.");
		CreateTankSpawnTimer();
	}
	TankNumber = 0;
	ZCL_Change();
	return Plugin_Handled;
}

public Action Command_TankRun_SetSpawnTimer(int client, int args)
{
	if (!bCheckClientAccess(client))
	{
		PrintToChat(client, "\x04[ERROR] \x03你无权使用该指令.");
		return Plugin_Handled;
	}

	if (!TankRun)
	{
		PrintToChat(client, "\x04[ERROR] \x03当前未启用Tank Run.");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		PrintToChat(client, "\x04[ERROR] \x03No set value.");
		return Plugin_Handled;
	}

	int arg = GetCmdArgInt(1);

	if (arg < 15 || arg > 180)
	{
		PrintToChat(client, "\x04[ERROR] \x04Time \x05<-> \x04Min \x05: \x0315  \x04|  \x04Max \x05: \x03180");
		return Plugin_Handled;
	}
	if (bCheckClientAccess(client))

	SpawnTimer = arg;
	GTankRunSpawnTimer.IntValue = arg;
	DeleteTankSpawnTimer();
	CreateTankSpawnTimer();
	PrintToChatAll("\x04[提示] \x05刷克间隔已被调整为 \x03%d \x05s.", SpawnTimer);
	return Plugin_Handled;
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

public Action SpawnOneTank(Handle timer)
{
	if (!TankRun)
		return Plugin_Continue;

	TankNumber ++;
	SpawnTank();
	CreateTimer(0.9, CheckSpawn, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action CheckSpawn(Handle timer)
{
	if (!TankRun)
		return Plugin_Continue;

	if (Get_TankNum() < TankNumber)
	{
		SpawnTank();
		CreateTimer(0.9, CheckSpawn, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action CheckTank(Handle timer, int client)
{
	if (!TankRun)
		return Plugin_Continue;

	if (!IsTank(client) || !IsPlayerAlive(client))
		return Plugin_Continue;

	if (Get_TankNum() > TankNumber)
	{
		TankNumber ++;
		ForcePlayerSuicide(client);
	}
	return Plugin_Continue;
}





// ====================================================================================================
// void
// ====================================================================================================

public void DeleteTankSpawnTimer()
{
	if (SpawnTankTimer != null)
		delete SpawnTankTimer;
}

public void CreateTankSpawnTimer()
{
	if (LeaveSafeArea)
	{
		if (CanSpawnTank)
		{
			CanSpawnTank = false;
			CreateTimer(3.0, SpawnOneTank);
		}
		if (SpawnTankTimer == null)
			SpawnTankTimer = CreateTimer(float(SpawnTimer), SpawnOneTank, _, TIMER_REPEAT);
	}
}

public void ZCL_Change()
{
	if (!TankRunForce)
		return;
	
	if (TankRun)
	{
		Origin_ConVarValue = G_Z_Common_Limit.IntValue;
		G_Z_Common_Limit.IntValue = 0;
	}
	else
		G_Z_Common_Limit.IntValue = Origin_ConVarValue;
}

public void SpawnTank()
{
	bool canspawn = false;
	float spawnpos[3];
	int target = L4D_GetHighestFlowSurvivor();
	if (IsSurvivor(target))
		canspawn = L4D_GetRandomPZSpawnPosition(target, 8, 10, spawnpos);

	if (canspawn)
		L4D2_SpawnTank(spawnpos, NULL_VECTOR);
	else
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2)
			{
				canspawn = L4D_GetRandomPZSpawnPosition(i, 8, 10, spawnpos);
				if (canspawn)
				{
					L4D2_SpawnTank(spawnpos, NULL_VECTOR);
					break;
				}
			} 
		}
	}
}





// ====================================================================================================
// int
// ====================================================================================================

public int Get_TankNum()
{
	int AliveNum = 0;
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && GetEntProp(i, Prop_Send, "m_zombieClass") == 8 && IsPlayerAlive(i))
			AliveNum ++;
	}
	return AliveNum;
}





// ====================================================================================================
// bool
// ====================================================================================================

public bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

public bool IsInfected(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3;
}

public bool IsTank(int client)
{
	return IsInfected(client) && (GetEntProp(client, Prop_Send, "m_zombieClass") == 8);
}

public bool bCheckClientAccess(int client)
{
	if (GetUserFlagBits(client) & ADMFLAG_ROOT)
		return true;
	return false;
}