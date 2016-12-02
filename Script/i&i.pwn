/*	
  _____       _____ 
 |_   _|___  |_   _|
   | | ( _ )   | |  
   | | / _ \/\ | |  
  _| || (_>  <_| |_ 
 |_____\___/\/_____|
  *IVENTORY & ITEM*
  -----------------
  	  =Marines= 
Function: Inventory
|-AddInventoryItem
|-RemoveInventoryItem
|-ResetInventoryItem
|-PlayerInventoryArrange
|-GetInventoryFreeSlots
|-IsPlayerInventoryOpen
|-IsPlayerGearLootingOpen
|-IsPlayerNearLooting
|-Show/HidePlayerGearLooting
|-Show/HidePlayerInventory
|-SetInventoryTextInfo
Function: Item
|-CreateItem
|-DestroyItem
|-IsItemValid
|-GetItemObjectID
|-DeleteAllDefinedItems
|-DefineItemType
|-DefineItemDescription
|-GetItemTypeDescription
|-GetItemTypeModel
|-GetItemWeight
|-GetItemType
|-GetItemTypePreviewRot
|-GetItemTypeName
|-GetItemTypeRot
|-GetItemTypeColor
Callbacks: 
|=OnPlayerUseItem
|=OnPlayerDropItem
-------------------------------------------------------

*/
#include <a_samp>
#include <streamer>
#include <e_dialog>
#include <zcmd>
#include <YSI\y_iterate>
#include <crashdetect>

#define function:%0(%1) forward %0(%1); public %0(%1)

/*Item define and function misc*/
#define MAX_ITEMS 1000
#define MAX_DEFINE_ITEMS	100
/*TYPE EQUIP ITEM*/
#define ITEM_TYPE_NULL		0
#define ITEM_TYPE_TOOL		1
#define ITEM_TYPE_FOOD		2
#define ITEM_TYPE_MEDIC		3

// Offset from player Z coordinate to floor Z coordinate
#define FLOOR_OFFSET		(0.96)
/*******************************************************
 Inventory Function
******************************************************/

#define GetInventoryWeight(%0) PlayerInv[%0][pinv_Weight]
#define SetInventoryWeight(%0,%1) PlayerInv[%0][pinv_Weight] = (%1)
#define GiveInventoryWeight(%0,%1) PlayerInv[%0][pinv_Weight] += (%1)

#define GetInventoryMaxWeight(%0) PlayerInv[%0][pinv_MaxWeight]
#define SetInventoryMaxWeight(%0,%1) PlayerInv[%0][pinv_MaxWeight] = (%1)
#define GiveInventoryMaxWeight(%0,%1) PlayerInv[%0][pinv_MaxWeight] += (%1)

/*Function in file math.pwn*/
stock Float:absoluteangle(Float:angle)
{
	while(angle < 0.0)angle += 360.0;
	while(angle > 360.0)angle -= 360.0;
	return angle;
}
stock Float:GetAngleToPoint(Float:fPointX, Float:fPointY, Float:fDestX, Float:fDestY)
	return absoluteangle(-(90-(atan2((fDestY - fPointY), (fDestX - fPointX)))));
enum e_itemdefine
{
	e_ItemModel,
	e_ItemName[64],
	e_ItemType,
	Float:e_ItemWeight,
	Float:e_ItemPreviewRotX,
	Float:e_ItemPreviewRotY,
	Float:e_ItemPreviewRotZ,
	Float:e_ItemPreviewZoom,
	Float:e_ItemRotX,
	Float:e_ItemRotY,
	Float:e_ItemRotZ,
	e_ItemColor,
	e_ItemDescription[128],
}
new DefineItem[MAX_DEFINE_ITEMS][e_itemdefine], ItemDefined_Total;

new ITEM_NULL,
ITEM_MEDKIT,
ITEM_BURGER,
ITEM_TOOLBOX;

/*Item data*/
enum e_item_data
{
	item_Type,
	item_Object,
	item_Model,
	item_Amount,
Float:item_Weight,
Float:item_PosX,
Float:item_PosY,
Float:item_PosZ,
	item_Interior,
	item_VirtualWorld,
Text3D:item_TextLabel,
}
new ItemData[MAX_ITEMS][e_item_data];
new Iterator:item_Index<MAX_ITEMS>;
/*Inventory and Gear*/
enum e_invtext_data
{
	/*GuiMain [Loot][Main][Item]*/
	PlayerText:invtext_GuiMain[20],
	/*Gui Title
	0 = inventory title
	1 = gear title*/
	PlayerText:invtext_GuiTitle[2],
	/*Gui Info*/
	PlayerText:invtext_GuiInfo,
	/*Gui Page 
	0 = page Inventory
	1 = page Gear*/
	PlayerText:invtext_GuiPage[2],
	/*Button : Button Inv = Inventory button 0 = Use 1 = Drop
			   Button Gear = Gear button 0 = loot 1 = put*/

	PlayerText:invtext_ButtonInv[4],
	PlayerText:invtext_ButtonGear[4],
	/*Inventory Item*/
	PlayerText:invtext_InvItem[10],
	/*Gear Item*/
	PlayerText:invtext_GearItem[10],
	/*Equip Weapon 0 = primary weapon
					1 = secondary weapon*/
	PlayerText:invtext_EquipWeapon[2],
	/*Equip name 0 = primary weapon
					1 = secondary weapon*/
	PlayerText:invtext_EquipWeaponName[2],
	/*Equip Tool*/
	PlayerText:invtext_EquipTool[5],
	/*Equip Food*/
	PlayerText:invtext_EquipFood[5],
	/*Equip Medic*/
	PlayerText:invtext_EquipMedic[5],
}
new InvTextDraw[MAX_PLAYERS][e_invtext_data];
///////////////////////Inventory Color/////////////////////////
enum e_invtext_edit
{
	invcolor_GuiMainColor[3],
	invcolor_EditGuiID,
	invcolor_SelectColor,
}
new InvEditColor[MAX_PLAYERS][e_invtext_edit];

//////////////////////Inventory and Gear MISC////////////////////
enum e_playerinv_misc
{
	invmisc_IsOpen,
	invmisc_IsPage,
	invmisc_IsLastClickSlot,
	invmisc_IsLastClickID,
	//Arrange inventory
	invmisc_ArrangeItem[50],
	invmisc_ArrangeItemAmount[50],
	//Equip Medic
	invmisc_EquipMedicItemid[5],//Item in show privew model
	invmisc_EquipMedicItemSlot[5], // item slot
	invmisc_EquipMedicCount,
	//Equip Food
	invmisc_EquipFoodItemid[5],
	invmisc_EquipFoodItemAmount[5],
	invmisc_EquipFoodItemSlot[5],
	invmisc_EquipFoodCount,
	//Equip
	invmisc_EquipToolItemid[5],
	invmisc_EquipToolItemAmount[5],
	invmisc_EquipToolItemSlot[5],
	invmisc_EquipToolCount,
	
}
new InvMisc[MAX_PLAYERS][e_playerinv_misc];
enum e_gear_misc
{
	gearmisc_IsOpen,
	gearmisc_IsLooting,
	gearmisc_IsLastClickSlot,
	gearmisc_IsLastClickID,
	//////////////////////////
	//Looting
	gearmisc_IsLootID[50],
}
new GearMisc[MAX_PLAYERS][e_gear_misc];
//////////////////////Inventory and Gear Data////////////////////
enum e_playerinv_data
{
	pinv_MaxPage,
Float:pinv_Weight,
Float:pinv_MaxWeight,
	pinv_SlotItem[50],
	pinv_SlotItemAmount[50],
}
new PlayerInv[MAX_PLAYERS][e_playerinv_data];
/***************************************************
	Callbacks
***************************************************/

public OnFilterScriptInit()
{
	ITEM_NULL = DefineItemType(0, "Null", ITEM_TYPE_NULL, 0.5, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, -1); 
	ITEM_MEDKIT = DefineItemType(11738, "Medkit", ITEM_TYPE_MEDIC, 0.5, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0xFF0000FF);
	ITEM_BURGER = DefineItemType(2703, "Burger", ITEM_TYPE_FOOD, 0.3, 0.0, 0.0, 0.0, 1.0, -76.0, 257.0, 11.0, 0xFF6347FF);
	ITEM_TOOLBOX = DefineItemType(19921, "Toolbox", ITEM_TYPE_TOOL, 2.5, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, -1);
	//ITEM DESCRIPTION
	new DescriptionStr[128];
	format(DescriptionStr, 128, "ITEM : ~r~Medkit~n~~w~Type : ~r~ Medicine~n~~w~Use: Health~n~Weight :%0.1f (Kg)", GetItemWeight(ITEM_MEDKIT));
	DefineItemDescription(ITEM_MEDKIT, DescriptionStr);
	format(DescriptionStr, 128, "ITEM : ~r~Burger~n~~w~Type : ~r~ Food~n~~w~Use: Eat~n~Weight :%0.1f (Kg)", GetItemWeight(ITEM_BURGER));
	DefineItemDescription(ITEM_BURGER, DescriptionStr);
	format(DescriptionStr, 128, "ITEM : ~r~Medkit~n~~w~Type : ~r~ Tool~n~~w~Use: Fix Vehicle~n~Weight :%0.1f (Kg)", GetItemWeight(ITEM_TOOLBOX));
	DefineItemDescription(ITEM_TOOLBOX, DescriptionStr);
	return 1;
}
public OnFilterScriptExit()
{
	DeleteAllDefinedItems();
	for(new i =0;i<MAX_ITEMS;i++)
	{
	  	if(IsValidDynamicObject(ItemData[i][item_Object]) && ItemData[i][item_Type] != 0)
	  	{
	  		DestroyItem(i);
	  	}
	}
	return 1;
}
public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(newkeys & KEY_YES &&  GetPlayerState(playerid) == PLAYER_STATE_ONFOOT)
	{
		if(InvMisc[playerid][invmisc_IsOpen] == 0)
			ShowPlayerInventory(playerid,0);
		if(GetPlayerSpecialAction(playerid) == SPECIAL_ACTION_DUCK && IsPlayerNearLooting(playerid) == 1)
			ShowPlayerGearLooting(playerid);
	}
	return 1;
}
public OnPlayerConnect(playerid)
{
	//Inventory and Gear MISC
	InvMisc[playerid][invmisc_IsOpen] = 0;
	InvMisc[playerid][invmisc_IsPage] = 0;
	InvMisc[playerid][invmisc_IsLastClickSlot] = -1;
	InvMisc[playerid][invmisc_IsLastClickID] = 0;
	for(new i =0 ;i<5;i++)
	{
		InvMisc[playerid][invmisc_EquipMedicItemid][i] = 0,//Item in show privew model
		InvMisc[playerid][invmisc_EquipMedicItemSlot][i] = 0;// item slot

		InvMisc[playerid][invmisc_EquipFoodItemid][i] = 0,//Item in show privew model
		InvMisc[playerid][invmisc_EquipFoodItemAmount][i]=0,
		InvMisc[playerid][invmisc_EquipFoodItemSlot][i] = 0;// item slot

		InvMisc[playerid][invmisc_EquipToolItemid][i] = 0,//Item in show privew model
		InvMisc[playerid][invmisc_EquipToolItemAmount][i]=0,
		InvMisc[playerid][invmisc_EquipToolItemSlot][i] = 0;// item slot
	}
	InvMisc[playerid][invmisc_EquipMedicCount] = 0;
	InvMisc[playerid][invmisc_EquipFoodCount]  = 0;	
	InvMisc[playerid][invmisc_EquipToolCount]  = 0;	

	GearMisc[playerid][gearmisc_IsLooting] = 0;
	GearMisc[playerid][gearmisc_IsLastClickSlot] = -1;
	GearMisc[playerid][gearmisc_IsLastClickID] = 0;


	///////////////////////////////////////////
	for(new i =0;i<50;i++)
	{
		PlayerInv[playerid][pinv_SlotItem][i] = 0;
		PlayerInv[playerid][pinv_SlotItemAmount][i] = 0;
		InvMisc[playerid][invmisc_ArrangeItem][i] = 0;
		InvMisc[playerid][invmisc_ArrangeItemAmount][i] = 0;
	}
	PlayerInv[playerid][pinv_MaxWeight] = 20.0;
	PlayerInv[playerid][pinv_Weight] 	= 0.0;
	PlayerInv[playerid][pinv_MaxPage] = 4;//4 +1 = 5 page = max
	//////////////////////////////////////////
	InvCreate_GuiMain(playerid);
	InvCreate_Button(playerid);
	InvCreate_EquipWeapon(playerid);
	InvCreate_EquipTool(playerid);
	InvCreate_EquipFood(playerid);
	InvCreate_EquipMedic(playerid);
	InvCreate_Item(playerid);
	InvCreate_GearItem(playerid);
	return 1;
}

