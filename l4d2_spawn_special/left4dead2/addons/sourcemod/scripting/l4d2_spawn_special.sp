#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define CVAR_FLAGS					FCVAR_NOTIFY

#define VOTE_NO						"no"
#define VOTE_YES					"yes"

#define NORMALPOSMULT				1.4
#define HIGHERPOS					300.0
#define HIGHERPOSADDDISTANCE		300.0
#define BaitDistance				200.0
#define NormalHighPoint				300.0

#define TRACE_RAY_FLAG 				MASK_SHOT | CONTENTS_MONSTERCLIP | CONTENTS_GRATE

#define GAMEDATA					"rygive"
#define NAME_CreateSmoker			"NextBotCreatePlayerBot<Smoker>"
#define NAME_CreateBoomer			"NextBotCreatePlayerBot<Boomer>"
#define NAME_CreateHunter			"NextBotCreatePlayerBot<Hunter>"
#define NAME_CreateSpitter			"NextBotCreatePlayerBot<Spitter>"
#define NAME_CreateJockey			"NextBotCreatePlayerBot<Jockey>"
#define NAME_CreateCharger			"NextBotCreatePlayerBot<Charger>"
#define NAME_CreateTank				"NextBotCreatePlayerBot<Tank>"

// Spawn Infected SDK
Handle SDK_CreateInfectedBot[6];
Address	StatsCondition;

char Infected_Name[6][10] =
{
	"Smoker",
	"Boomer",
	"Hunter",
	"Spitter",
	"Jockey",
	"Charger"
};

bool ProhibitTeleport = false;

bool CanStartSpawn = false;
bool IsInSpawnTime = false;
bool CanForceSpawn = false;
bool IsInSpawnCold = false;
bool IsInDeadSpawn = false;
bool IsTankToSpawn = false;
bool FreeMode = false;
float SpawnGameTime;
int SpawnSize_Record, OverloadDeadNumber, NormalDeadNumber;
Handle Infected_CheckTimer;
int FarFromTimer[32], NoInfectedAddTimer;
float HighestCeiling;

float SpawnTime = 16.0;
float FirstSpawnTime = 3.0;
int SILimit = 8, SpawnSize = 4;
int SpawnLimits[6] = {1, 1, 2, 1, 2, 1}, SpawnWeights[6] = {3, 2, 3, 2, 3, 3};
float InfectedPos_Record[32][3];
int InfectedTargetVictim[32];

int Infected_NumLimit_Temp, Infected_SpawnTimer_Temp;

int SpawnQuality = 0;
float SpawnAngleQuality = 5.0;
char SpawnQualityString[5][16] = {"Very Low", "Low", "Medium", "High", "Very High"};

int Spawn_Type1 = 1, Spawn_Type2 = 0;
bool Spawn_Type_Adaptive_Adjustment = true;
bool TankAlive_NoSpitter = true;
bool FirstSpawn_Trigger = true;
bool TankAlive_Trigger = true;
bool WaitSpawn_Trigger = true;
bool SpawnPush = true;
bool DeadClear = true;

float DefaultSpawnDistance = 250.0;
float DefaultTPSpawnDistance = 400.0;
float DefaultMaxSpawnDistance = 750.0;
float NearbySpawnDistance = 175.0;
float CantTPDistance = 250.0;
float ForceTPDistance = 1000.0;

ConVar Cvar_DefaultSpawnDistance;
ConVar Cvar_DefaultTPSpawnDistance;
ConVar Cvar_DefaultMaxSpawnDistance;
ConVar Cvar_NearbySpawnDistance;
ConVar Cvar_CantTPDistance;
ConVar Cvar_ForceTPDistance;
ConVar Cvar_Spawn_Type1, Cvar_Spawn_Type2;
ConVar Cvar_SpawnTime, Cvar_SILimit, Cvar_SpawnSize, Cvar_SpawnLimits, Cvar_SpawnWeights;
ConVar Cvar_FirstSpawnTime;
ConVar Cvar_SpawnAngleQuality;
ConVar Cvar_SpawnQuality;
ConVar Cvar_TankAlive_NoSpitter;
ConVar Cvar_Spawn_Type_Adaptive_Adjustment;
ConVar Cvar_FirstSpawn_Trigger, Cvar_TankAlive_Trigger, Cvar_WaitSpawn_Trigger;
ConVar Cvar_SpawnPush;
ConVar Cvar_ProhibitTeleport;
ConVar Cvar_DeadClear;

// Vote Menu
float Vote_Success_Percent = 0.51;
Menu Menu_Vote;
char votesmaps[MAX_NAME_LENGTH];
int ClientMenuType[32], ClientMenuItem[32];

char MapName[64];
Handle KeySIData;

// FirstSpawn Trigger
Handle FirstSpawn_PointCheckTimer;
bool TakeTheFirstSpawn = false;
float CenterPoint[3];
int TriggerType;
float TriggerDistance;
float MinTriggerDistance;
float MaxTriggerDistance;

// FirstSpawn Pos
float FToSpawnPos_Min[20][3];
float FToSpawnPos_Max[20][3];
int FToSpawnPos_Number;
int FToSpawnPos_Type[20];
int FSpawnRZI[6];
int FSpawnRCI[6][20];

// TankAlive Trigger
Handle TankAlive_LimitSpawnTimer;
float TankTriggerRange;
int Tank_DefaultHP;

// Wait Trigger
Handle WaitSpawn_PointCheckTimer;
float Wait_LimitPos[2][3];
float Wait_CenterPoint[3];
int Wait_TriggerType;
float Wait_TriggerDistance;

// Wait Trigger Data
float Wait_LimitPos_Min[10][3];
float Wait_LimitPos_Max[10][3];
int Wait_LimitPos_Number;
int Wait_TriggerType_Data[10];
float Wait_CenterPoint_Data[10][3];
float Wait_TriggerDistance_Min[10];
float Wait_TriggerDistance_Max[10];

// Spawn Type Pos Record
float SpawnPos_Record[32][3];
int SpawnPos_RecordNumber = 0;

// Spawn Type Change Data
float SurFlowData[256];
int SurFlowSTData[256][2];
int SurFlowDataNumber;
float SpawnPosLimit[2][3];
float SurFlowSpawnPos_Min[256][3];
float SurFlowSpawnPos_Max[256][3];

bool LateLoad;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	LateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	InitData();

	SetRandomSeed(GetSysTickCount());

	Cvar_DefaultSpawnDistance			=  CreateConVar("l4d2_ss_0_default_spawn_distance",
														"250.0",
														"默认最近刷特距离.",
														CVAR_FLAGS, true, 50.0, true, 1000.0);
	Cvar_DefaultTPSpawnDistance			=  CreateConVar("l4d2_ss_0_default_tp_spawn_distance",
														"400.0",
														"默认特感传送距离.",
														CVAR_FLAGS, true, 50.0, true, 1250.0);
	Cvar_DefaultMaxSpawnDistance		=  CreateConVar("l4d2_ss_0_default_max_spawn_distance",
														"750.0",
														"默认刷特最大距离.",
														CVAR_FLAGS, true, 500.0, true, 1250.0);
	Cvar_NearbySpawnDistance			=  CreateConVar("l4d2_ss_0_nearby_spawn_distance",
														"175.0",
														"特感分散生成的复活位间隔距离限制.",
														CVAR_FLAGS, true, 50.0, true, 350.0);
	Cvar_CantTPDistance					=  CreateConVar("l4d2_ss_0_cant_tp_distance",
														"250.0",
														"特感周围这个范围内有存活生还者时将禁止被传送.",
														CVAR_FLAGS, true, 1.0);
	Cvar_ForceTPDistance				=  CreateConVar("l4d2_ss_0_force_tp_distance",
														"1000.0",
														"特感距离所有存活生还者这个平面距离以上将可以被强制传送.",
														CVAR_FLAGS, true, 500.0);
	Cvar_Spawn_Type1					=  CreateConVar("l4d2_ss_1_spawn_type1",
														"1",
														"默认刷特方式.\n 0 = 无权重\n 1 = 靠近 \n 2 = 高处\n 3 = 前方\n 4 = 后方",
														CVAR_FLAGS, true, 0.0, true, 4.0);
	Cvar_Spawn_Type2					=  CreateConVar("l4d2_ss_1_spawn_type2",
														"0",
														"默认限制刷特.\n 0 = 无限制\n 1 = 禁止高处 \n 2 = 禁止低处",
														CVAR_FLAGS, true, 0.0, true, 2.0);
	Cvar_SpawnTime						=  CreateConVar("l4d2_ss_2_spawn_time",
														"16.0",
														"刷特时间.",
														CVAR_FLAGS, true, 1.0, true, 32.0);
	Cvar_SILimit						=  CreateConVar("l4d2_ss_2_si_limit",
														"8",
														"特感数量上限.",
														CVAR_FLAGS, true, 1.0, true, 8.0);
	Cvar_SpawnSize						=  CreateConVar("l4d2_ss_2_spawn_size",
														"4",
														"每波特感数量.",
														CVAR_FLAGS, true, 1.0, true, 8.0);
	Cvar_SpawnLimits					=  CreateConVar("l4d2_ss_2_spawn_limits",
														"1 1 2 1 2 1",
														"特感数量上限.(Smoker - Boomer - Hunter - Spitter - Jockey - Charger)",
														CVAR_FLAGS);
	Cvar_SpawnWeights					=  CreateConVar("l4d2_ss_2_spawn_weights",
														"3 2 3 2 3 3",
														"特感生成权重.(Smoker - Boomer - Hunter - Spitter - Jockey - Charger)",
														CVAR_FLAGS);
	Cvar_FirstSpawnTime					=  CreateConVar("l4d2_ss_first_spawn_time",
														"3.0",
														"第一波刷特时间. (自定义设定时无效)",
														CVAR_FLAGS, true, 0.1, true, 10.0);
	Cvar_SpawnAngleQuality				=  CreateConVar("l4d2_ss_3_spawn_angle_quality",
														"5.0",
														"刷特角度精度. (数值越小精度越高)",
														CVAR_FLAGS, true, 3.0, true, 36.0);
	Cvar_SpawnQuality					=  CreateConVar("l4d2_ss_3_spawn_quality",
														"0",
														"刷特质量.\n 0 = 最低\n 1 = 低\n 2 = 中\n 3 = 高\n 4 = 最高",
														CVAR_FLAGS, true, 0.0, true, 4.0);
	Cvar_TankAlive_NoSpitter			=  CreateConVar("l4d2_ss_5_tank_alive_no_spitter",
														"1",
														"启用有Tank存活时禁止生成Spitter. (0 = 启用, 1 = 禁用)",
														CVAR_FLAGS, true, 0.0, true, 1.0);
	Cvar_Spawn_Type_Adaptive_Adjustment	=  CreateConVar("l4d2_ss_1_spawn_type_adaptive_adjustment",
														"1",
														"刷特方式自适应调整. [需自定义]",
														CVAR_FLAGS, true, 0.0, true, 1.0);
	Cvar_FirstSpawn_Trigger				=  CreateConVar("l4d2_ss_4_first_spawn_trigger",
														"1",
														"启用第一波特感自定义触发与生成. [需自定义] (0 = 禁用, 1 = 启用)",
														CVAR_FLAGS, true, 0.0, true, 1.0);
	Cvar_TankAlive_Trigger				=  CreateConVar("l4d2_ss_4_tank_alive_trigger",
														"1",
														"启用Tank局特感延迟复活机制. (0 = 禁用, 1 = 启用)",
														CVAR_FLAGS, true, 0.0, true, 1.0);
	Cvar_WaitSpawn_Trigger				=  CreateConVar("l4d2_ss_4_wait_spawn_trigger",
														"1",
														"启用自定义特殊事件等待触发生成机制. [需自定义] (0 = 禁用, 1 = 启用)",
														CVAR_FLAGS, true, 0.0, true, 1.0);
	Cvar_SpawnPush						=  CreateConVar("l4d2_ss_5_spawn_push",
														"1",
														"启用Boomer、Jockey与Charger高处复活时的速度. (0 = 禁用, 1 = 启用)",
														CVAR_FLAGS, true, 0.0, true, 1.0);
	Cvar_ProhibitTeleport				=  CreateConVar("l4d2_ss_5_prohibit_teleport",
														"0",
														"禁止特感传送. (0 = 启用传送, 1 = 禁用传送)",
														CVAR_FLAGS, true, 0.0, true, 1.0);
	Cvar_DeadClear						=  CreateConVar("l4d2_ss_5_dead_clear",
														"1",
														"启用踢出死亡的特感Bot. (0 = 禁用, 1 = 启用)",
														CVAR_FLAGS, true, 0.0, true, 1.0);

	Cvar_DefaultSpawnDistance.AddChangeHook(ConVarChanged);
	Cvar_DefaultTPSpawnDistance.AddChangeHook(ConVarChanged);
	Cvar_DefaultMaxSpawnDistance.AddChangeHook(ConVarChanged);
	Cvar_NearbySpawnDistance.AddChangeHook(ConVarChanged);
	Cvar_CantTPDistance.AddChangeHook(ConVarChanged);
	Cvar_ForceTPDistance.AddChangeHook(ConVarChanged);
	Cvar_Spawn_Type1.AddChangeHook(ConVarChanged);
	Cvar_Spawn_Type2.AddChangeHook(ConVarChanged);
	Cvar_SpawnTime.AddChangeHook(ConVarChanged);
	Cvar_SILimit.AddChangeHook(ConVarChanged);
	Cvar_SpawnSize.AddChangeHook(ConVarChanged);
	Cvar_SpawnLimits.AddChangeHook(ConVarChanged);
	Cvar_SpawnWeights.AddChangeHook(ConVarChanged);
	Cvar_FirstSpawnTime.AddChangeHook(ConVarChanged);
	Cvar_SpawnAngleQuality.AddChangeHook(ConVarChanged);
	Cvar_SpawnQuality.AddChangeHook(ConVarChanged);
	Cvar_TankAlive_NoSpitter.AddChangeHook(ConVarChanged);
	Cvar_Spawn_Type_Adaptive_Adjustment.AddChangeHook(ConVarChanged);
	Cvar_FirstSpawn_Trigger.AddChangeHook(ConVarChanged);
	Cvar_TankAlive_Trigger.AddChangeHook(ConVarChanged);
	Cvar_WaitSpawn_Trigger.AddChangeHook(ConVarChanged);
	Cvar_SpawnPush.AddChangeHook(ConVarChanged);
	Cvar_ProhibitTeleport.AddChangeHook(ConVarChanged);
	Cvar_DeadClear.AddChangeHook(ConVarChanged);

	HookEvent("round_start",			Event_RoundStart,			EventHookMode_PostNoCopy);
	HookEvent("round_end",				Event_RoundEnd,				EventHookMode_PostNoCopy);
	HookEvent("player_spawn",			Event_PlayerSpawn);
	HookEvent("player_death",			Event_PlayerDeath);

	RegConsoleCmd("sm_vote",			Command_Votes,				"玩家投票菜单.");
	RegConsoleCmd("sm_freemode",		Command_FreeMode,			"自由模式.");
	RegConsoleCmd("sm_notp",			Command_No_Teleport,		"开启/关闭 特感传送.");
	RegConsoleCmd("sm_spawntype",		Command_Spawn_Type,			"改变刷特方式.");
	RegConsoleCmd("sm_spawnquality",	Command_Spawn_Quality,		"改变刷特精度.");
	RegConsoleCmd("sm_xx",				Command_Mode_Look,			"查看游戏模式.");

	if (LateLoad && L4D_HasAnySurvivorLeftSafeArea())
		L4D_OnFirstSurvivorLeftSafeArea_Post(0);

	SI_KV_Load();
	AutoExecConfig(true, "l4d2_spawn_special");
}

