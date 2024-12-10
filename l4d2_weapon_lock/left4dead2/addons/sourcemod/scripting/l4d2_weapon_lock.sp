#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <l4d2util>
#include <colors>

#define CVAR_FLAGS		FCVAR_NOTIFY

#define VOTE_NO			"no"
#define VOTE_YES		"yes"

#define RIGHT_SOUND		"ui/alert_clink.wav"
#define ERROR_SOUND		"ui/beep_error01.wav"

float Vote_Success_Percent = 0.51;
Menu g_hVoteMenu;
char votesmaps[MAX_NAME_LENGTH];

bool Weapon_Lock = true;

char Weapon_String[37][24] =
{
	"Pistol",					// 0
	"Uzi",						// 1
	"Pump_Shotgun",				// 2
	"Auto_Shotgun",				// 3
	"M16",						// 4
	"Hunting_Rifle",			// 5
	"Smg",						// 6
	"Shotgun_Chrome",			// 7
	"Scar",						// 8
	"Sniper_Military",			// 9
	"Shotgun_Spas",				// 10
	"First_Aid_Kit",			// 11
	"Molotov",					// 12
	"Pipe_Bomb",				// 13
	"Pills",					// 14
	"No_Record",				// 15
	"No_Record",				// 16
	"No_Record",				// 17
	"Melee",					// 18
	"Chainsaw",					// 19
	"Grenade_Launcher",			// 20
	"No_Record",				// 21
	"Adrenaline",				// 22
	"Defibrillator",			// 23
	"Vomitjar",					// 24
	"AK47",						// 25
	"No_Record",				// 26
	"No_Record",				// 27
	"No_Record",				// 28
	"Upgrade_Ammo_Incendiary",	// 29
	"Upgrade_Ammo_Explosive",	// 30
	"Magnum",					// 31
	"MP5",						// 32
	"SG552",					// 33
	"AWP",						// 34
	"Scout",					// 35
	"M60"						// 36
};

char Weapon_Text[37][24] =
{
	"小手枪",
	"UZI",
	"木喷",
	"一代连喷",
	"M16步枪",
	"15连狙/木狙",
	"SMG",
	"铁喷",
	"SCAR/三连发",
	"30连狙",
	"二代连喷",
	"医疗包",
	"燃烧瓶",
	"土质炸弹",
	"止痛药",
	"无记录",
	"无记录",
	"无记录",
	"近战",
	"电锯",
	"榴弹发射器",
	"无记录",
	"肾上腺素",
	"除颤器",
	"胆汁罐",
	"AK47步枪",
	"无记录",
	"无记录",
	"无记录",
	"燃烧升级子弹包",
	"高爆升级子弹包",
	"马格南",
	"MP5",
	"SG552步枪",
	"AWP/大狙",
	"Scout/鸟狙",
	"M60"
};

char Weapon_Group_String[5][24] =
{
	"Group_SMG",				// 101
	"Group_ShotGun",			// 102
	"Group_Rifle",				// 103
	"Group_AutoShotGun",		// 104
	"Group_Sniper"				// 105
};

char Weapon_Group_Text[5][24] =
{
	"冲锋枪",
	"单喷",
	"步枪",
	"连喷",
	"狙击枪"
};

int Group_Weapon_Wepid[5][5] =
{
	{ 2,  7, 33,  0,  0},
	{ 3,  8,  0,  0,  0},
	{ 5,  9, 26, 34, 37},
	{ 4, 11,  0,  0,  0},
	{ 6, 10, 35, 36,  0}
};

ConVar GWeapon_Hold_Max[37];
ConVar GGroup_Weapon_Hold_Max[5];

int Weapon_Hold_Max[37];
int Weapon_Hold_Num[37];
int Group_Weapon_Hold_Max[5];
int Group_Weapon_Hold_Num[5];

int Survivor_Number = 0;
bool IsCheckPlayerNumber;

int Ammo_Give_Mode = 1;
bool Dynamic_Change = false;
bool Dynamic_Print = true;
bool Text_Print = true;
bool Sound_Print = true;
bool Sound_Print_Optimize = true;
bool IncludeDeadBot = true;

