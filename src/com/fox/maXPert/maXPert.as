import com.Components.ItemSlot;
import com.GameInterface.DistributedValue;
import com.Utils.Format;
import com.Utils.LDBFormat;
import flash.geom.Point;
import gfx.managers.DragManager;
import mx.utils.Delegate;
import com.GameInterface.Game.Character;
import com.Utils.ID32;
import com.GameInterface.Inventory;
import com.GameInterface.InventoryItem;
import com.GameInterface.CraftingInterface;
import com.GameInterface.Tooltip.TooltipInterface;
import com.GameInterface.Tooltip.TooltipData;
import com.GameInterface.Tooltip.TooltipManager;
import com.Utils.DragObject;

class com.fox.maXPert.maXPert {

	private var m_expContainer:MovieClip
	private var m_upgradewindow:DistributedValue
	private var m_remainingTalismanExp:TextField
	private var m_remainingGlyphExp:TextField
	private var m_remainingSignetExp:TextField
	private var m_UpgradeInventory:Inventory;
	private var m_EquipmentInventory:Inventory;
	private var m_Inventory:Inventory;
	private var refresh;
	private var m_swfroot:MovieClip;
	private var Tooltip:TooltipInterface;
	private var warningClip:MovieClip;
	private var resultItemID;
	private var ItemPositions = new Array();

	public function maXPert(swfRoot: MovieClip) {
		m_swfroot = swfRoot;
		m_upgradewindow = DistributedValue.Create("ItemUpgradeWindow");
		m_UpgradeInventory = new Inventory(new ID32(_global.Enums.InvType.e_Type_GC_CraftingInventory, Character.GetClientCharID().GetInstance()));
		m_Inventory = new Inventory(new ID32(_global.Enums.InvType.e_Type_GC_BackpackContainer, Character.GetClientCharID().GetInstance()));
		m_EquipmentInventory = new Inventory(new ID32(_global.Enums.InvType.e_Type_GC_WeaponContainer, Character.GetClientCharacter().GetID().GetInstance()));

		/*
		com.GameInterface.UtilsBase.PrintChatText("Weapon / Talisman");
		com.GameInterface.UtilsBase.PrintChatText("Standard "+string(Inventory.GetItemXPForLevel(30131, 2, 2)));
		com.GameInterface.UtilsBase.PrintChatText("Superior "+string(Inventory.GetItemXPForLevel(30131, 3, 2)));
		com.GameInterface.UtilsBase.PrintChatText("Epic "+string(Inventory.GetItemXPForLevel(30131, 4, 2)));
		com.GameInterface.UtilsBase.PrintChatText("Mythic "+string(Inventory.GetItemXPForLevel(30131, 5, 2)));
		com.GameInterface.UtilsBase.PrintChatText("Legendary "+string(Inventory.GetItemXPForLevel(30131, 6, 2)));
		com.GameInterface.UtilsBase.PrintChatText("--------");
		com.GameInterface.UtilsBase.PrintChatText("Glyph");
		com.GameInterface.UtilsBase.PrintChatText("Standard "+string(Inventory.GetItemXPForLevel(30129, 2, 2)));
		com.GameInterface.UtilsBase.PrintChatText("Superior "+string(Inventory.GetItemXPForLevel(30129, 3, 2)));
		com.GameInterface.UtilsBase.PrintChatText("Epic "+string(Inventory.GetItemXPForLevel(30129, 4, 2)));
		com.GameInterface.UtilsBase.PrintChatText("Mythic "+string(Inventory.GetItemXPForLevel(30129, 5, 2)));
		com.GameInterface.UtilsBase.PrintChatText("Legendary " + string(Inventory.GetItemXPForLevel(30129, 6, 2)));
		com.GameInterface.UtilsBase.PrintChatText("--------");
		com.GameInterface.UtilsBase.PrintChatText("Signet");
		com.GameInterface.UtilsBase.PrintChatText("Standard "+string(Inventory.GetItemXPForLevel(30133, 2, 2)));
		com.GameInterface.UtilsBase.PrintChatText("Superior "+string(Inventory.GetItemXPForLevel(30133, 3, 2)));
		com.GameInterface.UtilsBase.PrintChatText("Epic "+string(Inventory.GetItemXPForLevel(30133, 4, 2)));
		com.GameInterface.UtilsBase.PrintChatText("Mythic "+string(Inventory.GetItemXPForLevel(30133, 5, 2)));
		com.GameInterface.UtilsBase.PrintChatText("Legendary " + string(Inventory.GetItemXPForLevel(30133, 6, 2)));
		*/
	}