public void OnPluginEnd()
{
	TweakSettings(true);
	SI_KV_Close();
	OnMapEnd();
}

public void TweakSettings(bool restore)
{
	if (!restore)
	{
		FindConVar("z_max_player_zombies").SetBounds(ConVarBound_Upper, true, float(MaxClients));
		FindConVar("z_max_player_zombies").SetFloat(float(MaxClients));
		FindConVar("z_minion_limit").SetInt(MaxClients);
		FindConVar("survival_max_specials").SetInt(MaxClients);

		FindConVar("z_smoker_limit").SetInt(0);
		FindConVar("z_boomer_limit").SetInt(0);
		FindConVar("z_hunter_limit").SetInt(0);
		FindConVar("z_spitter_limit").SetInt(0);
		FindConVar("z_jockey_limit").SetInt(0);
		FindConVar("z_charger_limit").SetInt(0);

		FindConVar("survival_max_smokers").SetInt(0);
		FindConVar("survival_max_boomers").SetInt(0);
		FindConVar("survival_max_hunters").SetInt(0);
		FindConVar("survival_max_spitters").SetInt(0);
		FindConVar("survival_max_jockeys").SetInt(0);
		FindConVar("survival_max_chargers").SetInt(0);

		FindConVar("z_spawn_range").SetInt(800);
		FindConVar("z_discard_range").SetInt(3000);
		FindConVar("z_safe_spawn_range").SetInt(200);
		FindConVar("z_spawn_safety_range").SetInt(200);
	}
	else
	{
		FindConVar("z_minion_limit").RestoreDefault();
		FindConVar("survival_max_specials").RestoreDefault();

		FindConVar("z_smoker_limit").RestoreDefault();
		FindConVar("z_boomer_limit").RestoreDefault();
		FindConVar("z_hunter_limit").RestoreDefault();
		FindConVar("z_spitter_limit").RestoreDefault();
		FindConVar("z_jockey_limit").RestoreDefault();
		FindConVar("z_charger_limit").RestoreDefault();

		FindConVar("survival_max_smokers").RestoreDefault();
		FindConVar("survival_max_boomers").RestoreDefault();
		FindConVar("survival_max_hunters").RestoreDefault();
		FindConVar("survival_max_spitters").RestoreDefault();
		FindConVar("survival_max_jockeys").RestoreDefault();
		FindConVar("survival_max_chargers").RestoreDefault();

		FindConVar("z_spawn_range").RestoreDefault();
		FindConVar("z_discard_range").RestoreDefault();
		FindConVar("z_safe_spawn_range").RestoreDefault();
		FindConVar("z_spawn_safety_range").RestoreDefault();
	}
}

public void OnConfigsExecuted()
{
	TweakSettings(false);
	Vote_End_Config();
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

public void GetCvars()
{
	DefaultSpawnDistance					= Cvar_DefaultSpawnDistance.FloatValue;
	DefaultTPSpawnDistance					= Cvar_DefaultTPSpawnDistance.FloatValue;
	DefaultMaxSpawnDistance					= Cvar_DefaultMaxSpawnDistance.FloatValue;
	NearbySpawnDistance						= Cvar_NearbySpawnDistance.FloatValue;
	CantTPDistance							= Cvar_CantTPDistance.FloatValue;
	ForceTPDistance							= Cvar_ForceTPDistance.FloatValue;

	if (DefaultMaxSpawnDistance < DefaultSpawnDistance + 250.0)
		DefaultMaxSpawnDistance = DefaultSpawnDistance + 250.0;
	if (DefaultMaxSpawnDistance < DefaultTPSpawnDistance + 250.0)
		DefaultMaxSpawnDistance = DefaultTPSpawnDistance + 250.0;

	FirstSpawnTime							= Cvar_FirstSpawnTime.FloatValue;
	Spawn_Type1								= Cvar_Spawn_Type1.IntValue;
	Spawn_Type2								= Cvar_Spawn_Type2.IntValue;
	SpawnTime								= Cvar_SpawnTime.FloatValue;
	SILimit									= Cvar_SILimit.IntValue;
	SpawnSize								= Cvar_SpawnSize.IntValue;
	TankAlive_NoSpitter						= Cvar_TankAlive_NoSpitter.BoolValue;
	Spawn_Type_Adaptive_Adjustment			= Cvar_Spawn_Type_Adaptive_Adjustment.BoolValue;
	FirstSpawn_Trigger						= Cvar_FirstSpawn_Trigger.BoolValue;
	TankAlive_Trigger						= Cvar_TankAlive_Trigger.BoolValue;
	WaitSpawn_Trigger						= Cvar_WaitSpawn_Trigger.BoolValue;
	SpawnPush								= Cvar_SpawnPush.BoolValue;
	SpawnAngleQuality						= Cvar_SpawnAngleQuality.FloatValue;
	SpawnQuality							= Cvar_SpawnQuality.IntValue;
	ProhibitTeleport						= Cvar_ProhibitTeleport.BoolValue;
	DeadClear								= Cvar_DeadClear.BoolValue;

	int TempI;
	char TempString[24], Buffers[6][4];
	Cvar_SpawnLimits.GetString(TempString, sizeof(TempString));
	ExplodeString(TempString, " ", Buffers, sizeof(Buffers), sizeof(Buffers[]));
	for (int i = 0; i < 6 ; i++)
	{
		TempI = StringToInt(Buffers[i]);
		if (TempI >= 0)
			SpawnLimits[i] = TempI;
	}
	Cvar_SpawnWeights.GetString(TempString, sizeof(TempString));
	ExplodeString(TempString, " ", Buffers, sizeof(Buffers), sizeof(Buffers[]));
	for (int i = 0; i < 6 ; i++)
	{
		TempI = StringToInt(Buffers[i]);
		if (TempI >= 0)
			SpawnWeights[i] = TempI;
	}
}





// ====================================================================================================
// Game void
// ====================================================================================================

// 离开安全区
public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client)
{
	RemoveInfectedClips();

	if (CanStartSpawn)
		return;
	
	CanStartSpawn = true;
	ClearAllTimer();

	Spawn_Type1 = Cvar_Spawn_Type1.IntValue;
	Spawn_Type2 = Cvar_Spawn_Type2.IntValue;

	if (FirstSpawn_Trigger && TakeTheFirstSpawn)
	{
		TriggerDistance = GetRandomFloat(MinTriggerDistance, MaxTriggerDistance);
		FirstSpawn_PointCheckTimer = CreateTimer(0.1, ReadyToFirstSpawn, _, TIMER_REPEAT);
	}
	else
		CreateTimer(FirstSpawnTime, StartSpawn, _, TIMER_FLAG_NO_MAPCHANGE);

	Infected_CheckTimer = CreateTimer(1.0, Check_Infected, _, TIMER_REPEAT);
}

// 地图开始
public void OnMapStart()
{
	GetCurrentMap(MapName, sizeof(MapName));
	SI_KV_UpdateModeSpawnInfo();
}

// 地图结束
public void OnMapEnd()
{
	CanStartSpawn = false;
	KvRewind(KeySIData);
	ClearAllTimer();
}





// ====================================================================================================
// Config
// ====================================================================================================

public void SI_KV_Load()
{
	char NameBuff[PLATFORM_MAX_PATH];

	KeySIData = CreateKeyValues("Mode_Spawn");
	BuildPath(Path_SM, NameBuff, sizeof(NameBuff), "configs/mode_spawn.txt");

	if (!FileToKeyValues(KeySIData, NameBuff))
	{
		LogError("[SI] Couldn't mode spawn data!");
		SI_KV_Close();
		return;
	}
}

public void SI_KV_Close()
{
	if (KeySIData == INVALID_HANDLE)
		return;

	CloseHandle(KeySIData);
	KeySIData = INVALID_HANDLE;
}

