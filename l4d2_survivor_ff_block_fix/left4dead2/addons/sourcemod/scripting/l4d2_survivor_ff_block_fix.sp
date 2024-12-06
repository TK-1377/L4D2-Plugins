#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <left4dhooks>

#define CVAR_FLAGS				FCVAR_NOTIFY

#define DOUBANFIRE				2056
#define DOUBANONFIRE			268435464

bool BlockFF_RoundStart = false;
bool BlockFF_RoundStart_Print = false;
bool BlockFF_InsideSafeRoom = false;
bool BlockFF_GetEnd = false;
bool BlockFF_MeleeHurt = false;
bool BlockFF_FireHurt = false;
float BlockFF_MinDistance = 0.0;
float BlockFF_MaxDistance = 0.0;
float BlockFF_InfectedNearRange = 0.0;
bool BlockFF_ChargerCarry = false;
bool BlockFF_RescuedPinned = false;
bool BlockFF_HaveAliveTank = false;
float BlockFF_ColdTime = 0.0;
int BlockFF_RoundMaxFF = -1;

ConVar GBlockFF_RoundStart;
ConVar GBlockFF_RoundStart_Print;
ConVar GBlockFF_InsideSafeRoom;
ConVar GBlockFF_GetEnd;
ConVar GBlockFF_MeleeHurt;
ConVar GBlockFF_FireHurt;
ConVar GBlockFF_MinDistance;
ConVar GBlockFF_MaxDistance;
ConVar GBlockFF_InfectedNearRange;
ConVar GBlockFF_ChargerCarry;
ConVar GBlockFF_RescuedPinned;
ConVar GBlockFF_HaveAliveTank;
ConVar GBlockFF_ColdTime;
ConVar GBlockFF_RoundMaxFF;

bool LeftSafeArea = false;
bool GetEnd = false;
bool IsAllowBlockFF[32] = {false, ...};
bool CanHurt[32] = {false, ...};
bool CanHurtChange[32] = {false, ...};
bool IsSpawning[32] = {false, ...};
bool IsCheckStartSafeArea = false;
bool IsGetEndSafeDoorPos = false;
int StartSafeArea = -1, EndSafeArea = -1;
int MyFF[32] = {0, ...};
float EndSafeDoorPos[3] = {0.0, 0.0, 0.0};

