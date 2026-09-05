local mod = get_mod("autofocus")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "general_settings",
				type = "group",
				tab = mod:localize("tab_general"),
				sub_widgets = {
					{
						setting_id = "focus_method",
						type = "dropdown",
						default_value = "force_foreground",
						options = {
							{ text = "option_force_foreground", value = "force_foreground" },
							{ text = "option_bring_to_view", value = "bring_to_view" },
							{ text = "option_flash_only", value = "flash_only" },
						},
					},
					{
						setting_id = "play_sound",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "triggers_group",
						type = "group",
						sub_widgets = {
							{
								setting_id = "trigger_on_hit",
								type = "checkbox",
								default_value = true,
							},
							{
								setting_id = "trigger_rescued",
								type = "checkbox",
								default_value = true,
							},
							{
								setting_id = "trigger_rescue_started",
								type = "checkbox",
								default_value = false,
							},
							{
								setting_id = "trigger_revived_downed",
								type = "checkbox",
								default_value = true,
							},
							{
								setting_id = "trigger_respawned_hogtied",
								type = "checkbox",
								default_value = false,
							},
							{
								setting_id = "trigger_mission_vote",
								type = "checkbox",
								default_value = true,
							},
							{
								setting_id = "trigger_pre_mission_lobby",
								type = "checkbox",
								default_value = true,
							},
							{
								setting_id = "trigger_spawn_mission",
								type = "checkbox",
								default_value = true,
							},
						},
					},
				},
			},
		},
	},
}