public void SI_KV_UpdateModeSpawnInfo()
{
	if (KeySIData == INVALID_HANDLE)
	{
		LogError("[SI] No mobinfo keyvalues loaded!");
		return;
	}

	TakeTheFirstSpawn = false;
	CenterPoint = NULL_VECTOR;
	TriggerType = 0;
	MinTriggerDistance = 0.0;
	MaxTriggerDistance = 0.0;

	FToSpawnPos_Number = 0;
	for (int i = 0; i < 6 ; i++)
	{
		FSpawnRZI[i] = 0;
		for (int j = 0; j < 20 ; j++)
			FSpawnRCI[i][j] = 0;
	}
	for (int i = 0; i < 20 ; i++)
	{
		FToSpawnPos_Min[i] = NULL_VECTOR;
		FToSpawnPos_Max[i] = NULL_VECTOR;
		FToSpawnPos_Type[i] = 0;
	}

	Wait_LimitPos_Number = 0;
	for (int i = 0; i < 10 ; i++)
	{
		Wait_CenterPoint_Data[i] = NULL_VECTOR;
		Wait_LimitPos_Min[i] = NULL_VECTOR;
		Wait_LimitPos_Max[i] = NULL_VECTOR;
		Wait_TriggerType_Data[i] = 0;
		Wait_TriggerDistance_Min[i] = 0.0;
		Wait_TriggerDistance_Max[i] = 0.0;
	}

	for (int i = 0; i < 256 ; i++)
	{
		SurFlowData[i] = 0.0;
		SurFlowSpawnPos_Min[i] = NULL_VECTOR;
		SurFlowSpawnPos_Max[i] = NULL_VECTOR;
	}
	SurFlowDataNumber = 0;

	if (KvJumpToKey(KeySIData, MapName))
	{
		KvGetVector(KeySIData, "center_point", CenterPoint, NULL_VECTOR);
		MinTriggerDistance = KvGetFloat(KeySIData, "min_trigger", 0.0);
		MaxTriggerDistance = KvGetFloat(KeySIData, "max_trigger", 0.0);
		TriggerType = KvGetNum(KeySIData, "trigger_type", 0);
		
		if ((CenterPoint[0] != 0.0 || CenterPoint[1] != 0.0 || CenterPoint[2] != 0.0) &&
			MinTriggerDistance > 0.0 &&
			MaxTriggerDistance > MinTriggerDistance &&
			TriggerType >= 0 &&
			TriggerType <= 6)
		{
			TakeTheFirstSpawn = true;
		}
		
		char SearchString[24];

		for (int i = 0; i < 20 ; i++)
		{
			Format(SearchString, sizeof(SearchString), "fs_type_%d", i + 1);
			FToSpawnPos_Type[i] = KvGetNum(KeySIData, SearchString, 0);

			if (FToSpawnPos_Type[i] < 0 || FToSpawnPos_Type[i] > 7)
				break;

			Format(SearchString, sizeof(SearchString), "fs_minpos_%d", i + 1);
			KvGetVector(KeySIData, SearchString, FToSpawnPos_Min[i], NULL_VECTOR);
			Format(SearchString, sizeof(SearchString), "fs_maxpos_%d", i + 1);
			KvGetVector(KeySIData, SearchString, FToSpawnPos_Max[i], NULL_VECTOR);

			if ((FToSpawnPos_Min[i][0] == 0.0 &&
				FToSpawnPos_Min[i][1] == 0.0 &&
				FToSpawnPos_Min[i][2] == 0.0) ||
				(FToSpawnPos_Type[i] > 0 &&
				FToSpawnPos_Max[i][0] == 0.0 &&
				FToSpawnPos_Max[i][1] == 0.0 &&
				FToSpawnPos_Max[i][2] == 0.0))
			{
				break;
			}

			FToSpawnPos_Number ++;

			char Get_String[24], Buffers[6][4];
			Format(SearchString, sizeof(SearchString), "fs_select_%d", i + 1);
			KvGetString(KeySIData, SearchString, Get_String, sizeof(Get_String), NULL_STRING);

			if (strlen(Get_String) < 11)
				break;

			ExplodeString(Get_String, " ", Buffers, sizeof(Buffers), sizeof(Buffers[]));
			for (int j = 0; j < 6 ; j++)
			{
				int TempI = StringToInt(Buffers[j]);
				if (TempI < 0)
					continue;

				FSpawnRZI[j] += TempI;
				FSpawnRCI[j][i] = TempI;
			}
		}

		for (int i = 0; i < 10 ; i++)
		{
			Format(SearchString, sizeof(SearchString), "ws_cpoint_%d", i + 1);
			KvGetVector(KeySIData, SearchString, Wait_CenterPoint_Data[i], NULL_VECTOR);

			if (Wait_CenterPoint_Data[i][0] == 0.0 &&
				Wait_CenterPoint_Data[i][1] == 0.0 &&
				Wait_CenterPoint_Data[i][2] == 0.0)
			{
				break;
			}

			Format(SearchString, sizeof(SearchString), "wl_minpos_%d", i + 1);
			KvGetVector(KeySIData, SearchString, Wait_LimitPos_Min[i], NULL_VECTOR);
			Format(SearchString, sizeof(SearchString), "wl_maxpos_%d", i + 1);
			KvGetVector(KeySIData, SearchString, Wait_LimitPos_Max[i], NULL_VECTOR);

			if ((Wait_LimitPos_Min[i][0] == 0.0 &&
				Wait_LimitPos_Min[i][1] == 0.0 &&
				Wait_LimitPos_Min[i][2] == 0.0) ||
				(Wait_LimitPos_Max[i][0] == 0.0 &&
				Wait_LimitPos_Max[i][1] == 0.0 &&
				Wait_LimitPos_Max[i][2] == 0.0))
			{
				break;
			}

			Format(SearchString, sizeof(SearchString), "ws_trtype_%d", i + 1);
			Wait_TriggerType_Data[i] = KvGetNum(KeySIData, SearchString, 0);

			if (Wait_TriggerType_Data[i] < 0 || Wait_TriggerType_Data[i] > 6)
				break;

			Format(SearchString, sizeof(SearchString), "ws_mintrdist_%d", i + 1);
			Wait_TriggerDistance_Min[i] = KvGetFloat(KeySIData, SearchString, 0.0);
			Format(SearchString, sizeof(SearchString), "ws_maxtrdist_%d", i + 1);
			Wait_TriggerDistance_Max[i] = KvGetFloat(KeySIData, SearchString, 0.0);
			
			if (Wait_TriggerDistance_Min[i] <= 0.0 || Wait_TriggerDistance_Min[i] >= Wait_TriggerDistance_Max[i])
				break;
			
			Wait_LimitPos_Number ++;
		}

		for (int i = 0; i < 256 ; i++)
		{
			Format(SearchString, sizeof(SearchString), "sur_flow_%d", i + 1);
			SurFlowData[i] = KvGetFloat(KeySIData, SearchString, SurFlowData[i]);

			if (SurFlowData[i] <= 0.0)
				break;
			else
			{
				Format(SearchString, sizeof(SearchString), "spawn_type1_%d", i + 1);
				SurFlowSTData[i][0] = KvGetNum(KeySIData, SearchString, SurFlowSTData[i][0]);
				Format(SearchString, sizeof(SearchString), "spawn_type2_%d", i + 1);
				SurFlowSTData[i][1] = KvGetNum(KeySIData, SearchString, SurFlowSTData[i][1]);
				Format(SearchString, sizeof(SearchString), "limit_pos_min_%d", i + 1);
				KvGetVector(KeySIData, SearchString, SurFlowSpawnPos_Min[i]);
				Format(SearchString, sizeof(SearchString), "limit_pos_max_%d", i + 1);
				KvGetVector(KeySIData, SearchString, SurFlowSpawnPos_Max[i]);
				SurFlowDataNumber ++;
			}
		}
	}
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

// 回合开始
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	IsInSpawnTime = false;
	CanForceSpawn = false;
	IsInSpawnCold = false;
	IsInDeadSpawn = false;
	IsTankToSpawn = false;
	SpawnGameTime = 0.0;

	for (int i = 1; i <= MaxClients ; i++)
	{
		InfectedTargetVictim[i] = 0;
		FarFromTimer[i] = 0;
		InfectedPos_Record[i] = NULL_VECTOR;
	}
}

// 回合结束
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	OnMapEnd();
}

// 玩家复活
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (FreeMode) // 自由模式不控制特感生成
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!CIsInfected(client))
		return;

	int ZombieClass = GetEntProp(client, Prop_Send, "m_zombieClass");

	if (TankAlive_Trigger && ZombieClass == 8 && IsFakeClient(client))
		CreateTimer(3.0, CheckTankAlive, client, TIMER_FLAG_NO_MAPCHANGE);

	if (ZombieClass < 1 || ZombieClass > 6) // 不控制Tank生成
		return;

	if (IsFakeClient(client))
	{
		// 禁止刷特数量超过上限、非刷特模式下刷特和导演刷特
		if (GetInfectedBotNum(0) > SILimit || SpawnTime > 60.0 || (!IsInSpawnTime && !CanForceSpawn))
		{
			KickClient(client);
			return;
		}
		
		if (SpawnSize <= 0 ||
			GetInfectedBotNum(ZombieClass) > SpawnLimits[ZombieClass - 1] ||
			SpawnWeights[ZombieClass - 1] <= 0) // 禁止被限制、数量达到上限和无权重的特感生成
		{
			KickClient(client);
			return;
		}
	}

	FarFromTimer[client] = -3;
	GetClientAbsOrigin(client, InfectedPos_Record[client]);
	BypassAndExecuteCommand("nb_assault");

	if (!SpawnPush)
		return;

	if (!IsFakeClient(client)) // 不为玩家特感设置复活速度
		return;

	if (ZombieClass == 1 || ZombieClass == 3 || ZombieClass == 4) // 不为Smoker、Hunter和Spitter设置空降复活速度
		return;

	int victim = InfectedTargetVictim[client];

	if (!CIsSurvivor(victim) || !IsPlayerAlive(victim)) // Target无效, 获取最近的生还者
		victim = GetNearestSurvivor(client);

	if (victim == 0) // Target无效
		return;

	float TargetPos[3];
	GetClientAbsOrigin(victim, TargetPos);

	if (InfectedPos_Record[client][2] - TargetPos[2] <= 218.0) // 高度过低, 不设置复活速度
		return;

	float ToSpawnSpeed[3] = {0.0, 0.0, 80.0};
	float JumpPos[3];

	for (int i = 0; i < 3 ; i++)
		JumpPos[i] = InfectedPos_Record[client][i];

	JumpPos[2] += ZombieClass == 5 ? 50.0 : 75.0;

	for (int i = 0; i < 2 ; i++)
	{
		ToSpawnSpeed[i] = (TargetPos[i] - InfectedPos_Record[client][i]); // 瞄准生还者
		if (ZombieClass != 5) // 非Jockey时, 复活速度需要更快
			ToSpawnSpeed[i] *= 1.3;
		ToSpawnSpeed[i] = GetCorrectFloat(ToSpawnSpeed[i], -350.0, 350.0); // 设置速度上限值
	}

	TeleportEntity(client, JumpPos, NULL_VECTOR, ToSpawnSpeed);
}

// 玩家死亡
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (FreeMode)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!CIsInfected(client))
		return;
	
	InfectedTargetVictim[client] = 0;

	if (SpawnTime > 60.0)
		return;

	int ZombieClass = GetEntProp(client, Prop_Send, "m_zombieClass");

	if (ZombieClass < 1 || ZombieClass > 6)
		return;

	if (IsInSpawnTime)
	{
		OverloadDeadNumber ++;
		NormalDeadNumber ++;
	}
	else
		NormalDeadChange(client, ZombieClass, false);

	FarFromTimer[client] = 0;
}





// ====================================================================================================
// Command Action
// ====================================================================================================

public Action Command_Votes(int client, int args)
{
	if (!CIsInGameClient(client) || IsFakeClient(client))
		return Plugin_Handled;
	
	if (GetClientTeam(client) == 1)
	{
		PrintToChat(client, "\x04[ERROR] \x03观战者无法进行此项投票.");
		return Plugin_Handled;
	}

	Show_MainMenu(client);
	return Plugin_Handled;
}

// 查看当前特感模式
public Action Command_Mode_Look(int client, int args)
{
	if (!CIsInGameClient(client) || IsFakeClient(client))
		return Plugin_Handled;

	PrintToChat(client, "\x04特感上限 : \x03%d", SILimit);
	PrintToChat(client, "\x04每波特感 : \x03%d", SpawnSize);
	PrintToChat(client, "\x04复活时间 : \x03%.0fs", SpawnTime);
	PrintToChat(client, "\x04特感复活距离 : \x03%.0f \x01 - \x03%.0f", DefaultSpawnDistance, DefaultMaxSpawnDistance);
	PrintToChat(client, "\x04特感传送距离 : \x03%.0f", DefaultTPSpawnDistance);
	return Plugin_Handled;
}

// Free Mode
public Action Command_FreeMode(int client, int args)
{
	if (!CIsInGameClient(client) || IsFakeClient(client))
		return Plugin_Handled;
	
	if (!IsAdministrators(client))
	{
		PrintToChat(client, "\x04[ERROR] \x03You are not allowed to use this command.");
		return Plugin_Handled;
	}

	FreeMode = !FreeMode;
	PrintToChat(client, "\x05[Mode Spawn] \x04Free Mode : \x03%s", FreeMode ? "ON" : "OFF");
	return Plugin_Handled;
}

// No Teleport
public Action Command_No_Teleport(int client, int args)
{
	if (!CIsInGameClient(client) || IsFakeClient(client))
		return Plugin_Handled;
	
	if (!IsAdministrators(client))
	{
		PrintToChat(client, "\x04[ERROR] \x03You are not allowed to use this command.");
		return Plugin_Handled;
	}

	ProhibitTeleport = !ProhibitTeleport;
	PrintToChat(client, "\x05[Mode Spawn] \x04Prohibit Teleport : \x03%s", ProhibitTeleport ? "ON" : "OFF");
	return Plugin_Handled;
}

// Spawn Type
public Action Command_Spawn_Type(int client, int args)
{
	if (!CIsInGameClient(client) || IsFakeClient(client) || args < 2)
		return Plugin_Handled;
	
	if (!IsAdministrators(client))
	{
		PrintToChat(client, "\x04[ERROR] \x03You are not allowed to use this command.");
		return Plugin_Handled;
	}

	int new_spawntype1 = GetCmdArgInt(1);
	int new_spawntype2 = GetCmdArgInt(2);

	if (new_spawntype1 < 0 || new_spawntype1 > 4)
		return Plugin_Handled;
	
	if (new_spawntype2 < 0 || new_spawntype2 > 2)
		return Plugin_Handled;

	static char SpawnType1Name[5][12] =
	{
		"Null",			// 无权重
		"Near",			// 靠近
		"Height",		// 高点
		"Front",		// 前方
		"Rear"			// 后方
	};

	static char SpawnType2Name[3][12] =
	{
		"Null",			// 无限制
		"NoHeight",		// 禁止高处
		"NoLow"			// 禁止低处
	};

	Spawn_Type1 = new_spawntype1;
	Spawn_Type2 = new_spawntype2;
	PrintToChat(client, "\x05[Mode Spawn] \x04Spawn Type Priority : \x03%s %s",
				SpawnType1Name[Spawn_Type1], SpawnType2Name[Spawn_Type2]);
	return Plugin_Handled;
}

// Spawn Quantity
public Action Command_Spawn_Quality(int client, int args)
{
	if (!CIsInGameClient(client) || IsFakeClient(client) || args < 1)
		return Plugin_Handled;
	
	if (!IsAdministrators(client))
	{
		PrintToChat(client, "\x04[ERROR] \x03You are not allowed to use this command.");
		return Plugin_Handled;
	}

	int new_spawnquantity = GetCmdArgInt(1);

	if (new_spawnquantity < 0 || new_spawnquantity > 4)
		return Plugin_Handled;

	SpawnQuality = new_spawnquantity;
	PrintToChat(client, "\x05[Mode Spawn] \x04Spawn Quantity : \x03%s", SpawnQualityString[SpawnQuality]);
	return Plugin_Handled;
}





// ====================================================================================================
// Show Menu
// ====================================================================================================

public void Show_MainMenu(int client)
{
	Handle menu = CreatePanel();
	DrawPanelItem(menu, "更改特感数量");
	DrawPanelItem(menu, "更改特感复活时间");
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Vote_MainMenu, 15);
}

public void Show_NumberLimitMenu(int client)
{
	Handle menu = CreatePanel();
	SetPanelTitle(menu, "更改特感数量");
	DrawPanelItem(menu, "1");
	DrawPanelItem(menu, "2");
	DrawPanelItem(menu, "3");
	DrawPanelItem(menu, "4");
	DrawPanelItem(menu, "5");
	DrawPanelItem(menu, "6");
	DrawPanelItem(menu, "7");
	DrawPanelItem(menu, "8");
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	SendPanelToClient(menu, client, Vote_NumberLimitMenu, 15);
}