public void OnPluginStart()
{
	GBlockFF_RoundStart				=  CreateConVar("l4d2_sfbf_round_start",
													"0",
													"启用未离开安全区前无友伤. (0 = 禁用, 1 = 启用)",
													CVAR_FLAGS, true, 0.0, true, 1.0);
	GBlockFF_RoundStart_Print		=  CreateConVar("l4d2_sfbf_round_start_print",
													"0",
													"启用离开安全区时开启友伤文本提示. (0 = 禁用, 1 = 启用)",
													CVAR_FLAGS, true, 0.0, true, 1.0);
	GBlockFF_InsideSafeRoom			=  CreateConVar("l4d2_sfbf_inside_saferoom",
													"0",
													"启用安全区内无法造成和受到友伤. (0 = 禁用, 1 = 启用)",
													CVAR_FLAGS, true, 0.0, true, 1.0);
	GBlockFF_GetEnd					=  CreateConVar("l4d2_sfbf_get_end",
													"0",
													"启用触碰终点安全门、到达终点安全区和救援到来时关闭友伤. (0 = 禁用, 1 = 启用)",
													CVAR_FLAGS, true, 0.0, true, 1.0);
	GBlockFF_MeleeHurt				=  CreateConVar("l4d2_sfbf_melee_hurt",
													"0",
													"启用免除近战友伤. (0 = 禁用, 1 = 启用)",
													CVAR_FLAGS, true, 0.0, true, 1.0);
	GBlockFF_FireHurt				=  CreateConVar("l4d2_sfbf_fire_hurt",
													"0",
													"启用免除火伤友伤. (0 = 禁用, 1 = 启用)",
													CVAR_FLAGS, true, 0.0, true, 1.0);
	GBlockFF_MinDistance			=  CreateConVar("l4d2_sfbf_min_distance",
													"0.0",
													"免除多近距离的友伤? (0.0 = 不启用)",
													CVAR_FLAGS, true, 0.0);
	GBlockFF_MaxDistance			=  CreateConVar("l4d2_sfbf_max_distance",
													"0.0",
													"免除多远距离的友伤? (0.0 = 不启用)",
													CVAR_FLAGS, true, 0.0);
	GBlockFF_InfectedNearRange		=  CreateConVar("l4d2_sfbf_infected_near_range",
													"0.0",
													"身边多近距离以内有存活特感免除友伤? (0.0 = 不启用)",
													CVAR_FLAGS, true, 0.0);
	GBlockFF_ChargerCarry			=  CreateConVar("l4d2_sfbf_charger_carry",
													"0",
													"启用对Charger携带幸存者无友伤. (0 = 禁用, 1 = 启用)",
													CVAR_FLAGS, true, 0.0, true, 1.0);
	GBlockFF_RescuedPinned			=  CreateConVar("l4d2_sfbf_rescued_pinned",
													"0",
													"启用对解控(smoker, jockey, charger)后幸存者短暂无友伤. (0 = 禁用, 1 = 启用)",
													CVAR_FLAGS, true, 0.0, true, 1.0);
	GBlockFF_HaveAliveTank			=  CreateConVar("l4d2_sfbf_have_alive_tank",
													"0",
													"启用有Tank存活时无友伤. (0 = 禁用, 1 = 启用)",
													CVAR_FLAGS, true, 0.0, true, 1.0);
	GBlockFF_ColdTime				=  CreateConVar("l4d2_sfbf_cold_time",
													"0.0",
													"多少秒内第一次造成的友伤将被免除? (0.0 = 不启用)",
													CVAR_FLAGS, true, 0.0);
	GBlockFF_RoundMaxFF				=  CreateConVar("l4d2_sfbf_round_max_ff",
													"-1",
													"设置回合友伤上限值. (-1 = 不启用)",
													CVAR_FLAGS, true, -1.0);

	GBlockFF_RoundStart.AddChangeHook(ConVarChanged);
	GBlockFF_RoundStart_Print.AddChangeHook(ConVarChanged);
	GBlockFF_MeleeHurt.AddChangeHook(ConVarChanged);
	GBlockFF_FireHurt.AddChangeHook(ConVarChanged);
	GBlockFF_MinDistance.AddChangeHook(ConVarChanged);
	GBlockFF_MaxDistance.AddChangeHook(ConVarChanged);
	GBlockFF_InfectedNearRange.AddChangeHook(ConVarChanged);
	GBlockFF_ChargerCarry.AddChangeHook(ConVarChanged);
	GBlockFF_RescuedPinned.AddChangeHook(ConVarChanged);
	GBlockFF_HaveAliveTank.AddChangeHook(ConVarChanged);
	GBlockFF_ColdTime.AddChangeHook(ConVarChanged);
	GBlockFF_RoundMaxFF.AddChangeHook(ConVarChanged);

	HookEvent("round_start",				Event_RoundStart,					EventHookMode_PostNoCopy);
	HookEvent("player_entered_checkpoint",	Event_PlayerEnteredCheckpoint);
	HookEvent("player_left_checkpoint",		Event_PlayerLeftCheckpoint);
	HookEvent("player_left_safe_area",		Event_PlayerLeftSafeArea,			EventHookMode_PostNoCopy);
	HookEvent("finale_escape_start", 		Event_OnFinaleStart,				EventHookMode_PostNoCopy);
	HookEvent("finale_vehicle_incoming", 	Event_OnFinaleStart,				EventHookMode_PostNoCopy);
	HookEvent("finale_vehicle_ready", 		Event_OnFinaleStart,				EventHookMode_PostNoCopy);
	HookEvent("player_hurt",				Event_PlayerHurt);
	HookEvent("player_spawn",				Event_PlayerSpawn);
	HookEvent("tongue_release",				Event_RescuedFromInfected);
	HookEvent("jockey_ride_end",			Event_RescuedFromInfected);
	HookEvent("charger_carry_end",			Event_RescuedFromInfected);
	HookEvent("door_open",					Event_Door_OC);
	HookEvent("door_close",					Event_Door_OC);
	HookEvent("player_bot_replace",			Event_PlayerBotReplace);
	HookEvent("bot_player_replace",			Event_BotPlayerReplace);

	AutoExecConfig(true, "l4d2_survivor_ff_block_fix");
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
	BlockFF_RoundStart				= GBlockFF_RoundStart.BoolValue;
	BlockFF_RoundStart_Print		= GBlockFF_RoundStart_Print.BoolValue;
	BlockFF_InsideSafeRoom			= GBlockFF_InsideSafeRoom.BoolValue;
	BlockFF_GetEnd					= GBlockFF_GetEnd.BoolValue;
	BlockFF_MeleeHurt				= GBlockFF_MeleeHurt.BoolValue;
	BlockFF_FireHurt				= GBlockFF_FireHurt.BoolValue;
	BlockFF_MinDistance				= GBlockFF_MinDistance.FloatValue;
	BlockFF_MaxDistance				= GBlockFF_MaxDistance.FloatValue;
	BlockFF_InfectedNearRange		= GBlockFF_InfectedNearRange.FloatValue;
	BlockFF_ChargerCarry			= GBlockFF_ChargerCarry.BoolValue;
	BlockFF_RescuedPinned			= GBlockFF_RescuedPinned.BoolValue;
	BlockFF_HaveAliveTank			= GBlockFF_HaveAliveTank.BoolValue;
	BlockFF_ColdTime				= GBlockFF_ColdTime.FloatValue;
	BlockFF_RoundMaxFF				= GBlockFF_RoundMaxFF.IntValue;

	if (BlockFF_ColdTime > 0.0 && BlockFF_ColdTime < 0.3)
		BlockFF_ColdTime = 0.3;
}





