-- 10:45
local router = nil

repeat
    for i, v in next, getgc(true) do
        if type(v) == "table" and rawget(v, "get_remote_from_cache") then
            router = v
            break
        end
    end
    if not router then
        print("⏳ Router retrying...")
        task.wait(1)
    end
until router ~= nil

print("✅ Router found!")

local function rename(remotename, hashedremote)
    hashedremote.Name = remotename
end

table.foreach(debug.getupvalue(router.get_remote_from_cache, 1), rename)

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local petToEquip
--------------------------------------------------------------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentPacks = ReplicatedStorage.SharedModules.ContentPacks
local EquipRemote = ReplicatedStorage:WaitForChild("API"):WaitForChild("ToolAPI/Equip")
local startingMoney
local ClientData = require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData)
local ConvertedPetNameCache = {}
local ConvertedPetKindToNameCache = {}

local CheckBoxDialog = game:GetService("Players").LocalPlayer.PlayerGui.DialogApp.Dialog.CheckboxDialog
local playerGui = game:GetService("Players").LocalPlayer.PlayerGui
local ignore = {ButtonGUI = true, PetFarmGUI = true}

local ContentPacks = game:GetService("ReplicatedStorage").SharedModules.ContentPacks
local AddPetRemote = game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("IdleProgressionAPI/AddPet")
local RemovePetRemote = game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("IdleProgressionAPI/RemovePet")
local CommitRemote = game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("IdleProgressionAPI/CommitAllProgression")
local DoNeonFusion = game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("PetAPI/DoNeonFusion")
---------------------------------------------------------------------------------------------------------------------------
_G.PetTask = "none"
_G.FarmPause = false
_G.EventName = "eggs_2026"
_G.SessionMainPetUnique = nil
---------------------------------------------------------------------------------------------------------------------------

--debugger
local debugMode = true
local function dbg(msg)
   if debugMode then
        print(msg)
   end
end

-- auto play
local function autoPlay() 
    local NewsApp = game:GetService("Players").LocalPlayer.PlayerGui.NewsApp.Enabled
    local sound = require(game.ReplicatedStorage:WaitForChild("Fsys")).load("SoundPlayer")
    local UI = require(game.ReplicatedStorage:WaitForChild("Fsys")).load("UIManager")
    
    sound.FX:play("BambooButton")
    UI.set_app_visibility("NewsApp", false)
    task.wait(5)
    game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("DailyLoginAPI/ClaimDailyReward"):InvokeServer()
    sound.FX:play("BambooButton")
    UI.set_app_visibility("DailyLoginApp", false)
    UI.set_app_visibility("DialogApp", false)
end

local function antiAFK()
    local virtualUser = game:GetService("VirtualUser")

    Player.Idled:Connect(function()
        virtualUser:CaptureController()
        virtualUser:ClickButton2(Vector2.new())
    end)
end

local function respawn()
    game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("TeamAPI/Spawn"):InvokeServer()
end
   
local function disableTenMinutesCash()
    game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("PayAPI/Collect"):FireServer()
    game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("PayAPI/DisablePopups"):FireServer()
    
    local dialog = game:GetService("Players").LocalPlayer.PlayerGui.DialogApp.Dialog

    -- force it off initially
    dialog.Visible = false

    -- whenever it changes, force it back to false
    dialog:GetPropertyChangedSignal("Visible"):Connect(function()
        if dialog.Visible == true then
            dialog.Visible = false
        end
    end)
end

local function turnToBaby()
    game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("TeamAPI/ChooseTeam"):InvokeServer("Babies",{["dont_send_back_home"] = true, ["source_for_logging"] = "avatar_editor"})
end

local function taskwait(x)
    task.wait(x)
end
local function optimizer()
    local Lighting = game:GetService("Lighting")
    local Workspace = game:GetService("Workspace")

    Lighting.GlobalShadows = false
    Lighting.Brightness = 1
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0

    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("PostEffect")
        or v:IsA("Atmosphere")
        or v:IsA("Sky") then
            v:Destroy()
        end
    end

    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter")
        or v:IsA("Trail")
        or v:IsA("Smoke")
        or v:IsA("Fire")
        or v:IsA("Sparkles")
        or v:IsA("Beam") then
            v.Enabled = false

        elseif v:IsA("Decal") or v:IsA("Texture") then
            v:Destroy()

        elseif v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
            v.CastShadow = false
        end
    end
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter")
        or v:IsA("Trail")
        or v:IsA("Beam")
        or v:IsA("Explosion") then
            v:Destroy()
        end
    end
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Decal") or v:IsA("Texture") then
            v:Destroy()
        end
    end
    workspace.CurrentCamera.FieldOfView = 40

    -- remove all other player characters
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Player and player.Character then
            player.Character:Destroy()
        end
    end

    -- also remove them if they spawn later
    Players.PlayerAdded:Connect(function(player)
        if player == LocalPlayer then return end

        player.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            if char and char.Parent then
                char:Destroy()
            end
        end)
    end)

    -- keep only the current pet char inside workspace.Pets
    local petWrappers = ClientData.get("pet_char_wrappers")
    local myPetChar = petWrappers and petWrappers[1] and petWrappers[1].char

    if myPetChar and Workspace:FindFirstChild("Pets") then
        for _, pet in ipairs(Workspace.Pets:GetChildren()) do
            if pet ~= myPetChar then
                pet:Destroy()
            end
        end
    end
end
local function getCurrentMoney()
    return require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData).get_data()[game.Players.LocalPlayer.Name].money
end

local function ConvertPetKindToName(petname)
    if not petname or petname == "" then
        return petname
    end

    if ConvertedPetKindToNameCache[petname] then
        return ConvertedPetKindToNameCache[petname]
    end

    for _, pack in ipairs(ContentPacks:GetChildren()) do
        local inventorySubDB = pack:FindFirstChild("InventorySubDB")
        local petsModule = inventorySubDB and inventorySubDB:FindFirstChild("Pets")

        if pack:IsA("Folder") and petsModule then
            local petsTable = require(petsModule)

            for _, petInfo in pairs(petsTable) do
                for _, value in pairs(petInfo) do
                    if tostring(value) == petname then
                        ConvertedPetKindToNameCache[petname] = petInfo.name
                        return petInfo.name
                    end
                end
            end
        end
    end

    ConvertedPetKindToNameCache[petname] = petname
    return petname
end

local function ConvertPetName(petname)
    if not petname or petname == "" then
        return petname
    end

    if ConvertedPetNameCache[petname] then
        return ConvertedPetNameCache[petname]
    end

    for _, pack in ipairs(ContentPacks:GetChildren()) do
        local inventorySubDB = pack:FindFirstChild("InventorySubDB")
        local petsModule = inventorySubDB and inventorySubDB:FindFirstChild("Pets")

        if pack:IsA("Folder") and petsModule then
            local petsTable = require(petsModule)

            for _, petInfo in pairs(petsTable) do
                for _, value in pairs(petInfo) do
                    if tostring(value) == petname then
                        ConvertedPetNameCache[petname] = petInfo.kind
                        return petInfo.kind
                    end
                end
            end
        end
    end

    ConvertedPetNameCache[petname] = petname
    return petname
end

local function equipPet()
    if _G.SessionMainPetUnique then
        EquipRemote:InvokeServer(_G.SessionMainPetUnique, {
            use_sound_delay = true,
            equip_as_last = false
        })
    end
    local playerData = ClientData.get_data()[Player.Name]
    if not playerData or not playerData.inventory or not playerData.inventory.pets then
        warn("No pet inventory found")
        return
    end

    local inventoryPets = playerData.inventory.pets
    local prioritizePet = getgenv().HiraXRey.PrioritizePet
    local prioritizedKind = prioritizePet and ConvertPetName(prioritizePet) or nil

    local petToEquip = nil
    
    for _, pet in pairs(inventoryPets) do
        if pet.kind ~= "practice_dog" then
            petToEquip = pet.unique

            if pet.properties and pet.properties.age == 6 then
                break
            end
        end
    end
    if prioritizedKind then
        for _, pet in pairs(inventoryPets) do
            if pet.kind == prioritizedKind then
                petToEquip = pet.unique

                if pet.properties and pet.properties.age == 6 then
                    break
                end
            end
        end
    end

    if not petToEquip then
        warn("No pet found to equip")
        return
    end
    _G.SessionMainPetUnique = petToEquip
    EquipRemote:InvokeServer(petToEquip, {
        use_sound_delay = true,
        equip_as_last = false
    })
end

local furnitureList = {
    {
        minMoney = 0,
        kind = "basiccrib",
        furnitureName = "BasicCrib",
        cframe = CFrame.new(33.5, 0, -30) * CFrame.Angles(0, -1.57, 0),
        furnID = nil
    },
    {
        minMoney = 0,
        kind = "cheapbathtub",
        furnitureName = "CheapBathtub",
        cframe = CFrame.new(34.5, 0, -8.5) * CFrame.Angles(0, 1.57, 0),
        furnID = nil
    },
    {
        minMoney = 100,
        kind = "piano",
        furnitureName = "Piano",
        cframe = CFrame.new(7.5, 7.5, -5.5) * CFrame.Angles(-1.57, 0, 0),
        furnID = nil
    },
    {
        minMoney = 0,
        kind = "ailments_refresh_2024_cheap_water_bowl",
        furnitureName = "AilmentsRefresh2024CheapWaterBowl",
        cframe = CFrame.new(30.5, 0, -20) * CFrame.Angles(0, -1.57, 0),
        furnID = nil
    },
    {
        minMoney = 0,
        kind = "ailments_refresh_2024_cheap_food_bowl",
        furnitureName = "AilmentsRefresh2024CheapFoodBowl",
        cframe = CFrame.new(30.5, 0, -20) * CFrame.Angles(0, -1.57, 0),
        furnID = nil
    },
    {
        minMoney = 0,
        kind = "ailments_refresh_2024_litter_box",
        furnitureName = "AilmentsRefresh2024LitterBox",
        cframe = CFrame.new(30.5, 0, -20) * CFrame.Angles(0, -1.57, 0),
        furnID = nil
    },
    {
        minMoney = 0,
        kind = "lures_2023_normal_lure",
        furnitureName = "Lures2023NormalLure",
        cframe = CFrame.new(11, 0, -19.900390625) * CFrame.Angles(0, 0, 0),
        furnID = nil
    }
}

