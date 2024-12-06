#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#include <colors>

bool PlayerIsReady[32];
bool IsShould[32];
bool IsReady, ToReady, CutReady, IsCheck;
bool IsHideHUD[32], IsLockWalk[32];
int rs_ci = 0;
float PosRecord[32][3];
bool PosIsRecord[32];
bool IsHaveSafeArea;
bool GameStart = true;
float TP_GameTimer[32];

char rWeekName[7][3] = {"一", "二", "三", "四", "五", "六", "日"};
char Mapname[64];

public void OnPluginStart()
{
	HookEvent("round_start",			Event_RoundStart,		EventHookMode_PostNoCopy);
	HookEvent("round_end",				Event_RoundEnd,			EventHookMode_PostNoCopy);
	HookEvent("player_team",			Event_PlayerTeam);
	HookEvent("player_spawn",			Event_PlayerSpawn);
	HookEvent("player_bot_replace",		Event_PlayerBotReplace);
	HookEvent("bot_player_replace",		Event_BotPlayerReplace);

	RegConsoleCmd("sm_ready",		Command_Ready,			"开局准备.");
	RegConsoleCmd("sm_r",			Command_Ready,			"开局准备.");
	RegConsoleCmd("sm_unready",		Command_UnReady,		"取消准备.");
	RegConsoleCmd("sm_ur",			Command_UnReady,		"取消准备.");
	RegConsoleCmd("sm_readyhud",	Command_ReadyHUD_OC,	"打开/隐藏Ready HUD.");
}





// ====================================================================================================
// Game void
// ====================================================================================================

// 地图开始
public void OnMapStart()
{
	GetCurrentMap(Mapname, sizeof(Mapname));
}

// 地图结束
public void OnMapEnd()
{
	GameStart = true;
}

// 玩家离开.
public void OnClientDisconnect(int client)
{
	if (IsReady)
		return;

	if (IsFakeClient(client))
		return;

	if (PlayerIsReady[client])
		PlayerIsReady[client] = false;
	else
	{
		if (!IsCheck)
		{
			IsCheck = true;
			CreateTimer(0.3, RPD);
		}
	}
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!GameStart)
		return;

	IsReady = false;
	ToReady = false;
	CutReady = false;
	IsCheck = false;
	GameStart = false;
	IsHaveSafeArea = true;

	for (int i = 1; i <= MaxClients ; i++)
	{
		PlayerIsReady[i] = false;
		IsShould[i] = true;
		PosIsRecord[i] = false;
		IsHideHUD[i] = false;
		IsLockWalk[i] = false;
		TP_GameTimer[i] = 0.0;
	}
	CreateTimer(1.0, CT);
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	OnMapEnd();
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	if (IsReady)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));		//获取要转换队伍的玩家id
	int old_team = event.GetInt("oldteam");						//获取玩家当前的队伍
	int new_team = event.GetInt("team");						//获取玩家要转换的队伍

	if (new_team < 2 && old_team >= 2)
	{
		if (!IsCheck)
		{
			IsCheck = true;
			CreateTimer(0.5, RPD);
		}

		if (!IsHaveSafeArea && IsLockWalk[client])
			SetEntityMoveType(client, MOVETYPE_WALK);
	}
	PlayerIsReady[client] = false;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (IsReady)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (IsInfected(client))
	{
		if (IsFakeClient(client))
			KickClient(client);
		else
			ForcePlayerSuicide(client);
	}
}

public void Event_PlayerBotReplace(Event event, char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(event.GetInt("bot"));

	if (!IsSurvivor(bot) || !IsPlayerAlive(bot))
		return;

	int player = GetClientOfUserId(event.GetInt("player"));

	if (PosIsRecord[player])
	{
		for (int i = 0; i < 3 ; i++)
			PosRecord[bot][i] = PosRecord[player][i];
		PosIsRecord[bot] = true;
		PosIsRecord[player] = false;
	}
	PlayerIsReady[bot] = false;
	PlayerIsReady[player] = false;
}

