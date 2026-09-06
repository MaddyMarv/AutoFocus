local mod = get_mod("autofocus")

local ffi = rawget(_G, "Mods") and Mods.lua and Mods.lua.ffi

if ffi then
	pcall(function()
		ffi.cdef[[
			typedef void* HWND;
			typedef int BOOL;
			typedef unsigned int UINT;
			typedef unsigned long DWORD;

			HWND GetForegroundWindow(void);
			BOOL SetForegroundWindow(HWND hWnd);
			BOOL ShowWindow(HWND hWnd, int nCmdShow);
			BOOL SetWindowPos(HWND hWnd, HWND hWndInsertAfter, int X, int Y, int cx, int cy, UINT uFlags);
			BOOL BringWindowToTop(HWND hWnd);
			void SwitchToThisWindow(HWND hWnd, BOOL fUnknown);
			HWND FindWindowA(const char* lpClassName, const char* lpWindowName);
		]]
	end)
end

local HWND_TOPMOST = ffi and ffi.cast("HWND", -1) or nil
local HWND_NOTOPMOST = ffi and ffi.cast("HWND", -2) or nil
local SWP_NOSIZE = 0x0001
local SWP_NOMOVE = 0x0002
local SWP_NOACTIVATE = 0x0010
local SWP_SHOWWINDOW = 0x0040
local SW_RESTORE = 9
local SW_SHOWNOACTIVATE = 4

local cached_hwnd = nil

local function get_darktide_hwnd()
	if not ffi then
		return nil
	end

	if cached_hwnd and cached_hwnd ~= ffi.cast("HWND", 0) then
		return cached_hwnd
	end

	cached_hwnd = ffi.C.FindWindowA(nil, "Warhammer 40,000: Darktide")

	if not cached_hwnd or cached_hwnd == ffi.cast("HWND", 0) then
		cached_hwnd = ffi.C.FindWindowA("stingray_window", nil)
	end

	return cached_hwnd
end

local last_focus_t = 0

local function trigger_focus(ignore_current_focus)
	if not mod:is_enabled() then
		return
	end

	local current_t = Managers.time and Managers.time:time("main") or os.clock()
	if not ignore_current_focus and (current_t - last_focus_t < 2.0) then
		return
	end

	local has_focus = rawget(_G, "Window") and Window.has_focus and Window.has_focus()

	if not ignore_current_focus and has_focus then
		return
	end

	last_focus_t = current_t

	local focus_method = mod:get("focus_method") or "force_foreground"

	if mod:get("play_sound") then
		if rawget(_G, "Wwise") and Wwise.set_state then
			Wwise.set_state("options_mute_all", "false")
		end

		local ui_manager = Managers.ui
		if ui_manager and ui_manager.play_2d_sound then
			ui_manager:play_2d_sound("wwise/events/ui/play_hud_new_objective")
		end
	end

	if rawget(_G, "Window") and Window.flash_window then
		Window.flash_window(nil, "start", 5)
	end

	if focus_method == "flash_only" then
		return
	end

	if focus_method == "bring_to_view" and ffi then
		local hwnd = get_darktide_hwnd()

		if hwnd and hwnd ~= ffi.cast("HWND", 0) then
			ffi.C.ShowWindow(hwnd, SW_SHOWNOACTIVATE)
			ffi.C.SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE + SWP_NOSIZE + SWP_SHOWWINDOW + SWP_NOACTIVATE)
			ffi.C.SetWindowPos(hwnd, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE + SWP_NOSIZE + SWP_SHOWWINDOW + SWP_NOACTIVATE)
		end
		return
	end

	if rawget(_G, "Window") and Window.set_focus then
		Window.set_focus()
	end

	if ffi then
		local hwnd = get_darktide_hwnd()

		if hwnd and hwnd ~= ffi.cast("HWND", 0) then
			ffi.C.ShowWindow(hwnd, SW_RESTORE)
			ffi.C.SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE + SWP_NOSIZE + SWP_SHOWWINDOW)
			ffi.C.SetWindowPos(hwnd, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE + SWP_NOSIZE + SWP_SHOWWINDOW)
			ffi.C.BringWindowToTop(hwnd)
			ffi.C.SetForegroundWindow(hwnd)
			ffi.C.SwitchToThisWindow(hwnd, 1)
		end
	end
