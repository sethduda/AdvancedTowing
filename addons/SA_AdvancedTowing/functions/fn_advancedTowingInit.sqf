/*
The MIT License (MIT)

Copyright (c) 2016 Seth Duda

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#define SA_Find_Surface_ASL_Under_Position(_object,_positionAGL,_returnSurfaceASL,_canFloat) \
_objectASL = AGLToASL (_object modelToWorldVisual (getCenterOfMass _object)); \
_surfaceIntersectStartASL = [_positionAGL select 0, _positionAGL select 1, (_objectASL select 2) + 1]; \
_surfaceIntersectEndASL = [_positionAGL select 0, _positionAGL select 1, (_objectASL select 2) - 10]; \
_surfaces = lineIntersectsSurfaces [_surfaceIntersectStartASL, _surfaceIntersectEndASL, _object, objNull, true, 2]; \
_returnSurfaceASL = [_positionAGL select 0, _positionAGL select 1, 0]; \
if(count _surfaces > 0) then { \
	if!(((_surfaces select 0) select 2) isKindOf "RopeSegment") then { \
		_returnSurfaceASL = (_surfaces select 0) select 0; \
	} else { \
		if(count _surfaces > 1) then { \
			if!(((_surfaces select 1) select 2) isKindOf "RopeSegment") then { \
				_returnSurfaceASL = (_surfaces select 1) select 0; \
			}; \
		}; \
	}; \
	if(_canFloat && (_returnSurfaceASL select 2) < 0) then { \
		_returnSurfaceASL set [2,0]; \
	}; \
};

#define SA_Find_Surface_ASL_Under_Model(_object,_modelOffset,_returnSurfaceASL,_canFloat) \
SA_Find_Surface_ASL_Under_Position(_object, (_object modelToWorldVisual _modelOffset), _returnSurfaceASL,_canFloat);
			
#define SA_Find_Surface_AGL_Under_Model(_object,_modelOffset,_returnSurfaceAGL,_canFloat) \
SA_Find_Surface_ASL_Under_Model(_object,_modelOffset,_returnSurfaceAGL,_canFloat); \
_returnSurfaceAGL = ASLtoAGL _returnSurfaceAGL;

#define SA_Get_Cargo(_vehicle,_cargo) \
if( count (ropeAttachedObjects _vehicle) == 0 ) then { \
	_cargo = objNull; \
} else { \
	_cargo = ((ropeAttachedObjects _vehicle) select 0) getVariable ["SA_Cargo",objNull]; \
};
		
SA_Advanced_Towing_Install = {

// Prevent advanced towing from installing twice
if(!isNil "SA_TOW_INIT") exitWith {};
SA_TOW_INIT = true;

diag_log "Advanced Towing Loading...";

SA_Simulate_Towing_Speed = {
	
	params ["_vehicle"];
	
	private ["_runSimulation","_currentCargo","_maxVehicleSpeed","_maxTowedVehicles","_vehicleMass"];
	
	_maxVehicleSpeed = getNumber (configFile >> "CfgVehicles" >> typeOf _vehicle >> "maxSpeed");
	_vehicleMass = 1000 max (getMass _vehicle);
	_maxTowedCargo = missionNamespace getVariable ["SA_MAX_TOWED_CARGO",1];
	_runSimulation = true;
	
	private ["_currentVehicle","_totalCargoMass","_totalCargoCount","_findNextCargo","_towRopes","_ropeLength"];
	private ["_ends","_endsDistance","_currentMaxSpeed","_newMaxSpeed"];
	
	while {_runSimulation} do {
	
		// Calculate total mass and count of cargo being towed (only takes into account
		// cargo that's actively being towed (e.g. there's no slack in the rope)
		
		_currentVehicle = _vehicle;
		_totalCargoMass = 0;
		_totalCargoCount = 0;
		_findNextCargo = true;
		while {_findNextCargo} do {
			_findNextCargo = false;
			SA_Get_Cargo(_currentVehicle,_currentCargo);
			if(!isNull _currentCargo) then {
				_towRopes = _currentVehicle getVariable ["SA_Tow_Ropes",[]];
				if(count _towRopes > 0) then {
					_ropeLength = ropeLength (_towRopes select 0);
					_ends = ropeEndPosition (_towRopes select 0);
					_endsDistance = (_ends select 0) distance (_ends select 1);
					if( _endsDistance >= _ropeLength - 2 ) then {
						_totalCargoMass = _totalCargoMass + (1000 max (getMass _currentCargo));
						_totalCargoCount = _totalCargoCount + 1;
						_currentVehicle = _currentCargo;
						_findNextCargo = true;
					};
				};
			};
		};
	
		_newMaxSpeed = _maxVehicleSpeed / (1 max ((_totalCargoMass /  _vehicleMass) * 2));
		_newMaxSpeed = (_maxVehicleSpeed * 0.75) min _newMaxSpeed;
		
		// Prevent vehicle from moving if trying to move more cargo than pre-defined max
		if(_totalCargoCount > _maxTowedCargo) then {
			_newMaxSpeed = 0;
		};
		
		_currentMaxSpeed = _vehicle getVariable ["SA_Max_Tow_Speed",_maxVehicleSpeed];
		
		if(_currentMaxSpeed != _newMaxSpeed) then {
			_vehicle setVariable ["SA_Max_Tow_Speed",_newMaxSpeed];
		};
		
		sleep 0.1;
		
	};
};

SA_Simulate_Towing = {

	params ["_vehicle","_vehicleHitchModelPos","_cargo","_cargoHitchModelPos","_ropeLength"];

	private ["_lastCargoHitchPosition","_lastCargoVectorDir","_cargoLength","_maxDistanceToCargo","_lastMovedCargoPosition","_cargoHitchPoints"];
	private ["_vehicleHitchPosition","_cargoHitchPosition","_newCargoHitchPosition","_cargoVector","_movedCargoVector","_attachedObjects","_currentCargo"];
	private ["_newCargoDir","_lastCargoVectorDir","_newCargoPosition","_doExit","_cargoPosition","_vehiclePosition","_maxVehicleSpeed","_vehicleMass","_cargoMass","_cargoCanFloat"];	
	private ["_cargoCorner1AGL","_cargoCorner1ASL","_cargoCorner2AGL","_cargoCorner2ASL","_cargoCorner3AGL","_cargoCorner3ASL","_cargoCorner4AGL","_cargoCorner4ASL","_surfaceNormal1","_surfaceNormal2","_surfaceNormal"];
	
	_maxVehicleSpeed = getNumber (configFile >> "CfgVehicles" >> typeOf _vehicle >> "maxSpeed");
	_cargoCanFloat = if( getNumber (configFile >> "CfgVehicles" >> typeOf _cargo >> "canFloat") == 1 ) then { true } else { false };
	
	private ["_cargoCenterOfMassAGL","_cargoModelCenterGroundPosition"];
	SA_Find_Surface_AGL_Under_Model(_cargo,getCenterOfMass _cargo,_cargoCenterOfMassAGL,_cargoCanFloat);
	_cargoModelCenterGroundPosition = _cargo worldToModelVisual _cargoCenterOfMassAGL;
	_cargoModelCenterGroundPosition set [0,0];
	_cargoModelCenterGroundPosition set [1,0];
	
	// Calculate cargo model corner points
	private ["_cargoCornerPoints"];
	_cargoCornerPoints = [_vehicle] call SA_Get_Corner_Points;
	_corner1 = _cargoCornerPoints select 0;
	_corner2 = _cargoCornerPoints select 1;
	_corner3 = _cargoCornerPoints select 2;
	_corner4 = _cargoCornerPoints select 3;
	
	
	// Try to set cargo owner if the towing client doesn't own the cargo
	if(local _vehicle && !local _cargo) then {
		[[_cargo, clientOwner],"SA_Set_Owner"] call SA_RemoteExecServer;
	};
	
	_vehicleHitchModelPos set [2,0];
	_cargoHitchModelPos set [2,0];
	
	_lastCargoHitchPosition = _cargo modelToWorld _cargoHitchModelPos;
	_lastCargoVectorDir = vectorDir _cargo;
	_lastMovedCargoPosition = getPos _cargo;
	
	_cargoHitchPoints = [_cargo] call SA_Get_Hitch_Points;
	_cargoLength = (_cargoHitchPoints select 0) distance (_cargoHitchPoints select 1);
	
	_vehicleMass = 1 max (getMass _vehicle);
	_cargoMass = getMass _cargo;
	if(_cargoMass == 0) then {
		_cargoMass = _vehicleMass;
	};
	
	_maxDistanceToCargo = _ropeLength;

	_doExit = false;
	
	// Start vehicle speed simulation
	[_vehicle] spawn SA_Simulate_Towing_Speed;
	
	while {!_doExit} do {

		_vehicleHitchPosition = _vehicle modelToWorld _vehicleHitchModelPos;
		_vehicleHitchPosition set [2,0];
		_cargoHitchPosition = _lastCargoHitchPosition;
		_cargoHitchPosition set [2,0];
		
		_cargoPosition = getPos _cargo;
		_vehiclePosition = getPos _vehicle;
		
		if(_vehicleHitchPosition distance _cargoHitchPosition > _maxDistanceToCargo) then {
		
			// Calculated simulated towing position + direction
			_newCargoHitchPosition = _vehicleHitchPosition vectorAdd ((_vehicleHitchPosition vectorFromTo _cargoHitchPosition) vectorMultiply _ropeLength);
			_cargoVector = _lastCargoVectorDir vectorMultiply _cargoLength;
			_movedCargoVector = _newCargoHitchPosition vectorDiff _lastCargoHitchPosition;
			_newCargoDir = vectorNormalized (_cargoVector vectorAdd _movedCargoVector);
			//if(_isRearCargoHitch) then {
			//	_newCargoDir = _newCargoDir vectorMultiply -1;
			//};
			_lastCargoVectorDir = _newCargoDir;
			_newCargoPosition = _newCargoHitchPosition vectorAdd (_newCargoDir vectorMultiply -(vectorMagnitude (_cargoHitchModelPos)));
			
			SA_Find_Surface_ASL_Under_Position(_cargo,_newCargoPosition,_newCargoPosition,_cargoCanFloat);
			
			// Calculate surface normal (up) (more realistic than surfaceNormal function)
			SA_Find_Surface_ASL_Under_Model(_cargo,_corner1,_cargoCorner1ASL,_cargoCanFloat);
			SA_Find_Surface_ASL_Under_Model(_cargo,_corner2,_cargoCorner2ASL,_cargoCanFloat);
			SA_Find_Surface_ASL_Under_Model(_cargo,_corner3,_cargoCorner3ASL,_cargoCanFloat);
			SA_Find_Surface_ASL_Under_Model(_cargo,_corner4,_cargoCorner4ASL,_cargoCanFloat);
			_surfaceNormal1 = (_cargoCorner1ASL vectorFromTo _cargoCorner3ASL) vectorCrossProduct (_cargoCorner1ASL vectorFromTo _cargoCorner2ASL);
			_surfaceNormal2 = (_cargoCorner4ASL vectorFromTo _cargoCorner2ASL) vectorCrossProduct (_cargoCorner4ASL vectorFromTo _cargoCorner3ASL);
			_surfaceNormal = _surfaceNormal1 vectorAdd _surfaceNormal2;

			_newCargoPosition = _newCargoPosition vectorAdd ( _cargoModelCenterGroundPosition vectorMultiply -1 );

			_cargo setVectorDir _newCargoDir;
			_cargo setVectorUp _surfaceNormal;
			_cargo setPosWorld _newCargoPosition;

			_lastCargoHitchPosition = _newCargoHitchPosition;
			_maxDistanceToCargo = _vehicleHitchPosition distance _newCargoHitchPosition;
			_lastMovedCargoPosition = _cargoPosition;

			_massAdjustedMaxSpeed = _vehicle getVariable ["SA_Max_Tow_Speed",_maxVehicleSpeed];		
			if(speed _vehicle > (_massAdjustedMaxSpeed)+0.1) then {
				_vehicle setVelocity ((vectorNormalized (velocity _vehicle)) vectorMultiply (_massAdjustedMaxSpeed/3.6));
			};
			
		} else {
		
			if(_lastMovedCargoPosition distance _cargoPosition > 2) then {
				_lastCargoHitchPosition = _cargo modelToWorld _cargoHitchModelPos;
				_lastCargoVectorDir = vectorDir _cargo;
			};
			
		};
		
		// If vehicle isn't local to the client, switch client running towing simulation
		if(!local _vehicle) then {
			[_this,"SA_Simulate_Towing",_vehicle] call SA_RemoteExec;
			_doExit = true;
		};
		
		// If the vehicle isn't towing anything, stop the towing simulation
		SA_Get_Cargo(_vehicle,_currentCargo);
		if(isNull _currentCargo) then {
			_doExit = true;
		};
		
		sleep 0.01;
		
	};
};

SA_Get_Corner_Points = {
	params ["_vehicle"];
	private ["_centerOfMass","_bbr","_p1","_p2","_rearCorner","_rearCorner2","_frontCorner","_frontCorner2"];
	private ["_maxWidth","_widthOffset","_maxLength","_lengthOffset"];
	_centerOfMass = getCenterOfMass _vehicle;
	_bbr = boundingBoxReal _vehicle;
	_p1 = _bbr select 0;
	_p2 = _bbr select 1;
	_maxWidth = abs ((_p2 select 0) - (_p1 select 0));
	_widthOffset = ((_maxWidth / 2) - abs ( _centerOfMass select 0 )) * 0.75;
	_maxLength = abs ((_p2 select 1) - (_p1 select 1));
	_lengthOffset = ((_maxLength / 2) - abs (_centerOfMass select 1 )) * 0.75;
	_rearCorner = [(_centerOfMass select 0) + _widthOffset, (_centerOfMass select 1) - _lengthOffset, _centerOfMass select 2];
	_rearCorner2 = [(_centerOfMass select 0) - _widthOffset, (_centerOfMass select 1) - _lengthOffset, _centerOfMass select 2];
	_frontCorner = [(_centerOfMass select 0) + _widthOffset, (_centerOfMass select 1) + _lengthOffset, _centerOfMass select 2];
	_frontCorner2 = [(_centerOfMass select 0) - _widthOffset, (_centerOfMass select 1) + _lengthOffset, _centerOfMass select 2];
	[_rearCorner,_rearCorner2,_frontCorner,_frontCorner2];
};

SA_Get_Hitch_Points = {
	params ["_vehicle"];
	private ["_cornerPoints","_rearCorner","_rearCorner2","_frontCorner","_frontCorner2","_rearHitchPoint"];
	private ["_frontHitchPoint","_sideLeftPoint","_sideRightPoint"];
	_cornerPoints = [_vehicle] call SA_Get_Corner_Points;
	_rearCorner = _cornerPoints select 0;
	_rearCorner2 = _cornerPoints select 1;
	_frontCorner = _cornerPoints select 2;
	_frontCorner2 = _cornerPoints select 3;
	_rearHitchPoint = ((_rearCorner vectorDiff _rearCorner2) vectorMultiply 0.5) vectorAdd  _rearCorner2;
	_frontHitchPoint = ((_frontCorner vectorDiff _frontCorner2) vectorMultiply 0.5) vectorAdd  _frontCorner2;
	//_sideLeftPoint = ((_frontCorner vectorDiff _rearCorner) vectorMultiply 0.5) vectorAdd  _frontCorner;
	//_sideRightPoint = ((_frontCorner2 vectorDiff _rearCorner2) vectorMultiply 0.5) vectorAdd  _frontCorner2;
	[_frontHitchPoint,_rearHitchPoint];
};

SA_Attach_Tow_Ropes = {
	params ["_cargo","_player"];
	_vehicle = _player getVariable ["SA_Tow_Ropes_Vehicle", objNull];
	if(!isNull _vehicle) then {
		if(local _vehicle) then {
			private ["_towRopes","_vehicleHitch","_cargoHitch","_objDistance","_ropeLength"];
			_towRopes = _vehicle getVariable ["SA_Tow_Ropes",[]];
			if(count _towRopes == 1) then {
			
				/*
				private ["_cargoHitchPoints","_distanceToFrontHitch","_distanceToRearHitch","_isRearCargoHitch"];
				_cargoHitchPoints = [_cargo] call SA_Get_Hitch_Points;
				_distanceToFrontHitch = player distance (_cargo modelToWorld (_cargoHitchPoints select 0));
				_distanceToRearHitch = player distance (_cargo modelToWorld (_cargoHitchPoints select 1));
				if( _distanceToFrontHitch < _distanceToRearHitch ) then {
					_cargoHitch = _cargoHitchPoints select 0;
					_isRearCargoHitch = false;
				} else {
					_cargoHitch = _cargoHitchPoints select 1;
					_isRearCargoHitch = true;
				};
				*/
				
				_cargoHitch = ([_cargo] call SA_Get_Hitch_Points) select 0;
				
				_vehicleHitch = ([_vehicle] call SA_Get_Hitch_Points) select 1;
				_ropeLength = (ropeLength (_towRopes select 0));
				_objDistance = ((_vehicle modelToWorld _vehicleHitch) distance (_cargo modelToWorld _cargoHitch));
				if( _objDistance > _ropeLength ) then {
					[["The tow ropes are too short. Move vehicle closer.", false],"SA_Hint",_player] call SA_RemoteExec;
				} else {		
					[_vehicle,_player] call SA_Drop_Tow_Ropes;
					_helper = "Land_Can_V2_F" createVehicle position _cargo;
					_helper attachTo [_cargo, _cargoHitch];
					_helper setVariable ["SA_Cargo",_cargo,true];
					hideObject _helper;
					[[_helper],"SA_Hide_Object_Global"] call SA_RemoteExecServer;
					[_helper, [0,0,0], [0,0,-1]] ropeAttachTo (_towRopes select 0);
					[_vehicle,_vehicleHitch,_cargo,_cargoHitch,_ropeLength] spawn SA_Simulate_Towing;
				};
			};
		} else {
			[_this,"SA_Attach_Tow_Ropes",_vehicle,true] call SA_RemoteExec;
		};
	};
};