public void Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(event.GetInt("player"));

	if (!IsSurvivor(player) || !IsPlayerAlive(player))
		return;

	int bot = GetClientOfUserId(event.GetInt("bot"));

	if (PosIsRecord[bot])
	{
		for (int i = 0; i < 3 ; i++)
			PosRecord[player][i] = PosRecord[bot][i];
		PosIsRecord[player] = true;
		PosIsRecord[bot] = false;
	}
	PlayerIsReady[player] = false;
	PlayerIsReady[bot] = false;
}





// ====================================================================================================
// Game Action
// ====================================================================================================

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (IsReady)
		return Plugin_Continue;
	
	if (!IsInGameClient(client) || IsFakeClient(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
		return Plugin_Continue;
	
	if (!IsShould[client])
		return Plugin_Continue;
	
	if ((buttons & IN_SPEED) && (buttons & (IN_USE | IN_RELOAD | IN_FORWARD | IN_BACK)))
	{
		IsShould[client] = false;
		CreateTimer(1.0, ReCold_GiveWeapon, client);
		L4D_RemoveWeaponSlot(client, view_as<L4DWeaponSlot>(0));
		if (buttons & IN_USE)
			Give_Client_WP(client, 1);
		else if (buttons & IN_RELOAD)
			Give_Client_WP(client, 2);
		else if (buttons & IN_FORWARD)
			Give_Client_WP(client, 3);
		else if (buttons & IN_BACK)
			Give_Client_WP(client, 4);
	}
	return Plugin_Continue;
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	if (IsReady)
		return Plugin_Continue;
	
	if (!IsSurvivor(client) || !IsPlayerAlive(client))
		return Plugin_Continue;
	
	if (PosIsRecord[client])
		TP(client, PosRecord[client]);
	else
		TP_OtherInSaferoomClient(client);

	float GameTimer = GetGameTime();
	if (GameTimer - TP_GameTimer[client] > 0.05)
	{
		if (GameTimer - TP_GameTimer[client] < 0.1)
		{
			IsHaveSafeArea = false;
			for (int i = 1; i <= MaxClients ; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsValidEntity(i))
				{
					IsLockWalk[i] = true;
					SetEntityMoveType(i, MOVETYPE_NONE);
				}
			}
		}
		TP_GameTimer[client] = GameTimer;
	}
	return Plugin_Handled;
}





// ====================================================================================================
// Command Action
// ====================================================================================================

// 准备
public Action Command_Ready(int client, int args)
{
	if (IsReady || !IsInGameClient(client) || IsFakeClient(client))
		return Plugin_Handled;
	
	int myteam = GetClientTeam(client);

	if (myteam < 2 || myteam > 3)
		return Plugin_Handled;

	if (PlayerIsReady[client])
		return Plugin_Handled;
	
	PlayerIsReady[client] = true;

	int readynum = GetReadyNum();
	int playernum = GetPlayerNum(0);

	switch (myteam)
	{
		case 2 :
		{
			CPrintToChatAll("{olive}[Ready] {blue}%N {default}已经准备. {orange}[ {olive}%d {orange}/ {olive}%d {orange}]",
							client, readynum, playernum);
		}
		case 3 :
		{
			CPrintToChatAll("{olive}[Ready] {red}%N {default}已经准备. {orange}[ {olive}%d {orange}/ {olive}%d {orange}]",
							client, readynum, playernum);
		}
	}

	if (readynum >= playernum)
		GetReadyToPlayGame();
	else
		PrintHintText(client, "你已经准备, 输入 !unready 或者 !ur 可取消准备.");

	return Plugin_Handled;
}

