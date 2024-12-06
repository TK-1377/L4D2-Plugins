#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>
#include <l4d2util>
#include <colors>

#define CVAR_FLAGS					FCVAR_NOTIFY

bool BoxShow = true;
char BoxColors[2][12] =
{
	"0 150 255",
	"208 0 208"
};
int BoxApertureColors[2][4] =
{
	{0, 150, 255, 255},
	{208, 0, 208, 255}
};
int BoxModelIndex;
int BoxAlpha = 255;
bool TPSound = true;
int TPTextType = 2;
float TPColdTime = 3.0;
float TPDistanceLimit = 100.0;
float BulletNoLostDistance = 200.0;
bool BoxAperture = true;

ConVar GBoxShow;
ConVar GBoxColors[2];
ConVar GBoxAlpha;
ConVar GTPSound;
ConVar GTPTextType;
ConVar GTPColdTime;
ConVar GTPDistanceLimit;
ConVar GBulletNoLostDistance;
ConVar GBoxAperture;

bool TPOpen = false;
int TPBoxNumber = 0;
bool CanCheck[32] = {true, ...};
bool CanTP[32] = {true, ...};
float BoxPos[2][3];
float BoxAperturePos[2][3];
int BoxEntityID[2];
Handle BoxApertureTimer[2];

public void OnPluginStart()
{
	GBoxShow						=  CreateConVar("l4d2_updp_box_show",
													"1",
													"启用传送点光柱显示. (0 = 禁用, 1 = 启用)",
													CVAR_FLAGS, true, 0.0, true, 1.0);
	GBoxColors[0]					=  CreateConVar("l4d2_updp_box1_colors",
													"0 150 255",
													"传送点1光柱颜色.",
													CVAR_FLAGS);
	GBoxColors[1]					=  CreateConVar("l4d2_updp_box2_colors",
													"208 0 208",
													"传送点2光柱颜色.",
													CVAR_FLAGS);
	GBoxAlpha						=  CreateConVar("l4d2_updp_box_alpha",
													"255",
													"传送点光柱透明度. (0 = 完全透明, 255 = 完全不透明)",
													CVAR_FLAGS, true, 0.0, true, 255.0);
	GTPSound						=  CreateConVar("l4d2_updp_tp_sound",
													"1",
													"启用传送音效提示. (0 = 禁用, 1 = 启用)",
													CVAR_FLAGS, true, 0.0, true, 1.0);
	GTPTextType						=  CreateConVar("l4d2_updp_tp_text_type",
													"2",
													"传送点文本提示.\n 0 = 不提示\n 1 = 仅提示玩家\n 2 = 提示安放传送点的玩家和距离",
													CVAR_FLAGS, true, 0.0, true, 2.0);
	GTPColdTime						=  CreateConVar("l4d2_updp_tp_coldtime",
													"3.0",
													"传送的冷却时间.",
													CVAR_FLAGS, true, 1.0);
	GTPDistanceLimit				=  CreateConVar("l4d2_updp_tp_distance_limit",
													"100.0",
													"距离传送点多近可以传送? (此值不建议太大)",
													CVAR_FLAGS, true, 30.0);
	GBulletNoLostDistance			=  CreateConVar("l4d2_updp_bullet_no_lost_distance",
													"200.0",
													"距离传送点多近可以不消耗子弹? (0.0 = 不启用)",
													CVAR_FLAGS, true, 0.0);
	GBoxAperture					=  CreateConVar("l4d2_updp_box_aperture",
													"1",
													"启用显示传送光圈. (0 = 禁用, 1 = 启用)",
													CVAR_FLAGS, true, 0.0, true, 1.0);

	GBoxShow.AddChangeHook(ConVarChanged);
	GBoxColors[0].AddChangeHook(ConVarChanged);
	GBoxColors[1].AddChangeHook(ConVarChanged);
	GBoxAlpha.AddChangeHook(ConVarChanged);
	GTPSound.AddChangeHook(ConVarChanged);
	GTPTextType.AddChangeHook(ConVarChanged);
	GTPColdTime.AddChangeHook(ConVarChanged);
	GTPDistanceLimit.AddChangeHook(ConVarChanged);
	GBulletNoLostDistance.AddChangeHook(ConVarChanged);
	GBoxAperture.AddChangeHook(ConVarChanged);
	
	HookEvent("round_start",				Event_RoundStart,				EventHookMode_PostNoCopy);
	HookEvent("round_end",					Event_RoundEnd,					EventHookMode_PostNoCopy);
	HookEvent("upgrade_pack_used",			Event_UpgradePackUsed);
	HookEvent("weapon_fire",				Event_WeaponFire);

	AutoExecConfig(true, "l4d2_upammo_pack_delivery_point");
}





