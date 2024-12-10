#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <colors>

#define CVAR_FLAGS		FCVAR_NOTIFY

char FilePath[PLATFORM_MAX_PATH], FileLine[PLATFORM_MAX_PATH];

char TextPrint[128][128];
int TextPrintNum = 0;
Handle TextPrintTimer;

float InforPrintInterval = 60.0;
ConVar Cvar_InforPrintInterval;

public void OnPluginStart()
{
	SetRandomSeed(GetSysTickCount());

	Cvar_InforPrintInterval = CreateConVar("l4d2_text_print_interval", "60.0", "文本输出的时间间隔.(s)", CVAR_FLAGS, true, 30.0);
	Cvar_InforPrintInterval.AddChangeHook(ConVarChanged);

	GetCustonText();

	AutoExecConfig(true, "l4d2_custom_text_broadcast");

	CreatePluginTimer();
}

public void OnPluginEnd()
{
	DeletePluginTimer();
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	InforPrintInterval = Cvar_InforPrintInterval.FloatValue;
	DeletePluginTimer();
	CreatePluginTimer();
}

public Action ToPrintText(Handle timer)
{
	CPrintToChatAll("{olive}[P] {blue}%s\n", TextPrint[GetRandomInt(0, TextPrintNum - 1)]);
	return Plugin_Continue;
}

public void GetCustonText()
{
	BuildPath(Path_SM, FilePath, sizeof(FilePath), "configs/l4d2_custom_text_broadcast.txt");
	if (FileExists(FilePath))
		IsSetCustonText();
}

public void IsSetCustonText()
{
	File file = OpenFile(FilePath, "rb");

	if (file)
	{
		TextPrintNum = 0;
		while (!file.EndOfFile())
		{
			file.ReadLine(FileLine, sizeof(FileLine));
			TrimString(FileLine);

			if (strlen(FileLine) > 0 && FileLine[0] != '/' && TextPrintNum < 128)
			{
				Format(TextPrint[TextPrintNum], sizeof(TextPrint), "%s", FileLine);
				TextPrintNum ++;
			}
		}
	}
}

public void CreatePluginTimer()
{
	if (TextPrintTimer == null && TextPrintNum > 1)
		TextPrintTimer = CreateTimer(InforPrintInterval, ToPrintText, _, TIMER_REPEAT);
}

public void DeletePluginTimer()
{
	if (TextPrintTimer != null)
		delete TextPrintTimer;
}