SA_Take_Tow_Ropes = {
	params ["_vehicle","_player"];
	if(local _vehicle) then {
		diag_log format ["Take Tow Ropes Called %1", _this];
		private ["_existingTowRopes","_hitchPoint","_rope"];
		_existingTowRopes = _vehicle getVariable ["SA_Tow_Ropes",[]];
		if(count _existingTowRopes == 0) then {
			_hitchPoint = [_vehicle] call SA_Get_Hitch_Points select 1;
			_rope = ropeCreate [_vehicle, _hitchPoint, 10];
			_vehicle setVariable ["SA_Tow_Ropes",[_rope],true];
			_this call SA_Pickup_Tow_Ropes;
		};
	} else {
		[_this,"SA_Take_Tow_Ropes",_vehicle,true] call SA_RemoteExec;
	};
};

SA_Put_Away_Tow_Ropes = {
	params ["_vehicle","_player"];
	if(local _vehicle) then {
		private ["_existingTowRopes","_hitchPoint","_rope"];
		_existingTowRopes = _vehicle getVariable ["SA_Tow_Ropes",[]];
		if(count _existingTowRopes > 0) then {
			_this call SA_Pickup_Tow_Ropes;
			_this call SA_Drop_Tow_Ropes;
			{
				ropeDestroy _x;
			} forEach _existingTowRopes;
			_vehicle setVariable ["SA_Tow_Ropes",nil,true];
		};
	} else {
		[_this,"SA_Put_Away_Tow_Ropes",_vehicle,true] call SA_RemoteExec;
	};
};

