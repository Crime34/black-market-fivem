local ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(100)
    end
end)

local BlackMarketItems = {
    {
        id = 1,
        name = "lockpick",
        label = "Lockpick",
        price = 150,
        description = "Permet de crocheter les portes des véhicules",
        category = "tools",
        image = "lockpick.png"
    },
    {
        id = 2,
        name = "weapon_pistol",
        label = "Pistolet",
        price = 5000,
        description = "Arme de poing standard",
        category = "weapons",
        image = "pistol.png"
    },
    {
        id = 3,
        name = "weapon_combatpistol",
        label = "Pistolet de Combat",
        price = 7500,
        description = "Pistolet de combat amélioré",
        category = "weapons",
        image = "combat_pistol.png"
    },
    {
        id = 4,
        name = "clip",
        label = "Chargeur",
        price = 50,
        description = "Chargeur pour arme",
        category = "ammo",
        image = "clip.png"
    },
    {
        id = 5,
        name = "weapon_microsmg",
        label = "Micro SMG",
        price = 12000,
        description = "Mitraillette compacte",
        category = "weapons",
        image = "microsmg.png"
    },
    {
        id = 6,
        name = "drill",
        label = "Perceuse",
        price = 500,
        description = "Outil pour percer les coffres",
        category = "tools",
        image = "drill.png"
    },
    {
        id = 7,
        name = "hackerdevice",
        label = "Dispositif de Hack",
        price = 1000,
        description = "Pour hacker les systèmes électroniques",
        category = "tools",
        image = "hack.png"
    },
    {
        id = 8,
        name = "armor",
        label = "Gilet Pare-Balles",
        price = 800,
        description = "Protection corporelle",
        category = "protection",
        image = "armor.png"
    }
}

function GetItemByName(itemName)
    for _, item in pairs(BlackMarketItems) do
        if item.name == itemName then
            return item
        end
    end
    return nil
end

RegisterNetEvent('blackmarket:buyItem')
AddEventHandler('blackmarket:buyItem', function(itemName, quantity)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then
        print('[Black Market] Erreur: Joueur introuvable (ID: ' .. src .. ')')
        TriggerClientEvent('blackmarket:notification', src, '~r~Erreur: Joueur introuvable', 'error')
        return
    end
    
    local item = GetItemByName(itemName)
    
    if not item then
        print('[Black Market] Item introuvable: ' .. itemName)
        TriggerClientEvent('blackmarket:notification', src, '~r~Item introuvable!', 'error')
        return
    end
    
    local totalPrice = item.price * quantity
    
    local playerMoney = xPlayer.getMoney()
    
    print('[Black Market] Tentative d\'achat:')
    print('  - Joueur: ' .. xPlayer.getName() .. ' (ID: ' .. src .. ')')
    print('  - Item: ' .. item.label .. ' (' .. itemName .. ')')
    print('  - Quantité: ' .. quantity)
    print('  - Prix total: $' .. totalPrice)
    print('  - Argent du joueur: $' .. playerMoney)
    
    if playerMoney < totalPrice then
        print('[Black Market] Achat refusé: argent insuffisant')
        TriggerClientEvent('blackmarket:notification', src, '~r~Argent insuffisant! Il vous manque $' .. (totalPrice - playerMoney), 'error')
        return
    end
    
    xPlayer.removeMoney(totalPrice)
    print('[Black Market] Argent retiré: $' .. totalPrice)
    
    local success = false
    
    if string.find(string.lower(itemName), "weapon_") then
        local weaponName = string.upper(itemName)
        xPlayer.addWeapon(weaponName, 50)
        print('[Black Market] Arme donnée: ' .. weaponName .. ' avec 50 balles')
        TriggerClientEvent('blackmarket:notification', src, '~g~Achat réussi: ' .. item.label .. ' x1 (+50 balles)', 'success')
        success = true
    elseif itemName == "armor" then
        TriggerClientEvent('blackmarket:giveArmor', src, quantity)
        print('[Black Market] Armure donnée: x' .. quantity)
        TriggerClientEvent('blackmarket:notification', src, '~g~Achat réussi: ' .. item.label .. ' x' .. quantity, 'success')
        success = true
    else
        xPlayer.addInventoryItem(itemName, quantity)
        print('[Black Market] Item donné: ' .. itemName .. ' x' .. quantity)
        TriggerClientEvent('blackmarket:notification', src, '~g~Achat réussi: ' .. item.label .. ' x' .. quantity, 'success')
        success = true
    end
    
    if success then
        TriggerClientEvent('blackmarket:updateMoney', src, xPlayer.getMoney())
        print('[Black Market] ✓ Achat complété avec succès!')
        print('  - Nouvel argent: $' .. xPlayer.getMoney())
    else
        xPlayer.addMoney(totalPrice)
        print('[Black Market] Erreur lors du don de l\'item - Remboursement effectué')
        TriggerClientEvent('blackmarket:notification', src, '~r~Erreur lors de l\'achat. Vous avez été remboursé.', 'error')
    end
end)

RegisterNetEvent('blackmarket:requestItems')
AddEventHandler('blackmarket:requestItems', function()
    local src = source
    TriggerClientEvent('blackmarket:receiveItems', src, BlackMarketItems)
    print('[Black Market] Items envoyés au client (ID: ' .. src .. ')')
end)

RegisterNetEvent('blackmarket:giveArmor')
AddEventHandler('blackmarket:giveArmor', function()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('^2[Black Market] ^7Ressource démarrée avec succès!')
        print('^2[Black Market] ^7' .. #BlackMarketItems .. ' items disponibles')
        print('^3[Black Market] Items configurés:^7')
        for _, item in pairs(BlackMarketItems) do
            print('  - ' .. item.label .. ' ($' .. item.price .. ')')
        end
    end
end)

RegisterCommand('checkblackmarket', function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        print('[Black Market Debug] Inventaire de ' .. xPlayer.getName() .. ':')
        print('  - Argent: $' .. xPlayer.getMoney())
        
        for _, item in pairs(BlackMarketItems) do
            if not string.find(item.name, "weapon_") then
                local count = xPlayer.getInventoryItem(item.name)
                if count then
                    print('  - ' .. item.label .. ': ' .. (count.count or 0))
                end
            end
        end
    end
end, false)