ConVar GAmmo_Give_Mode;
ConVar GDynamic_Change;
ConVar GDynamic_Print;
ConVar GText_Print;
ConVar GSound_Print;
ConVar GSound_Print_Optimize;
ConVar GIncludeDeadBot;

float RecordPos[32][3];
bool CanPlaySound[32];
bool IsUseU[32];

int Dynamic_Change_Data[42][32];
bool IsNeedDynamicChange[43];

char Path[PLATFORM_MAX_PATH], FileLine[PLATFORM_MAX_PATH];

public void OnPluginStart()
{
	for (int i = 0; i < 42 ; i++)
		IsNeedDynamicChange[i] = false;

	char ConVar_Text1[64], ConVar_Text2[64];
	for (int i = 0; i < 37 ; i++)
	{
		Weapon_Hold_Max[i] = -1;
		Weapon_Hold_Num[i] = 0;
		if (IsValidCI(i))
		{
			int x = (i + 1) / 10;
			int y = (i + 1) % 10;
			Format(ConVar_Text1, sizeof(ConVar_Text1), "l4d2_weapon_lock_%d_%d_%s", x, y, Weapon_String[i]);
			Format(ConVar_Text2, sizeof(ConVar_Text2), "%s 数量限制. (<0 = 无限制, 0 = 不可拾取)", Weapon_Text[i]);
			GWeapon_Hold_Max[i] = CreateConVar(ConVar_Text1, "-1", ConVar_Text2, CVAR_FLAGS);
		}
	}

	for (int i = 0; i < 5 ; i++)
	{
		Group_Weapon_Hold_Max[i] = -1;
		Group_Weapon_Hold_Num[i] = 0;
		Format(ConVar_Text1, sizeof(ConVar_Text1), "l4d2_weapon_lock_g%d_%s", i + 38, Weapon_Group_String[i]);
		Format(ConVar_Text2, sizeof(ConVar_Text2), "%s 数量限制. (<0 = 无限制, 0 = 不可拾取)", Weapon_Group_Text[i]);
		GGroup_Weapon_Hold_Max[i] = CreateConVar(ConVar_Text1, "-1", ConVar_Text2, CVAR_FLAGS);
	}

	GAmmo_Give_Mode			=  CreateConVar("l4d2_weapon_lock_z_ammo_give_mode",
											"1",
											"弹药给予模式.\n 0 = 禁用\n 1 = 仅不可拾取的主武器\n 2 = 主武器",
											CVAR_FLAGS, true, 0.0, true, 2.0);
	GDynamic_Change			=  CreateConVar("l4d2_weapon_lock_z_dynamic_change",
											"0",
											"启用武器数量限制随人数改变而动态改变. (0 = 禁用, 1 = 启用)",
											CVAR_FLAGS, true, 0.0, true, 1.0);
	GDynamic_Print			=  CreateConVar("l4d2_weapon_lock_z_dynamic_print",
											"1",
											"启用武器数量限制动态改变的文本提示. (0 = 禁用, 1 = 启用)",
											CVAR_FLAGS, true, 0.0, true, 1.0);
	GText_Print				=  CreateConVar("l4d2_weapon_lock_z_text_print",
											"1",
											"启用禁止拾取的文本提示. (0 = 禁用, 1 = 启用)",
											CVAR_FLAGS, true, 0.0, true, 1.0);
	GSound_Print			=  CreateConVar("l4d2_weapon_lock_z_sound_print",
											"1",
											"启用拾取武器的声音提示. (0 = 禁用, 1 = 启用)",
											CVAR_FLAGS, true, 0.0, true, 1.0);
	GSound_Print_Optimize	=  CreateConVar("l4d2_weapon_lock_z_sound_print_optimize",
											"1",
											"启用拾取武器的声音提示优化. (0 = 禁用, 1 = 启用)",
											CVAR_FLAGS, true, 0.0, true, 1.0);
	GIncludeDeadBot			=  CreateConVar("l4d2_weapon_lock_z_include_dead_bot",
											"1",
											"启用对死亡Bot的有效玩家计入. (0 = 死亡的Bot生还不计入有效人数, 1 = 计入)",
											CVAR_FLAGS, true, 0.0, true, 1.0);


	for (int i = 0; i < 37 ; i++)
	{
		if (IsValidCI(i))
			GWeapon_Hold_Max[i].AddChangeHook(ConVarChanged);
	}
	for (int i = 0; i < 5 ; i++)
		GGroup_Weapon_Hold_Max[i].AddChangeHook(ConVarChanged);

	GAmmo_Give_Mode.AddChangeHook(ConVarChanged);
	GDynamic_Change.AddChangeHook(ConVarChanged);
	GDynamic_Print.AddChangeHook(ConVarChanged);
	GText_Print.AddChangeHook(ConVarChanged);
	GSound_Print.AddChangeHook(ConVarChanged);
	GSound_Print_Optimize.AddChangeHook(ConVarChanged);
	GIncludeDeadBot.AddChangeHook(ConVarChanged);

	HookEvent("round_start",			Event_RoundStart,			EventHookMode_PostNoCopy);			// 回合开始
	HookEvent("player_team",			Event_PlayerTeam);												// 玩家转换队伍
	HookEvent("player_death",			Event_PlayerDeath);												// 玩家死亡
	HookEvent("player_spawn",			Event_PlayerSpawn);												// 玩家复活

	RegConsoleCmd("sm_wplimit",			Command_Weapon_Lock_Vote,	"武器限制开关投票.");
	RegConsoleCmd("sm_wpdata",			Command_Weapon_Data_Look,	"Look Weapon Lock Data.");
	RegConsoleCmd("sm_wpdatareload",	Command_Weapon_Data_Reload,	"Reload Weapon Lock Data.");

	// 获取配置文件
	GetWeaponLockConfigs();

	// 生成指定文件名的CFG
	AutoExecConfig(true, "l4d2_weapon_lock");
}

