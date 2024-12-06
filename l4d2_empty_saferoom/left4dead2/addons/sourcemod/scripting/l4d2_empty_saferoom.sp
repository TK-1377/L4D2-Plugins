#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <l4d2util>
#include <left4dhooks>

bool EntityIsOnSurvivor[2049];

public void OnPluginStart()
{
	HookEvent("round_start", 				Event_RoundStart, 				EventHookMode_PostNoCopy);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(1.0, DealyDeleteSafeRoomItems, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action DealyDeleteSafeRoomItems(Handle timer, int client)
{
	CheckEntityOnSurvivor();

	float EntityPos[3];

	int entcnt = GetEntityCount();
	for (int ent = MaxClients + 1; ent <= entcnt; ent++)
	{
		if (!IsValidEdict(ent) || EntityIsOnSurvivor[ent])
			continue;

		int wepid = IdentifyWeapon(ent);

		if (!IsDeleteWeaponByWepid(wepid))
			continue;

		GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", EntityPos);

		if (L4D_IsPositionInFirstCheckpoint(EntityPos) || L4D_IsPositionInLastCheckpoint(EntityPos))
			AcceptEntityInput(ent, "Kill");
	}
	return Plugin_Continue;
}

public void CheckEntityOnSurvivor()
{
	for (int i = 0; i < 2049 ; i++)
		EntityIsOnSurvivor[i] = false;

	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			for (int j = 0; j < 5 ; j++)
			{
				int weapon = GetPlayerWeaponSlot(i, j);

				if (weapon > MaxClients && IsValidEdict(weapon))
					EntityIsOnSurvivor[weapon] = true;
			}
		}
	}
}

public bool IsDeleteWeaponByWepid(int wepid)
{
	return (wepid >= 12 && wepid <= 15) || (wepid >= 23 && wepid <= 25);
}