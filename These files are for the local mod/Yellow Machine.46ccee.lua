require("vscode/console")

local DEBUG = true 

local loadedData, loadedDataOrder, originalLoadedOrder, uiHeight, uiWidth, useDecorativeNames, armyDisplay, armyText
local url = DEBUG and "http://127.0.0.1:3000/get_army_by_id?id=" or "https://yellowscribe.net/get_army_by_id?id=" 

local uiTemplates = {
    
    EDIT_UNIT_CONTAINER = [[<Row preferredHeight="${fullHeight}"><Cell><TableLayout autoCalculateHeight="true">
                                <Row preferredHeight="55">
                                    <Cell>
                                        <InputField id="editTitle-${uuid}" uuid="${uuid}" onEndEdit="updateUnitName" text="${unitName}" fontSize="24" preferredHeight="55" textAlignment="MiddleCenter" />
                                    </Cell>
                                </Row>
                                <Row preferredHeight="${moddedMaxHeight}">
                                    <Cell>
                                        <HorizontalScrollView childForceExpandHeight="false" flexibleWidth="1" flexibleHeight="1" noScrollbars="${noScrollBars}">
                                            <TableLayout width="${width}" childAlignment="MiddleCenter" cellSpacing="10" height="${maxHeight}">
                                                <Row id="modelEntryContainer-${uuid}" flexibleWidth="1" preferredHeight="${maxHeight}" childAlignment="MiddleCenter">
                                                    ${modelEntries}
                                                </Row>
                                            </TableLayout>
                                        </HorizontalScrollView>
                                    </Cell>
                                </Row>
                            </TableLayout></Cell></Row> ]],-- flexibleHeight="1" flexibleWidth="1" childForceExpandHeight="false"${unassignedWeaponsHeight}
    EDIT_MODEL_ENTRY = [[   <Cell preferredWidth="500">  
                                <VerticalLayout id="modelData-${modelID}" color="White" childForceExpandHeight="false" childForceExpandWidth="false" padding="7">
                                    <Text fontStyle="Bold" fontSize="20" flexibleWidth="1" horizontalOverflow="Overflow">${modelCount}${modelName}</Text>
                                    <VerticalLayout childForceExpandHeight="false" spacing="10">
                                        ${weaponSection}
                                        ${abilitySection}  
                                        ${unassignedSection}
                                    </VerticalLayout>
                                </VerticalLayout>
                            </Cell> ]],
    WEAPON_SECTION = [[ <VerticalLayout childForceExpandHeight="false">
                            <Text class="smallText">Weapons:</Text>
                            <VerticalLayout padding="20 10 0 0" childForceExpandHeight="false">
                                <Text alignment="UpperLeft" class="smallText">${weapons}</Text>
                                ${assignedWeapons}
                            </VerticalLayout>
                        </VerticalLayout> ]],
    ABILITIES_SECTION = [[  <VerticalLayout childForceExpandHeight="false">
                                <Text class="smallText">Abilities:</Text>
                                <VerticalLayout padding="20 10 0 0" childForceExpandHeight="false">
                                    <Text class="smallText">${abilities}</Text>
                                </VerticalLayout>
                            </VerticalLayout> ]],

    FORMATTEDRULES_SECTION = [[  <VerticalLayout childForceExpandHeight="false">
                                <Text class="smallText">Rules:</Text>
                                <VerticalLayout padding="20 10 0 0" childForceExpandHeight="false">
                                    <Text class="smallText">${formattedrules}</Text>
                                </VerticalLayout>
                            </VerticalLayout> ]],

    UNASSIGNED_SECTION = [[ <VerticalLayout childForceExpandHeight="false">
                                <Text class="smallText">Unassigned Weapons:</Text>
                                <VerticalLayout padding="20 10 0 0" childForceExpandHeight="false">
                                    ${unassigned}
                                </VerticalLayout>
                            </VerticalLayout> ]],
    --assignedSectionHeader = "", --[[  <VerticalLayout padding="0 0 -8 0" flexibleWidth="1"> ]]
    --assignedSectionFooter = "", --[[  </VerticalLayout> ]]


    
    UNASSIGNED_WEAPON = [[  <HorizontalLayout>
                                <Button class="unassignedWeapon" text="${weaponName}" onclick="46ccee/assignWeapon(${weaponEscapedName}|${unitID}|${modelID})" />
                                <Button class="assignAllButton" onclick="46ccee/assignWeapon(${weaponEscapedName}|${unitID}|${modelID}|all)" text="All" />
                                <Button class="assignAllButton" onclick="46ccee/assignWeapon(${weaponEscapedName}|${unitID}|${modelID}|unit)" text="Unit" />
                            </HorizontalLayout> ]],
    ASSIGNED_WEAPON = [[ 
                            <HorizontalLayout>
                                <Button class="assignedWeapon" text="${weaponName}" onclick="46ccee/removeWeapon(${weaponEscapedName}|${unitID}|${modelID})" />
                                <Button class="unassignAllButton" onclick="46ccee/removeWeapon(${weaponEscapedName}|${unitID}|${modelID}|all)" text="All" />
                                <Button class="unassignAllButton" onclick="46ccee/removeWeapon(${weaponEscapedName}|${unitID}|${modelID}|unit)" text="Unit" />
                            </HorizontalLayout>
                         ]],
    UNIT_CONTAINER = [[ <VerticalLayout class="transparent" childForceExpandHeight="false">
                            <Text class="unitName">${unitName}</Text>
                            <VerticalLayout class="unitContainer" childForceExpandHeight="false" preferredHeight="${height}" spacing="20">
                                ${unitData}
                            </VerticalLayout>
                        </VerticalLayout> ]],
    MODEL_CONTAINER = [[<VerticalLayout preferredWidth="500" childForceExpandHeight="false" class="modelContainer" id="${unitID}|${modelID}" preferredHeight="${height}">
                            <Text class="modelDataName">${numberString}${modelName}</Text>
                            ${weapons}
                            ${abilities}
                        </VerticalLayout> ]],
    MODEL_DATA = [[ <VerticalLayout childForceExpandHeight="false" childForceExpandWidth="false">
                        <Text height="15"><!-- spacer --></Text>
                        <Text class="modelDataTitle">${dataType}</Text>
                        <Text class="modelData" preferredHeight="${height}">${data}</Text>
                    </VerticalLayout> ]],

    MODEL_GROUPING_CONTAINER = [[ <HorizontalLayout class="groupingContainer">${modelGroups}</HorizontalLayout> ]] 
}

--[[ UNIT SCRIPTING DATA ]]--
--[[ everything in this section is meant to be a string because this is what we
are inputting into created models ]]--