local function GetFurniture(furnitureKind)
    ClientData = require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData)
    local playerName = game.Players.LocalPlayer.Name
    local data = ClientData.get_data()[playerName].house_interior.furniture
    for x, y in pairs(data) do
        if y.id == furnitureKind then
            return x
        end
    end
    return nil
end

local function GetBuildingFurniture(furnitureName)
    local furnitureFolder = workspace.HouseInteriors.furniture

    if furnitureFolder then
        for _, child in pairs(furnitureFolder:GetChildren()) do
            if child:IsA("Folder") then
                for _, grandchild in pairs(child:GetChildren()) do
                    if grandchild:IsA("Model") then
                        if grandchild.Name == furnitureName then
                            local furnitureUniqueValue = grandchild:GetAttribute("furniture_unique")
                            --dbg("Grandchild Model:", grandchild.Name)
                            --dbg("furniture_unique:", furnitureUniqueValue)
                            return furnitureUniqueValue
                        end
                    end
                end
            end
        end
    end
end

local function buyFurnitures()
    -- assign value to furnID
    for _, item in ipairs(furnitureList) do
        item.furnID = GetFurniture(item.kind)
    end

    startingMoney = getCurrentMoney()

    for _, item in ipairs(furnitureList) do
        if not item.furnID and startingMoney > item.minMoney then
            game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("HousingAPI/BuyFurnitures"):InvokeServer({
                [1] = {
                    properties = {
                        cframe = item.cframe
                    },
                    kind = item.kind
                }
            })

            item.furnID = GetFurniture(item.kind)
            task.wait(1)
            startingMoney = getCurrentMoney()
        else
            dbg(item.kind .. " not bought")
        end
    end
end

---------------------------------------------------------------------------------------------------------------------------------------------
-- PETPET FUNCTIONS
local function buildPriorityKinds()
    local kinds = {}
    local rawPriority = getgenv().HiraXRey.PetPenPriority or {}

    for _, name in ipairs(rawPriority) do
        local kind = ConvertPetName(name)
        kinds[kind] = true
    end

    return kinds
end

local function shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

local function getData()
    return ClientData.get_data()[Player.Name]
end

local function getEquippedPetUnique(data)
    return data.equip_manager
        and data.equip_manager.pets
        and data.equip_manager.pets[1]
end

local function buildDesiredPets(data, priorityKinds)
    local inventoryPets = data.inventory.pets or {}
    local equippedUnique = getEquippedPetUnique(data)

    local priorityPets = {}
    local normalPets = {}
    local inventorySet = {}

    for unique, pet in pairs(inventoryPets) do
        inventorySet[unique] = pet

        local age = pet.properties and pet.properties.age or 0
        local isValid = age < 6 and unique ~= equippedUnique

        if isValid then
            if priorityKinds[pet.kind] then
                table.insert(priorityPets, unique)
            else
                table.insert(normalPets, unique)
            end
        end
    end

    shuffle(normalPets)

    local desired = {}
    local desiredSet = {}

    for _, unique in ipairs(priorityPets) do
        if #desired >= 4 then break end
        desiredSet[unique] = true
        table.insert(desired, unique)
    end

    for _, unique in ipairs(normalPets) do
        if #desired >= 4 then break end
        desiredSet[unique] = true
        table.insert(desired, unique)
    end

    return desired, desiredSet, inventorySet
end

local function removeInvalidPetsFromPen(data, desiredSet, inventorySet)
    local petPenPets = data.idle_progression_manager.active_pets

    for unique, penPet in pairs(petPenPets) do
        local invPet = inventorySet[unique]
        local age = invPet and invPet.properties and invPet.properties.age or 999
        local shouldRemove =
            not invPet
            or age >= 6
            or penPet.max_age
            or not desiredSet[unique]

        if shouldRemove then
            RemovePetRemote:FireServer(unique)
            task.wait(0.5)
        end
    end
end

local function addMissingPetsToPen(data, desired)
    local petPenPets = data.idle_progression_manager.active_pets
    local inPen = {}

    for unique in pairs(petPenPets) do
        inPen[unique] = true
    end

    local currentCount = 0
    for _ in pairs(inPen) do
        currentCount += 1
    end

    for _, unique in ipairs(desired) do
        if currentCount >= 4 then
            break
        end

        if not inPen[unique] then
            AddPetRemote:FireServer(unique)
            inPen[unique] = true
            currentCount += 1
            task.wait(0.5)
        end
    end
end
local function getPetPenCount(data)
    local petPenPets = data.idle_progression_manager.active_pets or {}
    local count = 0

    for _ in pairs(petPenPets) do
        count += 1
    end

    return count
end

---------------------------------------------------------------------------------------------------------------------------------------------
-- AutoFuse FUNCTIONS
local function getPets()
    return ClientData.get_data()[Player.Name].inventory.pets
end