end

mod.trigger_focus = trigger_focus

local previous_state = nil
local was_being_assisted = false
local was_dead = false
local has_spawned_in_mission = false
local previous_health = nil
local previous_toughness = nil

mod.update = function(dt)
	if not mod:is_enabled() then
		return
	end

	if ffi and (not cached_hwnd or cached_hwnd == ffi.cast("HWND", 0)) then
		local has_focus = rawget(_G, "Window") and Window.has_focus and Window.has_focus()
		if has_focus then
			cached_hwnd = ffi.C.GetForegroundWindow()
		end
	end

	local player_manager = Managers.player
	local player = player_manager and player_manager:local_player(1)
	local player_unit = player and player.player_unit

	if not player_unit or not Unit.alive(player_unit) then
		was_dead = true
		previous_state = nil
		was_being_assisted = false
		previous_health = nil
		previous_toughness = nil
		return
	end

	local health_extension = ScriptUnit.has_extension(player_unit, "health_system")
	local toughness_extension = ScriptUnit.has_extension(player_unit, "toughness_system")

	local current_health = health_extension and health_extension:current_health()
	local current_toughness = toughness_extension and toughness_extension:current_toughness_percent()

	if mod:get("trigger_on_hit") and not was_dead then
		if previous_health and current_health and (previous_health - current_health > 0.01) then
			trigger_focus()
		elseif previous_toughness and current_toughness and (previous_toughness - current_toughness > 0.001) then
			trigger_focus()
		end
	end

	previous_health = current_health
	previous_toughness = current_toughness

	local mechanism_manager = Managers.mechanism
	local mechanism_name = mechanism_manager and mechanism_manager:mechanism_name()
	local is_in_mission = mechanism_name and mechanism_name ~= "hub"

	if is_in_mission and not has_spawned_in_mission then
		has_spawned_in_mission = true
		if mod:get("trigger_spawn_mission") then
			trigger_focus()
		end
	end

	local unit_data_extension = ScriptUnit.has_extension(player_unit, "unit_data_system")
	if not unit_data_extension then
		return
	end

	local character_state_component = unit_data_extension:read_component("character_state")
	local current_state = character_state_component and character_state_component.state_name

	if not current_state then
		return
	end

	local assisted_state_input = unit_data_extension:read_component("assisted_state_input")
	local is_being_assisted = assisted_state_input and assisted_state_input.in_progress or false

	if previous_state == "hogtied" and current_state ~= "hogtied" then
		if mod:get("trigger_rescued") then
			trigger_focus()
		end
	end

	if not was_being_assisted and is_being_assisted then
		if mod:get("trigger_rescue_started") then
			trigger_focus()
		end
	end

	local is_incapacitated = previous_state == "knocked_down" or previous_state == "netted" or previous_state == "ledge_hanging"
	if is_incapacitated and current_state ~= previous_state and current_state ~= "dead" and current_state ~= "hogtied" then
		if mod:get("trigger_revived_downed") then
			trigger_focus()
		end
	end

	if was_dead and current_state == "hogtied" then
		if mod:get("trigger_respawned_hogtied") then
			trigger_focus()
		end
	end

	previous_state = current_state
	was_being_assisted = is_being_assisted

	if current_state == "dead" then
		was_dead = true
	else
		was_dead = false
	end
end

mod.on_game_state_changed = function(status, state_name)
	previous_state = nil
	was_being_assisted = false
	was_dead = false
	has_spawned_in_mission = false
	previous_health = nil
	previous_toughness = nil
