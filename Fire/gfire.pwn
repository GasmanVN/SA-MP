/*==============================================================================

   *******************
   **G Custom Fire**
   *******************
		>Credits<
	   -NhatNguyen-
	-Meta:->Thank for First script(BEST)
	
	->Callbacks
	public OnPlayerExtinguishFire(playerid,fireid);
	public OnPlayerExtinguishedFire(playerid,fireid);
	public OnPlayerBurning(playerid);
	->Functions
	native CreateFire(Float:x, Float:y, Float:z,world,interior,firetype,Float:radiusburn);
	native DestroyFire(id);

==============================================================================*/
///////////////////////////////////////////////////////////////////////////////////////////////////////////
#if !defined MAX_FIRES
#define MAX_FIRES						10000
#endif

#define GFire_BurnOthers								
#define GFire_CanBurnPlayers              1
#define GFire_BURNING_RADIUS 				1.2     	
#define GFire_ONFOOT_RADIUS				1.5			
#define GFire_PISSING_DISTANCE			2.0			
#define GFire_CAR_RADIUS					7.0			
#define GFire_Z_DIFFERENCE				2.5			
#define FIRE_UPDATE_TIMER_DELAY     		500     			
#define EXTINGUISH_TIME_VEHICLE				2					
#define EXTINGUISH_TIME_ONFOOT				4					
#define EXTINGUISH_TIME_PEEING				10			
#define EXTINGUISH_TIME_PLAYER				2			
#define GFire_FIRE_OBJECT_SLOT			9

#define GFIRE_TYPE_NORMAL					1
#define GFIRE_TYPE_LARGER					2

#if !defined SPECIAL_ACTION_PISSING
	#define SPECIAL_ACTION_PISSING	(68)
#endif
//===================== forwards ====================
//native
forward CreateFire(Float:x, Float:y, Float:z,world,interior,firetype,Float:radiusburn);
forward DestroyFire(id);

//gameplay forward
forward OnPlayerExtinguishFire(playerid,fireid);
forward OnPlayerExtinguishedFire(playerid,fireid);
forward OnPlayerBurning(playerid);
//script forward
forward RemoveSmokeFromFire(id);
forward TogglePlayerBurning(playerid, burning);
forward OnFireUpdate();
forward ExtinguishTimer(playerid, id);
forward BurningTimer(playerid);

//===================== Variables ====================

enum FlameInfo
{
	GFire_id,
	GFire_Exists,
	Float:GFire_pos[3],
	GFire_Smoke[5],
	Float:GFire_RadiusBurn,
}