public void OnConfigsExecuted()
{
	GetWeaponLockConfigs();
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
	for (int i = 0; i < 37 ; i++)
	{
		if (IsValidCI(i))
			Weapon_Hold_Max[i] = GWeapon_Hold_Max[i].IntValue;
	}

	for (int i = 0; i < 5 ; i++)
		Group_Weapon_Hold_Max[i] = GGroup_Weapon_Hold_Max[i].IntValue;

	Ammo_Give_Mode			= GAmmo_Give_Mode.IntValue;
	Dynamic_Change			= GDynamic_Change.BoolValue;
	Dynamic_Print			= GDynamic_Print.BoolValue;
	Text_Print				= GText_Print.BoolValue;
	Sound_Print				= GSound_Print.BoolValue;
	Sound_Print_Optimize	= GSound_Print_Optimize.BoolValue;
	IncludeDeadBot			= GIncludeDeadBot.BoolValue;

	if (Dynamic_Change)
		Dynamic_Change_By_Survivor_Number(Survivor_Number, GetValidSurvivorNumber());
}





// ====================================================================================================
// Configs
// ====================================================================================================

public void GetWeaponLockConfigs()
{
	BuildPath(Path_SM, Path, sizeof(Path), "configs/l4d2_weapon_lock_dynamic_change.txt");
	if (FileExists(Path))
		GetDynamicChange();
}