local function findFusionBatch(wantNeon)
    local groupedPets = {}

    for _, pet in next, getPets() do
        local props = pet.properties

        if props and props.age == 6 and not props.mega_neon then
            local isNeon = props.neon == true

            if isNeon == wantNeon then
                local kind = pet.kind
                local list = groupedPets[kind]

                if not list then
                    list = {}
                    groupedPets[kind] = list
                end

                list[#list + 1] = pet.unique

                if #list >= 4 then
                    return kind, {list[1], list[2], list[3], list[4]}
                end
            end
        end
    end

    return nil, nil
end

local function runFusionPhase(wantNeon)
    local phaseName = wantNeon and "neon" or "normal"
    local resultName = wantNeon and "Mega Neon" or "Neon"

    while true do
        local fusionKind, fusionBatch = findFusionBatch(wantNeon)

        if not fusionBatch then
            dbg("Not enough same-kind full grown " .. phaseName .. " pets to fuse.")
            break
        end

        dbg("Fusing 4 " .. phaseName .. " pets:", fusionKind, table.concat(fusionBatch, ", "))

        local success, result = pcall(function()
            return DoNeonFusion:InvokeServer(fusionBatch)
        end)

        if success then
            dbg("Successfully fused 4 " .. fusionKind .. " into a " .. resultName .. "!")
        else
            dbg("Failed to fuse " .. fusionKind .. ":" .. result)
            break
        end

        task.wait(2)
    end

    dbg("Fuse " .. phaseName .. " phase complete")
end

---------------------------------------------------------------------------------------------------------------------------------------------
-- Frames FUNCTIONS
local function hideFrames(gui)
    for _, obj in pairs(gui:GetDescendants()) do
        if obj:IsA("Frame") then
            obj.Visible = false

            -- keep forcing it hidden
            obj:GetPropertyChangedSignal("Visible"):Connect(function()
                if obj.Visible then
                    obj.Visible = false
                end
            end)
        end
    end
end

autoPlay()
antiAFK()
disableTenMinutesCash()
optimizer()
respawn()
taskwait(5)
turnToBaby()
taskwait(5)
equipPet()
taskwait(2)
buyFurnitures()



local function getCandies()
    dbg("Getting candies")
    local ids = {"{46dca2e4-1ac9-4859-942b-f1c80b6d070b}", "{008581c8-0479-4fbe-9034-c2a42c7e5d25}", "{bfbfac00-a715-44a6-a32d-b02fb4fc71d7}", "{ae5b4d83-c5f6-48bd-9072-d6607145caf4}", "{dda99337-dec1-4e4c-b10c-4cab4e29f014}", "{65dff08c-c13a-4483-bc8e-b8246d2944f5}", "{b12eacc6-a77c-408d-bf3d-3fa6ec22b864}", "{b8af299f-f9e3-4c9b-8d9b-c90ab67e05ef}", "{d53bcd3e-e8c5-46d5-814d-c531af19b313}", "{e9466b21-fe37-40f0-ba35-66a9567396a8}", "{503633c5-07a4-4452-9923-7d959fcc84bb}", "{392f996d-3dde-47fe-84a5-0a8989d38a24}", "{6793647b-8deb-47c6-8341-985cae96da9c}", "{fb1162cc-45ff-4e33-bf12-59399c4053a4}", "{01d591d9-b992-42be-9414-baf55b410727}", "{ed56c5a7-6e5f-4923-9e33-386863295295}", "{722590bd-f2e4-40f9-9764-064e188da384}", "{13f51cec-d29b-4aff-90d0-f272f971c345}", "{414ac687-fb44-45ca-ac90-526f5ae22057}", "{39d7a4a8-76bf-4f68-9705-d92b6ab4fd70}", "{1a0f3a77-adb7-45b4-9168-e27643493e42}", "{0104d31d-2ccc-41e4-b415-4ed1dde10312}", "{94a2c2bd-d22f-4819-a058-faa3021bdaad}", "{3203fbe6-7723-4378-9bf6-5c8a24ab1be2}", "{14619336-a4d1-4bee-960c-69aa204626db}", "{6ea7b899-4b3b-4a1a-899e-27afddae023a}", "{50feac33-9eee-4588-afc3-97df922e3f00}", "{6de1b526-6b01-4ff9-811b-687b4c0b9b3e}", "{64085bd1-e20e-4998-86e8-f67a478939e9}", "{6f897409-0177-458c-b377-4569e997a13a}", "{3753c264-3548-4afa-b355-5722f90f6a69}", "{87d1777e-38f8-43d0-a564-c5c7f6e22203}", "{642e8389-1353-417a-ab9c-940876373917}", "{a00bb1d2-97c0-462b-a66c-c1049eb973a3}", "{16f59f0c-ed14-45cf-a6f9-51f9c051f7e0}", "{a734bf4b-be08-4038-a0c3-7eb3c6111fdb}", "{f34ed415-d405-4579-ab1f-8fbe53aa22f2}", "{9d205f01-ae45-4559-baac-4cb6c0c8993d}", "{bf5eb2a3-d2c8-4f6e-a7cb-7e724b12c5ae}", "{bd281fb7-d03f-4f28-9fd3-2d4eea36e743}", "{06407d28-82ad-442b-96bb-818f907493ff}", "{65e6b558-5220-435c-a805-513095676aa9}", "{0bc92778-87f1-4409-a54a-cf9178964b1f}", "{b9daf426-92c1-49b4-abca-c58ca5d9e0a9}", "{78710ec1-0493-4748-a610-83fee2716624}", "{a3c7f548-e41a-46b1-8d87-c5de3a566148}", "{e02061cb-cf98-4fe4-9802-145c98c0867b}", "{2babb231-7601-41bf-bbb4-f0edf5a1747d}", "{83e6fdda-ad9a-4528-9520-479b5852a361}", "{5d94b1f9-e1f8-447e-aacc-7433703547e9}", "{88b29049-39c6-455e-be1f-75530cf110aa}", "{d5bc0c47-1580-4fdd-9cf3-102f7843c39e}", "{ee4b4ef5-09b8-4bdd-805c-c1fd20f9bae0}", "{cb1c2f4a-34d0-4685-a6cf-01a4d20bfd2d}", "{2bf4ce11-5905-4c97-ab4f-298025e5b4e0}", "{cb955dfc-093d-4001-b5b0-ef6b175072a1}", "{18e0c4cc-3d06-4331-b73b-cae5ef2e6715}", "{25a67c29-8c07-4065-9a77-73c34f2f0a0e}", "{8dd0d543-1617-4bdf-a26a-53cd87610262}", "{30fb32a8-4d35-4093-875f-a62aa5e51417}", "{00449e7d-6dd4-4d3b-a884-924e79e7d545}", "{168b3ef7-1333-4dac-a725-c1e9b3f1b2f0}", "{f7a4b382-bf78-4be3-928b-dff5b4c2e72f}", "{c75165b8-a8b8-4759-831e-1ea6022688c7}", "{8d7ca87b-3661-4cc9-b205-089c357b17dc}", "{1282b867-96a8-4267-8582-2e91712478af}", "{4584035e-483d-4297-88ac-8c2e8661ec5d}", "{9a5b0a26-3b95-49b7-828d-3813b71c4e3e}", "{68f85bed-4a19-4d73-a7f8-951335ba9355}", "{4a056f1a-37d8-4d4f-94b7-b82b62336853}", "{bd307b69-7ce4-48df-a067-c80979c4dc94}", "{0fcc587a-22ed-4ae2-888d-97fefe2fb869}", "{a4a8791f-e993-44e2-87e4-0031fc210d18}", "{8215710d-9345-43c3-892e-bac765ea2d4b}", "{226038b9-cd4e-4746-a8f0-6087f75d08b5}", "{68d47ab1-dc88-4cf2-ac32-d172b5a084fa}", "{9525ebe4-fc85-4024-9ae4-5994fd6e7788}", "{2b42e6ef-7ce6-4e79-baa9-c6ddafd0aae7}", "{0fb7de61-82ba-47a5-bfbb-882751320ef0}", "{836ebd89-fb1e-4209-bbd9-8a72a33b7cdc}", "{993b0fb9-f6f2-4542-867a-e7ae76b0bc00}", "{ce58a7ce-11de-4dc8-a707-3547974c122c}", "{31ddd2ed-0d40-4282-9d1e-91171f623ef2}", "{471f1636-cb7d-41d4-96ca-2e14c1a2f183}", "{34d7d7ee-54e2-4d06-bb00-69fd5e39beb1}", "{ffbaad1b-d694-484a-8d21-338564b913f8}", "{f9463560-7550-40d5-9cee-b47f1e1d5ff6}", "{9b8a54ab-0ceb-4da5-a631-47453d887121}", "{eb2318a3-3e2f-42de-b3ab-7474ee12d9d9}", "{e650261b-64fc-4c08-a75a-3b2a4082d014}", "{6285ff12-7e0d-4ea3-bfac-b708f7365d54}", "{e838c521-7f7a-4307-b2a1-333a47485eaf}", "{e7f5681d-0b3a-42ff-9cf1-eaec59b64672}", "{08e4d9b6-cd7e-4005-91b1-cfde5cd50a14}", "{e0bb09bf-53b8-4e10-9dbd-e1958731cc7a}", "{92d40e4b-7b11-40e5-b2ae-4b3026e02817}", "{dd4e80a1-a8bc-43a6-a18d-07e0e9cdebb8}", "{dd025eb2-10b6-46d3-8468-994282cd29ab}", "{db50e49e-6354-4597-af0a-9b9b7e0cfbe8}", "{3d111c0e-23ea-441e-b2b1-3000b2d1abe8}", "{680e7b63-a67f-4cc0-be71-887b85ebfef6}", "{2c5411a9-693e-415d-b7e9-03cf06bf99b1}", "{dab729ce-1a78-44d8-b8e6-873ec5c49f4e}", "{d7c51b61-218b-4c1d-8e24-16b16dd38dba}", "{a2a0075b-47a9-4e0c-9a36-10e6608175d9}", "{74df0f87-4ccc-485c-8cba-d265b28cbac4}", "{0d988090-c906-4cb5-95d9-f0de8bba141e}", "{8e34db76-d4b2-4a40-9167-31d0d5470ee4}", "{ceb96285-96c9-4b0a-99d4-8d07bc9e6a1f}", "{943a378c-45ca-4beb-82c4-4bd9f19dfcad}", "{cddabde9-0758-40b9-bb11-6962a4722a57}", "{0411269e-69f3-4e27-8a05-b0299da87394}", "{cb24b90b-41ef-4062-8290-5c3daa9f0ebb}", "{b1c79cc8-86e4-43c8-a67b-221a4a8f3546}", "{6505337b-0020-466c-89a0-051118c7902b}", "{5f4c7e43-2c1a-4c12-8cf2-b34bceb7af70}", "{c5ad92df-018c-4c5a-ad06-deab43d0061c}", "{42307410-1e97-4ba2-9096-20dd1c51a63d}", "{bee31fae-6a2e-4c95-a673-36b275c75949}", "{2085eb60-8b89-456d-a7ab-70e54ccbf346}", "{84cc461f-f18c-486a-b52b-c02fd5d14951}", "{b9ce37d2-fd61-4fe2-b513-e0314fe79514}", "{45f636ca-5b3b-43b7-ba2b-fe68568b6c41}", "{436438e8-983d-47bd-92cf-035bbcbb1de5}", "{b8da90f7-bc29-4d4d-8d78-900a2e2c3e37}", "{c8093c22-2a65-46a5-bd5b-ce7e207a6e86}", "{4a221530-7fcf-480a-bc29-c210511b7ff2}", "{054f97cb-753c-4d8c-9281-930418b5f5ec}", "{0a62702e-2eb4-4628-b128-25bd9bc24f0e}", "{0c87b405-232b-48d7-b7b7-0c0636899a33}", "{5f692b00-a30a-4fce-8e5a-f6d3dd7e2916}", "{6b627e9b-ee52-456b-833e-4c59d522510e}", "{b5fe9857-95cf-4a77-aba2-c633d77698cf}", "{68a61a0d-ade1-48c9-9f94-0aa4ed75342b}", "{b350cb36-9362-4f0f-a211-64401bcfbf07}", "{b38f85d7-e7da-4ed1-979a-cc39ac61c5f5}", "{4796c501-7172-465d-acfe-07140c2cb8f6}", "{a84c8c62-f11c-4c1d-a297-1bed6d880054}", "{087cca29-ac27-403a-a9db-06fd353f0145}", "{1e0a75f5-a635-463d-8cec-2345e852b85c}", "{c874f7e6-c67c-4e40-a645-bbba707c34e1}", "{3ef891aa-e19e-4d17-842c-93af4177ca35}", "{d00b5a85-9d9c-413d-8da4-7134d96c9919}", "{a629e0da-32cb-46dd-8e33-e8c4238c539e}", "{29633ad0-9a26-49bf-84c1-4326bd105bff}", "{6dc84eed-c94b-4cca-af77-a83e15f8a3f2}", "{85dba3ea-fa05-4652-916c-02c2d5cf31de}", "{21840898-ee73-4bdf-8a94-5338f290d9e0}", "{2cadac03-4f42-43f6-b4b3-c3764848ef08}", "{203064f6-2485-483b-bfb7-ef35465465fe}", "{886df299-df87-4c08-b244-78af0c59c27e}", "{97b8ced9-a518-46b4-89ac-db4c7bf1ada2}", "{2b5ccdab-832d-40ba-ad3b-460452445b67}", "{026ade17-6e94-4c22-83d7-425d99ab7e66}", "{454c9f46-b453-4d56-8621-9bfdac448523}", "{95e065db-b9f1-4a29-9cc9-d8c6db795ef2}", "{00ffe177-bae9-4b56-a6cf-57a0bfa59f04}", "{30d06033-95f8-43a1-a311-dcde2dfd6a34}", "{c171242e-1662-43ef-a7a6-ef6ed4c16929}", "{8ab0c870-bc05-4b8a-9e85-2c60dc0b156d}", "{896d9f21-776f-4dee-b22c-11ecab9b6c9b}", "{8900eea5-fccc-4d0c-8b55-3cb4e2991261}", "{1dc10d7d-c04a-48f6-a823-54bca1f2be3d}", "{2b9bb081-9fd8-481c-b49a-2f93110083d6}", "{3f22d40a-4ee0-44da-8adf-1ea0fbbb340d}", "{721f5ad8-453b-4a32-a8f8-8a2bf5704db2}", "{6662d503-755c-40cc-89fd-6fa237616470}"}
    local args = {
        {
            interior_name = "MainMap",
            marshmallow_ids = ids
        }
    }

    game:GetService("ReplicatedStorage")
        :WaitForChild("adoptme_new_net")
        :WaitForChild("adoptme_legacy_shared.ContentPacks.Sugarfest2026.Game.CocoadileRiver.ChocolateRiverNet:6")
        :FireServer(unpack(args))

    task.wait(1)
    game:GetService("ReplicatedStorage"):WaitForChild("adoptme_new_net"):WaitForChild("adoptme_legacy_shared.ContentPacks.Sugarfest2026.Game.CocoadileRiver.ChocolateRiverNet:14"):FireServer()

    return true
end

local function HoldAndDrop()
    local success, err = pcall(function()
        local char = tostring(ClientData.get('pet_char_wrappers')[1].char)
        dbg('holding pet ' .. char)
        local args = {
            ClientData.get('pet_char_wrappers')[1].char  -- keep original Instance for FireServer
        }
        game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("AdoptAPI/HoldBaby"):FireServer(unpack(args))
        task.wait(1)
        dbg('dropping pet ' .. char)
        local args = {
            ClientData.get('pet_char_wrappers')[1].char  -- keep original Instance for FireServer
        }
        game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("AdoptAPI/EjectBaby"):FireServer(unpack(args))
    end)

    if not success then
        warn("HoldAndDrop error: " .. tostring(err) .. " | retrying in 1s...")
        task.wait(1)
        HoldAndDrop()
    end
end

local function HasAilment(ailments, targetKind)
    if typeof(ailments) ~= "table" then
        return false
    end
    for _, ailment in pairs(ailments) do
        if ailment.kind == targetKind then
            return true
        end
    end
    return false
end

local function HandlePetAilments(furnitureNumber, usage, petTask, specialFurnitureNumber)
    dbg("doing " .. petTask .. " Task")
    ClientData = require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData)
    local equippedPet =  ClientData.get_data()[game.Players.LocalPlayer.Name].equip_manager.pets[1].unique
    if specialFurnitureNumber then
        dbg("Running Special furniture")
        task.spawn(function()
            game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("HousingAPI/ActivateInteriorFurniture"):InvokeServer(specialFurnitureNumber, usage, {["cframe"] = CFrame.new(game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.Position)}, ClientData.get("pet_char_wrappers")[1]["char"])
        end)
    end
    
    if specialFurnitureNumber == nil and furnitureNumber ~= 0 then
        dbg("Running normal furniture")
        task.spawn(function()
            game:GetService("ReplicatedStorage").API["HousingAPI/ActivateFurniture"]:InvokeServer(game:GetService("Players").LocalPlayer,furnitureList[furnitureNumber].furnID,usage,{['cframe'] = CFrame.new(game:GetService("Players").LocalPlayer.Character.Head.Position + Vector3.new(0, .5, 0))},ClientData.get("pet_char_wrappers")[1]["char"])
        end)
    end

    local t = 0
    repeat
        task.wait(1)
        t = t + 1
        dbg(t)
    until not HasAilment(
        require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData)
            .get_data()[game.Players.LocalPlayer.Name]
            .ailments_manager.ailments[equippedPet],
        petTask
    ) or t > 60

    HoldAndDrop()
    -- local args = {
    --     [1] = ClientData.get("pet_char_wrappers")[1].pet_unique
    -- }
    
    -- game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("AdoptAPI/EjectBaby"):FireServer(unpack(args))