public OnPlayerClickTextDraw(playerid, Text:clickedid)
{
	if(clickedid == Text:INVALID_TEXT_DRAW )
	{
		if(InvMisc[playerid][invmisc_IsOpen] == 1)
			HidePlayerInventory(playerid);
		
	}
	return 1;
}
public OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid)
{
	if(InvMisc[playerid][invmisc_IsOpen] == 1)
	{
		if(playertextid == InvTextDraw[playerid][invtext_ButtonInv][0])/*Button Inventory Use*/
		{
			if(InvMisc[playerid][invmisc_IsLastClickSlot] == -1 ) return SetInventoryTextInfo(playerid,1,"~r~ERROR: ~w~Vui long chon Item."); 
			if(PlayerInv[playerid][pinv_SlotItem][InvMisc[playerid][invmisc_IsLastClickSlot]] == 0)
				return 1;

			CallLocalFunction("OnPlayerUseItem","iiii",playerid,
				PlayerInv[playerid][pinv_SlotItem][InvMisc[playerid][invmisc_IsLastClickSlot]],
				PlayerInv[playerid][pinv_SlotItemAmount][InvMisc[playerid][invmisc_IsLastClickSlot]],
				InvMisc[playerid][invmisc_IsLastClickSlot]);
		}
		else if(playertextid == InvTextDraw[playerid][invtext_ButtonInv][1])/*Button Inventory Drop*/
		{
			if(InvMisc[playerid][invmisc_IsLastClickSlot] == -1 ) return SetInventoryTextInfo(playerid,1,"~r~ERROR: ~w~Vui long chon Item."); 
			if(PlayerInv[playerid][pinv_SlotItem][InvMisc[playerid][invmisc_IsLastClickSlot]] == 0)
				return 1;
			CallLocalFunction("OnPlayerDropItem","iiii",playerid,
				PlayerInv[playerid][pinv_SlotItem][InvMisc[playerid][invmisc_IsLastClickSlot]],
				PlayerInv[playerid][pinv_SlotItemAmount][InvMisc[playerid][invmisc_IsLastClickSlot]],
				InvMisc[playerid][invmisc_IsLastClickSlot]);
		}
		else if(playertextid == InvTextDraw[playerid][invtext_ButtonInv][2])/*Button Inventory UP*/
		{
			if(InvMisc[playerid][invmisc_IsPage] == PlayerInv[playerid][pinv_MaxPage]) return SetInventoryTextInfo(playerid,1,"~r~ERROR: ~w~MAX_ITEM limit reached.");
			InvMisc[playerid][invmisc_IsPage]++;
			ShowPlayerInventory(playerid,InvMisc[playerid][invmisc_IsPage]);
		}
		else if(playertextid == InvTextDraw[playerid][invtext_ButtonInv][3])/*Button Inventory Down*/
		{
			if(InvMisc[playerid][invmisc_IsPage] <= 0) return SetInventoryTextInfo(playerid,1,"~r~ERROR: ~w~MAX_ITEM limit reached.");
			InvMisc[playerid][invmisc_IsPage]--;
			ShowPlayerInventory(playerid,InvMisc[playerid][invmisc_IsPage]);
		}
		//Gear
		else if(playertextid == InvTextDraw[playerid][invtext_ButtonGear][0])/*Button Gear Loot*/
		{
			if(GearMisc[playerid][gearmisc_IsLastClickSlot] == -1) return SetInventoryTextInfo(playerid,1,"~r~ERROR: ~w~Vui long chon Item."); 
			if(GearMisc[playerid][gearmisc_IsLooting] == 1)
			{
				new itemid = GearMisc[playerid][gearmisc_IsLootID][GearMisc[playerid][gearmisc_IsLastClickSlot]];
				if(GetInventoryWeight(playerid)+GetItemWeight(ItemData[itemid][item_Type]) > GetInventoryMaxWeight(playerid))
				{
					for(new i = 0; i<10; i++)
					{
						GearMisc[playerid][gearmisc_IsLootID][i] = 0;
					}
					SetInventoryTextInfo(playerid,1,"~r~ERROR:~w~ Khong the vac nang hon nua");
				}
				else if(GetInventoryFreeSlots(playerid) != -1)
				{
					
					if(IsValidDynamicObject(ItemData[itemid][item_Object]) && ItemData[itemid][item_Type] != 0)
	  				{
	  					AddInventoryItem(playerid,GetInventoryFreeSlots(playerid),
	  						ItemData[itemid][item_Type],ItemData[itemid][item_Amount]);
	  					DestroyItem(itemid);
	  					PlayerInventoryArrange(playerid);
	  					ShowPlayerInventory(playerid,InvMisc[playerid][invmisc_IsPage]);
	  					
	  					ShowPlayerGearLooting(playerid);
	  				}
	  				else
	  				{
	  					PlayerInventoryArrange(playerid);
	  					ShowPlayerInventory(playerid,InvMisc[playerid][invmisc_IsPage]);
	  					
	  					ShowPlayerGearLooting(playerid);
	  				}
				}
				else
				{
					for(new i = 0; i<10; i++)
					{
						GearMisc[playerid][gearmisc_IsLootID][i] = 0;
					}
					SetInventoryTextInfo(playerid,1,"~r~ERROR:~w~ Tui do da day");
				}
			}
		}
		else if(playertextid == InvTextDraw[playerid][invtext_ButtonGear][1])/*Button Gear Put*/
		{
			SetInventoryTextInfo(playerid,1,"~w~Button:~r~ PUT");
		}
		else if(playertextid == InvTextDraw[playerid][invtext_ButtonGear][2])/*Button Gear UP*/
		{
			SetInventoryTextInfo(playerid,1,"~w~Button:~r~ UP");
		}
		else if(playertextid == InvTextDraw[playerid][invtext_ButtonGear][3])/*Button Gear DOWN*/
		{
			
			SetInventoryTextInfo(playerid,1,"~w~Button:~r~ DOWN");
		}
		for(new id = 0; id<5; id++)
		{
			if(playertextid == InvTextDraw[playerid][invtext_EquipTool][id])/*Button Inventory Tool Equip*/
			{
				if(InvMisc[playerid][invmisc_EquipToolItemid][id] == 0) return SetInventoryTextInfo(playerid,1,"~r~Khong co vat pham de dung");
				
				CallLocalFunction("OnPlayerUseItem","iiii",playerid,InvMisc[playerid][invmisc_EquipToolItemid][id],
					InvMisc[playerid][invmisc_EquipToolItemAmount][id],
					InvMisc[playerid][invmisc_EquipToolItemSlot][id]);
				break;
			}
			else if(playertextid == InvTextDraw[playerid][invtext_EquipFood][id])/*Button Inventory Food Equip*/
			{
				if(InvMisc[playerid][invmisc_EquipFoodItemid][id] == 0) return SetInventoryTextInfo(playerid,1,"~r~Khong co vat pham de dung");
				
				CallLocalFunction("OnPlayerUseItem","iiii",playerid,InvMisc[playerid][invmisc_EquipFoodItemid][id],
					InvMisc[playerid][invmisc_EquipFoodItemAmount][id],
					InvMisc[playerid][invmisc_EquipFoodItemSlot][id]);
				break;
			}
			else if(playertextid == InvTextDraw[playerid][invtext_EquipMedic][id])/*Button Inventory Medic Equip*/
			{
				if(InvMisc[playerid][invmisc_EquipMedicItemid][id] == 0) return SetInventoryTextInfo(playerid,1,"~r~Khong co vat pham de dung");
				CallLocalFunction("OnPlayerUseItem","iiii",playerid,InvMisc[playerid][invmisc_EquipMedicItemid][id],1,
					InvMisc[playerid][invmisc_EquipMedicItemSlot][id]);
				break;
			}
		}
		for(new id = 0; id<10; id++)
		{
			if(playertextid == InvTextDraw[playerid][invtext_InvItem][id])/* Inventory Item*/
			{
				InvMisc[playerid][invmisc_IsLastClickSlot] = id+(InvMisc[playerid][invmisc_IsPage]*10);
				PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_InvItem][InvMisc[playerid][invmisc_IsLastClickID]], 255);
				PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_InvItem][InvMisc[playerid][invmisc_IsLastClickID]],0x00000050);//119);
				PlayerTextDrawShow(playerid,InvTextDraw[playerid][invtext_InvItem][InvMisc[playerid][invmisc_IsLastClickID]]);

				InvMisc[playerid][invmisc_IsLastClickID] = id;
				PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_InvItem][id], 0);
				PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_InvItem][id],0x80808050);
				PlayerTextDrawShow(playerid,InvTextDraw[playerid][invtext_InvItem][id]);

				///////////////////////////////////////////////////////////////////////////////////////
				SetInventoryTextInfo(playerid,1,GetItemTypeDescription(PlayerInv[playerid][pinv_SlotItem][id+(InvMisc[playerid][invmisc_IsPage])]));
				break;
			}
			else if(playertextid == InvTextDraw[playerid][invtext_GearItem][id])/* Gear Item*/
			{
				if(GearMisc[playerid][gearmisc_IsLooting] == 1)
				{
					GearMisc[playerid][gearmisc_IsLastClickSlot] = id;
					if(GearMisc[playerid][gearmisc_IsLastClickID] != -1)
					{
					PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GearItem][GearMisc[playerid][gearmisc_IsLastClickID]], 255);
					PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GearItem][GearMisc[playerid][gearmisc_IsLastClickID]],0x00000050);//119);
					PlayerTextDrawShow(playerid,InvTextDraw[playerid][invtext_GearItem][GearMisc[playerid][gearmisc_IsLastClickID]]);
					}
					GearMisc[playerid][gearmisc_IsLastClickID] = id;
					PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GearItem][id],0);
					PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GearItem][id],0x80808050);
					PlayerTextDrawShow(playerid,InvTextDraw[playerid][invtext_GearItem][id]);
					SetInventoryTextInfo(playerid,1,GetItemTypeDescription(ItemData[GearMisc[playerid][gearmisc_IsLootID][id]][item_Type]));
				}
				break;
			}
		}
	}

	return 1;
}
function: OnPlayerUseItem(playerid, itemid, amount, slotid)
{
	new textinfo[128];
	if(itemid == ITEM_MEDKIT)
	{
		format(textinfo,sizeof(textinfo),"~w~Su dung : ~r~Medkit");
		RemoveInventoryItem(playerid,slotid);
	}
	else if(itemid == ITEM_TOOLBOX)
	{
		if(IsPlayerInAnyVehicle(playerid))
		{
			format(textinfo,sizeof(textinfo),"~w~Su dung : ~r~Repair Vehicle");
			RepairVehicle(GetPlayerVehicleID(playerid));
		}
		else format(textinfo,sizeof(textinfo),"~w~You need in any ~n~vehicle to use toolbox");
	}	
	else
	{
		format(textinfo,sizeof(textinfo),"~w~Su dung : %s",GetItemTypeName(itemid,amount));
		RemoveInventoryItem(playerid,slotid);
	}
	PlayerInventoryArrange(playerid);
	HidePlayerInventory(playerid);
	SetTimerEx("ShowPlayerInventory",50,false,"ii",playerid,InvMisc[playerid][invmisc_IsPage]);
	SetInventoryTextInfo(playerid,0,textinfo);
	return 1;
}
function: OnPlayerDropItem(playerid, itemid, amount, slotid)
{
	RemoveInventoryItem(playerid,slotid);
	
	ApplyAnimation(playerid,"GRENADE","WEAPON_throwu",3.0,0,0,0,0,0);
	static Float:x,Float:y,Float:z,Float:r;
	GetPlayerFacingAngle(playerid,r);
	GetPlayerPos(playerid,x,y,z);
	CreateItem(itemid,amount
				,x + (0.5 * floatsin(-r, degrees)),
					y + (0.5 * floatcos(-r, degrees)),
					z - FLOOR_OFFSET,GetPlayerVirtualWorld(playerid),GetPlayerInterior(playerid));
	if(GearMisc[playerid][gearmisc_IsOpen] == 1 && GearMisc[playerid][gearmisc_IsLooting] == 1)
	{
		PlayerInventoryArrange(playerid);
		ShowPlayerInventory(playerid,InvMisc[playerid][invmisc_IsPage]);
		ShowPlayerGearLooting(playerid);
	}
	else HidePlayerInventory(playerid);
	Streamer_Update(playerid);
	return 1;
}
//COMMANDS
CMD:invcolor(playerid,params[])
{
	DialogShow(playerid, INV_EDIT_COLOR, DIALOG_STYLE_LIST,"Edit INV Color","GuiMain:Center\nGuiMain:Right\nGuiMain:Left\nSelect Color","Chon","Dong");
	return 1;
}
CMD:inv(playerid,params[])
{
	if(strval(params) == 1)
		ShowPlayerInventory(playerid,0);
	else HidePlayerInventory(playerid);
	return 1;
}