public void GetDynamicChange()
{
	File file = OpenFile(Path, "rb");

	if (file)
	{
		for (int i = 0; i < 42 ; i++)
		{
			IsNeedDynamicChange[i] = false;
			for (int j = 0; j < 32 ; j++)
				Dynamic_Change_Data[i][j] = -1;
		}

		bool LoadGroup = false;
		bool NeedCustom = false;
		int Group_MyGid = -1;
		while (!file.EndOfFile())
		{
			file.ReadLine(FileLine, sizeof(FileLine));
			TrimString(FileLine);

			if (strlen(FileLine) > 1 && FileLine[0] != '/')
			{
				char Target_Str[12];
				strcopy(Target_Str, sizeof(Target_Str), FileLine);

				if (strcmp(Target_Str, "Group_MyGid") == 0)
				{
					char GStr[6] = "";
					for (int j = 12 ; j < strlen(FileLine) ; j++)
					{
						if (FileLine[j] >= '0' && FileLine[j] <= '9')
						{
							for (int k = j ; k < strlen(FileLine) ; k++)
							{
								if (k - j >= 6)
									break;
								if ((FileLine[k] < '0' || FileLine[k] > '9') && FileLine[k] != ' ')
									break;
								GStr[k - j] = FileLine[k];
							}
							break;
						}
					}

					if (strlen(GStr) > 0)
					{
						int TempI = StringToInt(GStr);
						if (TempI > 0 && TempI <= 42)
						{
							Group_MyGid = TempI - 1;
							LoadGroup = true;
							NeedCustom = false;
						}
					}
				}
				else if (LoadGroup)
				{
					if (strcmp(Target_Str, "Change_Rule") == 0)
					{
						char GStr[8] = "";
						bool NeedToFloat = false;
						for (int j = 12 ; j < strlen(FileLine) ; j++)
						{
							if ((FileLine[j] >= '0' && FileLine[j] <= '9') || FileLine[j] == '-')
							{
								for (int k = j ; k < strlen(FileLine) ; k++)
								{
									if (k - j >= 8)
										break;
									if ((FileLine[k] < '0' || FileLine[k] > '9') &&
										FileLine[k] != ' ' && FileLine[k] != '-' && FileLine[k] != '.')
									{
										break;
									}
									if (FileLine[k] == '.')
										NeedToFloat = true;
									GStr[k - j] = FileLine[k];
								}
								break;
							}
						}

						if (strlen(GStr) > 0)
						{
							if (NeedToFloat)
							{
								float TempF = StringToFloat(GStr);
								if (TempF > 0.0 && TempF < 1.0)
								{
									for (int j = 0; j < 32 ; j++)
										Dynamic_Change_Data[Group_MyGid][j] = RoundToFloor(float(j) * TempF);
									NeedCustom = false;
									LoadGroup = false;
								}
								else if (TempF >= 1.0)
								{
									float TempFF = TempF - float(RoundToFloor(TempF));
									for (int j = 0; j < 32 ; j++)
									{
										if (TempF < float(j + 1))
											Dynamic_Change_Data[Group_MyGid][j] = RoundToFloor(float(j) * TempFF);
									}
									NeedCustom = false;
									LoadGroup = false;
								}
							}
							else
							{
								int TempI = StringToInt(GStr);
								if (TempI < 0)
								{
									int TempData, LimitStart = 0;

									if (TempI < -100)
									{
										LimitStart = (TempI * -1) / 100;
										TempI += LimitStart * 100;
									}

									for (int j = 0; j < 32 ; j++)
									{
										if (j >= LimitStart)
										{
											TempData = j + TempI;
											Dynamic_Change_Data[Group_MyGid][j] = TempData < 0?0:TempData;
										}
									}
									NeedCustom = false;
								}
								else if (TempI == 0)
									NeedCustom = true;
								else
								{
									int FenZI = TempI / 100;
									int FenMu = TempI % 100;
									if (FenMu < 1)
										FenMu = 1;
									for (int j = 0; j < 32 ; j++)
										Dynamic_Change_Data[Group_MyGid][j] = (j + FenZI) / FenMu;
									NeedCustom = false;
								}
							}
							LoadGroup = false;
							IsNeedDynamicChange[Group_MyGid] = true;
						}
					}
				}
				else if (NeedCustom)
				{
					if (strcmp(Target_Str, "Custom_Data") == 0)
					{
						char GStr[128] = "";
						for (int j = 12 ; j < strlen(FileLine) ; j++)
						{
							if (FileLine[j] >= '0' && FileLine[j] <= '9')
							{
								for (int k = j ; k < strlen(FileLine) ; k++)
								{
									if (k - j >= 128)
										break;
									if ((FileLine[k] < '0' || FileLine[k] > '9') && FileLine[k] != ' ')
										break;
									GStr[k - j] = FileLine[k];
								}
								break;
							}
						}

						if (strlen(GStr) > 0)
						{
							char Buffers[32][4];
							ExplodeString(GStr, " ", Buffers, sizeof(Buffers), sizeof(Buffers[]));

							for (int j = 0; j < 32 ; j++)
							{
								if (strlen(Buffers[j]) > 0)
									Dynamic_Change_Data[Group_MyGid][j] = StringToInt(Buffers[j]);
								else
								{
									if (j > 0 && j < 32)
									{
										for (int k = j; k < 32 ; k++)
											Dynamic_Change_Data[Group_MyGid][k] = Dynamic_Change_Data[Group_MyGid][j - 1];
									}
									break;
								}
							}
							LoadGroup = false;
							NeedCustom = false;
						}
					}
				}
			}
		}
	}
	delete file;
}





