#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS						FCVAR_NOTIFY

#define SpriteCustomVMTPathString		"mart/mart_custombar2.vmt"
#define SpriteCustomVTFPathString		"mart/mart_custombar2.vtf"	

int SpriteEntityID[2049];
int SpriteFrameEntityID[2049];

bool RoundEnd;

float CheckInterval = 0.5;
float SpriteWitchHigh = 70.0;
int SpriteWitchAlpha = 200;
char SpriteWitchScale[5] = "0.60";
char SpriteWitchColors[12] = "208 0 0";
int SpriteWitchVisibility = 7;
bool SpriteWitchTeamVisibility[3] = {true, true, true};

ConVar GCheckInterval;
ConVar GSpriteWitchHigh;
ConVar GSpriteWitchAlpha;
ConVar GSpriteWitchScale;
ConVar GSpriteWitchColors;
ConVar GSpriteWitchVisibility;

public void OnPluginStart()
{
	ReZero();

	GCheckInterval						=  CreateConVar("l4d2_witch_hp_sprite_check_interval",
														"0.5",
														"Witch血量显示条计时器检查的时间间隔.",
														CVAR_FLAGS, true, 0.1);
	GSpriteWitchHigh					=  CreateConVar("l4d2_witch_hp_sprite_high",
														"70.0",
														"Witch血量显示条位于对应玩家的高度.",
														CVAR_FLAGS, true, 0.0);
	GSpriteWitchAlpha					=  CreateConVar("l4d2_witch_hp_sprite_alpha",
														"200",
														"Witch血量显示条的可见度. (0 = 完全透明, 255 = 完全不透明)",
														CVAR_FLAGS, true, 0.0, true, 255.0);
	GSpriteWitchScale					=  CreateConVar("l4d2_witch_hp_sprite_scale",
														"0.60",
														"Witch血量显示条的大小.",
														CVAR_FLAGS, true, 0.01);
	GSpriteWitchColors					=  CreateConVar("l4d2_witch_hp_sprite_colors",
														"208 0 0",
														"Witch血量显示条的RGB.",
														CVAR_FLAGS);
	GSpriteWitchVisibility				=  CreateConVar("l4d2_witch_hp_sprite_visibility",
														"7",
														"可以看见Witch血量显示条的队伍. (1 = 旁观 2 = 生还 4 = 感染者)\n 将需要项相加",
														CVAR_FLAGS, true, 0.0, true, 7.0);

	GCheckInterval.AddChangeHook(ConVarChanged);
	GSpriteWitchHigh.AddChangeHook(ConVarChanged);
	GSpriteWitchAlpha.AddChangeHook(ConVarChanged);
	GSpriteWitchScale.AddChangeHook(ConVarChanged);
	GSpriteWitchColors.AddChangeHook(ConVarChanged);
	GSpriteWitchVisibility.AddChangeHook(ConVarChanged);

	AddFileToDownloadsTable(SpriteCustomVMTPathString);
	AddFileToDownloadsTable(SpriteCustomVTFPathString);

	HookEvent("round_start",		Event_RoundStart,			EventHookMode_PostNoCopy);
	HookEvent("round_end",			Event_RoundEnd,				EventHookMode_PostNoCopy);
	HookEvent("witch_spawn",		Event_WitchSpawn);
	HookEvent("witch_killed",		Event_WitchKilled);

	AutoExecConfig(true, "l4d2_witch_hp_sprite");
}





// ====================================================================================================
// ConVar Changed
// ====================================================================================================

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