end

local actions = {
    "hungry", "thirsty", "sleepy", "toilet", "bored", "dirty",
    "play", "school", "salon", "pizza_party", "sick",
    "camping", "beachparty", "walk", "ride", "pet_me"
}

-- Function to buy an item
local function buyItem(itemType, itemName, buyCount)
    local args = {
        [1] = itemType,
        [2] = itemName,
        [3] = { ["buy_count"] = buyCount }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ShopAPI/BuyItem"):InvokeServer(unpack(args))
end

-- Function to use an item multiple times
local function useItem(itemID, useCount)
    for i = 1, useCount do
        local args = {
            [1] = itemID,
            [2] = "END"
        }
        game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ToolAPI/ServerUseTool"):FireServer(unpack(args))
        task.wait(0.5)
    end
end

-- Function to get the ID of a specific food item
local function getFoodID(itemName)
    ClientData = require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData)
    local ailmentsData = ClientData.get_data()[game.Players.LocalPlayer.Name].inventory.food
    for key, value in pairs(ailmentsData) do
        if value.id == itemName then
            return key
        end
    end
    return nil
end

local function teleportPlayerNeeds(x, y, z)

    if x == 0 and y == 350 and z == 0 then
        x = math.random(10, 20)
    end
    if Player and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        Player.Character.HumanoidRootPart.CFrame = CFrame.new(x, y, z) 
    else
        dbg("Player or character not found!")
    end
end

local function createPlatform(platformType)
    local character = Player.Character or Player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    local platformName = "GlobalPlatform"

    if platformType == "beach_party" then
        platformName = "BeachPlatform"
    elseif platformType == "camping" then
        platformName = "CampingPlatform"
    end

    -- Check all workspace children first
    for _, object in pairs(workspace:GetChildren()) do
        if object.Name == platformName then
            dbg("Already have " .. platformName)
            return
        end
    end

    -- Create only if not found
    local platform = Instance.new("Part")
    platform.Name = platformName
    platform.Size = Vector3.new(25000, 1, 25000)
    platform.Anchored = true
    platform.CFrame = humanoidRootPart.CFrame * CFrame.new(0, -5, 0)
    platform.BrickColor = BrickColor.new("Bright yellow")
    platform.Parent = workspace
    platform.Transparency = 1
    platform.CanCollide = true

    dbg(platformName .. " created")
end
teleportPlayerNeeds(0, 500, 0)
createPlatform()

ClientData = require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData)
local net = game:GetService("ReplicatedStorage"):WaitForChild("adoptme_new_net")

-- Wait a bit for all children to replicate
task.wait(2)

local function fireAllMatching(pattern, args)
    local fired = false
    for _, child in pairs(net:GetChildren()) do
        if string.find(child.Name, pattern, 1, true) then
            dbg("Firing:" .. child.Name .. "|" .. child.ClassName)
            pcall(function()
                if child.ClassName == "RemoteEvent" then
                    child:FireServer(unpack(args or {}))
                    fired = true
                elseif child.ClassName == "RemoteFunction" then
                    child:InvokeServer(unpack(args or {}))
                    fired = true
                end
            end)
        end
    end
    if not fired then
        dbg("⚠️ No match found for pattern:" .. pattern)
    end
end

local function doEventTasks()
    fireAllMatching("DailiesNetService", {"sugarfest"})
    fireAllMatching("BoardGameNetService", {})

    for x, y in pairs(ClientData.get_data()[Player.Name].inventory.gifts) do
        if y.kind == "sugarfest_2026_dice" then
            dbg("Using Sugarfest Dice")
            local equipArgs = {
                y.unique,
                {
                    use_sound_delay = true,
                    equip_as_last = false
                }
            }
            game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ToolAPI/Equip"):InvokeServer(unpack(equipArgs))

            fireAllMatching("BoardGameNetService", {{
                dice_item_unique = y.unique
            }})

            task.wait(1)
        end

        if y.kind == "sugarfest_2026_custom_dice" then
            dbg("Using Custom Dice")
            local equipArgs = {
                y.unique,
                {
                    use_sound_delay = true,
                    equip_as_last = false
                }
            }
            game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ToolAPI/Equip"):InvokeServer(unpack(equipArgs))

            fireAllMatching("BoardGameNetService", {{
                dice_item_unique = y.unique,
                supplied_distance = 6
            }})
        end
    end

    if getgenv().HiraXRey.AutoChisel then
        local EggsCandies = ClientData.get_data()[game.Players.LocalPlayer.Name].eggs_2026
        local maxChisel = math.floor(EggsCandies / 6500)
        local buyArgs = {
            "gifts",
            "sugarfest_2026_candy_chisel",
            {
                buy_count = maxChisel
            }
        }
        game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ShopAPI/BuyItem"):InvokeServer(unpack(buyArgs))
        for _, y in pairs(ClientData.get_data()[Player.Name].inventory.gifts) do

            if y.kind == "sugarfest_2026_candy_chisel" then
                local args = {
                    y.unique,
                    "START"
                }
                game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ToolAPI/ServerUseTool"):FireServer(unpack(args))
                for x = 1, 1000 do
                    local args = {
                        {
                            carve_amount = x
                        }
                    }
                    game:GetService("ReplicatedStorage"):WaitForChild("adoptme_new_net"):WaitForChild("CandyCliffCarve"):InvokeServer(unpack(args))
                    game:GetService("ReplicatedStorage"):WaitForChild("adoptme_new_net"):WaitForChild("CandyCliffConsumeChisel"):InvokeServer()
                end
                game:GetService("ReplicatedStorage"):WaitForChild("adoptme_new_net"):WaitForChild("CandyCliffConsumeChisel"):InvokeServer()
            end
        end

    end
end

local initialPetPenRun = true
if getgenv().HiraXRey.PetPen then
    dbg("PetPen started")
    task.spawn(function()
        while true do
            local data = getData()
            local petPenCount = getPetPenCount(data)

            if data.idle_progression_manager.age_up_pending or petPenCount < 4 or initialPetPenRun then
                initialPetPenRun = false
                CommitRemote:FireServer(true)
                task.wait(1)
                data = getData()

                local priorityKinds = buildPriorityKinds()
                local desired, desiredSet, inventorySet = buildDesiredPets(data, priorityKinds)

                removeInvalidPetsFromPen(data, desiredSet, inventorySet)

                task.wait(1)
                data = getData()

                addMissingPetsToPen(data, desired)
                
                if getgenv().HiraXRey.AutoFuse then
                    runFusionPhase(false) -- normal -> neon
                    runFusionPhase(true)  -- neon -> mega
                end
            end
            
            task.wait(60)
        end
    end)
end
if getgenv().HiraXRey.RemoveAllUI then
    -- existing GUIs
    for _, gui in pairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and not ignore[gui.Name] then
            hideFrames(gui)
        end
    end

    -- future GUIs
    playerGui.ChildAdded:Connect(function(gui)
        if gui:IsA("ScreenGui") and not ignore[gui.Name] then
            hideFrames(gui)
        end
    end)
end