// ====================================================================================================
// Game void
// ====================================================================================================

public void OnMapStart()
{
	PrecacheSound(RIGHT_SOUND, true);
	PrecacheSound(ERROR_SOUND, true);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUse);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_WeaponCanUse, WeaponCanUse);
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

// 回合开始
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	IsCheckPlayerNumber = false;
	for (int i = 1; i < 32 ; i++)
	{
		CanPlaySound[i] = true;
		IsUseU[i] = false;
		for (int j = 0; j < 3 ; j++)
			RecordPos[i][j] = 0.0;
	}
}

// 玩家转换队伍
public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	if (!Weapon_Lock)
		return;

	if (!Dynamic_Change)
		return;

	int old_team = event.GetInt("oldteam");
	int new_team = event.GetInt("team");

	if (old_team == new_team)
		return;

	if (old_team != 2 && new_team != 2)
		return;
	
	if (IsCheckPlayerNumber)
		return;

	IsCheckPlayerNumber = true;
	CreateTimer(0.4, CheckPlayerNumber, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.4, ReCold_Check, _, TIMER_FLAG_NO_MAPCHANGE);
}

// 玩家死亡
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!Weapon_Lock)
		return;
	
	if (!Dynamic_Change)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!CIsSurvivor(client))
		return;

	if (IsCheckPlayerNumber)
		return;
	
	IsCheckPlayerNumber = true;
	CreateTimer(0.2, CheckPlayerNumber, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, ReCold_Check, _, TIMER_FLAG_NO_MAPCHANGE);
}

// 玩家复活
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!Weapon_Lock)
		return;
	
	if (!Dynamic_Change)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!CIsSurvivor(client))
		return;

	if (IsCheckPlayerNumber)
		return;
	
	IsCheckPlayerNumber = true;
	CreateTimer(0.2, CheckPlayerNumber, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, ReCold_Check, _, TIMER_FLAG_NO_MAPCHANGE);
}





// ====================================================================================================
// Game Action
// ====================================================================================================

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3],
					int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (!Sound_Print)
		return Plugin_Continue;

	if (!Sound_Print_Optimize)
		return Plugin_Continue;

	if (!CIsSurvivor(client) || !IsPlayerAlive(client) || IsFakeClient(client))
		return Plugin_Continue;
	
	if (IsUseU[client])
		return Plugin_Continue;
	
	if (!CanPlaySound[client])
		return Plugin_Continue;
	
	if (buttons & IN_USE)
		IsUseU[client] = true;
	return Plugin_Continue;
}

