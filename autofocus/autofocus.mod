return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`autofocus` encountered an error loading the Darktide Mod Framework.")

		new_mod("autofocus", {
			mod_script       = "autofocus/scripts/mods/autofocus/autofocus",
			mod_data         = "autofocus/scripts/mods/autofocus/autofocus_data",
			mod_localization = "autofocus/scripts/mods/autofocus/autofocus_localization",
		})
	end,
	packages = {},
}