CMD:show(playerid,params[]) return ShowPlayerGearLooting(playerid);
CMD:create(playerid,params[])
{
	new Float:x,Float:y,Float:z;
	GetPlayerPos(playerid, x,y,z);
	CreateItem(strval(params),1,x,y,z-FLOOR_OFFSET,GetPlayerVirtualWorld(playerid),GetPlayerInterior(playerid));
	return 1;
}
CMD:add(playerid,params[])
{
	AddInventoryItem(playerid,GetInventoryFreeSlots(playerid),strval(params),1);
	return 1;
}
CMD:remove(playerid,params[])
{
	RemoveInventoryItem(playerid,strval(params));
	PlayerInventoryArrange(playerid);
	ShowPlayerInventory(playerid,InvMisc[playerid][invmisc_IsPage]);
	return 1;
}
/*==============================================================================

	Core Item script

==============================================================================*/
function: CreateItem(itemtype, amount, Float:x, Float:y, Float:z, world, interior)
{
	if(itemtype == ITEM_NULL)
		return 0;
	new id = Iter_Free(item_Index);

	if(id == -1)
	{
		print("ERROR: MAX_ITEM limit reached.");
		return -1;
	}
	new Float:rx,Float:ry,Float:rz,str[128];
	GetItemTypeRot(itemtype,rx,ry,rz);
	ItemData[id][item_Type] 		= itemtype;
	ItemData[id][item_Object] 		= CreateDynamicObject(GetItemTypeModel(itemtype), x, y, z, rx, ry, rz);
	ItemData[id][item_Amount] 		= amount;
	ItemData[id][item_VirtualWorld] = world;
	ItemData[id][item_Interior] 	= interior;
	ItemData[id][item_PosX]			= x;
	ItemData[id][item_PosY]			= y;
	ItemData[id][item_PosZ]			= z;
	format(str,sizeof(str),"%s\n{ADFF2F}%0.1f(Kg)",GetItemTypeName(itemtype,amount),GetItemWeight(itemtype));
	ItemData[id][item_TextLabel] = CreateDynamic3DTextLabel(str,GetItemTypeColor(itemtype),x,y,z+0.3,1.2,_,_,_,world,interior);
	//SetItemTextures(itemtype,ItemData[i][item_Object]);
	Iter_Add(item_Index, id);
	return id;
}
function: DestroyItem(itemid)
{
	if(!Iter_Contains(item_Index, itemid))
		return 0;
	if(ItemData[itemid][item_Type] == 0)
		return 0;
	if(IsValidDynamicObject(ItemData[itemid][item_Object]))
			DestroyDynamicObject(ItemData[itemid][item_Object]);
	if(IsValidDynamic3DTextLabel(ItemData[itemid][item_TextLabel]))
			DestroyDynamic3DTextLabel(ItemData[itemid][item_TextLabel]);
	ItemData[itemid][item_Type] 		= 0;
	ItemData[itemid][item_Amount] 		= 0;
	ItemData[itemid][item_VirtualWorld] = 0;
	ItemData[itemid][item_Interior] 	= 0;
	ItemData[itemid][item_PosX]			= 0.0;
	ItemData[itemid][item_PosY]			= 0.0;
	ItemData[itemid][item_PosZ]			= 0.0;
	Iter_Remove(item_Index, itemid);
	return 1;
}
stock IsItemValid(itemid)
{
	return Iter_Contains(item_Index, itemid);
}
stock GetItemObjectID(itemid)
{
	if(!Iter_Contains(item_Index, itemid))
		return 0;

	return ItemData[itemid][item_Object];
}

////////////////////////SETUP ITEM////////////////////////////////
stock DeleteAllDefinedItems()
{
	for(new i = 0; i< ItemDefined_Total; i++)
	{
		DefineItem[i][e_ItemModel] 		= 0;
		format(DefineItem[i][e_ItemName], 64, "");
		DefineItem[i][e_ItemType] 			= 0;
		DefineItem[i][e_ItemWeight] 		= 0;
		DefineItem[i][e_ItemPreviewRotX] 	= 0;
		DefineItem[i][e_ItemPreviewRotY] 	= 0;
		DefineItem[i][e_ItemPreviewRotZ] 	= 0;
		DefineItem[i][e_ItemPreviewZoom] 	= 0;
		DefineItem[i][e_ItemRotX]			= 0;
		DefineItem[i][e_ItemRotY]			= 0;
		DefineItem[i][e_ItemRotZ]			= 0;
		DefineItem[i][e_ItemColor]			= 0;
		DefineItem[i][e_ItemDescription] 	= EOS;
	}
	ItemDefined_Total = 0;
	return 1;
}
stock DefineItemType(itemmodelid, itemname[], type, Float:itemweight, Float:itempreviewposx= 0.0, Float:itempreviewposy= 0.0, 
	Float:itempreviewposz= 0.0, Float:itempreviewzoom = 1.0, Float:itemrotx= 0.0,  Float:itemroty= 0.0, Float:itemrotz= 0.0, itemcolor = -1)
{
	new newdefineitemid = ItemDefined_Total;
	if(newdefineitemid == MAX_DEFINE_ITEMS)
	{
		printf("Limit of Define item");
		return 0;
	}
	ItemDefined_Total++;
	DefineItem[newdefineitemid][e_ItemModel] 		= itemmodelid;
	format(DefineItem[newdefineitemid][e_ItemName], 64, itemname);
	DefineItem[newdefineitemid][e_ItemType] 			= type;
	DefineItem[newdefineitemid][e_ItemWeight] 		= itemweight;
	DefineItem[newdefineitemid][e_ItemPreviewRotX] 	= itempreviewposx;
	DefineItem[newdefineitemid][e_ItemPreviewRotY] 	= itempreviewposy;
	DefineItem[newdefineitemid][e_ItemPreviewRotZ] 	= itempreviewposz;
	DefineItem[newdefineitemid][e_ItemPreviewZoom] 	= itempreviewzoom;
	DefineItem[newdefineitemid][e_ItemRotX]			= itemrotx;
	DefineItem[newdefineitemid][e_ItemRotY]			= itemroty;
	DefineItem[newdefineitemid][e_ItemRotZ]			= itemrotz;
	DefineItem[newdefineitemid][e_ItemColor]			= itemcolor;
	return newdefineitemid;
}
stock DefineItemDescription(itemid, description[])
{
	format(DefineItem[itemid][e_ItemDescription], 128, description);
	return 1;
}
stock GetItemTypeDescription(itemid)
{
	new rdes[128];
	format(rdes, 128, "%s", DefineItem[itemid][e_ItemDescription]);
	return rdes;
}
function: GetItemTypeModel(itemid)
{
	if(itemid == ITEM_NULL) 
		return -1;
	return DefineItem[itemid][e_ItemModel];
}
function: Float:GetItemWeight(itemid)
{
	if(itemid == ITEM_NULL) 
		return 0.0;
	return DefineItem[itemid][e_ItemWeight];
}
function: GetItemType(itemid)
{
	if(itemid == ITEM_NULL) 
		return ITEM_TYPE_NULL;
	return DefineItem[itemid][e_ItemType];
}
function: GetItemTypePreviewRot(itemid, &Float:rx, &Float:ry, &Float:rz, &Float:zoom)
{
	if(itemid == ITEM_NULL) 
		return 0;
	rx = DefineItem[itemid][e_ItemPreviewRotX];
	ry = DefineItem[itemid][e_ItemPreviewRotY];
	rz = DefineItem[itemid][e_ItemPreviewRotZ];
	zoom = DefineItem[itemid][e_ItemPreviewZoom];
	return 1;
}
stock GetItemTypeName(itemid, amount)
{
	#pragma unused amount
	new itemname[64];
	format(itemname, 64, "%s", DefineItem[itemid][e_ItemName]);
	if(itemid == ITEM_NULL)
		itemname = "";
	return itemname;
}

function: GetItemTypeRot(itemid, &Float:rx, &Float:ry, &Float:rz)
{
	if(itemid == ITEM_NULL) 
		return 0;
	rx = DefineItem[itemid][e_ItemRotX];
	ry = DefineItem[itemid][e_ItemRotY];
	rz = DefineItem[itemid][e_ItemRotZ];
	return 1;
}
function: GetItemTypeColor(itemid)
{
	if(itemid == ITEM_NULL) 
		return -1;
	return DefineItem[itemid][e_ItemColor];
}

/*==============================================================================

	Core Inventory and Item script

==============================================================================*/
function: AddInventoryItem(playerid,slot,itemid,amount)
{
	if(itemid == 0) return 1;
	if(itemid > ItemDefined_Total) return 1;
	PlayerInv[playerid][pinv_Weight] += GetItemWeight(itemid);
	PlayerInv[playerid][pinv_SlotItem][slot] = itemid;
	PlayerInv[playerid][pinv_SlotItemAmount][slot] = amount;
	if(IsPlayerInventoryOpen(playerid) == 1)
		ShowPlayerInventory(playerid,InvMisc[playerid][invmisc_IsPage]);
	return 1;
}
function: RemoveInventoryItem(playerid,slot)
{
	PlayerInv[playerid][pinv_Weight] -= GetItemWeight(PlayerInv[playerid][pinv_SlotItem][slot]);
    PlayerInv[playerid][pinv_SlotItem][slot] = 0;
	PlayerInv[playerid][pinv_SlotItemAmount][slot] = 0;
	return 1;
}
function: ResetInventoryItem(playerid)
{
	for(new slot =0; slot<10+(PlayerInv[playerid][pinv_MaxPage]*10); slot++)
	{
	    if(PlayerInv[playerid][pinv_SlotItem][slot] != 0)
		{
		RemoveInventoryItem(playerid,slot);
		}
	}
	return 1;
}

