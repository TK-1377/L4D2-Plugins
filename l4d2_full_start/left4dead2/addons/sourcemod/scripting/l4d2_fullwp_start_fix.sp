#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <l4d2util>

public void OnPluginStart()
{}

public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client)
{
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	int alive_survivor_num = 0;
	int shotgun_hold_num   = 0;
	int smgd_hold_num	   = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			alive_survivor_num++;
			int weapon = GetPlayerWeaponSlot(i, 0);
			int wepid  = IdentifyWeapon(weapon);
			if (wepid > 0)
			{
				if (wepid == 2 || wepid == 7 || wepid == 33)
					smgd_hold_num++;
				else if (wepid == 3 || wepid == 8)
					shotgun_hold_num++;
			}
		}
	}
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			int weapon = GetPlayerWeaponSlot(i, 0);
			int wepid  = IdentifyWeapon(weapon);
			if (wepid <= 0)
			{
				if (smgd_hold_num < (alive_survivor_num - 1))
				{
					FakeClientCommand(i, "give smg_silenced");
					smgd_hold_num++;
				}
				else if (shotgun_hold_num < (alive_survivor_num - 1))
				{
					FakeClientCommand(i, "give shotgun_chrome");
					shotgun_hold_num++;
				}
			}
		}
	}
	SetCommandFlags("give", flags | FCVAR_CHEAT);
}