// ====================================================================================================
// ConVarChanged
// ====================================================================================================

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	BoxShow = GBoxShow.BoolValue;

	int TempI;
	char Buffers[3][4];
	for (int i = 0; i < 2 ; i++)
	{
		GBoxColors[i].GetString(BoxColors[i], sizeof(BoxColors[]));
		TrimString(BoxColors[i]);

		ExplodeString(BoxColors[i], " ", Buffers, sizeof(Buffers), sizeof(Buffers[]));
		for (int j = 0; j < 3 ; j++)
		{
			TempI = StringToInt(Buffers[j]);
			if (TempI < 0 || TempI > 255)
				continue;
			BoxApertureColors[i][j] = TempI;
		}
	}

	BoxAlpha				= GBoxAlpha.IntValue;
	TPSound					= GTPSound.BoolValue;
	TPTextType				= GTPTextType.IntValue;
	TPColdTime				= GTPColdTime.FloatValue;
	TPDistanceLimit			= GTPDistanceLimit.FloatValue;
	BulletNoLostDistance	= GBulletNoLostDistance.FloatValue;
	BoxAperture				= GBoxAperture.BoolValue;

	if (!BoxAperture)
	{
		for (int i = 0; i < 2 ; i++)
		{
			if (BoxApertureTimer[i] != null)
				delete BoxApertureTimer[i];
		}
	}
}





// ====================================================================================================
// Game void
// ====================================================================================================

public void OnMapStart()
{
	BoxModelIndex = PrecacheModel("sprites/laserbeam.vmt", true);
	PrecacheSound("ui/gift_drop.wav", true);
}

public void OnMapEnd()
{
	for (int i = 0; i < 2 ; i++)
	{
		if (BoxEntityID[i] > 0 && IsValidEdict(BoxEntityID[i]))
			RemoveEntity(BoxEntityID[i]);
		BoxEntityID[i] = INVALID_ENT_REFERENCE;

		if (BoxApertureTimer[i] != null)
			delete BoxApertureTimer[i];
	}
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		CanCheck[i] = true;
		CanTP[i] = true;
	}

	TPOpen = false;
	TPBoxNumber = 0;
	for (int i = 0; i < 2 ; i++)
	{
		BoxPos[i] = NULL_VECTOR;
		BoxAperturePos[i] = NULL_VECTOR;
		BoxEntityID[i] = INVALID_ENT_REFERENCE;
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	OnMapEnd();
}

public void Event_UpgradePackUsed(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!CIsSurvivor(client) || !IsPlayerAlive(client) || IsFakeClient(client))
		return;

	float ClientPos[3];
	GetClientAbsOrigin(client, ClientPos);

	int CreateTPBoxCI = TPBoxNumber % 2;

	if (TPTextType > 0)
	{
		CPrintToChatAll("{orange}[提示] {blue}%N {default}%s安放了{olive}传送点{default}[{orange}%d{default}].",
						client,
						TPBoxNumber < 2 ? "" : "重新",
						CreateTPBoxCI + 1);
	}

	TPBoxNumber ++;
	if (!TPOpen && TPBoxNumber >= 2)
	{
		TPOpen = true;
		CPrintToChatAll("{orange}[提示] {olive}传送点已连接.");
	}

	if (TPTextType > 1)
	{
		float OtherPos[3], Distance;
		for (int i = 1; i <= MaxClients ; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !IsFakeClient(i) && i != client)
			{
				GetClientAbsOrigin(i, OtherPos);
				Distance = GetVectorDistance(ClientPos, OtherPos);
				CPrintToChat(i, "{orange}[提示] {olive}该传送点{default}距离你 {blue}%.1f", Distance);
			}
		}
	}
	
	if (BoxShow)
		CreateTrigger(client, CreateTPBoxCI);
}

public void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	if (BulletNoLostDistance <= 0.0 || TPBoxNumber <= 0)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!CIsSurvivor(client) || !IsPlayerAlive(client) || !IsNearTPBox(client, BulletNoLostDistance))
		return;

	int wepid = event.GetInt("weaponid");

	if (!IsAllowWepid(wepid))
		return;

	int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

	if (!IsValidEdict(weapon))
		return;
	
	int Clips = GetEntProp(weapon, Prop_Data, "m_iClip1");

	if (Clips >= 0)
		SetEntProp(weapon, Prop_Data, "m_iClip1", Clips + 1);
}





// ====================================================================================================
// Game Action
// ====================================================================================================

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3],
					int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (!TPOpen)
		return Plugin_Continue;
	
	if (!CIsSurvivor(client) || !IsPlayerAlive(client) || IsFakeClient(client) || !IsPlayerState(client))
		return Plugin_Continue;

	if (!CanCheck[client] || !CanTP[client])
		return Plugin_Continue;

	if (!(buttons & IN_DUCK))
		return Plugin_Continue;

	CanCheck[client] = false;
	CreateTimer(0.1, CheckPlayerPos, client);
	CreateTimer(0.3, ReCold_CanCheck, client);
	return Plugin_Continue;
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