public void Show_SpawnTimeMenu(int client, int type)
{
	static char SpawnTimeString[32][4] =
	{
		"1s", "2s", "3s", "4s", "5s", "6s", "7s", "8s", "9s", "10s", "11s",
		"12s", "13s", "14s", "15s", "16s", "17s", "18s", "19s", "20s", "21s",
		"22s", "23s", "24s", "25s", "26s", "27s", "28s", "29s", "30s", "31s", "32s"
	};

	static int start_type[5] = {0, 7, 13, 19, 25};
	static int end_type[5] = {6, 12, 18, 24, 31};

	Handle menu = CreatePanel();
	SetPanelTitle(menu, "更改特感复活时间");
	for (int i = start_type[type]; i <= end_type[type]; i++)
		DrawPanelItem(menu, SpawnTimeString[i]);
	DrawPanelText(menu, " \n");
	if (type > 0)
		DrawPanelItem(menu, "上一页");
	if (type < 4)
		DrawPanelItem(menu, "下一页");
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	ClientMenuType[client] = type;
	ClientMenuItem[client] = end_type[type] - start_type[type] + 1;
	SendPanelToClient(menu, client, Vote_SpawnTimeMenu, 15);
}





// ====================================================================================================
// Menu
// ====================================================================================================

// 主投票菜单
public int Vote_MainMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (itemNum)
			{
				case 1: 
					Show_NumberLimitMenu(client);
				case 2: 
					Show_SpawnTimeMenu(client, 0);
			}
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

// 特感数量限制投票
public int Vote_NumberLimitMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum <= 8)
			{
				Infected_NumLimit_Temp		= itemNum;
				Infected_SpawnTimer_Temp	= 0;
				Vote_CMode_Menu(client);
			}
			else if (itemNum == 9)
				Show_MainMenu(client);
			else
				delete menu;
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

// 特感复活时间菜单
public int Vote_SpawnTimeMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	static int start_item[5] = {0, 7, 13, 19, 25};

	switch (action)
	{
		case MenuAction_Select:
		{
			if (itemNum <= ClientMenuItem[client])
			{
				Infected_NumLimit_Temp		= 0;
				Infected_SpawnTimer_Temp	= start_item[ClientMenuType[client]] + itemNum;
				Vote_CMode_Menu(client);
			}
			else if (ClientMenuType[client] == 4 && itemNum == 8)
				Show_SpawnTimeMenu(client, ClientMenuType[client] - 1);
			else if (ClientMenuType[client] > 0 && itemNum == 7)
				Show_SpawnTimeMenu(client, ClientMenuType[client] - 1);
			else if (ClientMenuType[client] < 4 && itemNum == 8)
				Show_SpawnTimeMenu(client, ClientMenuType[client] + 1);
			else if (itemNum == 9)
				Show_MainMenu(client);
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

// 投票内容显示与发送
public void Vote_CMode_Menu(int client)
{
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "\x04[提示]\x05已有投票在进行中.");
		return;
	}

	if (GetClientNumber(2, false, true) <= 1)
	{
		Vote_End_Config();
		return;
	}
	Menu_Vote = CreateMenu(Handler_VoteCallback, MENU_ACTIONS_ALL);
	
	if (Infected_NumLimit_Temp > 0)
		SetMenuTitle(Menu_Vote, "投票将特感数量更改 : %d", Infected_NumLimit_Temp, votesmaps);
	else if (Infected_SpawnTimer_Temp > 0)
		SetMenuTitle(Menu_Vote, "投票将特感复活时间更改 : %d s", Infected_SpawnTimer_Temp, votesmaps);

	AddMenuItem(Menu_Vote, VOTE_YES, "同意");
	AddMenuItem(Menu_Vote, VOTE_NO, "反对");
	SetMenuExitButton(Menu_Vote, false);
	
	int VoteClient[32], VoteNum = 0;
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i))
		{
			int MyTeam = GetClientTeam(i);
			if (MyTeam == 2 || MyTeam == 3)
				VoteClient[VoteNum ++] = i;
		}
	}

	if (VoteNum > 0)
		VoteMenu(Menu_Vote, VoteClient, VoteNum, 15);
}

// 投票过程及结果展示
public int Handler_VoteCallback(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 0 : 
				PrintToChatAll("\x04[提示] \x03%N \x05已投票. [ \x04同意 \x05]", param1);
			case 1 : 
				PrintToChatAll("\x04[提示] \x03%N \x05已投票. [ \x04反对 \x05]", param1);
		}
	}
	char item[32], display[32];
	float percent;
	int votes, totalVotes;
	GetMenuVoteInfo(param2, votes, totalVotes);
	GetMenuItem(menu, param1, item, sizeof(item), _, display, sizeof(display));
	
	if (strcmp(item, VOTE_NO) == 0 && param1 == 1)
		votes = totalVotes - votes;
	percent = GetVotePercent(votes, totalVotes);
	
	if (action == MenuAction_End)
		delete Menu_Vote;
	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
		PrintToChatAll("\x04[提示] \x05本次投票没有玩家投票.");
	else if (action == MenuAction_VoteEnd)
	{
		char per = '%';
		int NeedI = RoundToNearest(100.0 * Vote_Success_Percent);
		int TrueI = RoundToNearest(100.0 * percent);
		if ((strcmp(item, VOTE_YES) == 0 && FloatCompare(percent, Vote_Success_Percent) < 0 && param1 == 0) ||
			(strcmp(item, VOTE_NO) == 0 && param1 == 1))
		{
			PrintToChatAll("\x04[提示] \x05投票失败, 同意票数 ( \x04%d %s \x05) 未通过. < \x04%d %s \x05>"
							, TrueI, per, NeedI, per);
			PrintToChatAll("\x05< \x04同意 \x03%d \x04反对 \x03%d \x04合计 \x03%d \x04[ \x03%d %s \x04] \x05>"
							, votes, totalVotes - votes, totalVotes, TrueI, per);
		}
		else
		{
			PrintHintTextToAll("[提示] 投票通过.");
			PrintToChatAll("\x04[提示] \x05投票通过.");
			PrintToChatAll("\x05< \x04同意 \x03%d \x04反对 \x03%d \x04合计 \x03%d \x04[ \x03%d %s \x04] \x05>"
							, votes, totalVotes - votes, totalVotes, TrueI, per);
			Vote_End_Config();
		}
	}
	return 0;
}

public float GetVotePercent(int votes, int totalVotes)
{
	return float(votes) / float(totalVotes);
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

// 检测幸存者位置进行第一波刷特
public Action ReadyToFirstSpawn(Handle timer)
{
	float SurPos[3], SurTriggerDistance;
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, SurPos);

			if (L4D_IsPositionInFirstCheckpoint(SurPos))
				continue;

			switch (TriggerType)
			{
				case 0 :
					SurTriggerDistance = GetVectorDistance(SurPos, CenterPoint);
				case 1 :
					SurTriggerDistance = SurPos[0] - CenterPoint[0];
				case 2 :
					SurTriggerDistance = CenterPoint[0] - SurPos[0];
				case 3 :
					SurTriggerDistance = SurPos[1] - CenterPoint[1];
				case 4 :
					SurTriggerDistance = CenterPoint[1] - SurPos[1];
				case 5 :
					SurTriggerDistance = SurPos[2] - CenterPoint[2];
				case 6 :
					SurTriggerDistance = CenterPoint[2] - SurPos[2];
			}

			if (SurTriggerDistance >= TriggerDistance)
			{
				OnStartSpawn();
				FirstSpawn_PointCheckTimer = null;
				return Plugin_Stop;
			}
		}
	}
	return Plugin_Continue;
}

// 检查特感
public Action Check_Infected(Handle timer)
{
	if (SpawnTime > 60.0 || !CanStartSpawn || SpawnSize <= 0)
		return Plugin_Continue;

	float GameTime = GetGameTime();

	for (int i = 1; i <= MaxClients && !ProhibitTeleport ; i++)
	{
		if (IsClientInGame(i) &&
			GetClientTeam(i) == 3 &&
			IsPlayerAlive(i) &&
			IsFakeClient(i))
		{
			int ZombieClass = GetEntProp(i, Prop_Send, "m_zombieClass");

			if (ZombieClass < 1 || ZombieClass > 6)
				continue;

			//PrintToChatAll("检查特感: %N", i);

			if (IsAtkSurvivor(i, ZombieClass))
			{
				FarFromTimer[i] = -3;
				continue;
			}

			float InfectedPos[3], SurvivorPos[3], dist;
			GetClientAbsOrigin(i, InfectedPos);
			for (int j = 0; j < 3 ; j++)
				InfectedPos_Record[i][j] = InfectedPos[j];

			bool ForceFarFrom = true;
			bool CanSee = false;
			bool CantTP = false;

			for (int j = 1; j <= MaxClients ; j++)
			{
				if (IsClientInGame(j) && GetClientTeam(j) == 2 && IsPlayerAlive(j))
				{
					GetClientAbsOrigin(j, SurvivorPos);
					dist = GetVectorDistance(InfectedPos, SurvivorPos);

					if (dist >= 5000.0)//距离过远直接踢出
					{
						KickClient(i);
						break;
					}

					if (dist <= CantTPDistance)//距离生还者过近禁止传送
					{
						CantTP = true;
						//PrintToChatAll("%N 距离生还过近, 不传送", i);
						break;
					}

					if (!ForceFarFrom)
						continue;

					dist = Get2DBoxDistance(InfectedPos, SurvivorPos);

					if (dist <= ForceTPDistance)//距离所有生还者平面距离都很远, 强制传送
					{
						ForceFarFrom = false;
						//PrintToChatAll("%N 距离生还较近, 不触发强制传送", i);
					}
				}
			}

			if (CantTP)
			{
				FarFromTimer[i] = 0;
				continue;
			}

			for (int j = 1; j <= MaxClients ; j++)
			{
				if (IsClientInGame(j) && GetClientTeam(j) == 2 && IsPlayerAlive(j))
				{
					//检查双方可见性
					if (L4D2_IsVisibleToPlayer(j, 2, 3, 0, InfectedPos) || L4D2_IsVisibleToPlayer(i, 3, 2, 0, SurvivorPos))
					{
						CanSee = true;
						//PrintToChatAll("%N 能被生还者看见/能看见生还者", i);
						break;
					}
				}
			}

			if (!ForceFarFrom && CanSee)//强制传送或者不可见, 开始传送计时
				continue;

			//PrintToChatAll("%N tptimeadd : %d", i, FarFromTimer[i]);

			FarFromTimer[i] ++;
			if (FarFromTimer[i] > 3)
				NormalDeadChange(i, ZombieClass, true);
		}
	}

	if (FreeMode)
		return Plugin_Continue;

	if (FirstSpawn_PointCheckTimer != null ||
		(IsHaveAliveTank() && TankAlive_LimitSpawnTimer != null) ||
		(Wait_LimitPos_Number > 0 && WaitSpawn_PointCheckTimer != null))
	{
		NoInfectedAddTimer = RoundToCeil(SpawnTime) - 1;
		return Plugin_Continue;
	}

	if (GetInfectedBotNum(0) > 0)
	{
		NoInfectedAddTimer -= RoundToNearest(SpawnTime / 2.0);
		if (NoInfectedAddTimer <= 0)
			NoInfectedAddTimer = 0;
		return Plugin_Continue;
	}

	if (GameTime - SpawnGameTime < 1.0 && OverloadDeadNumber > 0) // 刷特期间有特感立即死亡且场上检测不到任何特感重启刷特
	{
		OnStartSpawn();
		return Plugin_Continue;
	}

	NoInfectedAddTimer ++;
	if (float(NoInfectedAddTimer) >= SpawnTime) // 场上无特感计时累加到刷特时间补偿刷特
	{
		OnStartSpawn();
		NoInfectedAddTimer = 0;
	}

	return Plugin_Continue;
}

// 检查Tank是否存活
public Action CheckTankAlive(Handle timer, int tank)
{
	if (!CIsTank(tank) || !IsFakeClient(tank) || !IsPlayerAlive(tank) || SpawnTime >= 60.0)
		return Plugin_Continue;
	
	IsTankToSpawn = true;
	if (TankAlive_LimitSpawnTimer != null)
		delete TankAlive_LimitSpawnTimer;
	
	TankAlive_LimitSpawnTimer = CreateTimer(0.1, CheckTankRange, tank, TIMER_REPEAT);
	Tank_DefaultHP = GetClientHealth(tank);
	TankTriggerRange = 9999.0;
	return Plugin_Continue;
}