local UNIT_SPECIFIC_DATA_TEMPLATE = [[ --[[ UNIT-SPECIFIC DATA ${endBracket}--
local unitData = {
    unitName = "${unitName}",
    unitDecorativeName = "${unitDecorativeName}",
    factionKeywords = "${factionKeywords}",
    keywords = "${keywords}",
    abilities = {
        ${abilities}
    },
    formattedrules = {
        ${formattedrules}
    },    
    models = {
        ${models}
    }${changingCharacteristics}${woundTrack},
    weapons = {
        ${weapons}
    }${psychic},
    uuid = "${uuid}"${singleModel},
    uiHeight = ${height},
    uiWidth = ${width}
} ]]
local CHANGING_CHARACTERISTICS_TEMPLATE = [[,
    changingCharacteristics = { 
        ${changingChars} 
    },
]]
local WEAPON_TEMPLATE = [[[c6c930]${name}[-]
${rangeAndType} S:${s} AP:${ap} D:${d} ${ability} ]]
local DEFAULT_BRACKET_VALUE_TEMPLATE = "[98ffa7]${val}[-]"
local ABILITITY_STRING_TEMPLATE = '{ name = [[${name}]], desc = [[${desc}]] }'
local WEAPON_ENTRY_TEMPLATE = '{ name="${name}", range=[[${range}]], type="${type}", s="${s}", ap="${ap}", d="${d}", abilities=[[${abilities}]] }'
local CHANGING_CHARACTERISTICS_ENTRY_TEMPLATE = '["${name}"] = { "${characteristics}" }'
local WOUND_TRACK_ENTRY_TEMPLATE = [[       ["${name}"] = {
            ${tracks}
        }]]
local PSYKER_PROFILE_TEMPLATE = [[      ["${name}"] = ${profiles}]]
local PSYCHIC_POWER_TEMPLATE = [[${name} (${warpCharge}, ${range})]]
local PSYCHIC_POWER_ENTRY_TEMPLATE = '{ name="${name}", warpCharge="${warpCharge}", range=[[${range}]], details=[[${details}]] }'





local YELLOW_STORAGE_GUID = "43ecc1"
local ARMY_BOARD_GUID = "2955a6"
local DELETION_ZONE_GUID = "f33dff"
local AGENDA_MANAGER_GUID = "45cd3f"
local IS_IN_HOME_MOD
local yellowStorage,YELLOW_STORAGE_XML,YELLOW_STORAGE_SCRIPT,army,armyBoard,uiHeight,uiWidth
local SLOT_POINTS = {slot={},boundingBox={},placed={},models={}}
local SLOTS_TO_DISPLAY = {
    "slot",
    "boundingBox",
    "placed",
    "models"
}
local DEFAULT_MODEL_SPACING = 0.15
local DEFAULT_FOOTPRINT_PADDING = 0.5
local BOUNDING_BOX_RATIO = 2
local MODEL_PLACEMENT_Y = 5.4
local ARMY_PLACEMENT_STARTING_X = -5
local ARMY_PLACEMENT_STARTING_Z = -7
local WEAPON_TYPE_VALUES = {
    ["rapid fire"] = 0,
    ["assault"] = 0,
    ["heavy"] = 0,
    ["macro"] = 0,
    ["pistol"] = 1,
    ["grenade"] = 2,
    ["melee"] = 3
}
local CREATE_ARMY_BUTTON = {
    label="CREATE ARMY", click_function="createArmy", function_owner=self,
    position={0.5,1.5,0}, rotation={180,0,180}, height=550, width=2750, font_size=220, font_style = "Bold",
    font_color={1,1,1}, color={0,150/255,0}
}
local ON_BUTTON = {
    label="LOAD ROSTER", click_function="turnOnYellowMachine", function_owner=self,
    position={0,0.52,0}, rotation={180,0,180}, height=550, width=2750, font_size=220, font_style = "Bold",
    font_color={1,1,1}, color={0,150/255,0}
}
local modelAssociations,activeButtons = {},{}
local numAssociatedObjects,firstModelAssociation = 0,true
local ERROR_RED = { 1, 0.25, 0.25 }











function moveToLoadingScreen()
    if armyText ~= nil and armyText ~= "" then
        if #armyText == 8 then
            loadedData = nil
            UI.hide("welcomeWindow")
            UI.show("loading")
            Wait.time(|| sendRequest(armyText), 0.2)
        else
            broadcastToAll("It looks like your Yellowscribe code is malformed, please make sure to enter it correctly!", ERROR_RED)
            return
        end
    else
        broadcastToAll("Please paste your code into the box before clicking submit!", ERROR_RED)
        return
    end

    Wait.time(function () -- delay so that animations dont blend
        --UI.show("loading") 

        --local loadingAnimation = Wait.time(|| updateLoadingDots(), 0.4, -1)

        Wait.condition(function ()
            if loadedData.err == nil then

                loadEditedArmy(loadedData)
                --UI.hide("loading")
    
                --loadArmyDisplay()
    
                --Wait.time(function () 
                --showWindow("postLoading")
                    --Wait.stop(loadingAnimation)
                --end, 0.2)
            else
                UI.hide("loading")
                -- wait because sometimes the response comes back before the loading screen even shows up
                Wait.time(function () 
                    broadcastToAll(loadedData.err, ERROR_RED)
                    UI.show("welcomeWindow")
                end, 0.2)
                
                --Wait.stop(loadingAnimation)
            end
        end,
        || loadedData ~= nil,
        20,
        function ()
            UI.hide("loading")
            broadcastToAll("Something has gone horribly wrong! Please try again.", ERROR_RED)
            UI.show("welcomeWindow")
            --Wait.stop(loadingAnimation)
        end)
    end, 0.15)
end



function acceptEditedArmy()
    UI.hide("mainPanel")
    loadEditedArmy({ -- args sent as table because this used to be Global and I'm too lazy to rewrite it
        data = loadedData, 
        order = originalLoadedOrder,
        uiHeight = uiHeight,
        uiWidth = uiWidth,
        useDecorativeNames = useDecorativeNames
    })
end




function updateArmyInputText(player, text)
    armyText = text
end



function sendRequest(data)    
    -- Perform the request
    log(url..data)
    WebRequest.get(url..data, handleResponse)
end


function handleResponse(response)
    -- Check if the request failed to complete e.g. if your Internet connection dropped out.
    if response.is_error then
        broadcastToAll("Something went wrong at the server!", ERROR_RED)
        log(response.text)
        return
    end
    
    local data = JSON.decode(response.text)
    
    if data.err ~= nil then
        loadedData = data
    else
        loadedData = {}
        --[[ loadedDataOrder = data.order
        originalLoadedOrder = clone(data.order) --]]
        loadedData.uiHeight = data.uiHeight
        loadedData.uiWidth = data.uiWidth
        YELLOW_STORAGE_SCRIPT = data.baseScript
        loadedData.armyData = data.armyData
        loadedData.height = data.height
        loadedData.xml = data.xml
        loadedData.order = data.order
        loadedData.useDecorativeNames = data.decorativeNames == "true"
    end
end



function loadArmyDisplay()
--[[    {
            uuid: {
                containerXML: "...",
                entries: [
                    id: "...",
                    contentXML: "..."
                ]
            }...
        } 
    ]]
    local armyDisplayTable = {}

    for _,uuid in ipairs(loadedDataOrder) do
        armyDisplayTable[uuid] = formatUnitXml(loadedData[uuid])
    end
    
    --armyDisplay = armyDisplayTable
    --local currentContainerValue = UI.getValue("loadedArmyContainer")

    --if currentContainerValue == nil then currentContainerValue = ""

    local containersString,modelContainersString = "",""

    for _,uuid in ipairs(loadedDataOrder) do
        containersString = containersString..armyDisplayTable[uuid].containerXML
    end

    loadUnitEditingXML(containersString)
end







function formatUnitXml(unit)
    --local unitTitleInputXml = interpolate(uiTemplates.editUnitTitle, { uuid=unit.uuid, unitName=unit.name })
    --local unitDataXml = ""
    --local unitEntries = {}
    local weaponSection,abilitySection,unassignedSection,modelContainersXML = "","","","",""
    local maxHeight = 0
    local weaponTitleHeight,abilityTitleHeight,unassignedTitleHeight,maxModelHeight,width,numModels = 0,0,0,0,0,0
    local modelData, model
    local sortedModelIDs = sortModels(unit.models.models, function (modelA, modelB)
        return modelA.name < modelB.name or (modelA.name == modelB.name and modelA.number > modelB.number)
    end)

    for _,modelID in pairs(sortedModelIDs) do
        model = unit.models.models[modelID]
        modelData = getModelFormatData(unit.uuid, model, modelID, unit.unassignedWeapons, model.assignedWeapons) -- no assigned weapons yet

        if modelData.height > maxHeight then 
            maxHeight = modelData.height 
        end

        modelContainersXML = modelContainersXML..interpolate(uiTemplates.EDIT_MODEL_ENTRY, {
            modelCount = model.number > 1 and (tostring(model.number).."x ") or "",
            modelName = model.name, 
            weaponSection = modelData.weaponXML, 
            abilitySection = modelData.abilityXML,
            unassignedSection = modelData.unassignedXML,
            modelID = modelID
        })

        numModels = numModels + 1
        width = width + 400
    end

    width = width - 15

    maxModelHeight = maxHeight + 30--(maxLines*20) + 30 + weaponTitleHeight + abilityTitleHeight + unassignedTitleHeight
--[[    {
            uuid: {
                containerXML: "...",
                entries: [
                    id: "...",
                    contentXML: "..."
                ]
            }...
        } 
    ]]
    -- make room for scroll bars if we need them
    local moddedMaxHeight = maxModelHeight + (numModels < 4 and 0 or 20)
    
    return {
        containerXML = interpolate(uiTemplates.EDIT_UNIT_CONTAINER, { 
            unitTitleInput = unitTitleInputXml, 
            --unitData = unitDataXml, 
            maxHeight = maxModelHeight, 
            noScrollBars = tostring(numModels < 4),
            moddedMaxHeight = moddedMaxHeight,
            fullHeight = moddedMaxHeight + 55,
            uuid = unit.uuid,
            unitName = unit.decorativeName ~= nil and unit.decorativeName or unit.name,
            modelEntries = modelContainersXML,
            width = width
        })--,
        --entries = unitEntries
    }
end



function getModelFormatData(unitID, model, modelID, unassignedWeapons, assignedWeapons)
    local height,weaponTitleHeight,abilityTitleHeight,unassignedTitleHeight = 0,0,0,0
    local weaponSection,abilitySection,unassignedSection,assignedString = "","","",""

    if assignedWeapons == nil then assignedWeapons = {} end
    if #model.weapons > 0 or #assignedWeapons > 0 then

        if #assignedWeapons > 0 then
            --assignedString = uiTemplates.assignedSectionHeader

            for _,weapon in pairs(assignedWeapons) do
                assignedString = assignedString..interpolate(uiTemplates.ASSIGNED_WEAPON, { 
                    weaponName = weapon.name, 
                    weaponEscapedName = weapon.name:gsub(",", "$$$"):gsub("%(","***"):gsub("%)","+++"), 
                    unitID = unitID, 
                    modelID = modelID 
                })
            end

            --assignedString = assignedString..uiTemplates.assignedSectionFooter
    
            height = height + (#assignedWeapons * 24)
        end
        
        weaponSection = interpolate(uiTemplates.WEAPON_SECTION, { 
            weapons = table.concat(map(model.weapons, |weapon| weapon.number == 1 and weapon.name or (weapon.number.."x "..weapon.name)), "\n"), 
            assignedWeapons = assignedString  
        })
        
        height = height + (#model.weapons * 20) + 42 -- title and spacing
    end

    if #model.abilities > 0 then
        abilitySection = interpolate(uiTemplates.ABILITIES_SECTION, { abilities=table.concat(model.abilities, "\n")})
        height = height + (#model.abilities * 20) + 42 -- title and spacing
    end

    if #unassignedWeapons > 0 and #unassignedWeapons > #assignedWeapons then
        local unassignedString = ""
        
        for _,weapon in pairs(unassignedWeapons) do
            --log(weapon.name)
            --log(includes(assignedWeapons, weapon, "name"))
            if not includes(assignedWeapons, weapon, "name") then
                unassignedString = unassignedString..interpolate(uiTemplates.UNASSIGNED_WEAPON, { 
                    weaponName = weapon.name, 
                    weaponEscapedName = weapon.name:gsub(",", "$$$"):gsub("%(","***"):gsub("%)","+++"), 
                    unitID = unitID, 
                    modelID = modelID 
                })
            end
        end

        unassignedSection = interpolate(uiTemplates.UNASSIGNED_SECTION, { unassigned=unassignedString })
        height = height + (#unassignedWeapons * 24) + 42 -- title and spacing
    end
    
    return { 
        weaponXML = weaponSection, 
        abilityXML = abilitySection,
        unassignedXML = unassignedSection, 
        height = height,
        weaponTitleHeight = weaponTitleHeight,
        abilityTitleHeight = abilityTitleHeight,
        unassignedTitleHeight = unassignedTitleHeight
    }
end








function updateUnitName(player, text, elementID)
    loadedData[split(elementID, "-")[2]].decorativeName = text
end



function assignWeapon(player, data)
    local weaponData = split(data, "|")
    local weaponName,unitID,modelID,multiple = (weaponData[1]:gsub("%$%$%$", ","):gsub("%*%*%*", "("):gsub("%+%+%+", ")")),weaponData[2],weaponData[3],weaponData[4]
    local model = loadedData[unitID].models.models[modelID]
    local newModel
    -- TODO: fix determining if is single model 
    -- (currently considers the last model in multi-model a single model)
    -- I dont remember why its important that it knows its a single model or not
    -- in any case, that is now availible under loadedData[unitID].isSingleModel
    --log(weaponName)
    local modelWithSameWeapons = findModelWithSameWeapons(unitID, model, modelID, weaponName, true)

    if multiple == nil and model.number > 1 then
        if modelWithSameWeapons ~= nil then 
            --newModel = modelWithSameWeapons
            modelWithSameWeapons.number = modelWithSameWeapons.number + 1
        else
            newModel = clone(model)
            newModel.number = 1
            modelID = split(modelID, "-")[1].."-"..uuid()
            if newModel["assignedWeapons"] == nil then
                newModel["assignedWeapons"] = { { name=weaponName, number=1 } }
            else
                table.insert(newModel.assignedWeapons, { name=weaponName, number=1 })
            end
        end
        model.number = model.number - 1
    else
        if multiple == nil then
            if modelWithSameWeapons ~= nil then 
                --newModel = modelWithSameWeapons
                modelWithSameWeapons.number = modelWithSameWeapons.number + 1
                model.number = model.number - 1
            else
                if model["assignedWeapons"] == nil then
                    model["assignedWeapons"] = { { name=weaponName, number=1 } }
                else
                    table.insert(model.assignedWeapons, { name=weaponName, number=1 })
                end
            end
        elseif multiple == "all" then
            if modelWithSameWeapons ~= nil then 
                --newModel = modelWithSameWeapons
                modelWithSameWeapons.number = modelWithSameWeapons.number + model.number
                model.number = 0
            else
                if model["assignedWeapons"] == nil then
                    model["assignedWeapons"] = { { name=weaponName, number=1 } }
                else
                    table.insert(model.assignedWeapons, { name=weaponName, number=1 })
                end
            end
        else -- unit
            for _,editModel in pairs(loadedData[unitID].models.models) do
                if editModel["assignedWeapons"] == nil then
                    editModel["assignedWeapons"] = { { name=weaponName, number=1 } }
                else
                    if not includes(editModel.assignedWeapons, {name=weaponName}, "name") then
                        table.insert(editModel.assignedWeapons, { name=weaponName, number=1 })
                    end
                end
            end
        end

        if model.number <= 0 then removeModelByID(unitID, modelID) end
    end

    if newModel ~= nil then
        loadedData[unitID].models.models[modelID] = newModel -- if a new model wasn't created this does nothing
    end

    -- always move most recently edited unit to the top of the window
    moveUnitToTopOfWindow(unitID)
    loadArmyDisplay()
    showWindow("postLoading")
    --refreshWindowAfterDelay("postLoading", 2, true)
end



function removeWeapon(player, data)
    local weaponData = split(data, "|")
    local weaponName,unitID,modelID,multiple = (weaponData[1]:gsub("%$%$%$", ","):gsub("%*%*%*", "("):gsub("%+%+%+", ")")),weaponData[2],weaponData[3],weaponData[4]
    local model = loadedData[unitID].models.models[modelID]

    -- remove the weapon
    --model.assignedWeapons = filter(model.assignedWeapons, function (name) return name ~= weaponName end)

    if multiple == nil and modelID:find("-", 1, true) then -- if is a multi-model group
        local modelWithSameWeapons = findModelWithSameWeapons(unitID, model, modelID, weaponName, false)

        if modelWithSameWeapons ~= nil then
            modelWithSameWeapons.number = modelWithSameWeapons.number + 1
        else
            newModel = clone(model)
            newModel.number = 1
            modelID = split(modelID, "-")[1].."-"..uuid()

            newModel.assignedWeapons = filter(model.assignedWeapons, |weapon| weapon.name ~= weaponName)
            loadedData[unitID].models.models[modelID] = newModel
        end

        model.number = model.number - 1

        if model.number <= 0 then removeModelByID(unitID, modelID) end
    else 
        if multiple == "unit" then
            for _,editModel in pairs(loadedData[unitID].models.models) do
                editModel.assignedWeapons = filter(editModel.assignedWeapons, |weapon| weapon.name ~= weaponName)
            end
        else -- if the model is a single-model group or removing from the whole model group
            -- remove the weapon from the mdoel group
            model.assignedWeapons = filter(model.assignedWeapons, |weapon| weapon.name ~= weaponName)
        end
    end

    -- always move most recently edited unit to the top of the window
    moveUnitToTopOfWindow(unitID)
    loadArmyDisplay()
    showWindow("postLoading")
    --refreshWindowAfterDelay("postLoading", 2, true)
end

function moveUnitToTopOfWindow(unitID)
    for idx,uuid in ipairs(loadedDataOrder) do
        if uuid == unitID then
            table.remove(loadedDataOrder, idx)
            table.insert(loadedDataOrder, 1, unitID)
            break;
        end
    end
end







function updateLoadingDots()
    local currentDots = UI.getValue("loadingDots")

    if currentDots == nil or currentDots == "" then
        UI.setValue("loadingDots", ".")
    elseif #currentDots == 5 then
        UI.setValue("loadingDots", "")
    else
        UI.setValue("loadingDots", currentDots.."..")
    end
end


function closeWelcomeWindow()
    UI.hide("mainPanel")
end

function turnOnYellowMachine()
    showWindow("welcomeWindow")
end








--[[ EVENT HANDLERS ]]--


function onLoad()
    IS_IN_HOME_MOD = Global.getVar("isYMBS2TTS") ~= nil

    yellowStorage = getObjectFromGUID(YELLOW_STORAGE_GUID)
    YELLOW_STORAGE_XML = yellowStorage.getData().XmlUI
    YELLOW_STORAGE_SCRIPT = yellowStorage.getLuaScript()

    if not IS_IN_HOME_MOD then
        getObjectFromGUID(AGENDA_MANAGER_GUID).destroy()
        getObjectFromGUID(DELETION_ZONE_GUID).destroy()
        yellowStorage.destroy()

        self.setPosition({x=0, y=4, z=0})
        self.createButton(ON_BUTTON)
        self.setLock(false)

        CREATE_ARMY_BUTTON.position = {0,0.6,0}
    else
        showWindow("welcomeWindow")
    end
end

function onScriptingButtonDown(index, player_color)
    --slotPoints = { {5,1,5}, {-5,1,-5} }
    if DEBUG then
        Global.setVectorLines(SLOT_POINTS[SLOTS_TO_DISPLAY[index]])
    end
end

function onPlayerAction(player, action, targets)
    if action == Player.Action.PickUp and #activeButtons > 0 then
        makeSureObjectsAreAttached(targets)

        local intendedTargets

        if #player.getSelectedObjects() == 0 then
            intendedTargets = { player.getHoverObject() }
        else
            intendedTargets = player.getSelectedObjects()

            if not includes(intendedTargets, player.getHoverObject()) then
                table.insert(intendedTargets, player.getHoverObject())
            end
        end
        
        local targetsData = map(intendedTargets, function (target)
            local data = target.getData()

            data.States = nil

            return data
        end)

        for _,activeButton in pairs(activeButtons) do
            local buttonModel = army[activeButton.unit].models.models[activeButton.model]
    
            buttonModel.associatedModels = targetsData

            -- its ok if we overwrite this every time, we only ever need one and they shooould be all the same
            buttonModel.associatedModelBounds = intendedTargets[1].getBoundsNormalized()

            self.UI.setAttributes(activeButton.buttonID, {
                color = "#33ff33"
            })
        end

        for _,target in ipairs(intendedTargets) do
            target.highlightOn({ r=51/255, g=1, b=51/255 }, 2)
        end

        activeButtons = {}
    end
end





--[[ MODEL SELECTION ]]--


function selectModelGroup(player,_, unitAndModelID)
    local idValues = split(unitAndModelID, "|")
    local unitID,modelID = idValues[1], idValues[2]
    local sameButtonIndex = find(map(activeButtons, |button| button.buttonID), unitAndModelID)

    if sameButtonIndex > 0 then
        for _,modelData in ipairs(army[unitID].models.models[modelID].associatedModels) do
            getObjectFromGUID(modelData.GUID).highlightOff()
        end
        army[unitID].models.models[modelID].associatedModels = nil
        table.remove(activeButtons, sameButtonIndex)
        self.UI.setAttribute(unitAndModelID, "color", "White")
    else
        table.insert(activeButtons, { unit = unitID, model = modelID, buttonID = unitAndModelID })
        self.UI.setAttribute(unitAndModelID, "color", "#ff00ca")

        if #activeButtons == 1 then -- if it's the first button selected
            broadcastToAll("Pick up a model or models to represent your selection!", {r=1, g=0, b=202/255})
        end
    end
end

function showAssociatedModel(_,_, button)
    highlightAssociatedModel(button, true)
end

function hideAssociatedModel(_,_, button)
    highlightAssociatedModel(button, false)
end

function highlightAssociatedModel(unitAndModelID, on)
    local idValues = split(unitAndModelID, "|")
    local buttonModel = army[idValues[1]].models.models[idValues[2]]

    if buttonModel.associatedModels ~= nil and #buttonModel.associatedModels > 0 then
        for _,associatedModel in ipairs(buttonModel.associatedModels) do
            local object = getObjectFromGUID(associatedModel.GUID)
            
            if object ~= nil then
                if on then
                    object.highlightOn({ r=51/255, g=1, b=51/255 })
                else
                    object.highlightOff()
                end
            end
        end
    end
end

function makeSureObjectsAreAttached(objects)
    for _,attachmentSet in ipairs(getObjectsToAttach(filter(objects, |object| #object.getJoints() > 0))) do
        for _,jointedObj in pairs(attachmentSet.toAttach) do
            if attachmentSet.lowestObj ~= jointedObj then
                attachmentSet.lowestObj.addAttachment(jointedObj)
            end
        end
    end
end

function getObjectsToAttach(objects)
    local toAttach = {}

    for _,object in ipairs(objects) do
        local attachmentSet = getObjectsToAttachRecursive(object, {}, { 
            lowestY = object.getPosition().y, 
            lowestObj = object,
            toAttach = { [object.getGUID()]=object }
        })

        for guid,_ in pairs(attachmentSet.toAttach) do
            for _,set in ipairs(toAttach) do
                if set.toAttach[guid] ~= nil then
                    mergeAttachmentSets(attachmentSet, set)
                    goto afterInsert
                end
            end
        end

        table.insert(toAttach, attachmentSet)
        ::afterInsert::
    end

    return toAttach
end

function getObjectsToAttachRecursive(object, found, toAttachTable)
    for _,joint in ipairs(object.getJoints()) do
        if found[joint.joint_object_guid] == nil then
            local jointedObj = getObjectFromGUID(joint.joint_object_guid)
            local jointedObjY = jointedObj.getPosition().y
            
            found[joint.joint_object_guid] = true
            toAttachTable.toAttach[joint.joint_object_guid] = jointedObj

            if jointedObjY < toAttachTable.lowestY then
                toAttachTable.lowestY = jointedObjY
                toAttachTable.lowestObj = jointedObj
            end

            getObjectsToAttachRecursive(jointedObj, found, toAttachTable)
        end
    end

    return toAttachTable
end

function mergeAttachmentSets(setToMerge, mergeIntoSet)
    for guid,obj in pairs(setToMerge.toAttach) do
        if mergeIntoSet.toAttach[guid] == nil then
            mergeIntoSet.toAttach[guid] = obj
        end
    end

    if setToMerge.lowestY < mergeIntoSet.lowestY then
        mergeIntoSet.lowestY = setToMerge.lowestY
        mergeIntoSet.lowestObj = setToMerge.lowestObj
    end
end








--[[ ARMY CREATION ]]--

-- formats and creates the army based on selected models 
function createArmy()
    -- we only want to create models for ones that have a model selected
    local unitsToCreate = filter(army, function (unit) 
        unit.models.models = filter(unit.models.models, function (model)
            if model.associatedModels == nil or #model.associatedModels == 0 then 
                -- make sure we are spawning thr right number of models if only part of a unit is beign spawned
                unit.models.totalNumberOfModels = unit.models.totalNumberOfModels - model.number
            end
            
            return model.associatedModels ~= nil and #model.associatedModels > 0
        end)

        return len(unit.models.models) > 0
    end)

    if len(unitsToCreate) == 0 then
        broadcastToAll("You haven't selected any models!", ERROR_RED)
        return
    end
    
    -- delete anything that might get in the way in the future
    deleteAllObjectsInCreationZone()

    -- this feels so inefficient to go through the array so many times,
    -- but at this point, the array really shouldn't be that long, 
    -- so I dont have to worry too much about big-O
    unitsToCreate = table.sort(map(unitsToCreate, function (unit)
        unit.models.models = table.sort(unit.models.models, |modelA, modelB| modelA.number < modelB.number)

        --[[ for _,model in ipairs(unit.models.models) do
            model.associatedModel = getObjectFromGUID(model.associatedModel)
        end --]]

        unit.footprint = determineFootprint(unit)

        return unit
    end), function (unitA, unitB)
        if unitA.footprint.width == unitB.footprint.width then
            return unitB.footprint.height < unitA.footprint.height  
        end

        return unitA.footprint.width > unitB.footprint.width
    end)

    local selfPosition = self.getPosition()

    -- at this point, we should have a list of units sorted by width then height of their footprints
    placeArmy(unitsToCreate, ARMY_PLACEMENT_STARTING_X + selfPosition.x, ARMY_PLACEMENT_STARTING_Z + selfPosition.z, selfPosition.y)
end


function placeArmy(unitMap, startingX, startingZ, startingY)
    local emptySlots = {} -- {{x,z,h,w},...}
    local boundingBox = { h=0, w=0 }
    
    for _,unit in pairs(unitMap) do
        local placedInEmptySlot = false

        -- try to place at an origin
        for idx,slot in ipairs(emptySlots) do
            if unit.footprint.height <= slot.h and unit.footprint.width <= slot.w then
                placeUnit(unit, startingX-slot.x, startingZ+slot.z, startingY)

                if DEBUG then
                    table.insert(SLOT_POINTS.placed, { points= {
                        {startingX-slot.x,MODEL_PLACEMENT_Y+1,startingZ+slot.z},
                        {startingX-slot.x-unit.footprint.width,MODEL_PLACEMENT_Y+1,startingZ+slot.z},
                        {startingX-slot.x-unit.footprint.width,MODEL_PLACEMENT_Y+1,startingZ+slot.z+unit.footprint.height},
                        {startingX-slot.x,MODEL_PLACEMENT_Y+1,startingZ+slot.z+unit.footprint.height},
                        {startingX-slot.x,MODEL_PLACEMENT_Y+1,startingZ+slot.z}
                    },
                    color = {0,0,0}})
                end

                table.remove(emptySlots, idx)

                -- slot to the side should be filled first if possible
                -- so insert the top one first
                if (slot.h - unit.footprint.height) >= 1 then
                    if DEBUG then
                        table.insert(SLOT_POINTS.slot,{points= {
                            {startingX-slot.x,MODEL_PLACEMENT_Y+1,startingZ+slot.z+unit.footprint.height},
                            {startingX-slot.x-slot.w,MODEL_PLACEMENT_Y+1,startingZ+slot.z+unit.footprint.height},
                            {startingX-slot.x-slot.w,MODEL_PLACEMENT_Y+1,startingZ+slot.z+slot.h},
                            {startingX-slot.x,MODEL_PLACEMENT_Y+1,startingZ+slot.z+slot.h},
                            {startingX-slot.x,MODEL_PLACEMENT_Y+1,startingZ+slot.z+unit.footprint.height}
                        },
                        color = {0,1,0}})
                    end

                    table.insert(emptySlots, {
                        x = slot.x, 
                        z = slot.z + unit.footprint.height, 
                        h = slot.h - unit.footprint.height, 
                        w = slot.w
                    })
                end
                
                if (slot.w - unit.footprint.width) >= 1 then
                    if DEBUG then
                        table.insert(SLOT_POINTS.slot,{ points = {
                            {startingX-slot.x-unit.footprint.width,MODEL_PLACEMENT_Y+1,startingZ+slot.z},
                            {startingX-boundingBox.w,MODEL_PLACEMENT_Y+1,startingZ+slot.z},
                            {startingX-boundingBox.w,MODEL_PLACEMENT_Y+1,startingZ+slot.z+unit.footprint.height},
                            {startingX-slot.x-unit.footprint.width,MODEL_PLACEMENT_Y+1,startingZ+slot.z+unit.footprint.height},
                            {startingX-slot.x-unit.footprint.width,MODEL_PLACEMENT_Y+1,startingZ+slot.z}
                        },
                        color = {0,0,1}})
                    end

                    table.insert(emptySlots, {
                        x = slot.x + unit.footprint.width, 
                        z = slot.z, 
                        w = slot.w - unit.footprint.width, 
                        h = unit.footprint.height 
                    })
                end
                -- >= 1 because we dont want to make additional tiny slots that will never be filled

                placedInEmptySlot = true
                break;
            end
        end

        if placedInEmptySlot then -- do nothing
        
        -- if expanding upward makes sense
        elseif (boundingBox.h + unit.footprint.height) < (boundingBox.w * BOUNDING_BOX_RATIO) then
            placeUnit(unit, startingX, startingZ + boundingBox.h, startingY)

            if DEBUG then
                table.insert(SLOT_POINTS.placed, { points= {
                    {startingX,MODEL_PLACEMENT_Y+1,startingZ+boundingBox.h},
                    {startingX-unit.footprint.width,MODEL_PLACEMENT_Y+1,startingZ+boundingBox.h},
                    {startingX-unit.footprint.width,MODEL_PLACEMENT_Y+1,startingZ+boundingBox.h+unit.footprint.height},
                    {startingX,MODEL_PLACEMENT_Y+1,startingZ+boundingBox.h+unit.footprint.height},
                    {startingX,MODEL_PLACEMENT_Y+1,startingZ+boundingBox.h}
                },
                color = {0,0,0}})
            end
            
            if (boundingBox.w - unit.footprint.width >= 1) then
                if DEBUG then
                    table.insert(SLOT_POINTS.slot, { points= {
                        {startingX-unit.footprint.width,MODEL_PLACEMENT_Y+1,startingZ+boundingBox.h},
                        {startingX-boundingBox.w,MODEL_PLACEMENT_Y+1,startingZ+boundingBox.h},
                        {startingX-boundingBox.w,MODEL_PLACEMENT_Y+1,startingZ+boundingBox.h+unit.footprint.height},
                        {startingX-unit.footprint.width,MODEL_PLACEMENT_Y+1,startingZ+boundingBox.h+unit.footprint.height},
                        {startingX-unit.footprint.width,MODEL_PLACEMENT_Y+1,startingZ+boundingBox.h}
                    },
                    color = {1,0,1}})
                end

                table.insert(emptySlots, { 
                    x = unit.footprint.width, 
                    z = boundingBox.h, 
                    h = unit.footprint.height, 
                    w = boundingBox.w - unit.footprint.width 
                })
            end

            boundingBox.h = boundingBox.h + unit.footprint.height

        -- else place at far left
        else
            placeUnit(unit, startingX - boundingBox.w, startingZ, startingY)

            if DEBUG then
                table.insert(SLOT_POINTS.placed, { points= {
                    {startingX-boundingBox.w,MODEL_PLACEMENT_Y+1,startingZ},
                    {startingX-boundingBox.w-unit.footprint.width,MODEL_PLACEMENT_Y+1,startingZ},
                    {startingX-boundingBox.w-unit.footprint.width,MODEL_PLACEMENT_Y+1,startingZ+unit.footprint.height},
                    {startingX-boundingBox.w,MODEL_PLACEMENT_Y+1,startingZ+unit.footprint.height},
                    {startingX-boundingBox.w,MODEL_PLACEMENT_Y+1,startingZ}
                },
                color = {0,0,0}})
            end
            
            if boundingBox.h - unit.footprint.height >= 1 then
                if DEBUG then
                    table.insert(SLOT_POINTS.slot, { points= {
                        {startingX-boundingBox.w,MODEL_PLACEMENT_Y+1,startingZ+unit.footprint.height},
                        {startingX-boundingBox.w-unit.footprint.width,MODEL_PLACEMENT_Y+1,startingZ+unit.footprint.height},
                        {startingX-boundingBox.w-unit.footprint.width,MODEL_PLACEMENT_Y+1,startingZ+boundingBox.h},
                        {startingX-boundingBox.w,MODEL_PLACEMENT_Y+1,startingZ+boundingBox.h},
                        {startingX-boundingBox.w,MODEL_PLACEMENT_Y+1,startingZ+unit.footprint.height}
                    },
                    color = {0,0,0}})
                end

                table.insert(emptySlots, {
                    x = boundingBox.w,
                    z = unit.footprint.height,
                    h = boundingBox.h - unit.footprint.height,
                    w = unit.footprint.width
                })
            end

            boundingBox.w = boundingBox.w + unit.footprint.width
            
            if boundingBox.h == 0 then boundingBox.h = unit.footprint.height end -- handle first unit
        end
    end

    if DEBUG then
        SLOT_POINTS.boundingBox = {{
            points= {
                {startingX, MODEL_PLACEMENT_Y+1, startingZ},
                {startingX-boundingBox.w, MODEL_PLACEMENT_Y+1, startingZ},
                {startingX-boundingBox.w, MODEL_PLACEMENT_Y+1, startingZ+boundingBox.h},
                {startingX, MODEL_PLACEMENT_Y+1, startingZ+boundingBox.h},
                {startingX, MODEL_PLACEMENT_Y+1, startingZ},
            },
            color = {0,0,0}
        }}
    end

    local boardPosition = { x=startingX-(boundingBox.w*0.5), y=5+startingY, z=startingZ+(boundingBox.h * 0.5) }
    local boardScale = { x=(0.5*boundingBox.w), y=1, z=(0.5*boundingBox.h)}

    if armyBoard == nil then
        armyBoard = spawnObject({
            type = "Custom_Tile",
            sound = false,
            position = boardPosition,
            scale = boardScale
        })
        armyBoard.setCustomObject({
            image = "http://cloud-3.steamusercontent.com/ugc/1698405413696745750/BC055E0445A3CEC1A0A0754CF4F1646977612B09/",
            thickness = 0.37
        })
        armyBoard.setLock(true)
    else
        armyBoard.setScale(boardScale)
        armyBoard.setPosition(boardPosition)
    end
end


function placeUnit(unit, startX, startZ, startY)
    -- cheap way of determining a "sergeant" model:
    -- sort by number, pick the first, hope for the best
    local isFirstModel = true
    local xOffset = startX - DEFAULT_FOOTPRINT_PADDING -- left is negative
    local zOffset = startZ + DEFAULT_FOOTPRINT_PADDING -- up is positive
    local modelSize
    local currentRowHeight,currentModelsInRow = 0,0
    local leaderData = formatLeaderScript(unit)

    for modelID,model in pairs(unit.models.models) do
        --local currentModelObj = getObjectFromGUID(model.associatedModel)
        -- I dont remember why I'm passing the data as an object instead of just as arguments
        local modelProfile = getProfileForModel(model, unit)
        local modelDescription = buildModelDescription(model, unit, modelProfile)
        local modelNickname = (modelProfile ~= nil and ("[00ff16]"..modelProfile.w.."/"..modelProfile.w.."[-] ") or "")
                                ..getModelDisplayName(model, unit)
        local modelTags = getModelTags(model, unit)
        
        local modelData = formatModelData(model.associatedModels,
                                            modelDescription,
                                            modelNickname,
                                            modelTags)

        modelSize = model.associatedModelBounds.size
        --log(model)

        if currentRowHeight < modelSize.z then currentRowHeight = modelSize.z end

        for i=1,model.number do
            createModelFromData(chooseRandomModel(modelData),
                                --unit.decorativeName and unit.decorativeName or unit.name, 
                                xOffset-(modelSize.x*0.5), 
                                zOffset+(modelSize.z*0.5),
                                startY, 
                                leaderData)
            table.insert(SLOT_POINTS.models,{ points = {
                {xOffset,MODEL_PLACEMENT_Y+1,zOffset},
                {xOffset-modelSize.x,MODEL_PLACEMENT_Y+1,zOffset},
                {xOffset-modelSize.x,MODEL_PLACEMENT_Y+1,zOffset+modelSize.z},
                {xOffset,MODEL_PLACEMENT_Y+1,zOffset+modelSize.z},
                {xOffset,MODEL_PLACEMENT_Y+1,zOffset}
            },
            color = {0,0,1}})
            leaderData = nil
            currentModelsInRow = currentModelsInRow + 1
            

            if currentModelsInRow == unit.modelsPerRow then
                currentModelsInRow = 0
                xOffset = startX - DEFAULT_FOOTPRINT_PADDING
                zOffset = zOffset + currentRowHeight + DEFAULT_MODEL_SPACING
            else
                xOffset = xOffset - (modelSize.x + DEFAULT_MODEL_SPACING)
            end
        end
    end
end

-- determines how much space a unit should take up once it is created
function determineFootprint(unit)
    -- determine models per row
    local modelsPerRow = unit.models.totalNumberOfModels
    local currentModelsInRow,currentWidth,footprintWidth,footprintHeight,modelsLeft = 0,0,0,0,0
    local currentRow = 1
    local currentHeights = {}
    local currentModelBounds

    if modelsPerRow > 5 then
        if modelsPerRow < 20 and modelsPerRow % 3 == 0 then
            if modelsPerRow < 12 then modelsPerRow = 3
            else modelsPerRow = modelsPerRow / 3 end
        elseif modelsPerRow < 20 and modelsPerRow % 5 == 0 then
            modelsPerRow = 5
        elseif modelsPerRow > 10 then
            modelsPerRow = 10
        end
    end

    unit.modelsPerRow = modelsPerRow

    -- I realize that this is doing almost exactly what we will do later when actually creating the models
    -- unfortunately, this is the only way that I can think of to guarantee the footprint of a unit
    -- with models of different sizes
    for _,model in pairs(unit.models.models) do
        currentModelBounds = model.associatedModelBounds.size

        if currentHeights[currentRow] == nil or currentModelBounds.z > currentHeights[currentRow] then 
            currentHeights[currentRow] = currentModelBounds.z 
        end

        if (currentModelsInRow + model.number) >= modelsPerRow then
            currentWidth = currentWidth + ((modelsPerRow - currentModelsInRow) * (currentModelBounds.x + DEFAULT_MODEL_SPACING))

            if currentWidth > footprintWidth then footprintWidth = currentWidth end

            modelsLeft = model.number - (modelsPerRow - currentModelsInRow)
            currentRow = currentRow + 1

            while modelsLeft >= modelsPerRow do
                table.insert(currentHeights, currentModelBounds.z + DEFAULT_MODEL_SPACING)
                currentRow = currentRow + 1
                modelsLeft = modelsLeft - modelsPerRow
                currentWidth = (currentModelBounds.x + DEFAULT_MODEL_SPACING) * modelsPerRow
            end

            if modelsLeft > 0 then
                table.insert(currentHeights, currentModelBounds.z + DEFAULT_MODEL_SPACING)
                currentModelsInRow = modelsLeft
            end

            if currentWidth > footprintWidth then footprintWidth = currentWidth end

            currentWidth = currentModelsInRow * (currentModelBounds.x + DEFAULT_MODEL_SPACING)
        else
            currentWidth = currentWidth + (model.number * (currentModelBounds.x + DEFAULT_MODEL_SPACING))
            currentModelsInRow = currentModelsInRow + model.number
        end
    end

    --if footprintHeight == 0 then footprintHeight = currentHeight end -- in case it hasnt been set yet (usually only because a row hasnt been filled)
    for _,height in ipairs(currentHeights) do
        footprintHeight = footprintHeight + height
    end
    
    return { width = footprintWidth+(2*DEFAULT_FOOTPRINT_PADDING), height = footprintHeight+(2*DEFAULT_FOOTPRINT_PADDING) }
end

-- formats both the leader and follower model data from a given model
function formatModelData(associatedModels, description, nickname, tags)
    for _,modelData in ipairs(associatedModels) do
        modelData.Description = description
        modelData.Nickname = nickname
        modelData.Tags = tags
        -- make sure base data doesnt include any xml or luascript
        modelData.XmlUI = ""
        modelData.LuaScript = ""
        modelData.LuaScriptState = nil
    end

    return associatedModels
end


function formatLeaderScript(unit)
    return interpolate(UNIT_SPECIFIC_DATA_TEMPLATE, {
        unitName = unit.name,
        unitDecorativeName = (unit.decorativeName ~= nil and unit.decorativeName ~= "") and unit.decorativeName:gsub('"', '\\"') or unit.name,
        
        factionKeywords = table.concat(unit.factionKeywords, ", "), -- dont break xml   --map(unit.factionKeywords, |keyword| (keyword:gsub(">", "＞"):gsub("<", "＜")))

        keywords = table.concat(unit.keywords, ", "), -- dont break xml   --map(unit.keywords, |keyword| (keyword:gsub(">", "＞"):gsub("<", "＜")))

        abilities = getFormattedAbilities(unit.abilities, unit.rules),
        formattedrules = getFormattedAbilities(unit.formattedrules,""),

        models = table.concat(map(unit.modelProfiles, function (profile)
            -- if the unit has brackets, treat each one as a separate model
            if unit.woundTrack ~= nil and unit.woundTrack[profile.name] then
                local toReturn = {}
                local originalName = profile.name
                local changing
                
                for key,bracket in pairs(unit.woundTrack[profile.name]) do
                    profile.name = originalName.." ("..key..")"
                    changing = tableToFlatString(profile)

                    -- this seems like an inefficient way of doing it, but was the easiest to come up with
                    for _,val in ipairs(bracket) do
                        changing = changing:gsub("%*", val:gsub('"', '\\"'), 1)
                    end

                    table.insert(toReturn, changing)
                end
                
                return table.concat(toReturn, ",\n\t\t")
            end

            -- otherwise, just add the model
            return tableToFlatString(profile)
        end), ",\n\t\t"),

        weapons = table.concat(map(unit.weapons, |weapon| interpolate(WEAPON_ENTRY_TEMPLATE, weapon)), ",\n\t\t"),

        endBracket = "]]",
        uuid = unit.uuid,
        height = uiHeight,
        width = uiWidth,

        changingCharacteristics = unit.woundTrack == nil and "" or interpolate(CHANGING_CHARACTERISTICS_TEMPLATE, { 
            changingChars = formatChangingCharacteristics(unit)
        }),

        woundTrack = unit.woundTrack == nil and "" or "\twoundTrack = "..tableToString(map(unit.woundTrack, function (tracks, name)
            return interpolate(WOUND_TRACK_ENTRY_TEMPLATE, {
                tracks = table.concat(map(tracks, function (track, key)
                    local temp = '["'..key..'"] = { "'

                    temp = temp..table.concat(map(track, |val| (val:gsub('"', '\\"'))), '", "')

                    return temp..'" }'
                end), ",\n\t\t\t", start_index, end_index ),
                name = name
            })
            
        end), ",\n", true, "\t"),

        singleModel = (not unit.isSingleModel) and "" or ",\n\tisSingleModel = true",

        psychic = unit.psykerProfiles == nil and "" or ",\n\tpsykerProfiles = "..
            tableToString(map(unit.psykerProfiles, |profile| tableToFlatString(profile)), ",\n\t\t", true, "\t", "\t\t")..
            ",\n\tpowersKnown = "..
            tableToString(map(unit.powersKnown, |power| interpolate(PSYCHIC_POWER_ENTRY_TEMPLATE, power)), ",\n\t\t", true, "\t", "\t\t") 
    })..YELLOW_STORAGE_SCRIPT
end

function formatChangingCharacteristics(unit)
    local changing = {}

    for _,profile in pairs(unit.modelProfiles) do
        for char,val in pairs(profile) do -- profile
            if val == "*" then 
                if changing[profile.name] == nil then changing[profile.name] = {} end

                table.insert(changing[profile.name], char) 
            end
        end
    end

    --[[ for name,_ in pairs(unit.woundTrack) do
        
        changing[name] = {}

        for char,val in pairs(unit.modelProfiles[name]) do -- profile
            if val == "*" then table.insert(changing[name], char) end
        end
    end --]]

    local toReturn = {}

    for name,arr in pairs(changing) do
        table.insert(toReturn, interpolate(CHANGING_CHARACTERISTICS_ENTRY_TEMPLATE, { 
            characteristics = table.concat(arr, '", "'),
            name = name
        }))
    end

    return table.concat(toReturn, ",\n\t\t")
end

function getModelDisplayName(model, unit)
    if unit.isSingleModel or useDecorativeNames then
        if unit.decorativeName ~= nil and unit.decorativeName ~= "" then
            return unit.decorativeName
        else
            return model.name
        end
    end

    return model.name
end

function getModelTags(model, unit) 
    local tags = { "uuid:"..unit.uuid }

    if unit.woundTrack ~= nil then
        for key,_ in pairs(unit.woundTrack) do
            if key == model.name then table.insert(tags, "wt:"..model.name) 
            -- this is a special case for Armigers (i.e. units that have multiple of the same model that has a wound track)
            -- where the data source creator named the profile in the plural ("Armigers")    
            elseif key == model.name.."s" then table.insert(tags, "wt:"..model.name.."s") end
        end
    end

    return tags
end

-- Combine abilities and rules and format them properly to be displayed in a unit's datasheet
function getFormattedAbilities(abilities, rules)
    local abilitiesString = table.concat(map(abilities, function (ability)
        ability.name = ability.name:gsub("%[", "("):gsub("%]", ")") -- try not to break formatting

        return interpolate(ABILITITY_STRING_TEMPLATE, ability)
    end), ",\n\t\t")

    if #rules > 0 then
        abilitiesString = abilitiesString..
                            (len(abilities) > 0 and ",\n\t\t" or "")..
                            interpolate(ABILITITY_STRING_TEMPLATE, { 
                                name="Additional Rules\n(see the books)",
                                desc = table.concat(map(rules, |rule| (rule:gsub("%[", "("):gsub("%]", ")"))), ", ")-- try not to break formatting
                            })                     
    end

    return abilitiesString
end

-- chooses a random model from the given array
-- technically this is a general method that could be used for selecting
-- a random value from any array
function chooseRandomModel(modelArray)
    if #modelArray == 1 then return modelArray[1] end
    if modelArray == nil or #modelArray == 0 then return nil end

    return modelArray[math.random(1, #modelArray)] -- both inclusive
end

-- spawns a model from the given data set
function createModelFromData(modelData, x, z, y, leaderModelScript)
    if leaderModelScript ~= nil then
        modelData = clone(modelData) -- prevent weird things with tables being treated as references
        table.insert(modelData.Tags, "leaderModel")
        modelData.XmlUI = YELLOW_STORAGE_XML
        modelData.LuaScript = leaderModelScript
    end

    local spawnData = {
        data = modelData,
        position = {
            x = x,
            y = MODEL_PLACEMENT_Y+y,
            z = z
        },
        rotation = { x=0, y=180, z=0 }, -- this seems right for most (but not all models)
    }
    
    spawnObjectData(spawnData)
end

-- finds the appropriate characteristic profile for the given model in the given unit
function getProfileForModel(model, unit)
    for _,profile in pairs(unit.modelProfiles) do
        if profile.name == model.name then
            return profile
        end
    end
    -- if there arent any exactly matching profiles, try a more fuzzy search
    for _,profile in pairs(unit.modelProfiles) do
        local found = profile.name:find(model.name, 1, true) -- search for plain text (ie not pattern)

        if found ~= nil then return profile end
    end
    -- if there arent any matching profiles, assume theres only one profile for every model in the unit
    for _,profile in pairs(unit.modelProfiles) do return profile end

    -- returns nil if not found
end

-- gets a model's description
function buildModelDescription(model, unit, modelProfile)
    return  formatCharDesc(modelProfile, unit)..
            formatWeaponDesc(model, unit, modelProfile ~= nil)..
            formatAbilityDesc(model, unit, modelProfile ~= nil)..
            formatPsychicDesc(model, unit, modelProfile ~= nil)
end

-- formats the characteristics section in a model's description
function formatCharDesc(modelProfile, unit)
    if modelProfile == nil then return "" end -- handles the rare case where a model just doesnt have a profile (eg Mekboy Workshop)

    local charHeadingString,charValueString = "[56f442]",""
    local currentChar = 1
    local woundTrack

    if unit.woundTrack ~= nil then
        if unit.woundTrack[modelProfile.name] ~= nil then 
            woundTrack = map(unit.woundTrack[modelProfile.name], |v| v) -- make it array-like
        elseif len(unit.woundTrack) == 1 then
            for _,wt in pairs(unit.woundTrack) do
                woundTrack = map(wt, |v| v)
            end
        end
    end 

    for heading,value in pairs(modelProfile) do 
        if heading ~= "name" then 
            if value == "*" and woundTrack ~= nil then
                value = woundTrack[1][currentChar]
                charValueString = charValueString..interpolate(DEFAULT_BRACKET_VALUE_TEMPLATE, { val=value }).."   "
                currentChar = currentChar + 1
            else
                charValueString = charValueString..(value == "-" and "  "..value or value).."   "
            end
            
            charHeadingString = charHeadingString..formatHeading(heading, value)
        end
    end

    charHeadingString = charHeadingString.."[-]\n"

    return charHeadingString..charValueString.."[-][-]" -- the double brackets at the end helps us to update brakcets if the unit has them
end

-- formats the heading line for the characteristics section in a model's description
-- the spacing is based on the values given so that they line up properly
function formatHeading(heading, value)
    local spacing = value:gsub("\\",""):len()-heading:len()
    
    if heading == "ws" or heading == "m" or heading =="a" then 
        spacing = spacing + 2
    else
        spacing = spacing + 3
    end

    if (heading == "m" and value:len() > 2) or ((heading == "a" or heading == "s" or heading == "t" or heading == "w") and value:len() > 1) then
        if heading == "m" and value ~= "-" and value:find('%-') ~= nil then
            heading = heading.."   "
        end

        heading = " "..heading
    end

    return capitalize(heading)..string.rep(" ", spacing)
end

-- decides whether to fully capitalize or (in the case of ld and sv) titlecase a string
function capitalize(heading)
    if heading == "ld" or heading == "sv" then return titlecase(heading) end
    return heading:upper()
end

-- only use this for changing ld and sv to Ld and Sv
function titlecase(s)
    return s:gsub("^(%w)", |a| a:upper())
end

-- formats the string for the weapons section in a model's description
function formatWeaponDesc(model, unit, needSpacingBefore)
    if #model.weapons == 0 then return "" end

    local weapons = (needSpacingBefore and "\n\n" or "").."[e85545]Weapons[-]"

    for _,weapon in pairs(model.weapons) do
        weapons = weapons.."\n"..formatWeapon(unit.weapons[weapon.name], weapon.number)
    end

    return weapons
end

-- formats the string for a weapon entry in a model's description
function formatWeapon(weaponProfile, number)
    return  interpolate(WEAPON_TEMPLATE, {
        name = number == 1 and weaponProfile.name or (number.."x "..weaponProfile.name),
        rangeAndType = (weaponProfile.range == "Melee") and "Melee" or weaponProfile.range.." "..weaponProfile.type,
        s = weaponProfile.s,
        ap = weaponProfile.ap,
        d = weaponProfile.d,
        ability = weaponProfile.abilities == "-" and "" or "Sp:*"
    })
end

-- formats the string for the abilities section in a model's description
function formatAbilityDesc(model, unit, needSpacingBefore)
    if #model.abilities == 0 then return "" end

    return ((needSpacingBefore or #model.weapons > 0) and "\n\n" or "").."[dc61ed]Abilities[-]\n"..table.concat(model.abilities, "\n")
end


function formatPsychicDesc(model, unit)
    if unit.powersKnown == nil or #unit.powersKnown == 0 then return "" end

    return ((needSpacingBefore or #model.weapons > 0 or #model.abilities > 0) and "\n\n" or "")..
            "[5785fe]Psychic Powers[-]\n"..table.concat(map(unit.powersKnown, |power| interpolate(PSYCHIC_POWER_TEMPLATE, {
                name = power.name,
                warpCharge = power.warpCharge,
                range = power.range
            })), "\n")
end


function deleteAllObjectsInCreationZone()
    local deletionZone = getObjectFromGUID(DELETION_ZONE_GUID)

    if deletionZone == nil then return end
    
    for _,object in ipairs(deletionZone.getObjects()) do
        if object ~= armyBoard and object.getGUID() ~= YELLOW_STORAGE_GUID then
            object.setLuaScript("") -- prevent unintended consequences of destruction
            object.destruct() -- at this point the object is a different object because we reloaded it
        end
    end
end








--[[ INITIALIZATION HELPER FUNCTIONS ]]--


function loadUnitEditingXML(xml) 
    self.UI.setValue("loadedArmyContainer", xml)
end

function showWindow(name)
    -- delay in case of update
    Wait.frames(function ()
        UI.setXml(self.UI.getXml())

        Wait.frames(function ()
            UI.setAttribute("mainPanel", "active", true)
            UI.show(name)
        end, 2)
    end, 2)
end






--[[ LOADING FROM GLOBAL UI ]]--


function loadEditedArmy(data)
    self.clearButtons()
    
    army = data.armyData
    uiHeight = data.uiHeight
    uiWidth = data.uiWidth
    useDecorativeNames = data.useDecorativeNames
    --YELLOW_STORAGE_SCRIPT = armyData.baseScript -- yes I know I'm assigning a new value to something I marked as a constant, sue me

    local formattedArmyData = getLoadedArmyXML(data.order)

    if formattedArmyData.totalHeight < 3000 then
        self.UI.setAttributes("loadedScrollContainer", {
            noScrollbars = true,
            width = 2030
        })
    else
        self.UI.setAttributes("loadedScrollContainer", {
            noScrollbars = false,
            width = 2050
        })
    end

    self.UI.setAttribute("loadedContainer", "height", formattedArmyData.totalHeight)--formattedArmyData.totalHeight
    self.UI.setValue("loadedContainer", formattedArmyData.xml)
    self.UI.setAttribute("postLoading", "active", "false")
    self.UI.hide("postLoading")
    self.UI.setClass("mainPanel", "hiddenBigWindow")

    self.createButton(CREATE_ARMY_BUTTON)

    Wait.frames(function ()
        UI.hide("mainPanel")
        self.UI.setAttribute("loadedScrollContainer", "active", "true")
        self.UI.setXml(self.UI.getXml())
    end, 2)
end


function getLoadedArmyXML(order)
    local xmlString = ""
    local modelInUnitCount,modelDataForXML,currentUnitContainerHeight,totalUnitContainerHeight
    local maxModelHeight,totalHeight = 0,0
    
    for _,uuid in ipairs(order) do
        local unit = army[uuid]
        local modelGroupString,unitDataString = "",""

        modelInUnitCount = 0
        currentUnitContainerHeight = 0
        totalUnitContainerHeight = 50 -- name

        for modelID,model in pairs(unit.models.models) do
            modelInUnitCount = modelInUnitCount + 1
            modelDataForXML = getModelDataForXML(uuid, modelID, model, unit.weapons)
            modelGroupString = modelGroupString..interpolate(uiTemplates.MODEL_CONTAINER, modelDataForXML)

            if modelDataForXML.height > maxModelHeight then 
                maxModelHeight = modelDataForXML.height 
                currentUnitContainerHeight = modelDataForXML.height
            end

            if modelInUnitCount % 4 == 0 then
                unitDataString = unitDataString..interpolate(uiTemplates.MODEL_GROUPING_CONTAINER, {
                    modelGroups = modelGroupString,
                    width = "1000",
                    height = maxModelHeight
                })

                modelInUnitCount = 0
                maxModelHeight = 0
                modelGroupString = ""
                totalUnitContainerHeight = totalUnitContainerHeight + currentUnitContainerHeight + 20 -- spacing
            end
        end
        
        if modelInUnitCount ~= 0 then
            unitDataString = unitDataString..interpolate(uiTemplates.MODEL_GROUPING_CONTAINER, {
                modelGroups = modelGroupString,
                width = tostring(250 * modelInUnitCount),
                height = maxModelHeight
            })
            maxModelHeight = 0
            totalUnitContainerHeight = totalUnitContainerHeight + currentUnitContainerHeight
        end
        
        totalHeight = totalHeight + totalUnitContainerHeight + 100 -- spacing

        xmlString = xmlString..interpolate(uiTemplates.UNIT_CONTAINER, { 
            unitName = unit.decorativeName and unit.decorativeName or unit.name,
            unitData = unitDataString,
            height = totalUnitContainerHeight
        })
    end

    return { xml = xmlString, totalHeight = totalHeight }
end


function getModelDataForXML(unitID, modelID, model, characteristicProfiles)
    local weaponSection,abilitiesSection = "",""
    local totalCardHeight = 40 -- name
    
    model.weapons = table.sort(model.weapons, function (weaponA,weaponB) --combine(model.weapons, model.assignedWeapons)
        local typeA = trim(characteristicProfiles[weaponA.name].type):gsub("%s+%d?D?d?%/?%d+$", ""):lower()
        local typeB = trim(characteristicProfiles[weaponB.name].type):gsub("%s+%d?D?d?%/?%d+$", ""):lower()
        local typeAVal = WEAPON_TYPE_VALUES[typeA] == nil and 0 or WEAPON_TYPE_VALUES[typeA]
        local typeBVal = WEAPON_TYPE_VALUES[typeB] == nil and 0 or WEAPON_TYPE_VALUES[typeB]
        
        if typeAVal == typeBVal then return weaponA.name < weaponB.name end
        return typeAVal < typeBVal
    end)
    
    if model.weapons ~= nil and #model.weapons > 0 then
        weaponSection = interpolate(uiTemplates.MODEL_DATA, {
            dataType = "Weapons:",
            data = table.concat(map(model.weapons, 
                                    |weapon| weapon.number == 1 and weapon.name or (weapon.number.."x "..weapon.name))
                                ,"\n"),
            height = 37 * #model.weapons
        })
        totalCardHeight = totalCardHeight + (37 * #model.weapons) + (#model.abilities > 0 and 55 or 60) -- title and spacer
    end
    
    if #model.abilities > 0 then
        abilitiesSection = interpolate(uiTemplates.MODEL_DATA, {
            dataType = "Abilities:",
            data = table.concat(model.abilities, "\n"),
            height = 37 * #model.abilities
        })
        totalCardHeight = totalCardHeight + (37 * #model.abilities) + 60 -- title and spacer
    end
    
    return {
        modelName = model.name,
        numberString = model.number > 1 and (tostring(model.number).."x ") or "",
        weapons = weaponSection,
        abilities = abilitiesSection,
        unitID = unitID,
        modelID = modelID,
        height = totalCardHeight
    }
end











--[[ UTILITY FUNCTIONS ]]--


function interpolate(templateString, replacementValues)
    return (templateString:gsub('($%b{})', |w| replacementValues[w:sub(3, -2)] or w)) -- extra parenthesis to prevent double return from gsub
end

function combine(tab1, tab2)
    if tab1 == nil then return clone(tab2) end
    if tab2 == nil then return clone(tab1) end

    local newTab = clone(tab1)

    for _,val in pairs(clone(tab2)) do
        table.insert(newTab, val)
    end

    return newTab
end

function clone(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[clone(orig_key)] = clone(orig_value)
        end
        setmetatable(copy, clone(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)%"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function filter(t, filterFunc)
    local out = {}
  
    for k, v in pairs(clone(t)) do
      if filterFunc(v, k, t) then table.insert(out,v) end
    end
  
    return out
end

function includes (tab, val, checkKey)
    for index, value in ipairs(tab) do
        if checkKey ~= nil then
            if value[checkKey] == val[checkKey] then
                return true
            end
        else
            if value == val then
                return true
            end
        end
    end

    return false
end

function find(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return index
        end
    end

    return -1
end

function filterKeepKeys(t, filterFunc)
    local out = {}

    for k, v in pairs(clone(t)) do
      if filterFunc(v, k, t) then out[k] = v end
    end
  
    return out
end

function map(t, mapFunc)
    local out = {}

    for k,v in pairs(clone(t)) do
        table.insert(out, mapFunc(v,k))
    end

    return out
end

function len(t)
    local count = 0

    for _,_ in pairs(t) do
        count = count + 1
    end

    return count
end

function trim(s)
    return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
end

-- this should only ever be used with one dimensional tables
function tableToFlatString(t)
    return tableToString(t, ", ")
end

-- this is not a particularly robust solution, it is only really for my purposes in this script
-- thus, I very much do not recommend anyone copy this
-- note to self: can make it recursive to traverse multi-dimensional tables but eh
-- warnings: 
--      this assumes a table is array-like if the key "1" exists,
--      this assumes all values are strings
function tableToString(t, delimiter, bracketsOnNewLine, extraTabbing, tabBeforeFirstElement)
    local out = "{ "
    local arrayLike = t[1] ~= nil

    if bracketsOnNewLine ~= nil and bracketsOnNewLine then
        out = out.."\n"..(tabBeforeFirstElement ~= nil and tabBeforeFirstElement or "")
    end
    
    out = out..table.concat(map(t, function (v,k) 
        if arrayLike then return v end
        return k..'="'..v:gsub('"', '\\"')..'"'
    end), delimiter)

    if bracketsOnNewLine ~= nil and bracketsOnNewLine then
        return out.."\n"..(extraTabbing ~= nil and extraTabbing or "").."}"
    end

    return out.." }"
end

function removeModelByID(unitID, modelID)
    loadedData[unitID].models.models[modelID] = nil
end

function findModelWithSameWeapons(unitID, model, ignoreKey, weaponName, adding)
    return filter(loadedData[unitID].models.models, function (checkedModel, key)
        -- solves a few problems
        if checkedModel.assignedWeapons == nil then checkedModel.assignedWeapons = {} end
        if model.assignedWeapons == nil then model.assignedWeapons = {} end
        if ignoreKey ~= nil and ignoreKey == key then return false end
        
        if checkedModel == model or
            checkedModel.name ~= model.name or
            #checkedModel.weapons ~= #model.weapons or
            #checkedModel.abilities ~= #model.abilities or
            #checkedModel.assignedWeapons ~= (#model.assignedWeapons + (adding and 1 or -1)) then 
                return false 
        end
        
        for _,cWeapon in pairs(checkedModel.weapons) do
            if not includes(model.weapons, cWeapon, "name") then return false end
        end
        
        for _,cAbility in pairs(checkedModel.abilities) do
            if not includes(model.abilities, cAbility) then return false end
        end
        
        for _,cAWeapon in pairs(model.assignedWeapons) do
            if cAWeapon.name ~= weaponName and
                 not includes(checkedModel.assignedWeapons, cAWeapon, "name") then return false end
        end
        
        if adding and not includes(checkedModel.assignedWeapons, {name=weaponName}, "name") then return false end

        modelID = key
        return true
    end)[1]
end

function sortModels(tbl, sortFunction)
    local keys = {}

    for key in pairs(tbl) do
        table.insert(keys, key)
    end

    table.sort(keys, function(a, b)
        return sortFunction(tbl[a], tbl[b])
    end)

    return keys
end

function uuid()
    local template ='xxxxxxxx'      
    return string.gsub(template, '[xy]', function (c)          
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)          
        return string.format('%x', v)      
    end)
end

function removeModelByID(unitID, modelID)
    loadedData[unitID].models.models[modelID] = nil
end

function findModelWithSameWeapons(unitID, model, ignoreKey, weaponName, adding)
    return filter(loadedData[unitID].models.models, function (checkedModel, key)
        -- solves a few problems
        if checkedModel.assignedWeapons == nil then checkedModel.assignedWeapons = {} end
        if model.assignedWeapons == nil then model.assignedWeapons = {} end
        if ignoreKey ~= nil and ignoreKey == key then return false end
        
        if checkedModel == model or
            checkedModel.name ~= model.name or
            #checkedModel.weapons ~= #model.weapons or
            #checkedModel.abilities ~= #model.abilities or
            #checkedModel.assignedWeapons ~= (#model.assignedWeapons + (adding and 1 or -1)) then 
                return false 
        end
        
        for _,cWeapon in pairs(checkedModel.weapons) do
            if not includes(model.weapons, cWeapon, "name") then return false end
        end
        
        for _,cAbility in pairs(checkedModel.abilities) do
            if not includes(model.abilities, cAbility) then return false end
        end
        
        for _,cAWeapon in pairs(model.assignedWeapons) do
            if cAWeapon.name ~= weaponName and
                 not includes(checkedModel.assignedWeapons, cAWeapon, "name") then return false end
        end
        
        if adding and not includes(checkedModel.assignedWeapons, {name=weaponName}, "name") then return false end

        modelID = key
        return true
    end)[1]
end

function sortModels(tbl, sortFunction)
    local keys = {}

    for key in pairs(tbl) do
        table.insert(keys, key)
    end

    table.sort(keys, function(a, b)
        return sortFunction(tbl[a], tbl[b])
    end)

    return keys
end