#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <colors>

public void OnPluginStart()
{
	HookEvent("door_open",			Event_DoorOpen);											// 打开安全门
	HookEvent("door_close",			Event_DoorClose);											// 关上安全门
}

// 打开安全门
public void Event_DoorOpen(Event event, const char[] name, bool dontBroadcast)
{
	if (!event.GetBool("checkpoint"))
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsInGameClient(client))
		return;
	
	switch (GetClientTeam(client))
	{
		case 2 :
			CPrintToChatAll("{olive}[OC Door] {blue}%N {default}open the safedoor.", client);
		case 3 :
			CPrintToChatAll("{olive}[OC Door] {red}%N {default}open the safedoor.", client);
	}
}

// 关上安全门
public void Event_DoorClose(Event event, const char[] name, bool dontBroadcast)
{
	if (!event.GetBool("checkpoint"))
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsInGameClient(client))
		return;
	
	switch (GetClientTeam(client))
	{
		case 2 :
			CPrintToChatAll("{olive}[OC Door] {blue}%N {default}close the safedoor.", client);
		case 3 :
			CPrintToChatAll("{olive}[OC Door] {red}%N {default}close the safedoor.", client);
	}
}

public bool IsInGameClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}