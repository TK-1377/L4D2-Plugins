#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>

#define CVAR_FLAGS				FCVAR_NOTIFY

#define MaxColorsNum			11

#define Hunter_GetUp_Timer		2.0
#define	Charger_GetUp_Timer		3.0
#define Boomed_Fade_Timer		10.0

int Colors_Value[MaxColorsNum][3] =
{
	{  0, 208,   0},		// 健康
	{  0, 208, 208},		// 快要瘸腿
	{208, 208,   0},		// 瘸腿
	{208, 208, 208},		// 低血量
	{  0,   0, 208},		// 黑白
	{208,   0, 208},		// 被喷
	{255, 128,   0},		// 倒地
	{255, 128,   0},		// 挂边
	{255,   0,   0},		// 被控
	{224, 126, 149},		// 起身
	{208,   0,   0}			// 其他
};

char Colors_ConVarString[MaxColorsNum][11] =
{
	"health",
	"qlimp",
	"limp",
	"lowhp",
	"blackwhite",
	"boomed",
	"fallen",
	"falling",
	"pinned",
	"getup",
	"other"
};

char Colors_ConVarText[MaxColorsNum][48] =
{
	"健康(HP > Y1)",
	"快要瘸腿(瘸腿临界值 <= HP <= Y1)",
	"瘸腿(HP < 瘸腿临界值)",
	"低血量(HP <= X1)",
	"黑白",
	"被喷",
	"倒地",
	"挂边",
	"被控",
	"起身",
	"其他"
};

int Colors_Weight[MaxColorsNum] =
{
	2,		// 健康
	2,		// 快要瘸腿
	2,		// 瘸腿
	3,		// 低血量
	5,		// 黑白
	7,		// 被喷
	2,		// 倒地
	2,		// 挂边
	8,		// 被控
	6,		// 起身
	0		// 其他
};

int HPFX1 = 24;
int HPFY1 = 50;
int GLOW_RANGE = 1800;

ConVar GColors_Value[MaxColorsNum];
ConVar GColors_Weight[MaxColorsNum];

ConVar GHPFX1;
ConVar GHPFY1;
ConVar GGLOW_RANGE;
ConVar G_Survivor_Limp_Health;
ConVar G_Survivor_Max_Incapacitated_Count;

int GlowType[32];
float VomitStart[32], VomitEnd[32];
bool IsBoomed[32], IsGetUp[32];

Handle GlowCheck;