function: GetInventoryFreeSlots(playerid)
{
	for(new slot =0; slot<10+(PlayerInv[playerid][pinv_MaxPage]*10); slot++)
	{
	    if(PlayerInv[playerid][pinv_SlotItem][slot] == 0)
		{
		return slot;
		}
	}
	return -1;
}
stock PlayerInventoryArrange(playerid)
{
	new invarrangecount = 10+(PlayerInv[playerid][pinv_MaxPage]*10);

    for(new slot =0; slot<invarrangecount; slot++)
	{
	    if(PlayerInv[playerid][pinv_SlotItem][slot] != 0)
		{
		InvMisc[playerid][invmisc_ArrangeItem][slot] = PlayerInv[playerid][pinv_SlotItem][slot];
		InvMisc[playerid][invmisc_ArrangeItemAmount][slot] = PlayerInv[playerid][pinv_SlotItemAmount][slot];
		}
	}
	ResetInventoryItem(playerid);
	for(new ai =0; ai<invarrangecount; ai++)
	{
	    if(InvMisc[playerid][invmisc_ArrangeItem][ai] != 0)
		{
		AddInventoryItem(playerid,GetInventoryFreeSlots(playerid),InvMisc[playerid][invmisc_ArrangeItem][ai]
			,InvMisc[playerid][invmisc_ArrangeItemAmount][ai]);
		InvMisc[playerid][invmisc_ArrangeItem][ai] = 0;
		InvMisc[playerid][invmisc_ArrangeItemAmount][ai] = 0;
		}
	}
	return 1;
}
/*==============================================================================

	Core Inventory script

==============================================================================*/
stock IsPlayerInventoryOpen(playerid)
{
	return InvMisc[playerid][invmisc_IsOpen];
}
stock IsPlayerGearLootingOpen(playerid)
{
	return GearMisc[playerid][gearmisc_IsOpen];
}
stock IsPlayerNearLooting(playerid)
{
	//new Float:x,Float:y,Float:z;
	for(new i =0;i<MAX_ITEMS;i++)
	{
	  	if(IsValidDynamicObject(ItemData[i][item_Object]) && ItemData[i][item_Type] != 0)
	  	{
	    	//GetDynamicObjectPos(ItemData[i][item_Object],x,y,z);
	      	if(IsPlayerInRangeOfPoint(playerid,1.8,ItemData[i][item_PosX],
	      		ItemData[i][item_PosY],ItemData[i][item_PosZ]) && GetPlayerInterior(playerid) == ItemData[i][item_Interior] &&
			GetPlayerVirtualWorld(playerid) == ItemData[i][item_VirtualWorld])
	   		{
	   			return 1;
	   		}
	   	}
	}
	return 0;
}
function: ShowPlayerGearLooting(playerid)
{
	if(InvMisc[playerid][invmisc_IsOpen] == 0)
		ShowPlayerInventory(playerid,0);
	/*Looting*/
	GearMisc[playerid][gearmisc_IsLooting] = 1;
	/*Title*/
	PlayerTextDrawSetString(playerid,InvTextDraw[playerid][invtext_GuiTitle][1],"Looting");
	PlayerTextDrawShow(playerid, InvTextDraw[playerid][invtext_GuiTitle][1]);
	/*Edit Color*/
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GuiMain][2], InvEditColor[playerid][invcolor_GuiMainColor][2]);
	/*Main*/
	for(new id = 14; id<20; id++)
	{
		PlayerTextDrawShow(playerid,InvTextDraw[playerid][invtext_GuiMain][id]);
	}
	PlayerTextDrawShow(playerid,InvTextDraw[playerid][invtext_GuiMain][2]);
	/*Button Show*/
	PlayerTextDrawShow(playerid,InvTextDraw[playerid][invtext_ButtonGear][0]);
	/*Misc*/
	GearMisc[playerid][gearmisc_IsOpen] = 1;
	/*Show Item*/
	new Float:x,Float:y,Float:z,string[128];
	new item_get_count =-1;
	for(new i =0 ; i< 10;i++)
	{
		PlayerTextDrawHide(playerid,InvTextDraw[playerid][invtext_GearItem][i]);
	}
	for(new i =0;i<MAX_ITEMS;i++)
	{
	  	if(IsValidDynamicObject(ItemData[i][item_Object]) && ItemData[i][item_Type] != 0)
	  	{
	    	GetDynamicObjectPos(ItemData[i][item_Object],x,y,z);
	      	if(IsPlayerInRangeOfPoint(playerid,1.8,ItemData[i][item_PosX],
	      		ItemData[i][item_PosY],ItemData[i][item_PosZ]) && GetPlayerInterior(playerid) == ItemData[i][item_Interior] &&
			GetPlayerVirtualWorld(playerid) == ItemData[i][item_VirtualWorld])
	   		{
	   			item_get_count++;
	   			GearMisc[playerid][gearmisc_IsLootID][item_get_count] = i;
	   			PlayerTextDrawBackgroundColor(playerid, InvTextDraw[playerid][invtext_GearItem][item_get_count], 255);
		   		PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GearItem][item_get_count], GetItemTypeColor(ItemData[i][item_Type]));
				PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GearItem][item_get_count], 0x00000050);//119);
		   		format(string,sizeof(string),"%s",GetItemTypeName(ItemData[i][item_Type],ItemData[i][item_Amount]));
				PlayerTextDrawSetString(playerid,InvTextDraw[playerid][invtext_GearItem][item_get_count],string);
				PlayerTextDrawShow(playerid,InvTextDraw[playerid][invtext_GearItem][item_get_count]);
		   		if(item_get_count == 9)
		   		{
					break;
		   		}
	   		}
		}
	}
	if(item_get_count > -1)
	{
		new Float:px,Float:py,Float:pz;
   		GetPlayerPos(playerid,px,py,pz);
   		SetPlayerFacingAngle(playerid,GetAngleToPoint(px,py,x,y));
	}
	else
	{
		HidePlayerGearLooting(playerid);
	}
	GearMisc[playerid][gearmisc_IsLastClickID] = -1;
	return 1;
}
function: HidePlayerGearLooting(playerid)
{
	/*Misc*/
	GearMisc[playerid][gearmisc_IsOpen] = 0;
	/*Looting*/
	GearMisc[playerid][gearmisc_IsLooting] = 0;
	/*Title*/
	PlayerTextDrawHide(playerid, InvTextDraw[playerid][invtext_GuiTitle][1]);
	/*Main*/
	for(new id = 14; id<20; id++)
	{
		PlayerTextDrawHide(playerid,InvTextDraw[playerid][invtext_GuiMain][id]);
	}
	PlayerTextDrawHide(playerid,InvTextDraw[playerid][invtext_GuiMain][2]);
	/*Button Hide*/
	for(new id = 0; id<2; id++)
	{
		/*Button*/
		PlayerTextDrawHide(playerid,InvTextDraw[playerid][invtext_ButtonGear][id]);
	}
	for(new i = 0; i<10; i++)
	{
		GearMisc[playerid][gearmisc_IsLootID][i] = 0;
	}
	GearMisc[playerid][gearmisc_IsLastClickSlot] = -1;
	GearMisc[playerid][gearmisc_IsLastClickID] = 0;
	return 1;
}
function: ShowPlayerInventory(playerid,page)
{
	new str[128];
	InvMisc[playerid][invmisc_EquipMedicCount] = 0;
	InvMisc[playerid][invmisc_EquipFoodCount] = 0;
	//page
	format(str,sizeof(str),"%d",page+1);
	PlayerTextDrawSetString(playerid,InvTextDraw[playerid][invtext_GuiPage][0],str);
	InvMisc[playerid][invmisc_IsPage] = page;
	/*Title*/
	format(str,sizeof(str),"%d/%d-(%0.1f/%0.1f)Kg",InvMisc[playerid][invmisc_IsPage]+1,PlayerInv[playerid][pinv_MaxPage]+1,
		PlayerInv[playerid][pinv_Weight],PlayerInv[playerid][pinv_MaxWeight]);
	PlayerTextDrawSetString(playerid,InvTextDraw[playerid][invtext_GuiTitle][0],str);
	//edit color
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GuiMain][0], InvEditColor[playerid][invcolor_GuiMainColor][0]);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GuiMain][1], InvEditColor[playerid][invcolor_GuiMainColor][1]);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GuiMain][2], InvEditColor[playerid][invcolor_GuiMainColor][2]);
	//////////
	/*Main Show*/
	PlayerTextDrawShow(playerid,InvTextDraw[playerid][invtext_GuiMain][0]);
	PlayerTextDrawShow(playerid,InvTextDraw[playerid][invtext_GuiMain][1]);
	for(new id = 3; id<14; id++)
	{
		PlayerTextDrawShow(playerid,InvTextDraw[playerid][invtext_GuiMain][id]);
	}
	/*Button Show*/
	for(new id = 0; id<4; id++)
	{
		/*Button*/
		PlayerTextDrawShow(playerid,InvTextDraw[playerid][invtext_ButtonInv][id]);
	}
	/*Gui Title*/
	PlayerTextDrawShow(playerid,InvTextDraw[playerid][invtext_GuiTitle][0]);
	/*Gui Page*/
	PlayerTextDrawShow(playerid,InvTextDraw[playerid][invtext_GuiPage][0]);
	/*Equip weapon show*/
	for(new id = 0; id<2; id++)
	{
		/*Equip weapon*/
		PlayerTextDrawShow(playerid,InvTextDraw[playerid][invtext_EquipWeapon][id]);
		PlayerTextDrawShow(playerid,InvTextDraw[playerid][invtext_EquipWeaponName][id]);	
	}
	/*Reset Prieview Model*/
	for(new id = 0; id<5; id++)
	{
		PlayerTextDrawSetPreviewModel(playerid, InvTextDraw[playerid][invtext_EquipTool][id], 19134);
		PlayerTextDrawSetPreviewRot(playerid, InvTextDraw[playerid][invtext_EquipTool][id], 0.000000, 0.000000, 0.000000, -1.000000);

		PlayerTextDrawSetPreviewModel(playerid, InvTextDraw[playerid][invtext_EquipFood][id], 19134);
		PlayerTextDrawSetPreviewRot(playerid, InvTextDraw[playerid][invtext_EquipFood][id], 0.000000, 0.000000, 0.000000, -1.000000);

		PlayerTextDrawSetPreviewModel(playerid, InvTextDraw[playerid][invtext_EquipMedic][id], 19134);
		PlayerTextDrawSetPreviewRot(playerid, InvTextDraw[playerid][invtext_EquipMedic][id], 0.000000, 0.000000, 0.000000, -1.000000);
		InvMisc[playerid][invmisc_EquipMedicItemid][id] = 0,//Item in show privew model
		InvMisc[playerid][invmisc_EquipMedicItemSlot][id] = 0;// item slot

		InvMisc[playerid][invmisc_EquipFoodItemid][id] = 0,//Item in show privew model
		InvMisc[playerid][invmisc_EquipFoodItemAmount][id]=0,
		InvMisc[playerid][invmisc_EquipFoodItemSlot][id] = 0;// item slot

		InvMisc[playerid][invmisc_EquipToolItemid][id] = 0,//Item in show privew model
		InvMisc[playerid][invmisc_EquipToolItemAmount][id]=0,
		InvMisc[playerid][invmisc_EquipToolItemSlot][id] = 0;// item slot

	}
	/*Tutorial Info*/
	PlayerTextDrawShow(playerid,InvTextDraw[playerid][invtext_GuiInfo]);
	/*Show item*/
	for(new id = 0; id<10; id++)
	{
		PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_InvItem][id], GetItemTypeColor(PlayerInv[playerid][pinv_SlotItem][id+(InvMisc[playerid][invmisc_IsPage]*10)]));
		PlayerTextDrawBackgroundColor(playerid, InvTextDraw[playerid][invtext_InvItem][id], 255);
		PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_InvItem][id], 0x00000050);//119);
		format(str,sizeof(str),"%s",GetItemTypeName(PlayerInv[playerid][pinv_SlotItem][id+(InvMisc[playerid][invmisc_IsPage]*10)],
			PlayerInv[playerid][pinv_SlotItemAmount][id+(InvMisc[playerid][invmisc_IsPage]*10)]));
		PlayerTextDrawSetString(playerid,InvTextDraw[playerid][invtext_InvItem][id],str);
		PlayerTextDrawShow(playerid,InvTextDraw[playerid][invtext_InvItem][id]);

		if(GetItemType(PlayerInv[playerid][pinv_SlotItem][id+(InvMisc[playerid][invmisc_IsPage]*10)]) == ITEM_TYPE_MEDIC
			&& InvMisc[playerid][invmisc_EquipMedicCount] < 5)
		{
			InvMisc[playerid][invmisc_EquipMedicCount]++;
			InvMisc[playerid][invmisc_EquipMedicItemid][InvMisc[playerid][invmisc_EquipMedicCount]-1] = PlayerInv[playerid][pinv_SlotItem][id+(InvMisc[playerid][invmisc_IsPage]*10)];
			InvMisc[playerid][invmisc_EquipMedicItemSlot][InvMisc[playerid][invmisc_EquipMedicCount]-1]	= id+(InvMisc[playerid][invmisc_IsPage]*10);
			new Float:rot[4];
			GetItemTypePreviewRot(PlayerInv[playerid][pinv_SlotItem][id+(InvMisc[playerid][invmisc_IsPage]*10)],rot[0],rot[1],rot[2],rot[3]);
			PlayerTextDrawSetPreviewModel(playerid, InvTextDraw[playerid][invtext_EquipMedic][InvMisc[playerid][invmisc_EquipMedicCount]-1],
			 GetItemTypeModel(PlayerInv[playerid][pinv_SlotItem][id+(InvMisc[playerid][invmisc_IsPage]*10)]));
			PlayerTextDrawSetPreviewRot(playerid, InvTextDraw[playerid][invtext_EquipMedic][InvMisc[playerid][invmisc_EquipMedicCount]-1], rot[0],rot[1],rot[2],rot[3]);
		}
		else if(GetItemType(PlayerInv[playerid][pinv_SlotItem][id+(InvMisc[playerid][invmisc_IsPage]*10)]) == ITEM_TYPE_FOOD
			&& InvMisc[playerid][invmisc_EquipFoodCount] < 5)
		{
			InvMisc[playerid][invmisc_EquipFoodCount]++;
			InvMisc[playerid][invmisc_EquipFoodItemid][InvMisc[playerid][invmisc_EquipFoodCount]-1] = PlayerInv[playerid][pinv_SlotItem][id+(InvMisc[playerid][invmisc_IsPage]*10)];
			InvMisc[playerid][invmisc_EquipFoodItemAmount][InvMisc[playerid][invmisc_EquipFoodCount]-1] = PlayerInv[playerid][pinv_SlotItemAmount][id+(InvMisc[playerid][invmisc_IsPage]*10)];
			InvMisc[playerid][invmisc_EquipFoodItemSlot][InvMisc[playerid][invmisc_EquipFoodCount]-1]	= id+(InvMisc[playerid][invmisc_IsPage]*10);
			new Float:rot[4];
			GetItemTypePreviewRot(PlayerInv[playerid][pinv_SlotItem][id+(InvMisc[playerid][invmisc_IsPage]*10)],rot[0],rot[1],rot[2],rot[3]);
			PlayerTextDrawSetPreviewModel(playerid, InvTextDraw[playerid][invtext_EquipFood][InvMisc[playerid][invmisc_EquipFoodCount]-1],
			 GetItemTypeModel(PlayerInv[playerid][pinv_SlotItem][id+(InvMisc[playerid][invmisc_IsPage]*10)]));
			PlayerTextDrawSetPreviewRot(playerid, InvTextDraw[playerid][invtext_EquipFood][InvMisc[playerid][invmisc_EquipFoodCount]-1], rot[0],rot[1],rot[2],rot[3]);
		}
		else if(GetItemType(PlayerInv[playerid][pinv_SlotItem][id+(InvMisc[playerid][invmisc_IsPage]*10)]) == ITEM_TYPE_TOOL
			&& InvMisc[playerid][invmisc_EquipToolCount] < 5)
		{
			InvMisc[playerid][invmisc_EquipToolCount]++;
			InvMisc[playerid][invmisc_EquipToolItemid][InvMisc[playerid][invmisc_EquipToolCount]-1] = PlayerInv[playerid][pinv_SlotItem][id+(InvMisc[playerid][invmisc_IsPage]*10)];
			InvMisc[playerid][invmisc_EquipToolItemAmount][InvMisc[playerid][invmisc_EquipToolCount]-1] = PlayerInv[playerid][pinv_SlotItemAmount][id+(InvMisc[playerid][invmisc_IsPage]*10)];
			InvMisc[playerid][invmisc_EquipToolItemSlot][InvMisc[playerid][invmisc_EquipToolCount]-1]	= id+(InvMisc[playerid][invmisc_IsPage]*10);
			new Float:rot[4];
			GetItemTypePreviewRot(PlayerInv[playerid][pinv_SlotItem][id+(InvMisc[playerid][invmisc_IsPage]*10)],rot[0],rot[1],rot[2],rot[3]);
			PlayerTextDrawSetPreviewModel(playerid, InvTextDraw[playerid][invtext_EquipTool][InvMisc[playerid][invmisc_EquipToolCount]-1],
			 GetItemTypeModel(PlayerInv[playerid][pinv_SlotItem][id+(InvMisc[playerid][invmisc_IsPage]*10)]));
			PlayerTextDrawSetPreviewRot(playerid, InvTextDraw[playerid][invtext_EquipTool][InvMisc[playerid][invmisc_EquipToolCount]-1], rot[0],rot[1],rot[2],rot[3]);
		}
	}
	for(new id = 0; id<5; id++)
	{
		/*Equip Tool*/
		PlayerTextDrawShow(playerid,InvTextDraw[playerid][invtext_EquipTool][id]);
		/*Equip Food*/
		PlayerTextDrawShow(playerid,InvTextDraw[playerid][invtext_EquipFood][id]);
		/*Equip medic*/
		PlayerTextDrawShow(playerid,InvTextDraw[playerid][invtext_EquipMedic][id]);
	}
	SelectTextDraw(playerid, InvEditColor[playerid][invcolor_SelectColor]);
	InvMisc[playerid][invmisc_IsOpen] = 1;
	return 1;
}
function: HidePlayerInventory(playerid)
{
	if(InvMisc[playerid][invmisc_IsOpen] == 0)
		return 0;
	if(GearMisc[playerid][gearmisc_IsOpen] == 1 && GearMisc[playerid][gearmisc_IsLooting] == 1)
			HidePlayerGearLooting(playerid);
	/*Main Hide*/
	for(new id = 0; id<14; id++)
	{
		PlayerTextDrawHide(playerid,InvTextDraw[playerid][invtext_GuiMain][id]);
	}
	if(GearMisc[playerid][gearmisc_IsOpen] == 1)
		PlayerTextDrawShow(playerid,InvTextDraw[playerid][invtext_GuiMain][2]);
	/*Button hide*/
	for(new id = 0; id<4; id++)
	{
		PlayerTextDrawHide(playerid,InvTextDraw[playerid][invtext_ButtonInv][id]);
		PlayerTextDrawHide(playerid,InvTextDraw[playerid][invtext_ButtonGear][id]);
	}
	/*Gui Title*/
	PlayerTextDrawHide(playerid,InvTextDraw[playerid][invtext_GuiTitle][0]);
	/*Gui Page*/
	PlayerTextDrawHide(playerid,InvTextDraw[playerid][invtext_GuiPage][0]);
	/*Equip weapon hide*/
	for(new id = 0; id<2; id++)
	{
		//////////////////////////////////////////////////////////////////////////////
		PlayerTextDrawHide(playerid,InvTextDraw[playerid][invtext_EquipWeapon][id]);
		PlayerTextDrawHide(playerid,InvTextDraw[playerid][invtext_EquipWeaponName][id]);
	}
	/*Equip tool hide*/
	for(new id = 0; id<5; id++)
	{
		PlayerTextDrawHide(playerid,InvTextDraw[playerid][invtext_EquipTool][id]);
	/*Equip food hide*/
		PlayerTextDrawSetPreviewModel(playerid, InvTextDraw[playerid][invtext_EquipFood][id], 19134);
		PlayerTextDrawSetPreviewRot(playerid, InvTextDraw[playerid][invtext_EquipFood][id], 0.000000, 0.000000, 0.000000, -1.000000);
		PlayerTextDrawHide(playerid,InvTextDraw[playerid][invtext_EquipFood][id]);
	/*Equip medic hide*/
		PlayerTextDrawSetPreviewModel(playerid, InvTextDraw[playerid][invtext_EquipMedic][id], 19134);
		PlayerTextDrawSetPreviewRot(playerid, InvTextDraw[playerid][invtext_EquipMedic][id], 0.000000, 0.000000, 0.000000, -1.000000);
		PlayerTextDrawHide(playerid,InvTextDraw[playerid][invtext_EquipMedic][id]);
	/*Misc*/
		InvMisc[playerid][invmisc_EquipMedicItemid][id] = 0,//Item in show privew model
		InvMisc[playerid][invmisc_EquipMedicItemSlot][id] = 0;// item slot

		InvMisc[playerid][invmisc_EquipFoodItemid][id] = 0,//Item in show privew model
		InvMisc[playerid][invmisc_EquipFoodItemAmount][id]=0,
		InvMisc[playerid][invmisc_EquipFoodItemSlot][id] = 0;// item slot
	}
	/**/
	PlayerTextDrawSetString(playerid, InvTextDraw[playerid][invtext_GuiInfo], "");
	PlayerTextDrawHide(playerid,InvTextDraw[playerid][invtext_GuiInfo]);
	/*Hide item*/
	for(new id = 0; id<10; id++)
	{
		PlayerTextDrawHide(playerid,InvTextDraw[playerid][invtext_InvItem][id]);
	}
	/*Hide item gear*/
	for(new id = 0; id<10; id++)
	{
		PlayerTextDrawHide(playerid,InvTextDraw[playerid][invtext_GearItem][id]);
	}
	CancelSelectTextDraw(playerid);
	InvMisc[playerid][invmisc_IsOpen] = 0;
	InvMisc[playerid][invmisc_IsLastClickSlot] = -1;
	InvMisc[playerid][invmisc_IsLastClickID] = 0;
	InvMisc[playerid][invmisc_EquipMedicCount] = 0;
	InvMisc[playerid][invmisc_EquipFoodCount] = 0;
	InvMisc[playerid][invmisc_EquipToolCount] = 0;
	PlayerInventoryArrange(playerid);
	return 1;
}
SetInventoryTextInfo(playerid,show = 0,info[],{Float, _}:...)
{
	static args,str[256];

	if ((args = numargs()) == 3)
	{
		PlayerTextDrawSetString(playerid, InvTextDraw[playerid][invtext_GuiInfo],info);
	}
	else
	{
		while (--args >= 3)
		{
			#emit LCTRL 5
			#emit LOAD.alt args
			#emit SHL.C.alt 2
			#emit ADD.C 12
			#emit ADD
			#emit LOAD.I
			#emit PUSH.pri
		}
		#emit PUSH.S info
		#emit PUSH.C 144
		#emit PUSH.C str
		#emit PUSH.S 8
		#emit SYSREQ.C format
		#emit LCTRL 5
		#emit SCTRL 4

		PlayerTextDrawSetString(playerid, InvTextDraw[playerid][invtext_GuiInfo], str);

		#emit RETN
	}
	if(show == 1)
		PlayerTextDrawShow(playerid,InvTextDraw[playerid][invtext_GuiInfo]);
	return 1;
}
//////////////////////Textdraw
stock InvCreate_GearItem(playerid)
{

	InvTextDraw[playerid][invtext_GearItem][0] = CreatePlayerTextDraw(playerid,140.000000, 157.000000, "Empty");
	_SetupItemGear(playerid,0);

	InvTextDraw[playerid][invtext_GearItem][1] = CreatePlayerTextDraw(playerid,140.000000, 174.000000, "Empty");
	_SetupItemGear(playerid,1);

	InvTextDraw[playerid][invtext_GearItem][2] = CreatePlayerTextDraw(playerid,140.000000, 191.000000, "Empty");
	_SetupItemGear(playerid,2);

	InvTextDraw[playerid][invtext_GearItem][3] = CreatePlayerTextDraw(playerid,140.000000, 208.500000, "Empty");
	_SetupItemGear(playerid,3);

	InvTextDraw[playerid][invtext_GearItem][4] = CreatePlayerTextDraw(playerid,140.000000, 226.000000, "Empty");
	_SetupItemGear(playerid,4);

	InvTextDraw[playerid][invtext_GearItem][5] = CreatePlayerTextDraw(playerid,140.000000, 243.000000, "Empty");
	_SetupItemGear(playerid,5);

	InvTextDraw[playerid][invtext_GearItem][6] = CreatePlayerTextDraw(playerid,140.000000, 261.000000, "Empty");
	_SetupItemGear(playerid,6);

	InvTextDraw[playerid][invtext_GearItem][7] = CreatePlayerTextDraw(playerid,140.000000, 278.500000, "Empty");
	_SetupItemGear(playerid,7);

	InvTextDraw[playerid][invtext_GearItem][8] = CreatePlayerTextDraw(playerid,140.000000, 295.500000, "Empty");
	_SetupItemGear(playerid,8);

	InvTextDraw[playerid][invtext_GearItem][9] = CreatePlayerTextDraw(playerid,140.000000, 313.000000, "Empty");
	_SetupItemGear(playerid,9);
	return 1;
}
stock _SetupItemGear(playerid,id)
{
	/*PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GearItem][id], 0);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_GearItem][id], 1);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_GearItem][id], 0.300000, 1.200000);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GearItem][id], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_GearItem][id], 1);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_GearItem][id], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_GearItem][id], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GearItem][id], 119);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_GearItem][id], 237.000000, 10.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_GearItem][id], 1);*/

	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GearItem][id], 255);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_GearItem][id], 2);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_GearItem][id], 0.159999, 1.200000);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GearItem][id], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_GearItem][id], 1);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_GearItem][id], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_GearItem][id], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GearItem][id], 0x00000050);//119);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_GearItem][id], 237.000000, 10.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_GearItem][id], 1);
	return 1;
}
stock InvCreate_Item(playerid)
{
	InvTextDraw[playerid][invtext_InvItem][0] = CreatePlayerTextDraw(playerid,400.000000, 157.000000, "Empty");
	_SetupItemInv(playerid,0);

	InvTextDraw[playerid][invtext_InvItem][1] = CreatePlayerTextDraw(playerid,400.000000, 174.000000, "Empty");
	_SetupItemInv(playerid,1);

	InvTextDraw[playerid][invtext_InvItem][2] = CreatePlayerTextDraw(playerid,400.000000, 191.000000, "Empty");
	_SetupItemInv(playerid,2);

	InvTextDraw[playerid][invtext_InvItem][3] = CreatePlayerTextDraw(playerid,400.000000, 208.000000, "Empty");
	_SetupItemInv(playerid,3);

	InvTextDraw[playerid][invtext_InvItem][4] = CreatePlayerTextDraw(playerid,400.000000, 225.500000, "Empty");
	_SetupItemInv(playerid,4);

	InvTextDraw[playerid][invtext_InvItem][5] = CreatePlayerTextDraw(playerid,400.000000, 243.000000, "Empty");
	_SetupItemInv(playerid,5);

	InvTextDraw[playerid][invtext_InvItem][6] = CreatePlayerTextDraw(playerid,400.000000, 260.500000, "Empty");
	_SetupItemInv(playerid,6);

	InvTextDraw[playerid][invtext_InvItem][7] = CreatePlayerTextDraw(playerid,400.000000, 278.000000, "Empty");
	_SetupItemInv(playerid,7);

	InvTextDraw[playerid][invtext_InvItem][8] = CreatePlayerTextDraw(playerid,400.000000, 295.500000, "Empty");
	_SetupItemInv(playerid,8);

	InvTextDraw[playerid][invtext_InvItem][9] = CreatePlayerTextDraw(playerid,400.000000, 313.000000, "Empty");
	_SetupItemInv(playerid,9);
	return 1;
}

