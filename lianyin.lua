--[[
	技能名：连营
	相关武将：标准·陆逊、SP·台版陆逊、倚天·陆抗
	描述：当你失去最后的手牌时，你可以摸一张牌。
	引用：liancheng、lianchengForZeroMaxCards
	状态：1217验证通过
]]--
liancheng = sgs.CreateTriggerSkill{
	name = "liancheng" ,
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
					player:getRoom():setPlayerFlag(player, "lianchengZeroMaxCards")
					return false
				end
				player:addMark(self:objectName())
			else
				if player:getMark(self:objectName()) == 0 then return false end
				player:removeMark(self:objectName())
				if player:askForSkillInvoke(self:objectName(), data) then
					player:drawCards(1)
				end
			end
		end
		return false
	end
}
lianchengForZeroMaxCards = sgs.CreateTriggerSkill{
	name = "#lianchengForZeroMaxcards" ,
	events = {sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		if (change.from == sgs.Player_Discard) and player:hasFlag("lianchengZeroMaxCards") then
			player:getRoom():setPlayerFlag(player, "-lianchengZeroMaxCards")
			if player:askForSkillInvoke("liancheng") then player:drawCards(1) end
		end
		return false
	end
}