SA_Pickup_Tow_Ropes = {
	params ["_vehicle","_player"];
	if(local _vehicle) then {
		private ["_attachedObj","_helper"];
		{
			_attachedObj = _x;
			{
				_attachedObj ropeDetach _x;
			} forEach (_vehicle getVariable ["SA_Tow_Ropes",[]]);
		} forEach ropeAttachedObjects _vehicle;
		_helper = "Land_Can_V2_F" createVehicle position _player;
		{
			[_helper, [0, 0, 0], [0,0,-1]] ropeAttachTo _x;
			_helper attachTo [_player, [-0.1, 0.1, 0.15], "Pelvis"];
		} forEach (_vehicle getVariable ["SA_Tow_Ropes",[]]);
		hideObject _helper;
		[[_helper],"SA_Hide_Object_Global"] call SA_RemoteExecServer;
		_player setVariable ["SA_Tow_Ropes_Vehicle", _vehicle,true];
		_player setVariable ["SA_Tow_Ropes_Pick_Up_Helper", _helper,true];
	} else {
		[_this,"SA_Pickup_Tow_Ropes",_vehicle,true] call SA_RemoteExec;
	};
};

SA_Drop_Tow_Ropes = {
	params ["_vehicle","_player"];
	if(local _vehicle) then {
		private ["_helper"];
		_helper = (_player getVariable ["SA_Tow_Ropes_Pick_Up_Helper", objNull]);
		if(!isNull _helper) then {
			{
				_helper ropeDetach _x;
			} forEach (_vehicle getVariable ["SA_Tow_Ropes",[]]);
			detach _helper;
			deleteVehicle _helper;
		};
		_player setVariable ["SA_Tow_Ropes_Vehicle", nil,true];
		_player setVariable ["SA_Tow_Ropes_Pick_Up_Helper", nil,true];
	} else {
		[_this,"SA_Drop_Tow_Ropes",_vehicle,true] call SA_RemoteExec;
	};
};