// 检查Tank距离生还距离
public Action CheckTankRange(Handle timer, int tank)
{
	if (!CIsTank(tank) || !IsPlayerAlive(tank))
	{
		TankAlive_LimitSpawnTimer = null;
		IsTankToSpawn = false;
		return Plugin_Stop;
	}

	float MinDist = 9999.0;
	float TankPos[3], TankEyePos[3], SurPos[3], Dist;
	GetClientAbsOrigin(tank, TankPos);
	GetClientEyePosition(tank, TankEyePos);
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			if (!L4D2_IsVisibleToPlayer(i, 2, 3, 0, TankEyePos))
				continue;

			GetClientAbsOrigin(i, SurPos);
			Dist = GetVectorDistance(TankPos, SurPos);

			if (MinDist > Dist)
				MinDist = Dist;
		}
	}

	int TankHP = GetClientHealth(tank);

	if (MinDist < 9999.0)
		TankTriggerRange = MinDist;

	
	if ((TankTriggerRange > 0.0 && TankTriggerRange < 400.0) ||
		(TankHP <= (Tank_DefaultHP / 2)))
	{
		OnStartSpawn();
		if (SpawnTime > 1.0)
			CreateTimer(SpawnTime - 1.0, ReCold_IsTankToSpawn, _, TIMER_FLAG_NO_MAPCHANGE);
		else
			IsTankToSpawn = false;
		TankAlive_LimitSpawnTimer = null;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

// 等待刷特
public Action WaitToSpawn(Handle timer)
{
	float SurPos[3], SurTriggerDistance;
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, SurPos);

			if (SurPos[0] >= Wait_LimitPos[0][0] && SurPos[0] <= Wait_LimitPos[1][0] &&
				SurPos[1] >= Wait_LimitPos[0][1] && SurPos[1] <= Wait_LimitPos[1][1] &&
				SurPos[2] >= Wait_LimitPos[0][2] && SurPos[2] <= Wait_LimitPos[1][2])
			{
				continue;
			}

			switch (Wait_TriggerType)
			{
				case 0 :
					SurTriggerDistance = GetVectorDistance(SurPos, Wait_CenterPoint);
				case 1 :
					SurTriggerDistance = SurPos[0] - Wait_CenterPoint[0];
				case 2 :
					SurTriggerDistance = Wait_CenterPoint[0] - SurPos[0];
				case 3 :
					SurTriggerDistance = SurPos[1] - Wait_CenterPoint[1];
				case 4 :
					SurTriggerDistance = Wait_CenterPoint[1] - SurPos[2];
				case 5 :
					SurTriggerDistance = SurPos[2] - Wait_CenterPoint[2];
				case 6 :
					SurTriggerDistance = Wait_CenterPoint[2] - SurPos[2];
			}

			if (SurTriggerDistance >= Wait_TriggerDistance)
			{
				OnStartSpawn();
				WaitSpawn_PointCheckTimer = null;
				return Plugin_Stop;
			}
		}
	}
	return Plugin_Continue;
}

// 开始刷特
public Action StartSpawn(Handle timer)
{
	if (TankAlive_LimitSpawnTimer != null && TankTriggerRange < (300.0 + SpawnTime * 75.0))
		return Plugin_Continue;
	
	if (IsTankToSpawn)
		return Plugin_Continue;

	OnStartSpawn();
	return Plugin_Continue;
}

// 开始生成一只特感
public Action SpawnSpecial(Handle timer, int ZombieClass)
{
	OnSpawnSpecial(ZombieClass);
	return Plugin_Continue;
}

public Action ReCold_IsInSpawnTime(Handle timer)
{
	IsInSpawnTime = false;
	return Plugin_Continue;
}

public Action ReCold_CanForceSpawn(Handle timer)
{
	CanForceSpawn = false;
	return Plugin_Continue;
}

public Action ReCold_IsInSpawnCold(Handle timer)
{
	IsInSpawnCold = false;
	return Plugin_Continue;
}

public Action ReCold_IsTankToSpawn(Handle timer)
{
	IsTankToSpawn = false;
	return Plugin_Continue;
}





// ====================================================================================================
// Config
// ====================================================================================================

// Vote End Config
public void Vote_End_Config()
{
	if (Infected_NumLimit_Temp > 0)
	{
		SpawnSize = Infected_NumLimit_Temp;
		if (SILimit < SpawnSize)
			SILimit = SpawnSize;
		else
		{
			if (SILimit < Cvar_SILimit.IntValue)
				SILimit = Cvar_SILimit.IntValue;
		}

		PrintHintTextToAll("[提示] 特感数量已更换为: %d .", SpawnSize);
		PrintToChatAll("\x04[提示] \x05特感数量已更换为: \x03%d\x05.", SpawnSize);
	}
	else if (Infected_SpawnTimer_Temp > 0)
	{
		SpawnTime = float(Infected_SpawnTimer_Temp);

		PrintHintTextToAll("[提示] 特感复活时间已更换为: %d s.", Infected_SpawnTimer_Temp);
		PrintToChatAll("\x04[提示] \x05特感复活时间已更换为: \x03%d\x05 s.", Infected_SpawnTimer_Temp);
	}
}





// ====================================================================================================
// Spawn Special
// ====================================================================================================

// 进行刷特
public void OnStartSpawn()
{
	if (FreeMode)
		return;

	if (!CanStartSpawn)
		return;

	if (IsInSpawnCold)
		return;
	
	if (SpawnSize <= 0)
		return;

	if (GetClientNumber(2, true, false) <= 0)
		return;

	if ((GetGameTime() - SpawnGameTime) < (SpawnTime - 3.0))
		return;

	int Can_Spawn_Size = SpawnSize;
	int AllInfectedBotNum = GetInfectedBotNum(0);
	if (AllInfectedBotNum + Can_Spawn_Size > SILimit)
		Can_Spawn_Size = SILimit - AllInfectedBotNum;

	if (Can_Spawn_Size <= 0)
		return;

	int InfectedBotNum[6];
	for (int i = 0; i < 6 ; i++)
		InfectedBotNum[i] = GetInfectedBotNum(i + 1);

	int CanSpawnNumber[6], CanSpawnNumberAmount = 0;
	bool HaveAliveTank = IsHaveAliveTank();
	for (int i = 0; i < 6 ; i++)
	{
		CanSpawnNumber[i] = SpawnLimits[i] - InfectedBotNum[i];
		if (i == 3 && HaveAliveTank && TankAlive_NoSpitter)
			CanSpawnNumber[i] = 0;
		if (SpawnWeights[i] <= 0)
			CanSpawnNumber[i] = 0;
		
		CanSpawnNumberAmount += CanSpawnNumber[i];
	}

	if (CanSpawnNumberAmount <= 0)
		return;
	
	int ReadySpawnZombieClass[8], TCI = 0, ReadyToSpawnZombieClassAmount[6], ZombieClassAmount[6], ZombieClassAmountSum = 0;
	for (int i = 0; i < 8 ; i++)
		ReadySpawnZombieClass[i] = 0;

	for (int i = 0; i < 6 ; i++)
	{
		ReadyToSpawnZombieClassAmount[i] = 0;
		ZombieClassAmount[i] = 0;
	}

	for (int i = 0; i < 6 ; i++)
	{
		ZombieClassAmount[i] = SpawnWeights[i] * CanSpawnNumber[i];
		ZombieClassAmountSum += ZombieClassAmount[i];
		//PrintToChatAll("\x05[DeBug] \x01ZombieClassAmount (%s) : \x05%d", Infected_Name[i], ZombieClassAmount[i]);
	}

	//PrintToChatAll("\x05[DeBug] \x01ZombieClassAmountSum : \x05%d", ZombieClassAmountSum);

	if (ZombieClassAmountSum < Can_Spawn_Size)
		return;

	for (int i = 0; i < Can_Spawn_Size ; i++)
	{
		int RamdomCI = GetRandomInt(1, ZombieClassAmountSum);
		int ZombieClass = 0;

		//PrintToChatAll("\x05[DeBug] \x04CI : \x05%d   \x01|  \x04RCI : %d", i + 1, RamdomCI);
		
		for (int j = 0; j < 6 ; j++)
		{
			if (ZombieClassAmount[j] <= 0)
				continue;

			RamdomCI -= ZombieClassAmount[j];
			if (RamdomCI <= 0)
			{
				ZombieClass = j + 1;
				break;
			}
		}

		//PrintToChatAll("\x05[DeBug] \x04CI : \x05%d   \x01|   \x04ZombieClass : %d", i + 1, ZombieClass);

		if (ZombieClass < 1 || ZombieClass > 6)
			continue;
		
		if (ReadyToSpawnZombieClassAmount[ZombieClass - 1] + InfectedBotNum[ZombieClass - 1] >= SpawnLimits[ZombieClass - 1])
			i --;
		else
		{
			ReadyToSpawnZombieClassAmount[ZombieClass - 1] ++;
			ReadySpawnZombieClass[TCI ++] = ZombieClass;
			//PrintToChatAll("\x05[DeBug] \x04ReadySpawnZombieClass (%d) : %s", TCI, Infected_Name[ZombieClass - 1]);
		}
	}

	if (DeadClear)
	{
		for (int i = 1; i <= MaxClients ; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsFakeClient(i) && !IsPlayerAlive(i))
				KickClient(i);
		}
	}

	IsInSpawnTime = true;
	IsInSpawnCold = true;
	IsInDeadSpawn = false;
	CreateTimer(0.6, ReCold_IsInSpawnTime, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.9, ReCold_IsInSpawnCold, _, TIMER_FLAG_NO_MAPCHANGE);
	SpawnSize_Record = Can_Spawn_Size;
	SpawnGameTime = GetGameTime();
	OverloadDeadNumber = 0;
	NormalDeadNumber = 0;
	SpawnPos_RecordNumber = 0;
	GetHighestCeiling();

	if (Spawn_Type_Adaptive_Adjustment && SurFlowDataNumber > 0)
	{
		float SurFlow = GetSurFlow();

		for (int i = 0; i < SurFlowDataNumber - 1 ; i++)
		{
			if (SurFlow >= SurFlowData[i] && SurFlow < SurFlowData[i + 1])
			{
				Spawn_Type1 = SurFlowSTData[i][0];
				Spawn_Type2 = SurFlowSTData[i][1];
				SpawnPosLimit[0] = SurFlowSpawnPos_Min[i];
				SpawnPosLimit[1] = SurFlowSpawnPos_Max[i];
				break;
			}
		}
	}

	if (WaitSpawn_Trigger && Wait_LimitPos_Number > 0 && WaitSpawn_PointCheckTimer == null)
	{
		for (int i = 0; i < Wait_LimitPos_Number ; i++)
		{
			float SurPos[3];
			for (int sur = 1; sur <= MaxClients ; sur ++)
			{
				if (IsClientInGame(sur) && GetClientTeam(sur) == 2 && IsPlayerAlive(sur))
				{
					GetClientAbsOrigin(sur, SurPos);

					if (SurPos[0] > Wait_LimitPos_Min[i][0] &&
						SurPos[0] < Wait_LimitPos_Max[i][0] &&
						SurPos[1] > Wait_LimitPos_Min[i][1] &&
						SurPos[1] < Wait_LimitPos_Max[i][1] &&
						SurPos[2] > Wait_LimitPos_Min[i][2] &&
						SurPos[2] < Wait_LimitPos_Max[i][2])
					{
						Wait_LimitPos[0] = Wait_LimitPos_Min[i];
						Wait_LimitPos[1] = Wait_LimitPos_Max[i];
						Wait_CenterPoint = Wait_CenterPoint_Data[i];
						Wait_TriggerType = Wait_TriggerType_Data[i];
						Wait_TriggerDistance = GetRandomFloat(Wait_TriggerDistance_Min[i], Wait_TriggerDistance_Max[i]);
						WaitSpawn_PointCheckTimer = CreateTimer(0.1, WaitToSpawn, _, TIMER_REPEAT);
						return;
					}
				}
			}
		}
	}
	
	for (int i = 0; i < Can_Spawn_Size ; i++)
		OnSpawnSpecial(ReadySpawnZombieClass[i]);
}

