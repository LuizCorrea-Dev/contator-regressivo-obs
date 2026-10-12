obs           = obslua
source_name   = ""

stop_text     = ""
mode          = ""
a_mode        = ""
format        = ""
activated     = false
global        = false
timer_active  = false
settings_     = nil
orig_time     = 0
cur_time      = 0
cur_ns        = 0
up_when_finished = false
up            = false
paused        = false
switch_to_scene = false
next_scene    = ""

-- Recursos de ocultar após término:
hide_after_finish = false
hide_delay_sec    = 0
timer_finished    = false
finish_timestamp_ns = 0
source_was_hidden = false

hotkey_id_reset     = obs.OBS_INVALID_HOTKEY_ID
hotkey_id_pause     = obs.OBS_INVALID_HOTKEY_ID

function delta_time(year, month, day, hour, minute, second)
	local now = os.time()

	if (year == -1) then
		year = os.date("%Y", now)
	end

	if (month == -1) then
		month = os.date("%m", now)
	end

	if (day == -1) then
		day = os.date("%d", now)
	end

	local future = os.time{year=year, month=month, day=day, hour=hour, min=minute, sec=second}
	local seconds = os.difftime(future, now)

	if (seconds < 0) then
		seconds = seconds + 86400
	end

	return seconds * 1000000000
end

-- Define a visibilidade do item de texto na cena atual
function set_source_visibility(visible)
	if source_name == nil or source_name == "" then
		return
	end

	local current_scene_source = obs.obs_frontend_get_current_scene()
	if current_scene_source ~= nil then
		local scene = obs.obs_scene_from_source(current_scene_source)
		if scene ~= nil then
			local scene_item = obs.obs_scene_find_source(scene, source_name)
			if scene_item ~= nil then
				obs.obs_sceneitem_set_visible(scene_item, visible)
			end
		end
		obs.obs_source_release(current_scene_source)
	end
end

-- Verifica se a fonte de texto selecionada está presente na cena especificada
function is_source_in_scene(scene_source)
	if scene_source == nil or source_name == nil or source_name == "" then
		return false
	end
	local scene = obs.obs_scene_from_source(scene_source)
	if scene ~= nil then
		local scene_item = obs.obs_scene_find_source(scene, source_name)
		return scene_item ~= nil
	end
	return false
end

function set_time_text(ns, text)
	local ms = math.floor(ns / 1000000)

	if string.match(text, "%%0H") then
		local hours_infinite = math.floor(ms / 3600000)
		hours_infinite = string.format("%02d", hours_infinite)
		text = string.gsub(text, "%%0H", hours_infinite)
	end

	if string.match(text, "%%0M") then
		local minutes_infinite = math.floor(ms / 60000)
		minutes_infinite = string.format("%02d", minutes_infinite)
		text = string.gsub(text, "%%0M", minutes_infinite)
	end

	if string.match(text, "%%0S") then
		local seconds_infinite = math.floor(ms / 1000)
		seconds_infinite = string.format("%02d", seconds_infinite)
		text = string.gsub(text, "%%0S", seconds_infinite)
	end

	if string.match(text, "%%0h") then
		local hours = math.floor(ms / 3600000) % 24
		hours = string.format("%02d", hours)
		text = string.gsub(text, "%%0h", hours)
	end

	if string.match(text, "%%0m") then
		local minutes = math.floor(ms / 60000) % 60
		minutes = string.format("%02d", minutes)
		text = string.gsub(text, "%%0m", minutes)
	end

	if string.match(text, "%%0s") then
		local seconds = math.floor(ms / 1000) % 60
		seconds = string.format("%02d", seconds)
		text = string.gsub(text, "%%0s", seconds)
	end

	if string.match(text, "%%H") then
		local hours_infinite = math.floor(ms / 3600000)
		text = string.gsub(text, "%%H", hours_infinite)
	end

	if string.match(text, "%%M") then
		local minutes_infinite = math.floor(ms / 60000)
		text = string.gsub(text, "%%M", minutes_infinite)
	end

	if string.match(text, "%%S") then
		local seconds_infinite = math.floor(ms / 1000)
		text = string.gsub(text, "%%S", seconds_infinite)
	end

	if string.match(text, "%%h") then
		local hours = math.floor(ms / 3600000) % 24
		text = string.gsub(text, "%%h", hours)
	end

	if string.match(text, "%%m") then
		local minutes = math.floor(ms / 60000) % 60
		text = string.gsub(text, "%%m", minutes)
	end

	if string.match(text, "%%s") then
		local seconds = math.floor(ms / 1000) % 60
		text = string.gsub(text, "%%s", seconds)
	end

	if string.match(text, "%%d") then
		local days = math.floor(ms / 86400000)
		text = string.gsub(text, "%%d", tostring(days))
	end

	local decimal = string.format("%.3d", ms % 1000)

	if string.match(text, "%%3t") then
		decimal = string.sub(decimal, 1, 3)
		text = string.gsub(text, "%%3t", decimal)
	end

	if string.match(text, "%%2t") then
		decimal = string.sub(decimal, 1, 2)
		text = string.gsub(text, "%%2t", decimal)
	end

	if string.match(text, "%%t") then
		decimal = string.sub(decimal, 1, 1)
		text = string.gsub(text, "%%t", decimal)
	end

	local source = obs.obs_get_source_by_name(source_name)
	if source ~= nil then
		local settings = obs.obs_data_create()
		obs.obs_data_set_string(settings, "text", text)
		obs.obs_source_update(source, settings)
		obs.obs_data_release(settings)
		obs.obs_source_release(source)
	end