SA_Attach_Tow_Ropes_Action = {
	private ["_vehicle","_towVehicle"];
	_vehicle = cursorTarget;
	_towVehicle = player getVariable ["SA_Tow_Ropes_Vehicle", objNull];
	if([_vehicle] call SA_Can_Attach_Tow_Ropes) then {
		[_vehicle,player] call SA_Attach_Tow_Ropes;
	} else {
		false;
	};
};

SA_Attach_Tow_Ropes_Action_Check = {
	private ["_vehicle","_towVehicle","_isCargoBeingTowed","_isCargoTowingCargo","_isChainingEnabled","_isTowVehicleBeingTowed","_isTowVehicleTowingCargo"];
	_vehicle = cursorTarget;
	[_vehicle] call SA_Can_Attach_Tow_Ropes;
};

SA_Can_Attach_Tow_Ropes = {
	params ["_cargo"];
	private ["_towVehicle","_canBeTowed"];
	_towVehicle = player getVariable ["SA_Tow_Ropes_Vehicle", objNull];
	if(!isNull _towVehicle && !isNull _cargo) then {
		_canBeTowed = [_towVehicle,_cargo] call SA_Is_Supported_Cargo && vehicle player == player && player distance _cargo < 10 && _towVehicle != _cargo;		
		if!(missionNamespace getVariable ["SA_TOW_LOCKED_VEHICLES_ENABLED",false]) then {
			_canBeTowed = _canBeTowed && locked _cargo <= 1;
		};
		if!(missionNamespace getVariable ["SA_TOW_IN_EXILE_SAFEZONE_ENABLED",false]) then {
			if(!isNil "ExilePlayerInSafezone") then {
				_canBeTowed = _canBeTowed && !ExilePlayerInSafezone;
			};
		};
		_canBeTowed;
	} else {
		false;
	};
};

