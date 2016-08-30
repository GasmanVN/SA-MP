/*==============================================================================

   *******************
   **G JerryCan **
   *******************
	>Credits<
	-Gasman a.k.a NhatNguyen-
	-Meta:->Thank for Fire script(BEST)
	-Incognito: Streamer
	-ZeeX: Zcmd
	-Mauzen: Mapandreas
	-Someone for some Function sorry i don't remember
	-------------------------------------------------------------------------

==============================================================================*/
#define GJERRYCAN_VERSION "v0.0.1a"
/*============
   Includes
=============*/
#include <a_samp>
#include <streamer>
#include <zcmd>
#include <mapandreas>
#include "gfire.pwn"
/*============
   Defines
=============*/
/***************G Explosion Type****************/
#define GEXPLOSION_TYPE_VERYSMALL	12
#define GEXPLOSION_TYPE_SMALL		11
#define GEXPLOSION_TYPE_MEDIUM		0
#define GEXPLOSION_TYPE_LARGER		2
#define GEXPLOSION_TYPE_VERYLARGER	10
/********************JERRYCAN********************/
#define MAX_JERRYCAN_FUELOBJECT		100
/*============
   Var & Enum
=============*/
enum pJerrycan
{
	jcFuelValue,
	jcObjectFuel[MAX_JERRYCAN_FUELOBJECT],
	jcObjectFuelWorld[MAX_JERRYCAN_FUELOBJECT],
	jcObjectFuelInterior[MAX_JERRYCAN_FUELOBJECT],
	jcObjectFuelCreated[MAX_JERRYCAN_FUELOBJECT],
	jcObjectFuelUsed,
	jcNowFire,
	jcObjectJerryCanCreated,
	jcObjectJerryCan,
	jcObjectJerryCanFuel,
	jcObjectJerryCanWorld,
	jcObjectJerryCanInterior,
}
new JerryCan_Data[MAX_PLAYERS][pJerrycan];
new PlayerText:JerryCanText[MAX_PLAYERS][3];
new
	bool:nHoldingKey[MAX_PLAYERS];
/*============
   Forward
=============*/
forward _nKeyCheck(playerid);
forward OnPlayerHoldingKey(playerid, key);
forward OnPlayerStopHoldingKey(playerid, key);
forward DestroyJerryCanFireObject(playerid, fireid);
forward ContinueFire(playerid, Float:x, Float:y, Float:z);
/*======================
   Function & Math
========================*/
stock Float:frandom(Float:max, Float:min = 0.0, dp = 4)
{
    new
        Float:mul = floatpower(10.0, dp),
        imin = floatround(min * mul),
        imax = floatround(max * mul);
    return float(random(imax - imin) + imin) / mul;
}
stock GetXYFromPoint(Float:x1, Float:y1, Float:distance, &Float:x2, &Float:y2)
{
	new Float:a=float(random(360));
	x2=x1+distance*floatsin(a,degrees);
	y2=y1+distance*floatcos(a,degrees);
}
stock GetXYInFrontOfPlayer(playerid, &Float:x, &Float:y, Float:distance)
{
	new
			Float:angle;
	GetPlayerPos(playerid, x, y, angle);
	GetPlayerFacingAngle(playerid, angle);
	if(GetPlayerVehicleID(playerid))
		GetVehicleZAngle(GetPlayerVehicleID(playerid), angle);
	x += (distance * floatsin(-angle, degrees));
	y += (distance * floatcos(-angle, degrees));
}
stock Float:GetDistance2Points(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2) //By Gabriel "Larcius" Cordes
{
	return floatadd(floatadd(floatsqroot(floatpower(floatsub(x1,x2),2)),floatsqroot(floatpower(floatsub(y1,y2),2))),floatsqroot(floatpower(floatsub(z1,z2),2)));
}
stock removePlayerWeapon(playerid, weaponid) return SetPlayerAmmo(playerid, weaponid, 0);
/*============
   Server Callbacks
=============*/
public OnFilterScriptInit()
{
	print("\n--------------------------------------");
	print("G:Jerry Can");
	print("VERSION: "GJERRYCAN_VERSION"");
	print("Gasman");
	print("--------------------------------------\n");
	MapAndreas_Init(MAP_ANDREAS_MODE_NOBUFFER);
	G_InitFire();
	return 1;
}
public OnFilterScriptExit()
{
	G_FireExit();
	return 1;
}
/*============
   Player Callbacks
=============*/