	private function RefreshXP(result:Number, numItems:Number, feedback:String, items:Array, percentChance:Number) {
		Tooltip.Close();
		clearTimeout(refresh);
		warningClip.onRollOver = undefined;
		warningClip.onRollOut = undefined;
		m_remainingTalismanExp.text = "";
		m_remainingGlyphExp.text = "";
		m_remainingSignetExp.text = "";
		m_remainingTalismanExp.textColor = 0x6bb9ff;
		m_remainingGlyphExp.textColor = 0x6bb9ff;
		m_remainingSignetExp.textColor = 0x6bb9ff;
		var title:TextField = _root.itemupgrade.m_Window.m_Title;
		title.textColor = 0xFFFFFF;

		// This function can trigger like 20 times when something bugs out..hopefully nothing caused by this mod.
		// Using timeout to limit the function to only run once per 100ms
		refresh = setTimeout(Delegate.create(this, RefreshXPFunc), 100, items);
	}

	public function Load() {
		m_upgradewindow.SignalChanged.Connect(UpgradeWindowOpened, this);
		CraftingInterface.SignalCraftingResultFeedback.Connect(RefreshXP, this);
		setTimeout(Delegate.create(this, UpgradeWindowOpened), 50);
	}

	public function Unload() {
		Tooltip.Close();
		warningClip.onRollOver = undefined;
		warningClip.onRollOut = undefined;
		m_expContainer.removeMovieClip();
		m_upgradewindow.SignalChanged.Disconnect(UpgradeWindowOpened, this);
		CraftingInterface.SignalCraftingResultFeedback.Disconnect(RefreshXP, this);
	}

	// Checks if item is overcapped by at least a level
	private function CheckForWarning(clip:TextField,value,itemtype,rarity,amount) {
		var XpPerLevel = Inventory.GetItemXPForLevel(itemtype, rarity, 2);
		if (value == XpPerLevel*-1) {
			var title:TextField = _root.itemupgrade.m_Window.m_Title;
			title.text = "Warning(?)";
			title.textColor = 0xEC0006;
			clip.textColor=0xFF3E43
			warningClip.onRollOver = Delegate.create(this, function() {
				this.Tooltip.Close();
				var m_TooltipData:TooltipData = new TooltipData();
				m_TooltipData.m_Title = "<font size='16'><b>Warning</b></font>";
				m_TooltipData.m_Color = 0xFF040B;
				m_TooltipData.m_MaxWidth = 300;
				m_TooltipData.AddDescription("<font size='14'>At least levels worth of experience is getting wasted. There's a chance that the empowering fodder is worth more than "+string(amount)+" exp</font>");
				this.Tooltip = TooltipManager.GetInstance().ShowTooltip(undefined, TooltipInterface.e_OrientationVertical, -1, m_TooltipData);
			});
			warningClip.onRollOut = Delegate.create(this, function() {
				this.Tooltip.Close();
			});
		} else {
			clip.textColor = 0xFBFB00;
		}
	}

