#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>
#include <l4d2_boss_percents>
#include <witch_and_tankifier>
#include <l4d2_ems_hud>
#include <l4d2util>

Handle TankHUDTimer;
float MapMaxFlow;

public void OnPluginStart()
{
	TankHUDTimer = CreateTimer(1.0, DisplayTankDistance, _, TIMER_REPEAT);
}

public void OnPluginEnd()
{
	if (TankHUDTimer != null)
		delete TankHUDTimer;
}

public void OnMapStart()
{
	EnableHUD();
	MapMaxFlow = L4D2Direct_GetMapMaxFlowDistance();
}

public Action DisplayTankDistance(Handle timer)
{
	RemoveShowHUD();
	ShowHUD();
	return Plugin_Continue;
}

public void RemoveShowHUD()
{
	if (HUDSlotIsUsed(HUD_SCORE_1))
		RemoveHUD(HUD_SCORE_1);
}

public void ShowHUD()
{
	if (L4D_GetGameModeType() != GAMEMODE_VERSUS)
		return;

	bool IsStaticTank = LibraryExists("witch_and_tankifier") && IsStaticTankMap();
	int TankFlow, SurvivorFlow;

	if (!IsStaticTank)
	{
		TankFlow = (GetFeatureStatus(FeatureType_Native, "GetStoredTankPercent") != FeatureStatus_Unknown) ?
					GetStoredTankPercent() : GetRoundTankFlow();
	}

	SurvivorFlow = GetHighestSurvivorFlow();
	if (SurvivorFlow == -1)
		SurvivorFlow = GetFurthestSurvivorFlow();

	char DistanceInfo[128];

	if (IsStaticTank)
		Format(DistanceInfo, sizeof(DistanceInfo), "[➣ Cur : %d ]  [➣ Tank : static ]", SurvivorFlow);
	else
		Format(DistanceInfo, sizeof(DistanceInfo), "[➣ Cur : %d ]  [➣ Tank : %d ]", SurvivorFlow, TankFlow);

	HUDSetLayout(HUD_SCORE_1, HUD_FLAG_BLINK|HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_TEXT, DistanceInfo);
	HUDPlace(HUD_SCORE_1, 0.00, 0.03, 1.0, 0.03);
}

stock int GetHighestSurvivorFlow()
{
	int flow = -1;
	int client = L4D_GetHighestFlowSurvivor();
	if (client > 0)
		flow = RoundToNearest(100.0 * (L4D2Direct_GetFlowDistance(client) + GetVSMaxFlow()) / MapMaxFlow);
	return flow < 100 ? flow : 100;
}

stock int GetFurthestSurvivorFlow()
{
	int flow = RoundToNearest(100.0 * (L4D2_GetFurthestSurvivorFlow() + GetVSMaxFlow()) / MapMaxFlow);
	return flow < 100 ? flow : 100;
}

stock int GetRoundTankFlow()
{
	return RoundToNearest(L4D2Direct_GetVSTankFlowPercent(InSecondHalfOfRound()) + GetVSMaxFlow() / MapMaxFlow);
}

stock float GetVSMaxFlow()
{
	static ConVar Versus_Boss_Buffer;
	if (Versus_Boss_Buffer == null)
		Versus_Boss_Buffer = FindConVar("versus_boss_buffer");

	return Versus_Boss_Buffer.FloatValue;
}