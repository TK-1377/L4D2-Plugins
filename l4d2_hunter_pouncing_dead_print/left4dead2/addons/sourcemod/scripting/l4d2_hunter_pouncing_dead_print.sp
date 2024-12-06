#pragma semicolon 1

#pragma newdecls required

#include <sourcemod>
#include <l4d2util>
#include <colors>

#define CVAR_FLAGS		FCVAR_NOTIFY

int Hunter_HP[32];
int Hunter_ShotGroup[32][32];
int Hunter_DamageGroup[32][32];
int Hunter_ShotGunDamage[32][32];
bool Hunter_IsPouncing[32];
bool Hunter_IsAtk[32];
float ShotGun_FireTime[32][32];

char WeaponTypeName[9][12] =
{
	"手枪",
	"冲锋枪",
	"霰弹枪",
	"步枪",
	"狙击枪",
	"M60",
	"近战武器",
	"电锯",
	"榴弹发射器"
};

bool OnlyLastDamage = false;
bool OnlyPouncing = false;

ConVar GOnlyLastDamage;
ConVar GOnlyPouncing;

public void OnPluginStart()
{
	GOnlyLastDamage		=  CreateConVar("l4d2_hpdp_only_last_damage",
										"0",
										"启用只显示最后一击的伤害. (0 = 显示统计伤害总和, 1 = 只显示最后一击造成的伤害)\n 近战/电锯/榴弹发射器 将只显示最后一击造成的伤害",
										CVAR_FLAGS, true, 0.0, true, 1.0);
	GOnlyPouncing		=  CreateConVar("l4d2_hpdp_only_pouncing",
										"0",
										"启用只对Hunter飞扑状态下受到的伤害统计. (0 = 不论是否在飞扑都进行伤害统计, 1 = 只对飞扑状态下进行统计)",
										CVAR_FLAGS, true, 0.0, true, 1.0);
	
	GOnlyLastDamage.AddChangeHook(ConVarChanged);
	GOnlyPouncing.AddChangeHook(ConVarChanged);

	HookEvent("ability_use",			Event_AbilityUse);
	HookEvent("weapon_fire",			Event_WeaponFire);
	HookEvent("player_hurt",			Event_PlayerHurt);
	HookEvent("lunge_pounce",			Event_LungePounce);
	HookEvent("player_death",			Event_PlayerDeath);
	HookEvent("player_spawn",			Event_PlayerSpawn);

	AutoExecConfig(true, "l4d2_hunter_pouncing_dead_print");
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
	OnlyLastDamage		= GOnlyLastDamage.BoolValue;
	OnlyPouncing		= GOnlyPouncing.BoolValue;
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

public void Event_AbilityUse(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!CIsHunter(client) || Hunter_IsPouncing[client])
		return;

	Hunter_IsAtk[client] = false;
	char ability[64];
	GetEventString(event, "ability", ability, sizeof(ability));
	if (strcmp(ability, "ability_lunge") == 0)
	{
		Hunter_IsPouncing[client] = true;
		CreateTimer(0.05, CheckHunterPounce, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!CIsSurvivor(client))
		return;

	int wepid = event.GetInt("weaponid");

	if (GetWeaponType(wepid) != 2)
		return;
	
	for (int i = 1; i <= MaxClients ; i++)
		Hunter_ShotGunDamage[i][client] = Hunter_DamageGroup[i][client];
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!CIsHunter(client))
		return;

	if (Hunter_IsAtk[client] || (OnlyPouncing && !Hunter_IsPouncing[client]))
		return;

	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (!CIsSurvivor(attacker))
		return;

	int Damage = event.GetInt("dmg_health");

	if (Damage < 1)
		return;

	char weapon_name[64];
	GetEventString(event, "weapon", weapon_name, sizeof(weapon_name));
	Format(weapon_name, sizeof(weapon_name), "weapon_%s", weapon_name);
	int wepid = WeaponNameToId(weapon_name);
	int weapon_type = GetWeaponType(wepid);

	if (weapon_type == 2)
	{
		if (GetGameTime() - ShotGun_FireTime[client][attacker] > 0.2)
		{
			ShotGun_FireTime[client][attacker] = GetGameTime();
			Hunter_ShotGroup[client][attacker] ++;
		}
	}
	else
		Hunter_ShotGroup[client][attacker] ++;
	
	if (Hunter_HP[client] > Damage)
	{
		Hunter_HP[client] = GetClientHealth(client);
		Hunter_DamageGroup[client][attacker] += Damage;
	}
	else
		Hunter_DamageGroup[client][attacker] += Hunter_HP[client];
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!CIsHunter(client) || !Hunter_IsPouncing[client] || Hunter_IsAtk[client])
		return;

	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (!CIsSurvivor(attacker))
		return;

	char weapon_name[64];
	GetEventString(event, "weapon", weapon_name, sizeof(weapon_name));
	Format(weapon_name, sizeof(weapon_name), "weapon_%s", weapon_name);
	int wepid = WeaponNameToId(weapon_name);
	int weapon_type = GetWeaponType(wepid);
	
	bool IsHeadShot = GetEventBool(event, "headshot");

	int View_Damage = Hunter_DamageGroup[client][attacker];

	if (weapon_type == 2 && OnlyLastDamage)
		View_Damage = Hunter_DamageGroup[client][attacker] - Hunter_ShotGunDamage[client][attacker];
	else if (weapon_type >= 6 || OnlyLastDamage)
		View_Damage = Hunter_HP[client];

	if (weapon_type == -1)
	{
		CPrintToChatAll("{green}★ {blue}%N {default}空爆了突袭的 {olive}%N{default} ({green}%d {default}伤害)",
						attacker, client, View_Damage);
	}
	else if (weapon_type == 2)
	{
		CPrintToChatAll("{green}★ {blue}%N {default}使用%s {olive}%d枪 {default}空爆了突袭的 {olive}%N{default} ({green}%d {default}伤害)",
						attacker,
						WeaponTypeName[weapon_type],
						Hunter_ShotGroup[client][attacker],
						client,
						View_Damage);
	}
	else if (weapon_type >= 6)
	{
		CPrintToChatAll("{green}★ {blue}%N {default}使用%s {default}%s空爆了突袭的 {olive}%N{default} ({green}%d {default}伤害)",
						attacker,
						WeaponTypeName[weapon_type],
						IsHeadShot ? "爆头" : "",
						client,
						View_Damage);
	}
	else
	{
		CPrintToChatAll("{green}★ {blue}%N {default}使用%s {olive}%d枪 {default}%s空爆了突袭的 {olive}%N{default} ({green}%d {default}伤害)",
						attacker,
						WeaponTypeName[weapon_type],
						Hunter_ShotGroup[client][attacker],
						IsHeadShot ? "爆头" : "",
						client,
						View_Damage);
	}

	char Text[128] = "助攻: ";
	int Assists_Number = 0;
	int Assists_Damage = 0;
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) &&
			GetClientTeam(i) == 2 &&
			Hunter_DamageGroup[client][i] > 0 &&
			i != attacker)
		{
			Assists_Number ++;
			Assists_Damage += Hunter_DamageGroup[client][i];
			Format(Text, sizeof(Text), "%s {blue}%N \x01(伤害 \x04%d\x01)", Text, i, Hunter_DamageGroup[client][i]);
		}
	}

	if (Assists_Number > 3)
		PrintToChatAll("\x04(助攻合计: \x05%d\x04)", Assists_Damage);
	else if (Assists_Number > 0)
		CPrintToChatAll("\x04%s", Text);
}

