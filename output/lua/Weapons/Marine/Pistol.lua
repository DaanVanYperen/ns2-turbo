// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Pistol.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Marine/ClipWeapon.lua")
Script.Load("lua/PickupableWeaponMixin.lua")
Script.Load("lua/LiveMixin.lua")

class 'Pistol' (ClipWeapon)

Pistol.kMapName = "pistol"

Pistol.kModelName = PrecacheAsset("models/marine/pistol/pistol.model")
local kViewModels = GenerateMarineViewModelPaths("pistol")
local kAnimationGraph = PrecacheAsset("models/marine/pistol/pistol_view.animation_graph")

local kClipSize = 10
local kRange = 200
local kSpread = Math.Radians(0.4)
local kAltSpread = ClipWeapon.kCone0Degrees

local kLaserAttachPoint = "fxnode_laser"

local networkVars =
{
    altMode = "boolean",
    emptyPoseParam = "private float (0 to 1 by 0.01)",
    queuedShots = "private compensated integer (0 to 10)",
    timeAttackStarted = "time",
}

AddMixinNetworkVars(LiveMixin, networkVars)

function Pistol:OnCreate()

    ClipWeapon.OnCreate(self)
    
    InitMixin(self, PickupableWeaponMixin)
    InitMixin(self, LiveMixin)
    
    self.altMode = false
    self.emptyPoseParam = 0

end

local kAimAssistBulletSize = 0.15
function Pistol:GetBulletSize()
    return kAimAssistBulletSize
end


if Client then

    function Pistol:GetBarrelPoint()

        local player = self:GetParent()
        if player then
        
            local origin = player:GetEyePos()
            local viewCoords= player:GetViewCoords()
        
            return origin + viewCoords.zAxis * 0.4 + viewCoords.xAxis * -0.1 + viewCoords.yAxis * -0.2
        end
        
        return self:GetOrigin()
        
    end
    
    function Pistol:OverrideLaserLength()
    
        local parent = self:GetParent()
        
        if parent and parent == Client.GetLocalPlayer() and not parent:GetIsThirdPerson() then
            return 0.3
        end

        return 20
    
    end
    
    function Pistol:OverrideLaserWidth()
    
        local parent = self:GetParent()
        
        if parent and parent == Client.GetLocalPlayer() and not parent:GetIsThirdPerson() then
            return 0.02
        end

        return 0.045
    
    end
    
    function Pistol:OverrideStartColor()
    
        local parent = self:GetParent()
        
        if parent and parent == Client.GetLocalPlayer() and not parent:GetIsThirdPerson() then
            return Color(1, 0, 0, 0.35)
        end

        return Color(1, 0, 0, 0.7)
        
    end
    
    function Pistol:OverrideEndColor()
    
        local parent = self:GetParent()
        
        if parent and parent == Client.GetLocalPlayer() and not parent:GetIsThirdPerson() then
            return Color(1, 0, 0, 0)
        end

        return Color(1, 0, 0, 0.07)
        
    end

    function Pistol:GetLaserAttachCoords()
    
        // return first person coords
        local parent = self:GetParent()
        if parent and parent == Client.GetLocalPlayer() then

            local viewModel = parent:GetViewModelEntity()
        
            if Shared.GetModel(viewModel.modelIndex) then
                
                local viewCoords = parent:GetViewCoords()
                local attachCoords = viewModel:GetAttachPointCoords(kLaserAttachPoint)
                
                attachCoords.origin = viewCoords:TransformPoint(attachCoords.origin)
                
                // when we are not reloading or sprinting then return the view axis (otherwise the laser pointer goes in wrong direction)
                /*
                if not self:GetIsReloading() and not parent:GetIsSprinting() then
                
                    attachCoords.zAxis = viewCoords.zAxis
                    attachCoords.xAxis = viewCoords.xAxis
                    attachCoords.yAxis = viewCoords.yAxis

                else*/
                
                    attachCoords.zAxis = viewCoords:TransformVector(attachCoords.zAxis)
                    attachCoords.xAxis = viewCoords:TransformVector(attachCoords.xAxis)
                    attachCoords.yAxis = viewCoords:TransformVector(attachCoords.yAxis)
                    
                    local zAxis = attachCoords.zAxis
                    attachCoords.zAxis = attachCoords.xAxis
                    attachCoords.xAxis = zAxis
                    
                //end
                
                attachCoords.origin = attachCoords.origin - attachCoords.zAxis * 0.1
                
                return attachCoords
            
            end
            
        end
        
        // return third person coords
        return self:GetAttachPointCoords(kLaserAttachPoint)
        
    end
    
    function Pistol:GetUIDisplaySettings()
        return { xSize = 256, ySize = 256, script = "lua/GUIPistolDisplay.lua" }
    end
    
