
Script.Load("lua/Weapons/Alien/Ability.lua")

local kRange = 1.4

kOnocideDamage = 800
kOnocideDamageType = kDamageType.Structural
kOnocideRange = 18
kOnocideEnergyCost = 30

class 'Onocide' (Ability)

Onocide.kMapName = "onocide"

// after kDetonateTime seconds the skulk goes 'boom!'
local kDetonateTime = 2.0
local kXenocideSoundName = PrecacheAsset("sound/NS2.fev/alien/common/xenocide_start")


local networkVars = { }
        
local function TriggerOnocide(self, player)

    if Server then
    
        if not self.XenocideSoundName then
            self.XenocideSoundName = Server.CreateEntity(SoundEffect.kMapName)
            self.XenocideSoundName:SetAsset(kXenocideSoundName)
            self.XenocideSoundName:SetParent(self)
            self.XenocideSoundName:Start()
        else     
            self.XenocideSoundName:Start()    
        end
        //StartSoundEffectOnEntity(kXenocideSoundName, player)
        self.xenocideTimeLeft = kDetonateTime
        
    elseif Client and Client.GetLocalPlayer() == player then

        if not self.xenocideGui then
            self.xenocideGui = GetGUIManager():CreateGUIScript("GUIXenocideFeedback")
        end
    
        self.xenocideGui:TriggerFlash(kDetonateTime)
        player:SetCameraShake(.01, 25, kDetonateTime)
        
    end
    
end

local function CleanUI(self)

    if self.xenocideGui ~= nil then
    
        GetGUIManager():DestroyGUIScript(self.xenocideGui)
        self.xenocideGui = nil
        
    end
    
end
    
function Onocide:OnDestroy()

    if Client then
        CleanUI(self)
    end

end

function Onocide:GetDeathIconIndex()
    return kDeathMessageIcon.Xenocide
end

function Onocide:GetEnergyCost(player)

    if not self.xenociding then
        return kOnocideEnergyCost
    else
        return 0
    end
    
end

function Onocide:GetHUDSlot()
    return 3
end

function Onocide:GetRange()
    return kRange
end

function Onocide:OnPrimaryAttack(player)
    
    if player:GetEnergy() >= self:GetEnergyCost() then
    
        if not self.xenociding then

            TriggerOnocide(self, player)
            self.xenociding = true
           
        end
        
    end
    
end

local function StopOnocide(self)
    CleanUI(self)
    self.xenociding = false
end

function Onocide:OnProcessMove(input)

    local player = self:GetParent()
    if self.xenociding then
    
        if player:isa("Commander") then
            StopOnocide(self)
        elseif Server then
        
            self.xenocideTimeLeft = math.max(self.xenocideTimeLeft - input.time, 0)
            
            if self.xenocideTimeLeft == 0 and player:GetIsAlive() then
            
                local shockwaveOrigin = player:GetOrigin()
                local shockwave = CreateEntity(Shockwave.kMapName, shockwaveOrigin, self:GetTeamNumber())
                shockwave:SetOwner(player)

                local direction = GetNormalizedVectorXZ(player:GetViewCoords().zAxis)
                local coords = Coords.GetLookIn(shockwaveOrigin, direction) 
                shockwave:SetCoords(coords)
            
            
                player:TriggerEffects("xenocide", {effecthostcoords = Coords.GetTranslation(player:GetOrigin())})
                
                local hitEntities = GetEntitiesWithMixinWithinRange("Live", player:GetOrigin(), kOnocideRange)
                RadiusDamage(hitEntities, player:GetOrigin(), kOnocideRange, kOnocideDamage, self)
                
                player.spawnReductionTime = 4
                
                player:SetBypassRagdoll(true)

                player:Kill()
                
                if self.XenocideSoundName then
                    self.XenocideSoundName:Stop()
                    self.XenocideSoundName = nil
                end
            end
                if Server and not player:GetIsAlive() and self.XenocideSoundName and self.XenocideSoundName:GetIsPlaying() == true then
                    self.XenocideSoundName:Stop()
                    self.XenocideSoundName = nil                    
                end    

        elseif Client and not player:GetIsAlive() and self.xenocideGui then
            CleanUI(self)
        end
        
    end
    
end

if Server then

    function Onocide:GetDamageType()
    
        if self.xenocideTimeLeft == 0 then
            return kOnocideDamageType
        else
            return kBiteDamageType
        end
        
    end
    
end

Shared.LinkClassToMap("Onocide", Onocide.kMapName, networkVars)