SA_Attach_Tow_Ropes_Action_Disabled_Check = {
	private ["_vehicle","_towVehicle"];
	_vehicle = cursorTarget;
	_towVehicle = player getVariable ["SA_Tow_Ropes_Vehicle", objNull];
	if(!isNull _towVehicle && !isNull _vehicle) then {
		not([_towVehicle,_vehicle] call SA_Is_Supported_Cargo) && vehicle player == player && player distance _vehicle < 10 && _towVehicle != _vehicle;	
	} else {
		false;
	};
};

SA_Take_Tow_Ropes_Action_Check = {
	private ["_vehicle"];
	_vehicle = cursorTarget;
	if([_vehicle] call SA_Is_Supported_Vehicle) then {
		_existingTowRopes = _vehicle getVariable ["SA_Tow_Ropes",[]];
		_towVehicle = player getVariable ["SA_Tow_Ropes_Vehicle", objNull];
		vehicle player == player && player distance _vehicle < 10 && (count _existingTowRopes) == 0 && isNull _towVehicle;
	} else {
		false;
	};
};

SA_Put_Away_Tow_Ropes_Action_Check = {
	private ["_vehicle"];
	_vehicle = cursorTarget;
	if([_vehicle] call SA_Is_Supported_Vehicle) then {
		_existingTowRopes = _vehicle getVariable ["SA_Tow_Ropes",[]];
		vehicle player == player && player distance _vehicle < 10 && (count _existingTowRopes) > 0;
	} else {
		false;
	};
};

