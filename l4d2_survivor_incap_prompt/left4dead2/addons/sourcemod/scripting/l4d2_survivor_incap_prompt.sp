#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <colors>

#define CVAR_FLAGS		FCVAR_NOTIFY

bool FallPT = true;
bool HangPT = true;
bool DeadPT = true;
ConVar GFallPT;
ConVar GHangPT;
ConVar GDeadPT;

char FilePath[PLATFORM_MAX_PATH], FileLine[PLATFORM_MAX_PATH];

char IncapText[3][64] =
{
	"被撅倒了, 要亲亲才能起来.",
	"老寒腿了, 要扶扶才能起来.",
	"被撅死了, 要电电才能起来."
};

char IncapString[3][5] =
{
	"Fall",
	"Hang",
	"Dead"
};

public void OnPluginStart()
{
	GFallPT		= CreateConVar("l4d2_sip_fall_prompt",	"1",	"启用幸存者倒地提示. (0 = 禁用, 1 = 启用)", CVAR_FLAGS, true, 0.0, true, 1.0);
	GHangPT		= CreateConVar("l4d2_sip_hang_prompt",	"1",	"启用幸存者挂边提示. (0 = 禁用, 1 = 启用)", CVAR_FLAGS, true, 0.0, true, 1.0);
	GDeadPT		= CreateConVar("l4d2_sip_dead_prompt",	"1",	"启用幸存者死亡提示. (0 = 禁用, 1 = 启用)", CVAR_FLAGS, true, 0.0, true, 1.0);

	GFallPT.AddChangeHook(ConVarChanged);
	GHangPT.AddChangeHook(ConVarChanged);
	GDeadPT.AddChangeHook(ConVarChanged);

	HookEvent("player_ledge_grab",			Event_PlayerLedgeGrab);			//玩家挂边.
	HookEvent("player_incapacitated",		Event_Incapacitate);			//玩家倒地.
	HookEvent("player_death",				Event_PlayerDeath);				//玩家死亡.

	AutoExecConfig(true, "l4d2_survivor_incap_prompt");//生成指定文件名的CFG.

	GetConfig();
}





// ====================================================================================================
// ConVarChanged
// ====================================================================================================

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

public void GetCvars()
{
	FallPT	= GFallPT.BoolValue;
	HangPT	= GHangPT.BoolValue;
	DeadPT	= GDeadPT.BoolValue;
}





// ====================================================================================================
// Get Config
// ====================================================================================================

public void GetConfig()
{
	BuildPath(Path_SM, FilePath, sizeof(FilePath), "configs/l4d2_survivor_incap_prompt_text.txt");
	if (FileExists(FilePath))
		IsSetIncapTextConfig();
}

public void IsSetIncapTextConfig()
{
	File file = OpenFile(FilePath, "rb");

	if (file)
	{
		while (!file.EndOfFile())
		{
			file.ReadLine(FileLine, sizeof(FileLine));
			TrimString(FileLine);

			if (strlen(FileLine) > 1 && FileLine[0] != '/')
			{
				char Target_Str[5];
				strcopy(Target_Str, sizeof(Target_Str), FileLine);

				for (int i = 0 ; i < 3 ; i++)
				{
					if (strcmp(Target_Str, IncapString[i]) == 0)
					{
						int loc_start = -1, loc_end = -1;
						for (int j = 5; j < strlen(FileLine) ; j++)
						{
							if (FileLine[j] == '\"')
							{
								if (loc_start == -1)
									loc_start = j + 1;
								else
								{
									loc_end = j;
									break;
								}
							}
						}

						if (loc_start > 0 && loc_end > 0 && loc_start < loc_end)
						{
							char Get_Str[64];
							for (int j = loc_start ; j < loc_end ; j++)
								Get_Str[j - loc_start] = FileLine[j];

							Format(IncapText[i], sizeof(IncapText[]), "%s", Get_Str);
						}
						break;
					}
				}
			}
		}
	}

	delete file;
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

//玩家挂边.
public void Event_PlayerLedgeGrab(Event event, const char[] name, bool dontBroadcast)
{
	if (!HangPT)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsSurvivor(client))
		return;
	
	CreateTimer(0.3, PrintText, client);
}

//玩家倒地.
public void Event_Incapacitate(Event event, const char[] name, bool dontBroadcast)
{
	if (!FallPT)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsSurvivor(client))
		return;
	
	CreateTimer(0.3, PrintText, client);
}

//玩家死亡.
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!DeadPT)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsSurvivor(client))
		return;
	
	CreateTimer(0.3, PrintText, client);
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

public Action PrintText(Handle timer, int client)
{
	if (!IsSurvivor(client))
		return Plugin_Continue;
	
	if (IsPlayerAlive(client))
	{
		if (IsPlayerFallen(client))
			CPrintToChatAll("{orange}[提示] {blue}%N {olive}%s", client, IncapText[0]);
		else if (IsPlayerFalling(client))
			CPrintToChatAll("{orange}[提示] {blue}%N {olive}%s", client, IncapText[1]);
	}
	else
		CPrintToChatAll("{orange}[提示] {blue}%N {olive}%s", client, IncapText[2]);

	return Plugin_Continue;
}





// ====================================================================================================
// bool
// ====================================================================================================

public bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

public bool IsPlayerFalling(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") && GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

public bool IsPlayerFallen(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}