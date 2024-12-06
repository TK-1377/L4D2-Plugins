#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <l4d2util>

bool IsShould[32];

public void OnPluginStart()
{
	HookEvent("round_start",		Event_RoundStart,		EventHookMode_PostNoCopy);		//回合开始.
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients ; i++)
		IsShould[i] = true;
}





// ====================================================================================================
// Game Action
// ====================================================================================================

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3],
					int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (!IsAliveSurvivor(client))
		return Plugin_Continue;

	if (!IsPlayerState(client))
		return Plugin_Continue;
	
	if (!IsShould[client])
		return Plugin_Continue;
	
	if (!(buttons & IN_ATTACK2) && !(buttons & IN_RELOAD))
		return Plugin_Continue;
	

	char weapon_name[64];
	GetClientWeapon(client, weapon_name, sizeof(weapon_name));
	int wepid = WeaponNameToId(weapon_name);

	if (!IsPills(wepid))
		return Plugin_Continue;

	IsShould[client] = false;
	CreateTimer(0.5, ReCold_IsShould, client);
	CreateTimer(0.1, CheckPlayer, client);

	return Plugin_Continue;
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

public Action CheckPlayer(Handle timer, int client)
{
	CheckGivePillsPlayer(client);
	return Plugin_Continue;
}

public Action ReCold_IsShould(Handle timer, int client)
{
	IsShould[client] = true;
	return Plugin_Continue;
}





// ====================================================================================================
// void
// ====================================================================================================

public void CheckGivePillsPlayer(int client)
{
	if (!IsAliveSurvivor(client) || !IsPlayerState(client) || !IsHavePills(client))
		return;

	float give_dis[3], bgive_dis[3], sub_dis[3], give_angle[3], right_angle[3], dist;
	GetClientAbsOrigin(client, give_dis);
	GetClientEyeAngles(client, give_angle);
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (i != client &&
			IsClientInGame(i) &&
			GetClientTeam(i) == 2 &&
			IsPlayerAlive(i) &&
			IsPlayerState(i) &&
			!IsHavePills(i))
		{
			GetClientAbsOrigin(i, bgive_dis);
			dist = GetVectorDistance(give_dis, bgive_dis, true);
			if (dist > 274.0)
			{
				for (int j = 0; j < 3 ; j++)
					sub_dis[j] = give_dis[j] - bgive_dis[j];

				GetVectorAngles(sub_dis, right_angle);

				if (IsValidRatio1(give_angle[0], right_angle[0]) && IsValidRatio2(give_angle[1], right_angle[1]))
				{
					int weapon = GetPlayerWeaponSlot(client, 4);
					int pills_id = IdentifyWeapon(weapon);
					L4D_RemoveWeaponSlot(client, view_as<L4DWeaponSlot>(4));
					Give_Player_Pills(i, pills_id);
					Handle Temp_Event = CreateEvent("weapon_given");
					SetEventInt(Temp_Event, "userid", GetClientUserId(i));
					SetEventInt(Temp_Event, "giver", GetClientUserId(client));
					SetEventInt(Temp_Event, "weapon", pills_id);
					SetEventInt(Temp_Event, "weaponentid", weapon);
					FireEvent(Temp_Event);
					break;
				}
			}
		}
	}
}

public void Give_Player_Pills(int client, int pills_type)
{
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	if (pills_type == 15)
		FakeClientCommand(client, "give pain_pills");
	else if (pills_type == 23)
		FakeClientCommand(client, "give adrenaline");
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}





// ====================================================================================================
// bool
// ====================================================================================================

public bool IsAliveSurvivor(int client)
{
	return (client > 0 &&
			client <= MaxClients &&
			IsClientInGame(client) &&
			GetClientTeam(client) == 2 &&
			IsPlayerAlive(client));
}

public bool IsPlayerState(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated") && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

public bool IsHavePills(int client)
{
	int weapon = GetPlayerWeaponSlot(client, 4);
	int wepid  = IdentifyWeapon(weapon);

	return IsPills(wepid);
}

public bool IsPills(int wepid)
{
	return wepid == 15 || wepid == 23;
}

public bool IsValidRatio1(float n1, float n2)
{
	float n = n1 + n2;
	return ((n > -5.0 && n < 5.0) || (n > 355.0 && n < 365.0));
}

public bool IsValidRatio2(float n1, float n2)
{
	return ((n2 - n1) > 175.0 && (n2 - n1) < 185.0);
}