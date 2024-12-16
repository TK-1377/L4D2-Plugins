#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS						FCVAR_NOTIFY

#define SpriteCustomVMTPathString		"mart/mart_custombar2.vmt"
#define SpriteCustomVTFPathString		"mart/mart_custombar2.vtf"	

int SpriteEntityID[32];
int SpriteFrameEntityID[32];
int EntityMyOwner[2049];

bool RoundEnd;

float CheckInterval = 0.2;
float SpriteInfectedHigh = 88.0;
float SpriteJockeyHigh = 72.0;
float SpriteHunterLungeHigh = 60.0;
int SpriteInfectedAlpha = 200;
char SpriteInfectedScale[5] = "0.60";
char SpriteInfectedColors[12] = "208 0 0";
int SpriteInfectedVisibility = 5;
bool SpriteInfectedTeamVisibility[3] = {true, false, true};

ConVar GCheckInterval;
ConVar GSpriteInfectedHigh;
ConVar GSpriteJockeyHigh;
ConVar GSpriteHunterLungeHigh;
ConVar GSpriteInfectedAlpha;
ConVar GSpriteInfectedScale;
ConVar GSpriteInfectedColors;
ConVar GSpriteInfectedVisibility;

Handle SpriteCheckTimer;

public void OnPluginStart()
{
	ReZero();

	GCheckInterval						=  CreateConVar("l4d2_special_infected_hp_sprite_check_interval",
														"0.2",
														"特感血量显示条计时器检查的时间间隔.",
														CVAR_FLAGS, true, 0.1);
	GSpriteInfectedHigh					=  CreateConVar("l4d2_special_infected_hp_sprite_high",
														"88.0",
														"特感血量显示条位于对应玩家的高度.",
														CVAR_FLAGS, true, 0.0);
	GSpriteJockeyHigh					=  CreateConVar("l4d2_special_infected_hp_sprite_high_jockey",
														"72.0",
														"Jockey血量显示条位于对应玩家的高度. (< 0.0 = 不单独配置高度)",
														CVAR_FLAGS, true, -1.0);
	GSpriteHunterLungeHigh				=  CreateConVar("l4d2_special_infected_hp_sprite_high_hunter_lunge",
														"60.0",
														"非站立Hunter血量显示条位于对应玩家的高度. (< 0.0 = 不单独配置高度)",
														CVAR_FLAGS, true, -1.0);
	GSpriteInfectedAlpha				=  CreateConVar("l4d2_special_infected_hp_sprite_alpha",
														"200",
														"特感血量显示条的可见度. (0 = 完全透明, 255 = 完全不透明)",
														CVAR_FLAGS, true, 0.0, true, 255.0);
	GSpriteInfectedScale				=  CreateConVar("l4d2_special_infected_hp_sprite_scale",
														"0.60",
														"特感血量显示条的大小.",
														CVAR_FLAGS, true, 0.01);
	GSpriteInfectedColors				=  CreateConVar("l4d2_special_infected_hp_sprite_colors",
														"208 0 0",
														"特感血量显示条的RGB.",
														CVAR_FLAGS);
	GSpriteInfectedVisibility			=  CreateConVar("l4d2_special_infected_hp_sprite_visibility",
														"5",
														"可以看见特感血量显示条的队伍. (1 = 旁观 2 = 生还 4 = 感染者)\n 将需要项相加",
														CVAR_FLAGS, true, 0.0, true, 7.0);

	GCheckInterval.AddChangeHook(ConVarChanged);
	GSpriteInfectedHigh.AddChangeHook(ConVarChanged);
	GSpriteJockeyHigh.AddChangeHook(ConVarChanged);
	GSpriteHunterLungeHigh.AddChangeHook(ConVarChanged);
	GSpriteInfectedAlpha.AddChangeHook(ConVarChanged);
	GSpriteInfectedScale.AddChangeHook(ConVarChanged);
	GSpriteInfectedColors.AddChangeHook(ConVarChanged);
	GSpriteInfectedVisibility.AddChangeHook(ConVarChanged);

	AddFileToDownloadsTable(SpriteCustomVMTPathString);
	AddFileToDownloadsTable(SpriteCustomVTFPathString);

	HookEvent("round_start",		Event_RoundStart,			EventHookMode_PostNoCopy);
	HookEvent("round_end",			Event_RoundEnd,				EventHookMode_PostNoCopy);
	HookEvent("player_spawn",		Event_PlayerSpawn);
	HookEvent("player_death",		Event_PlayerDeath);

	AutoExecConfig(true, "l4d2_special_infected_hp_sprite");
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
	SpriteInfectedHigh		= GSpriteInfectedHigh.FloatValue;
	SpriteJockeyHigh		= GSpriteJockeyHigh.FloatValue;
	SpriteHunterLungeHigh	= GSpriteHunterLungeHigh.FloatValue;
	SpriteInfectedAlpha		= GSpriteInfectedAlpha.IntValue;

	float fSpriteInfectedScale = GSpriteInfectedScale.FloatValue;
	FloatToString(fSpriteInfectedScale, SpriteInfectedScale, sizeof(SpriteInfectedScale));

	SpriteInfectedVisibility	= GSpriteInfectedVisibility.IntValue;

	if (SpriteInfectedVisibility >= 4)
	{
		SpriteInfectedTeamVisibility[2] = true;
		SpriteInfectedTeamVisibility[1] = SpriteInfectedVisibility >= 6 ? true : false;
	}
	else
	{
		SpriteInfectedTeamVisibility[2] = false;
		SpriteInfectedTeamVisibility[1] = SpriteInfectedVisibility >= 2 ? true : false;
	}
	SpriteInfectedTeamVisibility[0] = (SpriteInfectedVisibility % 2) == 1 ? true : false;

	char TempStr[12], Buffers[3][4];
	int TempI3[3];
	GSpriteInfectedColors.GetString(TempStr, sizeof(TempStr));
	TrimString(TempStr);
	ExplodeString(TempStr, " ", Buffers, sizeof(Buffers), sizeof(Buffers[]));
	for (int j = 0; j < 3 ; j++)
	{
		TempI3[j] = StringToInt(Buffers[j]);
		TempI3[j] = CorrectInt(TempI3[j], 0, 255);
	}
	Format(SpriteInfectedColors, sizeof(SpriteInfectedColors), "%d %d %d", TempI3[0], TempI3[1], TempI3[2]);

	DeleteSpriteTimer();
	if (IsHaveInfected())
		CreateSpriteTimer();
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
	for (int i = 1; i <= MaxClients ; i++)
		KillSprite(i);
	
	DeleteSpriteTimer();
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

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	if (RoundEnd)
		return;

	if (SpriteCheckTimer != null)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsInfected(client))
		return;

	int ZombieClass = GetEntProp(client, Prop_Send, "m_zombieClass");

	if (ZombieClass < 1 || ZombieClass > 6)
		return;

	CreateTimer(0.1, ToReadyToCreateSpriteTimer, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (RoundEnd)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsInfected(client))
		return;

	int ZombieClass = GetEntProp(client, Prop_Send, "m_zombieClass");

	if (ZombieClass < 1 || ZombieClass > 6)
		return;

	KillSprite(client);

	if (!IsHaveInfected())
		DeleteSpriteTimer();
}