public OnPlayerDisconnect(playerid, reason)
{

	for(new i =0; i<MAX_JERRYCAN_FUELOBJECT; i++)
	{
		if(JerryCan_Data[playerid][jcObjectFuelCreated][i] == 1 && IsValidDynamicObject(JerryCan_Data[playerid][jcObjectFuel][i]))
		{
			DestroyDynamicObject(JerryCan_Data[playerid][jcObjectFuel][i]);
		}
	}
	return 1;
}
public OnPlayerConnect(playerid)
{
	///==Reset Player Var
	for(new i =0; i<MAX_JERRYCAN_FUELOBJECT; i++)
	{
		JerryCan_Data[playerid][jcObjectFuelCreated][i] = 0;
	}
	JerryCan_Data[playerid][jcFuelValue] = 0;
	JerryCan_Data[playerid][jcObjectFuelUsed] = 0;
	TogglePlayerHoldJerryCan(playerid, false);
	TogglePlayerPouredOutPetrol(playerid, false);
	///==Create Player TextDraw
	JerryCanText[playerid][0] = CreatePlayerTextDraw(playerid,497.000000, 23.000000, "JerryCanModel");
	PlayerTextDrawBackgroundColor(playerid,JerryCanText[playerid][0], 255);
	PlayerTextDrawFont(playerid,JerryCanText[playerid][0], 5);
	PlayerTextDrawLetterSize(playerid,JerryCanText[playerid][0], 0.500000, 1.000000);
	PlayerTextDrawColor(playerid,JerryCanText[playerid][0], -1);
	PlayerTextDrawSetOutline(playerid,JerryCanText[playerid][0], 0);
	PlayerTextDrawSetProportional(playerid,JerryCanText[playerid][0], 1);
	PlayerTextDrawSetShadow(playerid,JerryCanText[playerid][0], 1);
	PlayerTextDrawUseBox(playerid,JerryCanText[playerid][0], 1);
	PlayerTextDrawBoxColor(playerid,JerryCanText[playerid][0], 0);
	PlayerTextDrawTextSize(playerid,JerryCanText[playerid][0], 45.000000, 54.000000);
	PlayerTextDrawSetPreviewModel(playerid, JerryCanText[playerid][0], 1650);
	PlayerTextDrawSetPreviewRot(playerid, JerryCanText[playerid][0], 0.000000, 0.000000, 0.000000, 0.800000);
	PlayerTextDrawSetSelectable(playerid,JerryCanText[playerid][0], 0);

	JerryCanText[playerid][1] = CreatePlayerTextDraw(playerid,520.000000, 50.000000, "30");
	PlayerTextDrawAlignment(playerid,JerryCanText[playerid][1], 2);
	PlayerTextDrawBackgroundColor(playerid,JerryCanText[playerid][1], 255);
	PlayerTextDrawFont(playerid,JerryCanText[playerid][1], 2);
	PlayerTextDrawLetterSize(playerid,JerryCanText[playerid][1], 0.200000, 0.800000);
	PlayerTextDrawColor(playerid,JerryCanText[playerid][1], -1);
	PlayerTextDrawSetOutline(playerid,JerryCanText[playerid][1], 1);
	PlayerTextDrawSetProportional(playerid,JerryCanText[playerid][1], 1);
	PlayerTextDrawSetSelectable(playerid,JerryCanText[playerid][1], 0);

	JerryCanText[playerid][2] = CreatePlayerTextDraw(playerid,508.000000, 72.000000, "ld_poke:cdback");
	PlayerTextDrawBackgroundColor(playerid,JerryCanText[playerid][2], 255);
	PlayerTextDrawFont(playerid,JerryCanText[playerid][2], 4);
	PlayerTextDrawLetterSize(playerid,JerryCanText[playerid][2], 0.500000, 1.000000);
	PlayerTextDrawColor(playerid,JerryCanText[playerid][2], 80);
	PlayerTextDrawSetOutline(playerid,JerryCanText[playerid][2], 0);
	PlayerTextDrawSetProportional(playerid,JerryCanText[playerid][2], 1);
	PlayerTextDrawSetShadow(playerid,JerryCanText[playerid][2], 1);
	PlayerTextDrawUseBox(playerid,JerryCanText[playerid][2], 1);
	PlayerTextDrawBoxColor(playerid,JerryCanText[playerid][2], 255);
	PlayerTextDrawTextSize(playerid,JerryCanText[playerid][2], 24.000000, -35.000000);
	PlayerTextDrawSetSelectable(playerid,JerryCanText[playerid][2], 0);
	//
	return 1;
}
public OnPlayerSpawn(playerid) 
{
	GivePlayerWeapon(playerid, 1, 1);//Remove Fist Hud
	return 1;
}
public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(newkeys && !nHoldingKey[playerid])
	{
		SetPVarInt(playerid, "nKeyHold", newkeys);
	    _nKeyCheck(playerid);
	    nHoldingKey[playerid] = true;
	}
	if(newkeys & KEY_FIRE)
	{
		if(IsPlayerPouredOutPetrol(playerid)  == 1 && JerryCan_Data[playerid][jcObjectJerryCanCreated] == 0)
		{
			TogglePlayerHoldJerryCan(playerid, false);
			TogglePlayerPouredOutPetrol(playerid, false);

			
			PlayerTextDrawHide(playerid, JerryCanText[playerid][0]);
			PlayerTextDrawHide(playerid, JerryCanText[playerid][1]);
			PlayerTextDrawHide(playerid, JerryCanText[playerid][2]);
			new Float:x, Float:y, Float:z;
			GetPlayerPos(playerid, x, y, z);
			GetXYInFrontOfPlayer(playerid, x, y, 1.2);
			JerryCan_Data[playerid][jcObjectJerryCan] = CreateDynamicObject(1650, x, y, z-0.7, 0.0, 0.0, 0.0, GetPlayerVirtualWorld(playerid),
				GetPlayerInterior(playerid));
			JerryCan_Data[playerid][jcObjectJerryCanFuel] = JerryCan_Data[playerid][jcFuelValue];
			JerryCan_Data[playerid][jcFuelValue] = 0;
			JerryCan_Data[playerid][jcObjectJerryCanCreated] = 1;
			JerryCan_Data[playerid][jcObjectJerryCanWorld] = GetPlayerVirtualWorld(playerid);
			JerryCan_Data[playerid][jcObjectJerryCanInterior] = GetPlayerInterior(playerid);
		}
	}
	return 1;
}
public OnPlayerShootDynamicObject(playerid, weaponid, objectid, Float:x, Float:y, Float:z)
{
	for(new pid = 0, j = GetPlayerPoolSize(); pid <= j; pid++)
	{
		if(!IsPlayerConnected(pid)) continue;
		for(new i =0;i<MAX_JERRYCAN_FUELOBJECT;i++)
		{
			if(objectid == JerryCan_Data[pid][jcObjectFuel][i])
			{
				new Float:xa, Float:ya, Float:za;
				GetDynamicObjectPos(objectid, xa, ya, za);
				StartJerryCanFire(pid, xa, ya, za, JerryCan_Data[pid][jcObjectFuelWorld][i], JerryCan_Data[pid][jcObjectFuelInterior][i]);
				DestroyDynamicObject(objectid);
				JerryCan_Data[pid][jcObjectFuelCreated][i] = 0;
				JerryCan_Data[pid][jcObjectFuelUsed]--;
				for(new pl = 0, j2 = GetPlayerPoolSize(); pl <= j2; pl++)
				{
					if(!IsPlayerConnected(pl)) continue;
					Streamer_Update(pl);
				}
			}
		}
		if(objectid == JerryCan_Data[pid][jcObjectJerryCan] && JerryCan_Data[pid][jcObjectJerryCanCreated] == 1)
		{
			new Float:jcpos[3];
			GetDynamicObjectPos(objectid, jcpos[0], jcpos[1], jcpos[2]);
			DestroyDynamicObject(objectid);
			JerryCan_Data[pid][jcObjectJerryCanCreated] = 0;
			GExplosion(jcpos[0], jcpos[1], jcpos[2], GetExTypeJerryCanFuel(JerryCan_Data[pid][jcObjectJerryCanFuel]),
				JerryCan_Data[pid][jcObjectJerryCanWorld], JerryCan_Data[pid][jcObjectJerryCanInterior]);
			for(new pl = 0, j2 = GetPlayerPoolSize(); pl <= j2; pl++)
			{
				if(!IsPlayerConnected(pl)) continue;
				Streamer_Update(pl);
			}
		}
	}
	return 1;
}
public OnPlayerHoldingKey(playerid,key)
{
	if(IsPlayerHoldJerryCan(playerid) == 1 && key == 128 && JerryCan_Data[playerid][jcFuelValue]> 0
		&&JerryCan_Data[playerid][jcObjectFuelUsed] < MAX_JERRYCAN_FUELOBJECT-2 &&JerryCan_Data[playerid][jcObjectJerryCanCreated] == 0)
	{
		if(IsPlayerPouredOutPetrol(playerid)  == 0)
		{
			PlayerTextDrawShow(playerid, JerryCanText[playerid][0]);
		}
		JerryCan_Data[playerid][jcFuelValue]--;
		if(JerryCan_Data[playerid][jcFuelValue] <= 0)
		{
			TogglePlayerPouredOutPetrol(playerid, false);
			PlayerTextDrawHide(playerid, JerryCanText[playerid][0]);
			PlayerTextDrawHide(playerid, JerryCanText[playerid][1]);
			PlayerTextDrawHide(playerid, JerryCanText[playerid][2]);
		}
		else
		{
			new string[128];
			format(string, sizeof(string), "%d", JerryCan_Data[playerid][jcFuelValue]);
			PlayerTextDrawSetString(playerid, JerryCanText[playerid][1], string);
			PlayerTextDrawShow(playerid, JerryCanText[playerid][1]);
			PlayerTextDrawTextSize(playerid,JerryCanText[playerid][2], 29.000000, -((float(JerryCan_Data[playerid][jcFuelValue])/float(MAX_JERRYCAN_FUELOBJECT))*35.0));
			PlayerTextDrawShow(playerid, JerryCanText[playerid][2]);
			CreateJerryCanFuelObject(playerid);
			TogglePlayerPouredOutPetrol(playerid, true);
		}
	}
	return 1;
}
public OnPlayerStopHoldingKey(playerid,key)
{
	if(IsPlayerPouredOutPetrol(playerid) == 1 && key == 128)
	{
		TogglePlayerPouredOutPetrol(playerid, false);
		PlayerTextDrawHide(playerid, JerryCanText[playerid][0]);
		PlayerTextDrawHide(playerid, JerryCanText[playerid][1]);
		PlayerTextDrawHide(playerid, JerryCanText[playerid][2]);
	}
	return 1;
}
public _nKeyCheck(playerid)
{
	if(IsPlayerConnected(playerid))
	{
		new
		    keys, ud, lr;
		    
		GetPlayerKeys(playerid, keys, ud, lr);
		
		if(keys & GetPVarInt(playerid, "nKeyHold"))
		{
			CallLocalFunction("OnPlayerHoldingKey", "ii", playerid, GetPVarInt(playerid, "nKeyHold"));
		    SetTimerEx("_nKeyCheck", 300, 0, "i", playerid);
		    return 0;
		}
		else
		{
			CallLocalFunction("OnPlayerStopHoldingKey", "ii" ,playerid, GetPVarInt(playerid, "nKeyHold"));
		}
	}
	
	nHoldingKey[playerid] = false;
	
	return 0;
}/*
public OnPlayerUpdate(playerid)//Wiki
{
    new iCurWeap = GetPlayerWeapon(playerid); // Return the player's current weapon		
    if(iCurWeap != GetPVarInt(playerid, "iCurrentWeapon")) // If he changed weapons since the last update
    {
        // Lets call a callback named OnPlayerChangeWeapon
        OnPlayerChangeWeapon(playerid, GetPVarInt(playerid, "iCurrentWeapon"), iCurWeap);
        SetPVarInt(playerid, "iCurrentWeapon", iCurWeap);//Update the weapon variable
    }
    return 1; // Send this update to other players.
}
 
stock OnPlayerChangeWeapon(playerid, oldweapon, newweapon)
{
	if(newweapon == 0 && IsPlayerHoldJerryCan(playerid) == 1)
	{
		new string[128];
		format(string, sizeof(string), "%d", JerryCan_Data[playerid][jcFuelValue]);
		PlayerTextDrawSetString(playerid, JerryCanText[playerid][1], string);
		PlayerTextDrawShow(playerid, JerryCanText[playerid][0]);
		PlayerTextDrawShow(playerid, JerryCanText[playerid][1]);
		TogglePlayerHoldJerryCan(playerid, true);
	}
	else if(oldweapon == 0 && IsPlayerHoldJerryCan(playerid) == 1)
	{
		PlayerTextDrawHide(playerid, JerryCanText[playerid][0]);
		PlayerTextDrawHide(playerid, JerryCanText[playerid][1]);
		TogglePlayerHoldJerryCan(playerid, false);
	}
	return 1;
}*/
/*===============================
   Custome JerryCan Callbacks
=================================*/

