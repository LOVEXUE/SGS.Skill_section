--本文件专用于测试
module("extensions.text", package.seeall);extension = sgs.Package("text")
exam = sgs.General(extension, "exam", "god", 5)

--[[
LuaZhenlie = sgs.CreateTriggerSkill{
	name = "LuaZhenlie" ,
	events = {sgs.TargetConfirmed, sgs.CardEffected, sgs.SlashEffected} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			if player and player:isAlive() and player:hasSkill(self:objectName()) then
				local use = data:toCardUse()
				if use.to:contains(player) and (use.from:objectName() ~= player:objectName()) then
					if use.card:isKindOf("Slash") or use.card:isNDTrick() then
						if room:askForSkillInvoke(player, self:objectName(), data) then
							room:setCardFlag(use.card, "LuaZhenlieNullify")
							player:setFlags("LuaZhenlieTarget")
							room:loseHp(player)
							if player:isAlive() and player:hasFlag("LuaZhenlieTarget") and player:canDiscard(use.from, "he") then
								local id = room:askForCardChosen(player, use.from, "he", self:objectName(), false, sgs.Card_MethodDiscard)
								room:throwCard(id, use.from, player)
							end
						end
					end
				end
			end
		elseif event == sgs.CardEffected then
			local effect = data:toCardEffect()
			if (not effect.card:isKindOf("Slash")) and effect.card:hasFlag("LuaZhenlieNullify") and player:hasFlag("LuaZhenlieTarget") then
				player:setFlags("-LuaZhenlieTarget")
				return true
			end
		elseif event == sgs.SlashEffected then
			local effect = data:toSlashEffect()
			if effect.slash:hasFlag("LuaZhenlieNullify") and player:hasFlag("LuaZhenlieTarget") then
				player:setFlags("-LuaZhenlieTarget")
				return true
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}

exam:addSkill(LuaZhenlie)

sgs.LoadTranslationTable{
   ["LuaZhenlie"] = "贞烈",
   [":LuaZhenlie"] = 每当你成为一名其他角色使用的【杀】或非延时类锦囊牌的目标后，你可以失去1点体力，令此牌对你无效，然后你弃置其一张牌。,
	--引用：LuaZhenlie
}
]]--


--[[
LuaXingwu = sgs.CreateTriggerSkill{
	name = "LuaXingwu" ,
	events = {sgs.PreCardUsed, sgs.CardResponded, sgs.EventPhaseStart, sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.PreCardUsed) or (event == sgs.CardResponded) then
			local card = nil
			if event == sgs.PreCardUsed then
				card = data:toCard()
			else
				local response = data:toCardResponse()
				if response.m_isUse then
					card = response.m_card
				end
			end
			if card and (card:getTypeId() ~= sgs.Card_TypeSkill) and (card:getHandlingMethod() == sgs.Card_MethodUse) then
				local n = player:getMark()
				if card:isBlack() then
					n = bit32.bor(n, 1)
				elseif card:isRed() then
					n = bit32.bor(n, 2)
				end
				player:setMark(self:objectName(), n)
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Discard then
				local n = player:getMark(self:objectName())
				local red_avail = (bit32.band(n, 2) == 0)
				local black_avail = (bit32.band(n, 1) == 0)
				if player:isKongcheng() or ((not red_avail) and (not black_avail)) then return false end
				local pattern = ".|.|.|hand"
				if red_avail ~= black_avail then
					if red_avail then
						pattern = ".|red|.|hand"
					else
						pattern = ".|black|.|hand"
					end
				end
				local card = room:askForCard(player, pattern, "@xingwu", sgs.QVariant(), sgs.Card_MethodNone)
				if card then
					player:addToPile(self:objectName(), card)
				end
			elseif player:getPhase() == sgs.Player_RoundStart then
				player:setMark(self:objectName(), 0)
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.to and move.to:objectName() == player:objectName()) and (move.to_place == sgs.Player_PlaceSpecial) and (player:getPile(self:objectName()):length() >= 3) then
				player:clearOnePrivatePile(self:objectName())
				local males = sgs.SPlayerList()
				if males:isEmpty() then return false end
				local target = room:askForPlayerChosen(player, males, self:objectName(), "@xingwu-choose")
				room:damage(sgs.DamageStruct(self:objectName(), player, target, 2))
				if not player:isAlive() then return false end
				local equips = target:getEquips()
				if not equips:isEmpty() then
					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					for _, equip in sgs.qlist(equips) do
						if player:canDiscard(target, equip:getEffectiveId()) then
							dummy:addSubcard(equip)
						end
					end
					if dummy:subcardsLength() > 0 then
						room:throwCard(dummy, target, player)
					end
				end
			end
		end
		return false
	end
}

exam:addSkill(LuaXingwu)
   sgs.LoadTranslationTable{
   ["LuaXingwu"] = "星舞"
   [":LuaXingwu"] = "弃牌阶段开始时，你可以将一张与你本回合使用的牌颜色均不同的手牌置于武将牌上。,
		若你有三张“星舞牌”，你将其置入弃牌堆，然后选择一名角色，你对其造成2点伤害并弃置其装备区的所有牌。",
}
   --引用：LuaXingwu

]]--



