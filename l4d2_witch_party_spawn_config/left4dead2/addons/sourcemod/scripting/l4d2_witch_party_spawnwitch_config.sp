#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>
#include <sdktools>

#define CVAR_FLAGS		FCVAR_NOTIFY

int WitchParty = 0;
bool LeaveSafeArea = false;
bool CanSpawnWitch = true;
int SpawnTimer = 10;

Handle SpawnWitchTimer;

ConVar GWitchPartySpawnConfig;
ConVar GWitchPartySpawnTimer;

public void OnPluginStart()
{
	GWitchPartySpawnConfig	=  CreateConVar("l4d2_witch_party_spawn_config",
											"0",
											"启用Witch Party. (0 = 禁用, 1 = 旧版, 2 = 新版)",
											CVAR_FLAGS, true, 0.0, true, 2.0);
	GWitchPartySpawnTimer	=  CreateConVar("l4d2_witch_party_spawn_timer",
											"10",
											"Witch Party 生成时间间隔",
											CVAR_FLAGS, true, 3.0, true, 180.0);

	GWitchPartySpawnConfig.AddChangeHook(ConVarChanged);
	GWitchPartySpawnTimer.AddChangeHook(ConVarChanged);

	HookEvent("round_start",				Event_RoundStart,					EventHookMode_PostNoCopy);
	HookEvent("player_left_safe_area",		Event_PlayerLeftSafeArea,			EventHookMode_PostNoCopy);
	HookEvent("player_incapacitated",		Event_PlayerIncap);

	RegConsoleCmd("sm_witchparty",			Command_WitchParty_OC,				"开启/关闭 Witch Party.");
	RegConsoleCmd("sm_witchpartytimer",		Command_WitchParty_SetSpawnTimer,	"设置 Witch Party 刷妹间隔");

	AutoExecConfig(true, "l4d2_witch_party_spawn_config");
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
	WitchParty	= GWitchPartySpawnConfig.IntValue;
	SpawnTimer	= GWitchPartySpawnTimer.IntValue;

	DeleteWitchSpawnTimer();
	if (WitchParty > 0)
		CreateWitchSpawnTimer();
}





// ====================================================================================================
// Game void
// ====================================================================================================

public void OnMapEnd()
{
	LeaveSafeArea = false;
	DeleteWitchSpawnTimer();
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CanSpawnWitch = true;
	LeaveSafeArea = false;
	DeleteWitchSpawnTimer();
}

public void Event_PlayerLeftSafeArea(Event event, const char[] name, bool dontBroadcast)
{
	LeaveSafeArea = true;
	
	if (WitchParty > 0)
		CreateWitchSpawnTimer();
}

public void Event_PlayerIncap(Event event, const char[] name, bool dontBroadcast)
{
	if (WitchParty < 2)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsSurvivor(client) || !IsPlayerFallen(client))
		return;

	SpawnWitch();
	PrintToChatAll("\x04[提示] \x05一只Witch因为 \x03%N \x05倒地而生成.", client);
}






// ====================================================================================================
// Command Action
// ====================================================================================================

public Action Command_WitchParty_OC(int client, int args)
{
	if (!bCheckClientAccess(client))
	{
		PrintToChat(client, "\x04[ERROR] \x03你无权使用该指令.");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		PrintToChat(client, "\x04[ERROR] \x03No set value.");
		return Plugin_Handled;
	}

	int arg = GetCmdArgInt(1);
	
	if (arg < 0 || arg > 2)
	{
		PrintToChat(client, "\x04[ERROR] \x04Invalid value.");
		return Plugin_Handled;
	}

	WitchParty = arg;
	DeleteWitchSpawnTimer();
	if (WitchParty == 0)
	{
		DeleteWitchSpawnTimer();
		PrintToChatAll("\x04[提示] \x05已禁用Witch Party 刷妹模式.");
	}
	else
	{
		CreateWitchSpawnTimer();
		PrintToChatAll("\x04[提示] \x05已启用Witch Party (%s) 刷妹模式.", WitchParty > 1 ? "new" : "old");
	}
	return Plugin_Handled;
}

public Action Command_WitchParty_SetSpawnTimer(int client, int args)
{
	if (!bCheckClientAccess(client))
	{
		PrintToChat(client, "\x04[ERROR] \x03你无权使用该指令.");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		PrintToChat(client, "\x04[ERROR] \x03No set value.");
		return Plugin_Handled;
	}

	int arg = GetCmdArgInt(1);
	
	if (arg < 3 || arg > 180)
	{
		PrintToChat(client, "\x04[ERROR] \x04Time \x05<-> \x04Min \x05: \x033  \x04|  \x04Max \x05: \x03180");
		return Plugin_Handled;
	}

	SpawnTimer = arg;
	GWitchPartySpawnTimer.IntValue = arg;
	if (WitchParty > 0)
	{
		DeleteWitchSpawnTimer();
		CreateWitchSpawnTimer();
	}
	PrintToChatAll("\x04[提示] \x05刷妹间隔已被调整为 \x03%d \x05s.", SpawnTimer);
	return Plugin_Handled;
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

public Action SpawnOneWitch(Handle timer)
{
	SpawnWitch();
	return Plugin_Continue;
}





// ====================================================================================================
// void
// ====================================================================================================

public void DeleteWitchSpawnTimer()
{
	if (SpawnWitchTimer != null)
		delete SpawnWitchTimer;
}

public void CreateWitchSpawnTimer()
{
	if (LeaveSafeArea)
	{
		if (CanSpawnWitch)
		{
			CanSpawnWitch = false;
			CreateTimer(3.0, SpawnOneWitch);
		}
		if (SpawnWitchTimer == null)
			SpawnWitchTimer = CreateTimer(float(SpawnTimer), SpawnOneWitch, _, TIMER_REPEAT);
	}
}

public void SpawnWitch()
{
	bool canspawn;
	float spawnpos[3];
	int target = L4D_GetHighestFlowSurvivor();
	if (IsSurvivor(target))
	{
		canspawn = L4D_GetRandomPZSpawnPosition(target, 7, 10, spawnpos);
		if (!canspawn)
			canspawn = L4D_GetRandomPZSpawnPosition(target, 8, 10, spawnpos);
	}

	if (canspawn)
		L4D2_SpawnWitch(spawnpos, NULL_VECTOR);
	else
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2)
			{
				canspawn = L4D_GetRandomPZSpawnPosition(i, 7, 10, spawnpos);
				if (!canspawn)
					canspawn = L4D_GetRandomPZSpawnPosition(i, 8, 10, spawnpos);
				if (canspawn)
				{
					L4D2_SpawnWitch(spawnpos, NULL_VECTOR);
					break;
				}
			} 
		}
	} 
}





// ====================================================================================================
// bool
// ====================================================================================================

public bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

public bool IsPlayerFallen(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

public bool bCheckClientAccess(int client)
{
	if (GetUserFlagBits(client) & ADMFLAG_ROOT)
		return true;
	return false;
}