// ====================================================================================================
// Game void
// ====================================================================================================

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

public void OnMapStart()
{
	StartSafeArea	= -1;
	EndSafeArea		= -1;

	for (int i = 0; i < 3 ; i++)
		EndSafeDoorPos[i] = 0.0;
	IsGetEndSafeDoorPos = false;
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	LeftSafeArea = false;
	GetEnd = false;
	IsCheckStartSafeArea = false;

	for (int i = 1; i <= MaxClients ; i++)
	{
		MyFF[i] = 0;
		IsAllowBlockFF[i] = false;
		CanHurt[i] = false;
		CanHurtChange[i] = false;
	}
}

public void Event_PlayerEnteredCheckpoint(Event event, const char[] name, bool dontBroadcast)
{
	if (!LeftSafeArea || GetEnd || StartSafeArea <= 0)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (!IsSurvivor(client) || !IsPlayerAlive(client) || IsSpawning[client])
		return;

	int area = GetEventInt(event, "area");

	if (area == StartSafeArea)
		return;

	if (EndSafeArea > 0 && area != EndSafeArea)
		return;

	GetEnd = true;
	PrintHintTextToAll("%N到达终点安全区, 友伤已自动关闭.", client);

	if (EndSafeArea > 0)
		return;

	EndSafeArea = area;
}

public void Event_PlayerLeftCheckpoint(Event event, const char[] name, bool dontBroadcast)
{
	if (LeftSafeArea || StartSafeArea > 0)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsSurvivor(client) || !IsPlayerAlive(client) || IsSpawning[client])
		return;

	if (IsCheckStartSafeArea)
		return;

	int area = GetEventInt(event, "area");
	IsCheckStartSafeArea = true;
	CreateTimer(0.5, CheckIsStartSafeArea, area, TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_PlayerLeftSafeArea(Event event, const char[] name, bool dontBroadcast)
{
	if (LeftSafeArea)
		return;

	GetEndSafeDoorPos();

	if (BlockFF_RoundStart && BlockFF_RoundStart_Print)
		PrintHintTextToAll("友伤已自动开启.");
	
	LeftSafeArea = true;
}

public void Event_OnFinaleStart(Event event, const char[] name, bool dontBroadcast)
{
	if (L4D_GetCurrentChapter() < L4D_GetMaxChapters())
		return;

	if (!BlockFF_GetEnd)
		return;

	if (GetEnd)
		return;

	GetEnd = true;
	PrintHintTextToAll("救援来临, 友伤已自动关闭.");
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (BlockFF_RoundMaxFF < 0)
		return;

	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (!IsSurvivor(attacker) || MyFF[attacker] >= BlockFF_RoundMaxFF)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsSurvivor(client))
		return;

	if (attacker == client)
		return;
	
	int Dmg = GetEventInt(event, "dmg_health");
	
	if (Dmg <= 0)
		return;
	
	MyFF[attacker] += Dmg;
	if (MyFF[attacker] >= BlockFF_RoundMaxFF)
		PrintToChatAll("\x04[提示] \x03%N \x05的友伤已达到上限.[ \x03%d \x05]", attacker, MyFF[attacker]);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!IsGetEndSafeDoorPos)
		GetEndSafeDoorPos();

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsSurvivor(client))
		return;
	
	IsSpawning[client] = true;
	CreateTimer(1.0, Recold_IsSpawning, client);

	IsAllowBlockFF[client] = false;
	CanHurt[client] = false;
	CanHurtChange[client] = false;
}

