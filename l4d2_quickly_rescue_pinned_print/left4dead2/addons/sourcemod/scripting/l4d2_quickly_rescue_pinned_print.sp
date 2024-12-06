#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <l4d2util>
#include <colors>

#define CVAR_FLAGS		FCVAR_NOTIFY

float Pinned_Timer[32];
int PinnedType[32];			//	0 = Null	1 = Drag	2 = Chock	3 = Pounce	4 = Ride	5 = Carry	6 = Pummel
int PinnedFrom[32];
int PinnPlayer[32];

float QRP_Time = 1.00;
ConVar GQRP_Time;

char PinnedTypeName[6][6] =
{
	"拖拽",
	"窒息",
	"扑倒",
	"骑乘",
	"撞中",
	"碾压"
};

public void OnPluginStart()
{
	GQRP_Time			=  CreateConVar("l4d2_qrpp_quick_rescue_pinned_time",
										"1.00",
										"多少秒内的解救控制将可以被播报?",
										CVAR_FLAGS, true, 0.1, true, 3.0);

	GQRP_Time.AddChangeHook(ConVarChanged);

	HookEvent("tongue_grab",				Event_TongueGrab);
	HookEvent("choke_start",				Event_ChokeStart);
	HookEvent("lunge_pounce",				Event_LungePounce);
	HookEvent("jockey_ride",				Event_JockeyRide);
	HookEvent("charger_carry_start",		Event_ChargerCarryStart);
	HookEvent("charger_pummel_start",		Event_ChargerPummelStart);
	HookEvent("tongue_pull_stopped",		Event_TonguePullStopped);
	HookEvent("player_death",				Event_PlayerDeath);
	HookEvent("player_spawn",				Event_PlayerSpawn);
	HookEvent("player_shoved",				Event_PlayerShoved);

	AutoExecConfig(true, "l4d2_quickly_rescue_pinned_print");
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
	QRP_Time = GQRP_Time.FloatValue;
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

public void Event_TongueGrab(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!CIsInfected(attacker))
		return;
	
	int ZombieClass = GetEntProp(attacker, Prop_Send, "m_zombieClass");

	if (ZombieClass < 1 || ZombieClass > 6)
		return;

	int client = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if (!CIsValidSurvivor(client))
		return;
	
	Pinned_Timer[client] = GetGameTime();
	PinnedType[client] = 1;
	PinnedFrom[client] = attacker;
	PinnPlayer[attacker] = client;
}

public void Event_ChokeStart(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!CIsInfected(attacker))
		return;
	
	int ZombieClass = GetEntProp(attacker, Prop_Send, "m_zombieClass");

	if (ZombieClass < 1 || ZombieClass > 6)
		return;

	int client = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if (!CIsValidSurvivor(client))
		return;
	
	if (PinnedType[client] != 1)
		Pinned_Timer[client] = GetGameTime();
	PinnedType[client] = 2;
	PinnedFrom[client] = attacker;
	PinnPlayer[attacker] = client;
}

public void Event_LungePounce(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!CIsInfected(attacker))
		return;
	
	int ZombieClass = GetEntProp(attacker, Prop_Send, "m_zombieClass");

	if (ZombieClass < 1 || ZombieClass > 6)
		return;

	int client = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if (!CIsValidSurvivor(client))
		return;
	
	Pinned_Timer[client] = GetGameTime();
	PinnedType[client] = 3;
	PinnedFrom[client] = attacker;
	PinnPlayer[attacker] = client;
}

public void Event_JockeyRide(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!CIsInfected(attacker))
		return;
	
	int ZombieClass = GetEntProp(attacker, Prop_Send, "m_zombieClass");

	if (ZombieClass < 1 || ZombieClass > 6)
		return;

	int client = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if (!CIsValidSurvivor(client))
		return;
	
	Pinned_Timer[client] = GetGameTime();
	PinnedType[client] = 4;
	PinnedFrom[client] = attacker;
	PinnPlayer[attacker] = client;
}

public void Event_ChargerCarryStart(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!CIsInfected(attacker))
		return;
	
	int ZombieClass = GetEntProp(attacker, Prop_Send, "m_zombieClass");

	if (ZombieClass < 1 || ZombieClass > 6)
		return;

	int client = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if (!CIsValidSurvivor(client))
		return;
	
	Pinned_Timer[client] = GetGameTime();
	PinnedType[client] = 5;
	PinnedFrom[client] = attacker;
	PinnPlayer[attacker] = client;
}

public void Event_ChargerPummelStart(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!CIsInfected(attacker))
		return;
	
	int ZombieClass = GetEntProp(attacker, Prop_Send, "m_zombieClass");

	if (ZombieClass < 1 || ZombieClass > 6)
		return;

	int client = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if (!CIsValidSurvivor(client))
		return;
	
	if (PinnedType[client] != 5)
		Pinned_Timer[client] = GetGameTime();
	PinnedType[client] = 6;
	PinnedFrom[client] = attacker;
	PinnPlayer[attacker] = client;
}

