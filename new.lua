LuaXinmouCard = sgs.CreateSkillCard{
   name = "LuaXinmouCard",
   target_fixed = true,
   will_throw = true,
   on_use = function(self, room, source, targets)
      --execution Guanxing
      local ids = self:getSubcards()
      room:askForGuanxing(source, ids, false)
}

LuaXinmou = sgs.CreateViewAsSkill{
   name = "LuaXinmou",
   n = 1,
   view_filter = function(self, targets, to_select)
      return true
   end,
   view_as = function(self, cards)
      if #cards > 0 then
         --SkillCard
         local vs_card = LuaXinmouCard:clone()
         --addCard
         for _,card in pairs(cards) do
            vs_card: addSubcard(card)
         end
         return vs_card
      end,
      enabled_at_play = function(self, player)
         return not player:isNude()
      end
}
