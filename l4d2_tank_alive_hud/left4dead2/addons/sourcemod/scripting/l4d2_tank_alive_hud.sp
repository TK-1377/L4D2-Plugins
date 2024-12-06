#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

bool TankInPlay = false;
bool AI_Tank_View = true;

int Tank_Health;
int Tank_Client;
int Tank_Damage;
int Tank_Hit;
int Tank_Hurt;

bool Tank_IsHit;

Handle Tank_Alive_Hud;

ConVar Cvar_TankAliveHUDView;

public void OnPluginStart()
{
	Cvar_TankAliveHUDView = CreateConVar("l4d2_tank_alive_hud_view", "1", "Tank存活HUD显示.");

	Cvar_TankAliveHUDView.IntValue = 1;

	HookEvent("round_start",			Event_RoundStart,			EventHookMode_PostNoCopy);			// 回合开始
	HookEvent("round_end",				Event_RoundEnd,				EventHookMode_PostNoCopy);			// 回合结束
	HookEvent("player_hurt",			Event_PlayerHurt);												// 玩家受伤
	HookEvent("player_death",			Event_PlayerDeath);												// 玩家死亡
	HookEvent("tank_spawn",				Event_TankSpawn);												// Tank生成

	RegConsoleCmd("sm_aitankview",		Command_AI_Tank_View_OC);
}





// ====================================================================================================
// Game void
// ====================================================================================================

public void OnMapEnd()
{
	TankInPlay = false;
	if (Tank_Alive_Hud != null)
		delete Tank_Alive_Hud;
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

// 回合开始
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	OnMapEnd();
}

// 回合结束
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	OnMapEnd();
}

// 玩家受伤
public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (!TankInPlay)
		return;

	int client   = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int iDmg     = event.GetInt("dmg_health");

	if (IsSurvivor(client) && IsTank(attacker) && attacker == Tank_Client)
	{
		Tank_Damage += iDmg;

		if (!Tank_IsHit)
		{
			Tank_Hit ++;
			Tank_IsHit = true;
			CreateTimer(1.1, ReCold_Tank_Hit);
		}
	}
	else if (IsSurvivor(attacker) && IsTank(client) && client == Tank_Client)
		Tank_Hurt += iDmg;
}

// 玩家死亡
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsTank(client) || !IsNoHaveTank())
		return;

	TankInPlay = false;
	if (Tank_Alive_Hud != null)
		delete Tank_Alive_Hud;
}

// Tank生成
public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	if (TankInPlay)
		return;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsTank(client))
		return;

	if (!AI_Tank_View && IsFakeClient(client))
		return;

	CreateTimer(1.0, CheckTankAlive, client, TIMER_FLAG_NO_MAPCHANGE);
}





// ====================================================================================================
// Command Action
// ====================================================================================================