	private function RefreshXPFunc(items):Void {
		var m_ResultItem:InventoryItem = items[0];
		var m_StartItem:InventoryItem = InventoryItem(m_UpgradeInventory.GetItemAt(0));
		if (m_ResultItem) resultItemID = CreateID(m_ResultItem);
		else resultItemID = CreateID(m_StartItem);
		
		if (m_StartItem) {
			//checking if the item has glyph or signet slotted
			var GlyphSlotted = m_StartItem.m_ACGItem.m_TemplateID1;
			var SignetSlotted = m_StartItem.m_ACGItem.m_TemplateID2;
		//MAIN SLOT
			// If is NOT Glyph or Signet
			if (m_StartItem.m_RealType != 30129 && m_StartItem.m_RealType != 30133) {
				var MaxLevel:Number;
				//Hardcoded maxlevel, change if patched
				switch (m_StartItem.m_Rarity) {
					case 2:
						MaxLevel = 20;
						break
					case 3:
						MaxLevel = 25;
						break
					case 4:
						MaxLevel = 30;
						break
					case 5:
						MaxLevel = 35;
						break
					case 6:
						MaxLevel = 70;
						break
				}
				if (MaxLevel && m_StartItem.m_Rank != MaxLevel) {
					var XpToNextRarity = Inventory.GetItemXPForLevel(m_StartItem.m_RealType, m_StartItem.m_Rarity, MaxLevel);
					var needed = XpToNextRarity - m_StartItem.m_XP;
					var progress:Number;
					if (m_ResultItem) {
						progress = m_ResultItem.m_XP - m_StartItem.m_XP;
						needed -= progress;
					}
					m_remainingTalismanExp.text = Format.FormatNumeric(needed)  + " " +  LDBFormat.LDBGetText("Crafting", "XP");
					if (needed < 0) {
						CheckForWarning(m_remainingTalismanExp, needed, m_StartItem.m_RealType, m_StartItem.m_Rarity,progress);
					}
				}
			}
			// else if Glyph
			else if (m_StartItem.m_RealType == 30129 && m_StartItem.m_Rank != 20) {
				var XpToNextRarity = Inventory.GetItemXPForLevel(30129, m_StartItem.m_GlyphRarity, 20);
				var needed = XpToNextRarity - m_StartItem.m_GlyphXP;
				var progress:Number;
				if (m_ResultItem) {
					progress = m_ResultItem.m_XP - m_StartItem.m_XP;
					needed -= progress
				}
				m_remainingTalismanExp.text = Format.FormatNumeric(needed)  + " " +  LDBFormat.LDBGetText("Crafting", "XP");
				if (needed < 0) {
					CheckForWarning(m_remainingTalismanExp,needed,m_StartItem.m_RealType,m_StartItem.m_Rarity,progress);
				}
			}
			// else if Signet
			else if (m_StartItem.m_RealType == 30133 && m_StartItem.m_Rank!=20) {
				var XpToNextRarity = Inventory.GetItemXPForLevel(30133, m_StartItem.m_SignetRarity, 20);
				var needed = XpToNextRarity - m_StartItem.m_SignetXP;
				var progress:Number;
				if (m_ResultItem) {
					progress = m_ResultItem.m_SignetXP - m_StartItem.m_SignetXP;
					needed -= progress
				}
				m_remainingTalismanExp.text = Format.FormatNumeric(needed)  + " " +  LDBFormat.LDBGetText("Crafting", "XP");
				if (needed < 0) {
					CheckForWarning(m_remainingTalismanExp,needed,m_StartItem.m_RealType,m_StartItem.m_Rarity,progress)
				}
			}
		//MAIN SLOT END
		//GLYPH SLOT START
			//if current item
			//a) Has a glyph slotted
			//b) Is not a glyph or signet(Handled by MAIN)
			if (GlyphSlotted && m_StartItem.m_RealType != 30133 && m_StartItem.m_RealType != 30129 && m_StartItem.m_GlyphRank != 20) {
				var XpToNextRarity = Inventory.GetItemXPForLevel(30129, m_StartItem.m_GlyphRarity, 20);
				var needed = XpToNextRarity - m_StartItem.m_GlyphXP;
				var progress:Number;
				if (m_ResultItem) {
					progress = m_ResultItem.m_GlyphXP - m_StartItem.m_GlyphXP;
					needed -= progress;
				}
				m_remainingGlyphExp.text = Format.FormatNumeric(needed)  + " " +  LDBFormat.LDBGetText("Crafting", "XP");
				if (needed < 0) {
					CheckForWarning(m_remainingGlyphExp, needed, 30129, m_StartItem.m_GlyphRarity,progress);
				}
			}
		//GLYPH SLOT END
		//SIGNET SLOT START
			// Return if upgrade item is a weapon,as weapon signets should be ignored
			switch (m_StartItem.m_RealType) {
				case 30104:
				case 30106:
				case 30107:
				case 30118:
				case 30112:
				case 30110:
				case 30111:
				case 30100:
				case 30101:
					return;
			}
			//if current item
			//a) is not a signet or glyph(Handled by MAIN)
			//b) has a signet slotted
			if (SignetSlotted && m_StartItem.m_RealType != 30133 && m_StartItem.m_RealType != 30129 && m_StartItem.m_SignetRank!=20) {
				var XpToNextRarity = Inventory.GetItemXPForLevel(30133, m_StartItem.m_SignetRarity, 20);
				var needed = XpToNextRarity - m_StartItem.m_SignetXP;
				var progress:Number;
				if (m_ResultItem) {
					progress = m_ResultItem.m_SignetXP - m_StartItem.m_SignetXP;
					needed -= progress;
				}
				m_remainingSignetExp.text = Format.FormatNumeric(needed) + " " + LDBFormat.LDBGetText("Crafting", "XP");
				if (needed < 0) {
					CheckForWarning(m_remainingSignetExp, needed, 30133, m_StartItem.m_SignetRarity,progress);
				}
			}
		//SIGNET SLOT END
		}
	}