--[[
LuaLuoyan = sgs.CreateTriggerSkill{
	name = "LuaLuoyan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime,sgs.EventAcquireSkill,sgs.EventLoseSkill},
	can_trigger = function(self,player)
		return player ~= nil
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventLoseSkill and data:toString() == self:objectName() then
			room:handleAcquireDetachSkills(player,"-tianxiang|-liuli",true)
		elseif event == sgs.EventAcquireSkill and data:toString() == self:objectName() then
			if not player:getPile("xingwu"):isEmpty() then
				room:notifySkillInvoked(player,self:objectName())
				room:handleAcquireDetachSkills(player,"tianxiang|liuli")
			end
		elseif event == sgs.CardsMoveOneTime and player:isAlive() and player:hasSkill(self:objectName(),true) then
			local move = data:toMoveOneTime()
			if move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceSpecial and move.to_pile_name == "xingwu" then
				if player:getPile("xingwu"):length() == 1 then
					room:notifySkillInvoked(player,self:objectName())
					room:handleAcquireDetachSkills(player,"tianxiang|liuli")
				end
			elseif move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceSpecial) and table.contains(move.from_pile_names,"xingwu") then
				if player:getPile("xingwu"):isEmpty() then
					room:handleAcquireDetachSkills(player,"-tianxiang|-liuli",true)
				end
			end
		end
		return false
	end
}

exam:addSkill(LuaLuoyan)

sgs.LoadTranslationTable {
   ["LuaLuoyan"] = "落雁",
   [":LuaLuoyan"] = "<font color=\"blue\"><b>锁定技,若你的武将牌上有“星舞牌”，你视为拥有技能“天香”和“流离”。",
   --引用：LuaLuoyan
}

]]--



--[[
LuaWansha=sgs.CreateTriggerSkill{
	name = "LuaWansha",
	events = {sgs.AskForPeaches, sgs.EventPhaseChanging, sgs.Death},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.AskForPeaches then
			local dying = data:toDying()
			local jiaxu = room:getCurrent()
			if jiaxu and jiaxu:isAlive() and jiaxu:hasSkill(self:objectName()) and jiaxu:getPhase() ~= sgs.Player_NotActive then
				if dying.who:objectName() ~= player:objectName() and jiaxu:objectName() ~= player:objectName() then
					room:setPlayerFlag(player, "Global_PreventPeach")
				end
			end
		else
			if event == sgs.EventPhaseChanging then
				local change = data:toPhaseChange()
				if change.to ~= sgs.Player_NotActive then return false end
			elseif event == sgs.Death then
				local death = data:toDeath()
				if death.who:objectName() ~= player:objectName() or death.who:getPhase() == sgs.Player_NotActive then return false end
			end
			for _ , p in sgs.qlist(room:getAllPlayers()) do
				if p:hasFlag("Global_PreventPeach") then
                			 room:setPlayerFlag(p, "-Global_PreventPeach")
				end
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return target
	end
}

exam:addSkill(LuaWansha)
sgs.LoadTranslationTable{
   ["LuaWansha"] = "完杀",
   [":LuaWansha"] = "在你的回合，除你以外，只有处于濒死状态的角色才能使用【桃】。",
}

	--引用：LuaWansha

]]--