SA_Drop_Tow_Ropes_Action_Check = {
	!isNull (player getVariable ["SA_Tow_Ropes_Vehicle", objNull]) && vehicle player == player;
};

SA_Pickup_Tow_Ropes_Action_Check = {
	isNull (player getVariable ["SA_Tow_Ropes_Vehicle", objNull]) && count (missionNamespace getVariable ["SA_Nearby_Tow_Vehicles",[]]) > 0 && vehicle player == player;
};

SA_Pickup_Tow_Ropes_Action = {
	private ["_nearbyTowVehicles"];
	_nearbyTowVehicles = missionNamespace getVariable ["SA_Nearby_Tow_Vehicles",[]];
	if(count _nearbyTowVehicles > 0) then {
		[_nearbyTowVehicles select 0, player] call SA_Pickup_Tow_Ropes;
	};
};

SA_Drop_Tow_Ropes_Action = {
	private ["_vehicle"];
	_vehicle = player getVariable ["SA_Tow_Ropes_Vehicle", objNull];
	if(!isNull _vehicle) then {
		[_vehicle, player] call SA_Drop_Tow_Ropes;
	};
};

SA_TOW_SUPPORTED_VEHICLES = [
	"Tank", "Car", "Ship"
];

SA_Is_Supported_Vehicle = {
	params ["_vehicle","_isSupported"];
	_isSupported = false;
	if(not isNull _vehicle) then {
		{
			if(_vehicle isKindOf _x) then {
				_isSupported = true;
			};
		} forEach (missionNamespace getVariable ["SA_TOW_SUPPORTED_VEHICLES_OVERRIDE",SA_TOW_SUPPORTED_VEHICLES]);
	};
	_isSupported;
};

