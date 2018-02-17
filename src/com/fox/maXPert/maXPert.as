import com.GameInterface.DistributedValue;
import com.Utils.Format;
import mx.utils.Delegate;
import com.GameInterface.Game.Character;
import com.Utils.ID32;
import com.GameInterface.Inventory;
import com.GameInterface.InventoryItem;
import com.GameInterface.CraftingInterface;
import com.GameInterface.Tooltip.TooltipInterface;
import com.GameInterface.Tooltip.TooltipData;
import com.GameInterface.Tooltip.TooltipManager;

class com.fox.maXPert.maXPert {

	private var m_expContainer:MovieClip
	private var m_upgradewindow:DistributedValue
	private var m_remainingTalismanExp:TextField
	private var m_remainingGlyphExp:TextField
	private var m_remainingSignetExp:TextField
	private var m_UpgradeInventory:Inventory;
	private var refresh;
	private var m_swfroot:MovieClip;
	private var Tooltip:TooltipInterface;
	private var warningClip:MovieClip;

	public function maXPert(swfRoot: MovieClip) {
		m_swfroot = swfRoot;
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
		m_remainingSignetExp.textColor=0x6bb9ff;
		var title:TextField = _root.itemupgrade.m_Window.m_Title;
		title.textColor = 0xFFFFFF;
		
		//This function can trigger like..20 times when ..something bugs out
		// using timeout to limit the function to only run once per 100ms
		refresh = setTimeout(Delegate.create(this, RefreshXPFunc), 100,items);
	}

	public function Unload() {
		Tooltip.Close();
		warningClip.onRollOver = undefined;
		warningClip.onRollOut = undefined;
		m_expContainer.removeMovieClip();
		m_upgradewindow.SignalChanged.Disconnect(UpgradeWindowOpened, this);
		CraftingInterface.SignalCraftingResultFeedback.Disconnect(RefreshXP, this);
	}

	public function Load() {
		m_upgradewindow = DistributedValue.Create("ItemUpgradeWindow");
		m_upgradewindow.SignalChanged.Connect(UpgradeWindowOpened, this);
		setTimeout(Delegate.create(this, UpgradeWindowOpened), 50);
		m_UpgradeInventory = new Inventory(new ID32(_global.Enums.InvType.e_Type_GC_CraftingInventory, Character.GetClientCharID().GetInstance()));
		CraftingInterface.SignalCraftingResultFeedback.Connect(RefreshXP, this);
	}

