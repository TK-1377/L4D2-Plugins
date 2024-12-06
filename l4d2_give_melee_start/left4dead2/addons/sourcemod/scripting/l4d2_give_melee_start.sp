#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <clientprefs>

Handle integral;

bool CanGiveMelee[32] = {true};
int PlayerMelee[32];

int AS;

public Plugin myinfo =
{
	name        = "give_melee_start",
	author      = "77",
	description = "出门近战或手枪.",
	version     = "1.25",
	url         = "N/A"
}

bool bLate;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	bLate = late;
	return APLRes_Success; 
}

public void OnPluginStart()
{
	integral = RegClientCookie("l4d2_give_melee_start", "give_melee_start.smx", CookieAccess_Protected);

	HookEvent("round_start",	Event_RoundStart,				EventHookMode_Post); //回合开始

	RegConsoleCmd("sm_gmelee",	Command_Give_Melee_Menu,		"打开给予武器菜单.");
	RegConsoleCmd("sm_glook",	Command_Give_Look_Print,		"查看出门近战指令.");
	RegConsoleCmd("sm_gre",		Command_Give_remove,			"取消.");
	RegConsoleCmd("sm_gxd",		Command_Give_knife,				"小刀.");
	RegConsoleCmd("sm_gfz",		Command_Give_fireaxe,			"消防斧.");
	RegConsoleCmd("sm_gkd",		Command_Give_machete,			"砍刀.");
	RegConsoleCmd("sm_gwsd",	Command_Give_katana,			"武士刀.");
	RegConsoleCmd("sm_gqg",		Command_Give_crowbar,			"撬棍.");
	RegConsoleCmd("sm_ggef",	Command_Give_golfclub,			"高尔夫球杆.");
	RegConsoleCmd("sm_gbqp",	Command_Give_cricket_bat,		"板球拍.");
	RegConsoleCmd("sm_gbqg",	Command_Give_baseball_bat,		"棒球棍.");
	RegConsoleCmd("sm_gpdg",	Command_Give_frying_pan,		"平底锅.");
	RegConsoleCmd("sm_gdjt",	Command_Give_electric_guitar,	"电吉他.");
	RegConsoleCmd("sm_gjg",		Command_Give_tonfa,				"警棍.");
	RegConsoleCmd("sm_ggcc",	Command_Give_pitchfork,			"干草叉.");
	RegConsoleCmd("sm_gcz",		Command_Give_shovel,			"铲子.");
	RegConsoleCmd("sm_gxsq",	Command_Give_pistol,			"小手枪.");
	RegConsoleCmd("sm_gmgn",	Command_Give_magnum,			"马格南.");

	if (bLate)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				OnClientCookiesCached(i);
			}
		}
	}
}





// ====================================================================================================
// Cookie
// ====================================================================================================

//加载玩家 Cookie
public void OnClientCookiesCached(int client)
{
	if (!IsFakeClient(client))
	{
		char TempStr[11];
		GetClientCookie(client, integral, TempStr, sizeof(TempStr));
		PlayerMelee[client] = StringToInt(TempStr);
	}
}