stock _SetupItemInv(playerid,id)
{
	/*PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_InvItem][id], 0);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_InvItem][id], 1);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_InvItem][id], 0.300000, 1.200000);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_InvItem][id], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_InvItem][id], 1);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_InvItem][id], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_InvItem][id], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_InvItem][id], 0x00000050);//119);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_InvItem][id], 498.000000, 10.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_InvItem][id], 1);*/
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_InvItem][id], 255);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_InvItem][id], 2);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_InvItem][id], 0.159999, 1.200000);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_InvItem][id], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_InvItem][id], 1);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_InvItem][id], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_InvItem][id], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_InvItem][id], 0x00000050);//119);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_InvItem][id], 498.000000, 10.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_InvItem][id], 1);
}
stock InvCreate_EquipMedic(playerid)
{
	InvTextDraw[playerid][invtext_EquipMedic][0] = CreatePlayerTextDraw(playerid,245.000000, 319.000000, "Medicines1");
	_SetupButtonInvEquipMedic(playerid,0);

	InvTextDraw[playerid][invtext_EquipMedic][1] = CreatePlayerTextDraw(playerid,275.000000, 319.000000, "Medicines2");
	_SetupButtonInvEquipMedic(playerid,1);

	InvTextDraw[playerid][invtext_EquipMedic][2] = CreatePlayerTextDraw(playerid,305.000000, 319.000000, "Medicines3");
	_SetupButtonInvEquipMedic(playerid,2);

	InvTextDraw[playerid][invtext_EquipMedic][3] = CreatePlayerTextDraw(playerid,335.000000, 319.000000, "Medicines4");
	_SetupButtonInvEquipMedic(playerid,3);

	InvTextDraw[playerid][invtext_EquipMedic][4] = CreatePlayerTextDraw(playerid,364.700012, 319.000000, "Medicines5");
	_SetupButtonInvEquipMedic(playerid,4);
	return 1;
}
stock _SetupButtonInvEquipMedic(playerid,id)
{
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_EquipMedic][id], 0x80808077);//-741092557);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_EquipMedic][id], 5);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_EquipMedic][id], 0.500000, 1.000000);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_EquipMedic][id], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_EquipMedic][id], 0);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_EquipMedic][id], 1);
	PlayerTextDrawSetShadow(playerid,InvTextDraw[playerid][invtext_EquipMedic][id], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_EquipMedic][id], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_EquipMedic][id], 0);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_EquipMedic][id], 29.000000, 27.000000);
	PlayerTextDrawSetPreviewModel(playerid, InvTextDraw[playerid][invtext_EquipMedic][id], 19134);
	PlayerTextDrawSetPreviewRot(playerid, InvTextDraw[playerid][invtext_EquipMedic][id], 0.000000, 0.000000, 0.000000, -1.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_EquipMedic][id], 1);
	return 1;
}
stock InvCreate_EquipFood(playerid)
{
	InvTextDraw[playerid][invtext_EquipFood][0] = CreatePlayerTextDraw(playerid,245.000000, 278.000000, "Food/Drink1");
	_SetupButtonInvEquipFood(playerid,0);

	InvTextDraw[playerid][invtext_EquipFood][1] = CreatePlayerTextDraw(playerid,275.000000, 278.000000, "Food/Drink2");
	_SetupButtonInvEquipFood(playerid,1);

	InvTextDraw[playerid][invtext_EquipFood][2] = CreatePlayerTextDraw(playerid,305.000000, 278.000000, "Food/Drink3");
	_SetupButtonInvEquipFood(playerid,2);

	InvTextDraw[playerid][invtext_EquipFood][3] = CreatePlayerTextDraw(playerid,335.000000, 278.000000, "Food/Drink4");
	_SetupButtonInvEquipFood(playerid,3);

	InvTextDraw[playerid][invtext_EquipFood][4] = CreatePlayerTextDraw(playerid,364.700012, 278.000000, "Food/Drink5");
	_SetupButtonInvEquipFood(playerid,4);
	return 1;
}
stock _SetupButtonInvEquipFood(playerid,id)
{
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_EquipFood][id], 0x80808077);//-741092557);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_EquipFood][id], 5);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_EquipFood][id], 0.500000, 1.000000);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_EquipFood][id], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_EquipFood][id], 0);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_EquipFood][id], 1);
	PlayerTextDrawSetShadow(playerid,InvTextDraw[playerid][invtext_EquipFood][id], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_EquipFood][id], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_EquipFood][id], 0);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_EquipFood][id], 29.000000, 27.000000);
	PlayerTextDrawSetPreviewModel(playerid, InvTextDraw[playerid][invtext_EquipFood][id], 19134);
	PlayerTextDrawSetPreviewRot(playerid, InvTextDraw[playerid][invtext_EquipFood][id], 0.000000, 0.000000, 0.000000, -1.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_EquipFood][id], 1);
	return 1;
}
stock InvCreate_EquipTool(playerid)
{
	InvTextDraw[playerid][invtext_EquipTool][0] = CreatePlayerTextDraw(playerid,245.000000, 237.000000, "Equip1");
	_SetupButtonInvEquipTool(playerid,0);

	InvTextDraw[playerid][invtext_EquipTool][1] = CreatePlayerTextDraw(playerid,275.000000, 237.000000, "Equip2");
	_SetupButtonInvEquipTool(playerid,1);

	InvTextDraw[playerid][invtext_EquipTool][2] = CreatePlayerTextDraw(playerid,305.000000, 237.000000, "Equip3");
	_SetupButtonInvEquipTool(playerid,2);

	InvTextDraw[playerid][invtext_EquipTool][3] = CreatePlayerTextDraw(playerid,335.000000, 237.000000, "Equip4");
	_SetupButtonInvEquipTool(playerid,3);

	InvTextDraw[playerid][invtext_EquipTool][4] = CreatePlayerTextDraw(playerid,364.700012, 237.000000, "Equip5");
	_SetupButtonInvEquipTool(playerid,4);
	return 1;
}
stock _SetupButtonInvEquipTool(playerid,id)
{
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_EquipTool][id], 0x80808077);//-741092557);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_EquipTool][id], 5);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_EquipTool][id], 0.500000, 1.000000);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_EquipTool][id], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_EquipTool][id], 0);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_EquipTool][id], 1);
	PlayerTextDrawSetShadow(playerid,InvTextDraw[playerid][invtext_EquipTool][id], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_EquipTool][id], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_EquipTool][id], 0);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_EquipTool][id], 29.000000, 27.000000);
	PlayerTextDrawSetPreviewModel(playerid, InvTextDraw[playerid][invtext_EquipTool][id], 19134);
	PlayerTextDrawSetPreviewRot(playerid, InvTextDraw[playerid][invtext_EquipTool][id], 0.000000, 0.000000, 0.000000, -1.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_EquipTool][id], 1);
	return 1;
}
stock InvCreate_EquipWeapon(playerid)
{
	InvTextDraw[playerid][invtext_EquipWeapon][0] = CreatePlayerTextDraw(playerid,243.000000, 154.000000, "PrimaryWeapon");
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_EquipWeapon][0], 119);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_EquipWeapon][0], 5);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_EquipWeapon][0], 0.500000, 1.000000);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_EquipWeapon][0], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_EquipWeapon][0], 0);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_EquipWeapon][0], 1);
	PlayerTextDrawSetShadow(playerid,InvTextDraw[playerid][invtext_EquipWeapon][0], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_EquipWeapon][0], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_EquipWeapon][0], 0);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_EquipWeapon][0], 76.000000, 39.000000);
	PlayerTextDrawSetPreviewModel(playerid, InvTextDraw[playerid][invtext_EquipWeapon][0], 3008);
	PlayerTextDrawSetPreviewRot(playerid, InvTextDraw[playerid][invtext_EquipWeapon][0], 0.000000, 0.000000, 0.000000, 1.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_EquipWeapon][0], 1);

	InvTextDraw[playerid][invtext_EquipWeapon][1] = CreatePlayerTextDraw(playerid,319.500000, 154.000000, "SecondaryWeapon");
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_EquipWeapon][1], 119);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_EquipWeapon][1], 5);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_EquipWeapon][1], 0.500000, 1.000000);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_EquipWeapon][1], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_EquipWeapon][1], 0);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_EquipWeapon][1], 1);
	PlayerTextDrawSetShadow(playerid,InvTextDraw[playerid][invtext_EquipWeapon][1], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_EquipWeapon][1], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_EquipWeapon][1], 0);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_EquipWeapon][1], 75.000000, 39.000000);
	PlayerTextDrawSetPreviewModel(playerid, InvTextDraw[playerid][invtext_EquipWeapon][1], 3008);
	PlayerTextDrawSetPreviewRot(playerid, InvTextDraw[playerid][invtext_EquipWeapon][1], 0.000000, 0.000000, 0.000000, 1.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_EquipWeapon][1], 1);

	
	InvTextDraw[playerid][invtext_EquipWeaponName][0] = CreatePlayerTextDraw(playerid,243.000000, 186.000000, "Primary");
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_EquipWeaponName][0], 0);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_EquipWeaponName][0], 1);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_EquipWeaponName][0], 0.179999, 0.699998);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_EquipWeaponName][0], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_EquipWeaponName][0], 1);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_EquipWeaponName][0], 1);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_EquipWeaponName][0], 0);

	InvTextDraw[playerid][invtext_EquipWeaponName][1] = CreatePlayerTextDraw(playerid,320.000000, 186.000000, "Secondary");
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_EquipWeaponName][1], 0);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_EquipWeaponName][1], 1);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_EquipWeaponName][1], 0.179999, 0.699998);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_EquipWeaponName][1], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_EquipWeaponName][1], 1);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_EquipWeaponName][1], 1);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_EquipWeaponName][1], 0);

	return 1;
}
stock InvCreate_Button(playerid)
{
	//inv
	InvTextDraw[playerid][invtext_ButtonInv][0] = CreatePlayerTextDraw(playerid,424.000000, 332.000000, "USE");
	_SetupButtonInvGear(playerid,0,0);

	InvTextDraw[playerid][invtext_ButtonInv][1] = CreatePlayerTextDraw(playerid,474.000000, 332.000000, "Drop");
	_SetupButtonInvGear(playerid,1,0);

	InvTextDraw[playerid][invtext_ButtonInv][2] = CreatePlayerTextDraw(playerid,503.000000, 316.000000, "LD_BEAT:up");
	_SetupButtonInvGear2(playerid,2,0);

	InvTextDraw[playerid][invtext_ButtonInv][3] = CreatePlayerTextDraw(playerid,503.000000, 336.000000, "LD_BEAT:down");
	_SetupButtonInvGear2(playerid,3,0);

	///////////////////////////////////////////////Gear
	InvTextDraw[playerid][invtext_ButtonGear][0] = CreatePlayerTextDraw(playerid,163.000000, 332.000000, "Loot");
	_SetupButtonInvGear(playerid,0,1);

	InvTextDraw[playerid][invtext_ButtonGear][1] = CreatePlayerTextDraw(playerid,213.000000, 332.000000, "PUT");
	_SetupButtonInvGear(playerid,1,1);

	InvTextDraw[playerid][invtext_ButtonGear][2] = CreatePlayerTextDraw(playerid,123.000000, 316.000000, "LD_BEAT:up");
	_SetupButtonInvGear2(playerid,2,1);

	InvTextDraw[playerid][invtext_ButtonGear][3] = CreatePlayerTextDraw(playerid,123.000000, 336.000000, "LD_BEAT:down");
	_SetupButtonInvGear2(playerid,3,1);
	return 1;
}
stock _SetupButtonInvGear2(playerid,id,type)
{
	if(type == 0)
	{
		PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_ButtonInv][id], 255);
		PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_ButtonInv][id], 4);
		PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_ButtonInv][id], 0.500000, 1.000000);
		PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_ButtonInv][id], -1);
		PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_ButtonInv][id], 0);
		PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_ButtonInv][id], 1);
		PlayerTextDrawSetShadow(playerid,InvTextDraw[playerid][invtext_ButtonInv][id], 1);
		PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_ButtonInv][id], 1);
		PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_ButtonInv][id], 255);
		PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_ButtonInv][id], 12.000000, 12.000000);
		PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_ButtonInv][id], 1);
	}
	else
	{
		PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_ButtonGear][id], 255);
		PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_ButtonGear][id], 4);
		PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_ButtonGear][id], 0.500000, 1.000000);
		PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_ButtonGear][id], -1);
		PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_ButtonGear][id], 0);
		PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_ButtonGear][id], 1);
		PlayerTextDrawSetShadow(playerid,InvTextDraw[playerid][invtext_ButtonGear][id], 1);
		PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_ButtonGear][id], 1);
		PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_ButtonGear][id], 255);
		PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_ButtonGear][id], 12.000000, 12.000000);
		PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_ButtonGear][id], 1);
	}
	return 1;
}
stock _SetupButtonInvGear(playerid,id,type)
{
	if(type == 0)
	{
		PlayerTextDrawAlignment(playerid,InvTextDraw[playerid][invtext_ButtonInv][id], 2);
		PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_ButtonInv][id], 0);
		PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_ButtonInv][id], 2);
		PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_ButtonInv][id], 0.310000, 1.100000);
		PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_ButtonInv][id], -1);
		PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_ButtonInv][id], 1);
		PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_ButtonInv][id], 1);
		PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_ButtonInv][id], 1);
		PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_ButtonInv][id], 0);
		PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_ButtonInv][id], 15.000000, 15.000000);
		PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_ButtonInv][id], 1);
	}
	else
	{
		PlayerTextDrawAlignment(playerid,InvTextDraw[playerid][invtext_ButtonGear][id], 2);
		PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_ButtonGear][id], 0);
		PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_ButtonGear][id], 2);
		PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_ButtonGear][id], 0.310000, 1.100000);
		PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_ButtonGear][id], -1);
		PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_ButtonGear][id], 1);
		PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_ButtonGear][id], 1);
		PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_ButtonGear][id], 1);
		PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_ButtonGear][id], 0);
		PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_ButtonGear][id], 15.000000, 15.000000);
		PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_ButtonGear][id], 1);
	}
	return 1;
}
stock InvCreate_GuiMain(playerid)
{
	//Color Edit
	InvEditColor[playerid][invcolor_GuiMainColor][0] = 136;
	InvEditColor[playerid][invcolor_GuiMainColor][1] = 136;
	InvEditColor[playerid][invcolor_GuiMainColor][2] = 136;
	//Select color
	InvEditColor[playerid][invcolor_SelectColor] = 0x808080FF;
	//Textdraw
	InvTextDraw[playerid][invtext_GuiMain][0] = CreatePlayerTextDraw(playerid,319.000000, 141.000000, "_");
	PlayerTextDrawAlignment(playerid,InvTextDraw[playerid][invtext_GuiMain][0], 2);
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GuiMain][0], 255);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_GuiMain][0], 1);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_GuiMain][0], 0.500000, 22.899995);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GuiMain][0], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_GuiMain][0], 0);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_GuiMain][0], 1);
	PlayerTextDrawSetShadow(playerid,InvTextDraw[playerid][invtext_GuiMain][0], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_GuiMain][0], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GuiMain][0], 136);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_GuiMain][0], 100.000000, 150.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_GuiMain][0], 0);


	InvTextDraw[playerid][invtext_GuiMain][1] = CreatePlayerTextDraw(playerid,449.000000, 141.000000, "_");
	PlayerTextDrawAlignment(playerid,InvTextDraw[playerid][invtext_GuiMain][1], 2);
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GuiMain][1], 255);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_GuiMain][1], 1);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_GuiMain][1], 0.500000, 22.899995);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GuiMain][1], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_GuiMain][1], 0);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_GuiMain][1], 1);
	PlayerTextDrawSetShadow(playerid,InvTextDraw[playerid][invtext_GuiMain][1], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_GuiMain][1], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GuiMain][1], 136);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_GuiMain][1], 100.000000, 100.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_GuiMain][1], 0);


	InvTextDraw[playerid][invtext_GuiMain][2] = CreatePlayerTextDraw(playerid,188.500000, 141.000000, "_");
	PlayerTextDrawAlignment(playerid,InvTextDraw[playerid][invtext_GuiMain][2], 2);
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GuiMain][2], 255);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_GuiMain][2], 1);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_GuiMain][2], 0.500000, 22.899999);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GuiMain][2], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_GuiMain][2], 0);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_GuiMain][2], 1);
	PlayerTextDrawSetShadow(playerid,InvTextDraw[playerid][invtext_GuiMain][2], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_GuiMain][2], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GuiMain][2], 136);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_GuiMain][2], 100.000000, 100.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_GuiMain][2], 0);


	InvTextDraw[playerid][invtext_GuiMain][3] = CreatePlayerTextDraw(playerid,319.000000, 141.000000, "Backpack");
	PlayerTextDrawAlignment(playerid,InvTextDraw[playerid][invtext_GuiMain][3], 2);
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GuiMain][3], 255);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_GuiMain][3], 1);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_GuiMain][3], 0.250000, 1.000000);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GuiMain][3], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_GuiMain][3], 1);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_GuiMain][3], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_GuiMain][3], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GuiMain][3], 336860415);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_GuiMain][3], 393.000000, 150.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_GuiMain][3], 0);


	InvTextDraw[playerid][invtext_GuiMain][4] = CreatePlayerTextDraw(playerid,319.000000, 196.500000, "_");
	PlayerTextDrawAlignment(playerid,InvTextDraw[playerid][invtext_GuiMain][4], 2);
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GuiMain][4], 255);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_GuiMain][4], 1);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_GuiMain][4], 0.250000, 2.699999);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GuiMain][4], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_GuiMain][4], 1);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_GuiMain][4], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_GuiMain][4], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GuiMain][4], -1061109696);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_GuiMain][4], 393.000000, 150.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_GuiMain][4], 0);


	InvTextDraw[playerid][invtext_GuiMain][5] = CreatePlayerTextDraw(playerid,319.000000, 227.000000, "Equip/Tool");
	PlayerTextDrawAlignment(playerid,InvTextDraw[playerid][invtext_GuiMain][5], 2);
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GuiMain][5], 255);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_GuiMain][5], 1);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_GuiMain][5], 0.199999, 0.699998);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GuiMain][5], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_GuiMain][5], 1);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_GuiMain][5], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_GuiMain][5], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GuiMain][5], 336860415);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_GuiMain][5], 393.000000, 150.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_GuiMain][5], 0);

	InvTextDraw[playerid][invtext_GuiMain][6] = CreatePlayerTextDraw(playerid,319.000000, 268.000000, "Food/Drink");
	PlayerTextDrawAlignment(playerid,InvTextDraw[playerid][invtext_GuiMain][6], 2);
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GuiMain][6], 255);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_GuiMain][6], 1);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_GuiMain][6], 0.199999, 0.699998);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GuiMain][6], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_GuiMain][6], 1);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_GuiMain][6], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_GuiMain][6], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GuiMain][6], 336860415);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_GuiMain][6], 393.000000, 150.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_GuiMain][6], 0);

	InvTextDraw[playerid][invtext_GuiMain][7] = CreatePlayerTextDraw(playerid,319.000000, 309.000000, "MEDICINES");
	PlayerTextDrawAlignment(playerid,InvTextDraw[playerid][invtext_GuiMain][7], 2);
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GuiMain][7], 255);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_GuiMain][7], 1);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_GuiMain][7], 0.199999, 0.699998);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GuiMain][7], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_GuiMain][7], 1);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_GuiMain][7], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_GuiMain][7], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GuiMain][7], 336860415);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_GuiMain][7], 393.000000, 150.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_GuiMain][7], 0);


	//button gui
	//use
	InvTextDraw[playerid][invtext_GuiMain][8] = CreatePlayerTextDraw(playerid,423.000000, 333.000000, "_");
	PlayerTextDrawAlignment(playerid,InvTextDraw[playerid][invtext_GuiMain][8], 2);
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GuiMain][8], 255);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_GuiMain][8], 1);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_GuiMain][8], 0.500000, 1.000000);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GuiMain][8], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_GuiMain][8], 0);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_GuiMain][8], 1);
	PlayerTextDrawSetShadow(playerid,InvTextDraw[playerid][invtext_GuiMain][8], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_GuiMain][8], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GuiMain][8], 336860415);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_GuiMain][8], 0.000000, 40.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_GuiMain][8], 0);


	InvTextDraw[playerid][invtext_GuiMain][9] = CreatePlayerTextDraw(playerid,423.000000, 334.000000, "_");
	PlayerTextDrawAlignment(playerid,InvTextDraw[playerid][invtext_GuiMain][9], 2);
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GuiMain][9], 255);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_GuiMain][9], 1);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_GuiMain][9], 0.500000, 0.799999);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GuiMain][9], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_GuiMain][9], 0);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_GuiMain][9], 1);
	PlayerTextDrawSetShadow(playerid,InvTextDraw[playerid][invtext_GuiMain][9], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_GuiMain][9], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GuiMain][9], -1);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_GuiMain][9], 0.000000, 37.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_GuiMain][9], 0);

	InvTextDraw[playerid][invtext_GuiMain][10] = CreatePlayerTextDraw(playerid,423.000000, 334.500000, "_");
	PlayerTextDrawAlignment(playerid,InvTextDraw[playerid][invtext_GuiMain][10], 2);
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GuiMain][10], 255);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_GuiMain][10], 1);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_GuiMain][10], 0.500000, 0.649999);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GuiMain][10], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_GuiMain][10], 0);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_GuiMain][10], 1);
	PlayerTextDrawSetShadow(playerid,InvTextDraw[playerid][invtext_GuiMain][10], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_GuiMain][10], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GuiMain][10], 336860415);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_GuiMain][10], 0.000000, 36.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_GuiMain][10], 0);
	//drop

	InvTextDraw[playerid][invtext_GuiMain][11] = CreatePlayerTextDraw(playerid,473.000000, 333.000000, "_");
	PlayerTextDrawAlignment(playerid,InvTextDraw[playerid][invtext_GuiMain][11], 2);
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GuiMain][11], 255);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_GuiMain][11], 1);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_GuiMain][11], 0.500000, 1.000000);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GuiMain][11], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_GuiMain][11], 0);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_GuiMain][11], 1);
	PlayerTextDrawSetShadow(playerid,InvTextDraw[playerid][invtext_GuiMain][11], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_GuiMain][11], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GuiMain][11], 336860415);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_GuiMain][11], 0.000000, 40.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_GuiMain][11], 0);

	InvTextDraw[playerid][invtext_GuiMain][12] = CreatePlayerTextDraw(playerid,473.000000, 334.000000, "_");
	PlayerTextDrawAlignment(playerid,InvTextDraw[playerid][invtext_GuiMain][12], 2);
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GuiMain][12], 255);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_GuiMain][12], 1);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_GuiMain][12], 0.500000, 0.799999);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GuiMain][12], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_GuiMain][12], 0);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_GuiMain][12], 1);
	PlayerTextDrawSetShadow(playerid,InvTextDraw[playerid][invtext_GuiMain][12], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_GuiMain][12], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GuiMain][12], -1);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_GuiMain][12], 0.000000, 37.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_GuiMain][12], 0);

	InvTextDraw[playerid][invtext_GuiMain][13] = CreatePlayerTextDraw(playerid,473.000000, 334.500000, "_");
	PlayerTextDrawAlignment(playerid,InvTextDraw[playerid][invtext_GuiMain][13], 2);
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GuiMain][13], 255);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_GuiMain][13], 1);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_GuiMain][13], 0.500000, 0.649999);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GuiMain][13], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_GuiMain][13], 0);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_GuiMain][13], 1);
	PlayerTextDrawSetShadow(playerid,InvTextDraw[playerid][invtext_GuiMain][13], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_GuiMain][13], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GuiMain][13], 336860415);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_GuiMain][13], 0.000000, 36.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_GuiMain][13], 0);
	//loot

	InvTextDraw[playerid][invtext_GuiMain][14] = CreatePlayerTextDraw(playerid,163.000000, 333.000000, "_");
	PlayerTextDrawAlignment(playerid,InvTextDraw[playerid][invtext_GuiMain][14], 2);
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GuiMain][14], 255);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_GuiMain][14], 1);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_GuiMain][14], 0.500000, 1.000000);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GuiMain][14], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_GuiMain][14], 0);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_GuiMain][14], 1);
	PlayerTextDrawSetShadow(playerid,InvTextDraw[playerid][invtext_GuiMain][14], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_GuiMain][14], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GuiMain][14], 336860415);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_GuiMain][14], 0.000000, 40.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_GuiMain][14], 0);

	InvTextDraw[playerid][invtext_GuiMain][15] = CreatePlayerTextDraw(playerid,163.000000, 334.000000, "_");
	PlayerTextDrawAlignment(playerid,InvTextDraw[playerid][invtext_GuiMain][15], 2);
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GuiMain][15], 255);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_GuiMain][15], 1);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_GuiMain][15], 0.500000, 0.799999);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GuiMain][15], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_GuiMain][15], 0);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_GuiMain][15], 1);
	PlayerTextDrawSetShadow(playerid,InvTextDraw[playerid][invtext_GuiMain][15], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_GuiMain][15], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GuiMain][15], -1);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_GuiMain][15], 0.000000, 37.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_GuiMain][15], 0);

	InvTextDraw[playerid][invtext_GuiMain][16] = CreatePlayerTextDraw(playerid,163.000000, 334.500000, "_");
	PlayerTextDrawAlignment(playerid,InvTextDraw[playerid][invtext_GuiMain][16], 2);
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GuiMain][16], 255);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_GuiMain][16], 1);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_GuiMain][16], 0.500000, 0.649999);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GuiMain][16], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_GuiMain][16], 0);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_GuiMain][16], 1);
	PlayerTextDrawSetShadow(playerid,InvTextDraw[playerid][invtext_GuiMain][16], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_GuiMain][16], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GuiMain][16], 336860415);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_GuiMain][16], 0.000000, 36.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_GuiMain][16], 0);
	//Put

	InvTextDraw[playerid][invtext_GuiMain][17] = CreatePlayerTextDraw(playerid,213.000000, 333.000000, "_");
	PlayerTextDrawAlignment(playerid,InvTextDraw[playerid][invtext_GuiMain][17], 2);
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GuiMain][17], 255);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_GuiMain][17], 1);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_GuiMain][17], 0.500000, 1.000000);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GuiMain][17], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_GuiMain][17], 0);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_GuiMain][17], 1);
	PlayerTextDrawSetShadow(playerid,InvTextDraw[playerid][invtext_GuiMain][17], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_GuiMain][17], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GuiMain][17], 336860415);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_GuiMain][17], 0.000000, 40.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_GuiMain][17], 0);

	InvTextDraw[playerid][invtext_GuiMain][18] = CreatePlayerTextDraw(playerid,213.000000, 334.000000, "_");
	PlayerTextDrawAlignment(playerid,InvTextDraw[playerid][invtext_GuiMain][18], 2);
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GuiMain][18], 255);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_GuiMain][18], 1);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_GuiMain][18], 0.500000, 0.799999);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GuiMain][18], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_GuiMain][18], 0);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_GuiMain][18], 1);
	PlayerTextDrawSetShadow(playerid,InvTextDraw[playerid][invtext_GuiMain][18], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_GuiMain][18], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GuiMain][18], -1);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_GuiMain][18], 0.000000, 37.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_GuiMain][18], 0);

	InvTextDraw[playerid][invtext_GuiMain][19] = CreatePlayerTextDraw(playerid,213.000000, 334.500000, "_");
	PlayerTextDrawAlignment(playerid,InvTextDraw[playerid][invtext_GuiMain][19], 2);
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GuiMain][19], 255);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_GuiMain][19], 1);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_GuiMain][19], 0.500000, 0.649999);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GuiMain][19], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_GuiMain][19], 0);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_GuiMain][19], 1);
	PlayerTextDrawSetShadow(playerid,InvTextDraw[playerid][invtext_GuiMain][19], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_GuiMain][19], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GuiMain][19], 336860415);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_GuiMain][19], 0.000000, 36.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_GuiMain][19], 0);

	InvTextDraw[playerid][invtext_GuiInfo] = CreatePlayerTextDraw(playerid,244.000000, 196.000000, "");
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GuiInfo], 255);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_GuiInfo], 1);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_GuiInfo], 0.219999, 0.699998);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GuiInfo], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_GuiInfo], 1);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_GuiInfo], 1);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_GuiInfo], 0);


	InvTextDraw[playerid][invtext_GuiTitle][0] = CreatePlayerTextDraw(playerid,449.000000, 141.000000, "Slot 0/20");
	PlayerTextDrawAlignment(playerid,InvTextDraw[playerid][invtext_GuiTitle][0], 2);
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GuiTitle][0], 255);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_GuiTitle][0], 2);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_GuiTitle][0], 0.160000, 1.000000);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GuiTitle][0], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_GuiTitle][0], 1);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_GuiTitle][0], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_GuiTitle][0], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GuiTitle][0], 336860415);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_GuiTitle][0], 393.000000, 100.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_GuiTitle][0], 0);
	//gear
	InvTextDraw[playerid][invtext_GuiTitle][1] = CreatePlayerTextDraw(playerid,188.500000, 141.000000, "Loot 0/10");
	PlayerTextDrawAlignment(playerid,InvTextDraw[playerid][invtext_GuiTitle][1], 2);
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GuiTitle][1], 255);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_GuiTitle][1], 2);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_GuiTitle][1], 0.159999, 1.000000);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GuiTitle][1], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_GuiTitle][1], 1);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_GuiTitle][1], 1);
	PlayerTextDrawUseBox(playerid,InvTextDraw[playerid][invtext_GuiTitle][1], 1);
	PlayerTextDrawBoxColor(playerid,InvTextDraw[playerid][invtext_GuiTitle][1], 336860415);
	PlayerTextDrawTextSize(playerid,InvTextDraw[playerid][invtext_GuiTitle][1], 393.000000, 100.000000);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_GuiTitle][1], 0);

	//show page inv
	InvTextDraw[playerid][invtext_GuiPage][0] = CreatePlayerTextDraw(playerid,509.000000, 327.000000, "1");
	PlayerTextDrawAlignment(playerid,InvTextDraw[playerid][invtext_GuiPage][0], 2);
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GuiPage][0], 255);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_GuiPage][0], 2);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_GuiPage][0], 0.250000, 0.899999);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GuiPage][0], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_GuiPage][0], 1);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_GuiPage][0], 1);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_GuiPage][0], 0);
	//show page gear

	InvTextDraw[playerid][invtext_GuiPage][1] = CreatePlayerTextDraw(playerid,129.000000, 327.000000, "1");
	PlayerTextDrawAlignment(playerid,InvTextDraw[playerid][invtext_GuiPage][1], 2);
	PlayerTextDrawBackgroundColor(playerid,InvTextDraw[playerid][invtext_GuiPage][1], 255);
	PlayerTextDrawFont(playerid,InvTextDraw[playerid][invtext_GuiPage][1], 2);
	PlayerTextDrawLetterSize(playerid,InvTextDraw[playerid][invtext_GuiPage][1], 0.250000, 0.899999);
	PlayerTextDrawColor(playerid,InvTextDraw[playerid][invtext_GuiPage][1], -1);
	PlayerTextDrawSetOutline(playerid,InvTextDraw[playerid][invtext_GuiPage][1], 1);
	PlayerTextDrawSetProportional(playerid,InvTextDraw[playerid][invtext_GuiPage][1], 1);
	PlayerTextDrawSetSelectable(playerid,InvTextDraw[playerid][invtext_GuiPage][1], 0);
	return 1;
}
stock GetName(playerid)
{
    new name[24];
    GetPlayerName(playerid, name, sizeof(name));
    return name;
}
/************************
	Edit Gui Color Function and Dialog
*************************/
Dialog:INV_EDIT_COLOR(playerid, response, listitem, inputtext[])
{
	if(!response)return 1;
	if(listitem == 3)
	{
	DialogShow(playerid, INV_EDIT_COLOR_SELECT2, DIALOG_STYLE_LIST,"Edit Select Color",
		"{F81414}Red\n{F3FF02}Yellow\n{FFAF00}Orange\n{B7FF00}Lime\n{C3C3C3}Gray\n\
		{00C0FF}LightBlue\n{0049FF}Blue\n{B700FF}Violet\n{FF00EA}Pink","Chon","Dong");			
	}
	else
	{
	InvEditColor[playerid][invcolor_EditGuiID] = listitem;
	DialogShow(playerid, INV_EDIT_COLOR_SELECT, DIALOG_STYLE_LIST,"Edit INV Color",
		"{F81414}Red\n{F3FF02}Yellow\n{FFAF00}Orange\n{B7FF00}Lime\n{C3C3C3}Gray\n\
		{00C0FF}LightBlue\n{0049FF}Blue\n{B700FF}Violet\n{FF00EA}Pink\n{FFFFFF}Normal\n{FFF1AF}Tuy chinh","Chon","Dong");
	}
	return 1;
}
Dialog:INV_EDIT_COLOR_SELECT(playerid, response, listitem, inputtext[])
{
	if(!response)return 1;
	new color;
	switch(listitem)
	{
		case 0:color = 0xFF000066;
		case 1:color = 0xFFFF0066;
		case 2:color = 0xFFA50066;
		case 3:color = 0x00FF0066;
		case 4:color = 0x80808066;
		case 5:color = 0xADD8E666;
		case 6:color = 0x0000FF66;
		case 7:color = 0xEE82EE66;
		case 8:color = 0xFFC0CB66;
		case 9:color = 136;
		case 10: return DialogShow(playerid,INV_EDIT_COLOR_INPUT, DIALOG_STYLE_INPUT,"Mau tuy chinh","Nhap ma mau hex vao o duoi\n Vi du: mau vang '0xFFFF00FF'", "Chon","Dong");
	}
	InvEditColor[playerid][invcolor_GuiMainColor][InvEditColor[playerid][invcolor_EditGuiID]] = color;
	InvEditColor[playerid][invcolor_EditGuiID] = -1;
	return 1;
}
Dialog:INV_EDIT_COLOR_SELECT2(playerid, response, listitem, inputtext[])
{
	if(!response)return 1;
	new color;
	switch(listitem)
	{
		case 0:color = 0xFF0000FF;
		case 1:color = 0xFFFF00FF;
		case 2:color = 0xFFA500FF;
		case 3:color = 0x00FF00FF;
		case 4:color = 0x808080FF;
		case 5:color = 0xADD8E6FF;
		case 6:color = 0x0000FFFF;
		case 7:color = 0xEE82EEFF;
		case 8:color = 0xFFC0CBFF;
	}
	InvEditColor[playerid][invcolor_SelectColor] = color;
	return 1;
}
Dialog:INV_EDIT_COLOR_INPUT(playerid, response, listitem, inputtext[])
{
	if(!response)return 1;
	if(response)
    {
		new red[3], green[3], blue[3], alpha[3];
		if(inputtext[0] == '0' && inputtext[1] == 'x') // He's using 0xFFFFFF format
		{
			if(strlen(inputtext) != 8 && strlen(inputtext) != 10)
				return DialogShow(playerid,INV_EDIT_COLOR_INPUT, DIALOG_STYLE_INPUT,"Mau tuy chinh","Nhap ma mau hex vao o duoi\n Vi du: mau vang '0xFFFF00FF'", "Chon","Dong");
			else
			{
				format(red, sizeof(red), "%c%c", inputtext[2], inputtext[3]);
				format(green, sizeof(green), "%c%c", inputtext[4], inputtext[5]);
				format(blue, sizeof(blue), "%c%c", inputtext[6], inputtext[7]);
				if(inputtext[8] != '\0')
					format(alpha, sizeof(alpha), "%c%c", inputtext[8], inputtext[9]);
				else
					alpha = "FF";
			}
		}
        else if(inputtext[0] == '#') // He's using #FFFFFF format
        {
            if(strlen(inputtext) != 7 && strlen(inputtext) != 9) 
                return DialogShow(playerid,INV_EDIT_COLOR_INPUT, DIALOG_STYLE_INPUT,"Mau tuy chinh","Nhap ma mau hex vao o duoi\n Vi du: mau vang '0xFFFF00FF'", "Chon","Dong");
            else
            {
	            format(red, sizeof(red), "%c%c", inputtext[1], inputtext[2]);
	            format(green, sizeof(green), "%c%c", inputtext[3], inputtext[4]);
	           	format(blue, sizeof(blue), "%c%c", inputtext[5], inputtext[6]);
	            if(inputtext[7] != '\0')
	                format(alpha, sizeof(alpha), "%c%c", inputtext[7], inputtext[8]);
				else
					alpha = "FF";
			}
        }
        else // He's using FFFFFF format
        {
            if(strlen(inputtext) != 6 && strlen(inputtext) != 8)
                return DialogShow(playerid,INV_EDIT_COLOR_INPUT, DIALOG_STYLE_INPUT,"Mau tuy chinh","Nhap ma mau hex vao o duoi\n Vi du: mau vang '0xFFFF00FF'", "Chon","Dong");
            else
            {
	            format(red, sizeof(red), "%c%c", inputtext[0], inputtext[1]);
	            format(green, sizeof(green), "%c%c", inputtext[2], inputtext[3]);
	            format(blue, sizeof(blue), "%c%c", inputtext[4], inputtext[5]);
	            if(inputtext[6] != '\0')
	                format(alpha, sizeof(alpha), "%c%c", inputtext[6], inputtext[7]);
				else
					alpha = "FF";
			}
        }
        InvEditColor[playerid][invcolor_GuiMainColor][InvEditColor[playerid][invcolor_EditGuiID]] = RGB(HexToInt(red), HexToInt(green), HexToInt(blue), HexToInt(alpha));
		InvEditColor[playerid][invcolor_EditGuiID] = -1;
    }     
    
	return 1;
}
stock RGB( red, green, blue, alpha )
{
	/*  Combines a color and returns it, so it can be used in functions.
	    @red:           Amount of red color.
	    @green:         Amount of green color.
	    @blue:          Amount of blue color.
	    @alpha:         Amount of alpha transparency.

		-Returns:
		A integer with the combined color.
	*/
	return (red * 16777216) + (green * 65536) + (blue * 256) + alpha;
}
stock HexToInt(string[]) {
  if (string[0]==0) return 0;
  new i;
  new cur=1;
  new res=0;
  for (i=strlen(string);i>0;i--) {
    if (string[i-1]<58) res=res+cur*(string[i-1]-48); else res=res+cur*(string[i-1]-65+10);
    cur=cur*16;
  }
  return res;
}
///////////////////////////////////////////////////////////////////