public ContinueFire(playerid, Float:x, Float:y, Float:z)
{
	new Float:opos[3], Float:opos2[3], fcontinue = 0;
	if(JerryCan_Data[playerid][jcObjectJerryCanCreated] == 1)
	{
		new Float:jcpos[3];
		GetDynamicObjectPos(JerryCan_Data[playerid][jcObjectJerryCan], jcpos[0], jcpos[1], jcpos[2]);
		if(GetDistance2Points( x, y, z, jcpos[0], jcpos[1], jcpos[2]) < 2.2)
		{
			DestroyDynamicObject(JerryCan_Data[playerid][jcObjectJerryCan]);
			JerryCan_Data[playerid][jcObjectJerryCanCreated] = 0;
			GExplosion(jcpos[0], jcpos[1], jcpos[2], GetExTypeJerryCanFuel(JerryCan_Data[playerid][jcObjectJerryCanFuel]),
				JerryCan_Data[playerid][jcObjectJerryCanWorld], JerryCan_Data[playerid][jcObjectJerryCanInterior]);
			for(new pl = 0, j = GetPlayerPoolSize(); pl <= j; pl++)
			{
				if(!IsPlayerConnected(pl)) continue;
				Streamer_Update(pl);
			}
		}
	}
	for(new i =0;i<MAX_JERRYCAN_FUELOBJECT;i++)
	{
		if(JerryCan_Data[playerid][jcObjectFuelCreated][i] == 1)
		{
			GetDynamicObjectPos(JerryCan_Data[playerid][jcObjectFuel][i], opos[0], opos[1], opos[2]);
			if(GetDistance2Points( x, y, z, opos[0], opos[1], opos[2]) < 1.9)
			{
				new fire = CreateFire(opos[0], opos[1], opos[2]+0.7, JerryCan_Data[playerid][jcObjectFuelWorld][i], JerryCan_Data[playerid][jcObjectFuelInterior][i], 1, 1.2);
				DestroyDynamicObject(JerryCan_Data[playerid][jcObjectFuel][i]);
				JerryCan_Data[playerid][jcObjectFuelCreated][i] = 0;
				JerryCan_Data[playerid][jcObjectFuelUsed]--;
				fcontinue = 1;
				SetTimerEx("DestroyJerryCanFireObject", 15000, 0, "ii", playerid, fire);
				for(new pl = 0, j = GetPlayerPoolSize(); pl <= j; pl++)
				{
					if(!IsPlayerConnected(pl)) continue;
					Streamer_Update(pl);
				}
				break;
			}
		}
	}
	for(new pd = 0, j = GetPlayerPoolSize(); pd <= j; pd++)
	{
		if(!IsPlayerConnected(pd)) continue;
		if(pd != playerid) 
		{
			if(JerryCan_Data[pd][jcObjectJerryCanCreated] == 1)
			{
				new Float:jcpos[3];
				GetDynamicObjectPos(JerryCan_Data[pd][jcObjectJerryCan], jcpos[0], jcpos[1], jcpos[2]);
				if(GetDistance2Points( x, y, z, jcpos[0], jcpos[1], jcpos[2]) < 1.9)
				{
					DestroyDynamicObject(JerryCan_Data[pd][jcObjectJerryCan]);
					JerryCan_Data[pd][jcObjectJerryCanCreated] = 0;
					GExplosion(jcpos[0], jcpos[1], jcpos[2], GetExTypeJerryCanFuel(JerryCan_Data[pd][jcObjectJerryCanFuel]),
						JerryCan_Data[pd][jcObjectJerryCanWorld], JerryCan_Data[pd][jcObjectJerryCanInterior]);
					for(new pl = 0, j3 = GetPlayerPoolSize(); pl <= j3; pl++)
					{
						if(!IsPlayerConnected(pl)) continue;
						Streamer_Update(pl);
					}
				}
			}
			for(new i =0;i<MAX_JERRYCAN_FUELOBJECT;i++)
			{
				if(JerryCan_Data[pd][jcObjectFuelCreated][i] == 1)
				{
					GetDynamicObjectPos(JerryCan_Data[pd][jcObjectFuel][i], opos2[0], opos2[1], opos2[2]);
					if(GetDistance2Points(x,y,z, opos2[0], opos2[1], opos2[2]) < 2.2)
					{
						new fire = CreateFire(opos2[0], opos2[1], opos2[2]+0.7, JerryCan_Data[pd][jcObjectFuelWorld][i], JerryCan_Data[pd][jcObjectFuelInterior][i], 1, 1.2);
						DestroyDynamicObject(JerryCan_Data[pd][jcObjectFuel][i]);
						JerryCan_Data[pd][jcObjectFuelCreated][i] = 0;
						JerryCan_Data[pd][jcObjectFuelUsed]--;
						fcontinue = 1;
						SetTimerEx("DestroyJerryCanFireObject", 15000, 0, "ii", pd, fire);
						for(new pl = 0, j4 = GetPlayerPoolSize(); pl <= j4; pl++)
						{
							if(!IsPlayerConnected(pl)) continue;
							Streamer_Update(pl);
						}
						break;
					}
				}
			}
		}
	}
	if(fcontinue == 1)
		SetTimerEx("ContinueFire", 300, 0, "ifff", playerid, opos[0], opos[1], opos[2]);

	return 1;
}
public DestroyJerryCanFireObject(playerid, fireid)// Now playerid unused
{
	DestroyFire(fireid);
	return 1;
}
/*===============================
   JerryCan Functions
=================================*/
StartJerryCanFire(playerid, Float:x, Float:y, Float:z, world, interior)
{
	for(new pl = 0, j = GetPlayerPoolSize(); pl <= j; pl++)
	{
		if(!IsPlayerConnected(pl)) continue;
		Streamer_Update(pl);
	}
	new fire = CreateFire(x, y, z+0.7, world, interior, 1, 1.2);
	SetTimerEx("DestroyJerryCanFireObject", 15000, 0, "ii", playerid, fire);
	SetTimerEx("ContinueFire", 500, 0, "ifff", playerid, x, y, z);
	return 1;
}
CreateJerryCanFuelObject(playerid)
{
	new Float:x, Float:y, Float:z, amount;
	GetPlayerPos(playerid, x, y, z);
	GetXYInFrontOfPlayer(playerid, x, y, 1.7);
	MapAndreas_FindZ_For2DCoord(x, y, z);
	z+= 0.02;
	for(new i =0 ;i<MAX_JERRYCAN_FUELOBJECT;i++)
	{
		if(JerryCan_Data[playerid][jcObjectFuelCreated][i] == 0)
		{
			amount =i;
			break;
		}
	}
	JerryCan_Data[playerid][jcObjectFuelCreated][amount] = 1;

	JerryCan_Data[playerid][jcObjectFuel][amount] = CreateDynamicObject(19844, x, y, z, 0.0, 0.0, frandom(360.0,0.0),
		GetPlayerVirtualWorld(playerid), GetPlayerInterior(playerid));
	JerryCan_Data[playerid][jcObjectFuelWorld][amount] = GetPlayerVirtualWorld(playerid);
	JerryCan_Data[playerid][jcObjectFuelInterior][amount] = GetPlayerInterior(playerid);
	SetDynamicObjectMaterial(JerryCan_Data[playerid][jcObjectFuel][amount],0, 5069, "ctscene_las", "ruffroadlas");
	JerryCan_Data[playerid][jcObjectFuelUsed]++;
	return 1;
}

