#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>
#include <l4d2util>

#define CVAR_FLAGS		FCVAR_NOTIFY

bool player_check[32];

bool UpWeaponClear;

int AS;

bool
	clear_slot0 = true,
	clear_slot1 = true,
	clear_slot2 = true,
	clear_slot3 = true,
	clear_slot4 = true,
	clear_upweapon = false;

ConVar
	gclear_slot0,
	gclear_slot1,
	gclear_slot2,
	gclear_slot3,
	gclear_slot4,
	gclear_upweapon;

public Plugin myinfo = 
{
	name 			= "l4d2_complete_clear_player_weapon",
	author 			= "77",
	description 	= "结束时清除玩家武器.",
	version 		= "1.03",
	url 			= "N/A"
}

public void OnPluginStart()
{
	gclear_slot0	= CreateConVar("l4d2_clear_player_slot0",		"1",	"回合结束时是否清除玩家主武器.", CVAR_FLAGS, true, 0.0, true, 1.0);
	gclear_slot1	= CreateConVar("l4d2_clear_player_slot1",		"1",	"回合结束时是否清除玩家副武器.", CVAR_FLAGS, true, 0.0, true, 1.0);
	gclear_slot2	= CreateConVar("l4d2_clear_player_slot2",		"1",	"回合结束时是否清除玩家投掷物.", CVAR_FLAGS, true, 0.0, true, 1.0);
	gclear_slot3	= CreateConVar("l4d2_clear_player_slot3",		"1",	"回合结束时是否清除玩家医疗包, 电击器等等.", CVAR_FLAGS, true, 0.0, true, 1.0);
	gclear_slot4	= CreateConVar("l4d2_clear_player_slot4",		"1",	"回合结束时是否清除玩家止痛药和肾上腺素.", CVAR_FLAGS, true, 0.0, true, 1.0);
	gclear_upweapon	= CreateConVar("l4d2_clear_entity_upweapon",	"0",	"回合开始时是否清除大枪实体.", CVAR_FLAGS, true, 0.0, true, 1.0);

	gclear_slot0.AddChangeHook(ConVarChanged);
	gclear_slot1.AddChangeHook(ConVarChanged);
	gclear_slot2.AddChangeHook(ConVarChanged);
	gclear_slot3.AddChangeHook(ConVarChanged);
	gclear_slot4.AddChangeHook(ConVarChanged);
	gclear_upweapon.AddChangeHook(ConVarChanged);

	HookEvent("round_start",	Event_RoundStart,	EventHookMode_PostNoCopy);		//回合开始.
	HookEvent("round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy);		//回合结束.
	HookEvent("map_transition",	Event_RoundEnd,		EventHookMode_PostNoCopy);		//回合结束.

	RegConsoleCmd("sm_rmwp", Command_weapon_remove, "移除武器.");

	AutoExecConfig(true, "l4d2_complete_clear_player_weapon");//生成指定文件名的CFG.
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
	clear_slot0		= gclear_slot0.BoolValue;
	clear_slot1		= gclear_slot1.BoolValue;
	clear_slot2		= gclear_slot2.BoolValue;
	clear_slot3		= gclear_slot3.BoolValue;
	clear_slot4		= gclear_slot4.BoolValue;
	clear_upweapon	= gclear_upweapon.BoolValue;
}





// ====================================================================================================
// Command Action
// ====================================================================================================

//移除玩家所有武器
public Action Command_weapon_remove(int client, int args)
{
	L4D_RemoveAllWeapons(client);
	Give_Player_Pistol(client);
	return Plugin_Handled;
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

// 回合开始
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	AS = 0;
	UpWeaponClear = false;
	for (int i = 0; i < 32 ; i++)
		player_check[i] = false;

	CreateTimer(0.5, CPWP, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

// 回合结束
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.01, Remove);
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

// 清除大枪实体
public Action DeleteWeapon(Handle timer)
{
	Delete_UpWeapon();
	return Plugin_Continue;
}

// 检测玩家装备
public Action CPWP(Handle timer)
{
	AS ++;
	if (AS >= 40)
		return Plugin_Stop;

	Cheack_Player_Weapon();
	return Plugin_Continue;
}

// 移除所有玩家装备
public Action Remove(Handle timer)
{
	remove_all_players_weapons();
	return Plugin_Continue;
}





// ====================================================================================================
// void
// ====================================================================================================

// 检查玩家装备
public void Cheack_Player_Weapon()
{
	if (clear_upweapon && IsHavePlayer() && !UpWeaponClear)
	{
		UpWeaponClear = true;
		CreateTimer(0.3, DeleteWeapon);
	}
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			if (clear_upweapon && IsFakeClient(i) && clear_slot0)
			{
				int weapon_0	= GetPlayerWeaponSlot(i, 0);
				int wp_0		= IdentifyWeapon(weapon_0);
				if (!IsSmgdOrShotgun(wp_0))
				{
					L4D_RemoveWeaponSlot(i, view_as<L4DWeaponSlot>(0));
				}
			}
			if (!player_check[i])
			{
				player_check[i] = true;
				if (clear_slot0)
					L4D_RemoveWeaponSlot(i, view_as<L4DWeaponSlot>(0));
				if (clear_slot1)
				{
					L4D_RemoveWeaponSlot(i, view_as<L4DWeaponSlot>(1));
					Give_Player_Pistol(i);
				}
				if (clear_slot2)
					L4D_RemoveWeaponSlot(i, view_as<L4DWeaponSlot>(2));
				if (clear_slot3)
					L4D_RemoveWeaponSlot(i, view_as<L4DWeaponSlot>(3));
				if (clear_slot4)
					L4D_RemoveWeaponSlot(i, view_as<L4DWeaponSlot>(4));
			}
		}
	}
}

// 移除所有玩家装备
public void remove_all_players_weapons()
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			if (clear_slot0)
				L4D_RemoveWeaponSlot(i, view_as<L4DWeaponSlot>(0));
			if (clear_slot1)
			{
				L4D_RemoveWeaponSlot(i, view_as<L4DWeaponSlot>(1));
				Give_Player_Pistol(i);
			}
			if (clear_slot2)
				L4D_RemoveWeaponSlot(i, view_as<L4DWeaponSlot>(2));
			if (clear_slot3)
				L4D_RemoveWeaponSlot(i, view_as<L4DWeaponSlot>(3));
			if (clear_slot4)
				L4D_RemoveWeaponSlot(i, view_as<L4DWeaponSlot>(4));
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
		{
			return true;
		}
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