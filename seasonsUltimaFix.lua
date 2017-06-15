----------------------------------------------------------------------------------------------------
-- ULTIMA PATCH SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  Fix Krone Ultima from BM-modding to use Seasons bale wrapping features.
-- Authors:  baron
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, function (...)
local ultimaModNames, seasonsModNames = {"FS17_KroneUltimaCF155XC"}, {"FS17Contest_Seasons", "FS17_Seasons", "FS17_seasons", "FS17_RM_Seasons"}
local envUltima, envSeasons = nil, nil

    for _, name in pairs(ultimaModNames) do
        if g_modIsLoaded[name] then
            envUltima = getfenv(0)[name]
            break
        end
    end

    for _, name in pairs(seasonsModNames) do
        if g_modIsLoaded[name] then
            envSeasons = getfenv(0)[name]
            break
        end
    end

    if envUltima ~= nil and envSeasons ~= nil then
        -- Inject the code required for Seasons when Ultima.wrapperDropBale() is called
        envUltima.Ultima.wrapperDropBale = Utils.prependedFunction(envUltima.Ultima.wrapperDropBale, function (self)  
            local bale = self.wrapperCurrentBale.baleObject

            -- If fillType is silage, the Ultima bale is assumed to be wrapped
            if bale.fillType == FillUtil.FILLTYPE_SILAGE then

                -- wrappingState must be set to 1 for Seasons to recognize the bale as weather protected
                bale.wrappingState = 1 

                -- pass baleObject to Seasons
                self.lastDroppedBale = bale 

                -- pass source fillType to Seasons
                self.baleFillTypeSource = self.wrapperCurrentBale.fillType 

                -- call the necessary Seasons function to enable all mechanics for wrapped bales
                -- self is assumed to be of class BaleWrapper (only needs self.lastDroppedBale and self.baleFillTypeSource)
                envSeasons.ssBaleManager.baleWrapperDoStateChange(self, BaleWrapper.CHANGE_WRAPPER_BALE_DROPPED, nil)
            end
            
        end)
    end
end)

-- In savegame, store and retrieve Bale.wrappingState for bales regardless of Bale.supportsWrapping
-- to enable Seasons to properly recognize wrapped bales from the ultima
-- (another solution would be to have the user attribute supportsWrapping set to true in the i3d)
Bale.getSaveAttributesAndNodes = Utils.overwrittenFunction(Bale.getSaveAttributesAndNodes, function(self, superFunc, nodeIdent)
    local attributes, nodes = superFunc(self, nodeIdent)

    if not self.supportsWrapping and self.wrappingState ~= nil then
        attributes = attributes .. ' wrappingState="'..tostring(self.wrappingState)..'"'
    end
    
    return attributes, nodes
end)

Bale.loadFromAttributesAndNodes = Utils.overwrittenFunction(Bale.loadFromAttributesAndNodes, function(self, superFunc, xmlFile, key, resetVehicles)
    local state = superFunc(self, xmlFile, key, resetVehicles)

    self.wrappingState = getXMLFloat(xmlFile, key.."#wrappingState")

    return state
end)