task.spawn(function()
    while getgenv().HiraXRey.PetFarm do
        if not _G.FarmPause then
            dbg('loop again')
            _G.PetTask = "None"
            if ClientData.get_data()[game.Players.LocalPlayer.Name].equip_manager.pets[1].unique ~= _G.SessionMainPetUnique then
                equipPet()
            end
            ClientData = require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData)
            local equippedPet =  ClientData.get_data()[game.Players.LocalPlayer.Name].equip_manager.pets[1].unique
            local babyAilments = ClientData.get_data()[game.Players.LocalPlayer.Name].ailments_manager.baby_ailments
            local petAilments = ClientData.get_data()[game.Players.LocalPlayer.Name].ailments_manager.ailments[equippedPet]

            if petAilments then
                for _, ailment in pairs(petAilments) do
                    if ailment.kind == "hungry" then
                        _G.PetTask = "Hungry (PET)"
                        HandlePetAilments(5, "UseBlock", "hungry")

                    end
                    if ailment.kind == "thirsty" then
                        _G.PetTask = "Thristy (PET)"
                        HandlePetAilments(4, "UseBlock", "thirsty")            
                    end
                    if ailment.kind == "dirty" then
                        _G.PetTask = "Dirty (PET)"
                        HandlePetAilments(2, "Seat1", "dirty")
                    end
                    if ailment.kind == "sleepy" then
                        _G.PetTask = "Sleepy (PET)"
                        HandlePetAilments(1, "UseBlock", "sleepy")
                    end
                    if ailment.kind == "toilet" then
                        _G.PetTask = "Toilet (PET)"
                        HandlePetAilments(6, "UseBlock", "toilet")
                    end
                    if ailment.kind == "bored" then
                        _G.PetTask = "Bored (PET)"
                        HandlePetAilments(3, "Seat1", "bored")
                    end
                    if ailment.kind == "sick" then
                        _G.PetTask = "Sick (PET)"
                        game:GetService("ReplicatedStorage").API:FindFirstChild("LocationAPI/SetLocation"):FireServer("Hospital")
                        HoldAndDrop()
                        getgenv().HospitalBedID = GetBuildingFurniture("HospitalRefresh2023Bed")
                        HandlePetAilments(0, "Seat1", "sick", getgenv().HospitalBedID)
                    end
                    if ailment.kind == "salon" then
                        _G.PetTask = "Salon (PET)"
                        game:GetService("ReplicatedStorage").API:FindFirstChild("LocationAPI/SetLocation"):FireServer("Salon")
                        HoldAndDrop()
                        repeat
                            task.wait(1)
                        until not HasAilment(
                            require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData)
                                .get_data()[game.Players.LocalPlayer.Name]
                                .ailments_manager.ailments[equippedPet],
                            "salon"
                        )
                    end
                    if ailment.kind == "pizza_party" then
                        _G.PetTask = "Pizza Party (PET)"
                        game:GetService("ReplicatedStorage").API:FindFirstChild("LocationAPI/SetLocation"):FireServer("PizzaShop")
                        HoldAndDrop()
                        repeat
                            task.wait(1)
                        until not HasAilment(
                            require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData)
                                .get_data()[game.Players.LocalPlayer.Name]
                                .ailments_manager.ailments[equippedPet],
                            "pizza_party"
                        )
                    end
                    if ailment.kind == "school" then
                        _G.PetTask = "School (PET)"
                        game:GetService("ReplicatedStorage").API:FindFirstChild("LocationAPI/SetLocation"):FireServer("School")
                        HoldAndDrop()
                        repeat
                            task.wait(1)
                        until not HasAilment(
                            require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData)
                                .get_data()[game.Players.LocalPlayer.Name]
                                .ailments_manager.ailments[equippedPet],
                            "school"
                        )
                    end
                    if ailment.kind == "beach_party" then
                        _G.PetTask = "Beach Party (PET)"
                        local LiveOpsMapSwap = require(game:GetService("ReplicatedStorage").SharedModules.Game.LiveOpsMapSwap)
                        game:GetService("ReplicatedStorage").API:FindFirstChild("LocationAPI/SetLocation"):FireServer("MainMap",game:GetService("Players").LocalPlayer, LiveOpsMapSwap.get_current_map_type())
                        teleportPlayerNeeds(-551, 70, -1485)
                        createPlatform("beach_party")
                        HoldAndDrop()
                        repeat
                            task.wait(1)
                        until not HasAilment(
                            require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData)
                                .get_data()[game.Players.LocalPlayer.Name]
                                .ailments_manager.ailments[equippedPet],
                            "beach_party"
                        )
                    end
                    if ailment.kind == "camping" then
                        _G.PetTask = "Camping (PET)"
                        local LiveOpsMapSwap = require(game:GetService("ReplicatedStorage").SharedModules.Game.LiveOpsMapSwap)
                        game:GetService("ReplicatedStorage").API:FindFirstChild("LocationAPI/SetLocation"):FireServer("MainMap",game:GetService("Players").LocalPlayer, LiveOpsMapSwap.get_current_map_type())
                        teleportPlayerNeeds(-20.9, 70, -1056.7)
                        createPlatform("camping")
                        HoldAndDrop()
                        repeat
                            task.wait(1)
                        until not HasAilment(
                            require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData)
                                .get_data()[game.Players.LocalPlayer.Name]
                                .ailments_manager.ailments[equippedPet],
                            "camping"
                        )
                    end
                    if ailment.kind == "pet_me" then
                        _G.PetTask = "Pet Me (PET)"
                        local ClientData = require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData)
                        game:GetService("ReplicatedStorage").API['AdoptAPI/FocusPet']:FireServer(ClientData.get('pet_char_wrappers')[1].char)
                        task.wait(1)
                        game:GetService("ReplicatedStorage").API['PetAPI/ReplicateActivePerformances']:FireServer(ClientData.get('pet_char_wrappers')[1].char, {
                                ['FocusPet'] = true,
                                ['Petting'] = true,
                            })
                        task.wait(1)
                        game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("AilmentsAPI/ProgressPetMeAilment"):FireServer(ClientData.get('pet_char_wrappers')[1].pet_unique)
                        game:GetService("ReplicatedStorage").API['PetAPI/ReplicateActivePerformances']:FireServer(ClientData.get('pet_char_wrappers')[1].char, {
                                ['FocusPet'] = false,
                                ['Petting'] = false,
                            })
                        HoldAndDrop()
                    end
                    if ailment.kind == "play" then
                        _G.PetTask = "Play (PET)"
                        for i = 1, 3 do -- Loop 3 times
                            for i, v in pairs(ClientData.get("inventory").toys) do
                                if v.id == "squeaky_bone_default" then
                                    ToyToThrow = v.unique
                                end
                            end
                            game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("PetObjectAPI/CreatePetObject"):InvokeServer("__Enum_PetObjectCreatorType_1", {["reaction_name"] = "ThrowToyReaction", ["unique_id"] = ToyToThrow})
                            wait(7) -- Wait 4 seconds before next iteration
                        end
                        HoldAndDrop()
                    end
                    if ailment.kind == "walk" then
                        _G.PetTask = "Walk (PET)"
                        -- Get the player's character and HumanoidRootPart
                        local Player = game.Players.LocalPlayer
                        local Character = Player.Character or Player.CharacterAdded:Wait()
                        local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
                        local Humanoid = Character:WaitForChild("Humanoid") -- Get the humanoid
                        -- Set the distance and duration for the walk
                        local walkDistance = 1000  -- Adjust the distance as needed
                        local walkDuration = 30    -- Adjust the time in seconds as needed
                        -- Store the initial position to walk back to it later
                        local initialPosition = HumanoidRootPart.Position
                        -- Define the goal position (straight ahead in the character's current direction)
                        local forwardPosition = initialPosition + (HumanoidRootPart.CFrame.LookVector * walkDistance)
                        -- Calculate speed to match walkDuration
                        local walkSpeed = walkDistance / walkDuration
                        Humanoid.WalkSpeed = walkSpeed -- Temporarily set the humanoid's walk speed
                        -- Move to the forward position and back twice
                        for i = 1, 2 do
                            Humanoid:MoveTo(forwardPosition)
                            Humanoid.MoveToFinished:Wait() -- Wait until the humanoid reaches the target
                            task.wait(1) -- Optional pause after reaching the position

                            Humanoid:MoveTo(initialPosition)
                            Humanoid.MoveToFinished:Wait() -- Wait until the humanoid returns to the initial position
                            task.wait(1) -- Optional pause after returning
                        end
                        -- Reset to default walk speed
                        Humanoid.WalkSpeed = 16
                    end
                    if ailment.kind == "ride" then
                        _G.PetTask = "Ride (PET)"
                        for i,v in pairs(ClientData.get("inventory").strollers) do
                            if v.id == 'stroller-default' then
                                strollerUnique = v.unique
                            end   
                        end
                        
                        local args = {
                            [1] = strollerUnique,
                            [2] = {
                                ["use_sound_delay"] = true,
                                ["equip_as_last"] = false
                            }
                        }
                        
                        game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ToolAPI/Equip"):InvokeServer(unpack(args))         
            
                        local args = {
                            game:GetService("Players"):WaitForChild(workspace:WaitForChild("PlayerCharacters"):GetChildren()[1].Name),
                            workspace:WaitForChild("Pets"):GetChildren()[1],
                            game:GetService("Players").LocalPlayer.Character:WaitForChild("StrollerTool"):WaitForChild("ModelHandle"):WaitForChild("TouchToSits"):WaitForChild("TouchToSit")
                        }
                        
                        game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("AdoptAPI/UseStroller"):InvokeServer(unpack(args))
                        
                        -- Get the player's character and HumanoidRootPart
                        local Player = game.Players.LocalPlayer
                        local Character = Player.Character or Player.CharacterAdded:Wait()
                        local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
                        local Humanoid = Character:WaitForChild("Humanoid") -- Get the humanoid
            
                        -- Set the distance and duration for the walk
                        local walkDistance = 1000  -- Adjust the distance as needed
                        local walkDuration = 30    -- Adjust the time in seconds as needed
            
                        -- Store the initial position to walk back to it later
                        local initialPosition = HumanoidRootPart.Position
            
                        -- Define the goal position (straight ahead in the character's current direction)
                        local forwardPosition = initialPosition + (HumanoidRootPart.CFrame.LookVector * walkDistance)
            
                        -- Calculate speed to match walkDuration
                        local walkSpeed = walkDistance / walkDuration
                        Humanoid.WalkSpeed = walkSpeed -- Temporarily set the humanoid's walk speed
            
                        -- Move to the forward position and back twice
                        for i = 1, 2 do
                            Humanoid:MoveTo(forwardPosition)
                            Humanoid.MoveToFinished:Wait() -- Wait until the humanoid reaches the target
                            task.wait(1) -- Optional pause after reaching the position
                            Humanoid:MoveTo(initialPosition)
                            Humanoid.MoveToFinished:Wait() -- Wait until the humanoid returns to the initial position
                            task.wait(1) -- Optional pause after returning
                        end
                        -- Reset to default walk speed
            
                        local argsUnequip = {
                            [1] = strollerUnique,
                            [2] = {
                                ["use_sound_delay"] = true,
                                ["equip_as_last"] = false
                            }
                        }
                        
                        game:GetService("ReplicatedStorage")
                            :WaitForChild("API")
                            :WaitForChild("ToolAPI/Unequip")
                            :InvokeServer(unpack(argsUnequip))
                            
                        Humanoid.WalkSpeed = 16
                        HoldAndDrop()
                    end
                    if ailment.kind == "mystery" then
                        _G.PetTask = "Mystery (PET)"
                        local args = {
                            ClientData.get("pet_char_wrappers")[1]["char"],
                            {
                                FocusPet = true
                            }
                        }
                        game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("PetAPI/ReplicateActivePerformances"):FireServer(unpack(args))
                        for i = 1, 3 do
                            -- loop through all actions
                            for _ , action in ipairs(actions) do
                                local args = {
                                    ClientData.get("pet_char_wrappers")[1]["char"],
                                    {
                                        FocusPet = true
                                    }
                                }
                                game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("PetAPI/ReplicateActivePerformances"):FireServer(unpack(args))
                                
                                task.spawn(function() 
                                    local args = {
                                        ClientData.get("pet_char_wrappers")[1]["char"],
                                        {
                                            FocusPet = true
                                        }
                                    }
                                    game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("PetAPI/ReplicateActivePerformances"):FireServer(unpack(args))
                                    local args = {
                                        ClientData.get("pet_char_wrappers")[1].pet_unique,
                                        "mystery",
                                        i,
                                        action
                                    }
                                    game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("AilmentsAPI/ChooseMysteryAilment"):FireServer(unpack(args))
                                end)

                                dbg(ClientData.get_data()[game.Players.LocalPlayer.Name].equip_manager.pets[1].unique .. " " .. i .. " " .. action)
                                task.wait(3)
                                if not HasAilment(require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData).get_data()[game.Players.LocalPlayer.Name].ailments_manager.ailments[equippedPet], "mystery") then
                                    break
                                end
                            end
                            if not HasAilment(require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData).get_data()[game.Players.LocalPlayer.Name].ailments_manager.ailments[equippedPet], "mystery") then
                                break
                            end
                        end
                        HoldAndDrop()
                    end
                    
                end
            end

            if babyAilments then
                for _, ailment in pairs(babyAilments) do
                    if ailment.kind == "dirty" then
                        _G.PetTask = "Dirty (BABY)"
                        task.spawn(function()
                            game:GetService("ReplicatedStorage").API["HousingAPI/ActivateFurniture"]:InvokeServer(game:GetService("Players").LocalPlayer,furnitureList[2].furnID,"Seat1",{['cframe'] = CFrame.new(game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.Position)},ClientData.get("char_wrapper")["char"])
                        end)
            
                        repeat
                            task.wait(1)
                        until not HasAilment(
                            require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData)
                                .get_data()[game.Players.LocalPlayer.Name]
                                .ailments_manager.baby_ailments,
                            "dirty"
                        )
            
                        game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("AdoptAPI/ExitSeatStates"):FireServer()
                    end
                    if ailment.kind == "sleepy" then
                        _G.PetTask = "Sleepy (BABY)"
                        task.spawn(function()
                            game:GetService("ReplicatedStorage").API["HousingAPI/ActivateFurniture"]:InvokeServer(game:GetService("Players").LocalPlayer,furnitureList[1].furnID,"UseBlock",{['cframe'] = CFrame.new(game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.Position)},ClientData.get("char_wrapper")["char"])
                        end)
            
                        repeat
                            task.wait(1)
                        until not HasAilment(
                            require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData)
                                .get_data()[game.Players.LocalPlayer.Name]
                                .ailments_manager.baby_ailments,
                            "sleepy"
                        )
            
                        game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("AdoptAPI/ExitSeatStates"):FireServer()
                    end
                    if ailment.kind == "bored" then
                        _G.PetTask = "Bored (BABY)"
                        task.spawn(function()
                            game:GetService("ReplicatedStorage").API["HousingAPI/ActivateFurniture"]:InvokeServer(game:GetService("Players").LocalPlayer,furnitureList[3].furnID,"Seat1",{['cframe'] = CFrame.new(game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.Position)},ClientData.get("char_wrapper")["char"])
                        end)
            
                        repeat
                            task.wait(1)
                        until not HasAilment(
                            require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData)
                                .get_data()[game.Players.LocalPlayer.Name]
                                .ailments_manager.baby_ailments,
                            "bored"
                        )
            
                        game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("AdoptAPI/ExitSeatStates"):FireServer()
                    end
                    if ailment.kind == "hungry" then
                        _G.PetTask = "Hungry (BABY)"
                        if getCurrentMoney() >= 5 then
                            buyItem("food", "apple", 1)
                        end
                        useItem(getFoodID("apple"), 3)
                    end
                    if ailment.kind == "thirsty" then
                        _G.PetTask = "Thristy (BABY)"
                        if getCurrentMoney() >= 5 then
                            buyItem("food", "tea", 1)
                        end
                        useItem(getFoodID("tea"), 6)
                    end
                    if ailment.kind == "sick" then
                        _G.PetTask = "Sick (BABY)"
                        game:GetService("ReplicatedStorage").API:FindFirstChild("LocationAPI/SetLocation"):FireServer("Hospital")
                        getgenv().HospitalBedID = GetBuildingFurniture("HospitalRefresh2023Bed")

                        task.spawn(function()
                            game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("HousingAPI/ActivateInteriorFurniture"):InvokeServer(getgenv().HospitalBedID, "Seat1", {["cframe"] = CFrame.new(game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.Position)}, ClientData.get("char_wrapper")["char"])
                        end)

                        local t = 0
                        repeat
                            task.wait(1)
                            t = t + 1
                        until not HasAilment(
                            require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData)
                                .get_data()[game.Players.LocalPlayer.Name]
                                .ailments_manager.baby_ailments,
                            "sick"
                        ) or t > 60
            
                        game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("AdoptAPI/ExitSeatStates"):FireServer()
                    end
                    if ailment.kind == "salon" then
                        _G.PetTask = "Salon (BABY)"
                        game:GetService("ReplicatedStorage").API:FindFirstChild("LocationAPI/SetLocation"):FireServer("Salon")
                        repeat
                            task.wait(1)
                        until not HasAilment(
                            require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData)
                                .get_data()[game.Players.LocalPlayer.Name]
                                .ailments_manager.baby_ailments,
                            "salon"
                        )
                    end
                    if ailment.kind == "pizza_party" then
                        _G.PetTask = "Pizza Party (BABY)"
                        game:GetService("ReplicatedStorage").API:FindFirstChild("LocationAPI/SetLocation"):FireServer("PizzaShop")
                        repeat
                            task.wait(1)
                        until not HasAilment(
                            require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData)
                                .get_data()[game.Players.LocalPlayer.Name]
                                .ailments_manager.baby_ailments,
                            "pizza_party"
                        )
                    end
                    if ailment.kind == "school" then
                        _G.PetTask = "School (BABY)"
                        game:GetService("ReplicatedStorage").API:FindFirstChild("LocationAPI/SetLocation"):FireServer("School")
                        repeat
                            task.wait(1)
                        until not HasAilment(
                            require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData)
                                .get_data()[game.Players.LocalPlayer.Name]
                                .ailments_manager.baby_ailments,
                            "school"
                        )
                    end
                    if ailment.kind == "beach_party" then
                        _G.PetTask = "Beach Party (BABY)"
                        game:GetService("ReplicatedStorage").API:FindFirstChild("LocationAPI/SetLocation"):FireServer("School")
                        local LiveOpsMapSwap = require(game:GetService("ReplicatedStorage").SharedModules.Game.LiveOpsMapSwap)
                        game:GetService("ReplicatedStorage").API:FindFirstChild("LocationAPI/SetLocation"):FireServer("MainMap",game:GetService("Players").LocalPlayer, LiveOpsMapSwap.get_current_map_type())
                        teleportPlayerNeeds(-551, 70, -1485)
                        repeat
                            task.wait(1)
                        until not HasAilment(
                            require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData)
                                .get_data()[game.Players.LocalPlayer.Name]
                                .ailments_manager.baby_ailments,
                            "beach_party"
                        )
                    end
                    if ailment.kind == "camping" then
                        _G.PetTask = "Camping (BABY)"
                        game:GetService("ReplicatedStorage").API:FindFirstChild("LocationAPI/SetLocation"):FireServer("School")
                        local LiveOpsMapSwap = require(game:GetService("ReplicatedStorage").SharedModules.Game.LiveOpsMapSwap)
                        game:GetService("ReplicatedStorage").API:FindFirstChild("LocationAPI/SetLocation"):FireServer("MainMap",game:GetService("Players").LocalPlayer, LiveOpsMapSwap.get_current_map_type())
                        teleportPlayerNeeds(-20.9, 70, -1056.7)
                        repeat
                            task.wait(1)
                        until not HasAilment(
                            require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData)
                                .get_data()[game.Players.LocalPlayer.Name]
                                .ailments_manager.baby_ailments,
                            "camping"
                        )
                    end
                end
            end
        end
        if getgenv().HiraXRey.EventFarm then
            doEventTasks()
        end
        local isFinishedLure, BasicLure

        local success = pcall(function()
            local data = ClientData.get_data()[Player.Name]
            BasicLure = data.lures_2023_lure_manager.lures_map.BasicLure
            isFinishedLure = BasicLure.finished
        end)

        if not success then
            warn("BasicLure not found")
        end
        if isFinishedLure then
            local args = {
                game:GetService("Players").LocalPlayer,
                furnitureList[7].furnID,
                "UseBlock",
                false,
                game:GetService("Players").LocalPlayer.Character
            }
            game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("HousingAPI/ActivateFurniture"):InvokeServer(unpack(args))
        end
        if not BasicLure then
            for x, y in pairs(require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData).get_data()[game.Players.LocalPlayer.Name].inventory.food) do
                if y.kind == getgenv().HiraXRey.LureBait then
                    -- put bait
                    local args = {
                        game:GetService("Players").LocalPlayer,
                        furnitureList[7].furnID,                          
                        "UseBlock",
                        {
                            bait_unique = x
                        },
                        game:GetService("Players").LocalPlayer.Character
                    }
                    game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("HousingAPI/ActivateFurniture"):InvokeServer(unpack(args))
                    dbg("found it! " .. x .. y.kind)
                    break
                end
            end
        end
        task.wait(10)
    end

