#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>

#define CVAR_FLAGS		FCVAR_NOTIFY

char FilePath[PLATFORM_MAX_PATH], FileLine[PLATFORM_MAX_PATH];

int ChargerChargingAttackNumber[32];
bool ChargerChargingAttack[32][32];
bool IsPrint[32];
bool IsCarrySurvivor[32];
bool IsReadyToCharge[32];

char TauntText[32][128];
int TauntTextNumber = 0;

char CText[32][13] =
{
	"零", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八",
	"十九", "二十", "二十一", "二十二", "二十三", "二十四", "二十五", "二十六", "二十七", "二十八", "二十九", "三十", "三十一"
};

bool TauntTextType[32];

char CText_01[32][128];
char CText_02[32][128];

int MinNumView = 2;
int MinNumTauntView = 3;

ConVar GMinNumView;
ConVar GMinNumTauntView;

public void OnPluginStart()
{
	SetRandomSeed(GetSysTickCount());

	GMinNumView				=  CreateConVar("l4d2_charger_manyatk_prompt_min_num",
											"2",
											"触发一撞多提示的最低人数.",
											CVAR_FLAGS, true, 2.0, true, 31.0);
	GMinNumTauntView		=  CreateConVar("l4d2_charger_manyatk_prompt_taunt_min_num",
											"3",
											"触发一撞多嘲讽提示的最低人数.",
											CVAR_FLAGS, true, 2.0, true, 31.0);
	
	GMinNumView.AddChangeHook(ConVarChanged);
	GMinNumTauntView.AddChangeHook(ConVarChanged);

	HookEvent("ability_use",				Event_AbilityUse);
	HookEvent("charger_carry_start",		Event_ChargeCarryStart);
	HookEvent("charger_carry_end",			Event_ChargeCarryEnd);
	HookEvent("player_hurt",				Event_PlayerHurt);
	HookEvent("player_death",				Event_PlayerDeath);
	HookEvent("player_spawn",				Event_PlayerSpawn);
	HookEvent("player_bot_replace",			Event_PlayerBotReplace);
	HookEvent("bot_player_replace",			Event_BotPlayerReplace);

	GetConfig();

	AutoExecConfig(true, "l4d2_charger_manyatk_prompt");
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
	MinNumView		= GMinNumView.IntValue;
	MinNumTauntView	= GMinNumTauntView.IntValue;
}





// ====================================================================================================
// Get Config
// ====================================================================================================

public void GetConfig()
{
	BuildPath(Path_SM, FilePath, sizeof(FilePath), "configs/l4d2_charger_manyatk_prompt.txt");
	if (FileExists(FilePath))
		GetTauntText();
}

public void GetTauntText()
{
	File file = OpenFile(FilePath, "rb");

	if (file)
	{
		while (!file.EndOfFile())
		{
			file.ReadLine(FileLine, sizeof(FileLine));
			TrimString(FileLine);

			if (strlen(FileLine) > 1 && FileLine[0] != '/' && TauntTextNumber < 32)
			{
				strcopy(TauntText[TauntTextNumber], sizeof(TauntText[]), FileLine);

				if (StrContains(TauntText[TauntTextNumber], "&CText") != -1)
				{
					char Buffers[2][128];
					ExplodeString(TauntText[TauntTextNumber], "&CText", Buffers, sizeof(Buffers), sizeof(Buffers[]));
					CText_01[TauntTextNumber] = Buffers[0];
					CText_02[TauntTextNumber] = Buffers[1];
					TauntTextType[TauntTextNumber] = true;
				}
				else
					TauntTextType[TauntTextNumber] = false;

				TauntTextNumber ++;
			}
		}
	}
	delete file;
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

public void Event_AbilityUse(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsCharger(client) || !IsPlayerAlive(client))
		return;

	IsPrint[client] = false;
	IsCarrySurvivor[client] = false;
	ChargerChargingAttackNumber[client] = 0;
	IsReadyToCharge[client] = true;

	for (int i = 1; i <= MaxClients ; i++)
		ChargerChargingAttack[client][i] = false;
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsSurvivor(client))
		return;

	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (!IsCharger(attacker) || !IsPlayerAlive(attacker) || (!ChargerIsCharging(attacker) && !IsReadyToCharge[attacker]))
		return;

	if (IsPrint[attacker] || !IsReadyToCharge[attacker] || ChargerChargingAttack[attacker][client])
	{
		return;
	}

	int Damage = event.GetInt("dmg_health");

	if (Damage < 1)
		return;

	ChargerChargingAttack[attacker][client] = true;
	ChargerChargingAttackNumber[attacker] ++;
}

