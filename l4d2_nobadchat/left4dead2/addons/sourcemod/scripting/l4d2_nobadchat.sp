#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>

int BlockTextNumber = 0;
char BlockText[512][32];

char FilePath[PLATFORM_MAX_PATH], FileLine[PLATFORM_MAX_PATH];

public void OnPluginStart()
{
	GetConfig();

	RegConsoleCmd("say",		Command_Say);
	RegConsoleCmd("say_team",	Command_SayTeam);
}

public void GetConfig()
{
	BuildPath(Path_SM, FilePath, sizeof(FilePath), "configs/l4d2_nobadchat.txt");
	if (FileExists(FilePath))
		IsSetBlockText();
}

public void IsSetBlockText()
{
	File file = OpenFile(FilePath, "rb");

	if (file)
	{
		BlockTextNumber = 0;
		while (!file.EndOfFile())
		{
			file.ReadLine(FileLine, sizeof(FileLine));
			TrimString(FileLine);

			if (strlen(FileLine) > 0 && FileLine[0] != '/' && BlockTextNumber < 512)
			{
				Format(BlockText[BlockTextNumber], sizeof(BlockText), "%s", FileLine);
				BlockTextNumber ++;
			}
		}
	}
}

public Action Command_Say(int client, int args)
{
	if (ShouldBlockChat(client, args))
	{
		PrintToChat(client, "\x05Hey, don't speak swearing!");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Command_SayTeam(int client, int args)
{
	if (ShouldBlockChat(client, args))
	{
		PrintToChat(client, "\x05Hey, don't speak swearing!");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public bool ShouldBlockChat(int client, int args)
{
	if (BlockTextNumber <= 0)
		return false;
	char text[256];
	GetCmdArgString(text, sizeof(text));
	StripQuotes(text);

	if (text[0] == '/' || text[0] == '!')
		return false;

	for (int i = 0; i < BlockTextNumber ; i++)
	{
		if (StrContains(text, BlockText[i]) != -1)
			return true;
	}
	return false;
}