public void Event_RescuedFromInfected(Handle event, const char[] name, bool dontBroadcast)
{
	if (!BlockFF_RescuedPinned)
		return;

	int client = GetClientOfUserId(GetEventInt(event, "victim"));

	if (!IsSurvivor(client) || !IsPlayerAlive(client) || IsAllowBlockFF[client])
		return;
	
	IsAllowBlockFF[client] = true;
	CreateTimer(1.0, ReCold_IsAllowBlockFF, client);
}

public void Event_Door_OC(Event event, const char[] name, bool dontBroadcast)
{
	if (!IsGetEndSafeDoorPos || GetEnd || !event.GetBool("checkpoint"))
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsSurvivor(client) || !IsPlayerAlive(client) || IsSpawning[client])
		return;

	float ClientPos[3], Distance;
	GetClientAbsOrigin(client, ClientPos);
	Distance = GetVectorDistance(ClientPos, EndSafeDoorPos);

	if (Distance > 200.0)
		return;

	GetEnd = true;
	PrintHintTextToAll("%N触碰终点安全门, 友伤已自动关闭.", client);
}

public void Event_PlayerBotReplace(Event event, char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(event.GetInt("bot"));

	if (!IsSurvivor(bot) || !IsPlayerAlive(bot) || !IsSpawning[bot])
		return;

	int player = GetClientOfUserId(event.GetInt("player"));

	if (player <= 0 || player > MaxClients || !IsClientInGame(player))
		return;

	IsSpawning[player] = true;
	CreateTimer(1.0, Recold_IsSpawning, player);
}

public void Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(event.GetInt("player"));

	if (!IsSurvivor(player) || !IsPlayerAlive(player) || !IsSpawning[player])
		return;

	int bot = GetClientOfUserId(event.GetInt("bot"));

	if (bot <= 0 || bot > MaxClients || !IsClientInGame(bot))
		return;

	IsSpawning[bot] = true;
	CreateTimer(1.0, Recold_IsSpawning, bot);
}