// ====================================================================================================
// Game Action
// ====================================================================================================

public Action OnSetTransmit(int entity, int client)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	int own = EntityMyOwner[entity];

	if (own == client)
		return Plugin_Handled;

	if (!IsInfected(own) || !IsPlayerAlive(own))
		return Plugin_Handled;

	int ZombieClass = GetEntProp(own, Prop_Send, "m_zombieClass");

	if (ZombieClass < 1 || ZombieClass > 6)
		return Plugin_Handled;

	int cteam = GetClientTeam(client);
	
	if (cteam < 1 || cteam > 3)
		return Plugin_Handled;

	if (SpriteInfectedTeamVisibility[cteam - 1])
		return Plugin_Continue;

	return Plugin_Handled;
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

public Action ToReadyToCreateSpriteTimer(Handle timer)
{
	if (IsHaveInfected())
		CreateSpriteTimer();
	return Plugin_Continue;
}

public Action InfectedSpriteCheck(Handle timer, int client)
{
	EveryInfectedSpriteCheck();
	return Plugin_Continue;
}





// ====================================================================================================
// void
// ====================================================================================================

public void EveryInfectedSpriteCheck()
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
		{
			int ZombieClass = GetEntProp(i, Prop_Send, "m_zombieClass");

			if (ZombieClass >= 1 && ZombieClass <= 6)
			{
				char SpriteName[28];
				FormatEx(SpriteName, sizeof(SpriteName), "%s-%02i", "l4d2_infected_sprite", i);

				int entity = INVALID_ENT_REFERENCE;

				if (SpriteEntityID[i] != INVALID_ENT_REFERENCE)
					entity = EntRefToEntIndex(SpriteEntityID[i]);

				if (entity == INVALID_ENT_REFERENCE)
				{
					float InfectedPos[3];
					GetClientAbsOrigin(i, InfectedPos);
					InfectedPos[2] += (ZombieClass == 5 && SpriteJockeyHigh >= 0.0) ? SpriteJockeyHigh : SpriteInfectedHigh;

					entity = CreateEntityByName("env_sprite");
					SpriteEntityID[i] = EntIndexToEntRef(entity);
					EntityMyOwner[entity] = i;
					DispatchKeyValue(entity, "targetname", SpriteName);
					DispatchKeyValue(entity, "spawnflags", "1");
					DispatchKeyValueVector(entity, "origin", InfectedPos);

					SDKHook(entity, SDKHook_SetTransmit, OnSetTransmit);
				}

				if (ZombieClass == 3 && SpriteHunterLungeHigh >= 0.0)
				{
					float InfectedPos[3];
					GetClientAbsOrigin(i, InfectedPos);
					InfectedPos[2] += ((GetEntityFlags(i) & FL_ONGROUND) && !GetEntProp(i, Prop_Send, "m_bDucked")) ?
										SpriteInfectedHigh : SpriteHunterLungeHigh;
					DispatchKeyValueVector(entity, "origin", InfectedPos);
				}

				int colorAlpha[4];
				GetEntityRenderColor(i, colorAlpha[0], colorAlpha[1], colorAlpha[2], colorAlpha[3]);

				char sAlpha[4];
				IntToString(RoundFloat(SpriteInfectedAlpha * colorAlpha[3] / 255.0), sAlpha, sizeof(sAlpha));

				DispatchKeyValue(entity, "model", SpriteCustomVMTPathString);
				DispatchKeyValue(entity, "rendercolor", SpriteInfectedColors);
				DispatchKeyValue(entity, "renderamt", sAlpha);
				DispatchKeyValue(entity, "renderfx", "0");
				DispatchKeyValue(entity, "scale", SpriteInfectedScale);
				DispatchKeyValue(entity, "fademindist", "-1");
				DispatchSpawn(entity);

				SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", i);
				SetVariantString("!activator");
				AcceptEntityInput(entity, "SetParent", i);
				AcceptEntityInput(entity, "ShowSprite");

				int entityFrame = INVALID_ENT_REFERENCE;

				if (SpriteFrameEntityID[i] != INVALID_ENT_REFERENCE)
					entityFrame = EntRefToEntIndex(SpriteFrameEntityID[i]);

				if (entityFrame == INVALID_ENT_REFERENCE)
				{
					entityFrame = CreateEntityByName("env_texturetoggle");
					SpriteFrameEntityID[i] = EntIndexToEntRef(entityFrame);
					DispatchKeyValue(entityFrame, "targetname", SpriteName);
					DispatchKeyValue(entityFrame, "target", SpriteName);
					DispatchSpawn(entityFrame);

					SetVariantString("!activator");
					AcceptEntityInput(entityFrame, "SetParent", entity);
				}

				int Infected_NowHP	= GetClientHealth(i);
				int Infected_MaxHP	= GetEntProp(i, Prop_Data, "m_iMaxHealth");
				int frame			= Infected_NowHP * 100 / Infected_MaxHP;

				frame = CorrectInt(frame, 0, 100);

				char input[38];
				FormatEx(input, sizeof(input), "OnUser1 !self:SetTextureIndex:%i:0:1", frame);
				SetVariantString(input);
				AcceptEntityInput(entityFrame, "AddOutput");
				AcceptEntityInput(entityFrame, "FireUser1");
			}
			else
				KillSprite(i);
		}
		else
			KillSprite(i);
	}
}