end

mod:hook_safe(CLASS.AttackReportManager, "add_attack_result", function(self, damage_profile, attacked_unit, attacking_unit, attack_direction, hit_world_position, hit_weakspot, damage, attack_result)
	if not mod:get("trigger_on_hit") then
		return
	end

	local player_manager = Managers.player
	local player = player_manager and player_manager:local_player(1)
	local player_unit = player and player.player_unit

	if player_unit and attacked_unit == player_unit then
		if (damage and damage > 0) or (attack_result and attack_result ~= "dodged" and attack_result ~= "friendly_fire") then
			trigger_focus()
		end
	end
end)

mod:hook_safe(CLASS.GameplayStateRun, "on_enter", function(self, parent, params)
	local mechanism_manager = Managers.mechanism
	local mechanism_name = mechanism_manager and mechanism_manager:mechanism_name()

	if mechanism_name and mechanism_name ~= "hub" then
		has_spawned_in_mission = true
		if mod:get("trigger_spawn_mission") then
			trigger_focus()
		end
	end
end)

mod:hook_safe(CLASS.MissionVotingView, "on_enter", function(self)
	if mod:get("trigger_mission_vote") then
		trigger_focus()
	end
end)

mod:hook_safe(CLASS.VotingManager, "set_notification", function(self, voting_id, data, sound_event)
	if mod:get("trigger_mission_vote") then
		trigger_focus()
	end
end)

mod:hook_safe(CLASS.UIManager, "event_show_ui_popup", function(self, data)
	local title = data and data.title_text
	local desc = data and data.description_text

	if mod:get("trigger_mission_vote") then
		if title and (title == "loc_accept_mission_voting_title_header" or string.find(title, "mission") or string.find(title, "voting")) then
			trigger_focus()
			return
		end
	end

	if mod:get("trigger_reconnect_mission") then
		if (title and string.find(title, "reconnect")) or (desc and string.find(desc, "reconnect")) then
			trigger_focus()
			return
		end
	end

	if mod:get("trigger_party_join_request") then
		if title and (title == "loc_party_request_to_join_header" or title == "loc_social_party_invite_received_header" or title == "loc_group_finder_group_invite_popup_title" or string.find(title, "request_to_join") or string.find(title, "party_invite")) then
			trigger_focus()
			return
		end
	end
end)

mod:hook_safe(CLASS.StateMainMenu, "_show_reconnect_popup", function(self)
	if mod:get("trigger_reconnect_mission") then
		trigger_focus()
	end
end)

mod:hook_safe(CLASS.MechanismHub, "_show_retry_popup", function(self)
	if mod:get("trigger_reconnect_mission") then
		trigger_focus()
	end
end)

mod:hook_safe(CLASS.PartyImmateriumManager, "_request_to_join_popup", function(self)
	if mod:get("trigger_party_join_request") then
		trigger_focus()
	end
end)

mod:hook_safe(CLASS.PartyImmateriumManager, "_handle_immaterium_invite", function(self)
	if mod:get("trigger_party_join_request") then
		trigger_focus()
	end
end)

mod:hook_safe(CLASS.ConstantGroupFinderStatus, "start_player_request_anim_enter", function(self)
	if mod:get("trigger_party_join_request") then
		trigger_focus()
	end
end)

mod:hook_safe(CLASS.LobbyView, "on_enter", function(self)
	if mod:get("trigger_pre_mission_lobby") then
		trigger_focus()
	end
end)

mod:command("test_autofocus", mod:localize("cmd_test_autofocus"), function()
	mod:echo("Testing AutoFocus in 3 seconds... Tab out now to test!")
	local t = 0
	local test_cb
	test_cb = function()
		trigger_focus(true)
	end
	if Promise and Promise.delay then
		Promise.delay(3):next(test_cb)
	else
		test_cb()
	end
end)