end

function on_event(event)
	if event == obs.OBS_FRONTEND_EVENT_SCENE_CHANGED then
		if not global then
			local cur_scene_source = obs.obs_frontend_get_current_scene()
			if cur_scene_source ~= nil then
				local has_source = is_source_in_scene(cur_scene_source)
				obs.obs_source_release(cur_scene_source)

				if has_source then
					activate(true)
				else
					activate(false)
				end
			end
		end
	elseif event == obs.OBS_FRONTEND_EVENT_STREAMING_STARTED then
		if mode == "Streaming timer" then
			cur_time = 0
			stop_timer()
			start_timer()
		end
	elseif event == obs.OBS_FRONTEND_EVENT_STREAMING_STOPPED then
		if mode == "Streaming timer" then
			stop_timer()
		end
	elseif event == obs.OBS_FRONTEND_EVENT_RECORDING_STARTED then
		if mode == "Recording timer" then
			cur_time = 0
			stop_timer()
			start_timer()
		end
	elseif event == obs.OBS_FRONTEND_EVENT_RECORDING_STOPPED then
		if mode == "Recording timer" then
			stop_timer()
		end
	end
end

function script_tick(sec)
	if timer_finished and hide_after_finish and not source_was_hidden then
		local elapsed_since_finish_ns = obs.os_gettime_ns() - finish_timestamp_ns
		if elapsed_since_finish_ns >= (hide_delay_sec * 1000000000) then
			set_source_visibility(false)
			source_was_hidden = true
		end
	end

	if timer_active == false then
		return
	end

	local delta = obs.os_gettime_ns() - orig_time

	if mode == "Countup" or mode == "Streaming timer" or mode == "Recording timer" or up == true then
		cur_ns = cur_time + delta
	else
		cur_ns = cur_time - delta
	end

	if cur_ns < 1 and (mode == "Countdown" or mode == "Specific time" or mode == "Specific date and time") then
		if up_when_finished == false then
			stop_timer()
			timer_finished = true
			finish_timestamp_ns = obs.os_gettime_ns()

			if next_scene ~= "" and switch_to_scene == true then
				local target_scene_source = obs.obs_get_source_by_name(next_scene)
				if target_scene_source ~= nil then
					obs.obs_frontend_remove_event_callback(on_event)
					obs.obs_frontend_set_current_scene(target_scene_source)
					obs.obs_frontend_add_event_callback(on_event)
					obs.obs_source_release(target_scene_source)
				end
			end

			set_time_text(0, stop_text)
			return
		else
			cur_time = 0
			up = true
			start_timer()
			return
		end
	end

	set_time_text(cur_ns, format)
end

function start_timer()
	timer_active = true
	orig_time = obs.os_gettime_ns()
end

function stop_timer()
	timer_active = false
end

function activate(activating)
	if (mode == "Streaming timer" or mode == "Recording timer") then
		return
	end

	activated = activating

	if activating then
		if global then
			return
		end
		paused = false
		script_update(settings_)
		start_timer()
	else
		if not global then
			stop_timer()
			paused = false
			script_update(settings_)
			stop_timer()
		end
	end
end

function activate_signal(cd, activating)
	local source = obs.calldata_source(cd, "source")
	if source ~= nil then
		local name = obs.obs_source_get_name(source)
		if (name == source_name) then
			activate(activating)
		end
	end
end

function source_activated(cd)
	activate_signal(cd, true)