end)

local PetFarmGUI = Instance.new("ScreenGui")
local UIFrame = Instance.new("Frame")
local MoneyLabel = Instance.new("TextLabel")
local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
local MoneyPHolder = Instance.new("TextLabel")
local UITextSizeConstraint_2 = Instance.new("UITextSizeConstraint")
local EventPHolder = Instance.new("TextLabel")
local UITextSizeConstraint_3 = Instance.new("UITextSizeConstraint")
local EventLabel = Instance.new("TextLabel")
local UITextSizeConstraint_4 = Instance.new("UITextSizeConstraint")
local TaskPHolder = Instance.new("TextLabel")
local UITextSizeConstraint_5 = Instance.new("UITextSizeConstraint")
local TaskLabel = Instance.new("TextLabel")
local UITextSizeConstraint_6 = Instance.new("UITextSizeConstraint")
local PetPHolder = Instance.new("TextLabel")
local UITextSizeConstraint_7 = Instance.new("UITextSizeConstraint")
local PetLabel = Instance.new("TextLabel")
local UITextSizeConstraint_8 = Instance.new("UITextSizeConstraint")
local PotionLabel = Instance.new("TextLabel")
local UITextSizeConstraint_9 = Instance.new("UITextSizeConstraint")
local PotionPHolder = Instance.new("TextLabel")
local UITextSizeConstraint_10 = Instance.new("UITextSizeConstraint")
local PetPenPHolder = Instance.new("TextLabel")
local UITextSizeConstraint_11 = Instance.new("UITextSizeConstraint")
local PetPenLabel = Instance.new("TextLabel")
local UITextSizeConstraint_12 = Instance.new("UITextSizeConstraint")
local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
local TimeLabel = Instance.new("TextLabel")
local UITextSizeConstraint_13 = Instance.new("UITextSizeConstraint")
local TimePHolder = Instance.new("TextLabel")
local UITextSizeConstraint_14 = Instance.new("UITextSizeConstraint")
local ButtonGUI = Instance.new("ScreenGui")
local ButtonFrame = Instance.new("Frame")
local ConsoleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")
local UITextSizeConstraint_15 = Instance.new("UITextSizeConstraint")
local ToggleButton = Instance.new("TextButton")
local UICorner_2 = Instance.new("UICorner")
local UITextSizeConstraint_16 = Instance.new("UITextSizeConstraint")