	private function createLabels() {
		//container
		var UpgradeContent:MovieClip = _root.itemupgrade.m_Window.m_Content;
		var format:TextFormat = UpgradeContent.m_GlyphUpgradeProgress.m_Text.getTextFormat();
		var x = UpgradeContent.m_GlyphLevelUpgrade._x;

		//talisman exp label
		m_remainingTalismanExp = UpgradeContent.createTextField(
			'm_RemainingTalismanExp', UpgradeContent.getNextHighestDepth(),
			x, UpgradeContent.m_UpgradeProgress._y + UpgradeContent.m_UpgradeProgress.m_Text._y,
			0, UpgradeContent.m_UpgradeProgress._height
		);
		m_remainingTalismanExp.selectable = false;
		m_remainingTalismanExp.autoSize = 'left';
		m_remainingTalismanExp.embedFonts = true;
		m_remainingTalismanExp.setTextFormat(format);
		m_remainingTalismanExp.setNewTextFormat(format);
		//Glyph exp label
		m_remainingGlyphExp = UpgradeContent.createTextField(
			'm_RemainingGlyphExp', UpgradeContent.getNextHighestDepth(),
			x, UpgradeContent.m_GlyphUpgradeProgress._y + UpgradeContent.m_GlyphUpgradeProgress.m_Text._y,
			0, UpgradeContent.m_GlyphUpgradeProgress._height
		);
		m_remainingGlyphExp.selectable = false;
		m_remainingGlyphExp.autoSize = 'left';
		m_remainingGlyphExp.embedFonts = true;
		m_remainingGlyphExp.setTextFormat(format);
		m_remainingGlyphExp.setNewTextFormat(format);
		//Signet exp label
		m_remainingSignetExp = UpgradeContent.createTextField(
			'm_RemainingSignetExp', UpgradeContent.getNextHighestDepth(),
			x, UpgradeContent.m_SignetUpgradeProgress._y + UpgradeContent.m_SignetUpgradeProgress.m_Text._y,
			0, UpgradeContent.m_SignetUpgradeProgress._height
		);
		m_remainingSignetExp.selectable = false;
		m_remainingSignetExp.autoSize = 'left';
		m_remainingSignetExp.embedFonts = true;
		m_remainingSignetExp.setTextFormat(format);
		m_remainingSignetExp.setNewTextFormat(format);
		//Tooltip, can't have hover info on textfields(?) so drawing box behind it
		warningClip = UpgradeContent.createEmptyMovieClip("Warning", UpgradeContent.getNextHighestDepth());
		warningClip.beginFill(0xFFFFFF, 0);
		warningClip.moveTo(0, 0);
		warningClip.lineTo(100, 0);
		warningClip.lineTo(100, 25);
		warningClip.lineTo(0, 25);
		warningClip.lineTo(0, 0);
		warningClip.endFill();
		warningClip._y -= 35; // Should probably draw this on the title clip.
	}

