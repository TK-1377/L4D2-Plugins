#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>

#define CVAR_FLAGS		FCVAR_NOTIFY

bool IsGod[32];
float God_Timer = 3.0;
ConVar Cvar_God_Timer;

public void OnPluginStart()
{
	Cvar_God_Timer	=  CreateConVar("l4d2_survivor_spawn_god_time",
									"3.0",
									"幸存者复活无敌时间. (0.0 = 不生效)", CVAR_FLAGS, true, 0.0);

	Cvar_God_Timer.AddChangeHook(ConVarChanged);

	HookEvent("round_start",		Event_RoundStart,		EventHookMode_PostNoCopy);
	HookEvent("player_spawn",		Event_PlayerSpawn);

	AutoExecConfig(true, "l4d2_spawn_survivor_god_time");//生成指定文件名的CFG.
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	God_Timer = Cvar_God_Timer.FloatValue;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype,
						int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!IsSurvivor(client) || !IsPlayerAlive(client))
		return Plugin_Continue;

	if (!IsGod[client])
		return Plugin_Continue;
	
	return Plugin_Handled;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients ; i++)
		IsGod[i] = false;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (God_Timer <= 0.0)
		return;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsSurvivor(client))
		return;

	IsGod[client] = true;
	CreateTimer(God_Timer, ReCold_IsGod, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action ReCold_IsGod(Handle timer, int client)
{
	IsGod[client] = false;
	return Plugin_Continue;
}

public bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}