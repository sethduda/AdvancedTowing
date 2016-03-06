class CfgPatches
{
	class SA_AdvancedTowing
	{
		units[] = {"SA_AdvancedTowing"};
		requiredVersion = 1.0;
		requiredAddons[] = {"A3_Modules_F"};
	};
};

/*
class CfgVehicles
{
	class Logic;
	class Module_F: Logic
	{
		class ArgumentsBaseUnits
		{
			class Anything;
		};
		class ModuleDescription
		{
			class Anything;
		};
	};
	class SA_AdvancedSlingLoadingModule: Module_F
	{
		// Standard object definitions
		scope = 2; // Editor visibility; 2 will show it in the menu, 1 will hide it.
		displayName = "Advanced Sling Loading"; // Name displayed in the menu
		category = "NO_CATEGORY";

		// Name of function triggered once conditions are met
		function = "SA_fnc_advancedSlingLoadingInit";
		// Execution priority, modules with lower number are executed first. 0 is used when the attribute is undefined
		functionPriority = 1;
		// 0 for server only execution, 1 for global execution, 2 for persistent global execution
		isGlobal = 0;
		// 1 for module waiting until all synced triggers are activated
		isTriggerActivated = 0;
		// 1 if modules is to be disabled once it's activated (i.e., repeated trigger activation won't work)
		isDisposable = 0;
		// // 1 to run init function in Eden Editor as well
		is3DEN = 0;

		// Menu displayed when the module is placed or double-clicked on by Zeus
		//curatorInfoType = "RscDisplayAttributeModuleNuke";

		// Module description. Must inherit from base class, otherwise pre-defined entities won't be available
		class ModuleDescription: ModuleDescription
		{
			description = "Enables advanced sling loading"; // Short description, will be formatted as structured text
			sync[] = {}; // Array of synced entities (can contain base classes)
		};
	};
};
*/

class CfgFunctions 
{
	class SA
	{
		class AdvancedSlingLoading
		{
			file = "\SA_AdvancedTowing\functions";
			class advancedTowingInit{postInit=1};
		};
	};
};