public Action CheckPlayerPos(Handle timer, int client)
{
	if (!CIsSurvivor(client) || !IsPlayerAlive(client) || !IsPlayerState(client) || !ClientIsDuck(client))
		return Plugin_Continue;

	float ClientPos[3], Distance;
	GetClientAbsOrigin(client, ClientPos);

	int OriginNearTPBoxCI = -1;

	for (int i = 0; i < 2 ; i ++)
	{
		Distance = GetVectorDistance(ClientPos, BoxPos[i]);
		if (Distance <= TPDistanceLimit)
		{
			OriginNearTPBoxCI = i;
			break;
		}
	}

	if (OriginNearTPBoxCI == -1)
		return Plugin_Continue;

	int TargetTPBoxCI = 1 - OriginNearTPBoxCI;
	ForceCrouch(client);
	TeleportEntity(client, BoxPos[TargetTPBoxCI], NULL_VECTOR, NULL_VECTOR);
	if (TPSound)
		EmitSoundToClient(client, "ui/gift_drop.wav");
	CanTP[client] = false;
	CreateTimer(TPColdTime, ReCold_CanTP, client, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action ReCold_CanCheck(Handle timer, int client)
{
	CanCheck[client] = true;
	return Plugin_Continue;
}

public Action ReCold_CanTP(Handle timer, int client)
{
	CanTP[client] = true;
	return Plugin_Continue;
}

public Action ShowBoxAperture(Handle timer, int CI)
{
	TE_SetupBeamRingPoint(BoxAperturePos[CI],
						35.0,
						BulletNoLostDistance * 2.0,
						BoxModelIndex,
						0,
						0,
						0,
						1.0,
						1.0,
						0.0,
						BoxApertureColors[CI],
						0,
						0);
	TE_SendToAll();
	return Plugin_Continue;
}





// ====================================================================================================
// Box
// ====================================================================================================

public void CreateTrigger(int client, int CI)
{
	float ClientPos[3];
	GetClientAbsOrigin(client, ClientPos);
	for (int i = 0; i < 3 ; i ++)
	{
		BoxPos[CI][i] = ClientPos[i];
		BoxAperturePos[CI][i] = ClientPos[i];
	}
	BoxAperturePos[CI][2] += 20.0;
	char sAlpha[4];
	IntToString(BoxAlpha, sAlpha, sizeof(sAlpha));
	int entity = CreateEntityByName("beam_spotlight");
	DispatchKeyValue(entity, "targetname", "l4d_random_beam_item");
	DispatchKeyValue(entity, "spawnflags", "3");
	DispatchKeyValue(entity, "rendercolor", BoxColors[CI]);
	DispatchKeyValue(entity, "renderamt", sAlpha);
	DispatchKeyValueFloat(entity, "SpotlightLength", 1500.0);
	DispatchKeyValueFloat(entity, "SpotlightWidth", 30.0);
	DispatchKeyValueFloat(entity, "HDRColorScale", 2.0);
	DispatchKeyValueVector(entity, "origin", ClientPos);
	DispatchKeyValueVector(entity, "angles", view_as<float>({270.0, 0.0, 0.0}));
	DispatchSpawn(entity);

	if (BoxEntityID[CI] > 0 && IsValidEdict(BoxEntityID[CI]))
		RemoveEntity(BoxEntityID[CI]);

	BoxEntityID[CI] = entity;

	if (!BoxAperture || BulletNoLostDistance <= 35.0)
		return;

	if (BoxApertureTimer[CI] == null)
		BoxApertureTimer[CI] = CreateTimer(1.0, ShowBoxAperture, CI, TIMER_REPEAT);
}





// ====================================================================================================
// void
// ====================================================================================================

public void ForceCrouch(int client)
{
	SetEntProp(client, Prop_Send, "m_bDucked", 1);
	SetEntProp(client, Prop_Send, "m_fFlags", GetEntProp(client, Prop_Send, "m_fFlags")|FL_DUCKING);
}





// ====================================================================================================
// Bool
// ====================================================================================================

public bool CIsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

public bool IsPlayerState(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated") && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

public bool ClientIsDuck(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_bDucked"));	
}

public bool IsAllowWepid(int wepid)
{
	return ((wepid >= 1 && wepid <= 11) || wepid == 26 || (wepid >= 32 && wepid <= 37));
}

public bool IsNearTPBox(int client, float LimitDistance)
{
	if (TPBoxNumber <= 0)
		return false;

	float ClientPos[3], Distance;
	GetClientAbsOrigin(client, ClientPos);
	int i_Max = TPBoxNumber >= 2 ? 2 : TPBoxNumber;
	for (int i = 0; i < i_Max ; i++)
	{
		Distance = GetVectorDistance(ClientPos, BoxPos[i]);
		if (Distance <= LimitDistance)
			return true;
	}
	return false;
}