public void OnPluginStart()
{
	GGLOW_RANGE		=  CreateConVar("l4d2_survivor_glow_a_range",
									"1800",
									"幸存者发光距离. (超过这个距离发光将变为原版设定, 即插件的发光效果不生效)",
									CVAR_FLAGS, true, 0.0);
	GHPFX1			=  CreateConVar("l4d2_survivor_glow_b1_health_x1",
									"24",
									"幸存者生命值 0 ~ 瘸腿临界值 的中间设定值. (此值大于等于瘸腿临界值会自动修正)\n瘸腿临界值 默认: 40",
									CVAR_FLAGS, true, 1.0);
	GHPFY1			=  CreateConVar("l4d2_survivor_glow_b2_health_y1",
									"50",
									"幸存者生命值 瘸腿临界值以上 的额外设定值. (此值小于等于瘸腿临界值会自动修正)\n瘸腿临界值 默认: 40",
									CVAR_FLAGS, true, 3.0);

	char TempStr1[48], TempStr2[12], TempStr3[72];
	for (int i = 0; i < MaxColorsNum ; i++)
	{
		int x = (i + 1) / 10;
		int y = (i + 1) % 10;
		Format(TempStr1, sizeof(TempStr1), "l4d2_survivor_glow_c%d_%d_%s", x, y, Colors_ConVarString[i]);
		Format(TempStr2, sizeof(TempStr2), "%d %d %d", Colors_Value[i][0], Colors_Value[i][1], Colors_Value[i][2]);
		Format(TempStr3, sizeof(TempStr3), "%s状态下的发光RGB值.", Colors_ConVarText[i]);
		GColors_Value[i] = CreateConVar(TempStr1, TempStr2, TempStr3, CVAR_FLAGS);

		if (i < MaxColorsNum - 1)
		{
			Format(TempStr1, sizeof(TempStr1), "l4d2_survivor_glow_w%d_%d_%s", x, y, Colors_ConVarString[i]);
			Format(TempStr2, sizeof(TempStr2), "%d", Colors_Weight[i]);
			Format(TempStr3, sizeof(TempStr3), "%s状态下的发光权重.", Colors_ConVarText[i]);
			GColors_Weight[i] = CreateConVar(TempStr1, TempStr2, TempStr3, CVAR_FLAGS, true, 0.0);
		}
	}

	G_Survivor_Limp_Health				= FindConVar("survivor_limp_health");
	G_Survivor_Max_Incapacitated_Count	= FindConVar("survivor_max_incapacitated_count");

	GGLOW_RANGE.AddChangeHook(ConVarChanged);
	GHPFX1.AddChangeHook(ConVarChanged);
	GHPFY1.AddChangeHook(ConVarChanged);
	for (int i = 0; i < MaxColorsNum ; i++)
	{
		GColors_Value[i].AddChangeHook(ConVarChanged);
		if (i < MaxColorsNum - 1)
			GColors_Weight[i].AddChangeHook(ConVarChanged);
	}

	HookEvent("round_start",			Event_RoundStart,			EventHookMode_PostNoCopy);
	HookEvent("round_end",				Event_RoundEnd,				EventHookMode_PostNoCopy);
	HookEvent("pounce_stopped",			Event_PounceEnd);
	HookEvent("charger_pummel_end",		Event_PummelEnd);
	HookEvent("player_bot_replace",		Event_PlayerBotReplace);
	HookEvent("bot_player_replace",		Event_BotPlayerReplace);
	HookEvent("player_disconnect",		Event_PlayerDisconnect,		EventHookMode_Pre);

	AutoExecConfig(true, "l4d2_survivor_glow");
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
	GLOW_RANGE		= GGLOW_RANGE.IntValue;
	HPFX1			= GHPFX1.IntValue;
	HPFY1			= GHPFY1.IntValue;

	int HPSLP = G_Survivor_Limp_Health.IntValue;

	if (HPFX1 >= HPSLP)
	{
		if (HPSLP >= 26)
			HPFX1 = 24;
		else
		{
			HPFX1 = HPSLP - 10;
			if (HPFX1 < 1)
				HPFX1 = 1;
		}
	}
	if (HPFY1 <= HPSLP)
		HPFY1 = HPSLP + 10;

	char Temp_GetConVarString[12], Buffers[3][4];
	int TempI;
	for (int i = 0; i < MaxColorsNum ; i++)
	{
		GColors_Value[i].GetString(Temp_GetConVarString, sizeof(Temp_GetConVarString));
		TrimString(Temp_GetConVarString);
		ExplodeString(Temp_GetConVarString, " ", Buffers, sizeof(Buffers), sizeof(Buffers[]));
		for (int j = 0; j < 3 ; j++)
		{
			TempI = StringToInt(Buffers[j]);
			Colors_Value[i][j] = CorrectInt(TempI, 0, 255);
		}
		if (i < MaxColorsNum - 1)
			Colors_Weight[i] = GColors_Weight[i].IntValue;
	}
}





// ====================================================================================================
// Game void
// ====================================================================================================

// 地图结束
public void OnMapEnd()
{
	if (GlowCheck != null)
		delete GlowCheck;
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	OnMapEnd();
	for (int i = 1; i <= MaxClients ; i ++)
	{
		GlowType[i]		= -15;
		VomitStart[i]	= 0.0;
		VomitEnd[i]		= 0.0;
		IsBoomed[i]		= false;
		IsGetUp[i]		= false;
	}

	if (GlowCheck == null)
		GlowCheck = CreateTimer(0.5, Glow_Check, _, TIMER_REPEAT);
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	OnMapEnd();
}