public Action WeaponCanUse(int client, int weapon)
{
	if (!Weapon_Lock)
		return Plugin_Continue;
	
	if (!CIsSurvivor(client) || !IsPlayerAlive(client))
		return Plugin_Continue;

	int wepid			= IdentifyWeapon(weapon);
	int wep_slot		= GetSlotFromWeaponId(wepid);
	int player_weapon	= GetPlayerWeaponSlot(client, wep_slot);
	int player_wepid	= IdentifyWeapon(player_weapon);

	if (!IsValidCI(wepid - 1) || weapon == player_weapon)
		return Plugin_Continue;
	
	All_Player_Weapon_ReCount();

	bool Prohibit_Use = false, Number_Limit = false;
	bool NeedCheck = true;

	if (wepid == player_wepid &&
		wepid != 1 && wepid != 19 && wepid != 20 && wepid != 21 && wepid != 37)
	{
		NeedCheck = false;
	}

	if (Weapon_Hold_Max[wepid - 1] == 0)
	{
		Prohibit_Use = true;
		NeedCheck = false;
	}
	else if (Weapon_Hold_Max[wepid - 1] > 0 && Weapon_Hold_Num[wepid - 1] >= Weapon_Hold_Max[wepid - 1] && wepid != player_wepid)
	{
		Number_Limit = true;
		NeedCheck = false;
	}

	if (NeedCheck && wep_slot == 0)
	{
		for (int i = 0; i < 5 ; i++)
		{
			if (!NeedCheck)
				break;

			if (Group_Weapon_Hold_Max[i] >= 0)
			{
				for (int j = 0; j < 5; j++)
				{
					if (IsValidCI(Group_Weapon_Wepid[i][j] - 1))
					{
						if (wepid == Group_Weapon_Wepid[i][j])
						{
							if (Group_Weapon_Hold_Max[i] == 0)
							{
								Prohibit_Use = true;
								NeedCheck = false;
							}
							else if (Group_Weapon_Hold_Num[i] >= Group_Weapon_Hold_Max[i])
							{
								if (!IsValidCI(player_wepid - 1) ||
									(player_wepid != Group_Weapon_Wepid[i][0] &&
									player_wepid != Group_Weapon_Wepid[i][1] &&
									player_wepid != Group_Weapon_Wepid[i][2] &&
									player_wepid != Group_Weapon_Wepid[i][3] &&
									player_wepid != Group_Weapon_Wepid[i][4]))
								{
									Number_Limit = true;
									NeedCheck = false;
								}
							}
							break;
						}
					}
					else
						break;
				}
			}
		}
	}

	if (wep_slot == 0 && ((Ammo_Give_Mode == 1 && !NeedCheck) || Ammo_Give_Mode == 2))
	{
		if (Text_Print)
		{
			if (NeedCheck || (!Prohibit_Use && !Number_Limit))
				PrintHintText(client, "已拾取弹药.");
		}

		if (Sound_Print)
		{
			if (NeedCheck || (!Prohibit_Use && !Number_Limit))
				EmitSoundToClient(client, RIGHT_SOUND);
		}

		Give_Ammo(client);
	}

	if (!NeedCheck)
	{
		if (Text_Print)
		{
			if (Prohibit_Use)
				PrintHintText(client, "该武器已被锁定.");
			else if (Number_Limit)
				PrintHintText(client, "该武器数量已达到上限.");
		}
		
		if (Sound_Print && (Prohibit_Use || Number_Limit))
		{
			if (Sound_Print_Optimize)
			{
				if (CanPlaySound[client] && (DistanceLimitCanPlaySound(client) || IsUseU[client]))
				{
					IsUseU[client] = false;
					EmitSoundToClient(client, ERROR_SOUND);
					CanPlaySound[client] = false;
					CreateTimer(0.5, ReCold_CanPlaySound, client, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			else
				EmitSoundToClient(client, ERROR_SOUND);
		}

		return Plugin_Handled;
	}
	return Plugin_Continue;
}





// ====================================================================================================
// Command Action
// ====================================================================================================

public Action Command_Weapon_Lock_Vote(int client, int args)
{
	if (!CIsValidClientIndex(client) || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;
	
	if (GetClientTeam(client) != 2 && !bCheckClientAccess(client))
	{
		PrintToChat(client, "\x04[ERROR] \x03只有生还者允许进行此项投票.");
		return Plugin_Handled;
	}

	WPLOCKVoteMenu(client);
	return Plugin_Handled;
}

public Action Command_Weapon_Data_Look(int client, int args)
{
	if (bCheckClientAccess(client))
	{
		if (args == 1)
		{
			int arg = GetCmdArgInt(1);
			if (arg >= 0 && arg < 42)
			{
				PrintToChat(client, "%s", arg < 37?Weapon_Text[arg]:Weapon_Group_Text[arg - 37]);
				for (int i = 0; i < 32 ; i++)
					PrintToChat(client, "%d人 : %d", i, Dynamic_Change_Data[arg][i]);
			}
		}
	}
	else
		PrintToChat(client, "\x04[ERROR] \x03你无权使用该指令.");
	return Plugin_Handled;
}

public Action Command_Weapon_Data_Reload(int client, int args)
{
	if (bCheckClientAccess(client))
	{
		GetWeaponLockConfigs();
		Dynamic_Change_By_Survivor_Number(Survivor_Number, Survivor_Number);
		PrintToChat(client, "\x05[INFO] \x04Weapon Data is reload.");
	}
	else
		PrintToChat(client, "\x04[ERROR] \x03你无权使用该指令.");
	return Plugin_Handled;
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

public Action CheckPlayerNumber(Handle timer)
{
	if (!Weapon_Lock)
		return Plugin_Continue;
	
	if (!Dynamic_Change)
		return Plugin_Continue;

	int TPN = GetValidSurvivorNumber();
	if (TPN != Survivor_Number)
		Dynamic_Change_By_Survivor_Number(Survivor_Number, TPN);
	return Plugin_Continue;
}

public Action ReCold_Check(Handle timer)
{
	IsCheckPlayerNumber = false;
	return Plugin_Continue;
}

public Action ReCold_CanPlaySound(Handle timer, int client)
{
	CanPlaySound[client] = true;
	return Plugin_Continue;
}









// ====================================================================================================
// Vote
// ====================================================================================================

public void WPLOCKVoteMenu(int client)
{
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "\x04[提示]\x05已有投票在进行中.");
		return;
	}
	g_hVoteMenu = CreateMenu(Handler_VoteCallback, MENU_ACTIONS_ALL);
	SetMenuTitle(g_hVoteMenu, "投票%s 武器限制?", Weapon_Lock?"关闭":"开启", votesmaps);
	AddMenuItem(g_hVoteMenu, VOTE_YES, "同意");
	AddMenuItem(g_hVoteMenu, VOTE_NO, "反对");
	SetMenuExitButton(g_hVoteMenu, false);
	VoteMenuToAll(g_hVoteMenu, 20);
}

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
		VoteMenuClose();
	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
		PrintToChatAll("\x04[提示]\x05本次投票没有玩家投票.");
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
			if (Weapon_Lock)
				Weapon_Lock = false;
			else
				Weapon_Lock = true;

			PrintHintTextToAll("[提示] 投票通过, 已%s 武器限制.", Weapon_Lock?"开启":"关闭");
			PrintToChatAll("\x04[提示] \x05投票通过,已%s 武器限制.", Weapon_Lock?"开启":"关闭");
			PrintToChatAll("\x05< \x04同意 \x03%d \x04反对 \x03%d \x04合计 \x03%d \x04[ \x03%d %s \x04] \x05>"
							, votes, totalVotes - votes, totalVotes, TrueI, per);
		}
	}
	return 0;
}