end

function source_deactivated(cd)
	activate_signal(cd, false)
end

function reset(pressed)
	if not pressed then
		return
	end

	if mode == "Streaming timer" or mode == "Recording timer" then
		return
	end

	script_update(settings_)
end

function on_pause(pressed)
	if not pressed then
		return
	end

	if mode == "Streaming timer" or mode == "Recording timer" then
		return
	end

	if cur_ns < 1 then
		reset(true)
	end

	if timer_active then
		stop_timer()
		cur_time = cur_ns
		paused = true
	else
		stop_timer()
		start_timer()
		paused = false
	end
end

function pause_button_clicked(props, p)
	on_pause(true)
	return true
end

function reset_button_clicked(props, p)
	reset(true)
	return true
end

function open_github_button_clicked(props, p)
	os.execute('start "" "https://github.com/LuizCorrea-Dev"')
	return true
end

-- Atualiza a visibilidade das propriedades conforme a etapa e o modo
function update_properties_visibility(props, settings)
	local step = obs.obs_data_get_int(settings, "wizard_step")
	if step < 1 then step = 1 end

	local p_step_info       = obs.obs_properties_get(props, "step_info")
	local p_target_scene    = obs.obs_properties_get(props, "target_scene")
	local p_auto_text_name  = obs.obs_properties_get(props, "auto_text_name")
	local p_btn_create_text = obs.obs_properties_get(props, "btn_create_text")
	local p_btn_back        = obs.obs_properties_get(props, "btn_back")

	-- Propriedades da Etapa 2:
	local p_mode            = obs.obs_properties_get(props, "mode")
	local p_duration        = obs.obs_properties_get(props, "duration")
	local p_offset          = obs.obs_properties_get(props, "offset")
	local p_year            = obs.obs_properties_get(props, "year")
	local p_month           = obs.obs_properties_get(props, "month")
	local p_day             = obs.obs_properties_get(props, "day")
	local p_hour            = obs.obs_properties_get(props, "hour")
	local p_minutes         = obs.obs_properties_get(props, "minutes")
	local p_seconds         = obs.obs_properties_get(props, "seconds")
	local p_format          = obs.obs_properties_get(props, "format")
	local p_source          = obs.obs_properties_get(props, "source")
	local p_switch_to_scene = obs.obs_properties_get(props, "switch_to_scene")
	local next_scene_prop   = obs.obs_properties_get(props, "next_scene")
	local p_stop_text       = obs.obs_properties_get(props, "stop_text")
	local p_hide_after      = obs.obs_properties_get(props, "hide_after_finish")
	local p_hide_delay      = obs.obs_properties_get(props, "hide_delay_minutes")
	local p_a_mode          = obs.obs_properties_get(props, "a_mode")
	local up_finished       = obs.obs_properties_get(props, "countup_countdown_finished")
	local button_pause      = obs.obs_properties_get(props, "pause_button")
	local button_reset      = obs.obs_properties_get(props, "reset_button")

	if step == 1 then
		obs.obs_property_set_visible(p_step_info, true)
		obs.obs_property_set_visible(p_target_scene, true)
		obs.obs_property_set_visible(p_auto_text_name, true)
		obs.obs_property_set_visible(p_btn_create_text, true)
		obs.obs_property_set_visible(p_btn_back, false)

		obs.obs_property_set_visible(p_mode, false)
		obs.obs_property_set_visible(p_duration, false)
		obs.obs_property_set_visible(p_offset, false)
		obs.obs_property_set_visible(p_year, false)
		obs.obs_property_set_visible(p_month, false)
		obs.obs_property_set_visible(p_day, false)
		obs.obs_property_set_visible(p_hour, false)
		obs.obs_property_set_visible(p_minutes, false)
		obs.obs_property_set_visible(p_seconds, false)
		obs.obs_property_set_visible(p_format, false)
		obs.obs_property_set_visible(p_source, false)
		obs.obs_property_set_visible(p_switch_to_scene, false)
		obs.obs_property_set_visible(next_scene_prop, false)
		obs.obs_property_set_visible(p_stop_text, false)
		obs.obs_property_set_visible(p_hide_after, false)
		obs.obs_property_set_visible(p_hide_delay, false)
		obs.obs_property_set_visible(p_a_mode, false)
		obs.obs_property_set_visible(up_finished, false)
		obs.obs_property_set_visible(button_pause, false)
		obs.obs_property_set_visible(button_reset, false)
	else
		obs.obs_property_set_visible(p_step_info, true)
		obs.obs_property_set_visible(p_target_scene, false)
		obs.obs_property_set_visible(p_auto_text_name, false)
		obs.obs_property_set_visible(p_btn_create_text, false)
		obs.obs_property_set_visible(p_btn_back, true)

		obs.obs_property_set_visible(p_mode, true)
		obs.obs_property_set_visible(p_format, true)
		obs.obs_property_set_visible(p_source, true)

		local mode_setting = obs.obs_data_get_string(settings, "mode")
		local enable_scene_switch = obs.obs_data_get_bool(settings, "switch_to_scene")
		obs.obs_property_set_enabled(next_scene_prop, enable_scene_switch)

		local enable_hide = obs.obs_data_get_bool(settings, "hide_after_finish")
		obs.obs_property_set_enabled(p_hide_delay, enable_hide)

		if (mode_setting == "Countdown") then
			obs.obs_property_set_visible(p_duration, true)
			obs.obs_property_set_visible(p_offset, false)
			obs.obs_property_set_visible(p_year, false)
			obs.obs_property_set_visible(p_month, false)
			obs.obs_property_set_visible(p_day, false)
			obs.obs_property_set_visible(p_hour, false)
			obs.obs_property_set_visible(p_minutes, false)
			obs.obs_property_set_visible(p_seconds, false)
			obs.obs_property_set_visible(p_stop_text, true)
			obs.obs_property_set_visible(button_pause, true)
			obs.obs_property_set_visible(button_reset, true)
			obs.obs_property_set_visible(p_a_mode, true)
			obs.obs_property_set_visible(up_finished, true)
			obs.obs_property_set_visible(p_switch_to_scene, true)
			obs.obs_property_set_visible(next_scene_prop, true)
			obs.obs_property_set_visible(p_hide_after, true)
			obs.obs_property_set_visible(p_hide_delay, true)
		elseif (mode_setting == "Countup") then
			obs.obs_property_set_visible(p_duration, false)
			obs.obs_property_set_visible(p_offset, true)
			obs.obs_property_set_visible(p_year, false)
			obs.obs_property_set_visible(p_month, false)
			obs.obs_property_set_visible(p_day, false)
			obs.obs_property_set_visible(p_hour, false)
			obs.obs_property_set_visible(p_minutes, false)
			obs.obs_property_set_visible(p_seconds, false)
			obs.obs_property_set_visible(p_stop_text, false)
			obs.obs_property_set_visible(button_pause, true)
			obs.obs_property_set_visible(button_reset, true)
			obs.obs_property_set_visible(p_a_mode, true)
			obs.obs_property_set_visible(up_finished, false)
			obs.obs_property_set_visible(p_switch_to_scene, false)
			obs.obs_property_set_visible(next_scene_prop, false)
			obs.obs_property_set_visible(p_hide_after, false)
			obs.obs_property_set_visible(p_hide_delay, false)
		elseif (mode_setting == "Specific time") then
			obs.obs_property_set_visible(p_duration, false)
			obs.obs_property_set_visible(p_offset, false)
			obs.obs_property_set_visible(p_year, false)
			obs.obs_property_set_visible(p_month, false)
			obs.obs_property_set_visible(p_day, false)
			obs.obs_property_set_visible(p_hour, true)
			obs.obs_property_set_visible(p_minutes, true)
			obs.obs_property_set_visible(p_seconds, true)
			obs.obs_property_set_visible(p_stop_text, true)
			obs.obs_property_set_visible(button_pause, true)
			obs.obs_property_set_visible(button_reset, true)
			obs.obs_property_set_visible(p_a_mode, true)
			obs.obs_property_set_visible(up_finished, true)
			obs.obs_property_set_visible(p_switch_to_scene, true)
			obs.obs_property_set_visible(next_scene_prop, true)
			obs.obs_property_set_visible(p_hide_after, true)
			obs.obs_property_set_visible(p_hide_delay, true)
		elseif (mode_setting == "Specific date and time") then
			obs.obs_property_set_visible(p_duration, false)
			obs.obs_property_set_visible(p_offset, false)
			obs.obs_property_set_visible(p_year, true)
			obs.obs_property_set_visible(p_month, true)
			obs.obs_property_set_visible(p_day, true)
			obs.obs_property_set_visible(p_hour, true)
			obs.obs_property_set_visible(p_minutes, true)
			obs.obs_property_set_visible(p_seconds, true)
			obs.obs_property_set_visible(p_stop_text, true)
			obs.obs_property_set_visible(button_pause, true)
			obs.obs_property_set_visible(button_reset, true)
			obs.obs_property_set_visible(p_a_mode, true)
			obs.obs_property_set_visible(up_finished, true)
			obs.obs_property_set_visible(p_switch_to_scene, true)
			obs.obs_property_set_visible(next_scene_prop, true)
			obs.obs_property_set_visible(p_hide_after, true)
			obs.obs_property_set_visible(p_hide_delay, true)
		elseif (mode_setting == "Streaming timer") then
			obs.obs_property_set_visible(p_duration, false)
			obs.obs_property_set_visible(p_offset, false)
			obs.obs_property_set_visible(p_year, false)
			obs.obs_property_set_visible(p_month, false)
			obs.obs_property_set_visible(p_day, false)
			obs.obs_property_set_visible(p_hour, false)
			obs.obs_property_set_visible(p_minutes, false)
			obs.obs_property_set_visible(p_seconds, false)
			obs.obs_property_set_visible(p_stop_text, false)
			obs.obs_property_set_visible(button_pause, false)
			obs.obs_property_set_visible(button_reset, false)
			obs.obs_property_set_visible(p_a_mode, false)
			obs.obs_property_set_visible(up_finished, false)
			obs.obs_property_set_visible(p_switch_to_scene, false)
			obs.obs_property_set_visible(next_scene_prop, false)
			obs.obs_property_set_visible(p_hide_after, false)
			obs.obs_property_set_visible(p_hide_delay, false)
		elseif (mode_setting == "Recording timer") then
			obs.obs_property_set_visible(p_duration, false)
			obs.obs_property_set_visible(p_offset, false)
			obs.obs_property_set_visible(p_year, false)
			obs.obs_property_set_visible(p_month, false)
			obs.obs_property_set_visible(p_day, false)
			obs.obs_property_set_visible(p_hour, false)
			obs.obs_property_set_visible(p_minutes, false)
			obs.obs_property_set_visible(p_seconds, false)
			obs.obs_property_set_visible(p_stop_text, false)
			obs.obs_property_set_visible(button_pause, false)
			obs.obs_property_set_visible(button_reset, false)
			obs.obs_property_set_visible(p_a_mode, false)
			obs.obs_property_set_visible(up_finished, false)
			obs.obs_property_set_visible(p_switch_to_scene, false)
			obs.obs_property_set_visible(next_scene_prop, false)
			obs.obs_property_set_visible(p_hide_after, false)
			obs.obs_property_set_visible(p_hide_delay, false)
		end
	end