// 取消准备
public Action Command_UnReady(int client, int args)
{
	if (IsReady || !IsInGameClient(client) || IsFakeClient(client))
		return Plugin_Handled;
	
	int myteam = GetClientTeam(client);

	if (myteam < 2 || myteam > 3)
		return Plugin_Handled;
	
	if (!PlayerIsReady[client])
		return Plugin_Handled;
	
	if (IsReady && (!ToReady || CutReady))
		return Plugin_Handled;

	PlayerIsReady[client] = false;

	int readynum = GetReadyNum();
	int playernum = GetPlayerNum(0);

	switch (myteam)
	{
		case 2 :
		{
			CPrintToChatAll("{olive}[Ready] {blue}%N {default}取消了准备. {orange}[ {olive}%d {orange}/ {olive}%d {orange}]",
							client, readynum, playernum);
		}
		case 3 :
		{
			CPrintToChatAll("{olive}[Ready] {red}%N {default}取消了准备. {orange}[ {olive}%d {orange}/ {olive}%d {orange}]",
							client, readynum, playernum);
		}
	}

	PrintHintText(client, "您已取消准备, 输入 !ready 或者 !r 重新准备.");

	if (IsReady)
	{
		IsReady = false;
		ToReady = false;
		CutReady = true;
		ReadyConfig(true);
		CreateTimer(3.5, ReCold_CutReady, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Handled;
}

// 打开/隐藏 Ready HUD
public Action Command_ReadyHUD_OC(int client, int args)
{
	if (!IsInGameClient(client) || IsFakeClient(client))
		return Plugin_Handled;
	
	IsHideHUD[client] = !IsHideHUD[client];
	PrintToChat(client, "\x04[提示] \x05你已%sReady HUD显示.", IsHideHUD[client] ? "隐藏" : "开启");
	return Plugin_Handled;
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

// 创建计时器
public Action CT(Handle timer)
{
	CreateTimer(1.0, RT, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

// 显示准备HUD
public Action RT(Handle timer)
{
	if (GameStart)
		return Plugin_Stop;

	Ready_HUD_view();
	return Plugin_Continue;
}

// 检测是否全部准备
public Action RPD(Handle timer)
{
	if (!IsReady)
		Ready_PD();
	IsCheck = false;
	return Plugin_Continue;
}

// 播放准备音效
public Action ReadySound(Handle timer)
{
	if (ToReady)
	{
		PrintHintTextToAll("Game Ready : %d", 3 - rs_ci);
		rs_ci ++;
		EmitSoundToAll("ui/beep07.wav");
	}
	return Plugin_Continue;
}

// 开始游戏
public Action PlayGame(Handle timer)
{
	if (ToReady)
	{
		for (int i = 1; i <= MaxClients ; i++)
		{
			if (IsValidEntity(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
				SetEntityMoveType(i, MOVETYPE_WALK);
		}
		PrintHintTextToAll("Game begins!");
		EmitSoundToAll("ui/survival_playerrec.wav");
		GameStart = true;
	}
	return Plugin_Continue;
}

// 重置中断准备
public Action ReCold_CutReady(Handle timer)
{
	CutReady = false;
	return Plugin_Continue;
}

// 重置给予T1武器许可
public Action ReCold_GiveWeapon(Handle timer, int client)
{
	IsShould[client] = true;
	return Plugin_Continue;
}





// ====================================================================================================
// TP
// ====================================================================================================

public void TP(int client, float TPPos[3])
{
	ForceCrouch(client);
	TeleportEntity(client, TPPos, NULL_VECTOR, NULL_VECTOR);
}

public void ForceCrouch(int client)
{
	SetEntProp(client, Prop_Send, "m_bDucked", 1);
	SetEntProp(client, Prop_Send, "m_fFlags", GetEntProp(client, Prop_Send, "m_fFlags")|FL_DUCKING);
}





// ====================================================================================================
// Ready HUD
// ====================================================================================================

// 显示HUD
public void Ready_HUD_view()
{
	if (IsReady)
		return;

	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsValidEntity(i))
		{
			if (!PosIsRecord[i])
			{
				GetClientAbsOrigin(i, PosRecord[i]);
				PosIsRecord[i] = true;
			}
		}
	}

	Panel menuPanel = new Panel();

	// Ready HUD
	menuPanel.DrawText("▶ Ready HUD  v1.1");

	// 服务器名称
	char cHostName[64];
	static ConVar gHostName;
	if (!gHostName)
		gHostName = FindConVar("hostname");
	gHostName.GetString(cHostName, sizeof(cHostName));
	Format(cHostName, sizeof(cHostName), "▶ %s", cHostName);
	if (GetPlayerNum(2) < GetSurvivorNum())
		Format(cHostName, sizeof(cHostName), "%s  [缺人]", cHostName);
	menuPanel.DrawText(cHostName);

	// 服务器游玩人数
	char PlayerNumber_Name[32];
	Format(PlayerNumber_Name, sizeof(PlayerNumber_Name), "▶ 人数 : %d / %d", GetPlayers(), GetMaxPlayers());
	menuPanel.DrawText(PlayerNumber_Name);

	// 地图信息
	char Map_Name[64];
	GetCurrentMap(Map_Name, sizeof(Map_Name));
	Format(Map_Name, sizeof(Map_Name), "▶ 地图 : %s  [ %d / %d ]", Map_Name, L4D_GetCurrentChapter(), L4D_GetMaxChapters());
	menuPanel.DrawText(Map_Name);

	// 实际时间
	char sDate[3][128], sInfo[256], sTime[256];
	FormatTime(sDate[0], sizeof(sDate[]), "%Y-%m-%d");
	FormatTime(sDate[1], sizeof(sDate[]), "%H:%M:%S");
	Format(sDate[2], sizeof(sDate[]), "周%s", IsWeekName());
	ImplodeStrings(sDate, sizeof(sDate), " ", sInfo, sizeof(sInfo));//打包字符串.
	Format(sTime, sizeof(sTime), "%s%s", sInfo, GetAddSpacesMax(3, " "));
	Format(sTime, sizeof(sTime), "▶ 时间 : %s", sTime);
	menuPanel.DrawText(sTime);

	menuPanel.DrawText(" ");

	char name_text[48];

	if (GetPlayerNum(2) > 0)
		menuPanel.DrawItem("生还者:");

	// 生还者
	for (int i = 1; i <= MaxClients ; i ++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			if (!IsFakeClient(i))
			{
				Format(name_text, sizeof(name_text), PlayerIsReady[i] ? "★  %N" : "☆  %N", i);
				menuPanel.DrawText(name_text);
			}
			else if (IsFakeClient(i) && IsClientIdle(i) > 0)
			{
				Format(name_text, sizeof(name_text), "☆  %N  [AFK]", IsClientIdle(i));
				menuPanel.DrawText(name_text);
			}
		}
	}

	if (GetPlayerNum(3) > 0)
	{
		menuPanel.DrawText(" ");
		menuPanel.DrawItem("感染者:");
	}

	// 被感染者
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && !IsFakeClient(i))
		{
			Format(name_text, sizeof(name_text), PlayerIsReady[i] ? "★  %N\n" : "☆  %N\n", i);
			menuPanel.DrawText(name_text);
		}
	}

	// 旁观者显示
	int spe_num = 0;
	for (int i = 1; i <= MaxClients ; i ++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 1 && iGetBotOfIdlePlayer(i) == 0)
			spe_num ++;
	}
	if (spe_num > 3)
	{
		menuPanel.DrawText(" ");
		menuPanel.DrawItem("旁观者:");
		menuPanel.DrawText("** Many **");
	}
	else if (spe_num > 0)
	{
		menuPanel.DrawText(" ");
		menuPanel.DrawItem("旁观者:");
		for (int i = 1; i <= MaxClients ; i ++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 1 && iGetBotOfIdlePlayer(i) == 0)
			{
				GetClientName(i, name_text, sizeof(name_text));
				menuPanel.DrawText(name_text);
			}
		}
	}

	menuPanel.DrawText(" ");
	// 已准备人数和需要准备的总人数
	char ReadyNum_Name[48];
	Format(ReadyNum_Name, sizeof(ReadyNum_Name), "▶ 当前已准备人数: %d / %d", GetReadyNum(), GetPlayerNum(0));
	menuPanel.DrawText(ReadyNum_Name);
	menuPanel.DrawText("▶ 指令: !ready(!r)  !unready(!ur)  !readyhud");
	menuPanel.DrawText("▶ 组键: Shift + W[木喷] / S[铁喷] / E[UZI] / R[SMG]");

	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && !IsHideHUD[i])
			menuPanel.Send(i, DummyHandler, 1);
	}
	delete menuPanel;
}