// 生成特感
public void OnSpawnSpecial(int ZombieClass)
{
	if (FreeMode)
		return;

	if (!CanStartSpawn)
		return;

	if (ZombieClass < 1 || ZombieClass > 6)
		return;

	if (GetInfectedBotNum(0) >= SILimit)
		return;

	if (GetInfectedBotNum(ZombieClass) >= SpawnLimits[ZombieClass - 1])
		return;

	if (!IsInSpawnTime && !CanForceSpawn)
		return;

	if (FirstSpawn_PointCheckTimer != null && FToSpawnPos_Number > 0)
	{
		int ToSpawnPosCI = 0;
		int R_SpawnPos_CI = FSpawnRZI[ZombieClass - 1] <= 1 ? 1 : GetRandomInt(1, FSpawnRZI[ZombieClass - 1]);
		float ToSpawnPos[3] = {0.0, 0.0, 0.0};

		for (int i = 0; i < FToSpawnPos_Number ; i++)
		{
			R_SpawnPos_CI -= FSpawnRCI[ZombieClass - 1][i];

			if (R_SpawnPos_CI <= 0)
			{
				ToSpawnPosCI = i;
				break;
			}
		}

		switch (FToSpawnPos_Type[ToSpawnPosCI])
		{
			case 0 :
				ToSpawnPos = FToSpawnPos_Min[ToSpawnPosCI];
			case 1 :
			{
				for (int i = 0 ; i < 3 ; i++)
				{
					ToSpawnPos[i] = FToSpawnPos_Min[ToSpawnPosCI][i] >= FToSpawnPos_Max[ToSpawnPosCI][i] ?
									FToSpawnPos_Min[ToSpawnPosCI][i] :
									GetRandomFloat(FToSpawnPos_Min[ToSpawnPosCI][i], FToSpawnPos_Max[ToSpawnPosCI][i]);
				}
			}
			case 2 :
			{
				float FX_Sub = FToSpawnPos_Max[ToSpawnPosCI][0] - FToSpawnPos_Min[ToSpawnPosCI][0];
				float FY_Sub = FToSpawnPos_Max[ToSpawnPosCI][1] - FToSpawnPos_Min[ToSpawnPosCI][1];

				if (FX_Sub <= 0.01 || FY_Sub <= 0.01)
					return;

				float TempF = FY_Sub / FX_Sub;
				ToSpawnPos[0] = GetRandomFloat(FToSpawnPos_Min[ToSpawnPosCI][0], FToSpawnPos_Max[ToSpawnPosCI][0]);
				ToSpawnPos[1] = FToSpawnPos_Min[ToSpawnPosCI][1] +
								(ToSpawnPos[0] - FToSpawnPos_Min[ToSpawnPosCI][0]) * TempF;
				ToSpawnPos[2] = FToSpawnPos_Min[ToSpawnPosCI][2];
			}
			case 3 :
			{
				float FX_Sub = FToSpawnPos_Max[ToSpawnPosCI][0] - FToSpawnPos_Min[ToSpawnPosCI][0];
				float FZ_Sub = FToSpawnPos_Max[ToSpawnPosCI][2] - FToSpawnPos_Min[ToSpawnPosCI][2];

				if (FX_Sub <= 0.01 || FZ_Sub <= 0.01)
					return;

				float TempF = FZ_Sub / FX_Sub;
				ToSpawnPos[0] = GetRandomFloat(FToSpawnPos_Min[ToSpawnPosCI][0], FToSpawnPos_Max[ToSpawnPosCI][0]);
				ToSpawnPos[1] = FToSpawnPos_Min[ToSpawnPosCI][1];
				ToSpawnPos[2] = FToSpawnPos_Min[ToSpawnPosCI][2] +
								(ToSpawnPos[0] - FToSpawnPos_Min[ToSpawnPosCI][0]) * TempF;
			}
			case 4 :
			{
				float FY_Sub = FToSpawnPos_Max[ToSpawnPosCI][1] - FToSpawnPos_Min[ToSpawnPosCI][1];
				float FZ_Sub = FToSpawnPos_Max[ToSpawnPosCI][2] - FToSpawnPos_Min[ToSpawnPosCI][2];

				if (FY_Sub <= 0.01 || FZ_Sub <= 0.01)
					return;

				float TempF = FZ_Sub / FY_Sub;
				ToSpawnPos[0] = FToSpawnPos_Min[ToSpawnPosCI][0];
				ToSpawnPos[1] = GetRandomFloat(FToSpawnPos_Min[ToSpawnPosCI][1], FToSpawnPos_Max[ToSpawnPosCI][1]);
				ToSpawnPos[2] = FToSpawnPos_Min[ToSpawnPosCI][2] +
								(ToSpawnPos[1] - FToSpawnPos_Min[ToSpawnPosCI][1]) * TempF;
			}
			case 5 :
			{
				float FX_Sub = FToSpawnPos_Max[ToSpawnPosCI][0] - FToSpawnPos_Min[ToSpawnPosCI][0];
				float FY_Sub = FToSpawnPos_Max[ToSpawnPosCI][1] - FToSpawnPos_Min[ToSpawnPosCI][1];

				if (FX_Sub <= 0.01 || FY_Sub <= 0.01)
					return;

				float TempF = FY_Sub / FX_Sub;
				ToSpawnPos[0] = GetRandomFloat(FToSpawnPos_Min[ToSpawnPosCI][0], FToSpawnPos_Max[ToSpawnPosCI][0]);
				ToSpawnPos[1] = FToSpawnPos_Max[ToSpawnPosCI][1] -
								(ToSpawnPos[0] - FToSpawnPos_Min[ToSpawnPosCI][0]) * TempF;
				ToSpawnPos[2] = FToSpawnPos_Min[ToSpawnPosCI][2];
			}
			case 6 :
			{
				float FX_Sub = FToSpawnPos_Max[ToSpawnPosCI][0] - FToSpawnPos_Min[ToSpawnPosCI][0];
				float FZ_Sub = FToSpawnPos_Max[ToSpawnPosCI][2] - FToSpawnPos_Min[ToSpawnPosCI][2];

				if (FX_Sub <= 0.01 || FZ_Sub <= 0.01)
					return;

				float TempF = FZ_Sub / FX_Sub;
				ToSpawnPos[0] = GetRandomFloat(FToSpawnPos_Min[ToSpawnPosCI][0], FToSpawnPos_Max[ToSpawnPosCI][0]);
				ToSpawnPos[1] = FToSpawnPos_Min[ToSpawnPosCI][1];
				ToSpawnPos[2] = FToSpawnPos_Max[ToSpawnPosCI][2] -
								(ToSpawnPos[0] - FToSpawnPos_Min[ToSpawnPosCI][0]) * TempF;
			}
			case 7 :
			{
				float FY_Sub = FToSpawnPos_Max[ToSpawnPosCI][1] - FToSpawnPos_Min[ToSpawnPosCI][1];
				float FZ_Sub = FToSpawnPos_Max[ToSpawnPosCI][2] - FToSpawnPos_Min[ToSpawnPosCI][2];

				if (FY_Sub <= 0.01 || FZ_Sub <= 0.01)
					return;

				float TempF = FZ_Sub / FY_Sub;
				ToSpawnPos[0] = FToSpawnPos_Min[ToSpawnPosCI][0];
				ToSpawnPos[1] = GetRandomFloat(FToSpawnPos_Min[ToSpawnPosCI][1], FToSpawnPos_Max[ToSpawnPosCI][1]);
				ToSpawnPos[2] = FToSpawnPos_Max[ToSpawnPosCI][2] -
								(ToSpawnPos[1] - FToSpawnPos_Min[ToSpawnPosCI][1]) * TempF;
			}
		}

		if (ToSpawnPos[0] == 0.0 && ToSpawnPos[1] == 0.0 && ToSpawnPos[2] == 0.0)
			return;

		if (ZombieClass == 2 || ZombieClass == 5)
			ToSpawnPos[2] += 20.0;
		
		int zombie = -1;
		zombie = SDKCall(SDK_CreateInfectedBot[ZombieClass - 1], Infected_Name[ZombieClass - 1]);

		if (zombie == -1)
			return;

		InitializeSpecial(zombie, ToSpawnPos);
		return;
	}

	int victim = GetRunMan();
	int incapsur = GetIncapSurvivor();

	if (victim == -1)
	{
		if (ZombieClass == 2 && incapsur > 0) // 优先让Boomer选取 倒地或者挂边 的幸存者作为目标进行复活
			victim = incapsur;
		else
		{
			int victim_group[32], victim_number = 0;
			float flow;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) &&
					GetClientTeam(i) == 2 &&
					IsPlayerAlive(i) &&
					!GetEntProp(i, Prop_Send, "m_isIncapacitated"))
				{
					flow = L4D2Direct_GetFlowDistance(i);
					if (flow && flow != -9999.0)
					{
						victim_group[victim_number] = i;
						victim_number ++;
					}
				}
			}

			if (victim_number <= 0)
				return;
			else if (victim_number == 1)
				victim = victim_group[0];
			else
			{
				int r = GetRandomInt(1, victim_number);
				victim = victim_group[r - 1];
			}
		}
	}

	float ToSpawnPos[3];
	bool IsSpawn = false;

	if (SpawnPosLimit[0][0] != 0.0 &&
		SpawnPosLimit[0][1] != 0.0 &&
		SpawnPosLimit[0][2] != 0.0 &&
		SpawnPosLimit[1][0] != 0.0 &&
		SpawnPosLimit[1][1] != 0.0 &&
		SpawnPosLimit[1][2] != 0.0)
	{
		for (int i = 0; i < 3 ; i++)
			ToSpawnPos[i] = GetRandomFloat(SpawnPosLimit[0][i], SpawnPosLimit[1][i]);

		if (ZombieClass == 2 || ZombieClass == 5)
			ToSpawnPos[2] += 20.0;
		
		int zombie = -1;
		zombie = SDKCall(SDK_CreateInfectedBot[ZombieClass - 1], Infected_Name[ZombieClass - 1]);

		if (zombie == -1)
			return;

		InitializeSpecial(zombie, ToSpawnPos);
		return;
	}

	float StSpawnPos[24][3], TempF3[3];
	int StSpawnPosNumber = 0;
	float TargetSur_Pos[3];
	GetClientAbsOrigin(victim, TargetSur_Pos);
	float TargetSur_Flow = L4D2Direct_GetFlowDistance(victim);

	float SpawnDistance = DefaultSpawnDistance; // 初始最近生成距离

	if (ZombieClass == 1) // 让Smoker活得远些
		SpawnDistance += 200.0;
	else if (ZombieClass == 4) // 让Spitter活得远些
		SpawnDistance += 100.0;

	float MaxSpawnDistance = DefaultMaxSpawnDistance; // 初始最远生成距离

	if (ZombieClass == 2) // 禁止Boomer活得太远
		MaxSpawnDistance -= 200.0;

	static float SpawnQuality_AddSpawnDist[5] = {100.0, 50.0, 33.3, 25.0, 20.0};

	for (; SpawnDistance < MaxSpawnDistance && StSpawnPosNumber < 24 ; SpawnDistance += SpawnQuality_AddSpawnDist[SpawnQuality])
	{
		if (GetSpawnPos(ToSpawnPos,
						ZombieClass,
						victim,
						SpawnDistance,
						SpawnDistance + SpawnQuality_AddSpawnDist[SpawnQuality]))
		{
			StSpawnPos[StSpawnPosNumber] = ToSpawnPos;
			StSpawnPosNumber ++;
		}
	}

	switch (Spawn_Type1)
	{
		case 2 : // 高点
		{
			float Tan_Float[24], TempF;

			if (ZombieClass != 3) // Hunter不优先活高位
			{
				for (int i = 0; i < StSpawnPosNumber ; i++)
				{
					float dist = Get2DBoxDistance(TargetSur_Pos, StSpawnPos[i]);

					if (dist > 500.0)
					{
						Tan_Float[i] = 0.0;
						continue;
					}

					Tan_Float[i] = StSpawnPos[i][2] - TargetSur_Pos[2];
				}

				for (int i = 0; i < StSpawnPosNumber - 1 ; i++)
				{
					for (int j = StSpawnPosNumber - 1; j > i ; j --)
					{
						if (Tan_Float[j] > Tan_Float[j - 1])
						{
							TempF3				= StSpawnPos[j];
							StSpawnPos[j]		= StSpawnPos[j - 1];
							StSpawnPos[j - 1]	= TempF3;

							TempF				= Tan_Float[j];
							Tan_Float[j]		= Tan_Float[j - 1];
							Tan_Float[j - 1]	= TempF;
						}
					}
				}
			}
		}
		case 3 : // 前方
		{
			float TempF, StSpawnPosFlow[24], Tan_Float[24];

			for (int i = 0; i < StSpawnPosNumber ; i++)
			{
				Address SpawnAddress = L4D_GetNearestNavArea(StSpawnPos[i], 120.0, false, false, false, 3);

				if (SpawnAddress == Address_Null)
					continue;
				
				StSpawnPosFlow[i] = L4D2Direct_GetTerrorNavAreaFlow(SpawnAddress);

				float Flow_Sub = StSpawnPosFlow[i] - TargetSur_Flow;

				if (Flow_Sub <= 0.0)
					Tan_Float[i] = 0.0;
				else
					Tan_Float[i] = Flow_Sub / GetVectorDistance(ToSpawnPos, TargetSur_Pos);
			}

			for (int i = 0; i < StSpawnPosNumber - 1 ; i++)
			{
				for (int j = StSpawnPosNumber - 1; j > i ; j --)
				{
					if (Tan_Float[j] > Tan_Float[j - 1])
					{
						TempF3				= StSpawnPos[j];
						StSpawnPos[j]		= StSpawnPos[j - 1];
						StSpawnPos[j - 1]	= TempF3;

						TempF				= Tan_Float[j];
						Tan_Float[j]		= Tan_Float[j - 1];
						Tan_Float[j - 1]	= TempF;
					}
				}
			}
		}
		case 4 : // 后方
		{
			float TempF, StSpawnPosFlow[24], Tan_Float[24];

			for (int i = 0; i < StSpawnPosNumber ; i++)
			{
				Address SpawnAddress = L4D_GetNearestNavArea(StSpawnPos[i], 120.0, false, false, false, 3);

				if (SpawnAddress == Address_Null)
					continue;
				
				StSpawnPosFlow[i] = L4D2Direct_GetTerrorNavAreaFlow(SpawnAddress);

				float Flow_Sub = TargetSur_Flow - StSpawnPosFlow[i];

				if (Flow_Sub <= 0.0)
					Tan_Float[i] = 0.0;
				else
					Tan_Float[i] = Flow_Sub / GetVectorDistance(StSpawnPos[i], TargetSur_Pos);
			}

			for (int i = 0; i < StSpawnPosNumber - 1 ; i++)
			{
				for (int j = StSpawnPosNumber - 1; j > i ; j --)
				{
					if (Tan_Float[j] < Tan_Float[j - 1])
					{
						TempF3				= StSpawnPos[j];
						StSpawnPos[j]		= StSpawnPos[j - 1];
						StSpawnPos[j - 1]	= TempF3;

						TempF				= Tan_Float[j];
						Tan_Float[j]		= Tan_Float[j - 1];
						Tan_Float[j - 1]	= TempF;
					}
				}
			}
		}
	}

	for (int i = 0; i < StSpawnPosNumber ; i++)
	{
		bool PosIsShould = true;

		for (int j = 0; j < SpawnPos_RecordNumber ; j++)
		{
			if (GetVectorDistance(StSpawnPos[i], SpawnPos_Record[j]) <= NearbySpawnDistance)
			{
				if (ZombieClass == 4) // 允许Spitter与其他特感活在一块
				{
					if (Get2DBoxDistance(StSpawnPos[i], SpawnPos_Record[j]) <= 40.0) // 防止堆叠
						StSpawnPos[i][2] = SpawnPos_Record[j][2];
				}
				else
					PosIsShould = false;
				break;
			}
		}

		if (!PosIsShould)
			continue;

		if (SpawnInfected(StSpawnPos[i], ZombieClass))
		{
			IsSpawn = true;
			SpawnPos_Record[SpawnPos_RecordNumber] = StSpawnPos[i];
			SpawnPos_RecordNumber ++;
			break;
		}
	}

	if (!IsSpawn)
	{
		if (SpawnPos_RecordNumber == 0)
		{
			if (TankAlive_LimitSpawnTimer != null && IsTankToSpawn)
				IsTankToSpawn = false;

			IsInSpawnTime = false;
			SpawnGameTime = 0.0;
			CreateTimer(1.0, StartSpawn, _, TIMER_FLAG_NO_MAPCHANGE);
			return;
		}
		else if (SpawnPos_RecordNumber == 1)
		{
			for (int i = 0; i < 3 ; i++)
				ToSpawnPos[i] = SpawnPos_Record[0][i];
		}
		else
		{
			int RPos_Select = GetRandomInt(1, SpawnPos_RecordNumber);
			for (int i = 0; i < 3 ; i++)
				ToSpawnPos[i] = SpawnPos_Record[RPos_Select - 1][i];
		}

		int zombie = -1;
		zombie = SDKCall(SDK_CreateInfectedBot[ZombieClass - 1], Infected_Name[ZombieClass - 1]);

		if (zombie == -1)
			return;

		InitializeSpecial(zombie, ToSpawnPos);
	}
}