public void Event_TonguePullStopped(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!CIsValidSurvivor(attacker))
		return;

	int victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (!CIsValidSurvivor(victim))
		return;

	if (PinnedType[victim] != 1 && PinnedType[victim] != 2)
		return;

	float RescueTime = GetGameTime() - Pinned_Timer[victim];

	if (RescueTime > QRP_Time)
		return;

	int smoker = GetClientOfUserId(GetEventInt(event, "smoker"));

	if (!CIsInfected(smoker) || !IsPlayerAlive(smoker))
		return;

	if (PinnPlayer[smoker] != victim || PinnedFrom[victim] != smoker)
		return;

	int ReleaseType = GetEventInt(event, "release_type");

	if (ReleaseType != 2 && ReleaseType != 4)
		return;

	char weapon_name[64];
	GetClientWeapon(attacker, weapon_name, sizeof(weapon_name));
	int wepid = WeaponNameToId(weapon_name);

	if (ReleaseType == 2)
	{
		CPrintToChatAll("{orange}★ {blue}%N {default}在{olive}%.2f{default}秒内 {olive}推救了 {default}被{olive}%s{default}的 {blue}%N.",
						attacker, RescueTime, PinnedTypeName[PinnedType[victim] - 1], victim);
	}
	else if (ReleaseType == 4)
	{
		if (attacker == victim)
		{
			if (wepid == 19 || wepid == 20)
			{
				CPrintToChatAll("{orange}★ {blue}%N {olive}砍断了 {blue}%N {default}的舌头完成自救.",
								attacker, smoker);
			}
			else
			{
				CPrintToChatAll("{orange}★ {blue}%N {olive}阻断了 {blue}%N {default}的舌头完成自救.",
								attacker, smoker);
			}
		}
		else
		{
			CPrintToChatAll("{orange}★ {blue}%N {default}在{olive}%.2f{default}秒内 {olive}打断了 {blue}%N {default}的舌头, {default}解控了被{olive}%s{default}的 {blue}%N.",
							attacker, RescueTime, smoker, PinnedTypeName[PinnedType[victim] - 1], victim);
		}
	}
				
	PinnedType[victim] = 0;
	PinnedFrom[victim] = 0;
	PinnPlayer[smoker] = 0;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!CIsInGameClient(client))
		return;
	
	if (GetClientTeam(client) == 3)
	{
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		int ZombieClass = GetEntProp(client, Prop_Send, "m_zombieClass");
		int victim = PinnPlayer[client];
		float RescueTime = GetGameTime() - Pinned_Timer[victim];

		if (CIsValidSurvivor(attacker) &&
			ZombieClass >= 1 &&
			ZombieClass <= 6 &&
			CIsValidSurvivor(victim) &&
			PinnedFrom[victim] == client &&
			RescueTime <= QRP_Time)
		{
			char weapon_name[64];
			GetClientWeapon(attacker, weapon_name, sizeof(weapon_name));
			int wepid = WeaponNameToId(weapon_name);

			if (victim == attacker && ZombieClass == 1 && PinnedType[victim] == 1)
			{
				CPrintToChatAll("{orange}★ {blue}%N {default}在{olive}%.2f{default}秒内 {olive}杀死了 {blue}%N {default}完成自救.",
								attacker, RescueTime, client);
			}
			else if (victim == attacker && ZombieClass == 6 && PinnedType[victim] >= 5)
			{
				if (wepid == 19 || wepid == 20)
				{
					CPrintToChatAll("{orange}★ {blue}%N {default}使用近战武器 {olive}杀死了 {default}冲锋的 {blue}%N {default}完成自救.",
									attacker, client);
				}
				else
				{
					CPrintToChatAll("{orange}★ {blue}%N {olive}杀死了 {default}冲锋的 {blue}%N {default}完成自救.",
									attacker, client);
				}
			}
			else
			{
				CPrintToChatAll("{orange}★ {blue}%N {default}在{olive}%.2f{default}秒内 {olive}杀死了 {blue}%N, {default}解控了被{olive}%s{default}的 {blue}%N.",
								attacker, RescueTime, client, PinnedTypeName[PinnedType[victim] - 1], victim);
			}

			PinnedType[victim] = 0;
			PinnedFrom[victim] = 0;
		}
	}

	PinnedType[client] = 0;
	PinnedFrom[client] = 0;
	PinnPlayer[client] = 0;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!CIsInGameClient(client))
		return;

	PinnedType[client] = 0;
	PinnedFrom[client] = 0;
	PinnPlayer[client] = 0;
}

public void Event_PlayerShoved(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!CIsInGameClient(client) || !IsPlayerAlive(client))
		return;
	
	if (GetClientTeam(client) == 3)
	{
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		int ZombieClass = GetEntProp(client, Prop_Send, "m_zombieClass");
		int victim = PinnPlayer[client];
		float RescueTime = GetGameTime() - Pinned_Timer[victim];

		if (CIsValidSurvivor(attacker) &&
			ZombieClass >= 1 &&
			ZombieClass <= 6 &&
			CIsValidSurvivor(victim) &&
			PinnedFrom[victim] == client &&
			RescueTime <= QRP_Time)
		{
			if (victim == attacker && ZombieClass == 1 && PinnedType[victim] == 1)
			{
				CPrintToChatAll("{orange}★ {blue}%N {default}在{olive}%.2f{default}秒内 {olive}推开了 {blue}%N {default}完成自救.",
								attacker, RescueTime, client);
			}
			else
			{
				CPrintToChatAll("{orange}★ {blue}%N {default}在{olive}%.2f{default}秒内 {olive}推开了 {blue}%N, {default}解控了被{olive}%s{default}的 {blue}%N.",
								attacker, RescueTime, client, PinnedTypeName[PinnedType[victim] - 1], victim);
			}

			PinnedType[victim] = 0;
			PinnedFrom[victim] = 0;
		}
	}

	PinnedType[client] = 0;
	PinnedFrom[client] = 0;
	PinnPlayer[client] = 0;
}





// ====================================================================================================
// bool
// ====================================================================================================

public bool CIsInGameClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

public bool CIsValidSurvivor(int client)
{
	return CIsInGameClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

public bool CIsInfected(int client)
{
	return CIsInGameClient(client) && GetClientTeam(client) == 3;
}