new GFire_Data[MAX_FIRES][FlameInfo];
new PlayerFireTimer[MAX_PLAYERS][3]; // Burn, StopBurn, Extinguish a fire
new Float:PlayerOnFireHP[MAX_PLAYERS];
new AaF_cache[MAX_PLAYERS] = { -1, ... };
new AaF_cacheTime[MAX_PLAYERS];
//======================Init Fire=====================
G_InitFire()
{
	for(new i; i < MAX_PLAYERS; i++)
	{
	    PlayerFireTimer[i][2] = -1;
	}
	SetTimer("OnFireUpdate", FIRE_UPDATE_TIMER_DELAY, 1);
	return 1;
}
G_FireExit()
{
	for(new i; i < MAX_FIRES; i++)
	{
	    DestroyFire(i);
	}
	for(new playerid; playerid < MAX_PLAYERS; playerid++)
	{
		if(GetPVarInt(playerid, "GFire_IsOnFire") && !GFire_CanPlayerBurn(playerid, 1))
		{
			TogglePlayerBurning(playerid, false);
		}
	}
	return 1;
}
//Server Public
public OnFireUpdate()
{
	new aim, piss;
	for(new playerid; playerid < MAX_PLAYERS; playerid++)
	{
        aim = -1; piss = -1;
	    if(!IsPlayerConnected(playerid) || IsPlayerNPC(playerid)) { continue; }
		if(GetPVarInt(playerid, "GFire_IsOnFire") && !GFire_CanPlayerBurn(playerid, 1))
		{
			TogglePlayerBurning(playerid, false);
		}
		if(GFire_Pissing_at_Flame(playerid) != -1 || GFire_Aiming_at_Flame(playerid) != -1)
		{
			piss = GFire_Pissing_at_Flame(playerid); aim = GFire_Aiming_at_Flame(playerid);
	        CallLocalFunction("OnPlayerExtinguishFire","ii",playerid,aim);
			if(PlayerFireTimer[playerid][2] == -1 && ((aim != -1 && GFire_Pressing(playerid) & KEY_FIRE) || piss != -1))
			{
			    new value, time, Float:x, Float:y, Float:z;
			    if(piss != -1)
			    {
					value = piss;
					time = EXTINGUISH_TIME_PEEING;
				}
				else if(aim != -1)
				{
					value = aim;
					if(GetPlayerWeapon(playerid) == 41)
					{
						CreateExplosion(GFire_Data[value][GFire_pos][0], GFire_Data[value][GFire_pos][1], GFire_Data[value][GFire_pos][2], 2, 5);
						continue;
					}
					if(IsPlayerInAnyVehicle(playerid))
					{
					    time = EXTINGUISH_TIME_VEHICLE;
					}
					else
					{
						time = EXTINGUISH_TIME_ONFOOT;
					}
				}
				if(value < -1)
				{
					time = EXTINGUISH_TIME_PLAYER;
				}
				time *= 1000;
				if(value >= -1)
				{
					x = GFire_Data[value][GFire_pos][0];
				    y = GFire_Data[value][GFire_pos][1];
				    z = GFire_Data[value][GFire_pos][2];
				    RemoveSmokeFromFire(value);
					GFire_Data[value][GFire_Smoke][0] = CreateDynamicObject(18725, x, y, z, 0.0, 0.0, 0.0);
					GFire_Data[value][GFire_Smoke][1] = CreateDynamicObject(18725, x+1, y, z, 0.0, 0.0, 0.0);
					GFire_Data[value][GFire_Smoke][2] = CreateDynamicObject(18725, x-1, y, z, 0.0, 0.0, 0.0);
					GFire_Data[value][GFire_Smoke][3] = CreateDynamicObject(18725, x, y+1, z, 0.0, 0.0, 0.0);
					GFire_Data[value][GFire_Smoke][4] = CreateDynamicObject(18725, x, y-1, z, 0.0, 0.0, 0.0);
				}
				PlayerFireTimer[playerid][2] = SetTimerEx("ExtinguishTimer", time, 0, "dd", playerid, value);
			}
		}
		if(GFire_CanPlayerBurn(playerid) && GFire_IsAtFlame(playerid))
		{
			TogglePlayerBurning(playerid, true);
		}
		#if defined GFire_BurnOthers
		new Float:x, Float:y, Float:z;
		for(new i; i < MAX_PLAYERS; i++)
	  	{
	  	    if(playerid != i && IsPlayerConnected(i) && !IsPlayerNPC(i))
		  	{
			  	if(GFire_CanPlayerBurn(i) && GetPVarInt(playerid, "GFire_IsOnFire") && !GetPVarInt(i, "GFire_IsOnFire"))
	  	    	{
				  	GetPlayerPos(i, x, y, z);
					if(IsPlayerInRangeOfPoint(playerid, GFire_BURNING_RADIUS, x, y, z))
					{
					    TogglePlayerBurning(i, true);
					}
				}
			}
		}
		#endif
 	}
	return 1;
}
//===================== Own Publics ====================

public CreateFire(Float:x, Float:y, Float:z,world,interior,firetype,Float:radiusburn)
{
	new slot = GFire_GetFlameSlot();
	if(slot == -1) {return slot;}
	GFire_Data[slot][GFire_Exists] = 1;
	GFire_Data[slot][GFire_pos][0] = x;
	GFire_Data[slot][GFire_pos][1] = y;
	GFire_Data[slot][GFire_pos][2] = z - GFire_Z_DIFFERENCE;
	switch(firetype)
	{
	case 1:GFire_Data[slot][GFire_id] = CreateDynamicObject(18689, GFire_Data[slot][GFire_pos][0], GFire_Data[slot][GFire_pos][1], GFire_Data[slot][GFire_pos][2], 0.0, 0.0, 0.0,world,interior);
	case 2:GFire_Data[slot][GFire_id] = CreateDynamicObject(18691, GFire_Data[slot][GFire_pos][0], GFire_Data[slot][GFire_pos][1], GFire_Data[slot][GFire_pos][2], 0.0, 0.0, 0.0,world,interior);
	}
	GFire_Data[slot][GFire_RadiusBurn] = radiusburn;
	for(new i; i < 5; i++)
	{
		GFire_Data[slot][GFire_Smoke][i] = -1;
	}
	return slot;
}

