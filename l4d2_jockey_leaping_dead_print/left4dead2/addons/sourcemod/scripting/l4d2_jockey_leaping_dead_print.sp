#pragma semicolon 1

#pragma newdecls required

#include <sourcemod>
#include <l4d2util>
#include <colors>

#define CVAR_FLAGS		FCVAR_NOTIFY

int Jockey_HP[32];
int Jockey_ShotGroup[32][32];
int Jockey_DamageGroup[32][32];
int Jockey_ShotGunDamage[32][32];
bool Jockey_IsLeaping[32];
bool Jockey_IsAtk[32];
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
bool OnlyLeaping = false;

ConVar GOnlyLastDamage;
ConVar GOnlyLeaping;

public void OnPluginStart()
{
	GOnlyLastDamage		=  CreateConVar("l4d2_jldp_only_last_damage",
										"0",
										"启用只显示最后一击的伤害. (0 = 显示统计伤害总和, 1 = 只显示最后一击造成的伤害)\n 近战/电锯/榴弹发射器 将只显示最后一击造成的伤害",
										CVAR_FLAGS, true, 0.0, true, 1.0);
	GOnlyLeaping		=  CreateConVar("l4d2_jldp_only_leaping",
										"0",
										"启用只对Jockey飞扑状态下受到的伤害统计. (0 = 不论是否在飞扑都进行伤害统计, 1 = 只对飞扑状态下进行统计)",
										CVAR_FLAGS, true, 0.0, true, 1.0);
	
	GOnlyLastDamage.AddChangeHook(ConVarChanged);
	GOnlyLeaping.AddChangeHook(ConVarChanged);

	HookEvent("weapon_fire",			Event_WeaponFire);
	HookEvent("player_hurt",			Event_PlayerHurt);
	HookEvent("jockey_ride",			Event_JockeyRide);
	HookEvent("jockey_ride_end",		Event_JockeyRideEnd);
	HookEvent("player_death",			Event_PlayerDeath);
	HookEvent("player_spawn",			Event_PlayerSpawn);

	AutoExecConfig(true, "l4d2_jockey_leaping_dead_print");
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
	OnlyLastDamage	= GOnlyLastDamage.BoolValue;
	OnlyLeaping		= GOnlyLeaping.BoolValue;
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

public void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!CIsSurvivor(client))
		return;

	int wepid = event.GetInt("weaponid");

	if (GetWeaponType(wepid) != 2)
		return;
	
	for (int i = 1; i <= MaxClients ; i++)
		Jockey_ShotGunDamage[i][client] = Jockey_DamageGroup[i][client];
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!CIsJockey(client))
		return;

	Jockey_IsLeaping[client] = JockeyIsLeaping(client);

	if (Jockey_IsAtk[client] || (OnlyLeaping && !Jockey_IsLeaping[client]))
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
			Jockey_ShotGroup[client][attacker] ++;
		}
	}
	else
		Jockey_ShotGroup[client][attacker] ++;
	
	if (Jockey_HP[client] > Damage)
	{
		Jockey_HP[client] = GetClientHealth(client);
		Jockey_DamageGroup[client][attacker] += Damage;
	}
	else
		Jockey_DamageGroup[client][attacker] += Jockey_HP[client];
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!CIsJockey(client) || !Jockey_IsLeaping[client] || Jockey_IsAtk[client])
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

	int View_Damage = Jockey_DamageGroup[client][attacker];

	if (weapon_type == 2 && OnlyLastDamage)
		View_Damage = Jockey_DamageGroup[client][attacker] - Jockey_ShotGunDamage[client][attacker];
	else if (weapon_type >= 6 || OnlyLastDamage)
		View_Damage = Jockey_HP[client];

	if (weapon_type == -1)
	{
		CPrintToChatAll("{green}★ {blue}%N {default}空爆了飞扑的 {olive}%N{default} ({green}%d {default}伤害)",
						attacker, client, View_Damage);
	}
	else if (weapon_type == 2)
	{
		CPrintToChatAll("{green}★ {blue}%N {default}使用%s {olive}%d枪 {default}空爆了飞扑的 {olive}%N{default} ({green}%d {default}伤害)",
						attacker,
						WeaponTypeName[weapon_type],
						Jockey_ShotGroup[client][attacker],
						client,
						View_Damage);
	}
	else if (weapon_type >= 6)
	{
		CPrintToChatAll("{green}★ {blue}%N {default}使用%s {default}%s空爆了飞扑的 {olive}%N{default} ({green}%d {default}伤害)",
						attacker,
						WeaponTypeName[weapon_type],
						IsHeadShot ? "爆头" : "",
						client,
						View_Damage);
	}
	else
	{
		CPrintToChatAll("{green}★ {blue}%N {default}使用%s {olive}%d枪 {default}%s空爆了飞扑的 {olive}%N{default} ({green}%d {default}伤害)",
						attacker,
						WeaponTypeName[weapon_type],
						Jockey_ShotGroup[client][attacker],
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
			Jockey_DamageGroup[client][i] > 0 &&
			i != attacker)
		{
			Assists_Number ++;
			Assists_Damage += Jockey_DamageGroup[client][i];
			Format(Text, sizeof(Text), "%s {blue}%N \x01(伤害 \x04%d\x01)", Text, i, Jockey_DamageGroup[client][i]);
		}
	}

	if (Assists_Number > 3)
		PrintToChatAll("\x04(助攻合计: \x05%d\x04)", Assists_Damage);
	else if (Assists_Number > 0)
		CPrintToChatAll("\x04%s", Text);
}

public void Event_JockeyRide(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!CIsJockey(client))
		return;

	Jockey_IsAtk[client] = true;
	Jockey_IsLeaping[client] = false;
}

public void Event_JockeyRideEnd(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!CIsJockey(client))
		return;

	Jockey_IsAtk[client] = false;
	Jockey_IsLeaping[client] = false;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!CIsJockey(client))
		return;
	
	Jockey_IsLeaping[client] = false;
	Jockey_IsAtk[client] = false;
	Jockey_HP[client] = GetClientHealth(client);

	for (int i = 1; i <= MaxClients ; i++)
	{
		Jockey_ShotGroup[client][i] = 0;
		Jockey_DamageGroup[client][i] = 0;
		ShotGun_FireTime[client][i] = 0.0;
	}
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

public bool CIsJockey(int client)
{
	return (client > 0 &&
			client <= MaxClients &&
			IsClientInGame(client) &&
			GetClientTeam(client) == 3 &&
			(GetEntProp(client, Prop_Send, "m_zombieClass") == 5));
}

public bool JockeyIsLeaping(int jockey)
{
	return !(GetEntityFlags(jockey) & FL_ONGROUND) && !(GetEntityMoveType(jockey) & MOVETYPE_LADDER);
}