public int DummyHandler(Handle menu, MenuAction action, int param1, int param2)
{
	return 1;
}





// ====================================================================================================
// void
// ====================================================================================================

// 检测是否准备完成
public void Ready_PD()
{
	if (GetPlayerNum(2) > 0 && GetReadyNum() >= GetPlayerNum(0))
		GetReadyToPlayGame();
}

// 准备开始游戏
public void GetReadyToPlayGame()
{
	IsReady = true;
	ToReady = true;
	rs_ci = 0;
	ReadyConfig(false);
	CreateTimer(0.1, ReadySound);
	CreateTimer(1.1, ReadySound);
	CreateTimer(2.1, ReadySound);
	CreateTimer(3.1, PlayGame);
}

// 准备与中断准备控制
public void ReadyConfig(bool IsCut)
{
	if (!IsHaveSafeArea)
		return;

	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsValidEntity(i))
		{
			if (IsCut)
				SetEntityMoveType(i, MOVETYPE_WALK);
			else
			{
				if (PosIsRecord[i])
					TP(i, PosRecord[i]);
				SetEntityMoveType(i, MOVETYPE_NONE);
			}
		}
	}
}

// 传送玩家至其他玩家(位于安全区域内)
public void TP_OtherInSaferoomClient(int client)
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (i != client && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && PosIsRecord[i])
		{
			float TP_Pos[3];
			GetClientAbsOrigin(i, TP_Pos);
			TP(client, TP_Pos);
			break;
		}
	}
}

