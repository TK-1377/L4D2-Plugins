#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <lerpmonitor>

#define CVAR_FLAGS		FCVAR_NOTIFY

char TeamName[3][16] =
{
	"(spectator)",
	"(survivor)",
	"(infected)"
};

float Ping_View_Interval = 60.0;
ConVar Cvar_Ping_View_Interval;

Handle PingViewTimer;

public void OnPluginStart()
{
	Cvar_Ping_View_Interval	=  CreateConVar("l4d2_view_player_ping_display_interval",
											"60.0",
											"全员玩家ping值显示的时间间隔.",
											CVAR_FLAGS, true, 30.0);

	Cvar_Ping_View_Interval.AddChangeHook(ConVarChanged);

	RegConsoleCmd("sm_ping",			Command_View_All_Player_Ping,	"查看玩家ping值");

	AutoExecConfig(true, "l4d2_view_player_ping");

	CreatePluginTimer();
}

public void OnPluginEnd()
{
	DeletePluginTimer();
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	Ping_View_Interval = Cvar_Ping_View_Interval.FloatValue;
	DeletePluginTimer();
	CreatePluginTimer();
}

public Action Command_View_All_Player_Ping(int client, int args)
{
	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	View_allping(client);
	return Plugin_Handled;
}

public Action ToDisplayAllPlayerPing(Handle timer)
{
	View_allping(0);
	return Plugin_Continue;
}

public void View_allping(int client)
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			int MyTeam = GetClientTeam(i);
			if (MyTeam >= 1 && MyTeam <= 3)
			{
				int MyPing = RoundToNearest(GetClientAvgLatency(i, NetFlow_Both) * 1000.0);
				float MyLerp = LM_GetLerpTime(i) * 1000.0;
				client == 0 ?
				PrintToChatAll("%s \x01%s \x03%N \x01 [\x04Ping \x03%d \x01| \x04Lerp \x03%.1f\x01]",
								MyPing <= 70 ? "\x05[Normal]" : (MyPing <= 180 ? "\x04[Warning]" : "\x03[Lagging]"),
								TeamName[MyTeam - 1], i, MyPing, MyLerp < 0.0 ? 0.0 : MyLerp)
				: PrintToChat(client, "%s \x01%s \x03%N \x01 [\x04Ping \x03%d \x01| \x04Lerp \x03%.1f\x01]",
								MyPing <= 70 ? "\x05[Normal]" : (MyPing <= 180 ? "\x04[Warning]" : "\x03[Lagging]"),
								TeamName[MyTeam - 1], i, MyPing, MyLerp < 0.0 ? 0.0 : MyLerp);
			}
		}
	}
	client == 0 ? PrintToChatAll(" ") : PrintToChat(client, " ");
}

public void CreatePluginTimer()
{
	if (PingViewTimer == null)
		PingViewTimer = CreateTimer(Ping_View_Interval, ToDisplayAllPlayerPing, _, TIMER_REPEAT);
}

public void DeletePluginTimer()
{
	if (PingViewTimer != null)
		delete PingViewTimer;
}