public Action Command_AI_Tank_View_OC(int client, int args)
{
	if (AI_Tank_View)
	{
		AI_Tank_View = false;
		PrintToChatAll("\x05[PT] \x04AI Tank View : OFF");

		if (TankInPlay && Tank_Alive_Hud != null && IsTank(Tank_Client) && IsFakeClient(Tank_Client))
			delete Tank_Alive_Hud;
	}
	else
	{
		AI_Tank_View = true;
		PrintToChatAll("\x05[PT] \x04AI Tank View : ON");

		if (TankInPlay && Tank_Alive_Hud == null)
			FindTank(true);
	}
	return Plugin_Handled;
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

// 检查Tank是否存活
public Action CheckTankAlive(Handle timer, int client)
{
	if (IsTank(client) && IsPlayerAlive(client))
	{
		TankInPlay	= true;
		Tank_Health	= GetClientHealth(client);
		Tank_Client	= client;
		Tank_Damage	= 0;
		Tank_Hit	= 0;
		Tank_IsHit	= false;

		if (Tank_Alive_Hud == null)
			Tank_Alive_Hud = CreateTimer(0.5, ViewTank, _, TIMER_REPEAT);
	}
	return Plugin_Continue;
}

// Tank攻击计算冷却修正
public Action ReCold_Tank_Hit(Handle timer)
{
	Tank_IsHit = false;
	return Plugin_Continue;
}

// 显示旁观者Tank HUD
public Action ViewTank(Handle timer)
{
	if (TankInPlay)
		TANK_HUD_VIEW();
	return Plugin_Continue;
}





// ====================================================================================================
// Tank Alive HUD
// ====================================================================================================

//显示旁观者Tank HUD
public void TANK_HUD_VIEW()
{
	Panel menuPanel = new Panel();
	menuPanel.DrawText("#    Tank HUD     #");
	menuPanel.DrawText("________________________");
	char text[36];
	if (IsTank(Tank_Client))
	{
		if (IsFakeClient(Tank_Client))
			Format(text, sizeof(text), "Control : AI", text);
		else
		{
			GetClientName(Tank_Client, text, sizeof(text));
			Format(text, sizeof(text), "Control : %s", text);
		}
		menuPanel.DrawText(text);


		Format(text, sizeof(text), "Default Health : %d", Tank_Health);
		menuPanel.DrawText(text);


		char per = '%';
		int NowHP = GetClientHealth(Tank_Client);
		float Tank_Health_Float = float(NowHP) * 100 / Tank_Health;
		Format(text, sizeof(text), "Health : %d   ( %.1f %s)", GetClientHealth(Tank_Client), Tank_Health_Float, per);
		menuPanel.DrawText(text);

		int tankFrustration = 100 - L4D_GetTankFrustration(Tank_Client);
		Format(text, sizeof(text), "Rage : %d %s", tankFrustration, per);
		menuPanel.DrawText(text);


		Format(text, sizeof(text), "Damage : %d   ( %d )", Tank_Damage, Tank_Hit);
		menuPanel.DrawText(text);


		if (IsPlayerAlive(Tank_Client) && NowHP > 0 && Tank_Hurt > 0)
		{
			int Dead_Timer = 0;
			int Tank_Hurt_InOneSecond = Tank_Hurt * 2;
			Dead_Timer = NowHP / Tank_Hurt_InOneSecond;
			if (NowHP / Tank_Hurt_InOneSecond != 0)
				Dead_Timer ++;

			Format(text, sizeof(text), "Hurt Speed : %d / s ( %d s )", Tank_Hurt_InOneSecond, Dead_Timer);
		}
		else
			Format(text, sizeof(text), "Hurt Speed : 0 / s ( - )");
		Tank_Hurt = 0;
		menuPanel.DrawText(text);


		if (!IsFakeClient(Tank_Client))
		{
			int cping = RoundToNearest(GetClientAvgLatency(Tank_Client, NetFlow_Both) * 1000.0);
			Format(text, sizeof(text), "Network : %d ms", cping);
			menuPanel.DrawText(text);
		}
	}
	else
		FindTank(false);

	menuPanel.DrawText("________________________");

	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) &&
			!IsFakeClient(i) &&
			(GetClientTeam(i) == 1 || (GetClientTeam(i) == 3 && Cvar_TankAliveHUDView.IntValue == 1)))
		{
			menuPanel.Send(i, DummyHandler, 1);
		}
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

public void FindTank(bool IsNeedReCreateTimer)
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) &&
			GetClientTeam(i) == 3 &&
			GetEntProp(i, Prop_Send, "m_zombieClass") == 8 &&
			IsPlayerAlive(i))
		{
			Tank_Client = i;
			if (IsNeedReCreateTimer)
				CreateTimer(0.5, CheckTankAlive, i);
			break;
		}
	}
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

public bool IsNoHaveTank()
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) &&
			GetClientTeam(i) == 3 &&
			GetEntProp(i, Prop_Send, "m_zombieClass") == 8 &&
			IsPlayerAlive(i))
		{
			return false;
		}
	}
	return true;
}