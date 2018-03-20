module("extensions.star", package.seeall);extension = sgs.Package("star")
zhushen = sgs.General(extension, "zhushen", "god", 5)



jiexian_yajiao = sgs.CreateTriggerSkill {
	name = "jiexian_yajiao",
	events = {sgs.CardUsed, sgs.CardResponded},

	on_trigger = function(self, event, player, data)
		if player:getPhase() ~= sgs.Player_NotActive then return end
		local room = player:getRoom()

		local card
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			card = use.card
		elseif event == sgs.CardResponded then
			card = data:toCardResponse().m_card
		end

		if not card or (card:getHandlingMethod() ~= sgs.Card_MethodUse and card:getHandlingMethod() ~= sgs.Card_MethodResponse) then return end

		if card:getTypeId() == sgs.Card_TypeSkill then return end

		if card:isVirtualCard() and card:subcardsLength() == 0 then return end

		if not player:askForSkillInvoke(self:objectName(), data) then return end
		room:broadcastSkillInvoke(self:objectName())

		local ids = room:getNCards(1, false)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), "")
		local move = sgs.CardsMoveStruct(ids, player, sgs.Player_PlaceTable, reason)
		room:moveCardsAtomic(move, true)

		if sgs.Sanguosha:getCard(ids:first()):getTypeId() == card:getTypeId() then
			local target = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(), "yajiao-target", true, true)
			if target then
				room:obtainCard(target, ids:first())
			else
				reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(), "")
				move = sgs.CardsMoveStruct(ids, nil, sgs.Player_DrawPile, reason)
				room:moveCardsAtomic(move, true)
			end
		else
			if player:askForSkillInvoke(self:objectName(), sgs.QVariant("discard")) then
				reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), "")
				room:throwCard(sgs.Sanguosha:getCard(ids:first()), reason, nil)
			else
				reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(), "")
				move = sgs.CardsMoveStruct(ids, nil, sgs.Player_DrawPile, reason)
				room:moveCardsAtomic(move, true)
			end
		end
		return false
	end
}

jiexian_tianzhu = sgs.CreateTriggerSkill{
	name = "jiexian_tianzhu",
	events = {sgs.EventPhaseStart, sgs.PreDamageDone},

	can_trigger = function(self, target)
		return target and target:isAlive()
	end,

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreDamageDone then
			local damage = data:toDamage()
			if damage.from then
				damage.from:setTag("Tianzhu", sgs.QVariant(true))
			end
		elseif event == sgs.EventPhaseStart then
			local splayer = room:findPlayerBySkillName(self:objectName())
			if not splayer or splayer:objectName() == player:objectName() then return false end
			if player:getPhase() == sgs.Player_Finish and player:getTag("Tianzhu"):toBool() then
				if splayer:canSlash(player, nil, false) then
					slash = room:askForUseSlashTo(splayer, player, "jiexian_tianzhu-slash", false)
				end
			elseif player:getPhase() == sgs.Player_RoundStart then
				player:setTag("Tianzhu", sgs.QVariant(false))
			end
		end
	end
}

jiexian_tianzi = sgs.CreateTriggerSkill {
	name = "#jiexian_tianzi",
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

jiexian_tianzi_keep = sgs.CreateMaxCardsSkill{
	name = "jiexian_tianzi",

	fixed_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			return target:getMaxHp()
		else
			return 0
		end
	end
}

shenlian = sgs.CreateTriggerSkill{
	name = "shenlian" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data)
		local move = data:toMoveOneTime()
		if move.from and (move.from:objectName() == player:objectName()) and move.from_places:contains(sgs.Player_PlaceHand) then
			if event == sgs.BeforeCardsMove then
				if player:isKongcheng() then return false end
				for _, id in sgs.qlist(player:handCards()) do
					if not move.card_ids:contains(id) then return false end
				end
				if (player:getMaxCards() == 0) and (player:getPhase() == sgs.Player_Discard)
						and (move.reason.m_reason == sgs.CardMoveReason_S_REASON_RULEDISCARD) then
					player:getRoom():setPlayerFlag(player, "shenlianZeroMaxCards")
					return false
				end
				player:addMark(self:objectName())
			else
				if player:getMark(self:objectName()) == 0 then return false end
				player:removeMark(self:objectName())
				if player:askForSkillInvoke(self:objectName(), data) then
					player:drawCards(1)
				end
				room:broadcastSkillInvoke(self:objectName())
			end
		end
		return false
	end
}
shenlianForZeroMaxCards = sgs.CreateTriggerSkill{
	name = "#shenlianForZeroMaxcards" ,
	events = {sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		if (change.from == sgs.Player_Discard) and player:hasFlag("shenlianZeroMaxCards") then
			player:getRoom():setPlayerFlag(player, "-shenlianZeroMaxCards")
			if player:askForSkillInvoke("shenlian") then player:drawCards(1) end
		end
		room:broadcastSkillInvoke(self:objectName())
		return false
	end
}




zhushen:addSkill("longdan")
zhushen:addSkill("weimu")
zhushen:addSkill(jiexian_yajiao)
zhushen:addSkill(jiexian_tianzhu)
zhushen:addSkill(jiexian_tianzi)
zhushen:addSkill(shenlian)
extension:insertRelatedSkills("jiexian_tianzi", "#jiexian_tianzi")

sgs.LoadTranslationTable {
	["star"] = "神将包",
	["#zhushen"] = "天之意志",
	["zhushen"] = "天道诛神",
	["&zhushen"] = "诛神",
	["jiexian_tianzi"] = "天姿",
	[":jiexian_tianzi"] = "<font color=\"blue\"><b>锁定技，</b></font>摸牌阶段摸牌时，你额外摸三张牌。",
	["$jiexian_tianzi"] = "夫英雄者,胸怀大志..腹有良谋",
	["jiexian_yajiao"] = "涯角",
	[":jiexian_yajiao"] = "每当你于回合外使用或打出一张手牌时，你可以亮出牌堆顶的一张牌，若此牌与你此次使用或打出的牌类别相同，你可以将之交给任意一名角色；若不同则你可以将之置入弃牌堆。",
	["$jiexian_yajiao1"] = "策马趋前，斩敌当先",
	["$jiexian_yajiao2"] = "遍寻天下，但求一败！",
	["yajiao-target"] = "你可以发动“涯角”将该牌交给一名角色",
	["jiexian_yajiao:discard"] = "你可以将该牌置入弃牌堆",
	["jiexian_tianzhu"] = "天诛",
	["$jiexian_tianzhu1"] = "善恶有报，天道轮回",
	["$jiexian_tianzhu2"] = "早知今日，何必当初",
	[":jiexian_tianzhu"] ="一名其他角色的结束阶段开始时，若该角色本回合造成过伤害，你可以对其使用一张【杀】。",
	["jiexian_tianzhu-slash"] = "你可以发动“天诛”对该角色使用一张【杀】",
	["shenlian"] = "神念",
	[":shenlian"] = "当你失去最后的手牌时，你可以摸一张牌",
	["$shenlian1"] = "失之淡然，得之坦然",
	["$shenlian2"] = "生生不息，源源不绝",
}
