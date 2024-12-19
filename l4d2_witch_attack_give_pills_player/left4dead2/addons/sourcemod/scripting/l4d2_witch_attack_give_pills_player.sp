#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

int PlayerHarasserWitch[32];
int PlayerPillsGiver[32];
bool IsPlayerHarasserWitch[32];

public void OnPluginStart()
{
	HookEvent("round_start",				Event_RoundStart,				EventHookMode_PostNoCopy);
	HookEvent("weapon_given",				Event_WeaponGiven);
	HookEvent("witch_harasser_set",			Event_WitchHarasserSet);
	HookEvent("witch_killed",				Event_WitchKilled);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype,
						int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!IsWitch(attacker) || !CIsSurvivor(client) || !IsPlayerHarasserWitch[client])
		return Plugin_Continue;
	
	ClearPluginData(client);
	return Plugin_Continue;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients ; i++)
		ClearPluginData(i);
}

public void Event_WeaponGiven(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!CIsSurvivor(client) || !IsPlayerAlive(client) || !IsWitchNear(client))
		return;
	
	int giver = GetClientOfUserId(event.GetInt("giver"));

	if (!CIsSurvivor(giver) || !IsPlayerAlive(giver))
		return;

	int wepid = event.GetInt("weapon");

	if (wepid != 15 && wepid != 23)
		return;
	
	float ClientPos[3], GiverPos[3];
	GetClientAbsOrigin(client, ClientPos);
	GetClientAbsOrigin(giver, GiverPos);

	if (GetVectorDistance(ClientPos, GiverPos) > 400.0)
		return;

	PlayerPillsGiver[client] = giver;
	int witch = PlayerHarasserWitch[client];

	if (!IsWitch(witch))
		return;

	if (IsPlayerHarasserWitch[client])
	{
		ClearPluginData(client);
		IsPlayerHarasserWitch[giver] = true;
		PlayerHarasserWitch[giver] = witch;
		WitchAttackTarget(witch, giver);
		PrintToChatAll("\x04[提示] \x03%N \x01因为\x05秒妹递药\x01而被Witch追杀.", giver);
	}
	else
		CreateTimer(5.0, Delay_ClearPlayerGiverData, client, TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_WitchHarasserSet(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!CIsSurvivor(client) || !IsPlayerAlive(client))
		return;

	int witchid = event.GetInt("witchid");

	if (PlayerHarasserWitch[client] == witchid)
		return;

	IsPlayerHarasserWitch[client] = true;
	PlayerHarasserWitch[client] = witchid;

	int giver = PlayerPillsGiver[client];

	if (!CIsSurvivor(giver) || !IsPlayerAlive(giver))
		return;
	
	ClearPluginData(client);
	IsPlayerHarasserWitch[giver] = true;
	PlayerHarasserWitch[giver] = witchid;
	WitchAttackTarget(witchid, giver);
	PrintToChatAll("\x04[提示] \x03%N \x01因为\x05秒妹递药\x01而被Witch追杀.", giver);
}

public void Event_WitchKilled(Event event, const char[] name, bool dontBroadcast)
{
	int witchid = event.GetInt("witchid");

	for (int i = 1; i <= MaxClients ; i++)
	{
		if (PlayerHarasserWitch[i] == witchid)
			ClearPluginData(i);
	}
}

public Action Delay_ClearPlayerGiverData(Handle timer, int client)
{
	PlayerPillsGiver[client] = 0;
	return Plugin_Continue;
}

public void ClearPluginData(int client)
{
	PlayerHarasserWitch[client] = 0;
	PlayerPillsGiver[client] = 0;
	IsPlayerHarasserWitch[client] = false;
}

public void WitchAttackTarget(int witch, int target)
{
	if (GetEntProp(witch, Prop_Data, "m_iHealth") < 0)
		return;

	if (GetEntityFlags(witch) & FL_ONFIRE)
	{
		ExtinguishEntity(witch);
		int flame = GetEntPropEnt(witch, Prop_Send, "m_hEffectEntity");
		if (flame != -1)
			AcceptEntityInput(flame, "Kill");

		SDKHooks_TakeDamage(witch, target, target, 0.0, DMG_BURN);
	}
	else
	{
		int anim = GetEntProp(witch, Prop_Send, "m_nSequence");
		SDKHooks_TakeDamage(witch, target, target, 0.0, DMG_BURN);
		SetEntProp(witch, Prop_Send, "m_nSequence", anim);
		SetEntProp(witch, Prop_Send, "m_bIsBurning", 0);
		SDKHook(witch, SDKHook_ThinkPost, PostThink);
	}
}

public void PostThink(int witch)
{
	SDKUnhook(witch, SDKHook_ThinkPost, PostThink);
	ExtinguishEntity(witch);
	int flame = GetEntPropEnt(witch, Prop_Send, "m_hEffectEntity");
	if (flame != -1)
		AcceptEntityInput(flame, "Kill");
}

public bool CIsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

public bool IsWitchNear(int client)
{
	int EntityCount = GetEntityCount();
	float ClientPos[3], EntityPos[3];
	GetClientAbsOrigin(client, ClientPos);
	for (int i = MaxClients + 1; i <= EntityCount; i++)
	{
		if (!IsValidEdict(i) || !IsWitch(i))
			continue;
		
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", EntityPos);
		if (GetVectorDistance(ClientPos, EntityPos) <= 350.0)
			return true;
	}
	return false;
}

public bool IsWitch(int entity)
{
	if (entity > MaxClients && IsValidEntity(entity))
	{
		static char classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (strcmp(classname, "witch", false) == 0)
			return true;
	}
	return false;
}