#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

char TankDamage_RecordText[128];

int Tank_DefHealth[32];
float Tank_SpawnTimer[32];
float Tank_AliveTimer[32];

int TakeTankDamage[32][32];
int GetTankDamage[32][32];
int Fist_Hit[32][32];
int Stone_Hit[32][32];
int Iron_Hurt[32][32];

bool Can_IronHurt[32];

public void OnPluginStart()
{
	HookEvent("round_start",	Event_RoundStart,		EventHookMode_PostNoCopy);		// 回合开始
	HookEvent("tank_spawn",     Event_TankSpawn);										// Tank生成
	HookEvent("player_hurt",	Event_PlayerHurt);										// 玩家受伤
	HookEvent("player_death",	Event_PlayerDeath);										// 玩家死亡
}





// ====================================================================================================
// Take Damage
// ====================================================================================================

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype,
						int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!IsTank(attacker))
		return Plugin_Continue;

	if (!IsSurvivor(client))
		return Plugin_Continue;

	char sClassName[20];
	GetEdictClassname(inflictor, sClassName, sizeof(sClassName));
	if (strcmp("weapon_tank_claw", sClassName) == 0)
		Fist_Hit[client][attacker] ++;
	else if (strcmp("tank_rock", sClassName) == 0)
		Stone_Hit[client][attacker] ++;
	else if (damage > 20.0)
	{
		if (Can_IronHurt[client])
		{
			Can_IronHurt[client] = false;
			CreateTimer(0.5, ReCold_Can_IronHurt, client, TIMER_FLAG_NO_MAPCHANGE);
			Iron_Hurt[client][attacker] ++;
		}
	}

	return Plugin_Continue;
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

// 回合开始
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		for (int j = 1; j <= MaxClients ; j++)
		{
			TakeTankDamage[i][j] = 0;
			GetTankDamage[i][j] = 0;
			Fist_Hit[i][j] = 0;
			Stone_Hit[i][j] = 0;
			Iron_Hurt[i][j] = 0;
		}
	}
}