public void VoteMenuClose()
{
	delete g_hVoteMenu;
}

public float GetVotePercent(int votes, int totalVotes)
{
	return float(votes) / float(totalVotes);
}





// ====================================================================================================
// void
// ====================================================================================================

public void All_Player_Weapon_ReCount()
{
	for (int i = 0; i < 37 ; i++)
		Weapon_Hold_Num[i] = 0;
	for (int i = 0; i < 5; i++)
		Group_Weapon_Hold_Num[i] = 0;

	int weapon[5];
	int wepid[5];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (CIsValidSurvivor(i) && IsPlayerAlive(i))
		{
			for (int j = 0; j < 5 ; j++)
			{
				weapon[j]	= GetPlayerWeaponSlot(i, j);
				wepid[j]	= IdentifyWeapon(weapon[j]);

				if (IsValidCI(wepid[j] - 1))
					Weapon_Hold_Num[wepid[j] - 1] ++;
			}

			for (int j = 0; j < 5; j++)
			{
				if (Group_Weapon_Hold_Max[j] >= 0)
				{
					for (int k = 0; k < 5 ; k++)
					{
						if (IsValidCI(Group_Weapon_Wepid[j][k] - 1))
						{
							if (wepid[0] == Group_Weapon_Wepid[j][k])
							{
								Group_Weapon_Hold_Num[j] ++;
								break;
							}
						}
						else
							break;
					}
				}
			}
		}
	}
}

