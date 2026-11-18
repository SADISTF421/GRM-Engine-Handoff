function actor_binder:save(packet)
    pcall(function() sl_sidecar_manager.before_save() end)


    pcall(function() shiza_skeleton_illusion.before_save() end)
    pcall(function() shiza_bar_light_flicker.before_save() end)
	
	local save_treasure_manager = true
	
	printf("actor_binder:save(): self.object:name()='%s'", self.object:name())
	object_binder.save(self, packet)


	 
	if save_treasure_manager == true then
		packet:w_u8(level.get_game_difficulty() + 128)
	else
		packet:w_u8(level.get_game_difficulty())
	end


	 
	if self.st.disable_input_time == nil then
		packet:w_bool(false)
	else
		packet:w_bool(true)
		utils.w_CTime(packet, self.st.disable_input_time)
	end

     
    shiza_hud_items.save_state(self.object)
    shiza_radiation.save_state(self.object)
    shiza_vodka.save_state(self.object)
    shiza_kill_stress.save_state(self.object)
    shiza_syringe.save_state(self.object)
	xr_logic.pstor_save_all(self.object, packet)

	self.weather_manager:save(packet)


	sr_psy_antenna.save( packet )

	
	if save_treasure_manager == true then
		treasure_manager.save(packet)
      
	end                                  

	task_manager.save(packet)

	self.actor_detector:save(packet)
	
end
 
function actor_binder:load(reader)
	printf("actor_binder:load(): self.object:name()='%s'", self.object:name())
	object_binder.load(self, reader)
	printf("actor_binder:object_binder.load(): self.object:name()='%s'", self.object:name())

	 
	local game_difficulty = reader:r_u8()
	
	local load_treasure_manager = false      
	if game_difficulty >= 128 then           
		game_difficulty = game_difficulty - 128
		load_treasure_manager = true           
	end                                      

	
	local grm_difficulty_name = game_difficulty_by_num[game_difficulty]
	if grm_difficulty_name ~= nil then
		get_console():execute("g_game_difficulty "..grm_difficulty_name)
	else
		printf("! [GRM_P1] Unknown difficulty value=%s; treasure=%s; retaining current setting", tostring(game_difficulty), tostring(load_treasure_manager))
	end

	if reader:r_eof() then
		abort("SAVE FILE IS CORRUPT")
	end

	local stored_input_time = reader:r_u8()
	if stored_input_time ~= 0 then
		self.st.disable_input_time = utils.r_CTime(reader)
		-- Длительность паузы не сохранялась: безопасно завершаем её после загрузки.
		self.st.disable_input_idle = self.st.disable_input_idle or 0
	end

	xr_logic.pstor_load_all(self.object, reader)
     
    shiza_hud_items.queue_load_state(self.object)
    shiza_radiation.queue_load_state(self.object)
    shiza_vodka.queue_load_state(self.object)
    shiza_kill_stress.queue_load_state(self.object)
    shiza_syringe.queue_load_state(self.object)
	self.weather_manager:load(reader)

	sr_psy_antenna.load(reader)
	
	if load_treasure_manager == true then
		treasure_manager.load(reader)      
	end                                  

	
	task_manager.load(reader)
	self.actor_detector:load(reader)	
    pcall(function() grm_eyes_open.queue_load() end)
end
 

 
 
 
 


 