--[[
LuaCangni = sgs.CreateTriggerSkill{
	name = "LuaCangni" ,
	events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_Discard) then
			if player:askForSkillInvoke(self:objectName()) then
				local choices = {}
				table.insert(choices, "draw")
				if player:isWounded() then
					table.insert(choices, recover)
				end
				local choice
				if #choices == 1 then
					choice = choices[1]
				else
					choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
				end
				if choice == "recover" then
					local recover = sgs.RecoverStruct()
					recover.who = player
					room:recover(player, recover)
				else
					player:drawCards(2)
				end
				player:turnOver()
				return false
			end
		elseif (event == sgs.CardsMoveOneTime) and (not player:faceUp()) then
			if (player:getPhase() ~= sgs.Player_NotActive) then return false end
			local move = data:toMoveOneTime()
			local target = room:getCurrent()
			if target:isDead() then return false end
			if (move.from and (move.from:objectName() == player:objectName())) and ((not move.to) or (move.to:objectName() ~= player:objectName())) then
				local invoke = false
				for i = 0, move.card_ids:length() - 1, 1 do
					if (move.from_places:at(i) == sgs.Player_PlaceHand) or (move.from_places:at(i) == sgs.Player_PlaceEquip) then
						invoke = true
						break
					end
				end
				room:setPlayerFlag(player, "LuaCangniLose")
				if invoke and (not target:isNude()) then
					if player:askForSkillInvoke(self:objectName()) then
						room:askForDiscard(target, self:objectName(), 1, 1, false, true)
					end
				end
				room:setPlayerFlag(player, "-LuaCangniLose")
				return false
			end
			if (move.to and (move.to:objectName() == player:objectName())) and ((not move.from) or (move.from:objectName() ~= player:objectName())) then
				if (move.to_place == sgs.Player_PlaceHand) or (move.to_place == sgs.Player_PlaceEquip) then
					room:setPlayerFlag(player, "LuaCangniGet")
					if (not target:hasFlag("LuaCangni_Used")) then
						if player:askForSkillInvoke(self:objectName()) then
							room:setPlayerFlag(target, "LuaCangni_Used")
							target:drawCards(1)
						end
					end
					room:setPlayerFlag(player, "-LuaCangniGet")
				end
			end
		end
		return false
	end
}

exam:addSkill(LuaCangni)

sgs.LoadTranslationTable{
   ["LuaCangni"] = "藏匿",
   [":LuaCangni"] = "弃牌阶段开始时，你可以回复1点体力或摸两张牌，然后将你的武将牌翻面；其他角色的回合内，当你获得（每回合限一次）/失去一次牌时，若你的武将牌背面朝上，你可以令该角色摸/弃置一张牌。",
	--引用：LuaCangni
}

]]--

