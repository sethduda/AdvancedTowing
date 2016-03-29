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
3. Note, for exile, you can also drop the PBO into the @ExileServer/addon folder instead of using the -serverMod command line option.


**Default Towing Rules:**

- Tanks can tow tanks, cars, ships and air 
- Cars can tow cars, ships and air 
- Trucks can tow cars, ships and air 
- Ships can only tow ships 

**Notes for Mission Makers:**

Note: The addon only needs to be installed on the server. It's optional for clients. 

You can enable "trains" of vehicles by defining the SA_MAX_TOWED_CARGO varible in your init.sqf file. By default, this is set to 1. When enabled, vehicles can tow up to the max number of specified vehicles. If you try to tow more, your vehicle won't be able to move. 

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

**Trying to run this on Exile?**

You can either install this like any other addon (using -serverMod command line option), or you can drop the pbo downloaded via steam into your @ExileServer/addon directory. Either approach will work. No changes needed to your mission file / description.ext / CfgRemoteExec. This addon has been built to use Exile's built in networking code. 

**Issues & Feature Requests**

https://github.com/sethduda/AdvancedTowing/issues 

If anyone wants to help fix any of these, please let me know. You can fork the repo and create a pull request. 

**Special Thanks for Testing:**

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