SA_TOW_RULES = [
	["Tank","CAN_TOW","Tank"],
	["Tank","CAN_TOW","Car"],
	["Tank","CAN_TOW","Ship"],
	["Tank","CAN_TOW","Air"],
	["Car","CAN_TOW","Car"],
	["Car","CAN_TOW","Ship"],
	["Car","CAN_TOW","Air"],
	["Ship","CAN_TOW","Ship"]
];

SA_Is_Supported_Cargo = {
	params ["_vehicle","_cargo"];
	private ["_canTow"];
	_canTow = false;
	if(not isNull _vehicle && not isNull _cargo) then {
		{
			if(_vehicle isKindOf (_x select 0)) then {
				if(_cargo isKindOf (_x select 2)) then {
					if( (toUpper (_x select 1)) == "CAN_TOW" ) then {
						_canTow = true;
					} else {
						_canTow = false;
					};
				};
			};
		} forEach (missionNamespace getVariable ["SA_TOW_RULES_OVERRIDE",SA_TOW_RULES]);
	};
	_canTow;
};

SA_Hint = {
    params ["_msg",["_isSuccess",true]];
    if(!isNil "ExileClient_gui_notification_event_addNotification") then {
		if(_isSuccess) then {
			["Success", [_msg]] call ExileClient_gui_notification_event_addNotification; 
		} else {
			["Whoops", [_msg]] call ExileClient_gui_notification_event_addNotification; 
		};
    } else {
        hint _msg;
    };
};

SA_Hide_Object_Global = {
	params ["_obj"];
	hideObjectGlobal _obj;
};

SA_Set_Owner = {
	params ["_obj","_client"];
	_obj setOwner _client;
};

SA_Take_Tow_Ropes_Action = {
	private ["_vehicle"];
	_vehicle = cursorTarget;
	if([_vehicle] call SA_Is_Supported_Vehicle) then {
		[_vehicle,player] call SA_Take_Tow_Ropes;
	};
};


SA_Put_Away_Tow_Ropes_Action = {
	private ["_vehicle"];
	_vehicle = cursorTarget;
	if([_vehicle] call SA_Is_Supported_Vehicle) then {
		[_vehicle,player] call SA_Put_Away_Tow_Ropes;
	};
};

SA_Add_Player_Tow_Actions = {
	
	player addAction ["Deploy Tow Ropes", { 
		[] call SA_Take_Tow_Ropes_Action;
	}, nil, 0, false, true, "", "call SA_Take_Tow_Ropes_Action_Check"];

	player addAction ["Put Away Tow Ropes", { 
		[] call SA_Put_Away_Tow_Ropes_Action;
	}, nil, 0, false, true, "", "call SA_Put_Away_Tow_Ropes_Action_Check"];

	player addAction ["Attach To Tow Ropes", { 
		[] call SA_Attach_Tow_Ropes_Action;
	}, nil, 0, false, true, "", "call SA_Attach_Tow_Ropes_Action_Check"];

	player addAction ["Cannot Attach Tow Ropes", { 
		["Your vehicle not strong enough. Find a larger vehicle!",false] call SA_Hint;
	}, nil, 0, false, true, "", "call SA_Attach_Tow_Ropes_Action_Disabled_Check"];

	player addAction ["Drop Tow Ropes", { 
		[] call SA_Drop_Tow_Ropes_Action;
	}, nil, 0, false, true, "", "call SA_Drop_Tow_Ropes_Action_Check"];

	player addAction ["Pickup Tow Ropes", { 
		[] call SA_Pickup_Tow_Ropes_Action;
	}, nil, 0, false, true, "", "call SA_Pickup_Tow_Ropes_Action_Check"];

	player addEventHandler ["Respawn", {
		player setVariable ["SA_Tow_Actions_Loaded",false];
	}];
	
};