//玩家离开
public void OnClientDisconnect(int client)
{
	if (!IsFakeClient(client))
	{
		char TempStr[11];
		IntToString(PlayerMelee[client], TempStr, sizeof(TempStr));
		SetClientCookie(client, integral, TempStr);
		PlayerMelee[client] = 0;
	}
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

//回合开始
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients ; i++)
	    CanGiveMelee[i] = true;
	AS = 0;
	CreateTimer(3.0, GiveMeleeDelay, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

//给予玩家 近战武器 或者 手枪
public Action GiveMeleeDelay(Handle timer)
{
	AS ++;
	if (AS >= 20)
		return Plugin_Stop;

	if (AS >= 2)
		GiveMelee();
	
	if (AS == 1)
	{
		PrintToChatAll("\x05出门近战 可用指令 :");
		PrintToChatAll("\x04!gmelee		\x05打开出门近战菜单");
		PrintToChatAll("\x04!glook		\x05查看出门近战指令");
	}

	return Plugin_Continue;
}





// ====================================================================================================
// Command Action
// ====================================================================================================

public Action Command_Give_remove(int client, int args)
{
	PlayerMelee[client] = 0;
	PrintToChat(client, "\x04您已取消出门近战设置.");
	return Plugin_Handled;
}

public Action Command_Give_knife(int client, int args)
{
	PlayerMelee[client] = 1;
	PrintToChat(client, "\x04您已将出门近战设置为 \x03小刀.");
	return Plugin_Handled;
}

public Action Command_Give_fireaxe(int client, int args)
{
	PlayerMelee[client] = 2;
	PrintToChat(client, "\x04您已将出门近战设置为 \x03消防斧.");
	return Plugin_Handled;
}

public Action Command_Give_machete(int client, int args)
{
	PlayerMelee[client] = 3;
	PrintToChat(client, "\x04您已将出门近战设置为 \x03砍刀.");
	return Plugin_Handled;
}

public Action Command_Give_katana(int client, int args)
{
	PlayerMelee[client] = 4;
	PrintToChat(client, "\x04您已将出门近战设置为 \x03武士刀.");
	return Plugin_Handled;
}

public Action Command_Give_crowbar(int client, int args)
{
	PlayerMelee[client] = 5;
	PrintToChat(client, "\x04您已将出门近战设置为 \x03撬棍.");
	return Plugin_Handled;
}

public Action Command_Give_golfclub(int client, int args)
{
	PlayerMelee[client] = 6;
	PrintToChat(client, "\x04您已将出门近战设置为 \x03高尔夫球杆.");
	return Plugin_Handled;
}

public Action Command_Give_cricket_bat(int client, int args)
{
	PlayerMelee[client] = 7;
	PrintToChat(client, "\x04您已将出门近战设置为 \x03板球拍.");
	return Plugin_Handled;
}

public Action Command_Give_baseball_bat(int client, int args)
{
	PlayerMelee[client] = 8;
	PrintToChat(client, "\x04您已将出门近战设置为 \x03棒球棍.");
	return Plugin_Handled;
}

public Action Command_Give_frying_pan(int client, int args)
{
	PlayerMelee[client] = 9;
	PrintToChat(client, "\x04您已将出门近战设置为 \x03平底锅.");
	return Plugin_Handled;
}

public Action Command_Give_electric_guitar(int client, int args)
{
	PlayerMelee[client] = 10;
	PrintToChat(client, "\x04您已将出门近战设置为 \x03电吉他.");
	return Plugin_Handled;
}

public Action Command_Give_tonfa(int client, int args)
{
	PlayerMelee[client] = 11;
	PrintToChat(client, "\x04您已将出门近战设置为 \x03警棍.");
	return Plugin_Handled;
}

public Action Command_Give_pitchfork(int client, int args)
{
	PlayerMelee[client] = 12;
	PrintToChat(client, "\x04您已将出门近战设置为 \x03干草叉.");
	return Plugin_Handled;
}

public Action Command_Give_shovel(int client, int args)
{
	PlayerMelee[client] = 13;
	PrintToChat(client, "\x04您已将出门近战设置为 \x03铲子.");
	return Plugin_Handled;
}

public Action Command_Give_pistol(int client, int args)
{
	PlayerMelee[client] = 14;
	PrintToChat(client, "\x04您已将出门近战设置为 \x03小手枪.");
	return Plugin_Handled;
}

public Action Command_Give_magnum(int client, int args)
{
	PlayerMelee[client] = 15;
	PrintToChat(client, "\x04您已将出门近战设置为 \x03马格南.");
	return Plugin_Handled;
}

// 查看 出门近战指令
public Action Command_Give_Look_Print(int client, int args)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		PrintToChat(client, "\x03 <-  出门近战指令  ->");
		PrintToChat(client, "\x04!gmelee	\x05查看出门近战菜单");
		PrintToChat(client, "\x04!glook	\x05查看出门近战指令");
		PrintToChat(client, "\x04!gre		\x05取消开局出门近战设置");
		PrintToChat(client, "\x04!gxd	\x05开局小刀");
		PrintToChat(client, "\x04!gfz		\x05开局消防斧");
		PrintToChat(client, "\x04!gkd	\x05开局砍刀");
		PrintToChat(client, "\x04!gwsd	\x05开局武士刀");
		PrintToChat(client, "\x04!gqg	\x05开局撬棍");
		PrintToChat(client, "\x04!ggef	\x05开局高尔夫球杆");
		PrintToChat(client, "\x04!gbqp	\x05开局板球拍");
		PrintToChat(client, "\x04!gbqg	\x05开局棒球棍");
		PrintToChat(client, "\x04!gpdg	\x05开局平底锅");
		PrintToChat(client, "\x04!gdjt	\x05开局电吉他");
		PrintToChat(client, "\x04!gjg		\x05开局警棍");
		PrintToChat(client, "\x04!ggcc	\x05开局干草叉");
		PrintToChat(client, "\x04!gcz		\x05开局铲子");
		PrintToChat(client, "\x04!gxsq	\x05开局小手枪");
		PrintToChat(client, "\x04!gmgn	\x05开局马格南");
	}
	return Plugin_Handled;
}

//查看 出门近战菜单
public Action Command_Give_Melee_Menu(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	Show_Give_Melee_Menu1(client);
	return Plugin_Handled;
}





// ====================================================================================================
// Show Give Melee Menu
// ====================================================================================================

public void Show_Give_Melee_Menu1(int client)
{
	if (!IsValidClient(client))
		return;

	Handle menu = CreatePanel();
	SetPanelTitle(menu, "出门近战设置");
	DrawPanelItem(menu, "取消出门近战");
	DrawPanelItem(menu, "小刀");
	DrawPanelItem(menu, "消防斧");
	DrawPanelItem(menu, "砍刀");
	DrawPanelItem(menu, "武士刀");
	DrawPanelItem(menu, "撬棍");
	DrawPanelItem(menu, "高尔夫球杆");
	DrawPanelItem(menu, "板球拍");
	DrawPanelItem(menu, "下一页");
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Give_Melee_Menu1, 15);
}

