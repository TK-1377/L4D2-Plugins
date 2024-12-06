#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <clientprefs>

char WeaponName[20][16] = 
{
	"ammo",
	"smg",
	"smg_silenced",
	"pumpshotgun",
	"shotgun_chrome",
	"pistol",
	"pistol_magnum",
	"knife",
	"fireaxe",
	"machete",
	"katana",
	"crowbar",
	"golfclub",
	"cricket_bat",
	"baseball_bat",
	"frying_pan",
	"tonfa",
	"pitchfork",
	"shovel",
	"electric_guitar"
};

char SWName[15][12] = 
{
	"小手枪",
	"马格南",
	"小刀",
	"消防斧",
	"砍刀",
	"武士刀",
	"撬棍",
	"高尔夫球杆",
	"板球拍",
	"棒球棍",
	"平底锅",
	"警棍",
	"干草叉",
	"铲子",
	"电吉他"
};

int ClientPage[32];
int MyStartGiveWeapon[32] = {0, ...};
Cookie StartGive;
bool LeftSafeArea = false;

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
	StartGive = RegClientCookie("l4d2_shop_buy_start_give", "l4d2_shop_buy.smx", CookieAccess_Protected);

	RegConsoleCmd("sm_buy",		Command_Buy,		"玩家购物菜单.");

	HookEvent("round_start",				Event_RoundStart,				EventHookMode_PostNoCopy);
	HookEvent("player_left_safe_area",		Event_PlayerLeftSafeArea,		EventHookMode_PostNoCopy);

	if (bLate)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
				OnClientCookiesCached(i);
		}
	}
}





// ====================================================================================================
// Cookie
// ====================================================================================================

public void OnClientCookiesCached(int client)
{
	if (IsFakeClient(client))
		return;
	
	char TempStr[11];
	GetClientCookie(client, StartGive, TempStr, sizeof(TempStr));
	MyStartGiveWeapon[client] = StringToInt(TempStr);
}

public void OnClientDisconnect(int client)
{
	if (IsFakeClient(client))
		return;

	char TempStr[11];
	IntToString(MyStartGiveWeapon[client], TempStr, sizeof(TempStr));
	SetClientCookie(client, StartGive, TempStr);
	MyStartGiveWeapon[client] = 0;
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	LeftSafeArea = false;
}

public void Event_PlayerLeftSafeArea(Event event, const char[] name, bool dontBroadcast)
{
	if (LeftSafeArea)
		return;

	LeftSafeArea = true;
	Give_All();
}





// ====================================================================================================
// Command Action
// ====================================================================================================

public Action Command_Buy(int client, int args)
{
	if (!IsSurvivor(client) || !IsPlayerAlive(client) || IsFakeClient(client))
		return Plugin_Handled;

	Show_BuyMenu(client);
	return Plugin_Handled;
}





// ====================================================================================================
// Show Menu
// ====================================================================================================

public void Show_BuyMenu(int client)
{
	Handle menu = CreatePanel();
	SetPanelTitle(menu, "购物菜单");
	DrawPanelItem(menu, "初级武器");
	DrawPanelItem(menu, "加满子弹");
	DrawPanelItem(menu, "近战/手枪");
	DrawPanelItem(menu, "设置出门副武器");
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Buy_Menu, 15);
}

public void Show_MinGunMenu(int client)
{
	Handle menu = CreatePanel();
	SetPanelTitle(menu, "初级武器");
	DrawPanelItem(menu, "UZI");
	DrawPanelItem(menu, "SMG");
	DrawPanelItem(menu, "木喷");
	DrawPanelItem(menu, "铁喷");
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	SendPanelToClient(menu, client, MinGunMenu_Menu, 15);
}

public void Show_SecondaryWeaponMenu(int client, int Page)
{
	Handle menu = CreatePanel();
	SetPanelTitle(menu, "近战/手枪");
	for (int i = (Page * 8); i < (8 + 7 * Page) ; i++)
		DrawPanelItem(menu, SWName[i]);
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, Page == 0 ? "下一页" : "上一页");
	DrawPanelItem(menu, Page == 0 ? "关闭" : "返回");
	ClientPage[client] = Page;
	SendPanelToClient(menu, client, SecondaryWeapon_Menu, 15);
}

public void Show_StartGiveMenu(int client, int Page)
{
	Handle menu = CreatePanel();
	SetPanelTitle(menu, "设置出门副武器");
	for (int i = (Page * 8); i < (8 + 7 * Page) ; i++)
		DrawPanelItem(menu, SWName[i]);
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, Page == 0 ? "下一页" : "上一页");
	DrawPanelItem(menu, Page == 0 ? "关闭" : "返回");
	ClientPage[client] = Page;
	SendPanelToClient(menu, client, StartGive_Menu, 15);
}





// ====================================================================================================
// Menu
// ====================================================================================================

public int Buy_Menu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (itemNum)
			{
				case 1: 
					Show_MinGunMenu(client);
				case 2: 
					Give_Client(client, 0);
				case 3: 
					Show_SecondaryWeaponMenu(client, 0);
				case 4: 
					Show_StartGiveMenu(client, 0);
			}
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

public int MinGunMenu_Menu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (itemNum <= 4)
				Give_Client(client, itemNum);
			else if (itemNum == 5)
				Show_BuyMenu(client);
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

public int SecondaryWeapon_Menu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (itemNum <= (8 - ClientPage[client]))
				Give_Client(client, (ClientPage[client] * 8 + itemNum + 4));
			else if (itemNum == (9 - ClientPage[client]))
				Show_SecondaryWeaponMenu(client, (1 - ClientPage[client]));
			else
				Show_BuyMenu(client);
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

public int StartGive_Menu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (itemNum <= (8 - ClientPage[client]))
			{
				MyStartGiveWeapon[client] = itemNum + 8 * ClientPage[client];
				PrintToChat(client, "\x04[提示] \x05您已将出门副武器设置为: \x03%s", SWName[MyStartGiveWeapon[client] - 1]);
			}
			else if (itemNum == (9 - ClientPage[client]))
				Show_StartGiveMenu(client, (1 - ClientPage[client]));
			else
				Show_BuyMenu(client);
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}





// ====================================================================================================
// void
// ====================================================================================================

public void Give_All()
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !IsFakeClient(i) && MyStartGiveWeapon[i] > 0)
			Give_Client(i, (MyStartGiveWeapon[i] + 4));
	}
}

public void Give_Client(int client, int WeaponCI)
{
	if (!IsSurvivor(client) || !IsPlayerAlive(client) || IsFakeClient(client))
		return;

	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give %s", WeaponName[WeaponCI]);
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}





// ====================================================================================================
// Bool
// ====================================================================================================

public bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}