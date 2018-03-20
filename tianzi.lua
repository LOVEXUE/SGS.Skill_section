
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
			return target:(getMaxHp()+3)
		else
			return 0
		end
	end
}
	["jiexian_tianzi"] = "天姿",
	[":jiexian_tianzi"] = "<font color=\"blue\"><b>锁定技，</b></font>摸牌阶段摸牌时，你额外摸三张牌；你的手牌上限不会因体力值的减少而减少。",
	jiexian_zhouyu:addSkill(jiexian_tianzi)
 	jiexian_zhouyu:addSkill(jiexian_tianzi_keep)
	extension:insertRelatedSkills("jiexian_tianzi", "#jiexian_tianzi")