public void Event_PounceEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "victim"));

	if (!IsSurvivor(client) || !IsPlayerAlive(client) || !IsPlayerState(client) || IsGetUp[client])
		return;

	IsGetUp[client] = true;
	SetGlow();
	CreateTimer(Hunter_GetUp_Timer, ReCold_IsGetUp, client, TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_PummelEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "victim"));

	if (!IsSurvivor(client) || !IsPlayerAlive(client) || !IsPlayerState(client) || IsGetUp[client])
		return;

	IsGetUp[client] = true;
	SetGlow();
	CreateTimer(Charger_GetUp_Timer, ReCold_IsGetUp, client, TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_PlayerBotReplace(Event event, char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(event.GetInt("bot"));

	if (!IsSurvivor(bot) || !IsPlayerAlive(bot))
		return;

	int player = GetClientOfUserId(event.GetInt("player"));

	GlowType[bot]		= -15;
	GlowType[player]	= -15;
	SetGlow();
	RemoveGlows(player);
}

public void Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(event.GetInt("player"));

	if (!IsSurvivor(player) || !IsPlayerAlive(player))
		return;

	int bot = GetClientOfUserId(event.GetInt("bot"));

	GlowType[bot]		= -15;
	GlowType[player]	= -15;
	SetGlow();
	RemoveGlows(bot);
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsSurvivor(client) || !IsFakeClient(client))
		return;
	
	GlowType[client] = -15;
	RemoveGlows(client);
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

public Action Glow_Check(Handle timer)
{
	SetGlow();
	return Plugin_Continue;
}

public Action ReCold_IsGetUp(Handle timer, int client)
{
	IsGetUp[client] = false;
	SetGlow();
	return Plugin_Continue;
}

public Action ReCold_IsBoomed(Handle timer, int client)
{
	IsBoomed[client] = false;
	return Plugin_Continue;
}





// ====================================================================================================
// Set Glow
// ====================================================================================================

public void SetGlow()
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) &&
			GetClientTeam(i) == 2 &&
			GetEntProp(i, Prop_Send, "m_survivorCharacter") >= 0 &&
			GetEntProp(i, Prop_Send, "m_survivorCharacter") <= 7)
		{
			float vstart = GetEntPropFloat(i, Prop_Send, "m_vomitStart");
			float vend   = GetEntPropFloat(i, Prop_Send, "m_vomitFadeStart");

			if (vstart > VomitStart[i] || vend > VomitEnd[i])
			{
				VomitStart[i]	= vstart;
				VomitEnd[i]		= vend;
				IsBoomed[i]		= true;
				CreateTimer(Boomed_Fade_Timer, ReCold_IsBoomed, i, TIMER_FLAG_NO_MAPCHANGE);
			}

			if (IsPlayerAlive(i))
			{
				int Now_GlowType = -1, Now_GlowWeight = -1;

				if (IsPlayerState(i))
				{
					int NowHP = GetPlayHP(i);

					if (NowHP > HPFY1)
					{
						Now_GlowType	= 0;
						Now_GlowWeight	= Colors_Weight[0];
					}
					else if (NowHP >= G_Survivor_Limp_Health.IntValue)
					{
						Now_GlowType	= 1;
						Now_GlowWeight	= Colors_Weight[1];
					}
					else
					{
						Now_GlowType	= 2;
						Now_GlowWeight	= Colors_Weight[2];

						if (Now_GlowWeight < Colors_Weight[3] && NowHP <= HPFX1)
						{
							Now_GlowType	= 3;
							Now_GlowWeight	= Colors_Weight[3];
						}
					}

					if (Now_GlowWeight < Colors_Weight[4] && 
						GetEntProp(i, Prop_Send, "m_currentReviveCount") >= G_Survivor_Max_Incapacitated_Count.IntValue)
					{
						Now_GlowType	= 4;
						Now_GlowWeight	= Colors_Weight[4];
					}

					if (Now_GlowWeight < Colors_Weight[9] && IsGetUp[i])
					{
						Now_GlowType	= 9;
						Now_GlowWeight	= Colors_Weight[9];
					}
				}
				else if (IsPlayerFallen(i))
				{
					Now_GlowType	= 6;
					Now_GlowWeight	= Colors_Weight[6];
				}
				else if (IsPlayerFalling(i))
				{
					Now_GlowType	= 7;
					Now_GlowWeight	= Colors_Weight[7];
				}

				if (Now_GlowWeight < Colors_Weight[5] && IsBoomed[i])
				{
					Now_GlowType	= 5;
					Now_GlowWeight	= Colors_Weight[5];
				}

				if (Now_GlowWeight < Colors_Weight[8] && IsPinned(i))
				{
					Now_GlowType	= 8;
					Now_GlowWeight	= Colors_Weight[8];
				}

				if (Now_GlowType == -1)
					Now_GlowType = 10;

				if (Now_GlowType == GlowType[i])
					continue;

				GlowType[i] = Now_GlowType;
				ResetGlows(i,Colors_Value[Now_GlowType][0], Colors_Value[Now_GlowType][1], Colors_Value[Now_GlowType][2]);
			}
			else
			{
				if (GlowType[i] != -15)
				{
					GlowType[i] = -15;
					RemoveGlows(i);
				}
			}
		}
	}
}