--[[
LuaShangshi = sgs.CreateTriggerSkill{
	name = "LuaShangshi",
	events = {sgs.EventPhaseChanging, sgs.CardsMoveOneTime, sgs.MaxHpChanged, sgs.HpChanged},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, triggerEvent, zhangchunhua, data)
		local room = zhangchunhua:getRoom()
		--local losthp = math.min(zhangchunhua:getLostHp(),2)
		--如果是怀旧版请如下写。
		local losthp = zhangchunhua:getLostHp()
		if (triggerEvent == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if zhangchunhua:getPhase() == sgs.Player_Discard then
				local changed = false
				if move.from and move.from:objectName() == zhangchunhua:objectName() and move.from_places:contains(sgs.Player_PlaceHand) then
					changed = true
				end
				if moce.to and move.to:objectName() == zhangchunhua:objectName() and move.to_place == sgs.Player_PlaceHand then
					changed = true
				end
				if changed then
					zhangchunhua:addMark("shangshi")
				end
				return false
			else
				local can_invoke = false
				if move.from and move.from:objectName() == zhangchunhua:objectName() and move.from_places:contains(sgs.Player_PlaceHand) then
					can_invoke = true
				end
				if move.to and move.to:objectName() == zhangchunhua:objectName() and move.to_place == sgs.Player_PlaceHand then
					can_invoke = true
				end
				if not can_invoke then
					return false
				end
			end
		elseif triggerEvent == sgs.HpChanged or triggerEvent == sgs.MaxHpChanged then
			if zhangchunhua:getPhase() == sgs.Player_Discard then
				zhangchunhua:addMark("shangshi")
				return false
			end
		elseif triggerEvent == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.from ~= sgs.Player_Discard then
				return false
			end
			if zhangchunhua:getMark("shangshi") <= 0 then
				return false
			end
			zhangchunhua:setMark("shangshi", 0)
		end
		if (zhangchunhua:getHandcardNum() < losthp and zhangchunhua:getPhase() ~= sgs.Player_Discard and zhangchunhua:askForSkillInvoke(self:objectName())) then
			zhangchunhua:drawCards(losthp - zhangchunhua:getHandcardNum());
		end
		return false;
	end
}

exam:addSkill(LuaShangshi)

sgs.LoadTranslationTable{
   ["LuaShangshi"] = "伤逝",
   [":LuaShangshi"] = "弃牌阶段外，当你的手牌数小于X时，你可以将手牌补至X张（X为你已损失的体力值）",
	--引用：LuaShangshi
}


]]--





--[[
LuaLianpoCount = sgs.CreateTriggerSkill{
	name = "#LuaLianpo-count" ,
	events = {sgs.Death, sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		if event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() then return false end
			local killer
			if death.damage then
				killer = death.damage.from
			else
				killer = nil
			end
			local current = player:getRoom():getCurrent()
			if killer and current and current:isAlive() and (current:getPhase() ~= sgs.Playr_NotActive) then
				killer:addMark("LuaLianpo")
			end
		elseif player:getPhase() == sgs.Player_NotActive then
			for _, p in sgs.qlist(player:getRoom():getAlivePlayers()) do
				p:setMark("LuaLianpo", 0)
			end
		end
	end,
	can_trigger = function(self,target)
		return target
	end
}
LuaLianpo = sgs.CreateTriggerSkill{
	name = "LuaLianpo" ,
	events = {sgs.EventPhaseChanging} ,
	--frequency = sgs.Skill_Frequent , 这句话源代码没有，但是我感觉应该加上，毕竟连破一点副作用都没有
	priority = 1,
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive then return false end
		local shensimayi = player:getRoom():findPlayerBySkillName("LuaLianpo")
		if (not shensimayi) or (shensimayi:getMark("LuaLianpo") <= 0) then return false end
		local n = shensimayi:getMark("LuaLianpo")
		shensimayi:setMark("LuaLianpo",0)
		if not shensimayi:askForSkillInvoke("LuaLianpo") then return false end
		local p = shensimayi
		local playerdata = sgs.QVariant()
		playerdata:setValue(p)
		player:getRoom():setTag("LuaLianpoInvoke", playerdata)
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}
LuaLianpoDo = sgs.CreateTriggerSkill{
	name = "LuaLianpo-do" ,
	events = {sgs.EventPhaseStart},
	priority = 1 ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:getTag("LuaLianpoInvoke") then
			local target = room:getTag("LuaLianpoInvoke"):toPlayer()
			room:removeTag("LuaLianpoInvoke")
			if target and target:isAlive() then
				target:gainAnExtraTurn()
			end
		end
	end,
	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_NotActive)
	end
}

exam:addSkill(LuaLianpo)
exam:addSkill(LuaLianpoDo)
exam:addSkill(LuaLianpoCount)

sgs.LoadTranslationTable{
   ["LuaLianpo"] = "连破",
   [":LuaLianpo"] = "若你在一回合内杀死了至少一名角色，此回合结束后，你可以进行一个额外的回合。",
}


	--技能名：连破
	--引用：LuaLianpoCount、LuaLianpo、LuaLianpoDo
	--状态：1217验证通过
]]--