public DestroyFire(id)
{
 	DestroyDynamicObject(GFire_Data[id][GFire_id]);
	GFire_Data[id][GFire_Exists] = 0;
	GFire_Data[id][GFire_pos][0] = 0.0;
	GFire_Data[id][GFire_pos][1] = 0.0;
	GFire_Data[id][GFire_pos][2] = 0.0;
	RemoveSmokeFromFire(id);
	return 1;
}
stock FireIsValid(id)
{
	if(GFire_Data[id][GFire_Exists] == 1) return 1;
	return 0;
}
public RemoveSmokeFromFire(id)
{
    for(new i; i < 5; i++)
	{
		DestroyDynamicObject(GFire_Data[id][GFire_Smoke][i]);
		GFire_Data[id][GFire_Smoke][i] = -1;
	}
}
public ExtinguishTimer(playerid, id)
{
	if(id < -1 && (GFire_Aiming_at_Flame(playerid) == id || GFire_Pissing_at_Flame(playerid) == id)) { TogglePlayerBurning(id+MAX_PLAYERS, false); }
	else if(GFire_Data[id][GFire_Exists] && ((GFire_Pressing(playerid) & KEY_FIRE && GFire_Aiming_at_Flame(playerid) == id) || (GFire_Pissing_at_Flame(playerid) == id)))
	{
 		if(GFire_Pissing_at_Flame(playerid) == id)
		{
		    CallLocalFunction("OnPlayerExtinguishedFire","ii",playerid,id);
		}
		else if(GFire_Aiming_at_Flame(playerid) == id)
		{
		    CallLocalFunction("OnPlayerExtinguishedFire","ii",playerid,id);
		}
	    DestroyFire(id);
	}
	KillTimer(PlayerFireTimer[playerid][2]);
	PlayerFireTimer[playerid][2] = -1;
}
public TogglePlayerBurning(playerid, burning)
{
	if(burning)
	{
	    SetPlayerAttachedObject(playerid, GFire_FIRE_OBJECT_SLOT, 18690, 2, -1, 0, -1.9, 0, 0);
		GetPlayerHealth(playerid, PlayerOnFireHP[playerid]);
		KillTimer(PlayerFireTimer[playerid][0]); KillTimer(PlayerFireTimer[playerid][1]);
		PlayerFireTimer[playerid][0] = SetTimerEx("BurningTimer",250, 1, "d", playerid);
		PlayerFireTimer[playerid][1] = SetTimerEx("TogglePlayerBurning", 7000, 0, "dd", playerid, 0);
	}
	else
	{
		KillTimer(PlayerFireTimer[playerid][0]);
		RemovePlayerAttachedObject(playerid, GFire_FIRE_OBJECT_SLOT);
	}
	SetPVarInt(playerid, "GFire_IsOnFire", burning);
	return 1;
}
public BurningTimer(playerid)
{
	if(GetPVarInt(playerid, "GFire_IsOnFire"))
	{
	    CallLocalFunction("OnPlayerBurning","i",playerid);
	    new Float:hp;
	    GetPlayerHealth(playerid, hp);
	    if(hp < PlayerOnFireHP[playerid])
	    {
	        PlayerOnFireHP[playerid] = hp;
		}
	    PlayerOnFireHP[playerid] -= 0.09;
		SetPlayerHealth(playerid, PlayerOnFireHP[playerid]);
	}
	else { KillTimer(PlayerFireTimer[playerid][0]); KillTimer(PlayerFireTimer[playerid][1]); }
}
//===================== stocks ====================
stock GFire_GetXYInFrontOfPlayer(playerid, &Float:x, &Float:y, &Float:z, &Float:a, Float:distance)
{
	GetPlayerPos(playerid, x, y ,z);
	if(IsPlayerInAnyVehicle(playerid))
	{
		GetVehicleZAngle(GetPlayerVehicleID(playerid),a);
	}
	else
	{
		GetPlayerFacingAngle(playerid, a);
	}
	x += (distance * floatsin(-a, degrees));
	y += (distance * floatcos(-a, degrees));
	return 0;
}

stock Float:GF_GetDistanceBetweenPointss(Float:x1,Float:y1,Float:z1,Float:x2,Float:y2,Float:z2) //By Gabriel "Larcius" Cordes
{
	return floatadd(floatadd(floatsqroot(floatpower(floatsub(x1,x2),2)),floatsqroot(floatpower(floatsub(y1,y2),2))),floatsqroot(floatpower(floatsub(z1,z2),2)));
}

stock Float:_DistanceCameraTargetToLocation(Float:CamX, Float:CamY, Float:CamZ, Float:ObjX, Float:ObjY, Float:ObjZ, Float:FrX, Float:FrY, Float:FrZ)
{
	new Float:TGTDistance;

	// get distance from camera to target
	TGTDistance = floatsqroot((CamX - ObjX) * (CamX - ObjX) + (CamY - ObjY) * (CamY - ObjY) + (CamZ - ObjZ) * (CamZ - ObjZ));

	new Float:tmpX, Float:tmpY, Float:tmpZ;

	tmpX = FrX * TGTDistance + CamX;
	tmpY = FrY * TGTDistance + CamY;
	tmpZ = FrZ * TGTDistance + CamZ;

	return floatsqroot((tmpX - ObjX) * (tmpX - ObjX) + (tmpY - ObjY) * (tmpY - ObjY) + (tmpZ - ObjZ) * (tmpZ - ObjZ));
}