public void Give_Ammo(int client)
{
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give ammo");
	SetCommandFlags("give", flags | FCVAR_CHEAT);
}

public void Dynamic_Change_By_Survivor_Number(int old_num, int new_num)
{
	if (!Dynamic_Change)
		return;

	if (Dynamic_Print)
		CPrintToChatAll("{olive}[WP_Lock] {blue}幸存者人数{default}: {orange}%d  {default}->  {orange}%d", old_num, new_num);
	for (int i = 0; i < 42 ; i++)
	{
		if (!IsNeedDynamicChange[i])
			continue;

		char OldData_String[11], NewData_String[11];
		int Old_Data = i < 37?Weapon_Hold_Max[i]:Group_Weapon_Hold_Max[i - 37];
		int New_Data = Dynamic_Change_Data[i][new_num];
		IntToString(Old_Data, OldData_String, sizeof(OldData_String));
		IntToString(New_Data, NewData_String, sizeof(NewData_String));
		if (Old_Data != New_Data)
		{
			if (Dynamic_Print)
			{
				CPrintToChatAll("{olive}[WP_Lock] {blue}%s{default}: {orange}%s {default}->  {orange}%s",
								i < 37?Weapon_Text[i]:Weapon_Group_Text[i - 37],
								Old_Data < 0?"无限制":(Old_Data == 0?"禁止拾取":OldData_String),
								New_Data < 0?"无限制":(New_Data == 0?"禁止拾取":NewData_String));
			}
			if (i < 37)
				Weapon_Hold_Max[i] = New_Data;
			else
				Group_Weapon_Hold_Max[i - 37] = New_Data;
		}
	}
	Survivor_Number = new_num;
}





// ====================================================================================================
// int
// ====================================================================================================

public int GetValidSurvivorNumber()
{
	int num = 0;
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (CIsValidSurvivor(i) && (!IsFakeClient(i) || IsPlayerAlive(i) || IncludeDeadBot))
			num ++;
	}
	return num;
}

/*public int GetWeaponSlot(int wepid)
{
	if ((wepid >= 2 && wepid <= 11) || wepid == 21 || wepid == 26 || (wepid >= 33 && wepid <= 37))
		return 0;
	else if (wepid == 1 || wepid == 19 || wepid == 20 || wepid == 32)
		return 1;
	else if (wepid == 13 || wepid == 14 || wepid == 25)
		return 2;
	else if (wepid == 12 || wepid == 24 || wepid == 30 || wepid == 31)
		return 3;
	else if (wepid == 15 || wepid == 23)
		return 4;
	return -1;
}*/





// ====================================================================================================
// bool
// ====================================================================================================

public bool CIsValidClientIndex(int client)
{
	return client > 0 && client <= MaxClients;
}

public bool CIsValidSurvivor(int client)
{
	return IsClientInGame(client) && GetClientTeam(client) == 2;
}

public bool CIsSurvivor(int client)
{
	return CIsValidClientIndex(client) && CIsValidSurvivor(client);
}

public bool IsValidCI(int CI)
{
	return (CI >= 0 &&
			CI < 37 &&
			(CI < 15 || CI > 17) &&
			CI != 21 &&
			(CI < 26 || CI > 28));
}

public bool DistanceLimitCanPlaySound(int client)
{
	if (RecordPos[client][0] == 0.0 && RecordPos[client][1] == 0.0 && RecordPos[client][2] == 0.0)
	{
		GetClientAbsOrigin(client, RecordPos[client]);
		return true;
	}

	float ClientPos[3];
	GetClientAbsOrigin(client, ClientPos);
	if (FloatAbs(ClientPos[0] - RecordPos[client][0]) > 20.0 || FloatAbs(ClientPos[1] - RecordPos[client][1]) > 20.0)
	{
		GetClientAbsOrigin(client, RecordPos[client]);
		return true;
	}
	return false;
}

// 判定玩家是否为管理员
public bool bCheckClientAccess(int client)
{
	if (GetUserFlagBits(client) & ADMFLAG_ROOT)
		return true;
	return false;
}