public void GetCvars()
{
	CheckInterval			= GCheckInterval.FloatValue;
	SpriteWitchHigh			= GSpriteWitchHigh.FloatValue;
	SpriteWitchAlpha		= GSpriteWitchAlpha.IntValue;

	float fSpriteWitchScale = GSpriteWitchScale.FloatValue;
	FloatToString(fSpriteWitchScale, SpriteWitchScale, sizeof(SpriteWitchScale));

	SpriteWitchVisibility	= GSpriteWitchVisibility.IntValue;

	if (SpriteWitchVisibility >= 4)
	{
		SpriteWitchTeamVisibility[2] = true;
		SpriteWitchTeamVisibility[1] = SpriteWitchVisibility >= 6 ? true : false;
	}
	else
	{
		SpriteWitchTeamVisibility[2] = false;
		SpriteWitchTeamVisibility[1] = SpriteWitchVisibility >= 2 ? true : false;
	}
	SpriteWitchTeamVisibility[0] = (SpriteWitchVisibility % 2) == 1 ? true : false;

	char TempStr[12], Buffers[3][4];
	int TempI3[3];
	GSpriteWitchColors.GetString(TempStr, sizeof(TempStr));
	TrimString(TempStr);
	ExplodeString(TempStr, " ", Buffers, sizeof(Buffers), sizeof(Buffers[]));
	for (int j = 0; j < 3 ; j++)
	{
		TempI3[j] = StringToInt(Buffers[j]);
		TempI3[j] = CorrectInt(TempI3[j], 0, 255);
	}
	Format(SpriteWitchColors, sizeof(SpriteWitchColors), "%d %d %d", TempI3[0], TempI3[1], TempI3[2]);
}





// ====================================================================================================
// Game void
// ====================================================================================================

public void OnMapStart()
{
	PrecacheModel(SpriteCustomVMTPathString, true);
}

public void OnMapEnd()
{
	for (int i = MaxClients + 1; i <= 2048 ; i++)
		KillSprite(i);
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ReZero();
	RoundEnd = false;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	RoundEnd = true;
	OnMapEnd();
	ReZero();
}