end

-- Automatização: Cria a fonte Texto (GDI+) na cena selecionada e vincula ao script
function create_text_source_action(props, p)
	if settings_ == nil then
		return false
	end

	local target_scene_name = obs.obs_data_get_string(settings_, "target_scene")
	if target_scene_name == nil or target_scene_name == "" then
		-- Tenta usar a cena atual caso nenhuma esteja explicitamente selecionada
		local cur = obs.obs_frontend_get_current_scene()
		if cur ~= nil then
			target_scene_name = obs.obs_source_get_name(cur)
			obs.obs_data_set_string(settings_, "target_scene", target_scene_name)
			obs.obs_source_release(cur)
		end
	end

	if target_scene_name == nil or target_scene_name == "" then
		return false
	end

	local auto_name = obs.obs_data_get_string(settings_, "auto_text_name")
	if auto_name == nil or auto_name == "" then
		auto_name = "Temporizador"
	end

	local scene_source = obs.obs_get_source_by_name(target_scene_name)
	if scene_source == nil then
		return false
	end

	local scene = obs.obs_scene_from_source(scene_source)
	if scene == nil then
		obs.obs_source_release(scene_source)
		return false
	end

	local existing_source = obs.obs_get_source_by_name(auto_name)
	local text_source = nil

	if existing_source ~= nil then
		text_source = existing_source
	else
		local text_settings = obs.obs_data_create()
		obs.obs_data_set_string(text_settings, "text", "05:00")
		text_source = obs.obs_source_create("text_gdiplus_v2", auto_name, text_settings, nil)
		if text_source == nil then
			text_source = obs.obs_source_create("text_gdiplus", auto_name, text_settings, nil)
		end
		obs.obs_data_release(text_settings)
	end

	if text_source ~= nil then
		local scene_item = obs.obs_scene_find_source(scene, auto_name)
		if scene_item == nil then
			obs.obs_scene_add(scene, text_source)
		end

		obs.obs_data_set_string(settings_, "source", auto_name)
		source_name = auto_name

		-- Atualiza a lista de fontes de texto das propriedades para incluir a nova
		local p_source = obs.obs_properties_get(props, "source")
		if p_source ~= nil then
			obs.obs_property_list_add_string(p_source, auto_name, auto_name)
		end

		-- Avança para a Etapa 2
		obs.obs_data_set_int(settings_, "wizard_step", 2)

		obs.obs_source_release(text_source)
		obs.obs_source_release(scene_source)

		update_properties_visibility(props, settings_)
		script_update(settings_)
		return true
	end

	obs.obs_source_release(scene_source)
	return false