public void ReZero()
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		SpriteEntityID[i]		= INVALID_ENT_REFERENCE;
		SpriteFrameEntityID[i]	= INVALID_ENT_REFERENCE;
	}
}

public void KillSprite(int client)
{
	if (SpriteEntityID[client] != INVALID_ENT_REFERENCE)
	{
		int entity = EntRefToEntIndex(SpriteEntityID[client]);

		if (entity != INVALID_ENT_REFERENCE)
			AcceptEntityInput(entity, "Kill");

		SpriteEntityID[client] = INVALID_ENT_REFERENCE;
	}

	if (SpriteFrameEntityID[client] != INVALID_ENT_REFERENCE)
	{
		int entityFrame = EntRefToEntIndex(SpriteFrameEntityID[client]);

		if (entityFrame != INVALID_ENT_REFERENCE)
			AcceptEntityInput(entityFrame, "Kill");

		SpriteFrameEntityID[client] = INVALID_ENT_REFERENCE;
	}
}

public void CreateSpriteTimer()
{
	if (SpriteCheckTimer == null)
		SpriteCheckTimer = CreateTimer(CheckInterval, InfectedSpriteCheck, _, TIMER_REPEAT);
}

public void DeleteSpriteTimer()
{
	if (SpriteCheckTimer != null)
		delete SpriteCheckTimer;
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

public bool IsHaveInfected()
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
		{
			int ZombieClass = GetEntProp(i, Prop_Send, "m_zombieClass");
			if (ZombieClass >= 1 && ZombieClass <= 6)
				return true;
		}
	}
	return false;
}

public bool IsInfected(int client)
{
	return (client > 0 &&
			client <= MaxClients &&
			IsClientInGame(client) &&
			GetClientTeam(client) == 3);
}