// Tank生成
public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsTank(client))
	{
		Tank_SpawnTimer[client] = GetGameTime();
		CreateTimer(1.5, Get_Tank_DefHealth, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

// 玩家受伤
public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client		= GetClientOfUserId(event.GetInt("userid"));
	int attacker	= GetClientOfUserId(event.GetInt("attacker"));
	int iDmg		= event.GetInt("dmg_health");

	if (iDmg > 0)
	{
		if (IsTank(attacker) && IsSurvivor(client))
			GetTankDamage[client][attacker] += iDmg;
		else if (IsSurvivor(attacker) && IsTank(client) && IsPlayerAlive(client))
		{
			int TankHurtSum = HurtSum(client);
			if (TankHurtSum < Tank_DefHealth[client])
			{
				int TempI = iDmg;
				if (TempI > (Tank_DefHealth[client] - TankHurtSum))
					TempI = Tank_DefHealth[client] - TankHurtSum;

				TakeTankDamage[attacker][client] += TempI;
			}
		}
	}
}

// 玩家死亡
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsTank(client))
		return;
	
	if (HurtSum(client) > 250)
	{
		Tank_AliveTimer[client] = GetGameTime() - Tank_SpawnTimer[client];
		CreateTimer(1.0, TankDeathPrint, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

public Action Get_Tank_DefHealth(Handle timer, int tank)
{
	if (!IsTank(tank) || !IsPlayerAlive(tank))
		return Plugin_Continue;

	Tank_DefHealth[tank] = GetClientHealth(tank);
	return Plugin_Continue;
}

public Action ReCold_Can_IronHurt(Handle timer, int client)
{
	Can_IronHurt[client] = false;
	return Plugin_Continue;
}

public Action TankDeathPrint(Handle timer, int Tank)
{
	Tank_dmg_print(Tank);
	return Plugin_Continue;
}





// ====================================================================================================
// void
// ====================================================================================================

public void Tank_dmg_print(int Tank)
{
	int Join_Number = 0;
	int List_Client[32];

	char text[128];

	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			if (TakeTankDamage[i][Tank] > 0 ||
				GetTankDamage[i][Tank] > 0 ||
				Fist_Hit[i][Tank] > 0 ||
				Stone_Hit[i][Tank] > 0 ||
				Iron_Hurt[i][Tank] > 0)
			{
				List_Client[Join_Number] = i;
				Join_Number ++;
			}
		}
	}

	int TempI;
	for (int i = 0; i < Join_Number - 1 ; i++)
	{
		for (int j = Join_Number - 1; j > i ; j --)
		{
			if (TakeTankDamage[List_Client[j]][Tank] > TakeTankDamage[List_Client[j - 1]][Tank])
			{
				TempI				= List_Client[j];
				List_Client[j]		= List_Client[j - 1];
				List_Client[j - 1]	= TempI;
			}
		}
	}

	int GetAliveTimer = RoundToCeil(Tank_AliveTimer[Tank]);
	PrintToChatAll("\x03<------- Tank局伤害播报 ------->");
	Format(text, sizeof(text), "Tank存活时间 : %d 分 %d 秒 [Default Health : %d]",
				(GetAliveTimer / 60), (GetAliveTimer % 60), Tank_DefHealth[Tank]);
	PrintToChatAll("\x05%s", text);
	SaveMessage(text);
	for (int i = 0; i < Join_Number ; i++)
	{
		float float_damage = HurtSum(Tank) > 0?(float(TakeTankDamage[List_Client[i]][Tank]) / HurtSum(Tank) * 100.0) : 0.0;
		float float_hurt = GetHurtSum(Tank) > 0?(float(GetTankDamage[List_Client[i]][Tank]) / GetHurtSum(Tank) * 100.0) : 0.0;
		char per = '%';
		GetClientName(List_Client[i], text, sizeof(text));
		Format(text, sizeof(text), "%s [伤害 %d](%.1f%s) [承伤 %d](%.1f%s) [拳 %d] [饼 %d] [铁 %d]",
				text,
				TakeTankDamage[List_Client[i]][Tank], float_damage, per,
				GetTankDamage[List_Client[i]][Tank], float_hurt, per,
				Fist_Hit[List_Client[i]][Tank], Stone_Hit[List_Client[i]][Tank], Iron_Hurt[List_Client[i]][Tank]);
		PrintToChatAll("\x03%N\x05 [伤害\x04%d\x05](\x04%.1f\x05%s) [承伤\x04%d\x05](\x04%.1f\x05%s) [拳\x04%d\x05] [饼\x04%d\x05] [铁\x04%d\x05]",
						List_Client[i],
						TakeTankDamage[List_Client[i]][Tank], float_damage, per,
						GetTankDamage[List_Client[i]][Tank], float_hurt, per,
						Fist_Hit[List_Client[i]][Tank], Stone_Hit[List_Client[i]][Tank], Iron_Hurt[List_Client[i]][Tank]);
		SaveMessage(text);
	}

	if (GetHurtSum(Tank) <= 0)
		PrintToChatAll("\x05零桑克!");

	PrintToChatAll("\x03<----------------------------->");
	text = " ";
	SaveMessage(text);

	for (int i = 1; i <= MaxClients ; i++)
	{
		TakeTankDamage[i][Tank] = 0;
		GetTankDamage[i][Tank] = 0;
		Fist_Hit[i][Tank] = 0;
		Stone_Hit[i][Tank] = 0;
		Iron_Hurt[i][Tank] = 0;
	}
}





// ====================================================================================================
// Record
// ====================================================================================================

public void OnMapStart()
{
	char map[128];
	char msg[1024];
	char date[21];
	char time[21];
	char logFile[100];

	GetCurrentMap(map, sizeof(map));

	/* The date may have rolled over, so update the logfile name here */
	FormatTime(date, sizeof(date), "%y.%m.%d", -1);
	Format(logFile, sizeof(logFile), "/logs/tank_damage_print[%s].log", date);
	BuildPath(Path_SM, TankDamage_RecordText, PLATFORM_MAX_PATH, logFile);

	FormatTime(time, sizeof(time), "%d/%m/%Y %H:%M:%S", -1);
	Format(msg, sizeof(msg), "[%s] --- NEW MAP STARTED: %s ---", time, map);

	SaveMessage("--=================================================================--");
	SaveMessage(msg);
	SaveMessage("--=================================================================--");
}

public void SaveMessage(char[] message)
{
	Handle fileHandle = OpenFile(TankDamage_RecordText, "a");
	WriteFileLine(fileHandle, message);
	CloseHandle(fileHandle);
}





// ====================================================================================================
// int
// ====================================================================================================

public int HurtSum(int Tank)
{
	int sum = 0;
	for (int i = 1; i <= MaxClients ; i++)
		sum += TakeTankDamage[i][Tank];
	return sum;
}

public int GetHurtSum(int Tank)
{
	int sum = 0;
	for (int i = 1; i <= MaxClients ; i++)
	    sum += GetTankDamage[i][Tank];
	return sum;
}





// ====================================================================================================
// bool
// ====================================================================================================

public bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

public bool IsTank(int client)
{
	return (client > 0 &&
			client <= MaxClients &&
			IsClientInGame(client) &&
			GetClientTeam(client) == 3 &&
			GetEntProp(client, Prop_Send, "m_zombieClass") == 8);
}