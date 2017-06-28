local HoldTypeTranslate = {
	["missile launcher"] = "rpg",
	crowbar = "melee",
	pistol = "pistol",
	smg2 = "smg",
	slam = "slam",
	python = "revolver",
	bow = "crossbow",
	Grenade = "grenade",
	stunbaton = "melee",
	shotgun = "shotgun",
	gauss = "physgun",
	ar2 = "ar2"
}

local function GetHL2Weapons( )
	local tbl = {}
	for classname, info in pairs( list.Get( "Weapon" ) ) do
		local extendedInfo = file.Read( "scripts/" .. classname .. ".txt", "GAME" )
		if extendedInfo then
			local infoTable = util.KeyValuesToTable( extendedInfo )
			table.insert( tbl, {
				WorldModel = infoTable.playermodel,
				PrintName = language.GetPhrase( infoTable.printname ),
				ClassName = classname,
				HoldType = HoldTypeTranslate[infoTable.anim_prefix]
			})
		end
	end
	return tbl
end

local function GetScriptedWeapons( ) 
	-- Don't include weapon bases
	return LibK._.filter( weapons.GetList( ), function( weapon )
		return not string.find( weapon.ClassName, "base" )
	end )
end

function Pointshop2.GetWeaponsForPicker( )
	local weapons
	if engine.ActiveGamemode( ) == "terrortown" then
		weapons = GetScriptedWeapons( )
	else
		weapons = table.Add( GetHL2Weapons( ), GetScriptedWeapons( ) )
	end

	table.sort( weapons, function( a, b ) 
		local aName = a.PrintName or a.ClassName
		local bName = b.PrintName or b.ClassName
		if LANG then
			aName = LANG.TryTranslation( aName )
			bName = LANG.TryTranslation( bName )
		end

		return aName < bName
	end )

	return weapons
end

function Pointshop2.IsValidWeaponClass( weaponClass )
	for k, v in pairs( Pointshop2.GetWeaponsForPicker( ) ) do
		if v.ClassName == weaponClass then
			return true
		end
	end
	return false
end

function Pointshop2.GetWeaponWorldModel( weaponClass )
	for k, v in pairs( Pointshop2.GetWeaponsForPicker( ) ) do
		if v.ClassName == weaponClass then
			return v.WorldModel
		end
	end
	return "models/error.mdl"
end

local function checkSlotWeapons( )
	local message = "[CRITICAL][ADMIN ONLY] There is a misconfiguration with your Permawepon Slots. The following slots have invalid weapon classes:\n\n"
	local hasError = false
	local slots = Pointshop2.GetSetting( "PS2 Weapons", "WeaponSlots.Slots" )
	for slotName, info in pairs( slots ) do
		if info.replaces and not weapons.GetStored( info.replaces ) then
			message = message .. slotName .. " (" .. info.replaces .. "): Could not be found on the server.\n"
			hasError = true
		end
	end

	if LocalPlayer():IsAdmin() and hasError then
		Pointshop2View:getInstance():displayError( message, 1000 )
	end
end
hook.Add( "PS2_OnSettingsUpdate", "ErrorNotifierPerma", function( ) 
	timer.Simple(3, checkSlotWeapons)
end )