stock GFire_IsPlayerAimingAt(playerid, Float:x, Float:y, Float:z, Float:radius)
{
	new Float:cx,Float:cy,Float:cz,Float:fx,Float:fy,Float:fz;
	GetPlayerCameraPos(playerid, cx, cy, cz);
	GetPlayerCameraFrontVector(playerid, fx, fy, fz);
	return (radius >= _DistanceCameraTargetToLocation(cx, cy, cz, x, y, z, fx, fy, fz));
}


//===================== Other Functions ====================

stock GFire_GetFireID(Float:x, Float:y, Float:z, &Float:dist)
{
	new id = -1;
	dist = 99999.99;
	for(new i; i < MAX_FIRES; i++)
	{
	    if(GF_GetDistanceBetweenPointss(x,y,z,GFire_Data[i][GFire_pos][0],GFire_Data[i][GFire_pos][1],GFire_Data[i][GFire_pos][2]) < dist)
	    {
	        dist = GF_GetDistanceBetweenPointss(x,y,z,GFire_Data[i][GFire_pos][0],GFire_Data[i][GFire_pos][1],GFire_Data[i][GFire_pos][2]);
	        id = i;
		}
	}
	return id;
}

stock GFire_CanPlayerBurn(playerid, val = 0)
{
	// && GetPlayerSkin(playerid) != 277 && GetPlayerSkin(playerid) != 278 && GetPlayerSkin(playerid) != 279 
	if(!GFire_IsPlayerInWater(playerid)&& ((!val && !GetPVarInt(playerid, "GFire_IsOnFire")) || (val && GetPVarInt(playerid, "GFire_IsOnFire")))) { return 1; }
	return 0;
}
stock GFire_IsPlayerInWater(playerid)
{
	new Float:X, Float:Y, Float:Z, an = GetPlayerAnimationIndex(playerid);
	GetPlayerPos(playerid, X, Y, Z);
	if((1544 >= an >= 1538 || an == 1062 || an == 1250) && (Z <= 0 || (Z <= 41.0 && GFire_IsPlayerInArea(playerid, -1387, -473, 2025, 2824))) ||
	(1544 >= an >= 1538 || an == 1062 || an == 1250) && (Z <= 2 || (Z <= 39.0 && GFire_IsPlayerInArea(playerid, -1387, -473, 2025, 2824))))
	{
	    return 1;
 	}
 	return 0;
}

stock GFire_IsPlayerInArea(playerid, Float:MinX, Float:MaxX, Float:MinY, Float:MaxY)
{
	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);
	#pragma unused z
    if(x >= MinX && x <= MaxX && y >= MinY && y <= MaxY) { return 1; }
    return 0;
}

stock GFire_GetFlameSlot()
{
	for(new i = 0; i < MAX_FIRES; i++)
	{
		if(!GFire_Data[i][GFire_Exists]) { return i; }
	}
	return -1;
}

//===================== "" ====================

stock GFire_IsAtFlame(playerid)
{
	for(new i; i < MAX_FIRES; i++)
	{
	    if(GFire_Data[i][GFire_Exists])
		{
		    if(!IsPlayerInAnyVehicle(playerid) && (IsPlayerInRangeOfPoint(playerid, GFire_Data[i][GFire_RadiusBurn], GFire_Data[i][GFire_pos][0], GFire_Data[i][GFire_pos][1], GFire_Data[i][GFire_pos][2]+GFire_Z_DIFFERENCE) ||
  			IsPlayerInRangeOfPoint(playerid, GFire_Data[i][GFire_RadiusBurn], GFire_Data[i][GFire_pos][0], GFire_Data[i][GFire_pos][1], GFire_Data[i][GFire_pos][2]+GFire_Z_DIFFERENCE-1)))
		    {
				return 1;
			}
		}
	}
	return 0;
}


