/**
 * changelog.txt
 *
 * eXileLoneDevs presents SethDuda's Advanced Towing for Exile
 * Originally by SethDuda, modified by Team XLD
 * www.DonkeyPunch.INFO -or- www.ExileMod.Com
 * © 2016 DirtySanchez / ka0s<3
 *
The MIT License (MIT)
Copyright (c) 2016 Seth Duda
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

1. Changed from an addon to an @ExileServer addons folder PBO
2. Cleaned up CfgRemoteExec code sethduda provided as exile compatible
3. Changed SA_Hint system for Exile Notifications
	-Made one Whoops and another Success
4. Added vehicle names to the new Notifications
5. Modified Cannot Tow from Hint to Exile Notification
6. Lock checks on both deploy and attach with appropriate Notifications
7. Added Exile_Item_Rope requirement for Deploy
8. Added Return Rope for Pack
9. SafeZones checks added to Deploy and Attach with appropriate Exile Notifications
10. Prevent Tow loop of vehicles, if vehicle is towing it cant be towed(can be reworked)
11. Started a max tow limit config and counter(WIP)
12. Added configurable Max Tow Limits and Exile Notification when Max has been reached
13. Currently Towing counter for attach and pack ropes
v0.8
14. Merged with Sethdudas newest update-fix for bridges and more
15. Added new configurable variables from seths update-fix

16. Reworked max tow limits in array for keeping ropes, much easier to track and remove
17. Added configurations for using Locked and SafeZone Notifications. Set to true/false

TODO: 

1. any new bugs / fixes / additions provided
 