// ====================================================================================================
// void
// ====================================================================================================

// 移除一些限制特感的透明墙体, 增加活动空间
public void RemoveInfectedClips()
{
	int entity = MaxClients + 1;
	while ((entity = FindEntityByClassname(entity, "func_playerinfected_clip")) != -1)
		RemoveEntity(entity);

	entity = MaxClients + 1;
	while ((entity = FindEntityByClassname(entity, "func_playerghostinfected_clip")) != -1)
		RemoveEntity(entity);
}

// 传送特感或者判定进行计时开始下一轮刷特
public void NormalDeadChange(int client, int ZombieClass, bool IsTeleport)
{
	if (IsTeleport && CIsInfected(client) && IsPlayerAlive(client))
	{
		static int InfectedMaxHP[6] = {250, 50, 150, 100, 325, 600};

		float ToSpawnPos[3];
		float SpawnDistance = DefaultTPSpawnDistance;
		int victim = InfectedTargetVictim[client];

		if (!CIsSurvivor(victim) || !IsPlayerAlive(victim))
			victim = GetNearestSurvivor(client);

		int NowHP = GetClientHealth(client);
		int NowMaxHP = InfectedMaxHP[ZombieClass - 1];
		int SetHP = NowHP;

		if (NowHP < NowMaxHP)
			SetHP = NowHP + (NowMaxHP - NowHP) / 2;

		if (!CIsSurvivor(victim) || !IsPlayerAlive(victim))
			return;
		
		for (; SpawnDistance < DefaultMaxSpawnDistance ; SpawnDistance += 50.0)
		{
			if (GetSpawnPos(ToSpawnPos, ZombieClass, victim, SpawnDistance, SpawnDistance + 50.0))
			{
				FarFromTimer[client] = 0;
				SetEntProp(client, Prop_Send, "m_iHealth", SetHP);
				TeleportEntity(client, ToSpawnPos, NULL_VECTOR, NULL_VECTOR);
				break;
			}
		}
	}
	else
	{
		NormalDeadNumber ++;
		if (NormalDeadNumber >= (SpawnSize_Record / 2) && !IsInDeadSpawn)
		{
			IsInDeadSpawn = true;
			CreateTimer(SpawnTime, StartSpawn, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

// CommandFlags
public void BypassAndExecuteCommand(char[] strCommand)
{
	int flags = GetCommandFlags(strCommand);
	SetCommandFlags(strCommand, flags & ~FCVAR_CHEAT);
	FakeClientCommand(GetRandomSurvivor(), "%s", strCommand);
	SetCommandFlags(strCommand, flags);
}

// 杀死或者踢出玩家
public void ClearClient(int client)
{
	if (IsFakeClient(client))
		KickClient(client);
	else
		ForcePlayerSuicide(client);
}

// 清除所有的计时器
public void ClearAllTimer()
{
	if (FirstSpawn_PointCheckTimer != null)
		delete FirstSpawn_PointCheckTimer;
	if (TankAlive_LimitSpawnTimer != null)
		delete TankAlive_LimitSpawnTimer;
	if (WaitSpawn_PointCheckTimer != null)
		delete WaitSpawn_PointCheckTimer;
	if (Infected_CheckTimer != null)
		delete Infected_CheckTimer;
}

// 获取最高的天花板高度
public void GetHighestCeiling()
{
	float SurEyePos[3], CeilingPos[3], HighSurEyePos = -9999.0;
	HighestCeiling = -9994.0;
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i))
			continue;

		GetClientEyePosition(i, SurEyePos);

		if (HighSurEyePos < SurEyePos[2])
			HighSurEyePos = SurEyePos[2];

		TR_TraceRayFilter(SurEyePos, view_as<float>({-90.0, 0.0, 0.0}),
						MASK_SOLID,
						RayType_Infinite,
						TraceEntityFilterPlayer,
						i);
		if (TR_DidHit(INVALID_HANDLE))
		{
			TR_GetEndPosition(CeilingPos, INVALID_HANDLE);
			if (HighestCeiling < CeilingPos[2])
				HighestCeiling = CeilingPos[2];
		}
	}
	HighestCeiling -= 80.0;

	if (HighestCeiling > HighSurEyePos + 800.0)
		HighestCeiling = HighSurEyePos + 800.0;
}

// 设置特感属性
void InitializeSpecial(int zombie, const float vPos[3])
{
	ChangeClientTeam(zombie, 3);
	SetEntProp(zombie, Prop_Send, "m_usSolidFlags", 16);
	SetEntProp(zombie, Prop_Send, "movetype", 2);
	SetEntProp(zombie, Prop_Send, "deadflag", 0);
	SetEntProp(zombie, Prop_Send, "m_lifeState", 0);
	SetEntProp(zombie, Prop_Send, "m_iObserverMode", 0);
	SetEntProp(zombie, Prop_Send, "m_iPlayerState", 0);
	SetEntProp(zombie, Prop_Send, "m_zombieState", 0);
	DispatchSpawn(zombie);
	TeleportEntity(zombie, vPos, NULL_VECTOR, NULL_VECTOR);
	SetEntProp(zombie, Prop_Send, "m_bDucked", 1);
	SetEntityFlags(zombie, GetEntityFlags(zombie)|FL_DUCKING);
}





// ====================================================================================================
// GameData
// ====================================================================================================

void InitData()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof sPath, "gamedata/%s.txt", GAMEDATA);
	if (!FileExists(sPath))
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if (!hGameData)
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TerrorNavMesh::GetLastCheckpoint"))
		LogError("Failed to find signature: \"TerrorNavMesh::GetLastCheckpoint\"");
	else
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Checkpoint::GetLargestArea"))
		LogError("Failed to find signature: \"Checkpoint::GetLargestArea\"");
	else
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

	Address pReplaceWithBot = hGameData.GetAddress("NextBotCreatePlayerBot.jumptable");
	if (pReplaceWithBot != Address_Null && LoadFromAddress(pReplaceWithBot, NumberType_Int8) == 0x68)
		PrepWindowsCreateBotCalls(pReplaceWithBot);
	else
		PrepLinuxCreateBotCalls(hGameData);

	InitPatchs(hGameData);

	delete hGameData;
}

void InitPatchs(GameData hGameData = null)
{
	int iOffset = hGameData.GetOffset("RoundRespawn_Offset");
	if (iOffset == -1)
		SetFailState("Failed to find offset: RoundRespawn_Offset");

	int iByteMatch = hGameData.GetOffset("RoundRespawn_Byte");
	if (iByteMatch == -1)
		SetFailState("Failed to find byte: RoundRespawn_Byte");

	StatsCondition = hGameData.GetMemSig("CTerrorPlayer::RoundRespawn");
	if (!StatsCondition)
		SetFailState("Failed to find address: CTerrorPlayer::RoundRespawn");
	
	StatsCondition += view_as<Address>(iOffset);
	int iByteOrigin = LoadFromAddress(StatsCondition, NumberType_Int8);
	if (iByteOrigin != iByteMatch)
		SetFailState("Failed to load 'CTerrorPlayer::RoundRespawn', byte mis-match @ %d (0x%02X != 0x%02X)", iOffset, iByteOrigin, iByteMatch);
}

void LoadStringFromAdddress(Address pAddr, char[] buffer, int maxlength)
{
	int i;
	char val;
	while (i < maxlength)
	{
		val = LoadFromAddress(pAddr + view_as<Address>(i), NumberType_Int8);
		if (val == 0)
		{
			buffer[i] = '\0';
			break;
		}
		buffer[i++] = val;
	}
	buffer[maxlength - 1] = '\0';
}

Handle PrepCreateBotCallFromAddress(StringMap SiFuncHashMap, const char[] SIName)
{
	Address pAddr;
	StartPrepSDKCall(SDKCall_Static);
	if (!SiFuncHashMap.GetValue(SIName, pAddr) || !PrepSDKCall_SetAddress(pAddr))
		SetFailState("Unable to find NextBotCreatePlayer<%s> address in memory.", SIName);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	return EndPrepSDKCall();	
}

void PrepWindowsCreateBotCalls(Address pJumpTableAddr)
{
	StringMap hashMap = new StringMap();
	for (int i; i < 7; i++)
	{
		// 12 bytes in PUSH32, CALL32, JMP8.
		Address pCaseBase = pJumpTableAddr + view_as<Address>(i * 12);
		Address pSIStringAddr = view_as<Address>(LoadFromAddress(pCaseBase + view_as<Address>(1), NumberType_Int32));
		char SIName[32];
		LoadStringFromAdddress(pSIStringAddr, SIName, sizeof SIName);

		Address pFuncRefAddr = pCaseBase + view_as<Address>(6); // 2nd byte of call, 5+1 byte offset.
		int funcRelOffset = LoadFromAddress(pFuncRefAddr, NumberType_Int32);
		Address pCallOffsetBase = pCaseBase + view_as<Address>(10); // first byte of next instruction after the CALL instruction
		Address pNextBotCreatePlayerBotTAddr = pCallOffsetBase + view_as<Address>(funcRelOffset);
		PrintToServer("Found NextBotCreatePlayerBot<%s>() @ %08x", SIName, pNextBotCreatePlayerBotTAddr);
		hashMap.SetValue(SIName, pNextBotCreatePlayerBotTAddr);
	}

	SDK_CreateInfectedBot[0] = PrepCreateBotCallFromAddress(hashMap, "Smoker");
	if (!SDK_CreateInfectedBot[0])
		SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateSmoker);

	SDK_CreateInfectedBot[1] = PrepCreateBotCallFromAddress(hashMap, "Boomer");
	if (!SDK_CreateInfectedBot[1])
		SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateBoomer);

	SDK_CreateInfectedBot[2] = PrepCreateBotCallFromAddress(hashMap, "Hunter");
	if (!SDK_CreateInfectedBot[2])
		SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateHunter);

	SDK_CreateInfectedBot[3] = PrepCreateBotCallFromAddress(hashMap, "Spitter");
	if (!SDK_CreateInfectedBot[3])
		SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateSpitter);
	
	SDK_CreateInfectedBot[4] = PrepCreateBotCallFromAddress(hashMap, "Jockey");
	if (!SDK_CreateInfectedBot[4])
		SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateJockey);

	SDK_CreateInfectedBot[5] = PrepCreateBotCallFromAddress(hashMap, "Charger");
	if (!SDK_CreateInfectedBot[5])
		SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateCharger);
}

void PrepLinuxCreateBotCalls(GameData hGameData = null)
{
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateSmoker))
		SetFailState("Failed to find signature: %s", NAME_CreateSmoker);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	SDK_CreateInfectedBot[0] = EndPrepSDKCall();
	if (!SDK_CreateInfectedBot[0])
		SetFailState("Failed to create SDKCall: %s", NAME_CreateSmoker);
	
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateBoomer))
		SetFailState("Failed to find signature: %s", NAME_CreateBoomer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	SDK_CreateInfectedBot[1] = EndPrepSDKCall();
	if (!SDK_CreateInfectedBot[1])
		SetFailState("Failed to create SDKCall: %s", NAME_CreateBoomer);
		
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateHunter))
		SetFailState("Failed to find signature: %s", NAME_CreateHunter);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	SDK_CreateInfectedBot[2] = EndPrepSDKCall();
	if (!SDK_CreateInfectedBot[2])
		SetFailState("Failed to create SDKCall: %s", NAME_CreateHunter);
	
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateSpitter))
		SetFailState("Failed to find signature: %s", NAME_CreateSpitter);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	SDK_CreateInfectedBot[3] = EndPrepSDKCall();
	if (!SDK_CreateInfectedBot[3])
		SetFailState("Failed to create SDKCall: %s", NAME_CreateSpitter);
	
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateJockey))
		SetFailState("Failed to find signature: %s", NAME_CreateJockey);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	SDK_CreateInfectedBot[4] = EndPrepSDKCall();
	if (!SDK_CreateInfectedBot[4])
		SetFailState("Failed to create SDKCall: %s", NAME_CreateJockey);
		
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateCharger))
		SetFailState("Failed to find signature: %s", NAME_CreateCharger);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	SDK_CreateInfectedBot[5] = EndPrepSDKCall();
	if (!SDK_CreateInfectedBot[5])
		SetFailState("Failed to create SDKCall: %s", NAME_CreateCharger);
		
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateTank))
		SetFailState("Failed to find signature: %s", NAME_CreateTank);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
}





// ====================================================================================================
// int
// ====================================================================================================

// 获取Client数量
public int GetClientNumber(int cteam, bool OnlyAlive, bool OnlyPlayer)
{
	int num = 0;
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) &&
			(cteam == 0 || GetClientTeam(i) == cteam) &&	// 指定队伍类型
			(!OnlyAlive || IsPlayerAlive(i)) &&				// 是否要求为活着的状态
			(!OnlyPlayer || !IsFakeClient(i)))				// 是否要求为非电脑玩家
		{
			num ++;
		}
	}
	return num;
}