TogglePlayerHoldJerryCan(playerid, bool:toggle)
{
	if(JerryCan_Data[playerid][jcObjectJerryCanCreated] == 1) return printf("[JERRYCAN DEBUG]: Player %d has jerrycan before", playerid);
	if(toggle == true)
	{
		new string[128];
		format(string, sizeof(string), "%d", JerryCan_Data[playerid][jcFuelValue]);
		PlayerTextDrawSetString(playerid, JerryCanText[playerid][1], string);
		PlayerTextDrawShow(playerid, JerryCanText[playerid][1]);
		PlayerTextDrawShow(playerid, JerryCanText[playerid][0]);
		PlayerTextDrawTextSize(playerid,JerryCanText[playerid][2], 29.000000, -((float(JerryCan_Data[playerid][jcFuelValue])/float(MAX_JERRYCAN_FUELOBJECT))*35.0));
		PlayerTextDrawShow(playerid, JerryCanText[playerid][2]);
		SetPlayerAttachedObject(playerid, 0, 1650, 6, 0.169000, 0.015999, 0.000000, 2.699999, -42.100017, 0.000000, 1.000000, 0.882000, 1.516998, 0, 0);
		SetPVarInt(playerid,"G_UseJerryCan",1);
	}
	else
	{
		PlayerTextDrawHide(playerid, JerryCanText[playerid][1]);
		PlayerTextDrawHide(playerid, JerryCanText[playerid][0]);
		PlayerTextDrawHide(playerid, JerryCanText[playerid][2]);
		RemovePlayerAttachedObject(playerid, 0);
		SetPVarInt(playerid,"G_UseJerryCan",0);
	}
	return 1;
}
IsPlayerHoldJerryCan(playerid)
{
	return GetPVarInt(playerid, "G_UseJerryCan");
}
TogglePlayerPouredOutPetrol(playerid, bool:toggle)
{
	if(toggle == true)
	{
		GivePlayerWeapon(playerid, 42, 1);
		SetPlayerAttachedObject(playerid, 1, 18676, 6, 0.149000, -0.253999, 0.126999, -91.699974, 0.000000, -20.400001, 1.706000, 1.000000, 0.169998, 0, 0);
		SetPVarInt(playerid, "G_PouredOutPetrol", 1);
	}
	else
	{
		SetPVarInt(playerid, "G_PouredOutPetrol" ,0);
		RemovePlayerAttachedObject(playerid, 1);
		removePlayerWeapon(playerid, 42);
	}
	return 1;
}
IsPlayerPouredOutPetrol(playerid)
{
	return GetPVarInt(playerid, "G_PouredOutPetrol");
}
SetPlayerJerryCanFuel(playerid, value)
{
	JerryCan_Data[playerid][jcFuelValue] = value;
	if(JerryCan_Data[playerid][jcFuelValue] > MAX_JERRYCAN_FUELOBJECT)
		JerryCan_Data[playerid][jcFuelValue] = MAX_JERRYCAN_FUELOBJECT-1;
	if(IsPlayerHoldJerryCan(playerid) == 1)
	{
		new string[128];
		format(string, sizeof(string), "%d", JerryCan_Data[playerid][jcFuelValue]);
		PlayerTextDrawSetString(playerid, JerryCanText[playerid][1], string);
		PlayerTextDrawShow(playerid, JerryCanText[playerid][1]);
		PlayerTextDrawTextSize(playerid,JerryCanText[playerid][2], 29.000000, -((float(JerryCan_Data[playerid][jcFuelValue])/float(MAX_JERRYCAN_FUELOBJECT))*35.0));
		PlayerTextDrawShow(playerid, JerryCanText[playerid][2]);
	}
	return 1;
}
stock GivePlayerJerryCanFuel(playerid, value)// stock because now unused
{
	JerryCan_Data[playerid][jcFuelValue] += value;
	if(JerryCan_Data[playerid][jcFuelValue] > MAX_JERRYCAN_FUELOBJECT)
		JerryCan_Data[playerid][jcFuelValue] = MAX_JERRYCAN_FUELOBJECT-1;
	if(IsPlayerHoldJerryCan(playerid) == 1)
	{
		new string[128];
		format(string, sizeof(string), "%d", JerryCan_Data[playerid][jcFuelValue]);
		PlayerTextDrawSetString(playerid, JerryCanText[playerid][1], string);
		PlayerTextDrawShow(playerid, JerryCanText[playerid][1]);
		PlayerTextDrawTextSize(playerid,JerryCanText[playerid][2], 29.000000, -((float(JerryCan_Data[playerid][jcFuelValue])/float(MAX_JERRYCAN_FUELOBJECT))*35.0));
		PlayerTextDrawShow(playerid, JerryCanText[playerid][2]);
	}
	return 1;
}
/*===============================
   Custome Explosion Function
=================================*/
GExplosion(Float:X, Float:Y, Float:Z, type = GEXPLOSION_TYPE_MEDIUM,world = 0,interior = 0)
{
	new Float:x, Float:y, Float:z, Float:Radius;
	switch(type)
	{
		case GEXPLOSION_TYPE_VERYSMALL: 	Radius = 2.5;
		case GEXPLOSION_TYPE_SMALL: 		Radius = 4.5;
		case GEXPLOSION_TYPE_MEDIUM: 		Radius = 7.0;
		case GEXPLOSION_TYPE_LARGER: 		Radius = 10.0;
		case GEXPLOSION_TYPE_VERYLARGER: 	Radius = 14.0;
	}
	for(new i =0; i < GetAmountFireOfType(type); i++)
	{
		GetXYFromPoint(X,Y,frandom(Radius, -Radius), x, y);
		MapAndreas_FindZ_For2DCoord(x, y, z);
		z+= 1.3;
		new fire = CreateFire( x, y, z, world, interior, random(2)+1, frandom(1.5,1.2));
		SetTimerEx("DestroyJerryCanFireObject", 30000, 0, "ii", INVALID_PLAYER_ID, fire);
	}
	CreateExplosion(X, Y, Z, type, Radius);
	return 1;
}
stock GetAmountFireOfType(type)
{
	new amount;
	switch(type)
	{
		case GEXPLOSION_TYPE_VERYSMALL: 	amount = 2;
		case GEXPLOSION_TYPE_SMALL: 		amount = 4;
		case GEXPLOSION_TYPE_MEDIUM: 		amount = 6;
		case GEXPLOSION_TYPE_LARGER: 		amount = 8;
		case GEXPLOSION_TYPE_VERYLARGER: 	amount = 10;
		default: amount = 5;
	}
	return amount;
}
GetExTypeJerryCanFuel(fuel)
{
	new type;
	switch(fuel)
	{
		case 0..10:type = GEXPLOSION_TYPE_VERYSMALL;
		case 11..20:type = GEXPLOSION_TYPE_SMALL;
		case 21..30:type = GEXPLOSION_TYPE_MEDIUM;
		case 31..69:type = GEXPLOSION_TYPE_LARGER;
		case 70..500:type = GEXPLOSION_TYPE_VERYLARGER;
	}
	return type;
}
/*===============================
   COMMANDS
=================================*/
CMD:jerryfuel(playerid,params[]) return SetPlayerJerryCanFuel(playerid, strval(params));
CMD:jerrycan(playerid,params[])
{
	
	if(strval(params) == 1)
	{
		TogglePlayerHoldJerryCan(playerid, true);
	}
	else
	{
		TogglePlayerHoldJerryCan(playerid, false);
	}

	return 1;
}