public void Event_LungePounce(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!CIsHunter(client))
		return;

	Hunter_IsAtk[client] = true;
	Hunter_IsPouncing[client] = false;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!CIsHunter(client))
		return;
	
	Hunter_IsPouncing[client] = false;
	Hunter_IsAtk[client] = false;
	Hunter_HP[client] = GetClientHealth(client);

	for (int i = 1; i <= MaxClients ; i++)
	{
		Hunter_ShotGroup[client][i] = 0;
		Hunter_DamageGroup[client][i] = 0;
		ShotGun_FireTime[client][i] = 0.0;
	}
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

public Action CheckHunterPounce(Handle timer, int hunter)
{
	if (!CIsHunter(hunter) || !IsPlayerAlive(hunter) || !HunterIsPouncing(hunter))
	{
		Hunter_IsPouncing[hunter] = false;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}





// ====================================================================================================
// int
// ====================================================================================================

public int GetWeaponType(int wepid)
{
	switch (wepid)
	{
		case 1, 32 :
			return 0;
		case 2, 7, 33 :
			return 1;
		case 3, 4, 8, 11 :
			return 2;
		case 5, 9, 26, 34 :
			return 3;
		case 6, 10, 35, 36 :
			return 4;
		case 37 :
			return 5;
		case 19, 20, 21 :
			return wepid - 13;
	}
	return -1;
}





// ====================================================================================================
// bool
// ====================================================================================================

public bool CIsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

public bool CIsHunter(int client)
{
	return (client > 0 &&
			client <= MaxClients &&
			IsClientInGame(client) &&
			GetClientTeam(client) == 3 &&
			(GetEntProp(client, Prop_Send, "m_zombieClass") == 3));
}

public bool HunterIsPouncing(int hunter)
{
	return !(GetEntityFlags(hunter) & FL_ONGROUND) && !(GetEntityMoveType(hunter) & MOVETYPE_LADDER);
}