// ====================================================================================================
// Glow
// ====================================================================================================

public void ResetGlows(int iEntity, int n1, int n2, int n3)
{
	SetEntProp(iEntity, Prop_Send, "m_iGlowType", 3);
	SetEntProp(iEntity, Prop_Send, "m_glowColorOverride", GetColor(n1, n2, n3));
	SetEntProp(iEntity, Prop_Send, "m_nGlowRange", GLOW_RANGE);
	SetEntProp(iEntity, Prop_Send, "m_bFlashing", 0, 0);
}

public void RemoveGlows(int iEntity)
{
	SetEntProp(iEntity, Prop_Send, "m_iGlowType", 0);
	SetEntProp(iEntity, Prop_Send, "m_glowColorOverride", 0);
	SetEntProp(iEntity, Prop_Send, "m_nGlowRange", 0);
	SetEntProp(iEntity, Prop_Send, "m_bFlashing", 0, 0);
}

public int GetColor(int a1, int a2, int a3)
{
	int color;
	color = a1;
	color += 256 * a2;
	color += 65536 * a3;
	return color;
}





// ====================================================================================================
// int
// ====================================================================================================

// 获取总生命值
public int GetPlayHP(int client)
{
	return (GetClientHealth(client) + GetPlayerTempHealth(client));
}

// 获取虚血值
public int GetPlayerTempHealth(int client)
{
	static Handle painPillsDecayCvar = null;
	if (painPillsDecayCvar == null)
	{
		painPillsDecayCvar = FindConVar("pain_pills_decay_rate");
		if (painPillsDecayCvar == null)
			return -1;
	}

	float Buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	float BufferTimer = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
	float Gfloat = GetConVarFloat(painPillsDecayCvar);
	int tempHealth = RoundToCeil(Buffer - ((GetGameTime() - BufferTimer) * Gfloat)) - 1;
	return tempHealth < 0 ? 0 : tempHealth;
}

public int CorrectInt(int value, int min, int max)
{
	if (value < min)
		return min;
	
	if (value > max)
		return max;
	
	return value;
}





// ====================================================================================================
// bool
// ====================================================================================================

// 判定幸存者是否被控
public bool IsPinned(int client)
{
	return (GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0 ||
			GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0 ||
			GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0 ||
			GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0 ||
			GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0);
}

public bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

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