public void Event_ChargeCarryStart(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsCharger(client) || !IsPlayerAlive(client))
		return;

	int victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (!IsSurvivor(victim) || !IsPlayerAlive(victim))
		return;

	IsCarrySurvivor[client] = true;

	if (ChargerChargingAttack[client][victim])
		return;

	ChargerChargingAttack[client][victim] = true;
	ChargerChargingAttackNumber[client] ++;
}

public void Event_ChargeCarryEnd(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsCharger(client) || !IsPlayerAlive(client) || IsPrint[client] || !IsCarrySurvivor[client])
		return;
	
	PrintCharger(client);
}

public void Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsCharger(client) || IsPrint[client] || !IsCarrySurvivor[client])
		return;

	PrintCharger(client);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsCharger(client))
		return;
	
	IsPrint[client] = false;
	IsCarrySurvivor[client] = false;
	IsReadyToCharge[client] = false;
}

public void Event_PlayerBotReplace(Event event, char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(event.GetInt("bot"));

	if (!IsSurvivor(bot) || !IsPlayerAlive(bot))
		return;

	int player = GetClientOfUserId(event.GetInt("player"));

	for (int i = 1; i <= MaxClients ; i++)
	{
		if (ChargerChargingAttack[i][player])
		{
			ChargerChargingAttack[i][player] = false;
			ChargerChargingAttack[i][bot] = true;
		}
	}
}

public void Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(event.GetInt("player"));

	if (!IsSurvivor(player) || !IsPlayerAlive(player))
		return;

	int bot = GetClientOfUserId(event.GetInt("bot"));

	for (int i = 1; i <= MaxClients ; i++)
	{
		if (ChargerChargingAttack[i][bot])
		{
			ChargerChargingAttack[i][bot] = false;
			ChargerChargingAttack[i][player] = true;
		}
	}
}





// ====================================================================================================
// void
// ====================================================================================================

public void PrintCharger(int client)
{
	IsReadyToCharge[client] = false;

	if (ChargerChargingAttackNumber[client] < MinNumView)
		return;
	
	if (IsFakeClient(client))
		PrintToChatAll("\x04[提示] \x05Charger(\x03AI\x05) \x01一撞\x04%s", CText[ChargerChargingAttackNumber[client]]);
	else
		PrintToChatAll("\x04[提示] \x05Charger(\x03%N\x05) \x01一撞\x04%s", client, CText[ChargerChargingAttackNumber[client]]);

	if (TauntTextNumber > 0 && ChargerChargingAttackNumber[client] >= MinNumTauntView)
	{
		int r = GetRandomInt(1, TauntTextNumber) - 1;

		if (TauntTextType[r])
			PrintToChatAll("\x05%s\x03%s\x05%s", CText_01[r], CText[ChargerChargingAttackNumber[client]], CText_02[r]);
		else
			PrintToChatAll("\x05%s", TauntText[r]);
	}
	
	IsPrint[client] = true;
}





// ====================================================================================================
// bool
// ====================================================================================================

public bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

public bool IsCharger(int client)  
{
	return (client > 0 &&
			client <= MaxClients &&
			IsClientInGame(client) &&
			GetClientTeam(client) == 3 &&
			GetEntProp(client, Prop_Send, "m_zombieClass") == 6);
}

public bool ChargerIsCharging(int charger)
{
	int AbilityEntity = GetEntPropEnt(charger, Prop_Send, "m_customAbility");
	return IsValidEdict(AbilityEntity) && GetEntProp(AbilityEntity, Prop_Send, "m_isCharging");
}