--本文件专用于测试
module("extensions.text", package.seeall);extension = sgs.Package("text")
exam = sgs.General(extension, "exam", "god", 5)


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
jiexian_tieqi = sgs.CreateTriggerSkill {
	name = "jiexian_tieqi",
	events = {sgs.TargetConfirmed},

	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if player:objectName() ~= use.from:objectName() or not use.card:isKindOf("Slash") then return end
		local jink_list = player:getTag("Jink_"..use.card:toString()):toIntList()
		local index = 0
		local room = player:getRoom()
		local new_jink_list = sgs.IntList()
		local current = room:getCurrent()
		if not current or current:getPhase() == sgs.Player_NotActive or current:isDead() then return end
		for _, p in sgs.qlist(use.to) do
			local d = sgs.QVariant()
			d:setValue(p)
			if player:askForSkillInvoke(self:objectName(), d) then
				room:setPlayerFlag(p, "TieqiTarget")
				room:addPlayerMark(p, "@skill_invalidity")
				room:setPlayerMark(current, "Tieqi", 1)
				-- for skills
				local lose_skills = p:getTag("TieqiSkills"):toString():split("+")
				local skills = p:getVisibleSkillList()
				for _, skill in sgs.qlist(skills) do
					if skill:getLocation() == sgs.Skill_Right and not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() and not (Set(lose_skills))[skill:objectName()] then
						if not fuckYoka(skill) then
							room:addPlayerMark(p, "Qingcheng"..skill:objectName())
							table.insert(lose_skills, skill:objectName())
							-- for such as juxiang,huoshou
							for _, sk in sgs.qlist(sgs.Sanguosha:getRelatedSkills(skill:objectName())) do
								room:addPlayerMark(p, "Qingcheng"..sk:objectName())
							end
						end
					end
				end
				p:setTag("TieqiSkills", sgs.QVariant(table.concat(lose_skills, "+")))

				local judge = sgs.JudgeStruct()
				judge.reason = self:objectName()
				judge.play_animation = false
				judge.who = player

				room:judge(judge)

				if not room:askForCard(p, ".."..string.upper(string.sub(judge.card:getSuitString(), 1, 1)), "tieqi-discard") then
					local log = sgs.LogMessage()
					log.type = "#NoJink"
					log.from = p
					room:sendLog(log)
					new_jink_list:append(0)
				else
					new_jink_list:append(jink_list:at(index))
				end
			else
				new_jink_list:append(jink_list:at(index))
			end
			index = index + 1
		end
		local d = sgs.QVariant()
		d:setValue(new_jink_list)
		player:setTag("Jink_"..use.card:toString(), d)
	end
}

jiexian_tieqi_clear = sgs.CreateTriggerSkill{
	name = "#jiexian_tieqi",
	events = {sgs.EventPhaseChanging, sgs.Death},

	can_trigger = function(self, target)
		return target and target:getMark("Tieqi") > 0
	end,

	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() then return end
		end

		local room = player:getRoom()

		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:hasFlag("TieqiTarget") then
				room:setPlayerMark(p, "@skill_invalidity", 0)
				-- for skills
				local lose_skills = p:getTag("TieqiSkills"):toString():split("+")
				for _, skill_name in ipairs(lose_skills) do
					room:removePlayerMark(p, "Qingcheng"..skill_name)
					-- for such as juxiang,huoshou
					for _, sk in sgs.qlist(sgs.Sanguosha:getRelatedSkills(skill_name)) do
						room:removePlayerMark(p, "Qingcheng"..sk:objectName())
					end
				end
				p:setTag("TieqiSkills", sgs.QVariant())
			end
		end
		return false
	end,
}

exam:addSkill(jiexian_tieqi)
exam:addSkill(jiexian_tieqi_clear)
extension:insertRelatedSkills("jiexian_tieqi", "#jiexian_tieqi")

sgs.LoadTranslationTable {
	["jiexian_tieqi"] = "铁骑",
	[":jiexian_tieqi"] = "当你使用【杀】指定一名角色为目标后，你可以进行一次判定并令该角色的非锁定技失效直到回合结束，除非该角色弃置一张与判定结果花色相同的牌，否则不能使用【闪】抵消此【杀】。",
	["tieqi-discard"] = "请弃置一张与判定牌相同花色的牌",
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