--[[
LuaLihunCard = sgs.CreateSkillCard{
	name = "LuaLihunCard" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:isMale() and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		effect.from:turnOver()
		local dummy_card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		for _, cd in sgs.qlist(effect.to:getHandcards()) do
			dummy_card:addSubcard(cd)
		end
		if not effect.to:isKongcheng() then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, effect.from:objectName(),effect.to:objectName(), "LuaLihun", nil)
			room:moveCardTo(dummy_card, effect.to, effect.from, sgs.Player_PlaceHand, reason, false)
		end
		effect.to:setFlags("LuaLihunTarget")
	end
}
LuaLihunVS = sgs.CreateViewAsSkill{
	name = "LuaLihun" ,
	n = 1,
	view_filter = function(self, cards, to_select)
		if #cards == 0 then
			return not sgs.Self:isJilei(to_select)
		else
			return false
		end
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = LuaLihunCard:clone()
		card:addSubcard(cards[1])
		return card
	end ,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he") and (not player:hasUsed("#LuaLihunCard"))
	end
}
LuaLihun = sgs.CreateTriggerSkill{
	name = "LuaLihun" ,
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd} ,
	view_as_skill = LuaLihunVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseEnd) and (player:getPhase() == sgs.Player_Play) then
			local target
			for _, other in sgs.qlist(room:getOtherPlayers(player)) do
				if other:hasFlag("LuaLihunTarget") then
					other:setFlags("-LuaLihunTarget")
					target = other
					break
				end
			end
			if (not target) or (target:getHp() < 1) or player:isNude() then return false end
			local to_back = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			if player:getCardCount(true) <= target:getHp() then
				if not player:isKongcheng() then to_goback = player:wholeHandCards() end
				for i = 0, 3, 1 do
					if player:getEquip(i) then to_goback:addSubcard(player:getEquip(i):getEffectiveId()) end
				end
			else
				to_goback = room:askForExchange(player, self:objectName(), target:getHp(), true, "LuaLihunGoBack")
			end
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), target:objectName(), self:objectName(), nil)
			room:moveCardTo(to_goback, player, target, sgs.Player_PlaceHand, reason)
		elseif (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_NotActive) then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasFlag("LuaLihunTarget") then
					p:setFlags("-LuaLihunTarget")
				end
			end
		end
	end ,
	can_trigger = function(self, target)
		return target and target:hasUsed("#LuaLihunCard")
	end
}

exam:addSkill(LuaLihun)

sgs.LoadTranslationTable{
   ["LuaLihun"] = "离魂",
   [":LuaLihun"] = "出牌阶段限一次，你可以弃置一张牌将武将牌翻面，然后获得一名男性角色的所有手牌，且出牌阶段结束时，你交给该角色X张牌。（X为该角色的体力值)。",
	引用：LuaLihun

}
]]--