	private function CreateID(Item:InventoryItem){
		if(Item) return string(Item.m_ACGItem.m_TemplateID0) + Item.m_ACGItem.m_TemplateID1 + Item.m_ACGItem.m_TemplateID2 + Item.m_XP;
	}
	//gets position, iconbox, and item data from clicked inventory item
	private function GetGridPosition(srcInventory:ID32, srcSlot:Number) {
		if (srcInventory.GetType() == _global.Enums.InvType.e_Type_GC_BackpackContainer){
			var Data:Object = new Object();
			Data.Box = _root.backpack2.GetIconBoxContainingItemSlot(srcInventory, srcSlot);
			Data.Item = CreateID(Data.Box.GetItemData(srcSlot));
			var mc:MovieClip = Data.Box.GetMovieClipFromInventoryPosition(srcSlot)
			var box = Data.Box.GetPos();
			Data.Pos = new Point(mc._x + box.x + 5, mc._y + box.y + 7 + Data.Box["m_TopBarHeight"])
			Data.EndPos = m_UpgradeInventory.GetFirstFreeItemSlot();
			ItemPositions.push(Data);
		}
		//original function
		_root.itemupgrade.m_Window.m_Content["SlotReceiveItem"](srcInventory, srcSlot);
	}

	// sends item back to where it came from
	private function MouseClick(slot:ItemSlot, buttonIndex:Number) {
		var currentDragObject:DragObject = DragObject.GetCurrentDragObject();
		// move to inventory position
		if (buttonIndex == 2 && !currentDragObject && !_root.itemupgrade.m_Window.m_Content.m_FromEquipped[slot.GetSlotID()]){
			for (var i in ItemPositions){
				var Data = ItemPositions[i];
				// if previously deposited item or result item.
				if (Data["Item"] == CreateID(slot.GetData()) || (Data.EndPos == 0 && slot.GetSlotID() == 0 && CreateID(slot.GetData()) == resultItemID) ){
					_root.backpack2.MoveItem(m_UpgradeInventory.GetInventoryID(), slot.GetSlotID(), Data["Box"].m_BoxID, Data["Pos"].x, Data["Pos"].y);
					delete ItemPositions[i];
					break
				}
			}
		}
		// equip
		else if (buttonIndex == 2 && !currentDragObject && _root.itemupgrade.m_Window.m_Content.m_FromEquipped[slot.GetSlotID()]) {
			var pos = slot.GetData().m_DefaultPosition;
			//Equip
			if (!m_EquipmentInventory.GetItemAt(pos) || (pos == _global.Enums.ItemEquipLocation.e_Wear_First_WeaponSlot && !m_EquipmentInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Second_WeaponSlot))){
				m_UpgradeInventory.UseItem(slot.GetSlotID());
			}
			// Slot already taken
			else{
				m_Inventory.AddItem(m_UpgradeInventory.GetInventoryID(), slot.GetSlotID(), m_Inventory.GetFirstFreeItemSlot());
				
			}
			return;
		}
		//original function, in case previous function fails, or item is dragged
		if (slot.GetData()) _root.itemupgrade.m_Window.m_Content.SlotMouseUpItem(slot, buttonIndex);
	}

	//gets position, iconbox, and item data from dragged inventory item
	private function onDragEnd(event:Object){
		if ( Mouse["IsMouseOver"](_root.itemupgrade) ){
			if ( event.data.type == "item"){
				var dstID = _root.itemupgrade.m_Window.m_Content.GetMouseSlotID();
				if ( dstID >= 0 && dstID != _root.itemupgrade.m_Window.m_Content.RESULT_SLOT && !event.data.split){
					var Data:Object = new Object();
					Data.Box = _root.backpack2.GetIconBoxContainingItemSlot(event.data.inventory_id, event.data.inventory_slot);
					Data.Item = CreateID(Data.Box.GetItemData(event.data.inventory_slot));
					var mc:MovieClip = Data.Box.GetMovieClipFromInventoryPosition(event.data.inventory_slot)
					var box = Data.Box.GetPos();
					Data.EndPos = dstID;
					Data.Pos = new Point(mc._x + box.x+5, mc._y + box.y + 7 + Data.Box["m_TopBarHeight"])
					ItemPositions.push(Data);
				}
			}
		}
		//original function
		_root.itemupgrade.m_Window.m_Content.onDragEnd(event);
	}
	
	private function UnloadAll(){
		var slots:Array = _root.itemupgrade.m_Window.m_Content.m_ItemSlots
		for (var i = 0; i < slots.length; i++){
			if(slots[i].m_ItemSlot.GetData()) MouseClick(slots[i].m_ItemSlot,2);
		}
		_root.itemupgrade.m_Window.m_Content._onUnload();
		ItemPositions = new Array();
		resultItemID = undefined;
	}

	private function UpgradeWindowOpened() {
		Tooltip.Close();
		if (m_upgradewindow.GetValue()) {
			if (_root.itemupgrade.m_Window.m_Content.m_LevelUpgrade) {
				// Used to get grid position when item is right clicked or dragged to upgrade window
				com.Utils.GlobalSignal.SignalSendItemToUpgrade.Disconnect(_root.itemupgrade.m_Window.m_Content.SlotReceiveItem);
				com.Utils.GlobalSignal.SignalSendItemToUpgrade.Connect(GetGridPosition, this);
				DragManager.instance.addEventListener("dragEnd", this, "onDragEnd" );
				DragManager.instance.removeEventListener("dragEnd", _root.itemupgrade.m_Window.m_Content, "onDragEnd" );
				// window closed,move all items back
				if (!_root.itemupgrade.m_Window.m_Content._onUnload){
					_root.itemupgrade.m_Window.m_Content._onUnload = _root.itemupgrade.m_Window.m_Content.onUnload;
					_root.itemupgrade.m_Window.m_Content.onUnload = Delegate.create(this, UnloadAll);
				}
				//Used to send items back
				for (var i = 0; i < 8; i++){
					_root.itemupgrade.m_Window.m_Content.m_ItemSlots[i].m_ItemSlot.SignalMouseUp.Disconnect(_root.itemupgrade.m_Window.m_Content.SlotMouseUpItem);
					_root.itemupgrade.m_Window.m_Content.m_ItemSlots[i].m_ItemSlot.SignalMouseUp.Connect(MouseClick, this);
				}
				//Exp labels
				createLabels();
				//In case there were items in the crafting window
				RefreshXP();
			} else {
				setTimeout(Delegate.create(this, UpgradeWindowOpened), 50);
			}
		}else{
			DragManager.instance.removeEventListener("dragEnd", this, "onDragEnd" );
			com.Utils.GlobalSignal.SignalSendItemToUpgrade.Disconnect(GetGridPosition, this);
		}
	}

}