	//checks if item is overcapped by at least a level
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
			clip.textColor=0xFBFB00
		}
	}

	private function RefreshXPFunc(items):Void {
		var m_ResultItem:InventoryItem = items[0];
		var m_StartItem:InventoryItem = InventoryItem(m_UpgradeInventory.GetItemAt(0))
		//checking if the item has glyph or signet slotted
		if (m_StartItem) {
			var GlyphSlotted = m_StartItem.m_ACGItem.m_TemplateID1 == 0 ? false : true;
			var SignetSlotted = m_StartItem.m_ACGItem.m_TemplateID2 == 0 ? false : true;
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
				if (MaxLevel && m_StartItem.m_Rank!=MaxLevel) {
					var XpToNextRarity = Inventory.GetItemXPForLevel(m_StartItem.m_RealType, m_StartItem.m_Rarity, MaxLevel);
					var needed = XpToNextRarity - m_StartItem.m_XP;
					var progress:Number;
					if (m_ResultItem) {
						progress = m_ResultItem.m_XP - m_StartItem.m_XP;
						needed -= progress;
					}
					m_remainingTalismanExp.text = Format.FormatNumeric(needed) + " Xp";
					if (needed < 0) {
						CheckForWarning(m_remainingTalismanExp, needed, m_StartItem.m_RealType, m_StartItem.m_Rarity,progress);
					}
				}
			}
			// else if Glyph
			else if (m_StartItem.m_RealType == 30129 && m_StartItem.m_Rank!=20) {
				var XpToNextRarity = Inventory.GetItemXPForLevel(30129, m_StartItem.m_GlyphRarity, 20);
				var needed = XpToNextRarity - m_StartItem.m_GlyphXP;
				var progress:Number;
				if (m_ResultItem) {
					progress = m_ResultItem.m_XP - m_StartItem.m_XP;
					needed -= progress
				}
				m_remainingTalismanExp.text = Format.FormatNumeric(needed) + " Xp";
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
				m_remainingTalismanExp.text = Format.FormatNumeric(needed) + " Xp";
				if (needed < 0) {
					CheckForWarning(m_remainingTalismanExp,needed,m_StartItem.m_RealType,m_StartItem.m_Rarity,progress)
				}
			}
		//MAIN SLOT END

		//GLYPH SLOT START
			//IF current item
			//a) Has a glyph slotted 
			//b) Is not a glyph or signet(Handled by MAIN)
			if (GlyphSlotted == true && m_StartItem.m_RealType != 30129 && m_StartItem.m_RealType != 30133) {
				if (m_StartItem.m_GlyphRank!=20) {
					var XpToNextRarity = Inventory.GetItemXPForLevel(30129, m_StartItem.m_GlyphRarity, 20);
					var needed = XpToNextRarity - m_StartItem.m_GlyphXP;
					m_remainingGlyphExp.text = Format.FormatNumeric(needed) + " Xp";
				}
				/* Broken for now
				if(m_StartItem.m_GlyphRank!=20){
					if(m_ResultItem && m_ResultItem.m_GlyphXP > m_StartItem.m_GlyphXP){
						var progress = m_ResultItem.m_GlyphXP - m_StartItem.m_GlyphXP;
						needed -= progress
						m_remainingGlyphExp.text = Format.FormatNumeric(needed) + " Xp";
					}
					else{
						m_remainingGlyphExp.text = Format.FormatNumeric(needed) + " Xp";
					}
					color(m_remainingGlyphExp, needed);
				}
				*/
			}
		//GLYPH SLOT END

		//SIGNET SLOT START
			// Return if upgrade item is a weapon,as weapon signets should be ignored
			var weapon:Boolean;
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
				m_remainingSignetExp.text = Format.FormatNumeric(needed) + " Xp";
				if (needed < 0) {
					CheckForWarning(m_remainingSignetExp, needed, 30133, m_StartItem.m_SignetRarity,progress);
				}
			}
		//SIGNET SLOT END
		}
	}

	private function createLabels() {
		//container
		var x = _root.itemupgrade.m_Window.m_Content;
		var format:TextFormat = x.m_LevelUpgrade.m_CurrentLevel.getTextFormat();
		var format2:TextFormat = x.m_LevelUpgrade.m_CurrentLevel.getTextFormat();
		format2.bold = true;
		m_expContainer = x.createEmptyMovieClip("maXPert", x.getNextHighestDepth());
		m_expContainer._y = 0;
		m_expContainer._x = x.m_LevelUpgrade._x;
		//talisman exp label
		m_remainingTalismanExp = m_expContainer.createTextField('m_remainingTalismanExp', m_expContainer.getNextHighestDepth(), 0,x.m_LevelUpgrade._y+41, 20, 20);
		m_remainingTalismanExp.selectable = false;
		m_remainingTalismanExp.autoSize = 'left';
		m_remainingTalismanExp.setTextFormat(format);
		m_remainingTalismanExp.setNewTextFormat(format);
		m_remainingTalismanExp.text  = '';
		//Glyph exp label
		m_remainingGlyphExp = m_expContainer.createTextField('m_remainingGlyphExp', m_expContainer.getNextHighestDepth(), 0,x.m_GlyphLevelUpgrade._y+41, 20, 20);
		m_remainingGlyphExp.selectable = false;
		m_remainingGlyphExp.autoSize = 'left';
		m_remainingGlyphExp.setTextFormat(format);
		m_remainingGlyphExp.setNewTextFormat(format);
		m_remainingGlyphExp.text  = '';
		//Signet exp label
		m_remainingSignetExp = m_expContainer.createTextField('m_remainingSignetExp', m_expContainer.getNextHighestDepth(), 0,x.m_SignetLevelUpgrade._y+41, 20, 20);
		m_remainingSignetExp.selectable = false;
		m_remainingSignetExp.autoSize = 'left';
		m_remainingSignetExp.setTextFormat(format);
		m_remainingSignetExp.setNewTextFormat(format);
		m_remainingSignetExp.text  = '';
		//Tooltip, can't have hover info on textfields(title) so drawing box behind it
		warningClip = x.createEmptyMovieClip("Warning", x.getNextHighestDepth());
		warningClip.beginFill(0xFFFFFF, 0);
		warningClip.moveTo(0, 0);
		warningClip.lineTo(100, 0);
		warningClip.lineTo(100, 25);
		warningClip.lineTo(0, 25);
		warningClip.lineTo(0, 0);
		warningClip.endFill();
		warningClip._y -= 35;
	}

	private function UpgradeWindowOpened() {
		Tooltip.Close();
		warningClip.onRollOver = undefined;
		warningClip.onRollOut = undefined;
		if (m_upgradewindow.GetValue()) {
			//need this to position my stuff
			if (_root.itemupgrade.m_Window.m_Content.m_LevelUpgrade) {
				createLabels();
				RefreshXP();
			} else {
				setTimeout(Delegate.create(this, UpgradeWindowOpened), 50);
			}
		}
	}

}