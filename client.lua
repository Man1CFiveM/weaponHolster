local QBCore = exports['qb-core']:GetCoreObject()
local BONE_INDEX = 24818

local weaponOnBack = {}
local WeaponInInventory = {}

local function getTwoSmallestKeys(tbl)
    local min1, min2 = math.huge, math.huge
    for k in pairs(tbl) do
        if k < min1 then
            min2 = min1
            min1 = k
        elseif k < min2 then
            min2 = k
        end
    end
    return min1, min2
end

local function createAndAttachWeapon(weapon, ped, bone, slot)
    local model = Config.Weapons[weapon] or Config.DefaultWeapon
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
    local weaponBack = CreateObject(joaat(model), 1.0, 1.0, 1.0, true, true, false)
    if slot == 1 then
        AttachEntityToEntity(weaponBack, ped, bone, 0.1, -0.15, 0.05, 180.0, -335.0, 180.0, false, true, false, true, 0, true)
    else
        AttachEntityToEntity(weaponBack, ped, bone, 0.1, -0.17, 0.05, 0.0, 335.0, 180.0, false, true, false, true, 0, true)
    end
    SetEntityCompletelyDisableCollision(weaponBack, false, true)
    return weaponBack
end

local function updateWeaponInInventory()
    local player = QBCore.Functions.GetPlayerData()
    while player == nil do player = QBCore.Functions.GetPlayerData() Wait(500) end
    local currentInventory = {}
    for i, item in pairs(player.items) do
        if item.type == "weapon" then
            currentInventory[item.slot] = item.name
        end
    end
    for slot, weapon in pairs(WeaponInInventory) do
        if not currentInventory[slot] or currentInventory[slot] ~= weapon then
            WeaponInInventory[slot] = nil
        end
    end
    for slot, weapon in pairs(currentInventory) do
        if not WeaponInInventory[slot] then
            WeaponInInventory[slot] = weapon
        end
    end
end

local function BackLoop()
    CreateThread(function()
        local ped = PlayerPedId()
        local bone = GetPedBoneIndex(ped, BONE_INDEX)
        while true do
            updateWeaponInInventory()
            local first, second = getTwoSmallestKeys(WeaponInInventory)
            if first then
                if weaponOnBack[1] and weaponOnBack[1] ~= WeaponInInventory[first] then
                    DeleteEntity(weaponOnBack[1])
                    weaponOnBack[1] = nil
                end
                if not weaponOnBack[1] then
                    weaponOnBack[1] = createAndAttachWeapon(WeaponInInventory[first], ped, bone, 1)
                end
            end
            if second then
                if weaponOnBack[2] and weaponOnBack[2] ~= WeaponInInventory[second] then
                    DeleteEntity(weaponOnBack[2])
                    weaponOnBack[2] = nil
                end
                if not weaponOnBack[2] then
                    weaponOnBack[2] = createAndAttachWeapon(WeaponInInventory[second], ped, bone, 2)
                end
            end
            Wait(Config.CheckInventory)
        end
    end)
end

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    for _, weapon in ipairs(weaponOnBack) do
        DeleteEntity(weapon)
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(1000)
    BackLoop()
end)