--Properties:

PetFarmGUI.Name = "PetFarmGUI"
PetFarmGUI.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
PetFarmGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
PetFarmGUI.IgnoreGuiInset = true

UIFrame.Name = "UIFrame"
UIFrame.Parent = PetFarmGUI
UIFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
UIFrame.BackgroundTransparency = -0.010
UIFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
UIFrame.BorderSizePixel = 0
UIFrame.Size = UDim2.new(0, 1309, 0, 793)

MoneyLabel.Name = "MoneyLabel"
MoneyLabel.Parent = UIFrame
MoneyLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MoneyLabel.BackgroundTransparency = 1.000
MoneyLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
MoneyLabel.BorderSizePixel = 0
MoneyLabel.Position = UDim2.new(0.0381970964, 0, 0.0895334184, 0)
MoneyLabel.Size = UDim2.new(0.152788386, 0, 0.0630517006, 0)
MoneyLabel.Font = Enum.Font.FredokaOne
MoneyLabel.Text = "Money"
MoneyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
MoneyLabel.TextScaled = true
MoneyLabel.TextSize = 66.000
MoneyLabel.TextWrapped = true
MoneyLabel.TextXAlignment = Enum.TextXAlignment.Left

UITextSizeConstraint.Parent = MoneyLabel
UITextSizeConstraint.MaxTextSize = 66

MoneyPHolder.Name = "MoneyPHolder"
MoneyPHolder.Parent = UIFrame
MoneyPHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MoneyPHolder.BackgroundTransparency = 1.000
MoneyPHolder.BorderColor3 = Color3.fromRGB(0, 0, 0)
MoneyPHolder.BorderSizePixel = 0
MoneyPHolder.Position = UDim2.new(0.221543163, 0, 0.0895334184, 0)
MoneyPHolder.Size = UDim2.new(0.323147446, 0, 0.0630517006, 0)
MoneyPHolder.Font = Enum.Font.FredokaOne
MoneyPHolder.Text = "999999"
MoneyPHolder.TextColor3 = Color3.fromRGB(255, 255, 255)
MoneyPHolder.TextScaled = true
MoneyPHolder.TextSize = 66.000
MoneyPHolder.TextWrapped = true
MoneyPHolder.TextXAlignment = Enum.TextXAlignment.Left

UITextSizeConstraint_2.Parent = MoneyPHolder
UITextSizeConstraint_2.MaxTextSize = 66

EventPHolder.Name = "EventPHolder"
EventPHolder.Parent = UIFrame
EventPHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
EventPHolder.BackgroundTransparency = 1.000
EventPHolder.BorderColor3 = Color3.fromRGB(0, 0, 0)
EventPHolder.BorderSizePixel = 0
EventPHolder.Position = UDim2.new(0.221543163, 0, 0.179066837, 0)
EventPHolder.Size = UDim2.new(0.323147446, 0, 0.0630517006, 0)
EventPHolder.Font = Enum.Font.FredokaOne
EventPHolder.Text = "999999"
EventPHolder.TextColor3 = Color3.fromRGB(255, 255, 255)
EventPHolder.TextScaled = true
EventPHolder.TextSize = 66.000
EventPHolder.TextWrapped = true
EventPHolder.TextXAlignment = Enum.TextXAlignment.Left

UITextSizeConstraint_3.Parent = EventPHolder
UITextSizeConstraint_3.MaxTextSize = 66

EventLabel.Name = "EventLabel"
EventLabel.Parent = UIFrame
EventLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
EventLabel.BackgroundTransparency = 1.000
EventLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
EventLabel.BorderSizePixel = 0
EventLabel.Position = UDim2.new(0.0381970964, 0, 0.179066837, 0)
EventLabel.Size = UDim2.new(0.152788386, 0, 0.0630517006, 0)
EventLabel.Font = Enum.Font.FredokaOne
EventLabel.Text = "Event"
EventLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
EventLabel.TextScaled = true
EventLabel.TextSize = 66.000
EventLabel.TextWrapped = true
EventLabel.TextXAlignment = Enum.TextXAlignment.Left

UITextSizeConstraint_4.Parent = EventLabel
UITextSizeConstraint_4.MaxTextSize = 66

TaskPHolder.Name = "TaskPHolder"
TaskPHolder.Parent = UIFrame
TaskPHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TaskPHolder.BackgroundTransparency = 1.000
TaskPHolder.BorderColor3 = Color3.fromRGB(0, 0, 0)
TaskPHolder.BorderSizePixel = 0
TaskPHolder.Position = UDim2.new(0.221543163, 0, 0.356872648, 0)
TaskPHolder.Size = UDim2.new(0.336898386, 0, 0.0630517006, 0)
TaskPHolder.Font = Enum.Font.FredokaOne
TaskPHolder.Text = "Drinking"
TaskPHolder.TextColor3 = Color3.fromRGB(255, 255, 255)
TaskPHolder.TextScaled = true
TaskPHolder.TextSize = 66.000
TaskPHolder.TextWrapped = true
TaskPHolder.TextXAlignment = Enum.TextXAlignment.Left

UITextSizeConstraint_5.Parent = TaskPHolder
UITextSizeConstraint_5.MaxTextSize = 66

TaskLabel.Name = "TaskLabel"
TaskLabel.Parent = UIFrame
TaskLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TaskLabel.BackgroundTransparency = 1.000
TaskLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
TaskLabel.BorderSizePixel = 0
TaskLabel.Position = UDim2.new(0.0381970964, 0, 0.356872648, 0)
TaskLabel.Size = UDim2.new(0.152788386, 0, 0.0630517006, 0)
TaskLabel.Font = Enum.Font.FredokaOne
TaskLabel.Text = "Task"
TaskLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TaskLabel.TextScaled = true
TaskLabel.TextSize = 66.000
TaskLabel.TextWrapped = true
TaskLabel.TextXAlignment = Enum.TextXAlignment.Left

UITextSizeConstraint_6.Parent = TaskLabel
UITextSizeConstraint_6.MaxTextSize = 66

PetPHolder.Name = "PetPHolder"
PetPHolder.Parent = UIFrame
PetPHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
PetPHolder.BackgroundTransparency = 1.000
PetPHolder.BorderColor3 = Color3.fromRGB(0, 0, 0)
PetPHolder.BorderSizePixel = 0
PetPHolder.Position = UDim2.new(0.221543163, 0, 0.447667092, 0)
PetPHolder.Size = UDim2.new(0.336898386, 0, 0.0630517006, 0)
PetPHolder.Font = Enum.Font.FredokaOne
PetPHolder.Text = "Metal Ox"
PetPHolder.TextColor3 = Color3.fromRGB(255, 255, 255)
PetPHolder.TextScaled = true
PetPHolder.TextSize = 66.000
PetPHolder.TextWrapped = true
PetPHolder.TextXAlignment = Enum.TextXAlignment.Left

UITextSizeConstraint_7.Parent = PetPHolder
UITextSizeConstraint_7.MaxTextSize = 66

PetLabel.Name = "PetLabel"
PetLabel.Parent = UIFrame
PetLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
PetLabel.BackgroundTransparency = 1.000
PetLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
PetLabel.BorderSizePixel = 0
PetLabel.Position = UDim2.new(0.0381970964, 0, 0.447667092, 0)
PetLabel.Size = UDim2.new(0.152788386, 0, 0.0630517006, 0)
PetLabel.Font = Enum.Font.FredokaOne
PetLabel.Text = "Pet"
PetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
PetLabel.TextScaled = true
PetLabel.TextSize = 66.000
PetLabel.TextWrapped = true
PetLabel.TextXAlignment = Enum.TextXAlignment.Left

UITextSizeConstraint_8.Parent = PetLabel
UITextSizeConstraint_8.MaxTextSize = 66

PotionLabel.Name = "PotionLabel"
PotionLabel.Parent = UIFrame
PotionLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
PotionLabel.BackgroundTransparency = 1.000
PotionLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
PotionLabel.BorderSizePixel = 0
PotionLabel.Position = UDim2.new(0.0381970964, 0, 0.264817148, 0)
PotionLabel.Size = UDim2.new(0.152788386, 0, 0.0630517006, 0)
PotionLabel.Font = Enum.Font.FredokaOne
PotionLabel.Text = "Potions"
PotionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
PotionLabel.TextScaled = true
PotionLabel.TextSize = 66.000
PotionLabel.TextWrapped = true
PotionLabel.TextXAlignment = Enum.TextXAlignment.Left

UITextSizeConstraint_9.Parent = PotionLabel
UITextSizeConstraint_9.MaxTextSize = 66

PotionPHolder.Name = "PotionPHolder"
PotionPHolder.Parent = UIFrame
PotionPHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
PotionPHolder.BackgroundTransparency = 1.000
PotionPHolder.BorderColor3 = Color3.fromRGB(0, 0, 0)
PotionPHolder.BorderSizePixel = 0
PotionPHolder.Position = UDim2.new(0.221543163, 0, 0.264817148, 0)
PotionPHolder.Size = UDim2.new(0.323147446, 0, 0.0630517006, 0)
PotionPHolder.Font = Enum.Font.FredokaOne
PotionPHolder.Text = "999999"
PotionPHolder.TextColor3 = Color3.fromRGB(255, 255, 255)
PotionPHolder.TextScaled = true
PotionPHolder.TextSize = 66.000
PotionPHolder.TextWrapped = true
PotionPHolder.TextXAlignment = Enum.TextXAlignment.Left