end

function prev_step_button_clicked(props, p)
	if settings_ ~= nil then
		obs.obs_data_set_int(settings_, "wizard_step", 1)
		update_properties_visibility(props, settings_)
		return true
	end
	return false
end

function settings_modified(props, prop, settings)
	update_properties_visibility(props, settings)
	return true
end

function script_properties()
	local props = obs.obs_properties_create()

	-- Seletor de Etapa (1: Criar Texto na Cena / 2: Configurar Temporizador)
	local p_step = obs.obs_properties_add_list(props, "wizard_step", "Etapa", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_INT)
	obs.obs_property_list_add_int(p_step, "Etapa 1: Selecionar Cena e Criar Texto", 1)
	obs.obs_property_list_add_int(p_step, "Etapa 2: Configurações do Temporizador", 2)
	obs.obs_property_set_modified_callback(p_step, settings_modified)

	-- Instruções / Status
	obs.obs_properties_add_text(props, "step_info", "Instrução", obs.OBS_TEXT_INFO)

	-- ETAPA 1: Seleção de Cena e Criação Automática
	local p_target = obs.obs_properties_add_list(props, "target_scene", "1. Escolha a Cena para o Contador", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
	local scenes = obs.obs_frontend_get_scenes()
	if scenes ~= nil then
		for _, sc in ipairs(scenes) do
			local name = obs.obs_source_get_name(sc)
			obs.obs_property_list_add_string(p_target, name, name)
		end
		obs.source_list_release(scenes)
	end

	obs.obs_properties_add_text(props, "auto_text_name", "Nome da Fonte de Texto (GDI+)", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_button(props, "btn_create_text", "➡️ Criar Texto e Avançar para Configuração", create_text_source_action)

	-- Botão para voltar à Etapa 1
	obs.obs_properties_add_button(props, "btn_back", "⬅️ Voltar para Escolha de Cena", prev_step_button_clicked)

	-- ETAPA 2: Propriedades do Temporizador
	local p_mode = obs.obs_properties_add_list(props, "mode", "Modo do Temporizador", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
	obs.obs_property_list_add_string(p_mode, "Contagem Regressiva (Countdown)", "Countdown")
	obs.obs_property_list_add_string(p_mode, "Contagem Progressiva (Countup)", "Countup")
	obs.obs_property_list_add_string(p_mode, "Horário Específico (Hoje)", "Specific time")
	obs.obs_property_list_add_string(p_mode, "Data e Horário Específicos", "Specific date and time")
	obs.obs_property_list_add_string(p_mode, "Tempo de Transmissão (Live)", "Streaming timer")
	obs.obs_property_list_add_string(p_mode, "Tempo de Gravação", "Recording timer")
	obs.obs_property_set_modified_callback(p_mode, settings_modified)

	obs.obs_properties_add_int(props, "duration", "Duração da contagem (segundos)", 1, 100000000, 1)
	obs.obs_properties_add_int(props, "offset", "Iniciar contagem progressiva a partir de (segundos)", 0, 100000000, 1)
	obs.obs_properties_add_int(props, "year", "Ano", 1971, 100000000, 1)
	obs.obs_properties_add_int(props, "month", "Mês (1-12)", 1, 12, 1)
	obs.obs_properties_add_int(props, "day", "Dia (1-31)", 1, 31, 1)
	obs.obs_properties_add_int(props, "hour", "Hora (0-24)", 0, 24, 1)
	obs.obs_properties_add_int(props, "minutes", "Minutos (0-59)", 0, 59, 1)
	obs.obs_properties_add_int(props, "seconds", "Segundos (0-59)", 0, 59, 1)

	local f_prop = obs.obs_properties_add_text(props, "format", "Formato de Exibição", obs.OBS_TEXT_MULTILINE)
	obs.obs_property_set_long_description(f_prop, "%d - dias\n%0h - horas com zero à esquerda (00..23)\n%h - horas (0..23)\n%0H - horas totais com zero (00..infinito)\n%H - horas totais (0..infinito)\n%0m - minutos com zero à esquerda (00..59)\n%m - minutos (0..59)\n%0M - minutos totais com zero (00..infinito)\n%M - minutos totais (0..infinito)\n%0s - segundos com zero à esquerda (00..59)\n%s - segundos (0..59)\n%0S - segundos totais com zero (00..infinito)\n%S - segundos totais (0..infinito)\n%t - décimos de segundo\n%2t - centésimos de segundo\n%3t - milésimos de segundo")

	local p_source = obs.obs_properties_add_list(props, "source", "Fonte de Texto Vinculada", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			local source_id = obs.obs_source_get_unversioned_id(source)
			if source_id == "text_gdiplus" or source_id == "text_ft2_source" or source_id == "text_gdiplus_v2" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(p_source, name, name)
			end
		end
		obs.source_list_release(sources)
	end

	local switch_scene = obs.obs_properties_add_bool(props, "switch_to_scene", "Mudar de cena ao terminar")
	obs.obs_property_set_modified_callback(switch_scene, settings_modified)
	local p_next = obs.obs_properties_add_list(props, "next_scene", "Cena de Destino", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local scenes2 = obs.obs_frontend_get_scenes()
	if scenes2 ~= nil then
		for _, scene in ipairs(scenes2) do
			local name = obs.obs_source_get_name(scene)
			obs.obs_property_list_add_string(p_next, name, name)
		end
		obs.source_list_release(scenes2)
	end

	obs.obs_properties_add_text(props, "stop_text", "Mensagem ao finalizar a contagem", obs.OBS_TEXT_DEFAULT)

	local hide_prop = obs.obs_properties_add_bool(props, "hide_after_finish", "Ocultar da tela após o término")
	obs.obs_property_set_modified_callback(hide_prop, settings_modified)
	obs.obs_properties_add_float(props, "hide_delay_minutes", "Tempo para sumir da tela (em minutos)", 0.0, 1440.0, 0.5)

	local p_a_mode = obs.obs_properties_add_list(props, "a_mode", "Modo de Ativação", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
	obs.obs_property_list_add_string(p_a_mode, "Iniciar/Resetar ao carregar a cena", "start_reset")
	obs.obs_property_list_add_string(p_a_mode, "Global (temporizador sempre ativo)", "global")
	obs.obs_properties_add_bool(props, "countup_countdown_finished", "Continuar contagem progressiva após o fim")

	obs.obs_properties_add_button(props, "pause_button", "Iniciar / Pausar", pause_button_clicked)
	obs.obs_properties_add_button(props, "reset_button", "Resetar", reset_button_clicked)

	obs.obs_properties_add_button(props, "github_button", "by Rootszera  |  github.com/LuizCorrea-Dev", open_github_button_clicked)

	if settings_ ~= nil then
		update_properties_visibility(props, settings_)
	end

	return props
end

function script_description()
	return "Temporizador Avançado para OBS Studio em Português (Brasil).\n\nAssistente em duas etapas: selecione a cena na primeira tela e clique no botão para criar a fonte Texto (GDI+) automaticamente. Em seguida, personalize o contador na segunda tela!"
end

function script_update(settings)
	stop_timer()
	up = false
	timer_finished = false
	finish_timestamp_ns = 0
	source_was_hidden = false

	set_source_visibility(true)

	local step = obs.obs_data_get_int(settings, "wizard_step")
	local step_info = "Etapa 1: Selecione a cena desejada e clique no botão abaixo para criar a fonte de texto."
	if step == 2 then
		step_info = "Etapa 2: A fonte foi criada e vinculada na cena! Configure o temporizador abaixo."
	end
	obs.obs_data_set_string(settings, "step_info", step_info)

	mode = obs.obs_data_get_string(settings, "mode")
	a_mode = obs.obs_data_get_string(settings, "a_mode")
	source_name = obs.obs_data_get_string(settings, "source")
	stop_text = obs.obs_data_get_string(settings, "stop_text")
	local year = obs.obs_data_get_int(settings, "year")
	local month = obs.obs_data_get_int(settings, "month")
	local day = obs.obs_data_get_int(settings, "day")
	local hour = obs.obs_data_get_int(settings, "hour")
	local minute = obs.obs_data_get_int(settings, "minutes")
	local second = obs.obs_data_get_int(settings, "seconds")
	format = obs.obs_data_get_string(settings, "format")
	up_when_finished = obs.obs_data_get_bool(settings, "countup_countdown_finished")
	switch_to_scene = obs.obs_data_get_bool(settings, "switch_to_scene")
	next_scene = obs.obs_data_get_string(settings, "next_scene")

	hide_after_finish = obs.obs_data_get_bool(settings, "hide_after_finish")
	local delay_mins = obs.obs_data_get_double(settings, "hide_delay_minutes")
	hide_delay_sec = delay_mins * 60

	if mode == "Countdown" then
		cur_time = obs.obs_data_get_int(settings, "duration") * 1000000000
	elseif mode == "Countup" then
		cur_time = obs.obs_data_get_int(settings, "offset") * 1000000000
	elseif mode == "Specific time" then
		cur_time = delta_time(-1, -1, -1, hour, minute, second)
	elseif mode == "Specific date and time" then
		cur_time = delta_time(year, month, day, hour, minute, second)
	else
		cur_time = 0
	end

	global = (a_mode == "global" or a_mode == "Global (temporizador sempre ativo)" or a_mode == "Global (timer always active)")

	if mode == "Streaming timer" or mode == "Recording timer" then
		global = true
	end

	set_time_text(cur_time, format)

	if global == false and paused == false then
		local cur_scene_source = obs.obs_frontend_get_current_scene()
		if cur_scene_source ~= nil then
			local has_source = is_source_in_scene(cur_scene_source)
			obs.obs_source_release(cur_scene_source)
			if has_source then
				start_timer()
			end
		else
			start_timer()
		end
	end
end

function script_defaults(settings)
	obs.obs_data_set_default_int(settings, "wizard_step", 1)
	obs.obs_data_set_default_string(settings, "auto_text_name", "Temporizador")
	obs.obs_data_set_default_string(settings, "step_info", "Etapa 1: Selecione a cena desejada e clique no botão abaixo para criar a fonte de texto.")
	obs.obs_data_set_default_int(settings, "duration", 300)
	obs.obs_data_set_default_int(settings, "offset", 0)
	obs.obs_data_set_default_int(settings, "year", tonumber(os.date("%Y", os.time())))
	obs.obs_data_set_default_int(settings, "month", tonumber(os.date("%m", os.time())))
	obs.obs_data_set_default_int(settings, "day", tonumber(os.date("%d", os.time())))
	obs.obs_data_set_default_string(settings, "stop_text", "Começando em instantes!")
	obs.obs_data_set_default_string(settings, "mode", "Countdown")
	obs.obs_data_set_default_string(settings, "a_mode", "start_reset")
	obs.obs_data_set_default_string(settings, "format", "%0m:%0s")
	obs.obs_data_set_default_bool(settings, "hide_after_finish", true)
	obs.obs_data_set_default_double(settings, "hide_delay_minutes", 1.0)
end

function script_save(settings)
	local hotkey_save_array_reset = obs.obs_hotkey_save(hotkey_id_reset)
	local hotkey_save_array_pause = obs.obs_hotkey_save(hotkey_id_pause)
	obs.obs_data_set_array(settings, "reset_hotkey", hotkey_save_array_reset)
	obs.obs_data_set_array(settings, "pause_hotkey", hotkey_save_array_pause)
	obs.obs_data_array_release(hotkey_save_array_pause)
	obs.obs_data_array_release(hotkey_save_array_reset)
end

function script_load(settings)
	local sh = obs.obs_get_signal_handler()
	obs.signal_handler_connect(sh, "source_activate", source_activated)
	obs.signal_handler_connect(sh, "source_deactivate", source_deactivated)

	hotkey_id_reset = obs.obs_hotkey_register_frontend("reset_timer_thingy", "Resetar Temporizador", reset)
	hotkey_id_pause = obs.obs_hotkey_register_frontend("pause_timer", "Iniciar/Pausar Temporizador", on_pause)
	local hotkey_save_array_reset = obs.obs_data_get_array(settings, "reset_hotkey")
	local hotkey_save_array_pause = obs.obs_data_get_array(settings, "pause_hotkey")
	obs.obs_hotkey_load(hotkey_id_reset, hotkey_save_array_reset)
	obs.obs_hotkey_load(hotkey_id_pause, hotkey_save_array_pause)
	obs.obs_data_array_release(hotkey_save_array_reset)
	obs.obs_data_array_release(hotkey_save_array_pause)

	obs.obs_frontend_add_event_callback(on_event)

	settings_ = settings

	script_update(settings)
end