end

function Pistol:OnMaxFireRateExceeded()
    self.queuedShots = Clamp(self.queuedShots + 1, 0, 10)
end

function Pistol:GetAnimationGraphName()
    return kAnimationGraph
end

function Pistol:GetHasSecondary(player)
    return false
end

function Pistol:GetViewModelName(sex, variant)
    return kViewModels[sex][variant]
end

function Pistol:GetDeathIconIndex()
    return kDeathMessageIcon.Pistol
end

// When in alt-fire mode, keep very accurate
function Pistol:GetInaccuracyScalar(player)
    return ClipWeapon.GetInaccuracyScalar(self, player) * ConditionalValue(self.altMode, .5, 1)
end

function Pistol:GetHUDSlot()
    return kSecondaryWeaponSlot
end

function Pistol:GetPrimaryMinFireDelay()
    return kPistolRateOfFire    
end

function Pistol:GetPrimaryAttackRequiresPress()
    return true
end

function Pistol:GetWeight()
    return kPistolWeight
end

function Pistol:GetClipSize()
    return kClipSize
end

function Pistol:GetSpread()
    return ConditionalValue(self.altMode, kAltSpread, kSpread)
end

function Pistol:GetBulletDamage(target, endPoint)
    return ConditionalValue(self.altMode, kPistolAltDamage, kPistolDamage)
end

function Pistol:GetIsLaserActive()
    return self.altMode and self:GetIsActive()
end

function Pistol:GetIdleAnimations(index)
    local animations = {"idle", "idle_spin", "idle_gangster"}
    return animations[index]
end

function Pistol:OnProcessMove(input)
    ClipWeapon.OnProcessMove(self, input)
    if self.clip ~= 0 then
        self.emptyPoseParam = 0
    else
        self.emptyPoseParam = Clamp(Slerp(self.emptyPoseParam, 1, input.time * 5), 0, 1)
    end
end

function Pistol:UpdateViewModelPoseParameters(viewModel)
    viewModel:SetPoseParam("empty", self.emptyPoseParam)
end

function Pistol:OnTag(tagName)

    PROFILE("Pistol:OnTag")

    ClipWeapon.OnTag(self, tagName)
    
    if tagName == "alt_mode" then
        self.altMode = not self.altMode
    elseif tagName == "idle_spin_start" then
        self:TriggerEffects("pistol_idle_spin")
    elseif tagName == "idle_gangster_start" then
        self:TriggerEffects("pistol_idle_gangster")
    end
    
end

function Pistol:OnUpdateAnimationInput(modelMixin)

    ClipWeapon.OnUpdateAnimationInput(self, modelMixin)

    modelMixin:SetAnimationInput("altMode", self.altMode)
    
end

function Pistol:FirePrimary(player)

    ClipWeapon.FirePrimary(self, player)
    
    self:TriggerEffects("pistol_attack")
    
    TEST_EVENT("Pistol primary attack")
    
end

function Pistol:ModifyDamageTaken(damageTable, attacker, doer, damageType)
    if damageType ~= kDamageType.Corrode then
        damageTable.damage = 0
    end
end

function Pistol:GetCanTakeDamageOverride()
    return self:GetParent() == nil
end

if Server then

    function Pistol:OnKill()
        DestroyEntity(self)
    end
    
    function Pistol:GetSendDeathMessageOverride()
        return false
    end 
    
end

function Pistol:OnDraw(player, previousWeaponMapName)

    ClipWeapon.OnDraw(self, player, previousWeaponMapName)

    self.queuedShots = 0
    
end

function Pistol:OnReload(player)

    ClipWeapon.OnReload(self, player)

    self.queuedShots = 0

end

function Pistol:OnProcessMove(input)

    ClipWeapon.OnProcessMove(self, input)

    if self.queuedShots > 0 then
    
        self.queuedShots = math.max(0, self.queuedShots - 1)
        self:OnPrimaryAttack(self:GetParent())
    
    end

end

Shared.LinkClassToMap("Pistol", Pistol.kMapName, networkVars)