SA_Find_Nearby_Tow_Vehicles = {
	private ["_nearVehicles","_nearVehiclesWithTowRopes","_vehicle","_ends","_end1","_end2"];
	_nearVehicles = [];
	{
		_nearVehicles append  (position player nearObjects [_x, 30]);
	} forEach (missionNamespace getVariable ["SA_TOW_SUPPORTED_VEHICLES_OVERRIDE",SA_TOW_SUPPORTED_VEHICLES]);
	_nearVehiclesWithTowRopes = [];
	{
		_vehicle = _x;
		{
			_ends = ropeEndPosition _x;
			if(count _ends == 2) then {
				_end1 = _ends select 0;
				_end2 = _ends select 1;
				if(((position player) distance _end1) < 5 || ((position player) distance _end2) < 5 ) then {
					_nearVehiclesWithTowRopes pushBack _vehicle;
				}
			};
		} forEach (_vehicle getVariable ["SA_Tow_Ropes",[]]);
	} forEach _nearVehicles;
	_nearVehiclesWithTowRopes;
};

if(!isDedicated) then {
	[] spawn {
		while {true} do {
			if(!isNull player && isPlayer player) then {
				if!( player getVariable ["SA_Tow_Actions_Loaded",false] ) then {
					[] call SA_Add_Player_Tow_Actions;
					player setVariable ["SA_Tow_Actions_Loaded",true];
				};
			};
			missionNamespace setVariable ["SA_Nearby_Tow_Vehicles", (call SA_Find_Nearby_Tow_Vehicles)];
			sleep 2;
		};
	};
};

SA_RemoteExec = {
	params ["_params","_functionName","_target",["_isCall",false]];
	if(!isNil "ExileClient_system_network_send") then {
		["AdvancedTowingRemoteExecClient",[_params,_functionName,_target,_isCall]] call ExileClient_system_network_send;
	} else {
		if(_isCall) then {
			_params remoteExecCall [_functionName, _target];
		} else {
			_params remoteExec [_functionName, _target];
		};
	};
};

SA_RemoteExecServer = {
	params ["_params","_functionName",["_isCall",false]];
	if(!isNil "ExileClient_system_network_send") then {
		["AdvancedTowingRemoteExecServer",[_params,_functionName,_isCall]] call ExileClient_system_network_send;
	} else {
		if(_isCall) then {
			_params remoteExecCall [_functionName, 2];
		} else {
			_params remoteExec [_functionName, 2];
		};
	};
};

if(isServer) then {
	
	// Adds support for exile network calls (Only used when running exile) //
	
	SA_SUPPORTED_REMOTEEXECSERVER_FUNCTIONS = ["SA_Set_Owner","SA_Hide_Object_Global"];
	
	ExileServer_AdvancedTowing_network_AdvancedTowingRemoteExecServer = {
		params ["_sessionId", "_messageParameters",["_isCall",false]];
		_messageParameters params ["_params","_functionName"];
		if(_functionName in SA_SUPPORTED_REMOTEEXECSERVER_FUNCTIONS) then {
			if(_isCall) then {
				_params call (missionNamespace getVariable [_functionName,{}]);
			} else {
				_params spawn (missionNamespace getVariable [_functionName,{}]);
			};
		};
	};
	
	SA_SUPPORTED_REMOTEEXECCLIENT_FUNCTIONS = ["SA_Simulate_Towing","SA_Attach_Tow_Ropes","SA_Take_Tow_Ropes","SA_Put_Away_Tow_Ropes","SA_Pickup_Tow_Ropes","SA_Drop_Tow_Ropes","SA_Hint"];
	
	ExileServer_AdvancedTowing_network_AdvancedTowingRemoteExecClient = {
		params ["_sessionId", "_messageParameters"];
		_messageParameters params ["_params","_functionName","_target",["_isCall",false]];
		if(_functionName in SA_SUPPORTED_REMOTEEXECCLIENT_FUNCTIONS) then {
			if(_isCall) then {
				_params remoteExecCall [_functionName, _target];
			} else {
				_params remoteExec [_functionName, _target];
			};
		};
	};

	// Install Advanced Towing on all clients (plus JIP) //
	
	publicVariable "SA_Advanced_Towing_Install";
	remoteExecCall ["SA_Advanced_Towing_Install", -2,true];
	
};

diag_log "Advanced Towing Loaded";

};

if(isServer) then {
	[] call SA_Advanced_Towing_Install;
};
