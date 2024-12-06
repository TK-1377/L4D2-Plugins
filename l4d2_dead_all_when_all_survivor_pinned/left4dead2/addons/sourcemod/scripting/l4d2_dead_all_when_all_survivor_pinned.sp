#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS		FCVAR_NOTIFY

Handle fail_find;
int fail_dn, dead_dn = 7;

int DEAD_TIMER = 3;
float FARFROM_DISTANCE = 800.0;
bool VOICE_PRINT = true, TIMER_PRINT = true;

ConVar
	GDEAD_TIMER,
	GFARFROM_DISTANCE,
	GVOICE_PRINT,
	GTIMER_PRINT;

public void OnPluginStart()
{
	GDEAD_TIMER			=  CreateConVar("l4d2_dawasp_dead_time",
										"3",
										"生还者全被控后几秒处死? (0 = 即刻处死)", CVAR_FLAGS, true, 0.0);
	GFARFROM_DISTANCE	=  CreateConVar("l4d2_dawasp_far_from_distance",
										"800.0",
										"倒地生还者距离其他 非倒地/挂边 的存活的幸存者多少距离以上视为远离?", CVAR_FLAGS, true, 50.0);
	GVOICE_PRINT		=  CreateConVar("l4d2_dawasp_voice_print",
										"1",
										"启用音效提示. (0 = 禁用, 1 = 启用)", CVAR_FLAGS, true, 0.0, true, 1.0);
	GTIMER_PRINT		=  CreateConVar("l4d2_dawasp_time_print",
										"1",
										"启用倒计时提示. (0 = 禁用, 1 = 启用)", CVAR_FLAGS, true, 0.0, true, 1.0);

	GDEAD_TIMER.AddChangeHook(ConVarChanged);
	GFARFROM_DISTANCE.AddChangeHook(ConVarChanged);
	GVOICE_PRINT.AddChangeHook(ConVarChanged);
	GTIMER_PRINT.AddChangeHook(ConVarChanged);

	HookEvent("round_start",	Event_RoundStart,		EventHookMode_PostNoCopy);		// 回合开始
	HookEvent("round_end",		Event_RoundEnd,			EventHookMode_PostNoCopy);		// 回合结束

	AutoExecConfig(true, "l4d2_dead_all_when_all_survivor_pinned");
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
	DEAD_TIMER			= GDEAD_TIMER.IntValue;
	FARFROM_DISTANCE	= GFARFROM_DISTANCE.FloatValue;
	VOICE_PRINT			= GVOICE_PRINT.BoolValue;
	TIMER_PRINT			= GTIMER_PRINT.BoolValue;

	dead_dn = DEAD_TIMER * 2 + 1;
}





// ====================================================================================================
// Game void
// ====================================================================================================

public void OnMapStart()
{
	PrecacheSound("ui/beep07.wav");
	PrecacheSound("ui/survival_teamrec.wav");
}

public void OnMapEnd()
{
	fail_dn = 0;
	if (fail_find != null)
		delete fail_find;
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

// 回合开始
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	OnMapEnd();
	if (fail_find == null)
		fail_find = CreateTimer(0.5, IAFF, _, TIMER_REPEAT);
}

// 回合结束
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	OnMapEnd();
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

public Action IAFF(Handle timer)
{
	Is_All_Fail_Find();
	return Plugin_Continue;
}





// ====================================================================================================
// void
// ====================================================================================================

public void Is_All_Fail_Find()
{
	int player_num = GetPlayerNumber(0);
	int incap_num = GetPlayerNumber(1);
	if (player_num >= 1 && incap_num >= player_num)
	{
		fail_dn ++;
		if (fail_dn >= dead_dn)
		{
			KillAllSurvivors();
		}
		else if (fail_dn == 1)
		{
			if (TIMER_PRINT)
			{
				PrintToChatAll("\x04[提示] \x05所有人\x03被控\x05/\x03挂边\x05/\x03倒地且远离队友\x05, 开启处死倒计时:");
			}
			else
			{
				PrintToChatAll("\x04[提示] \x05所有人\x03被控\x05/\x03挂边\x05/\x03倒地且远离队友\x05, 将在 \x03%d秒 \x05后被处死.",
								DEAD_TIMER);
			}
		}
		else if (fail_dn %2 == 0 && fail_dn < dead_dn)
		{
			if (TIMER_PRINT)
				PrintToChatAll("\x04[提示]\x05处死倒计时: \x03%d", ((dead_dn - fail_dn + 1) / 2));
			if (VOICE_PRINT)
				EmitSoundToAll("ui/beep07.wav");
		}
	}
	else
		fail_dn = 0;
}

public void KillAllSurvivors()
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			ForcePlayerSuicide(i);
	}
	EmitSoundToAll("ui/survival_teamrec.wav");
	PrintToChatAll("\x03<------- All Incap, Kill. ------->");
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

public int GetPlayerNumber(int type)
{
	int num = 0;
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			if (type == 0)
				num ++;
			else if (type == 1)
			{
				if (IsPinned(i) || IsPlayerFalling(i) || (IsPlayerFallen(i) && IsBeAwayFromOtherSurvivor(i)))
					num ++;
			}
		}
	}
	return num;
}











// ====================================================================================================
// bool
// ====================================================================================================

public bool IsPlayerState(int client)
{
    return !GetEntProp(client, Prop_Send, "m_isIncapacitated") && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

public bool IsPlayerFalling(int client)
{
    return GetEntProp(client, Prop_Send, "m_isIncapacitated") && GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

public bool IsPlayerFallen(int client)
{
    return GetEntProp(client, Prop_Send, "m_isIncapacitated") && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

public bool IsPinned(int client)
{
	return (GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0 ||
			GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0 ||
			GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0 ||
			GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0 ||
			GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0);
}

public bool IsBeAwayFromOtherSurvivor(int client)
{
	int player_num = GetPlayerNumber(0);
	if (player_num <= 1)
		return true;
	else
	{
		float client1_dis[3], client2_dis[3], dist;
		GetClientAbsOrigin(client, client1_dis);
		for (int i = 1; i <= MaxClients ; i ++)
		{
			if (i != client && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsPlayerState(i))
			{
				GetClientAbsOrigin(i, client2_dis);
				dist = GetVectorDistance(client1_dis, client2_dis);
				if (dist <= FARFROM_DISTANCE)
					return false;
			}
		}
		return true;
	}
}