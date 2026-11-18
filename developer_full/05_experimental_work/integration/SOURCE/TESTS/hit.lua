local g,other,wound,shiza=0,0,0,0
motivator_binder={};db={actor={id=function()return 1 end,active_item=function()return {section=function()return weapon end}end}}
grm_gore_test={hit=function()g=g+1 end};grm_painter_combat={on_hit=function()other=other+1 end};sr_territory={issue_event=function()end};xr_wounded={hit_callback=function()wound=wound+1 end};function shiza_gore_on_hit()shiza=shiza+1;return false end
function motivator_binder:hit_callback(obj, amount, local_direction, who, bone_index)
	pcall(function() grm_gore_test.hit(self, amount, who, bone_index) end)
	 
	 
	if self.st.active_section then
		xr_logic.issue_event(self.object, self.st[self.st.active_scheme], "hit_callback", obj, amount, local_direction, who, bone_index)
	end
	if self.st.combat_ignore then
		xr_logic.issue_event(self.object, self.st.combat_ignore, "hit_callback", obj, amount, local_direction, who, bone_index)
	end
	if self.st.combat then
		xr_logic.issue_event(self.object, self.st.combat, "hit_callback", obj, amount, local_direction, who, bone_index)
	end
	if self.st.hit then
		xr_logic.issue_event(self.object, self.st.hit, "hit_callback", obj, amount, local_direction, who, bone_index)
	end
	if amount > 0 then
		local knife_ok, actor_knife = pcall(function()
			if not who or not db or not db.actor or who:id() ~= db.actor:id() then return false end
			local item = db.actor:active_item()
			return item and item:section() == "wpn_knife"
		end)
		local is_head, head_id = false, nil
		if not (knife_ok and actor_knife) then is_head, head_id = shiza_gore_on_hit(self.object, bone_index) end
		if self.st then
			if is_head then
				local attacker_id = nil
				if who then
					local who_ok, value = pcall(function() return who:id() end)
					if who_ok then attacker_id = tonumber(value) end
				end
				self.st.shiza_gore_last_head_hit = { time = time_global(), who_id = attacker_id }
			else
				self.st.shiza_gore_last_head_hit = nil
			end
		end
		-- Дополнительные визуальные реакции на попадание игрока.
		pcall(function() grm_painter_combat.on_hit(self, amount, who, bone_index) end)
		sr_territory.issue_event(self.object, "hit_callback", obj, amount, local_direction, who, bone_index)
		xr_wounded.hit_callback(self.object:id())
	end
end


local b={st={},object={id=function()return 7 end}};weapon='wpn_knife';motivator_binder.hit_callback(b,nil,1,nil,db.actor,13);assert(g==1 and shiza==0 and other==1 and wound==1);weapon='wpn_toz34';motivator_binder.hit_callback(b,nil,1,nil,db.actor,13);assert(g==2 and shiza==1 and other==2 and wound==2);print('PASS: actor knife skips shiza gore bone handler; other callbacks and shotgun preserved')