public void Show_Give_Melee_Menu2(int client)
{
	if (!IsValidClient(client))
		return;

	Handle menu = CreatePanel();
	SetPanelTitle(menu, "出门近战设置");
	DrawPanelItem(menu, "棒球棍");
	DrawPanelItem(menu, "平底锅");
	DrawPanelItem(menu, "电吉他");
	DrawPanelItem(menu, "警棍");
	DrawPanelItem(menu, "干草叉");
	DrawPanelItem(menu, "铲子");
	DrawPanelItem(menu, "小手枪");
	DrawPanelItem(menu, "马格南");
	DrawPanelItem(menu, "上一页");
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Give_Melee_Menu2, 15);
}





// ====================================================================================================
// Give Melee Menu
// ====================================================================================================

public int Give_Melee_Menu1(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum <= 8)
			{
				PlayerMelee[client] = itemNum - 1;
				MenuEndPrint(client);
			}
			else if (itemNum == 9)
				Show_Give_Melee_Menu2(client);
			else
				delete menu;
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

public int Give_Melee_Menu2(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum <= 8)
			{
				PlayerMelee[client] = itemNum + 7;
				MenuEndPrint(client);
			}
			else if (itemNum == 9)
				Show_Give_Melee_Menu1(client);
			else
				delete menu;
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}





// ====================================================================================================
// Give Melee
// ====================================================================================================

// 给予玩家 近战武器 或者 手枪
public void GiveMelee()
{
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && CanGiveMelee[i])
		{
			CanGiveMelee[i] = false;
			if (PlayerMelee[i] == 1)
				FakeClientCommand(i, "give knife");
			else if (PlayerMelee[i] == 2)
				FakeClientCommand(i, "give fireaxe");
			else if (PlayerMelee[i] == 3)
				FakeClientCommand(i, "give machete");
			else if (PlayerMelee[i] == 4)
				FakeClientCommand(i, "give katana");
			else if (PlayerMelee[i] == 5)
				FakeClientCommand(i, "give crowbar");
			else if (PlayerMelee[i] == 6)
				FakeClientCommand(i, "give golfclub");
			else if (PlayerMelee[i] == 7)
				FakeClientCommand(i, "give cricket_bat");
			else if (PlayerMelee[i] == 8)
				FakeClientCommand(i, "give baseball_bat");
			else if (PlayerMelee[i] == 9)
				FakeClientCommand(i, "give frying_pan");
			else if (PlayerMelee[i] == 10)
				FakeClientCommand(i, "give electric_guitar");
			else if (PlayerMelee[i] == 11)
				FakeClientCommand(i, "give tonfa");
			else if (PlayerMelee[i] == 12)
				FakeClientCommand(i, "give pitchfork");
			else if (PlayerMelee[i] == 13)
				FakeClientCommand(i, "give shovel");
			else if (PlayerMelee[i] == 14)
				FakeClientCommand(i, "give pistol");
			else if (PlayerMelee[i] == 15)
				FakeClientCommand(i, "give pistol_magnum");
			else
				PlayerMelee[i] = 0;
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}





// ====================================================================================================
// void
// ====================================================================================================

public void MenuEndPrint(int client)
{
	switch(PlayerMelee[client])
	{
		case 0 :
			PrintToChat(client, "\x04您已取消出门近战设置.");
		case 1 :
			PrintToChat(client, "\x04您已将出门近战设置为 \x03小刀.");
		case 2 :
			PrintToChat(client, "\x04您已将出门近战设置为 \x03消防斧.");
		case 3 :
			PrintToChat(client, "\x04您已将出门近战设置为 \x03砍刀.");
		case 4 :
			PrintToChat(client, "\x04您已将出门近战设置为 \x03武士刀.");
		case 5 :
			PrintToChat(client, "\x04您已将出门近战设置为 \x03撬棍.");
		case 6 :
			PrintToChat(client, "\x04您已将出门近战设置为 \x03高尔夫球杆.");
		case 7 :
			PrintToChat(client, "\x04您已将出门近战设置为 \x03板球拍.");
		case 8 :
			PrintToChat(client, "\x04您已将出门近战设置为 \x03棒球棍.");
		case 9 :
			PrintToChat(client, "\x04您已将出门近战设置为 \x03平底锅.");
		case 10 :
			PrintToChat(client, "\x04您已将出门近战设置为 \x03电吉他.");
		case 11 :
			PrintToChat(client, "\x04您已将出门近战设置为 \x03警棍.");
		case 12 :
			PrintToChat(client, "\x04您已将出门近战设置为 \x03干草叉.");
		case 13 :
			PrintToChat(client, "\x04您已将出门近战设置为 \x03铲子.");
		case 14 :
			PrintToChat(client, "\x04您已将出门近战设置为 \x03小手枪.");
		case 15 :
			PrintToChat(client, "\x04您已将出门近战设置为 \x03马格南.");
	}
}





// ====================================================================================================
// bool
// ====================================================================================================

public bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}