// 给予玩家T1武器
public void Give_Client_WP(int client, int wp_type)
{
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	switch (wp_type)
	{
		case 1 :
			FakeClientCommand(client, "give smg");
		case 2 :
			FakeClientCommand(client, "give smg_silenced");
		case 3 :
			FakeClientCommand(client, "give pumpshotgun");
		case 4 :
			FakeClientCommand(client, "give shotgun_chrome");
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}





// ====================================================================================================
// int
// ====================================================================================================

// 获取各队伍玩家数量
public int GetPlayerNum(int cteam)
{
	int num = 0;
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) >= 2 && (!IsFakeClient(i) || IsClientIdle(i) > 0))
		{
			if (cteam == 0 || GetClientTeam(i) == cteam)
				num ++;
		}
	}
	return num;
}

// 获取存活的幸存者数量
public int GetSurvivorNum()
{
	int num = 0;
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			num ++;
	}
	return num;
}

// 获取非电脑玩家数量
public int GetPlayers()
{
	int num = 0;
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			num ++;
	}
	return num;
}

// 获取已准备的人数
public int GetReadyNum()
{
	int num = 0;
	for (int i = 1; i <= MaxClients; i ++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) >= 2 && !IsFakeClient(i) && PlayerIsReady[i])
			num ++;
	}
	return num;
}

// 获取服务器最大玩家数量
public int GetMaxPlayers()
{
	static ConVar GMaxPlayers;
	GMaxPlayers = FindConVar("sv_maxplayers");
	if (GMaxPlayers == null || GMaxPlayers.IntValue < 0)
		return MaxClients;
	
	return GMaxPlayers.IntValue;
}

// 获取闲置玩家对应的电脑.
public int iGetBotOfIdlePlayer(int client)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2 && IsClientIdle(i) == client)
			return i;
	}
	return 0;
}

// 获取电脑幸存者对应的玩家.
public int IsClientIdle(int client)
{
	if (!HasEntProp(client, Prop_Send, "m_humanSpectatorUserID"))
		return 0;

	return GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));
}





// ====================================================================================================
// char
// ====================================================================================================

//获取实际周几
char[] IsWeekName()
{
	char sWeek[8];
	FormatTime(sWeek, sizeof(sWeek), "%u");
	return rWeekName[StringToInt(sWeek) - 1];
}

//填入对应数量的内容.
char[] GetAddSpacesMax(int Value, char[] sContent)
{
	char g_sBlank[64];
	
	if(Value > 0)
	{
		char g_sFill[32][64];
		if(Value > sizeof(g_sFill))
			Value = sizeof(g_sFill);
		for (int i = 0; i < Value; i++)
			strcopy(g_sFill[i], sizeof(g_sFill[]), sContent);
		ImplodeStrings(g_sFill, sizeof(g_sFill), "", g_sBlank, sizeof(g_sBlank));//打包字符串.
	}
	return g_sBlank;
}





// ====================================================================================================
// bool
// ====================================================================================================

public bool IsInGameClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

public bool IsSurvivor(int client)
{
	return IsInGameClient(client) && GetClientTeam(client) == 2;
}

public bool IsInfected(int client)
{
	return IsInGameClient(client) && GetClientTeam(client) == 3;
}