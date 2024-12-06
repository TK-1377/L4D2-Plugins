#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <sdktools>

char Default_Name[MAXPLAYERS + 1][MAX_NAME_LENGTH];
char Locked_Name[MAXPLAYERS + 1][MAX_NAME_LENGTH];

public void OnPluginStart()
{
	RegConsoleCmd("sm_lockname",		Command_Lock_Name,			"锁名.");
	RegConsoleCmd("sm_unlockname",		Command_Unlock_Name,		"解除锁名.");
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
		return;

	for (int i = 1; i <= MaxClients ; i++)
	{
		char ClientName[MAX_NAME_LENGTH];
		char TempString[MAX_NAME_LENGTH];
		GetClientName(client, ClientName, sizeof(ClientName));
		if (strlen(Default_Name[i]) > 1 && strlen(Locked_Name[i]) > 1)
		{
			if (strcmp(ClientName, Default_Name[i]) == 0 || strcmp(ClientName, Locked_Name[i]) == 0)
			{
				if (i != client)
				{
					TempString = Default_Name[i];
					Default_Name[i] = Default_Name[client];
					Default_Name[client] = TempString;
					TempString = Locked_Name[i];
					Locked_Name[i] = Locked_Name[client];
					Locked_Name[client] = TempString;
				}
				CreateTimer(1.0, SetLockedName, client, TIMER_FLAG_NO_MAPCHANGE);
				return;
			}
		}
	}

	FormatEx(Default_Name[client], sizeof(Default_Name[]), "%N", client);
	Locked_Name[client] = "";
}

public Action Command_Lock_Name(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	char arg[MAX_NAME_LENGTH];
	GetCmdArgString(arg, sizeof(arg));

	if (strlen(arg) <= 1)
		return Plugin_Handled;

	FormatEx(Locked_Name[client], sizeof(Locked_Name[]), "%s", arg);
	SetClientInfo(client, "name", Locked_Name[client]);
	PrintToChat(client, "\x05[INFO] \x04Your new name \x05%s \x04is locked.", arg);
	return Plugin_Handled;
}

public Action Command_Unlock_Name(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	Locked_Name[client] = "";
	SetClientInfo(client, "name", Default_Name[client]);
	PrintToChat(client, "\x05[INFO] \x04Your default name \x05%s \x04is back.", Default_Name[client]);
	return Plugin_Handled;
}

public Action SetLockedName(Handle timer, int client)
{
	if (IsValidClient(client))
		SetClientInfo(client, "name", Locked_Name[client]);
	return Plugin_Continue;
}

public bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}