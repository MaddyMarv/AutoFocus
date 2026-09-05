return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`autofocus` mod must be lower than DMF in load order.")

		new_mod("autofocus", {
			mod_script       = "autofocus/scripts/mods/autofocus/autofocus",
			mod_data         = "autofocus/scripts/mods/autofocus/autofocus_data",
			mod_localization = "autofocus/scripts/mods/autofocus/autofocus_localization",
		})
	end,
	packages = {},
}
