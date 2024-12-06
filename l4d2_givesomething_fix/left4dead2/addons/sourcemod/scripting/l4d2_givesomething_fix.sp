#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>
#include <l4d2util>

#define CVAR_FLAGS		FCVAR_NOTIFY

int TimerCount;
bool CanGive[32];

bool LeftSafeArea = false;

bool StartGive = true;
bool LeftGive = true;
bool PillsGive = true;
bool FirstAidKitGive = true;

ConVar Cvar_Give_Time;
ConVar Cvar_Give_Type;

public void OnPluginStart()
{
	Cvar_Give_Time	=  CreateConVar("l4d2_gst_fix_give_time",
									"3",
									"什么时候给予全员物品?\n 1 = 开局\n 2 = 离开安全区\n将需要项相加.", CVAR_FLAGS, true, 0.0, true, 3.0);
	Cvar_Give_Type	=  CreateConVar("l4d2_gst_fix_give_type",
									"3",
									"给予全员哪些物品?\n 1 = 止痛药\n 2 = 医疗包\n将需要项相加.", CVAR_FLAGS, true, 0.0, true, 3.0);

	Cvar_Give_Time.AddChangeHook(ConVarChanged);
	Cvar_Give_Type.AddChangeHook(ConVarChanged);

	HookEvent("round_start",			Event_RoundStart,			EventHookMode_PostNoCopy);
	HookEvent("player_left_safe_area",	Event_PlayerLeftSafeArea,	EventHookMode_PostNoCopy);

	AutoExecConfig(true, "l4d2_givesomething_fix");
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
	int IGive_Time	= Cvar_Give_Time.IntValue;
	int IGive_Type	= Cvar_Give_Type.IntValue;

	StartGive = IGive_Time % 2 == 1;
	LeftGive = IGive_Time >= 2;
	PillsGive = IGive_Type % 2 == 1;
	FirstAidKitGive = IGive_Type >= 2;
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

// 回合开始
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	TimerCount = 0;
	LeftSafeArea = false;
	for (int i = 1; i <= MaxClients ; i++)
		CanGive[i] = true;

	if (StartGive)
		CreateTimer(3.0, GiveDelay, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

// 玩家离开安全区域
public void Event_PlayerLeftSafeArea(Event event, const char[] name, bool dontBroadcast)
{
	if (!LeftGive)
		return;

	if (LeftSafeArea)
		return;

	GiveAll(true);
	LeftSafeArea = true;
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

public Action GiveDelay(Handle timer)
{
	if (!StartGive)
		return Plugin_Stop;

	TimerCount ++;
	if (TimerCount >= 20)
		return Plugin_Stop;

	if (TimerCount >= 2)
		GiveAll(false);
	return Plugin_Continue;
}





// ====================================================================================================
// void
// ====================================================================================================

public void GiveAll(bool IsForce)
{
	int flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && (IsForce || CanGive[i]))
		{
			CanGive[i] = false;
			if (FirstAidKitGive && IdentifyWeapon(GetPlayerWeaponSlot(i, 3)) <= 0)
			{
				//L4D_RemoveWeaponSlot(i, view_as<L4DWeaponSlot>(3));
				FakeClientCommand(i, "give first_aid_kit");
			}
			if (PillsGive && IdentifyWeapon(GetPlayerWeaponSlot(i, 4)) <= 0)
			{
				//L4D_RemoveWeaponSlot(i, view_as<L4DWeaponSlot>(4));
				FakeClientCommand(i, "give pain_pills");
			}
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}