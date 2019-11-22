local _ = function(k,...) return ImportPackage("i18n").t(GetPackageName(),k,...) end

CarDealerObjectsCached = { }
CarDealerTable = { 
	{
		location = { 128990, 80774, 1567, 180 },
		spawn = { 127720, 80774, 1567, 180 }
	}
}
CarPriceTable = { 
	{
		modelid = 1,
		name = "Sedan 1",
		price = 1000
	},
	{
		modelid = 4,
		name = "Sedan 2",
		price = 1000
	},
	{
		modelid = 5,
		name = "Sedan 3",
		price = 1000
	},
	{
		modelid = 6,
		name = "Nascar",
		price = 1000
	},
	{
		modelid = 7,
		name = "Truck",
		price = 1000
	},
	{
		modelid = 11,
		name = "Coupe",
		price = 1000
	},
	{
		modelid = 12,
		name = "Rally",
		price = 1000
	}
}

AddEvent("OnPackageStart", function()
	for k,v in pairs(CarDealerTable) do
		v.npc = CreateNPC(v.location[1], v.location[2], v.location[3], v.location[4])
		CreateText3D(_("car_dealer").."\n".._("press_e"), 18, v.location[1], v.location[2], v.location[3] + 120, 0, 0, 0)

		table.insert(CarDealerObjectsCached, v.npc)
	end
end)

AddEvent("OnPlayerJoin", function(player)
    CallRemoteEvent(player, "carDealerSetup", CarDealerObjectsCached)
end)

AddRemoteEvent("carDealerInteract", function(player, cardealerobject)
    local cardealer = GetCarDealearByObject(cardealerobject)
	if cardealer then
		local x, y, z = GetNPCLocation(cardealer.npc)
		local x2, y2, z2 = GetPlayerLocation(player)
        local dist = GetDistance3D(x, y, z, x2, y2, z2)

		if dist < 150 then
			CallRemoteEvent(player, "openCarDealer")
		end
	end
end)

function sendCarList(player)
        CallRemoteEvent(player, "getCarList", CarPriceTable)
end
AddRemoteEvent("sendCarList", sendCarList)

function GetCarDealearByObject(cardealerobject)
	for k,v in pairs(CarDealerTable) do
		if v.npc == cardealerobject then
			return v
		end
	end
	return nil
end

function CreateVehicleDatabase(player, vehicle, modelid, color)
    local query = mariadb_prepare(sql, "INSERT INTO player_garage (id, ownerid, modelid, color, garage) VALUES (NULL, '?', '?', '?', '0');",
        tostring(PlayerData[player].accountid),
        tostring(modelid),
        tostring(color)
    )

    mariadb_async_query(sql, query, onVehicleCreateDatabase, vehicle)
end

function onVehicleCreateDatabase(vehicle)
    VehicleData[vehicle].garageid = mariadb_get_insert_id()
end

function buyCarServer(player, modelid, color)
    local modelid = math.tointeger(modelid)
    local price = getVehiclePrice(modelid)
    local name = getVehicleName(modelid)
    local color = tostring(color)

	if tonumber(price) > PlayerData[player].cash then
        AddPlayerChat(player, _("no_money_car"))
    else
        local x, y, z = GetPlayerLocation(player)

        for k,v in pairs(CarDealerTable) do
            local x2, y2, z2 = GetNPCLocation(v.npc)
            local dist = GetDistance3D(x, y, z, x2, y2, z2)
            if dist < 150.0 then
                for k,w in pairs(GetAllVehicles()) do
                    local x3, y3, z3 = GetVehicleLocation(w)
                    local dist2 = GetDistance3D(v.spawn[1], v.spawn[2], v.spawn[3], x3, y3, z3)
                    if dist2 > 1000.0 then
                        -- if no vehicle on the spawn zone continue
                        local vehicle = CreateVehicle(modelid, v.spawn[1], v.spawn[2], v.spawn[3], v.spawn[4])
                        SetVehicleRespawnParams(vehicle, false)
                        SetVehicleColor(vehicle, "0x"..color)
                        SetVehiclePropertyValue(vehicle, "locked", true, true)
                        CreateVehicleData(player, vehicle, modelid)
                        CreateVehicleDatabase(player, vehicle, modelid, color)
                        PlayerData[player].cash = PlayerData[player].cash - tonumber(price)
                        CallRemoteEvent(player, "closeCarDealer")
                        return AddPlayerChat(player, _("car_buy_sucess", name, price, _("currency")))
                    else
                        -- if vehicle on the spawn zone cancel and report an error
                        return AddPlayerChat(player, _("cannot_spawn_vehicle"))
                    end
                end
                -- if no vehicle in the world spawn the car
                local vehicle = CreateVehicle(modelid, v.spawn[1], v.spawn[2], v.spawn[3], v.spawn[4])
                SetVehicleColor(vehicle, "0x"..color)
                SetVehicleRespawnParams(vehicle, false)
                SetVehiclePropertyValue(vehicle, "locked", true, true)
                CreateVehicleData(player, vehicle, modelid)
                CreateVehicleDatabase(player, vehicle, modelid, color)
                PlayerData[player].cash = PlayerData[player].cash - tonumber(price)
                CallRemoteEvent(player, "closeCarDealer")
                return AddPlayerChat(player, _("car_buy_sucess", name, price, _("currency")))
            end
        end
        
    end
end
AddRemoteEvent("buyCarServer", buyCarServer)
