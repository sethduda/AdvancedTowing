# Advanced Towing

Adds support for towing vehicles using ropes. Works in both SP and MP. Supports Exile.

Also check out my Advanced Sling Loading addon for more rope features! 

**Features:**

- Tow other vehicles behind Ships, Cars, Trucks and Tanks 
- The size of the vehicle impacts it's towing capability 
- Other players (including AI) can tow other players 
- Supports towing damaged / destroyed vehicles 
- Supports towing "trains" of vehicles (disabled by default - see below) 

**Installation:**

1. Subscrive via steam: http://steamcommunity.com/sharedfiles/filedetails/?id=639837898 or dowload latest release from https://github.com/sethduda/AdvancedTowing/releases
2. If installing this on a server, add the addon to the -serverMod command line option
3. Optionally, this can be installed directly in the mission PBO by calling the advanced towing script via initServer.sqf. You'll find the sqf script (fn_advancedTowingInit.sqf) in the addons directory inside the downloaded addon.

**Default Towing Rules:**

- Tanks can tow tanks, cars, ships and air 
- Cars can tow cars, ships and air 
- Trucks can tow cars, ships and air 
- Ships can only tow ships 
- You can't tow locked vehicles (see settings below) 
- You can only tow one vehicle at a time (see settings below) 

**Notes for Mission Makers:**

You can enable "trains" of vehicles by defining the SA_MAX_TOWED_CARGO varible in your init.sqf file. By default, this is set to 1. When set, vehicles can tow up to the max number of specified vehicles. If you try to tow more, your vehicle won't be able to move. Note, however, mass of all vehicles will be taken into account. It's going to be slower to two vehicles vs one. 

```SA_MAX_TOWED_CARGO = 3; ```

You can customize which classes of objects can "deploy" tow ropes by overriding the SA_TOW_SUPPORTED_VEHICLES_OVERRIDE variable in an init.sqf file. 

```SA_TOW_SUPPORTED_VEHICLES_OVERRIDE = [ "Air", "Ship" ]; ```

This will only allow objects of class Air and Ship deploy tow ropes.

You can customize what can and can't be towed by defining the SA_TOW_RULES_OVERRIDE variable in the init.sqf file. 

```SA_TOW_RULES_OVERRIDE = 
[ ["Air", "CAN_TOW", "Ship"], 
["Air", "CAN_TOW", "Air"], 
["Ship", "CANT_TOW", "Air"], 
["Ship", "CAN_TOW", "Ship"] 
]; ```

In this example, all objects of class Air can tow Ships and Air. However, Ships can only tow ships. 

You can allow towing of locked vehicles by defining SA_TOW_LOCKED_VEHICLES_ENABLED in your init.sqf file. It defaults to false. 

```SA_TOW_LOCKED_VEHICLES_ENABLED = true; ```

You can allow towing in an Exile safe zone by defining SA_TOW_IN_EXILE_SAFEZONE_ENABLED in your init.sqf file. It default to false. 

```SA_TOW_IN_EXILE_SAFEZONE_ENABLED = true; ```

**Not working on your server?**

Make sure you have the mod listed in the -mod or -serverMod command line option. Only -serverMod is required for this addon. If still not working, check your server log to make sure the addon is found. 

**FAQ**

*This addon is only required on the server - is it going to slow down my server?*

No - while this addon is server-side only, it installs itself on all clients without them downloading the addon. Most of the time, the towing code actually runs client-side, even though you installed the addon only on the server. Magic! 

*Why is the vehicle I'm towing jumpy/laggy?*

If you're towing a vehicle that another player is driving, it's slower to transmit position updates for the towed vehicle. This will result in laggy looking towing. Have the player move to the passenger seat and then re-attach the tow ropes. 

Also, when using this in MP, all other players watching someone tow something will also notice the towed vehicle isn't moving as smoothly. This is also due to network delay. Usually this isn't too noticeable unless moving very fast. 

**Battleye kicks me when I try to do xyz. What do I do?**

You need to configure Battleye rules on your server. Below are the files you need to configure: 

setvariable.txt 

Add the following exclusions to the end of all lines starting with 4, 5, 6, or 7 if they contain "" (meaning applies to all values): 

!="SA_Cargo" !="SA_Tow_Ropes" !="SA_Tow_Ropes_Vehicle" !="SA_Tow_Ropes_Pick_Up_Helper" 

setvariableval.txt 

If you have any lines starting with 4, 5, 6, or 7 and they contain "" (meaning applies to all values) it's not going to work. Either remove the line or explicitly define the values you want to kick. Since the values of the variables above can vary, I don't know of a good way to define an exclusion rule. 

Also, it's possible there are other battleye filter files that can cause issues. If you check your battleye logs you can figure out which file is causing a problem.

**The tow actions appear when looking at a vehicle, but do nothing when I select them. How do I fix that?**

Most likely your server is setup with a white list for remote executions. In order to fix this, you need to modify your mission's description.ext file, adding the following CfgRemoteExec rules. If using InfiStar you should edit your cfgremoteexec.hpp instead of the description.ext file. See https://community.bistudio.com/wiki/Arma_3_Remote_Execution for more details on CfgRemoteExec.

```
class CfgRemoteExec
{
	class Functions
	{
		class SA_Simulate_Towing	{ allowedTargets=0; }; 
		class SA_Attach_Tow_Ropes	{ allowedTargets=0; }; 
		class SA_Take_Tow_Ropes		{ allowedTargets=0; }; 
		class SA_Put_Away_Tow_Ropes	{ allowedTargets=0; }; 
		class SA_Pickup_Tow_Ropes	{ allowedTargets=0; }; 
		class SA_Drop_Tow_Ropes		{ allowedTargets=0; }; 
		class SA_Set_Owner		{ allowedTargets=2; }; 
		class SA_Hint			{ allowedTargets=1; }; 
		class SA_Hide_Object_Global	{ allowedTargets=2; }; 
	};
};
```

**Issues & Feature Requests**

https://github.com/sethduda/AdvancedTowing/issues 

If anyone wants to help fix any of these, please let me know. You can fork the repo and create a pull request. 

**Special Thanks for Testing & Support:**

- Stay Alive Tactical Team (http://sa.clanservers.com) 
- BI forum community: diesel tech jc, TeTeT, belbo 
- Crimson Gaming for testing on exile (http://crimsongamingau.com)
- DirtySanchez & XLD (exilemod.com) for his great ideas & work to make this functional with Exile


---

The MIT License (MIT)

Copyright (c) 2016 Seth Duda

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