stock GFire_Aiming_at_Flame(playerid)
{
	if(gettime() - AaF_cacheTime[playerid] < 1)
  	{
  	    return AaF_cache[playerid];
 	}
 	AaF_cacheTime[playerid] = gettime();
 	
	new id = -1;
	new Float:dis = 99999.99;
	new Float:dis2;
	new Float:px, Float:py, Float:pz;
	new Float:x, Float:y, Float:z, Float:a;
	GFire_GetXYInFrontOfPlayer(playerid, x, y, z, a, 1);
	z -= GFire_Z_DIFFERENCE;
	
	new Float:cx,Float:cy,Float:cz,Float:fx,Float:fy,Float:fz;
	GetPlayerCameraPos(playerid, cx, cy, cz);
	GetPlayerCameraFrontVector(playerid, fx, fy, fz);
	
	for(new i; i < MAX_PLAYERS; i++)
	{
	    if(IsPlayerConnected(i) && GetPVarInt(i, "GFire_IsOnFire") && (GFire_IsInWaterCar(playerid) || GFire_HasExtinguisher(playerid) || GetPlayerWeapon(playerid) == 41 || GFire_Peeing(playerid)) && GetPVarInt(i, "GFire_IsOnFire"))
	    {
	        GetPlayerPos(i, px, py, pz);
	        if(!GFire_Peeing(playerid))
		 	{
	        	dis2 = _DistanceCameraTargetToLocation(cx, cy, cz, px, py, pz, fx, fy, fz);
 			}
 			else
 			{
 			    if(IsPlayerInRangeOfPoint(playerid, GFire_ONFOOT_RADIUS, px, py, pz))
				{
	        		dis2 = 0.0;
				}
 			}
	        if(dis2 < dis)
	        {
				dis = dis2;
	    		id = i;
	    		if(GFire_Peeing(playerid))
	    		{
	    		    return id;
				}
			}
		}
	}
	if(id != -1)
	{
	return id-MAX_PLAYERS;
	}
	for(new i; i < MAX_FIRES; i++)
	{
		if(GFire_Data[i][GFire_Exists])
		{
		    if(GFire_IsInWaterCar(playerid) || GFire_HasExtinguisher(playerid) || GetPlayerWeapon(playerid) == 41 || GFire_Peeing(playerid))
		    {
		        if(!GFire_Peeing(playerid))
				{
					dis2 = _DistanceCameraTargetToLocation(cx, cy, cz, GFire_Data[i][GFire_pos][0], GFire_Data[i][GFire_pos][1], GFire_Data[i][GFire_pos][2]+GFire_Z_DIFFERENCE, fx, fy, fz);
				}
				else
				{
				    dis2 = GF_GetDistanceBetweenPointss(x,y,z,GFire_Data[i][GFire_pos][0],GFire_Data[i][GFire_pos][1],GFire_Data[i][GFire_pos][2]);
				}
				if((IsPlayerInAnyVehicle(playerid) && dis2 < GFire_CAR_RADIUS && dis2 < dis) || (!IsPlayerInAnyVehicle(playerid) && ((dis2 < GFire_ONFOOT_RADIUS && dis2 < dis) || (GFire_Peeing(playerid) && dis2 < GFire_PISSING_DISTANCE && dis2 < dis))))
				{
				    dis = dis2;
				    id = i;
				}
			}
		}
	}
	if(id != -1)
	{
		if((IsPlayerInAnyVehicle(playerid) &&
		!IsPlayerInRangeOfPoint(playerid, 50, GFire_Data[id][GFire_pos][0], GFire_Data[id][GFire_pos][1], GFire_Data[id][GFire_pos][2]))
		||(!IsPlayerInAnyVehicle(playerid)  && !IsPlayerInRangeOfPoint(playerid, 5, GFire_Data[id][GFire_pos][0], GFire_Data[id][GFire_pos][1], GFire_Data[id][GFire_pos][2])))
		{
		id = -1;
		}
	}
	AaF_cache[playerid] = id;
	return id;
}

stock GFire_Pissing_at_Flame(playerid)
{
	if(GFire_Peeing(playerid))
	{
	    return GFire_Aiming_at_Flame(playerid);
	}
	return -1;
}

stock GFire_IsInWaterCar(playerid)
{
    if(GetVehicleModel(GetPlayerVehicleID(playerid)) == 407 || GetVehicleModel(GetPlayerVehicleID(playerid)) == 601) { return 1; }
	return 0;
}

stock GFire_HasExtinguisher(playerid)
{
    if(GetPlayerWeapon(playerid) == 42 && !IsPlayerInAnyVehicle(playerid)) { return 1; }
	return 0;
}

stock GFire_Peeing(playerid)
{
	return GetPlayerSpecialAction(playerid) == SPECIAL_ACTION_PISSING;
}

stock GFire_Pressing(playerid)
{
	new keys, updown, leftright;
	GetPlayerKeys(playerid, keys, updown, leftright);
	return keys;
}
