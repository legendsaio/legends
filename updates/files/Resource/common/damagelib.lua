-- ../../LuaDamageLib/data/annie.lua
do
    local damage_map = DamageLib.GetDamageFunctionMap( )
    
    local q_hash = Game.spelldataHash( "AnnieQ" )
    local w_hash = Game.spelldataHash( "AnnieW" )
    local r_hash = Game.spelldataHash( "AnnieR" )
    
    local total_damage = Game.fnvhash("TotalDamage")
    local initial_burst_damage = Game.fnvhash( "InitialBurstDamage" )
    local horizon_buff_hash = Game.fnvhash( "4628marker" )
    local crown_buff_hash = Game.fnvhash( "4644shield" )
    
    damage_map[q_hash] = function( source, target, bRawDamage, stage )
        local spell_entry = source.spellBook:GetSpellEntry( SpellSlot.Q )
    
        if spell_entry.level < 1 or spell_entry.level > 5 then return 0 end
    
        local raw_damage = spell_entry:GetCalculateInfo( source, total_damage, SpellSlot.Q )
        local horizon_buff = target:FindBuff( horizon_buff_hash )
        local crown_buff = target:FindBuff( crown_buff_hash )
        if horizon_buff and horizon_buff.isValid
        then
            raw_damage = raw_damage + raw_damage*0.1
        end
    
        if crown_buff and crown_buff.isValid
        then
            raw_damage = raw_damage - raw_damage * 0.75
        end
    
        return bRawDamage and raw_damage or DamageLib.CalculateMagicalDamage( source, target, raw_damage )
    end
    
    damage_map[w_hash] = function( source, target, bRawDamage, stage )
        local spell_entry = source.spellBook:GetSpellEntry( SpellSlot.W )
    
        if spell_entry.level < 1 or spell_entry.level > 5 then return 0 end
    
        local raw_damage = spell_entry:GetCalculateInfo( source, total_damage, SpellSlot.W )
        local horizon_buff = target:FindBuff( horizon_buff_hash )
        local crown_buff = target:FindBuff( crown_buff_hash )
    
        if horizon_buff and horizon_buff.isValid
        then
            raw_damage = raw_damage + raw_damage * 0.1
        end
    
        if crown_buff and crown_buff.isValid
        then
            raw_damage = raw_damage - raw_damage * 0.75
        end
    
        --print( "raw_w: ", raw_damage )
        return bRawDamage and raw_damage or DamageLib.CalculateMagicalDamage( source, target, raw_damage )
    end
    
    local tibbers_aura_damage_hash = Game.fnvhash( "TibbersAuraDamage" )
    local tibbers_aa_damage_hash = Game.fnvhash( "TibbersAADamage" )
    damage_map[r_hash] = function( source, target, bRawDamage, stage )
        local spell_entry = source.spellBook:GetSpellEntry( SpellSlot.R )
    
        if spell_entry.level < 1 or spell_entry.level > 3 then return 0 end
    
        local raw_damage = spell_entry:GetCalculateInfo( source, initial_burst_damage, SpellSlot.R )
        local horizon_buff = target:FindBuff( horizon_buff_hash )
        local crown_buff = target:FindBuff( crown_buff_hash )
    
        local tibbers_aura_damage = spell_entry:GetCalculateInfo( source, tibbers_aura_damage_hash, SpellSlot.R )
        local tibbers_aa_damage = spell_entry:GetCalculateInfo( source, tibbers_aa_damage_hash, SpellSlot.R )
    
        raw_damage = raw_damage + ( tibbers_aura_damage * 1 )
        if not target.canMove or source:FindBuff( anniepassiveprimed ) ~= nil
        then
            raw_damage = raw_damage + ( tibbers_aa_damage * 1 )
        end
    
        if horizon_buff and horizon_buff.isValid
        then
            raw_damage = raw_damage + raw_damage*0.1
        end
    
        if crown_buff and crown_buff.isValid
        then
            raw_damage = raw_damage - raw_damage * 0.75
        end
    
        return bRawDamage and raw_damage or DamageLib.CalculateMagicalDamage( source, target, raw_damage )
    end
    end
    
    -- ../../LuaDamageLib/data/camille.lua
    do
    -- Q1
    local CamilleQSpellDataHash = Game.spelldataHash("CamilleQ")
    local CamilleQHash = Game.fnvhash("CamilleQ")
    local BonusDamageHash = Game.fnvhash("BonusDamage")
    
    -- Q2
    local CamilleQ2SpellDataHash = Game.spelldataHash("CamilleQ2")
    local CamilleQ2Hash = Game.fnvhash("CamilleQ2")
    local EmpoweredBonusDamageHash = Game.fnvhash("EmpoweredBonusDamage")
    local DamageConversionPercentageHash = Game.fnvhash("DamageConversionPercentage")
    local camilleQ2chargedBuffHash = Game.fnvhash("camilleqprimingcomplete")
    
    -- W
    local CamilleWSpellDataHash = Game.spelldataHash("CamilleW")
    local CamilleWHash = Game.fnvhash("CamilleW")
    local BaseDamageTotalHash = Game.fnvhash("BaseDamageTotal")
    local OuterEdgeTooltipHash = Game.fnvhash("OuterEdgeTooltip")
    
    -- E
    local CamilleESpellDataHash = Game.spelldataHash("CamilleE")
    local CamilleEHash = Game.fnvhash("CamilleE")
    local CamilleETotalDamageHash = Game.fnvhash("TotalDamage")
    
    -- E2
    local CamilleE2SpellDataHash = Game.spelldataHash("CamilleEDash2")
    local CamilleE2Hash = Game.fnvhash("CamilleEDash2")
    local CamilleE2TotalDamageHash = Game.fnvhash("TotalDamage")
    
    local damageMap = DamageLib.GetDamageFunctionMap()
    
    -- local dmg = Game.localPlayer:GetSpellEntry(SpellSlot.Q):GetCalculateInfo(Game.localPlayer, BonusDamageHash, SpellSlot.Q)
    -- print(Game.localPlayer:GetSpellEntry(SpellSlot.Q):GetName(), dmg, DamageLib.CalculateMagicalDamage(Game.localPlayer, Game.localPlayer, dmg))
    
    damageMap[CamilleQSpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(CamilleQHash) -- This uses fnv hash
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        local rawDamage = entry:GetCalculateInfo(source, BonusDamageHash, slot)
    
        if useRawDamage or not target or not target:IsValid() then
            return rawDamage
        end
    
        return DamageLib.CalculatePhysicalDamage(source, target, rawDamage) + DamageLib.CalculateAutoAttackDamage(source, target)
    end
    
    damageMap[CamilleQ2SpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(CamilleQ2Hash) -- This uses fnv hash
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        local spellData = Game.GetSpellByHash(CamilleQSpellDataHash)
        local dmgToGet = BonusDamageHash
    
        if source:FindBuff(camilleQ2chargedBuffHash) ~= nil then
            dmgToGet = EmpoweredBonusDamageHash
        end
    
        local rawDamage = entry:GetCalculateInfo(source, dmgToGet, slot, spellData)
    
        if useRawDamage or not target or not target:IsValid() then
            return rawDamage
        end
    
        return DamageLib.CalculatePhysicalDamage(source, target, rawDamage) + DamageLib.CalculateAutoAttackDamage(source, target)
    end
    
    damageMap[CamilleWSpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(CamilleWHash)
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        local rawDamage = entry:GetCalculateInfo(source, BaseDamageTotalHash, slot)
        local bonusDamage = entry:GetCalculateInfo(source, OuterEdgeTooltipHash, slot)
        if useRawDamage or not target or not target:IsValid() then
            return rawDamage
        end
    
        local distance = source.position:Distance(target.position)
        if distance > 330 then
            return DamageLib.CalculatePhysicalDamage(source, target, rawDamage) + DamageLib.CalculatePhysicalDamage(source, target, (bonusDamage * target.maxHp))
        end
    
        return DamageLib.CalculatePhysicalDamage(source, target, rawDamage)
    end
    
    damageMap[CamilleESpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(CamilleEHash) -- This uses fnv hash
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        if not stage or stage ~= 3 then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        local rawDamage = entry:GetCalculateInfo(source, CamilleE2TotalDamageHash, slot)
    
        if useRawDamage or not target or not target:IsValid() then
            return rawDamage
        end
    
        return DamageLib.CalculatePhysicalDamage(source, target, rawDamage)
    end
    
    damageMap[CamilleE2SpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(CamilleE2Hash) -- This uses fnv hash
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        local spellData = Game.GetSpellByHash(CamilleESpellDataHash)
        local rawDamage = entry:GetCalculateInfo(source, CamilleE2TotalDamageHash, slot, spellData)
    
        if useRawDamage or not target or not target:IsValid() then
            return rawDamage
        end
    
        return DamageLib.CalculatePhysicalDamage(source, target, rawDamage)
    end
    
    end
    
    -- ../../LuaDamageLib/data/fiora.lua
    do
    -- REGISTER SPELLS DAMAGE
    
    -- print(Game.localPlayer:GetSpellEntry(SpellSlot.Passive):GetName())
    -- Game.localPlayer:GetSpellEntry(SpellSlot.Passive):PrintTooltip(false) --test with true and false depends on spell
    
    local FioraPassiveSpellDataHash = Game.spelldataHash("FioraPassive") -- Spell Data hash is used as key for damageMap
    local FioraPassiveHash = Game.fnvhash("FioraPassive") -- FNV hash is used by AIBaseClient:GetSpellSlot(spellHash) function
    local PassiveDamageTotalHash = Game.fnvhash("PassiveDamageTotal")
    
    local FioraQSpellDataHash = Game.spelldataHash("FioraQ")
    local FioraQHash = Game.fnvhash("FioraQ")
    local TotalDamageHash = Game.fnvhash("TotalDamage")
    local damageMap = DamageLib.GetDamageFunctionMap()
    
    local FioraWSpellDataHash = Game.spelldataHash("FioraW")
    local FioraWHash = Game.fnvhash("FioraW")
    local StabDamageHash = Game.fnvhash("StabDamage")
    
    local FioraESpellDataHash = Game.spelldataHash("FioraE")
    local FioraEHash = Game.fnvhash("FioraE")
    
    local FioraRSpellDataHash = Game.spelldataHash("FioraR")
    local FioraRHash = Game.fnvhash("FioraR")
    local FioraRDamageHash = Game.fnvhash("RDamageTotal")
    
    -- local dmg = Game.localPlayer:GetSpellEntry(SpellSlot.Q):GetCalculateInfo(Game.localPlayer, TotalDamageHash, SpellSlot.Q)
    -- print(Game.localPlayer:GetSpellEntry(SpellSlot.Q):GetName(), dmg, DamageLib.CalculateMagicalDamage(Game.localPlayer, Game.localPlayer, dmg))
    
    damageMap[FioraPassiveSpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(FioraPassiveHash) -- This uses fnv hash
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        if target and target:IsValid() then
            local passiveDamage = entry:GetCalculateInfo(source, PassiveDamageTotalHash, slot)
            return target.maxHp * passiveDamage
        else
            return 0
        end
    end
    
    damageMap[FioraQSpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(FioraQHash) -- This uses fnv hash
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        local rawDamage = entry:GetCalculateInfo(source, TotalDamageHash, slot)
    
        if useRawDamage or not target or not target:IsValid() then
            return rawDamage
        end
    
        return DamageLib.CalculatePhysicalDamage(source, target, rawDamage)
    end
    
    damageMap[FioraWSpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(FioraWHash)
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        local rawDamage = entry:GetCalculateInfo(source, StabDamageHash, slot)
    
        if useRawDamage or not target or not target:IsValid() then
            return rawDamage
        end
    
        return DamageLib.CalculateMagicalDamage(source, target, rawDamage)
    end
    
    damageMap[FioraESpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(FioraEHash)
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        if target and target:IsValid() then
            local AAdamage = DamageLib.CalculateAutoAttackDamage(source, target)
            local AAmodifier = entry.fValue[4]
            return AAdamage * (AAmodifier / 100)
        else
            return 0
        end
    end
    
    damageMap[FioraRSpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(FioraPassiveHash)
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        if target and target:IsValid() then
            local rDamage = entry:GetCalculateInfo(source, FioraRDamageHash, slot)
            return target.maxHp * rDamage
        else
            return 0
        end
    end
    
    -- local tsTarget = TargetSelector.GetTarget(500, DamageType.Physical);
    -- print("E Damage", Champions.E:GetDamage(tsTarget))
    
    end
    
    -- ../../LuaDamageLib/data/gangplank.lua
    do
    -- REGISTER SPELLS DAMAGE
    -- print(Game.localPlayer:GetSpellEntry(SpellSlot.R):GetName())
    -- Game.localPlayer:GetSpellEntry(SpellSlot.R):PrintTooltip(false) --test with true and false depends on spell
    
    local GangplankPassiveSpellDataHash = Game.spelldataHash("GangplankPassive") -- Spell Data hash is used as key for damageMap
    local GangplankPassiveHash = Game.fnvhash("GangplankPassive") -- FNV hash is used by AIBaseClient:GetSpellSlot(spellHash) function
    local PassiveDamageTotalHash = Game.fnvhash("TotalDamage")
    
    local GangplankQSpellDataHash = Game.spelldataHash("GangplankQ")
    local GangplankQHash = Game.fnvhash("GangplankQ")
    local TotalDamageHash = Game.fnvhash("TotalDamage")
    local damageMap = DamageLib.GetDamageFunctionMap()
    
    local GangplankWSpellDataHash = Game.spelldataHash("GangplankW")
    
    local GangplankESpellDataHash = Game.spelldataHash("GangplankE")
    local GangplankEHash = Game.fnvhash("GangplankE")
    
    local GangplankRSpellDataHash = Game.spelldataHash("GangplankR")
    local GangplankRHash = Game.fnvhash("GangplankR")
    local GangplankRDamageHash = Game.fnvhash("OneWaveDamage")
    
    
    damageMap[GangplankPassiveSpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(GangplankPassiveHash) -- This uses fnv hash
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        if target and target:IsValid() then
            local passiveDamage = entry:GetCalculateInfo(source, PassiveDamageTotalHash, slot)
            return passiveDamage
        else
            return 0
        end
    end
    
    damageMap[GangplankQSpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(GangplankQHash) -- This uses fnv hash
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        local rawDamage = entry:GetCalculateInfo(source, TotalDamageHash, slot)
    
        if useRawDamage or not target or not target:IsValid() then
            return rawDamage
        end
    
        return DamageLib.CalculatePhysicalDamage(source, target, rawDamage)
    end
    
    damageMap[GangplankWSpellDataHash] = function(source, target, useRawDamage, stage)
        return 0
    end
    
    damageMap[GangplankESpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(GangplankEHash)
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        local rawDamage = 80 + 25 * (entry.level - 1) -- extra hero damage: Effect2Amount
        if target.isHero then
            rawDamage = 80 + 25 * (entry.level - 1)
        else
            rawDamage = 0
        end
    
        if useRawDamage or not target or not target:IsValid() then
            return rawDamage
        end
    
        -- Add Ignores 40% of target's armor
        return DamageLib.CalculatePhysicalDamage(source, target, rawDamage)
    end
    
    damageMap[GangplankRSpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(GangplankRHash)
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        local rawDamage = entry:GetCalculateInfo(source, GangplankRDamageHash, slot)
    
        if useRawDamage or not target or not target:IsValid() then -- 1 wave raw damage x 3 true damage for upgraded R
            return rawDamage
        end
    
        return DamageLib.CalculateMagicalDamage(source, target, rawDamage)
    end
    
    end
    
    -- ../../LuaDamageLib/data/nilah.lua
    do
    -- REGISTER SPELLS DAMAGE
    -- print(Game.localPlayer:GetSpellEntry(SpellSlot.R):GetName())
    -- Game.localPlayer:GetSpellEntry(SpellSlot.R):PrintTooltip(false) --test with true and false depends on spell
    
    local NilahQSpellDataHash = Game.spelldataHash("NilahQ")
    local NilahQHash = Game.fnvhash("NilahQ")
    local DamageCalc = Game.fnvhash("DamageCalc")
    local damageMap = DamageLib.GetDamageFunctionMap()
    
    local NilahWSpellDataHash = Game.spelldataHash("NilahW")
    
    local NilahESpellDataHash = Game.spelldataHash("NilahE")
    local NilahEHash = Game.fnvhash("NilahE")
    local DashDamage = Game.fnvhash("DashDamage")
    
    local NilahRSpellDataHash = Game.spelldataHash("NilahR")
    local NilahRHash = Game.fnvhash("NilahR")
    local DamagePerTickCalcTooltip = Game.fnvhash("DamagePerTickCalcTooltip")
    local DamageCalc2 = Game.fnvhash("DamageCalc")
    
    -- print(Game.localPlayer:GetSpellEntry(SpellSlot.R):GetName())
    -- Game.localPlayer:GetSpellEntry(SpellSlot.R):PrintTooltip(false) --test with true and false depends on spell
    -- local dmg = Game.localPlayer:GetSpellEntry(SpellSlot.R):GetCalculateInfo(Game.localPlayer, DamageCalc2, SpellSlot.R)
    -- print(Game.localPlayer:GetSpellEntry(SpellSlot.R):GetName(), dmg, DamageLib.CalculatePhysicalDamage(Game.localPlayer, Game.localPlayer, dmg))
    
    
    damageMap[NilahQSpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(NilahQHash) -- This uses fnv hash
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        local rawDamage = entry:GetCalculateInfo(source, DamageCalc, slot)
    
        if useRawDamage or not target or not target:IsValid() then
            return rawDamage
        end
    
        return DamageLib.CalculatePhysicalDamage(source, target, rawDamage)
    end
    
    damageMap[NilahWSpellDataHash] = function(source, target, useRawDamage, stage)
        return 0
    end
    
    damageMap[NilahESpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(NilahEHash) -- This uses fnv hash
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        local rawDamage = entry:GetCalculateInfo(source, DashDamage, slot)
    
        if useRawDamage or not target or not target:IsValid() then
            return rawDamage
        end
    
        return DamageLib.CalculatePhysicalDamage(source, target, rawDamage)
    end
    
    
    damageMap[NilahRSpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(NilahRHash)
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        local rawDamage = entry:GetCalculateInfo(source, DamagePerTickCalcTooltip, slot)
        local rawDamage2 = entry:GetCalculateInfo(source, DamageCalc2, slot)
        if useRawDamage or not target or not target:IsValid() then -- 1 wave raw damage x 3 true damage for upgraded R
            return rawDamage + rawDamage2
        end
    
        return DamageLib.CalculateMagicalDamage(source, target, rawDamage + rawDamage2)
    end
    
    end
    
    -- ../../LuaDamageLib/data/qiyana.lua
    do
    -- REGISTER SPELLS DAMAGE
    -- print(Game.localPlayer:GetSpellEntry(SpellSlot.Q):GetName())
    local damageMap = DamageLib.GetDamageFunctionMap()
    
    
    local QiyanaPassiveSpellDataHash = Game.spelldataHash("QiyanaPassive") -- Spell Data hash is used as key for damageMap
    local QiyanaPassiveHash = Game.fnvhash("QiyanaPassive") -- FNV hash is used by AIBaseClient:GetSpellSlot(spellHash) function
    local PFinalDamage = Game.fnvhash("FinalDamage")
    
    ----------Q
    local QiyanaQSpellDataHash = Game.spelldataHash("QiyanaQ")
    local QiyanaQSpell2DataHash = Game.spelldataHash("QiyanaQ")
    local QiyanaQHash = Game.fnvhash("QiyanaQ")
    -----
    local QVanillaDamage = Game.fnvhash("VanillaDamage")
    local QEnchantedDamage = Game.fnvhash("EnchantedDamage")
    local QTremorDamage = Game.fnvhash("TremorDamage")
    -----
    ----------Q2
    local QiyanaQ2SpellDataHash = Game.spelldataHash("QiyanaQ_Grass")
    local QiyanaQ3SpellDataHash = Game.spelldataHash("QiyanaQ_Water")
    local QiyanaQ4SpellDataHash = Game.spelldataHash("QiyanaQ_Rock")
    local QiyanaQ2Hash = Game.fnvhash("QiyanaQ_Grass")
    local QiyanaQ3Hash = Game.fnvhash("QiyanaQ_Water")
    local QiyanaQ4Hash = Game.fnvhash("QiyanaQ_Rock")
    -----
    local QEnchantedDamage = Game.fnvhash("EnchantedDamage")
    -----
    ----------W
    local QiyanaWSpellDataHash = Game.spelldataHash("QiyanaW")
    local QiyanaWHash = Game.fnvhash("QiyanaW")
    -----
    local WOnHitDamage = Game.fnvhash("OnHitDamage")
    ----------E
    local QiyanaESpellDataHash = Game.spelldataHash("QiyanaE")
    local QiyanaEHash = Game.fnvhash("QiyanaE")
    -----
    local EDamage = Game.fnvhash("Damage")
    -----
    
    ----------R
    local QiyanaRSpellDataHash = Game.spelldataHash("QiyanaR")
    local QiyanaRHash = Game.fnvhash("QiyanaR")
    -----
    local RDamage = Game.fnvhash("Damage")
    local RMissingHealthDamageRock = Game.fnvhash("MissingHealthDamageRock") ---- 0.1
    
    
    -- Game.localPlayer:GetSpellEntry(SpellSlot.Q):PrintTooltip(false) --test with true and false depends on spell
    -- local dmg = Game.localPlayer:GetSpellEntry(SpellSlot.Q):GetCalculateInfo(Game.localPlayer, QEnchantedDamage, SpellSlot.Q)
    -- print(Game.localPlayer:GetSpellEntry(SpellSlot.Q):GetName(), dmg, DamageLib.CalculatePhysicalDamage(Game.localPlayer, Game.localPlayer, dmg))
    
    
    
    ----- P
    damageMap[QiyanaPassiveSpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(QiyanaPassiveHash) -- This uses fnv hash
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        if target and target:IsValid() then
            local passiveDamage = entry:GetCalculateInfo(source, PFinalDamage, slot)
            return passiveDamage
        else
            return 0
        end
    end
    
    
    ----- Q
    damageMap[QiyanaQSpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(QiyanaQHash) -- This uses fnv hash
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        local rawDamage = entry:GetCalculateInfo(source, QVanillaDamage, slot)
        local enchantedDamage = entry:GetCalculateInfo(source, QEnchantedDamage, slot)
        if enchantedDamage > rawDamage then
            rawDamage = enchantedDamage
        end
    
    
        if useRawDamage or not target or not target:IsValid() then
            return rawDamage
        end
    
        if stage == 4 then -- Rock, extra dmg only
            rawDamage = entry:GetCalculateInfo(source, QTremorDamage, slot)
            return DamageLib.CalculatePhysicalDamage(source, target, rawDamage)
        end
    
        return DamageLib.CalculatePhysicalDamage(source, target, rawDamage)
    end
    
    ----- Q2
    damageMap[QiyanaQ2SpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(QiyanaQ2Hash) -- This uses fnv hash
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        local rawDamage = entry:GetCalculateInfo(source, QVanillaDamage, slot)
        local enchantedDamage = entry:GetCalculateInfo(source, QEnchantedDamage, slot)
        if enchantedDamage > rawDamage then
            rawDamage = enchantedDamage
        end
    
    
        if useRawDamage or not target or not target:IsValid() then
            return rawDamage
        end
    
        if stage == 4 then -- Rock, extra dmg only
            rawDamage = entry:GetCalculateInfo(source, QTremorDamage, slot)
            return DamageLib.CalculatePhysicalDamage(source, target, rawDamage)
        end
    
        return DamageLib.CalculatePhysicalDamage(source, target, rawDamage)
    end
    ----- Q3
    damageMap[QiyanaQ3SpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(QiyanaQ3Hash) -- This uses fnv hash
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        local rawDamage = entry:GetCalculateInfo(source, QVanillaDamage, slot)
        local enchantedDamage = entry:GetCalculateInfo(source, QEnchantedDamage, slot)
        if enchantedDamage > rawDamage then
            rawDamage = enchantedDamage
        end
    
    
        if useRawDamage or not target or not target:IsValid() then
            return rawDamage
        end
    
        if stage == 4 then -- Rock, extra dmg only
            rawDamage = entry:GetCalculateInfo(source, QTremorDamage, slot)
            return DamageLib.CalculatePhysicalDamage(source, target, rawDamage)
        end
    
        return DamageLib.CalculatePhysicalDamage(source, target, rawDamage)
    end
    ----- Q4
    damageMap[QiyanaQ4SpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(QiyanaQ4Hash) -- This uses fnv hash
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        local rawDamage = entry:GetCalculateInfo(source, QVanillaDamage, slot)
        local enchantedDamage = entry:GetCalculateInfo(source, QEnchantedDamage, slot)
        if enchantedDamage > rawDamage then
            rawDamage = enchantedDamage
        end
    
    
        if useRawDamage or not target or not target:IsValid() then
            return rawDamage
        end
    
        if stage == 4 then -- Rock, extra dmg only
            rawDamage = entry:GetCalculateInfo(source, QTremorDamage, slot)
            return DamageLib.CalculatePhysicalDamage(source, target, rawDamage)
        end
    
        return DamageLib.CalculatePhysicalDamage(source, target, rawDamage)
    end
    ----- W
    damageMap[QiyanaWSpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(QiyanaWHash) -- This uses fnv hash
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        local rawDamage = entry:GetCalculateInfo(source, WOnHitDamage, slot)
    
        if useRawDamage or not target or not target:IsValid() then
            return rawDamage
        end
    
        return DamageLib.CalculatePhysicalDamage(source, target, rawDamage)
    end
    ----- E
    damageMap[QiyanaESpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(QiyanaEHash) -- This uses fnv hash
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        local rawDamage = entry:GetCalculateInfo(source, EDamage, slot)
    
        if useRawDamage or not target or not target:IsValid() then
            return rawDamage
        end
    
        return DamageLib.CalculatePhysicalDamage(source, target, rawDamage)
    end
    ----- R
    damageMap[QiyanaRSpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(QiyanaRHash)
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        local rawDamage = entry:GetCalculateInfo(source, RDamage, slot)
        local percDamage = entry:GetCalculateInfo(source, RMissingHealthDamageRock, slot)
    
        if target then
            rawDamage = rawDamage + target.totalMaxHealth * percDamage
        end
        if useRawDamage or not target or not target:IsValid() then -- 1 wave raw damage x 3 true damage for upgraded R
            return rawDamage
        end
    
        return DamageLib.CalculateMagicalDamage(source, target, rawDamage)
    end
    
    end
    
    -- ../../LuaDamageLib/data/riven.lua
    do
    local damageMap = DamageLib.GetDamageFunctionMap()
    
    local RivenPassiveSpellDataHash = Game.spelldataHash("RivenPassive") -- Spell Data hash is used as key for damageMap
    local RivenPassiveHash = Game.fnvhash("RivenPassive") -- FNV hash is used by AIBaseClient:GetSpellSlot(spellHash) function
    local RivenPassiveTotalDamageHash = Game.fnvhash("TotalDamage")
    
    local RivenQSpellDataHash = Game.spelldataHash("RivenTriCleave")
    local RivenQHash = Game.fnvhash("RivenTriCleave")
    local FirstSlashDamageHash = Game.fnvhash("FirstSlashDamage")
    
    local RivenWSpellDataHash = Game.spelldataHash("RivenMartyr")
    local RivenWHash = Game.fnvhash("RivenMartyr")
    local TotalDamageHash = Game.fnvhash("TotalDamage")
    
    local RivenRSpellDataHash = Game.spelldataHash("RivenFengShuiEngine")
    local RivenRHash = Game.fnvhash("RivenFengShuiEngine")
    local RivenRebonusDamageHash = Game.fnvhash("BonusAD")
    
    local RivenR2SpellDataHash = Game.spelldataHash("RivenIzunaBlade")
    local RivenR2Hash = Game.fnvhash("RivenIzunaBlade")
    
    
    damageMap[RivenPassiveSpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(RivenPassiveHash) -- This uses fnv hash
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        local rawDamage = entry:GetCalculateInfo(source, RivenPassiveTotalDamageHash, slot)
    
        if useRawDamage or not target or not target:IsValid() then
            return rawDamage
        end
    
        if target and target:IsValid() then
            if source:FindBuff("RivenPassiveAABoost") and (not stage or stage == 0) then
                local AAdamage = DamageLib.CalculateAutoAttackDamage(source, target)
                local passiveDamage = DamageLib.CalculatePhysicalDamage(source, target, rawDamage)
                return AAdamage + passiveDamage
            elseif stage and stage == 1 then
                local AAdamage = DamageLib.CalculateAutoAttackDamage(source, target)
                local passiveDamage = DamageLib.CalculatePhysicalDamage(source, target, rawDamage)
                return AAdamage + passiveDamage
            elseif stage and stage == 2 then
                local AAdamage = DamageLib.CalculateAutoAttackDamage(source, target)
                if source:FindBuff("RivenPassiveAABoost") then
                    local passiveDamage = DamageLib.CalculatePhysicalDamage(source, target, rawDamage)
                    return AAdamage + passiveDamage
                else
                    return AAdamage
                end
            else
                return 0
            end
        else
            return rawDamage
        end
    
        return DamageLib.CalculatePhysicalDamage(source, target, rawDamage)
    end
    
    damageMap[RivenQSpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(RivenQHash) -- This uses fnv hash
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        local rawDamage = entry:GetCalculateInfo(source, FirstSlashDamageHash, slot)
    
        if useRawDamage or not target or not target:IsValid() then
            return rawDamage
        end
    
        return DamageLib.CalculatePhysicalDamage(source, target, rawDamage)
    end
    
    damageMap[RivenWSpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(RivenWHash) -- This uses fnv hash
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        local rawDamage = entry:GetCalculateInfo(source, TotalDamageHash, slot)
    
        if useRawDamage or not target or not target:IsValid() then
            return rawDamage
        end
    
        return DamageLib.CalculatePhysicalDamage(source, target, rawDamage)
    end
    
    damageMap[RivenRSpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(RivenRHash) -- This uses fnv hash
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        local rawDamage = entry:GetCalculateInfo(source, RivenRebonusDamageHash, slot)
    
        if useRawDamage or not target or not target:IsValid() or not stage or stage < 2 then
            return rawDamage
        end
    
        if target and target:IsValid() and stage and stage > 1 then
            -- stage => expected final enemy Health after Combo damage, for Riven script
            local missinghealth = (target.maxHp - stage) / target.maxHp > 0.75 and 0.75 or (target.maxHp - stage) / target.maxHp
            local healthPercentBonus = missinghealth * 2.667
            local RawDamage = { 100, 150, 200 }
            local totalRawDamage = RawDamage[source:GetSpellEntry(slot).level] + 0.6 * source.charIntermediate.flatPhysicalDamageMod
            return DamageLib.CalculatePhysicalDamage(source, target, totalRawDamage * (1 + healthPercentBonus))
        else
            return 0
        end
    end
    
    damageMap[RivenR2SpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(RivenR2Hash) -- This uses fnv hash
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        if target and target:IsValid() and stage and stage >= 2 then
            -- stage => expected final enemy Health after Combo damage, for Riven script
            local missinghealth = (target.maxHp - stage) / target.maxHp > 0.75 and 0.75 or (target.maxHp - stage) / target.maxHp
            local healthPercentBonus = missinghealth * 2.667
            local RawDamage = { 100, 150, 200 }
            local totalRawDamage = RawDamage[source:GetSpellEntry(slot).level] + 0.6 * source.charIntermediate.flatPhysicalDamageMod
            return DamageLib.CalculatePhysicalDamage(source, target, totalRawDamage * (1 + healthPercentBonus))
        elseif target and target:IsValid() and (not stage or stage < 2) then
            -- normal R2 damage, for use on Evade, etc
            local missinghealth = (target.maxHp - target.hp) / target.maxHp > 0.75 and 0.75 or (target.maxHp - target.hp) / target.maxHp
            local healthPercentBonus = missinghealth * 2.667
            local RawDamage = { 100, 150, 200 }
            local totalRawDamage = RawDamage[source:GetSpellEntry(slot).level] + 0.6 * source.charIntermediate.flatPhysicalDamageMod
            return DamageLib.CalculatePhysicalDamage(source, target, totalRawDamage * (1 + healthPercentBonus))
        else
            return 0
        end
    end
    
    end
    
    -- ../../LuaDamageLib/data/tahmkench.lua
    do
     
        local damage_map = DamageLib.GetDamageFunctionMap( )
    
        local q_hash = Game.spelldataHash( "TahmKenchQ" )
        local w_hash = Game.spelldataHash( "TahmKenchW" )
        local r_hash = Game.spelldataHash( "TahmKenchRWrapper" )
    
        --w_entry:PrintTooltip( false )
        local crown_buff_hash = Game.fnvhash( "4644shield" )
    
        local total_damage = Game.fnvhash( "TotalDamage" )
        --local extra_damage = Game.fnvhash( "Spell.TahmKenchPassive:TotalDamage" )
        damage_map[q_hash] = function( source, target, bRawDamage, stage )
            local spell_entry = source.spellBook:GetSpellEntry( SpellSlot.Q )
            local spell_entry_passive = source.spellBook:GetSpellEntry( SpellSlot.Passive )
    
            if spell_entry.level < 1 or spell_entry.level > 5 then return 0 end
    
            local raw_damage = spell_entry:GetCalculateInfo( source, total_damage, SpellSlot.Q )
            local raw_extra_damage = spell_entry_passive:GetCalculateInfo( source, total_damage, SpellSlot.Passive )
    
            local crown_buff = target:FindBuff( crown_buff_hash )
            if crown_buff and crown_buff.isValid
            then
                raw_damage = raw_damage - raw_damage * 0.75
            end
    
            return bRawDamage and raw_damage or DamageLib.CalculateMagicalDamage( source, target, target.isHero and raw_damage + raw_extra_damage or raw_damage )
        end
    
        damage_map[w_hash] = function( source, target, bRawDamage, stage )
            local spell_entry = source.spellBook:GetSpellEntry( SpellSlot.W )
    
            if spell_entry.level < 1 or spell_entry.level > 5 then return 0 end
    
            local raw_damage = spell_entry:GetCalculateInfo( source, total_damage, SpellSlot.W )
    
            local crown_buff = target:FindBuff( crown_buff_hash )
            if crown_buff and crown_buff.isValid
            then
                raw_damage = raw_damage - raw_damage * 0.75
            end
    
            return bRawDamage and raw_damage or DamageLib.CalculateMagicalDamage( source, target, raw_damage )
        end
    
        local base_damage = Game.fnvhash( "BaseDamage" )
        local percent_hpdamage = Game.fnvhash( "PercentHPDamage" )
        damage_map[r_hash] = function( source, target, bRawDamage, stage )
            local spell_entry = source.spellBook:GetSpellEntry( SpellSlot.R )
    
            if spell_entry.level < 1 or spell_entry.level > 5 then return 0 end
    
            local raw_damage = spell_entry:GetCalculateInfo( source, base_damage, SpellSlot.R )
            local raw_damage_hpbonus = spell_entry:GetCalculateInfo( source, percent_hpdamage, SpellSlot.R ) * target.totalMaxHealth 
    
            local crown_buff = target:FindBuff( crown_buff_hash )
            if crown_buff and crown_buff.isValid
            then
                raw_damage = raw_damage - raw_damage * 0.75
            end
    
            return bRawDamage and raw_damage or DamageLib.CalculateMagicalDamage( source, target, raw_damage + raw_damage_hpbonus )
        end
     
    end
    
    -- ../../LuaDamageLib/data/veigar.lua
    do
    local damage_map = DamageLib.GetDamageFunctionMap( )
    
    local q_hash = Game.spelldataHash( "VeigarBalefulStrike" )
    local w_hash = Game.spelldataHash( "VeigarDarkMatter" )
    local r_hash = Game.spelldataHash( "VeigarR" )
    
    --Game.localPlayer:GetSpellEntry( SpellSlot.R ):PrintTooltip( false )
    
    local crown_buff_hash = Game.fnvhash( "4644shield" )
    
    local total_damage_tooltip = Game.fnvhash( "TotalDamageTooltip" )
    damage_map[q_hash] = function( source, target, bRawDamage, stage )
        local spell_entry = source.spellBook:GetSpellEntry( SpellSlot.Q )
        local spell_entry_passive = source.spellBook:GetSpellEntry( SpellSlot.Passive )
    
        if spell_entry.level < 1 or spell_entry.level > 5 then return 0 end
    
        local raw_damage = spell_entry:GetCalculateInfo( source, total_damage_tooltip, SpellSlot.Q )
    
        local crown_buff = target:FindBuff( crown_buff_hash )
        if crown_buff and crown_buff.isValid
        then
            raw_damage = raw_damage - raw_damage * 0.75
        end
    
        return bRawDamage and raw_damage or DamageLib.CalculateMagicalDamage( source, target,  raw_damage )
    end
    
    damage_map[w_hash] = function( source, target, bRawDamage, stage )
        local spell_entry = source.spellBook:GetSpellEntry( SpellSlot.W )
    
        if spell_entry.level < 1 or spell_entry.level > 5 then return 0 end
    
        local raw_damage = spell_entry:GetCalculateInfo( source, total_damage_tooltip, SpellSlot.W )
    
        local crown_buff = target:FindBuff( crown_buff_hash )
        if crown_buff and crown_buff.isValid
        then
            raw_damage = raw_damage - raw_damage * 0.75
        end
    
        return bRawDamage and raw_damage or DamageLib.CalculateMagicalDamage( source, target, raw_damage )
    end
    
    local min_damage_tooptip = Game.fnvhash( "MinDamageTooltip" )
    local max_damage_tooptip = Game.fnvhash( "MaxDamageTooltip" )
    damage_map[r_hash] = function( source, target, bRawDamage, stage )
        local spell_entry = source.spellBook:GetSpellEntry( SpellSlot.R )
    
        if spell_entry.level < 1 or spell_entry.level > 5 then return 0 end
    
        local raw_damage = 0
        local raw_damage_min = spell_entry:GetCalculateInfo( source, min_damage_tooptip, SpellSlot.R )
        local raw_damage_max = spell_entry:GetCalculateInfo( source, max_damage_tooptip, SpellSlot.R )
    
        local hp_percent_missing = ( 100.0 - target.hpPercent )
        if hp_percent_missing >= 33
        then
            raw_damage = raw_damage_max
        else
            raw_damage = raw_damage_min + ( math.floor( hp_percent_missing ) * 0.015 * raw_damage_min )
        end
    
        raw_damage = math.min( raw_damage_max, raw_damage )
    
        local crown_buff = target:FindBuff( crown_buff_hash )
        if crown_buff and crown_buff.isValid
        then
            raw_damage = raw_damage - raw_damage * 0.75
        end
    
        return bRawDamage and raw_damage or DamageLib.CalculateMagicalDamage( source, target, raw_damage )
    end
    end
    
    -- ../../LuaDamageLib/data/vladimir.lua
    do
    local damage_map = DamageLib.GetDamageFunctionMap( )
    
    local damagelib = {} 
    local crown_buff_hash = Game.fnvhash( "4644shield" )
    --Q
    local base_damage_tooltip = Game.fnvhash( "BaseDamageTooltip" )
    local empowered_damage_tooltip = Game.fnvhash( "EmpoweredDamageTooltip" )
    local vladimirqbuild = Game.fnvhash( "vladimirqbuild" )
    
    --W
    local total_damage_tooltip = Game.fnvhash( "TotalDamageTooltip" )
    local effect2_amount = Game.fnvhash( "Effect2Amount" ) --hp cost
    local vladimirsanguinepool = Game.fnvhash( "vladimirsanguinepool" ) --is_casting_w
    
    --E
    local min_damage_tooltip = Game.fnvhash( "MinDamageTooltip" )
    local max_damage_tooltip = Game.fnvhash( "MaxDamageTooltip" )
    local vladimire = Game.fnvhash( "VladimirE" )
    
    --R
    local damage_tooltip = Game.fnvhash( "Damage" )
    local rdebuff = Game.fnvhash( "vladimirhemoplaguedamageamp" )
    local rdebuff2 = Game.fnvhash( "vladimirhemoplaguedebuff" )
    
    local q_hash = Game.spelldataHash( "VladimirQ" )
    local w_hash = Game.spelldataHash( "VladimirSanguinePool" )
    local e_hash = Game.spelldataHash( "VladimirE" )
    local r_hash = Game.spelldataHash( "VladimirHemoplague" )
    
    damage_map[q_hash] = function( source, target, bRawDamage, stage )
        local spell_entry = source.spellBook:GetSpellEntry( SpellSlot.Q )
    
        if spell_entry.level < 1 or spell_entry.level > 5 then return 0 end
    
        local q_stacks = Game.localPlayer:GetBuffStacks( vladimirqbuild ) or 0
        local raw_damage = spell_entry:GetCalculateInfo( source, q_stacks >= 2 and empowered_damage_tooltip or base_damage_tooltip, SpellSlot.Q )
        local crown_buff = target:FindBuff( crown_buff_hash )
    
        local rdebuff = target:FindBuff( rdebuff ) ~= nil or target:FindBuff( rdebuff2 ) ~= nil
        if rdebuff or stage >= 2
        then
            raw_damage = raw_damage + raw_damage*0.1
        end
    
        if crown_buff and crown_buff.isValid
        then
            raw_damage = raw_damage - raw_damage * 0.75
        end
    
        return bRawDamage and raw_damage or DamageLib.CalculateMagicalDamage( source, target, raw_damage )
    end
    
    damage_map[w_hash] = function( source, target, bRawDamage, stage )
        local spell_entry = source.spellBook:GetSpellEntry( SpellSlot.W )
    
        if spell_entry.level < 1 or spell_entry.level > 5 then return 0 end
    
        local raw_damage = spell_entry:GetCalculateInfo( source, total_damage_tooltip, SpellSlot.W )
        local crown_buff = target:FindBuff( crown_buff_hash )
    
        local rdebuff = target:FindBuff( rdebuff ) ~= nil or target:FindBuff( rdebuff2 ) ~= nil
        if rdebuff or stage >= 2
        then
            raw_damage = raw_damage + raw_damage*0.1
        end
    
        if crown_buff and crown_buff.isValid
        then
            raw_damage = raw_damage - raw_damage * 0.75
        end
    
        return bRawDamage and raw_damage or DamageLib.CalculateMagicalDamage( source, target, raw_damage )
    end
    
    damage_map[e_hash] = function( source, target, bRawDamage, stage )
        local spell_entry = source.spellBook:GetSpellEntry( SpellSlot.E )
    
        if spell_entry.level < 1 or spell_entry.level > 5 then return 0 end
    
        local raw_damage = spell_entry:GetCalculateInfo( source, stage == 0 and min_damage_tooltip or max_damage_tooltip, SpellSlot.E )
        local crown_buff = target:FindBuff( crown_buff_hash )
    
        local rdebuff = target:FindBuff( rdebuff ) ~= nil or target:FindBuff( rdebuff2 ) ~= nil
        if rdebuff or stage >= 2
        then
            raw_damage = raw_damage + raw_damage * 0.1
        end
    
        if crown_buff and crown_buff.isValid
        then
            raw_damage = raw_damage - raw_damage * 0.75
        end
    
        return bRawDamage and raw_damage or DamageLib.CalculateMagicalDamage( source, target, raw_damage )
    end
    
    damage_map[r_hash] = function( source, target, bRawDamage, stage )
        local spell_entry = source.spellBook:GetSpellEntry( SpellSlot.R )
    
        if spell_entry.level < 1 or spell_entry.level > 3 then return 0 end
    
        local raw_damage = spell_entry:GetCalculateInfo( source, damage_tooltip, SpellSlot.R )
        local crown_buff = target:FindBuff( crown_buff_hash )
    
        if crown_buff and crown_buff.isValid
        then
            raw_damage = raw_damage - raw_damage * 0.75
        end
    
        return bRawDamage and raw_damage or DamageLib.CalculateMagicalDamage( source, target, raw_damage )
    end
    end
    
    -- ../../LuaDamageLib/data/yuumi.lua
    do
    -- Game.localPlayer:GetSpellEntry(SpellSlot.R):PrintTooltip(false) --test with true and false depends on spell
    
    local YuumiQSpellDataHash = Game.spelldataHash("YuumiQ")
    local YuumiQHash = Game.fnvhash("YuumiQ")
    local TotalMissileDamageHash = Game.fnvhash("TotalMissileDamage")
    local EmpoweredMissileDamageHash = Game.fnvhash("EmpoweredMissileDamage")
    local CurrentHealthDamageHash = Game.fnvhash("CurrentHealthDamage")
    local damageMap = DamageLib.GetDamageFunctionMap()
    
    local YuumiRSpellDataHash = Game.spelldataHash("YuumiR")
    local YuumiRHash = Game.fnvhash("YuumiR")
    
    damageMap[YuumiQSpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(YuumiQHash) -- This uses fnv hash
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        local rawDamage = entry:GetCalculateInfo(source, TotalMissileDamageHash, slot)
    
        if useRawDamage or not target or not target:IsValid() then
            return rawDamage
        end
    
        local qFlyTime = source.position:Distance(target.position) / 1000
        if qFlyTime >= 1 then
            local empoweredDamage = entry:GetCalculateInfo(source, EmpoweredMissileDamageHash, slot)
            local currentHPmodifierDamage = entry:GetCalculateInfo(source, CurrentHealthDamageHash, slot)
    
            local bonusDmgHP = target.hp * currentHPmodifierDamage
            return DamageLib.CalculateMagicalDamage(source, target, empoweredDamage + bonusDmgHP)
        end
    
        return DamageLib.CalculateMagicalDamage(source, target, rawDamage)
    end
    
    damageMap[YuumiRSpellDataHash] = function(source, target, useRawDamage, stage)
        local slot = source:GetSpellSlot(YuumiRHash)
        if slot == SpellSlot.Invalid then
            return 0
        end
    
        local entry = source:GetSpellEntry(slot)
        if not entry or not entry:IsValid() then
            return 0
        end
    
        -- this value is for the first wave of 7, next waves damage is halved
        local rawDamage = entry:GetCalculateInfo(source, TotalMissileDamageHash, slot)
    
        if useRawDamage or not target or not target:IsValid() then
            return (rawDamage * 6 * 0.5) + rawDamage
        end
    
        return DamageLib.CalculateMagicalDamage(source, target, (rawDamage * 6 * 0.5) + rawDamage)
    end
    
    end
    
    