--[[
LuaDuwuCard = sgs.CreateSkillCard{
	name = "LuaDuwuCard" ,
	filter = function(self, targets, to_select)
		if (#targets ~= 0) or (math.max(0, to_select:getHp()) ~= self:subcardsLength()) then return false end
		if (not sgs.Self:inMyAttackRange(to_select)) or (sgs.Self:objectName() == to_select:objectName()) then return false end
		if sgs.Self:getWeapon() and self:getSubcards():contains(sgs.Self:getWeapon():getId()) then
			local weapon = sgs.Self:getWeapon():getRealCard():toWeapon()
			local distance_fix = weapon:getRange() - 1
			if sgs.Self:getOffensiveHorse() and self:getSubcards():contains(sgs.Self:getOffensiveHorse():getId()) then
				distance_fix = distance_fix + 1
			end
			return sgs.Self:distanceTo(to_select, distance_fix) <= sgs.Self:getAttackRange()
		elseif sgs.Self:getOffensiveHorse() and self:getSubcards():contains(sgs.Self:getOffensiveHorse():getId()) then
			return sgs.Self:distanceTo(to_select, 1) <= sgs.Self:getAttackRange()
		else
			return true
		end
	end ,
	on_effect = function(self, effect)
		effect.from:getRoom():damage(sgs.DamageStruct("LuaDuwu", effect.from, effect.to))
	end
}
LuaDuwuVS = sgs.CreateViewAsSkill{
	name = "LuaDuwu" ,
	n = 999 ,
	view_filter = function()
		return true
	end ,
	view_as = function(self, cards)
		local duwu = LuaDuwuCard:clone()
		if #cards ~= 0 then
			for _, c in ipairs(cards) do
				duwu:addSubcard(c)
			end
		end
		return duwu
	end ,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he")
	end
}
LuaDuwu = sgs.CreateTriggerSkill{
	name = "LuaDuwu" ,
	events = 39, --sgs.QuitDying事件没有Lua接口，用此代替。
	view_as_skill = LuaDuwuVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.damage and (dying.damage:getReason() == "LuaDuwu") then
			local from = dying.damage.from
			if from and from:isAlive() then
				room:loseHp(from,1)
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

exam:addSkill(LuaDuwu)
exam:addSkill(LuaDuwuVS)

sgs.LoadTranslationTable{
   ["LuaDuwu"] = "黩武",
   [":LuaDuwu"] = "出牌阶段，你可以选择攻击范围内的一名其他角色并弃置X张牌：若如此做，你对该角色造成1点伤害。
		（X为该角色当前的体力值）",
}

]]--



--[[  -- pass
LuaChongzhen = sgs.CreateTriggerSkill{
	name = "LuaChongzhen" ,
	events = {sgs.CardResponded, sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardResponded then
			local resp = data:toCardResponse()
			if (resp.m_card:getSkillName() == "longdan") and resp.m_who and (not resp.m_who:isKongcheng()) then
				local _data = sgs.QVariant()
				_data:setValue(resp.m_who)
				if player:askForSkillInvoke(self:objectName(), _data) then
					local card_id = room:askForCardChosen(player, resp.m_who, "h", self:objectName())
					room:obtainCard(player, sgs.Sanguosha:getCard(card_id), false)
				end
			end
		else
			local use = data:toCardUse()
			if (use.from:objectName() == player:objectName()) and (use.card:getSkillName() == "longdan") then
				for _, p in sgs.qlist(use.to) do
					if p:isKongcheng() then continue end
					local _data = sgs.QVariant()
					_data:setValue(p)
					p:setFlags("LuaChongzhenTarget")
					local invoke = player:askForSkillInvoke(self:objectName(), _data)
					p:setFlags("-LuaChongzhenTarget")
					if invoke then
						local card_id = room:askForCardChosen(player,p,"h",self:objectName())
						room:obtainCard(player,sgs.Sanguosha:getCard(card_id), false)
					end
				end
			end
		end
		return false
	end
}

exam:addSkill("longdan")
exam:addSkill(LuaChongzhen)

sgs.LoadTranslationTable {
   ["LuaChongzhen"] = "冲阵",
   [":LuaChongzhen"] = "每当你发动“龙胆”使用或打出一张手牌时，你可以立即获得对方的一张手牌。",

}
]]--

--[[

Qianxi = sgs.CreateTriggerSkill{
	name = "Qianxi" ,
	events = {sgs.DamageCaused} ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if (player:distanceTo(damage.to) == 1) and damage.card and damage.card:isKindOf("Slash")
				and damage.by_user and (not damage.chain) and (not damage.transfer) then
			if player:askForSkillInvoke(self:objectName(), data) then
				local room = player:getRoom()
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|heart"
				judge.good = false
				judge.who = player
				judge.reason = self:objectName()
				room:judge(judge)
				if judge:isGood() then
					room:loseMaxHp(damage.to)
					return true
				end
			end
		end
		return false
	end
}

exam:addSkill(Qianxi)
sgs.LoadTranslationTable {
	["Qianxi"] = "潜袭",
	[":Qianxi"] = "每当你使用【杀】对距离为1的目标角色造成伤害时，你可以进行一次判定，若判定结果不为红桃，你防止此伤害，改为令其减1点体力上限。",
}

]]--

--[[
Table2IntList = function(theTable)
	local result = sgs.IntList()
		for i = 1, #theTable, 1 do
		result:append(theTable[i])
		end
	return result
	end
jiexian_tieqi = sgs.CreateTriggerSkill {
	name = "jiexian_tieqi",
	events = {sgs.TargetSpecified,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
			if event == sgs.EventPhaseStart then
				if player:getPhase() == sgs.Player_Finish then
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:getMark("tieqi_qingcheng") > 0 then
							room:setPlayerMark(p,"tieqi_qingcheng",0)
							room:setPlayerMark(p,"@skill_invalidity",0)
						local Qingchenglist = p:getTag("Qingcheng"):toString():split("+")
						if #Qingchenglist == 0 then return false end
					for _,skill_name in pairs(Qingchenglist)do
						room:setPlayerMark(p, "Qingcheng" .. skill_name, 0);
					end
					p:removeTag("Qingcheng")
					for _,t in sgs.qlist(room:getAllPlayers())do
					room:filterCards(t, t:getCards("he"), true)
				end
			end
		end
	end
			else
	local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
			--room:broadcastSkillInvoke(self:objectName())
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				local index = 1
				for _,to in sgs.qlist(use.to) do
					if to:objectName() ~= player:objectName() and room:askForSkillInvoke(player,self:objectName()) then
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(to, "tieqi_qingcheng")
						room:addPlayerMark(to, "@skill_invalidity")
							local skill_list = {}
							local Qingchenglist = to:getTag("Qingcheng"):toString():split("+") or {}
								for _,skill in sgs.qlist(to:getVisibleSkillList()) do
										if (not table.contains(skill_list,skill:objectName())) and (not skill:isAttachedLordSkill()) and (skill:getFrequency() ~= sgs.Skill_Compulsory) and (not skill:inherits("SPConvertSkill")) then
									table.insert(skill_list,skill:objectName())
									end
								end
				table.removeTable(skill_list,Qingchenglist)
					if #skill_list > 0 then
						for _,skill_qc in ipairs(skill_list) do
							table.insert(Qingchenglist,skill_qc)
							to:setTag("Qingcheng",sgs.QVariant(table.concat(Qingchenglist,"+")))
							room:addPlayerMark(to, "Qingcheng" .. skill_qc)
								for _,p in sgs.qlist(room:getAllPlayers()) do
									room:filterCards(p, p:getCards("he"), true)
								end
						end
					end
		local judge = sgs.JudgeStruct()
				judge.reason = self:objectName()
				judge.play_animation = false
				judge.good = false
				judge.pattern = "."
				judge.who = player
				room:judge(judge)
				if not room:askForCard(to, ".|"..judge.card:getSuitString(), "@tieqi-discard:"..judge.card:getSuitString()) then
					jink_table[index] = 0
					end
					index = index + 1
					end
				end
			local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
				return false
				end
			end
		end
}


exam:addSkill(jiexian_tieqi)


sgs.LoadTranslationTable {
["jiexian_tieqi"] = "铁骑",
[":jiexian_tieqi"] = "当你使用【杀】指定一名角色为目标后，你可以进行一次判定并令该角色的非锁定技失效直到回合结束，除非该角色弃置一张与判定结果花色相同的牌，否则不能使用【闪】抵消此【杀】。",
["@tieqi-discard"] = "请弃置一张花色为 %src 的牌",
}

]]--


--[[
LuaFenyong = sgs.CreateTriggerSkill{
	name = "LuaFenyong" ,
	events = {sgs.Damaged, sgs.DamageInflicted} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			if player:getMark("@fenyong") == 0 then
				if player:askForSkillInvoke(self:objectName()) then
					player:gainMark("@fenyong")
				end
			end
		elseif event == sgs.DamageInflicted then
			if player:getMark("@fenyong") > 0 then
				return true
			end
		end
		return false
	end
}
LuaFenyongClear = sgs.CreateTriggerSkill{
	name = "#LuaFenyong-clear" ,
	events = {sgs.EventPhaseChanging, sgs.Death} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then
				return false
			end
		else
			local death = data:toDeath()
			if (death.who:objectName() ~= player:objectName()) or (player:objectName() ~= room:getCurrent():objectName()) then
				return false
			end
		end
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:getMark("@fenyong") > 0 then
				room:setPlayerMark(p, "@fenyong", 0)
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}

extension:insertRelatedSkills("LuaFenyong", "#LuaFenyong-clear")
exam:addSkill(LuaFenyong)
exam:addSkill(LuaFenyongClear)
sgs.LoadTranslationTable {
	["LuaFenyong"] = "愤勇",
	[":LuaFenyong"] = "每当你受到一次伤害后，你可以竖置你的体力牌；当你的体力牌为竖置状态时，防止你受到的所有伤害;一名角色的结束阶段开始时，若你的体力牌处于竖置状态，你横置之。",
}
]]--



--[[ -- pass
Lingju1 = sgs.CreateDistanceSkill{
	name = "Lingju",
	correct_func = function(self, from, to)
		if from:hasSkill("Lingju") then
			return -1
		end
	end,
}

Lingju2 = sgs.CreateDistanceSkill{
	name = "#Lingju",
	correct_func = function(self, from, to)
		if to:hasSkill("Lingju") then
			return 1
		end
	end,
}
extension:insertRelatedSkills("Lingju", "#Lingju")
exam:addSkill(Lingju1)
exam:addSkill(Lingju2)

sgs.LoadTranslationTable {
   ["Lingju"] = "灵驹",
   ["#Lingju"] = "千里",
   [":Lingju"] = "<font color=\"blue\"><b>锁定技,你与其它角色计算距离-1；其它角色与你计算距离+1。",
}
]]--

--[[ -- pass
jiexian_tianzi = sgs.CreateTriggerSkill {
	name = "jiexian_tianzi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards},

	on_trigger = function(self, event, player, data)
		local log = sgs.LogMessage()
		log.type = "#TriggerSkill"
		log.from = player
		log.arg = "jiexian_tianzi"
		player:getRoom():sendLog(log)
		data:setValue(data:toInt() + 3)
	end
}

jiexian_yingzi_keep = sgs.CreateMaxCardsSkill{
   name = "#jiexian_yingzi_keep",
   extra_func = function(self, target)
      if target:hasSkill(self:objectName()) then
         return target:getLostHp()
      end
   end
}

exam:addSkill(jiexian_yingzi_keep)
exam:addSkill(jiexian_tianzi)
extension:insertRelatedSkills("jiexian_tianzi", "#jiexian_yingzi_keep")

sgs.LoadTranslationTable {
	["jiexian_tianzi"] = "天姿",
	[":jiexian_tianzi"] = "<font color=\"blue\"><b>锁定技，</b></font>摸牌阶段摸牌时，你额外摸三张牌;	你的手牌上限等于你的体力上限。",
}
]]--

--[[
jiexian_zhuhai = sgs.CreateTriggerSkill{
	name = "jiexian_zhuhai",
	events = {sgs.EventPhaseStart},

	can_trigger = function(self, target)
		return target and target:isAlive()
	end,

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local splayer = room:findPlayerBySkillName(self:objectName())
			if not splayer or splayer:objectName() == player:objectName() then return false end
			if player:getPhase() == sgs.Player_Finish then
				if splayer:canSlash(player, nil, false) then
					slash = room:askForUseSlashTo(splayer, player, "jiexian_zhuhai-slash", false)
				end
			elseif player:getPhase() == sgs.Player_RoundStart then
				player:setTag("Zhuhai", sgs.QVariant(false))
			end
		end
	end
}
exam:addSkill(jiexian_zhuhai)

sgs.LoadTranslationTable {
	["jiexian_zhuhai"] = "诛害",
	[":jiexian_zhuhai"] = "一名其他角色的结束阶段开始时你可以对其使用一张【杀】。",
	["jiexian_zhuhai-slash"] = "你可以发动“诛害”对该角色使用一张【杀】",
}

]]--


sgs.LoadTranslationTable {
	["text"] = "神将包",
	["#exam"] = "测试专用",
	["exam"] = "考核",
	["&exam"] = "验证",

}