public void Event_WitchSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	if (RoundEnd)
		return;

	int witch = event.GetInt("witchid");

	if (!IsWitch(witch))
		return;

	CreateTimer(0.3, CheckWitchAlive, witch, TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_WitchKilled(Event event, const char[] name, bool dontBroadcast)
{
	int witch = event.GetInt("witchid");

	if (!IsWitch(witch))
		return;

	KillSprite(witch);
}





// ====================================================================================================
// Game Action
// ====================================================================================================

public Action OnSetTransmit(int entity, int client)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	int cteam = GetClientTeam(client);
	
	if (cteam < 1 || cteam > 3)
		return Plugin_Handled;

	if (SpriteWitchTeamVisibility[cteam - 1])
		return Plugin_Continue;

	return Plugin_Handled;
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

public Action CheckWitchAlive(Handle timer, int witch)
{
	if (RoundEnd)
		return Plugin_Continue;

	if (IsWitch(witch) && GetEntProp(witch, Prop_Data, "m_iHealth") > 0)
	{
		OneWitchSpriteCheck(witch);
		CreateTimer(CheckInterval, WSC, witch, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public Action WSC(Handle timer, int witch)
{
	if (RoundEnd)
		return Plugin_Stop;

	if (!IsWitch(witch) || GetEntProp(witch, Prop_Data, "m_iHealth") <= 0)
	{
		KillSprite(witch);
		return Plugin_Stop;
	}

	OneWitchSpriteCheck(witch);
	return Plugin_Continue;
}





// ====================================================================================================
// void
// ====================================================================================================

public void OneWitchSpriteCheck(int witch)
{
	if (!IsWitch(witch))
	{
		KillSprite(witch);
		return;
	}

	int Witch_NowHP	= GetEntProp(witch, Prop_Data, "m_iHealth");

	if (Witch_NowHP <= 0)
	{
		KillSprite(witch);
		return;
	}

	char SpriteName[28];
	FormatEx(SpriteName, sizeof(SpriteName), "%s-%02i", "l4d2_witch_sprite", witch);

	int entity = INVALID_ENT_REFERENCE;

	if (SpriteEntityID[witch] != INVALID_ENT_REFERENCE)
		entity = EntRefToEntIndex(SpriteEntityID[witch]);

	if (entity == INVALID_ENT_REFERENCE)
	{
		float WitchPos[3];
		GetEntPropVector(witch, Prop_Send, "m_vecOrigin", WitchPos);
		WitchPos[2] += SpriteWitchHigh;

		entity = CreateEntityByName("env_sprite");
		SpriteEntityID[witch] = EntIndexToEntRef(entity);
		DispatchKeyValue(entity, "targetname", SpriteName);
		DispatchKeyValue(entity, "spawnflags", "1");
		DispatchKeyValueVector(entity, "origin", WitchPos);

		SDKHook(entity, SDKHook_SetTransmit, OnSetTransmit);
	}

	int colorAlpha[4];
	GetEntityRenderColor(witch, colorAlpha[0], colorAlpha[1], colorAlpha[2], colorAlpha[3]);

	char sAlpha[4];
	IntToString(RoundFloat(SpriteWitchAlpha * colorAlpha[3] / 255.0), sAlpha, sizeof(sAlpha));

	DispatchKeyValue(entity, "model", SpriteCustomVMTPathString);
	DispatchKeyValue(entity, "rendercolor", SpriteWitchColors);
	DispatchKeyValue(entity, "renderamt", sAlpha);
	DispatchKeyValue(entity, "renderfx", "0");
	DispatchKeyValue(entity, "scale", SpriteWitchScale);
	DispatchKeyValue(entity, "fademindist", "-1");
	DispatchSpawn(entity);

	SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", witch);
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", witch);
	AcceptEntityInput(entity, "ShowSprite");

	int entityFrame = INVALID_ENT_REFERENCE;

	if (SpriteFrameEntityID[witch] != INVALID_ENT_REFERENCE)
		entityFrame = EntRefToEntIndex(SpriteFrameEntityID[witch]);

	if (entityFrame == INVALID_ENT_REFERENCE)
	{
		entityFrame = CreateEntityByName("env_texturetoggle");
		SpriteFrameEntityID[witch] = EntIndexToEntRef(entityFrame);
		DispatchKeyValue(entityFrame, "targetname", SpriteName);
		DispatchKeyValue(entityFrame, "target", SpriteName);
		DispatchSpawn(entityFrame);

		SetVariantString("!activator");
		AcceptEntityInput(entityFrame, "SetParent", entity);
	}

	
	int Witch_MaxHP	= GetEntProp(witch, Prop_Data, "m_iMaxHealth");
	int frame		= Witch_NowHP * 100 / Witch_MaxHP;

	frame = CorrectInt(frame, 0, 100);

	char input[38];
	FormatEx(input, sizeof(input), "OnUser1 !self:SetTextureIndex:%i:0:1", frame);
	SetVariantString(input);
	AcceptEntityInput(entityFrame, "AddOutput");
	AcceptEntityInput(entityFrame, "FireUser1");
}

public void ReZero()
{
	for (int i = MaxClients + 1; i <= 2048 ; i++)
	{
		SpriteEntityID[i]		= INVALID_ENT_REFERENCE;
		SpriteFrameEntityID[i]	= INVALID_ENT_REFERENCE;
	}
}

public void KillSprite(int witch)
{
	if (SpriteEntityID[witch] != INVALID_ENT_REFERENCE)
	{
		int entity = EntRefToEntIndex(SpriteEntityID[witch]);

		if (entity != INVALID_ENT_REFERENCE)
			AcceptEntityInput(entity, "Kill");

		SpriteEntityID[witch] = INVALID_ENT_REFERENCE;
	}

	if (SpriteFrameEntityID[witch] != INVALID_ENT_REFERENCE)
	{
		int entityFrame = EntRefToEntIndex(SpriteFrameEntityID[witch]);

		if (entityFrame != INVALID_ENT_REFERENCE)
			AcceptEntityInput(entityFrame, "Kill");

		SpriteFrameEntityID[witch] = INVALID_ENT_REFERENCE;
	}
}





// ====================================================================================================
// int
// ====================================================================================================

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

public bool IsWitch(int entity)
{
	if (entity > MaxClients && IsValidEntity(entity))
	{
		static char classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		return (strcmp(classname, "witch", false) == 0);
	}
	return false;
}