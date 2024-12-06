#pragma semicolon 1

#pragma newdecls required

#include <sourcemod>
#include <l4d2util>
#include <colors>

#define CVAR_FLAGS		FCVAR_NOTIFY

int Charger_HP[32];
int Charger_DamageGroup[32][32];
int Charger_ShotGunDamage[32][32];
bool Charger_IsCharging[32];
bool Charger_IsAtk[32];

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
bool OnlyCharging = false;

ConVar GOnlyLastDamage;
ConVar GOnlyCharging;

public void OnPluginStart()
{
	GOnlyLastDamage		=  CreateConVar("l4d2_ccdp_only_last_damage",
										"0",
										"启用只显示最后一击的伤害. (0 = 显示统计伤害总和, 1 = 只显示最后一击造成的伤害)\n 近战/电锯/榴弹发射器 将只显示最后一击造成的伤害",
										CVAR_FLAGS, true, 0.0, true, 1.0);
	GOnlyCharging		=  CreateConVar("l4d2_ccdp_only_charging",
										"0",
										"启用只对Charger冲锋状态下受到的伤害统计. (0 = 不论是否在冲锋都进行伤害统计, 1 = 只对冲锋状态下进行统计)",
										CVAR_FLAGS, true, 0.0, true, 1.0);
	
	GOnlyLastDamage.AddChangeHook(ConVarChanged);
	GOnlyCharging.AddChangeHook(ConVarChanged);

	HookEvent("weapon_fire",			Event_WeaponFire);
	HookEvent("player_hurt",			Event_PlayerHurt);
	HookEvent("charger_carry_start",	Event_ChargeCarryStart);
	HookEvent("player_death",			Event_PlayerDeath);
	HookEvent("player_spawn",			Event_PlayerSpawn);

	AutoExecConfig(true, "l4d2_charger_charging_dead_print");
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
	OnlyCharging		= GOnlyCharging.BoolValue;
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
		Charger_ShotGunDamage[i][client] = Charger_DamageGroup[i][client];
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!CIsCharger(client))
		return;

	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (!CIsSurvivor(attacker))
		return;

	int Damage = event.GetInt("dmg_health");

	if (Damage < 1)
		return;

	int AbilityEntity = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	Charger_IsCharging[client] = (IsValidEdict(AbilityEntity) && GetEntProp(AbilityEntity, Prop_Send, "m_isCharging"));

	if (Charger_IsCharging[client] || !OnlyCharging)
	{
		if (Charger_HP[client] > Damage)
		{
			Charger_HP[client] = GetClientHealth(client);
			Charger_DamageGroup[client][attacker] += Damage;
		}
		else
			Charger_DamageGroup[client][attacker] += Charger_HP[client];
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!CIsCharger(client) || !Charger_IsCharging[client] || Charger_IsAtk[client])
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

	if (weapon_type == -1 || weapon_type == 2 || weapon_type == 8)
		IsHeadShot = false;

	int View_Damage = Charger_DamageGroup[client][attacker];

	if (weapon_type == 2 && OnlyLastDamage)
		View_Damage = Charger_DamageGroup[client][attacker] - Charger_ShotGunDamage[client][attacker];
	else if (weapon_type >= 6 || OnlyLastDamage)
		View_Damage = Charger_HP[client];

	if (weapon_type == -1)
	{
		CPrintToChatAll("{orange}★ {blue}%N {default}%s击杀了 {olive}一只冲锋的Charger{default}.({blue}%d 伤害{default})",
						attacker, IsHeadShot ? "爆头" : "", View_Damage);
	}
	else
	{
		CPrintToChatAll("{orange}★ {blue}%N {default}使用{blue}%s {default}%s%s {olive}一只冲锋的Charger{default}.({blue}%d 伤害{default})",
						attacker,
						WeaponTypeName[weapon_type],
						IsHeadShot ? "爆头" : "",
						weapon_type >= 6 ? "秒杀了" : "击杀了",
						View_Damage);
	}

	char Text[128] = "(助攻: ";
	int Assists_Number = 0;
	int Assists_Damage = 0;
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) &&
			GetClientTeam(i) == 2 &&
			Charger_DamageGroup[client][i] > 0 &&
			i != attacker)
		{
			Assists_Number ++;
			Assists_Damage += Charger_DamageGroup[client][i];
			Format(Text, sizeof(Text), "%s \x05%N \x04%d", Text, i, Charger_DamageGroup[client][i]);
		}
	}

	if (Assists_Number > 3)
		PrintToChatAll("\x04(助攻合计: \x05%d\x04)", Assists_Damage);
	else if (Assists_Number > 0)
		PrintToChatAll("\x04%s\x04)", Text);
}

public void Event_ChargeCarryStart(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!CIsCharger(client))
		return;

	Charger_IsAtk[client] = true;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!CIsCharger(client))
		return;
	
	Charger_IsCharging[client] = false;
	Charger_IsAtk[client] = false;
	Charger_HP[client] = GetClientHealth(client);

	for (int i = 1; i <= MaxClients ; i++)
		Charger_DamageGroup[client][i] = 0;
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

public bool CIsCharger(int client)
{
	return (client > 0 &&
			client <= MaxClients &&
			IsClientInGame(client) &&
			GetClientTeam(client) == 3 &&
			(GetEntProp(client, Prop_Send, "m_zombieClass") == 6));
}