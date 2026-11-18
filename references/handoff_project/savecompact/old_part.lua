function CRandomTask:save(p)
	printf("^^^ SAVE")
	--' Считаем количество записей
	local i = 0
	for k,v in pairs(self.task_info) do
		i = i + 1
	end
	p:w_u8(i)
	for k,v in pairs(self.task_info) do
		p:w_stringZ(k) 
		p:w_bool(v.enabled)	
		p:w_bool(v.enabled_props)
		p:w_stringZ(v.status)
		p:w_u32(v.selected_target or -1)
		utils.w_CTime(p, v.last_task_time)
	end

	--' Та же самая процедура с активными тасками
	i = 0
	for k,v in pairs(self.active_task_by_type) do
		i = i + 1
	end
	p:w_u8(i)
	for k,v in pairs(self.active_task_by_type) do
		p:w_stringZ(k) 
		p:w_stringZ(v)
	end
end
--' Загрузка
function CRandomTask:load(p)
	printf("^^^ LOAD")
	--' Считаем количество записей
	
	local i = p:r_u8()
	for k = 1,i do
		local id = p:r_stringZ()
		self.task_info[id].enabled = p:r_bool()
		self.task_info[id].enabled_props = p:r_bool()
		self.task_info[id].status = p:r_stringZ()

		local selected_target = p:r_u32()
		if selected_target ~= -1 then
			self.task_info[id].selected_target = selected_target
		end
		self.task_info[id].last_task_time = utils.r_CTime(p)
		
		if self.task_info[id].type == "defend_lager" then                                                           
			local defend_object = alife():object(self.task_info[id].selected_target)                                  
			local sm_ini = defend_object:spawn_ini()                                                                  
			self.task_info[id].defend_target = utils.cfg_get_number(sm_ini, "random_task", "defend_target", nil, true)
		end                                                                                                         

	end
	
	
	
	
	--' Та же самая процедура с активными тасками
	local i = p:r_u8()	
	for k = 1,i do
		local id = p:r_stringZ()
		self.active_task_by_type[id] = p:r_stringZ()	
	end
end
--' Генератор уникальных ID для фраз