// 获取非Tank被感染者Bot数量
public int GetInfectedBotNum(int TargetZombieClass)
{
	int infectedbotnum = 0;
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsFakeClient(i) && IsPlayerAlive(i))
		{
			int ZombieClass = GetEntProp(i, Prop_Send, "m_zombieClass");

			if (ZombieClass < 1 || ZombieClass > 6) // 不计算Tank
				continue;

			if (TargetZombieClass == 0 || TargetZombieClass == ZombieClass)
				infectedbotnum ++;
		}
	}
	return infectedbotnum;
}

// 获取少人模式
public int GetNumTypeNumber()
{
	static ConVar GNumType;
	if (!GNumType)
		GNumType = FindConVar("l4d2_num_type_vtypemode");

	if (GNumType == null || GNumType.IntValue < 1 || GNumType.IntValue > 4)
		return 4;
	
	return GNumType.IntValue;
}

// 获取跑分的幸存者
public int GetRunMan()
{
	float listflow[32], flow, max_flow = -9999.0;
	int list_num = 0, max_flow_position = 0, maxflowsur = -1;
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !GetEntProp(i, Prop_Send, "m_isIncapacitated"))
		{
			flow = L4D2Direct_GetFlowDistance(i);
			if (flow && flow != -9999.0)
			{
				if (flow > max_flow)
				{
					max_flow = flow;
					maxflowsur = i;
					max_flow_position = list_num;
				}

				listflow[list_num] = flow;
				list_num ++;
			}
		}
	}

	if (list_num <= 1)
		return -1;
	
	for (int i = 0; i < list_num ; i++)
	{
		if (i != max_flow_position)
		{
			if (max_flow - listflow[i] < 1000.0)
				return -1;
		}
	}

	return maxflowsur;
}

// 获取倒地&挂边的幸存者
public int GetIncapSurvivor()
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_isIncapacitated"))
			return i;
	}

	return -1;
}

// 获取最近的幸存者
public int GetNearestSurvivor(int client)
{
	float vPos[3], SurPos[3];
	GetClientAbsOrigin(client, vPos);
	int min_sur = 0;
	float min = 9999.0, dist;
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, SurPos);
			dist = GetVectorDistance(vPos, SurPos);

			if (dist < min)
			{
				min = dist;
				min_sur = i;
			}
		}
	}
	return min_sur;
}





// ====================================================================================================
// float
// ====================================================================================================

// 获取2D平面距离
public float Get2DBoxDistance(float Pos1[3], float Pos2[3])
{
	float Sub0 = FloatAbs(Pos2[0] - Pos1[0]);
	float Sub1 = FloatAbs(Pos2[1] - Pos1[1]);
	float Dist_SQ = Sub0 * Sub0 + Sub1 * Sub1;
	return SquareRoot(Dist_SQ);
}

// 修正float型变量
public float GetCorrectFloat(float value, float min, float max)
{
	if (value < min)
		return min;
	
	if (value > max)
		return max;
	
	return value;
}

// 获取生还者路程
public float GetSurFlow()
{
	int target;
	float SurMaxFlow = (target = L4D_GetHighestFlowSurvivor()) != -1 ?
						L4D2Direct_GetFlowDistance(target) : L4D2_GetFurthestSurvivorFlow();
	return SurMaxFlow;
}





// ====================================================================================================
// Client Bool
// ====================================================================================================

// 是否为在游戏内的客户端
public bool CIsInGameClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

// 是否为生还者
public bool CIsSurvivor(int client)
{
	return CIsInGameClient(client) && GetClientTeam(client) == 2;
}

// 是否为感染者
public bool CIsInfected(int client)
{
	return CIsInGameClient(client) && GetClientTeam(client) == 3;
}

// 是否为Tank
public bool CIsTank(int client)
{
	return CIsInfected(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == 8;
}

// 是否为正在控制幸存者的特感
public bool IsAtkSurvivor(int client, int ZombieClass)
{
	int victim = 0;
	switch (ZombieClass)
	{
		case 1 :
			victim = GetEntPropEnt(client, Prop_Send, "m_tongueVictim");
		case 3 :
			victim = GetEntPropEnt(client, Prop_Send, "m_pounceVictim");
		case 5 :
			victim = GetEntPropEnt(client, Prop_Send, "m_jockeyVictim");
		case 6 :
		{
			victim = GetEntPropEnt(client, Prop_Send, "m_pummelVictim");
			if (victim <= 0)
				victim = GetEntPropEnt(client, Prop_Send, "m_carryVictim");
		}
	}
	return CIsSurvivor(victim) && IsPlayerAlive(victim);
}

// 是否为管理员
public bool IsAdministrators(int client)
{
	if (GetUserFlagBits(client) & ADMFLAG_ROOT)
		return true;
	return false;
}





// ====================================================================================================
// Judge Bool
// ====================================================================================================

// 是否有存活的Tank
public bool IsHaveAliveTank()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == 8)
			return true;
	}
	return false;
}





// ====================================================================================================
// Spawn Bool
// ====================================================================================================

// 获取复活位置
public bool GetSpawnPos(float ToSpawnPos[3], int ZombieClass, int TargetSur, float MinSpawnDistance, float MaxSpawnDistance)
{
	if (!CIsSurvivor(TargetSur) || !IsPlayerAlive(TargetSur))
		return false;
	
	float RandomAngle = GetRandomFloat(-180.0, 180.0);
	bool PosCantSpawn[72];
	for (int i = 0; i < 72 ; i++)
		PosCantSpawn[i] = false;

	float SurPos[3];
	GetClientAbsOrigin(TargetSur, SurPos);
	float SurFlow = L4D2Direct_GetFlowDistance(TargetSur);

	float CeilingHigh = SurPos[2] + (Spawn_Type2 == 1 ? 71.0 : NormalHighPoint);

	if (CeilingHigh > HighestCeiling)
		CeilingHigh = HighestCeiling;

	float StSpawnPos[36][3];
	int StSpawnPosNumber = 0;

	int MaxFindCheckNum = RoundToNearest(360.0 / SpawnAngleQuality);

	static float SpawnQuality_AddFindDist[5] = {51.0, 26.0, 17.0, 13.0, 11.0};

	for (float StartSpawnDistance = MinSpawnDistance;
		StartSpawnDistance <= MaxSpawnDistance ;
		StartSpawnDistance += SpawnQuality_AddFindDist[SpawnQuality])
	{
		if (StSpawnPosNumber >= 36)
			break;

		for (int i = 0; i < MaxFindCheckNum ; i++)
		{
			if (StSpawnPosNumber >= 36)
				break;

			if (PosCantSpawn[i])
				break;

			RandomAngle += SpawnAngleQuality;
			if (RandomAngle >= 360.0)
				RandomAngle -= 360.0;

			float RadAngle = RandomAngle / 57.2957795130823;
			ToSpawnPos[0] = SurPos[0] + Cosine(RadAngle) * StartSpawnDistance;
			ToSpawnPos[1] = SurPos[1] + Sine(RadAngle) * StartSpawnDistance;
			ToSpawnPos[2] = Spawn_Type1 ? HighestCeiling : CeilingHigh;

			float GroundPos[3];
			TR_TraceRay(ToSpawnPos, view_as<float>({90.0, 0.0, 0.0}), TRACE_RAY_FLAG, RayType_Infinite);
			if (TR_DidHit())
			{
				TR_GetEndPosition(GroundPos);
				ToSpawnPos = GroundPos;
				ToSpawnPos[2] += 20.0;
			}

			Address SpawnAddress = L4D_GetNearestNavArea(ToSpawnPos, 120.0, false, false, false, 3);

			if (SpawnAddress == Address_Null)
			{
				PosCantSpawn[i] = true;
				continue;
			}

			if (ToSpawnPos[2] - SurPos[2] < 180.0)
			{
				float SpawnFlow = L4D2Direct_GetTerrorNavAreaFlow(SpawnAddress);

				if (SpawnFlow < 1.0 || SpawnFlow - SurFlow > 1500.0 || SurFlow - SpawnFlow > 750.0)
				{
					PosCantSpawn[i] = true;
					continue;
				}
			}

			float GroundHighRecord = GroundPos[2];

			if (Spawn_Type2 == 1 && ToSpawnPos[2] - SurPos[2] > 220.0)
				continue;

			if (Spawn_Type2 == 2 && SurPos[2] - ToSpawnPos[2] > 110.0)
				continue;

			for (int z = 0; z < 2 ; z ++)
			{
				if (StSpawnPosNumber >= 36)
					break;

				if (z == 1 && Spawn_Type2 == 1)
					break;
				
				bool PosIsShould = true;
				
				if (z == 1)
				{
					ToSpawnPos[2] = SurPos[2] + 71.0;
					TR_TraceRay(ToSpawnPos, view_as<float>({90.0, 0.0, 0.0}), TRACE_RAY_FLAG, RayType_Infinite);
					if (TR_DidHit())
					{
						TR_GetEndPosition(GroundPos);
						ToSpawnPos = GroundPos;
						ToSpawnPos[2] += 20.0;
					}

					if (FloatAbs(GroundPos[2] - GroundHighRecord) < 10.0)
					{
						PosIsShould = false;
						break;
					}
				}

				if (!PosIsShould)
					break;

				if (ZombieClass != 4)
				{
					for (int j = 0; j < SpawnPos_RecordNumber ; j++)
					{
						if (GetVectorDistance(ToSpawnPos, SpawnPos_Record[j]) <= NearbySpawnDistance)
						{
							PosIsShould = false;
							break;
						}
					}
				}

				if (!PosIsShould)
					continue;

				if (!IsOnValidMesh(ToSpawnPos))
					continue;

				if (IsPlayerStuck(ToSpawnPos))
					continue;

				if (IsPlayerVisible(ToSpawnPos, false))
				{
					PosCantSpawn[i] = true;
					continue;
				}

				StSpawnPos[StSpawnPosNumber ++] = ToSpawnPos;
				PosCantSpawn[i] = true;
			}
		}
	}

	if (StSpawnPosNumber == 0)
		return false;
	else if (StSpawnPosNumber == 1)
	{
		for (int i = 0; i < 3 ; i++)
			ToSpawnPos[i] = StSpawnPos[0][i];
		return true;
	}
	else
	{
		int RSpawnPos_Select = GetRandomInt(1, StSpawnPosNumber);
		for (int i = 0; i < 3 ; i++)
			ToSpawnPos[i] = StSpawnPos[RSpawnPos_Select - 1][i];
		return true;
	}
}

// 复活特感
public bool SpawnInfected(float ToSpawnPos[3], int ZombieClass)
{
	int zombie = -1;
	zombie = SDKCall(SDK_CreateInfectedBot[ZombieClass - 1], Infected_Name[ZombieClass - 1]);

	if (zombie == -1)
		return false;

	InitializeSpecial(zombie, ToSpawnPos);
	return true;
}

// 是否能被生还者看见
public bool IsPlayerVisible(float ToSpawnPos[3], bool IsTeleport)
{
	float ToSpawnEyePos[3], SurPos[3];
	for (int i = 0; i < 3 ; i++)
		ToSpawnEyePos[i] = ToSpawnPos[i];

	ToSpawnEyePos[2] += 62.0;//眼睛位置

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, SurPos);

			// 太近直接返回看见
			if (GetVectorDistance(ToSpawnPos, SurPos) < (IsTeleport ? DefaultTPSpawnDistance : DefaultSpawnDistance))
				return true;

			// 太远视为看不见
			if (Get2DBoxDistance(ToSpawnPos, SurPos) > 1000.0)
				continue;

			// 是否能被看见
			if (L4D2_IsVisibleToPlayer(i, 2, 3, 0, ToSpawnPos) || L4D2_IsVisibleToPlayer(i, 2, 3, 0, ToSpawnEyePos))
				return true;
		}
	}
	return false;
}

// 判定位置是否为有效复位区域
public bool IsOnValidMesh(float OnePos[3])
{
	// 禁止复活位起点安全区和终点安全区内
	if (L4D_IsPositionInFirstCheckpoint(OnePos) || L4D_IsPositionInLastCheckpoint(OnePos))
		return false;

	Address TempNavArea = L4D2Direct_GetTerrorNavArea(OnePos);
	return TempNavArea != Address_Null; // 位置区域必须有效
}

// 判定位置是否会卡住客户端
public bool IsPlayerStuck(float ToSpawnPos[3])
{
	//似乎所有客户端的尺寸都一样
	static const float mincsize[3] = {-16.0, -16.0, 0.0};
	static const float maxcsize[3] = {16.0, 16.0, 72.0};

	static bool IsHit;
	static Handle TempTrace;

	TempTrace = TR_TraceHullFilterEx(ToSpawnPos, ToSpawnPos, mincsize, maxcsize, MASK_PLAYERSOLID, TraceFilter_Stuck);
	IsHit = TR_DidHit(TempTrace);

	delete TempTrace;
	return IsHit;
}

public bool EnvBlockType(int entity)
{
	int BlockType = GetEntProp(entity, Prop_Data, "m_nBlockType");
	return !(BlockType == 1 || BlockType == 2);
}





// ====================================================================================================
// TraceFilter Bool
// ====================================================================================================

public bool TraceFilter_Stuck(int entity, int contentsMask)
{
	if (entity <= MaxClients || !IsValidEntity(entity))
		return false;

	static char sClassName[20];
	GetEntityClassname(entity, sClassName, sizeof(sClassName));
	if (strcmp(sClassName, "env_physics_blocker") == 0 && !EnvBlockType(entity))
		return false;

	return true;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask, any data)
{
	return entity > MaxClients;
}