
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

zhushen:addSkill("longdan")
zhushen:addSkill(jiexian_yajiao)
zhushen:addSkill(jiexian_tianzhu)

sgs.LoadTranslationTable {
	["#zhushen"] = "天之意志",
	["zhushen"] = "诛神-破",
	["&zhushen"] = "诛神",
	["jiexian_yajiao"] = "涯角",
	[":jiexian_yajiao"] = "每当你于回合外使用或打出一张手牌时，你可以亮出牌堆顶的一张牌，若此牌与你此次使用或打出的牌类别相同，你可以将之交给任意一名角色；若不同则你可以将之置入弃牌堆。",
	["yajiao-target"] = "你可以发动“涯角”将该牌交给一名角色",
	["jiexian_yajiao:discard"] = "你可以将该牌置入弃牌堆",
	["jiexian_tianzhu"] = "天诛",
	[":jiexian_tianzhu"] = "一名其他角色的结束阶段开始时，若该角色本回合造成过伤害，你可以对其使用一张【杀】。",
	["jiexian_tianzhu-slash"] = "你可以发动“天诛”对该角色使用一张【杀】",

}