// ====================================================================================================
// Game Action
// ====================================================================================================

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype,
						int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!IsSurvivor(attacker) || !IsSurvivor(client))
		return Plugin_Continue;

	if (BlockFF_RoundStart && !LeftSafeArea)
		return Plugin_Handled;

	if (BlockFF_GetEnd && GetEnd)
		return Plugin_Handled;

	if (BlockFF_InsideSafeRoom &&
		(L4D_IsInFirstCheckpoint(attacker) ||
		L4D_IsInLastCheckpoint(attacker) ||
		L4D_IsInFirstCheckpoint(client) ||
		L4D_IsInLastCheckpoint(client)))
	{
		return Plugin_Handled;
	}
	
	if (BlockFF_HaveAliveTank && IsHaveAliveTank())
		return Plugin_Handled;

	if (BlockFF_RoundMaxFF >= 0)
	{
		if (MyFF[attacker] >= BlockFF_RoundMaxFF)
			return Plugin_Handled;
		else
		{
			if (MyFF[attacker] + RoundToFloor(damage) > BlockFF_RoundMaxFF)
				damage = float(BlockFF_RoundMaxFF - MyFF[attacker]);
		}
	}

	if (damagetype & DMG_BLAST)
		return Plugin_Continue;

	if (damagetype == DMG_BURN || damagetype == DOUBANFIRE || damagetype == DOUBANONFIRE)
	{
		if (BlockFF_FireHurt)
			return Plugin_Handled;
		else
			return Plugin_Continue;
	}

	if (client == attacker)
		return Plugin_Continue;

	if (BlockFF_MeleeHurt && IsMelee(inflictor))
		return Plugin_Handled;

	if (BlockFF_ChargerCarry && GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0)
		return Plugin_Handled;
	
	if (BlockFF_RescuedPinned && IsAllowBlockFF[client])
		return Plugin_Handled;
	
	float AttackerPos[3], VictimPos[3], Dist;
	GetClientAbsOrigin(attacker, AttackerPos);
	GetClientAbsOrigin(client, VictimPos);
	Dist = GetVectorDistance(AttackerPos, VictimPos);

	if (BlockFF_MinDistance > 0.0 && Dist <= BlockFF_MinDistance)
		return Plugin_Handled;
	
	if (BlockFF_MaxDistance > 0.0 && Dist >= BlockFF_MaxDistance)
		return Plugin_Handled;

	if (BlockFF_InfectedNearRange > 0.0 && IsHaveInfectedCloseRange(client, VictimPos))
		return Plugin_Handled;

	if (BlockFF_ColdTime > 0.0 && !CanHurt[attacker])
	{
		if (!CanHurtChange[attacker])
		{
			CreateTimer(0.1, Change_CanHurt, attacker);
			CreateTimer(BlockFF_ColdTime, Recold_CanHurt, attacker);
			CanHurtChange[attacker] = true;
		}
		return Plugin_Handled;
	}

	return Plugin_Changed;
}

public Action OnTakeDamageAlive(int client, int &attacker, int &inflictor, float &damage, int &damagetype,
							int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!IsSurvivor(attacker) || !IsSurvivor(client))
		return Plugin_Continue;

	if (BlockFF_FireHurt && (damagetype == DMG_BURN || damagetype == DOUBANFIRE || damagetype == DOUBANONFIRE))
		return Plugin_Handled;
	
	return Plugin_Continue;
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

public Action Recold_IsSpawning(Handle timer, int client)
{
	IsSpawning[client] = false;
	return Plugin_Continue;
}

public Action CheckIsStartSafeArea(Handle timer, int area)
{
	if (LeftSafeArea)
		StartSafeArea = area;
	IsCheckStartSafeArea = false;
	return Plugin_Continue;
}

public Action Change_CanHurt(Handle timer, int client)
{
	CanHurt[client] = true;
	return Plugin_Continue;
}

public Action Recold_CanHurt(Handle timer, int client)
{
	CanHurt[client] = false;
	CanHurtChange[client] = false;
	return Plugin_Continue;
}

public Action ReCold_IsAllowBlockFF(Handle timer, int client)
{
	IsAllowBlockFF[client] = false;
	return Plugin_Continue;
}





// ====================================================================================================
// void
// ====================================================================================================

public void GetEndSafeDoorPos()
{
	int entity = INVALID_ENT_REFERENCE;
	if ((entity = FindEntityByClassname(MaxClients + 1, "info_changelevel")) == -1)
		entity = FindEntityByClassname(MaxClients + 1, "trigger_changelevel");

	if (entity == -1)
		return;

	int door = L4D_GetCheckpointLast();

	if (door == -1 || !IsValidEdict(door))
		return;

	IsGetEndSafeDoorPos = true;
	GetEntPropVector(door, Prop_Data, "m_vecAbsOrigin", EndSafeDoorPos);
}





// ====================================================================================================
// bool
// ====================================================================================================

public bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

public bool IsHaveAliveTank()
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == 8)
			return true;
	}
	return false;
}

public bool IsMelee(int inflictor)
{
	if (inflictor > MaxClients)
	{
		static char classname[13];
		GetEdictClassname(inflictor, classname, sizeof(classname));
		return strcmp(classname, "weapon_melee") == 0;
	}
	return false;
}

public bool IsHaveInfectedCloseRange(int client, float ClientPos[3])
{
	float InfectedPos[3];
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, InfectedPos);
			float distance = GetVectorDistance(ClientPos, InfectedPos);
			if (distance <= BlockFF_InfectedNearRange)
				return true;
		}
	}
	return false;
}