UITextSizeConstraint_10.Parent = PotionPHolder
UITextSizeConstraint_10.MaxTextSize = 66

PetPenPHolder.Name = "PetPenPHolder"
PetPenPHolder.Parent = UIFrame
PetPenPHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
PetPenPHolder.BackgroundTransparency = 1.000
PetPenPHolder.BorderColor3 = Color3.fromRGB(0, 0, 0)
PetPenPHolder.BorderSizePixel = 0
PetPenPHolder.Position = UDim2.new(0.221543238, 0, 0.605296314, 0)
PetPenPHolder.Size = UDim2.new(0.644766867, 0, 0.20680958, 0)
PetPenPHolder.Font = Enum.Font.FredokaOne
PetPenPHolder.Text = "Metal Ox, Swan, Bat Dragon, Shadow Dragon"
PetPenPHolder.TextColor3 = Color3.fromRGB(255, 255, 255)
PetPenPHolder.TextScaled = true
PetPenPHolder.TextSize = 19.000
PetPenPHolder.TextWrapped = true
PetPenPHolder.TextXAlignment = Enum.TextXAlignment.Left
PetPenPHolder.TextYAlignment = Enum.TextYAlignment.Top

UITextSizeConstraint_11.Parent = PetPenPHolder
UITextSizeConstraint_11.MaxTextSize = 66

PetPenLabel.Name = "PetPenLabel"
PetPenLabel.Parent = UIFrame
PetPenLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
PetPenLabel.BackgroundTransparency = 1.000
PetPenLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
PetPenLabel.BorderSizePixel = 0
PetPenLabel.Position = UDim2.new(0.0381970964, 0, 0.605296314, 0)
PetPenLabel.Size = UDim2.new(0.152788386, 0, 0.0630517006, 0)
PetPenLabel.Font = Enum.Font.FredokaOne
PetPenLabel.Text = "PetPen"
PetPenLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
PetPenLabel.TextScaled = true
PetPenLabel.TextSize = 66.000
PetPenLabel.TextWrapped = true
PetPenLabel.TextXAlignment = Enum.TextXAlignment.Left

UITextSizeConstraint_12.Parent = PetPenLabel
UITextSizeConstraint_12.MaxTextSize = 66

UIAspectRatioConstraint.Parent = UIFrame
UIAspectRatioConstraint.AspectRatio = 1.651

TimeLabel.Name = "TimeLabel"
TimeLabel.Parent = UIFrame
TimeLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TimeLabel.BackgroundTransparency = 1.000
TimeLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
TimeLabel.BorderSizePixel = 0
TimeLabel.Position = UDim2.new(0.0381970964, 0, 0.528373241, 0)
TimeLabel.Size = UDim2.new(0.152788386, 0, 0.0630517006, 0)
TimeLabel.Font = Enum.Font.FredokaOne
TimeLabel.Text = "Elapsed"
TimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TimeLabel.TextScaled = true
TimeLabel.TextSize = 66.000
TimeLabel.TextWrapped = true
TimeLabel.TextXAlignment = Enum.TextXAlignment.Left

UITextSizeConstraint_13.Parent = TimeLabel
UITextSizeConstraint_13.MaxTextSize = 66

TimePHolder.Name = "TimePHolder"
TimePHolder.Parent = UIFrame
TimePHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TimePHolder.BackgroundTransparency = 1.000
TimePHolder.BorderColor3 = Color3.fromRGB(0, 0, 0)
TimePHolder.BorderSizePixel = 0
TimePHolder.Position = UDim2.new(0.221543163, 0, 0.528373241, 0)
TimePHolder.Size = UDim2.new(0.336898386, 0, 0.0630517006, 0)
TimePHolder.Font = Enum.Font.FredokaOne
TimePHolder.Text = "00:00"
TimePHolder.TextColor3 = Color3.fromRGB(255, 255, 255)
TimePHolder.TextScaled = true
TimePHolder.TextSize = 66.000
TimePHolder.TextWrapped = true
TimePHolder.TextXAlignment = Enum.TextXAlignment.Left

UITextSizeConstraint_14.Parent = TimePHolder
UITextSizeConstraint_14.MaxTextSize = 66

ButtonGUI.Name = "ButtonGUI"
ButtonGUI.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
ButtonGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ButtonGUI.DisplayOrder = 10

ButtonFrame.Name = "ButtonFrame"
ButtonFrame.Parent = ButtonGUI
ButtonFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ButtonFrame.BackgroundTransparency = 1.000
ButtonFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
ButtonFrame.BorderSizePixel = 0
ButtonFrame.Size = UDim2.new(0, 1309, 0, 793)

ConsoleButton.Name = "ConsoleButton"
ConsoleButton.Parent = ButtonFrame
ConsoleButton.BackgroundColor3 = Color3.fromRGB(111, 111, 111)
ConsoleButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
ConsoleButton.BorderSizePixel = 4
ConsoleButton.Position = UDim2.new(0.558441579, 0, 0.0895334184, 0)
ConsoleButton.Size = UDim2.new(0.119938888, 0, 0.0517023951, 0)
ConsoleButton.Font = Enum.Font.FredokaOne
ConsoleButton.Text = "Console"
ConsoleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ConsoleButton.TextScaled = true
ConsoleButton.TextSize = 34.000
ConsoleButton.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
ConsoleButton.TextWrapped = true

UICorner.CornerRadius = UDim.new(0, 90)
UICorner.Parent = ConsoleButton

UITextSizeConstraint_15.Parent = ConsoleButton
UITextSizeConstraint_15.MaxTextSize = 34

ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = ButtonFrame
ToggleButton.BackgroundColor3 = Color3.fromRGB(111, 111, 111)
ToggleButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.BorderSizePixel = 4
ToggleButton.Position = UDim2.new(0.694423199, 0, 0.0895334184, 0)
ToggleButton.Size = UDim2.new(0.119938888, 0, 0.0517023951, 0)
ToggleButton.Font = Enum.Font.FredokaOne
ToggleButton.Text = "Toggle"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextScaled = true
ToggleButton.TextSize = 34.000
ToggleButton.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextWrapped = true

UICorner_2.CornerRadius = UDim.new(0, 90)
UICorner_2.Parent = ToggleButton

UITextSizeConstraint_16.Parent = ToggleButton
UITextSizeConstraint_16.MaxTextSize = 34

-- Scripts:

local function DEXTZZ_fake_script() -- ConsoleButton.LocalScript 
	local script = Instance.new('LocalScript', ConsoleButton)

	local button = script.Parent
	local StarterGui = game:GetService("StarterGui")
	
	button.MouseButton1Click:Connect(function()
		for i = 1, 10 do
			local success = pcall(function()
				StarterGui:SetCore("DevConsoleVisible", true)
			end)
	
			if success then
				break
			end
	
			task.wait(0.2)
		end
	end)
end
coroutine.wrap(DEXTZZ_fake_script)()
local function FZTKUH_fake_script() -- ToggleButton.LocalScript 
	local script = Instance.new('LocalScript', ToggleButton)

	local button = script.Parent
	local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	local uiFrame = playerGui:WaitForChild("PetFarmGUI"):WaitForChild("UIFrame")
	
	button.MouseButton1Click:Connect(function()
		uiFrame.Visible = not uiFrame.Visible
	end)
end
coroutine.wrap(FZTKUH_fake_script)()

local ClientData = require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData)
local function getCurrentMoney()
    return require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData).get_data()[game.Players.LocalPlayer.Name].money
end
-- Initialize values
-- Function to format elapsed time
local function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secondsLeft = seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, secondsLeft)
end
local initialMoney = getCurrentMoney()
local initialPotion = 0
local startTime = os.time()
local initialEventMoney = ClientData.get_data()[game.Players.LocalPlayer.Name].eggs_2026

for _, v in pairs(ClientData.get("inventory").food) do
    if v.id == "pet_age_potion" then
        initialPotion = initialPotion + 1
    end
end
-- Function to update stats dynamically
local function updateStats()
    -- Get current money and potion counts
    local currentMoney = getCurrentMoney()
    local currentPotionCount = 0
    local currentEventMoney = ClientData.get_data()[game.Players.LocalPlayer.Name].eggs_2026
    
    local rootData = ClientData.get_data()[game.Players.LocalPlayer.Name]
    for _, v in pairs(ClientData.get("inventory").food) do
        if v.id == "pet_age_potion" then
            currentPotionCount = currentPotionCount + 1
        end
    end

    -- Calculate changes
    local moneyChange = currentMoney - initialMoney
    local potionChange = currentPotionCount - initialPotion
    local elapsedTime = os.time() - startTime
    local EventMoneyChange = currentEventMoney - initialEventMoney

    -- Format elapsed time
    local formattedTime = formatTime(elapsedTime)

    local PetsInPetPen = {}
    local PetsInPetPenData = ClientData.get_data()[Player.Name].idle_progression_manager.active_pets

    for unique, kind in pairs(PetsInPetPenData) do
        table.insert(PetsInPetPen, ConvertPetKindToName(kind.item_info.kind))
    end

    local formattedPetPen = table.concat(PetsInPetPen, ", ")

    -- Dynamic updates for stats
    MoneyPHolder.Text = tostring(currentMoney) .. " (+" .. tostring(moneyChange) .. ")"
    EventPHolder.Text = tostring(currentEventMoney) .. " (+" .. tostring(EventMoneyChange) .. ")"
    PotionPHolder.Text = tostring(currentPotionCount) .. " (+" .. tostring(potionChange) .. ")"
    TimePHolder.Text = formattedTime
    TaskPHolder.Text = tostring(_G.PetTask or "None")
    PetPHolder.Text = tostring(ClientData.get('pet_char_wrappers')[1].char or "None") -- Ensure `getgenv().petToEquipName` is set elsewhere in your script
    PetPenPHolder.Text = tostring(formattedPetPen or "Loading...")
end

updateStats()


-- Function to continuously update UI
local function startUIUpdate()
    while true do
        updateStats()
        task.wait(getgenv().HiraXRey.StatsTimer) -- Adjust the wait time as needed (e.g., every 1 second)
    end
end
startUIUpdate()
