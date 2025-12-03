local blackMarketOpen = false
local ESX = nil
local blackMarketPed = nil

local BlackMarketConfig = {
    coords = vector3(-563.953247, -1708.122559, 19.679714),
    heading = 59.594276,
    markerType = 27,
    markerColor = {r = 200, g = 0, b = 0, a = 100},
    markerSize = {x = 1.5, y = 1.5, z = 1.0},
    drawDistance = 10.0,
    interactDistance = 2.5,
    pedModel = "a_m_m_afriamer_01",
    pedCoords = vector4(-563.953247, -1708.122559, 19.679714, 59.594276)
}

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

Citizen.CreateThread(function()
    while not NetworkIsSessionStarted() do
        Wait(100)
    end
    
    RequestModel(GetHashKey(BlackMarketConfig.pedModel))
    while not HasModelLoaded(GetHashKey(BlackMarketConfig.pedModel)) do
        Wait(1)
    end

    blackMarketPed = CreatePed(4, GetHashKey(BlackMarketConfig.pedModel), 
        BlackMarketConfig.pedCoords.x, 
        BlackMarketConfig.pedCoords.y, 
        BlackMarketConfig.pedCoords.z - 1.0, 
        BlackMarketConfig.pedCoords.w, 
        false, true)
    
    SetEntityHeading(blackMarketPed, BlackMarketConfig.pedCoords.w)
    FreezeEntityPosition(blackMarketPed, true)
    SetEntityInvincible(blackMarketPed, true)
    SetBlockingOfNonTemporaryEvents(blackMarketPed, true)
    
    RequestAnimDict("amb@world_human_leaning@male@wall@back@legs_crossed@idle_a")
    while not HasAnimDictLoaded("amb@world_human_leaning@male@wall@back@legs_crossed@idle_a") do
        Wait(1)
    end
    TaskPlayAnim(blackMarketPed, "amb@world_human_leaning@male@wall@back@legs_crossed@idle_a", "idle_a", 8.0, 1.0, -1, 1, 0, false, false, false)
    
    print("[Black Market] PED spawné avec succès")
end)

function OpenBlackMarket()
    if not blackMarketOpen then
        blackMarketOpen = true
        SetNuiFocus(true, true)
        
        SendNUIMessage({
            action = "openMarket",
            money = ESX and ESX.GetPlayerData().money or 50000
        })
        
        print("[Black Market] Menu ouvert")
    end
end

function CloseBlackMarket()
    if blackMarketOpen then
        blackMarketOpen = false
        SetNuiFocus(false, false)
        
        SendNUIMessage({
            action = "closeMarket"
        })
        
        print("[Black Market] Menu fermé")
    end
end

RegisterNUICallback('close', function(data, cb)
    CloseBlackMarket()
    cb('ok')
end)

RegisterNUICallback('buyItem', function(data, cb)
    print('[Black Market Client] Achat demandé:', data.item, 'x', data.quantity)
    TriggerServerEvent('blackmarket:buyItem', data.item, data.quantity)
    cb('ok')
end)

RegisterNetEvent('blackmarket:forceClose')
AddEventHandler('blackmarket:forceClose', function()
    if blackMarketOpen then
        SetNuiFocus(false, false)
        blackMarketOpen = false
    end
end)

RegisterNetEvent('blackmarket:giveArmor')
AddEventHandler('blackmarket:giveArmor', function(quantity)
    local playerPed = PlayerPedId()
    for i = 1, quantity do
        SetPedArmour(playerPed, 100)
        print('[Black Market] Armure donnée au joueur')
    end
end)

RegisterNetEvent('blackmarket:updateMoney')
AddEventHandler('blackmarket:updateMoney', function(newMoney)
    print('[Black Market] Mise à jour argent: $' .. newMoney)
    SendNUIMessage({
        action = "updateMoney",
        money = newMoney
    })
end)

RegisterNetEvent('blackmarket:notification')
AddEventHandler('blackmarket:notification', function(msg, type)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(msg)
    DrawNotification(false, false)
    print('[Black Market] Notification: ' .. msg)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local distance = #(playerCoords - BlackMarketConfig.coords)

        if distance < BlackMarketConfig.drawDistance then
            DrawMarker(
                BlackMarketConfig.markerType,
                BlackMarketConfig.coords.x,
                BlackMarketConfig.coords.y,
                BlackMarketConfig.coords.z - 1.0,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                BlackMarketConfig.markerSize.x,
                BlackMarketConfig.markerSize.y,
                BlackMarketConfig.markerSize.z,
                BlackMarketConfig.markerColor.r,
                BlackMarketConfig.markerColor.g,
                BlackMarketConfig.markerColor.b,
                BlackMarketConfig.markerColor.a,
                false, true, 2, false, nil, nil, false
            )

            if distance < BlackMarketConfig.interactDistance then
                SetTextComponentFormat('STRING')
                AddTextComponentString('Appuyez sur ~INPUT_CONTEXT~ pour accéder au Black Market')
                DisplayHelpTextFromStringLabel(0, 0, 1, -1)

                if IsControlJustReleased(0, 38) then
                    OpenBlackMarket()
                end
            end
        else
            Citizen.Wait(500)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if blackMarketOpen then
            if IsControlJustReleased(0, 322) then
                CloseBlackMarket()
            end
        else
            Citizen.Wait(500)
        end
    end
end)

Citizen.CreateThread(function()
    Wait(1000)
    SendNUIMessage({
        action = "closeMarket"
    })
    SetNuiFocus(false, false)
end)