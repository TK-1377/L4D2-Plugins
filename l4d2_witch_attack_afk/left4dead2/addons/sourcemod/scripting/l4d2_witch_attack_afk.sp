#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

int HarasserWitch[32];
bool PlayerHarasserWitch[32];

public void OnPluginStart()
{
	HookEvent("round_start",			Event_RoundStart,					EventHookMode_PostNoCopy);
	HookEvent("witch_harasser_set",		Event_WitchHarasser);
	HookEvent("witch_killed",			Event_KillWitch);
	HookEvent("player_bot_replace",		Event_PlayerBotReplace);
	HookEvent("bot_player_replace",		Event_BotPlayerReplace);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients ; i++)
		ClearPluginData(i);
}

public void Event_WitchHarasser(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsSurvivor(client))
		return;
	
	int witchid = event.GetInt("witchid");

	PlayerHarasserWitch[client] = true;
	HarasserWitch[client] = witchid;
}

public void Event_KillWitch(Event event, const char[] name, bool dontBroadcast)
{
	int witchid = event.GetInt("witchid");

	for (int i = 1; i <= MaxClients ; i++)
	{
		if (HarasserWitch[i] == witchid)
			ClearPluginData(i);
	}
}

public void Event_PlayerBotReplace(Event event, char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(event.GetInt("bot"));

	if (!IsSurvivor(bot) || !IsPlayerAlive(bot))
		return;

	int player = GetClientOfUserId(event.GetInt("player"));

	if (!PlayerHarasserWitch[player])
		return;
	
	int witch = HarasserWitch[player];

	if (IsWitch(witch))
	{
		PlayerHarasserWitch[bot] = true;
		HarasserWitch[bot] = witch;
		ClearPluginData(player);
		CreateTimer(0.3, WAT, bot);
	}
}

public void Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(event.GetInt("player"));

	if (!IsSurvivor(player) || !IsPlayerAlive(player))
		return;

	int bot = GetClientOfUserId(event.GetInt("bot"));

	if (!PlayerHarasserWitch[bot])
		return;
	
	int witch = HarasserWitch[bot];

	if (IsWitch(witch))
	{
		PlayerHarasserWitch[player] = true;
		HarasserWitch[player] = witch;
		ClearPluginData(bot);
		CreateTimer(0.3, WAT, player);
	}
}

public Action WAT(Handle timer, int client)
{
	if (!IsSurvivor(client) || !IsPlayerAlive(client))
		return Plugin_Continue;
	
	int witch = HarasserWitch[client];

	if (!IsWitch(witch))
		return Plugin_Continue;

	WitchAttackTarget(witch, client);
	return Plugin_Continue;
}

public void ClearPluginData(int player)
{
	HarasserWitch[player] = 0;
	PlayerHarasserWitch[player] = false;
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
	if (flame != -1 )
		AcceptEntityInput(flame, "Kill");
}

public bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

public bool IsWitch(int entity)
{
	if (entity > MaxClients && IsValidEntity(entity))
	{
		static char classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		return strcmp(classname, "witch", false) == 0;
	}
	return false;
}