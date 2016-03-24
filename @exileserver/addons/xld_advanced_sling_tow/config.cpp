class CfgPatches {
	class xld_advanced_sling_tow {
		units[] = {};
		weapons[] = {};
		requiredVersion = 0.1;
		requiredAddons[] = {"A3_Modules_F","exile_server_config"};
	};
};
class CfgFunctions {	
	class XLDAdvSlingTow {
		class main {
			file = "\x\addons\xld_advanced_sling_tow\functions";
			class advancedTowingInit {
				preInit = 1;
			};
		};
	};
};