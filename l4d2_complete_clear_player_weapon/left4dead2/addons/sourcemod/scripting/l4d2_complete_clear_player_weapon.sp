#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>
#include <l4d2util>

#define CVAR_FLAGS		FCVAR_NOTIFY

bool PlayerIsCheck[32];
bool UpWeaponClear = false;
bool RoundStartUpWPClear;
float TimerCreateTime;

bool SlotWeaponClear[5] = {true, true, true, true, true};
ConVar Cvar_SlotWeaponsClear[5];
ConVar Cvar_UpWeaponClear;

char SlotWeaponText[5][20] = {"主武器", "副武器", "投掷物", "医疗包", "止痛药/肾上腺素"};

public void OnPluginStart()
{
	char ConVarString[32], ConVarText[128];
	for (int i = 0; i < 5; i++)
	{
		Format(ConVarString, sizeof(ConVarString), "l4d2_clear_player_slot%d", i);
		Format(ConVarText, sizeof(ConVarText), "回合结束时是否清除玩家%s.", SlotWeaponText[i]);
		Cvar_SlotWeaponsClear[i] = CreateConVar(ConVarString, "1", ConVarText, CVAR_FLAGS, true, 0.0, true, 1.0);
		Cvar_SlotWeaponsClear[i].AddChangeHook(ConVarChanged);
	}
	Cvar_UpWeaponClear =  CreateConVar("l4d2_clear_player_upweapon",
										"0",
										"回合结束时是否清除玩家大枪.",
										CVAR_FLAGS, true, 0.0, true, 1.0);
	Cvar_UpWeaponClear.AddChangeHook(ConVarChanged);

	HookEvent("round_start",	Event_RoundStart,	EventHookMode_PostNoCopy);		// 回合开始
	HookEvent("round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy);		// 回合结束
	HookEvent("map_transition",	Event_RoundEnd,		EventHookMode_PostNoCopy);		// 回合结束

	AutoExecConfig(true, "l4d2_complete_clear_player_weapon"); //生成指定文件名的cfg
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
	for (int i = 0; i < 5 ;	i++)
		SlotWeaponClear[i] = Cvar_SlotWeaponsClear[i].BoolValue;
	UpWeaponClear = Cvar_UpWeaponClear.BoolValue;
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

// 回合开始
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	RoundStartUpWPClear = false;
	for (int i = 1; i <= MaxClients ; i++)
		PlayerIsCheck[i] = false;

	CreateTimer(0.5, CheckPlayersWeapon, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	TimerCreateTime = GetGameTime();
}

// 回合结束
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.01, ToRemoveAllPlayersWeapon);
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

// 清除大枪实体
public Action ToDeleteUpWeapon(Handle timer)
{
	Delete_UpWeapon();
	return Plugin_Continue;
}

// 检测玩家装备
public Action CheckPlayersWeapon(Handle timer)
{
	if (GetGameTime() - TimerCreateTime > 40.0)
		return Plugin_Stop;

	Cheack_Player_Weapon();
	return Plugin_Continue;
}

// 移除所有玩家装备
public Action ToRemoveAllPlayersWeapon(Handle timer)
{
	RemoveAllPlayersWeapon();
	return Plugin_Continue;
}





// ====================================================================================================
// void
// ====================================================================================================

// 检查玩家装备
public void Cheack_Player_Weapon()
{
	if (UpWeaponClear && !RoundStartUpWPClear && IsHavePlayer())
	{
		RoundStartUpWPClear = true;
		CreateTimer(0.3, ToDeleteUpWeapon, _, TIMER_FLAG_NO_MAPCHANGE);
	}

	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			if (UpWeaponClear && IsFakeClient(i) && SlotWeaponClear[0])
			{
				if (!IsSmgdOrShotgun(IdentifyWeapon(GetPlayerWeaponSlot(i, 0))))
					L4D_RemoveWeaponSlot(i, view_as<L4DWeaponSlot>(0));
			}

			if (PlayerIsCheck[i])
				continue;

			for (int j = 0; j < 5; j++)
			{
				if (SlotWeaponClear[j])
					L4D_RemoveWeaponSlot(i, view_as<L4DWeaponSlot>(j));
			}

			if (SlotWeaponClear[1])
				Give_Player_Pistol(i);
			
			PlayerIsCheck[i] = true;
		}
	}
}

// 移除所有玩家装备
public void RemoveAllPlayersWeapon()
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			for (int j = 0; j < 5; j++)
			{
				if (SlotWeaponClear[j])
					L4D_RemoveWeaponSlot(i, view_as<L4DWeaponSlot>(j));
			}

			if (SlotWeaponClear[1])
				Give_Player_Pistol(i);
		}
	}
}

// 给予玩家小手枪
public void Give_Player_Pistol(int client)
{
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give pistol");
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}

// 清除所有大枪实体
public void Delete_UpWeapon()
{
	int entcnt = GetEntityCount();
	for (int ent = 1; ent <= entcnt; ent++)
	{
		int wepid = IdentifyWeapon(ent);
		if (IsUpWeapon(wepid))
		{
			AcceptEntityInput(ent, "kill");
		}
	}
}





// ====================================================================================================
// bool
// ====================================================================================================

// 判定是否存在玩家
public bool IsHavePlayer()
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
			return true;
	}
	return false;
}


// 判定wepid 是否属于大枪
public bool IsUpWeapon(int wepid)
{
	return ((wepid >= 4 && wepid <= 6) ||
			(wepid >= 9 && wepid <= 11) ||
			wepid == 21 || wepid == 26 ||
			(wepid >= 34 && wepid <= 37));
}

// 判定wepid 是否属于 冲锋枪 或者 单喷
public bool IsSmgdOrShotgun(int wepid)
{
	return (wepid == 2 || wepid == 3 || wepid == 7 || wepid == 8 || wepid == 33);
}