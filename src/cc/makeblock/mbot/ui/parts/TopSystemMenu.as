package cc.makeblock.mbot.ui.parts
{
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import cc.makeblock.mbot.uiwidgets.DynamicCompiler;
	import cc.makeblock.mbot.uiwidgets.errorreport.ErrorReportFrame;
	import cc.makeblock.mbot.uiwidgets.extensionMgr.ExtensionUtil;
	import cc.makeblock.media.MediaManager;
	import cc.makeblock.menu.MenuUtil;
	import cc.makeblock.menu.SystemMenu;
	import cc.makeblock.updater.AppUpdater;
	
	import extensions.ArduinoManager;
	import extensions.BluetoothManager;
	import extensions.ConnectionManager;
	import extensions.DeviceManager;
	import extensions.ExtensionManager;
	import extensions.HIDManager;
	import extensions.ScratchExtension;
	import extensions.SerialDevice;
	import extensions.SerialManager;
	import extensions.SocketManager;
	
	import org.aswing.AsWingUtils;
	
	import translation.Translator;
	
	import util.ApplicationManager;
	import util.SharedObjectManager;
	
	public class TopSystemMenu extends SystemMenu
	{
		public function TopSystemMenu(stage:Stage, path:String)
		{
			super(stage, path);
			
			getNativeMenu().getItemByName("File").submenu.addEventListener(Event.DISPLAYING, __onInitFielMenu);
			getNativeMenu().getItemByName("Edit").submenu.addEventListener(Event.DISPLAYING, __onInitEditMenu);
			getNativeMenu().getItemByName("Connect").submenu.addEventListener(Event.DISPLAYING, __onShowConnect);
			getNativeMenu().getItemByName("Boards").submenu.addEventListener(Event.DISPLAYING, __onShowBoards);
			getNativeMenu().getItemByName("Extensions").submenu.addEventListener(Event.DISPLAYING, __onInitExtMenu);
			getNativeMenu().getItemByName("Language").submenu.addEventListener(Event.DISPLAYING, __onShowLanguage);
			
			register("File", __onFile);
			register("Edit", __onEdit);
			register("Connect", __onConnect);
			register("Boards", __onSelectBoard);
			register("Help", __onHelp);
			register("Manage Extensions", ExtensionUtil.OnManagerExtension);
			register("Restore Extensions", ExtensionUtil.OnLoadExtension);
			register("Clear Cache", ArduinoManager.sharedManager().clearTempFiles);
			register("Reset Default Program", __onResetDefaultProgram);
			register("Microsoft Cognitive Service Setting", __onMicrosoftSettingSelect);
			register("Set FirmWare Mode", __onResetDefaultProgram);
		}
		
		private function __onResetDefaultProgram(item:NativeMenuItem):void
		{
			var ext:ScratchExtension;
			var filePath:String;
			switch(item.name){
				case "mymBot":
					filePath = "mBlock/tools/hex/mbot_reset.hex";
					break;
				case "Starter":
					filePath = "mBlock/tools/hex/starter_factory_firmware.hex";
					break;
				case "Starter Bluetooth":
					filePath = "mBlock/tools/hex/Starter_Bluetooth.hex";
					break;
				case "mBot Ranger":
					filePath = "mBlock/tools/hex/auriga.hex";
					break;
				case "Mega Pi":
					filePath = "mBlock/tools/hex/mega_pi.hex";
					break;
				case "bluetooth mode":
					ext = mBlockRT.app.extensionManager.extensionByName("Auriga");
					if(ext != null)
						ext.js.call("switchMode", [0], null);
					return;
				case "ultrasonic mode":
					ext = mBlockRT.app.extensionManager.extensionByName("Auriga");
					if(ext != null)
						ext.js.call("switchMode", [1], null);
					return;
				case "line follower mode":
					ext = mBlockRT.app.extensionManager.extensionByName("Auriga");
					if(ext != null)
						ext.js.call("switchMode", [4], null);
					return;
				case "balance mode":
					ext = mBlockRT.app.extensionManager.extensionByName("Auriga");
					if(ext != null)
						ext.js.call("switchMode", [2], null);
					return;
				default:
					mBlockRT.app.scriptsPart.appendMessage("Unknow board: " + item.name);
					return;
			}
			var file:File = ApplicationManager.sharedManager().documents.resolvePath(filePath);
			if(file.exists){
				SerialManager.sharedManager().upgrade(file.nativePath);
			}else{
				mBlockRT.app.scriptsPart.appendMessage("File not exist: " + file.nativePath);
			}
		}
		
		public function changeLang():void
		{
			MenuUtil.ForEach(getNativeMenu(), changeLangImpl);
		}
		
		private function changeLangImpl(item:NativeMenuItem):*
		{
			var index:int = getNativeMenu().getItemIndex(item);
			if(0 <= index && index < defaultMenuCount){
				return true;
			}
			if(item.name.indexOf("serial_") == 0){
				return;
			}
			var p:NativeMenuItem = MenuUtil.FindParentItem(item);
			if(p != null && p.name == "Extensions"){
				if(p.submenu.getItemIndex(item) > 4){
					return true;
				}
			}
			setItemLabel(item);
			if(item.name == "Boards"){
				setItemLabel(item.submenu.getItemByName("Others"));
				return true;
			}
			if(item.name == "Language"){
				item = MenuUtil.FindItem(item.submenu, "set font size");
				setItemLabel(item);
				return true;
			}
		}
		
		private function setItemLabel(item:NativeMenuItem):void
		{
			var newLabel:String = Translator.map(item.name);
			if(item.label != newLabel){
				item.label = newLabel;
			}
		}
		
		private function __onFile(item:NativeMenuItem):void
		{
			switch(item.name)
			{
				case "New":
					mBlockRT.app.createNewProject();
					break;
				case "Load Project":
					mBlockRT.app.runtime.selectProjectFile();
					break;
				case "Save Project":
					mBlockRT.app.saveFile();
					break;
				case "Save Project As":
					mBlockRT.app.exportProjectToFile();
					break;
				case "Undo Revert":
					mBlockRT.app.undoRevert();
					break;
				case "Revert":
					mBlockRT.app.revertToOriginalProject();
					break;
				case "Import Image":
					MediaManager.getInstance().importImage();
					break;
				case "Export Image":
					MediaManager.getInstance().exportImage();
					break;
			}
		}
		
		private function __onEdit(item:NativeMenuItem):void
		{
			switch(item.name){
				case "Undelete":
					mBlockRT.app.runtime.undelete();
					break;
				case "Hide stage layout":
					mBlockRT.app.toggleHideStage();
					break;
				case "Small stage layout":
					mBlockRT.app.toggleSmallStage();
					break;
				case "Turbo mode":
					mBlockRT.app.toggleTurboMode();
					break;
				case "Arduino mode":
					mBlockRT.app.changeToArduinoMode();
					break;
			}
//			mBlockRT.app.track("/OpenEdit");
		}
		
		private function __onConnect(menuItem:NativeMenuItem):void
		{
			var key:String;
			if(menuItem.data){
				key = menuItem.data.@action;
			}else{
				key = menuItem.name;
			}
			if("upgrade_custom_firmware" == key){
				var panel:DynamicCompiler = new DynamicCompiler();
				panel.show();
				AsWingUtils.centerLocate(panel);
			}else{
				ConnectionManager.sharedManager().onConnect(key);
			}
		}
		
		private function __onShowLanguage(evt:Event):void
		{
			var languageMenu:NativeMenu = evt.target as NativeMenu;
			if(languageMenu.numItems <= 2){
				for each (var entry:Array in Translator.languages) {
					var item:NativeMenuItem = languageMenu.addItemAt(new NativeMenuItem(entry[1]), languageMenu.numItems-2);
					item.name = entry[0];
					item.checked = Translator.currentLang==entry[0];
				}
				languageMenu.addEventListener(Event.SELECT, __onLanguageSelect);
			}else{
				for each(item in languageMenu.items){
					if(item.isSeparator){
						break;
					}
					MenuUtil.setChecked(item, Translator.currentLang==item.name);
				}
			}
			try{
				var fontItem:NativeMenuItem = languageMenu.items[languageMenu.numItems-1];
				for each(item in fontItem.submenu.items){
					MenuUtil.setChecked(item, Translator.currentFontSize==int(item.label));
				}
			}catch(e:Error){
				
			}
		}
		
		private function __onMicrosoftSettingSelect(item:NativeMenuItem):void
		{
			mBlockRT.app.openMicrosoftCognitiveSetting(Translator.map("Microsoft Cognitive Services"));
		}
		private function __onLanguageSelect(evt:Event):void
		{
			var item:NativeMenuItem = evt.target as NativeMenuItem;
			if(item.name == "setFontSize"){
				Translator.setFontSize(int(item.label));
			}else{
				Translator.setLanguage(item.name);
			}
		}
		
		private function __onInitFielMenu(evt:Event):void
		{
			var menu:NativeMenu = evt.target as NativeMenu;
			
			MenuUtil.setEnable(menu.getItemByName("Undo Revert"), mBlockRT.app.canUndoRevert());
			MenuUtil.setEnable(menu.getItemByName("Revert"), mBlockRT.app.canRevert());
			
//			mBlockRT.app.track("/OpenFile");
		}
		
		private function __onInitEditMenu(evt:Event):void
		{
			var menu:NativeMenu = evt.target as NativeMenu;
			MenuUtil.setEnable(menu.getItemByName("Undelete"), mBlockRT.app.runtime.canUndelete());
			MenuUtil.setChecked(menu.getItemByName("Hide stage layout"), mBlockRT.app.stageIsHided);
			MenuUtil.setChecked(menu.getItemByName("Small stage layout"), !mBlockRT.app.stageIsHided && mBlockRT.app.stageIsContracted);
			MenuUtil.setChecked(menu.getItemByName("Turbo mode"), mBlockRT.app.interp.turboMode);
			MenuUtil.setChecked(menu.getItemByName("Arduino mode"), mBlockRT.app.stageIsArduino);
//			mBlockRT.app.track("/OpenEdit");
		}
		
		private function __onShowConnect(evt:Event):void
		{
			SocketManager.sharedManager().probe();
			HIDManager.sharedManager();
			
			var menu:NativeMenu = evt.target as NativeMenu;
			var subMenu:NativeMenu = new NativeMenu();
			
			var enabled:Boolean = mBlockRT.app.extensionManager.checkExtensionEnabled();
			var arr:Array = SerialManager.sharedManager().list;
			if(arr.length==0)
			{
				var nullItem:NativeMenuItem = new NativeMenuItem(Translator.map("no serial port"));
				nullItem.enabled = false;
				nullItem.name = "serial_"+"null";
				subMenu.addItem(nullItem);
			}
			else
			{
				for(var i:int=0;i<arr.length;i++){
					var item:NativeMenuItem = subMenu.addItem(new NativeMenuItem(arr[i]));
					item.name = "serial_"+arr[i];
					
					item.enabled = enabled;
					item.checked = SerialDevice.sharedDevice().ports.indexOf(arr[i])>-1 && SerialManager.sharedManager().isConnected;
				}
			}
			
			menu.getItemByName("Serial Port").submenu = subMenu;
			
			var bluetoothItem:NativeMenuItem = menu.getItemByName("Bluetooth");
			
			bluetoothItem.enabled = ApplicationManager.sharedManager().system == ApplicationManager.WINDOWS && BluetoothManager.sharedManager().isSupported
			while(bluetoothItem.submenu.numItems > 3){
				bluetoothItem.submenu.removeItemAt(3);
			}
			if(bluetoothItem.submenu.numItems>2){
				bluetoothItem.submenu.items[0].enabled = enabled;
				bluetoothItem.submenu.items[1].enabled = enabled;
				bluetoothItem.submenu.items[2].enabled = enabled;
			}
			arr = BluetoothManager.sharedManager().history;
			for(i=0;i<arr.length;i++){
				item = bluetoothItem.submenu.addItem(new NativeMenuItem(Translator.map(arr[i])));
				item.name = "bt_"+arr[i];
				item.enabled = enabled;
				item.checked = arr[i]==BluetoothManager.sharedManager().currentBluetooth && BluetoothManager.sharedManager().isConnected;
			}
			
			var tempItem:NativeMenuItem = menu.getItemByName("2.4G Serial").submenu.getItemAt(0);
			tempItem.enabled = enabled;
			tempItem.checked = HIDManager.sharedManager().isConnected;
			
			var netWorkMenuItem:NativeMenuItem = MenuUtil.FindItem(getNativeMenu(), "Network");
			subMenu = netWorkMenuItem.submenu;
			arr = SocketManager.sharedManager().list;
			while(subMenu.numItems > 1){
				subMenu.removeItemAt(1);
			}
			for(i=0;i<arr.length;i++){
				var ips:Array = arr[i].split(":");
				if(ips.length<3){
					continue;
				}
				var label:String = Translator.map(ips[0]+" - "+ips[2]);
				item = subMenu.addItem(new NativeMenuItem(label));
				item.name = "net_" + arr[i];
				item.enabled = enabled;
				item.checked = SocketManager.sharedManager().connected(ips[0]);
			}
			netWorkMenuItem.submenu = subMenu;
			var defaultProgramMenu:NativeMenuItem = MenuUtil.FindItem(getNativeMenu(), "Reset Default Program");
			var canReset:Boolean = SerialManager.sharedManager().isConnected;
			defaultProgramMenu.enabled = canReset;
			var setModeItem:NativeMenuItem = menu.getItemByName("Set FirmWare Mode");
			setModeItem.enabled = false;
			canReset = SerialManager.sharedManager().isConnected && DeviceManager.sharedManager().currentName!="PicoBoard";
			MenuUtil.FindItem(getNativeMenu(), "Upgrade Firmware").enabled = canReset;
			canReset = DeviceManager.sharedManager().currentName!="PicoBoard";
			MenuUtil.FindItem(getNativeMenu(), "View Source").enabled = canReset;
			
			if(canReset){
				defaultProgramMenu.submenu.removeAllItems();
				switch(DeviceManager.sharedManager().currentName){
					case "mBot":
						defaultProgramMenu.submenu.addItem(new NativeMenuItem("mBot")).name = "mymBot";
						break;
					case "Me Auriga":
						defaultProgramMenu.submenu.addItem(new NativeMenuItem("mBot Ranger")).name = "mBot Ranger";
						
						setModeItem.submenu.removeAllItems();
						/*tempItem = defaultProgramMenu.submenu.addItem(new NativeMenuItem("", true));
						tempItem.name = "";
						tempItem = defaultProgramMenu.submenu.addItem(new NativeMenuItem(""));
						tempItem.name = "Set mBot Ranger Mode";
						tempItem.label = Translator.map(tempItem.name);*/
						//当前主板时Auriga且已连接
						setModeItem.enabled = defaultProgramMenu.enabled;
						for each(var modeName:String in rangerModeList){
							tempItem = setModeItem.submenu.addItem(new NativeMenuItem(""));
							tempItem.name = modeName;
							tempItem.label = Translator.map(modeName);
						}
						break;
					case "Me Orion":
						defaultProgramMenu.submenu.addItem(new NativeMenuItem("Starter")).name = "Starter";
						break;
					case "Mega Pi":
						defaultProgramMenu.submenu.addItem(new NativeMenuItem("Mega Pi")).name = "Mega Pi";
						break;
				}
			}
		}
		
		static private const rangerModeList:Array = ["bluetooth mode","ultrasonic mode","line follower mode","balance mode"];
		
		private function __onSelectBoard(menuItem:NativeMenuItem):void
		{
			DeviceManager.sharedManager().onSelectBoard(menuItem.name);
		}
		
		private function __onShowBoards(evt:Event):void
		{
			var menu:NativeMenu = evt.target as NativeMenu;
			for each(var item:NativeMenuItem in menu.items){
				if(item.enabled){
					MenuUtil.setChecked(item, DeviceManager.sharedManager().checkCurrentBoard(item.name));
				}
			}
		}
		
		private var initExtMenuItemCount:int = -1;
		
		private function __onInitExtMenu(evt:Event):void
		{
			var menuItem:NativeMenu = evt.target as NativeMenu;
//			menuItem.removeEventListener(evt.type, __onInitExtMenu);
//			menuItem.addEventListener(evt.type, __onShowExtMenu);
			var list:Array = mBlockRT.app.extensionManager.extensionList;
			if(list.length==0){
				mBlockRT.app.extensionManager.copyLocalFiles();
				SharedObjectManager.sharedManager().setObject("first-launch",false);
			}
			if(initExtMenuItemCount < 0){
				initExtMenuItemCount = menuItem.numItems;
			}
			while(menuItem.numItems > initExtMenuItemCount){
				menuItem.removeItemAt(menuItem.numItems-1);
			}
			list = mBlockRT.app.extensionManager.extensionList;
//			var subMenu:NativeMenu = menuItem;
			for(var i:int=0;i<list.length;i++){
				var extName:String = list[i].extensionName;
				if(!canShowExt(extName)){
					continue;
				}
				var subMenuItem:NativeMenuItem = menuItem.addItem(new NativeMenuItem(Translator.map(extName)));
				subMenuItem.name = extName;
				subMenuItem.label = ExtensionManager.isMakeBlockExt(extName) ? "Makeblock" : extName;
				subMenuItem.checked = mBlockRT.app.extensionManager.checkExtensionSelected(extName);
				register(extName, __onExtensions);
			}
		}
		
		static private function canShowExt(extName:String):Boolean
		{
			var board:String = DeviceManager.sharedManager().currentBoard;
			var result:Boolean = true;
			switch(extName)
			{
				case "Orion":
					result = board.indexOf("orion") >= 0;
					break;
				case "mBot":
					result = board.indexOf("mbot") >= 0;
					break;
				case "UNO Shield":
					result = board.indexOf("shield") >= 0;
					break;
				case "MegaPi":
					result = board.indexOf("mega_pi") >= 0;
					break;
				case "PicoBoard":
					result = board.indexOf("picoboard") >= 0;
					break;
				case "Auriga":
					result = board.indexOf("auriga") >= 0;
					break;
				case "Neuron":
					result = board.indexOf("Neuron")>=0;
					break;
			}
			return result;
		}
		/*
		private function __onShowExtMenu(evt:Event):void
		{
			var menuItem:NativeMenu = evt.target as NativeMenu;
			var list:Array = mBlockRT.app.extensionManager.extensionList;
			for(var i:int=0;i<list.length;i++){
				var extName:String = list[i].extensionName;
				var subMenuItem:NativeMenuItem = menuItem.getItemAt(i+2);
				subMenuItem.checked = mBlockRT.app.extensionManager.checkExtensionSelected(extName);
			}
		}
		*/
		private function __onExtensions(menuItem:NativeMenuItem):void
		{
			mBlockRT.app.extensionManager.onSelectExtension(menuItem.name);
		}
		
		private function __onHelp(menuItem:NativeMenuItem):void
		{
			var path:String = menuItem.data.@url;
//			if("Forum" == menuItem.name){
//				path = Translator.map(path);
//			}
			if(path){
				navigateToURL(new URLRequest(path),"_blank");
			}else{
				path = menuItem.data.@url_en;
				if(path){
					if(Translator.currentLang == "zh_CN" || Translator.currentLang == "zh_TW"){
						path = menuItem.data.@url_cn;
					}
					navigateToURL(new URLRequest(path),"_blank");
				}
			}
			
//			switch(menuItem.name)
//			{
//				case "Share Your Project":
//					mBlockRT.app.track("/OpenShare/");
//					break;
//				case "FAQ":
//					mBlockRT.app.track("/OpenFaq/");
//					break;
//				default:
//					mBlockRT.app.track("/OpenHelp/"+menuItem.data.@key);
//			}
			
			switch(menuItem.data.@key.toString()){
				case "check_app_update":
					AppUpdater.getInstance().start(true);
					break;
				case "upload_bug":
					ErrorReportFrame.OpenSendWindow("");
					break;
			}
		}
	}
}