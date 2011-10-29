-- Ripped from Tukui
local H, C, L = unpack(select(2, ...))

C["media"] = {
	-- fonts (ENGLISH, SPANISH)
	["font"] = [=[Interface\Addons\oUF_Healium\tukui_skin\medias\fonts\normal_font.ttf]=], -- general font of oUF_Healium
	["uffont"] = [[Interface\AddOns\oUF_Healium\tukui_skin\medias\fonts\uf_font.ttf]], -- general font of unitframes

	-- fonts (GLOBAL)
	["pixelfont"] = [=[Interface\Addons\oUF_Healium\tukui_skin\medias\fonts\pixel_font.ttf]=], -- general font of oUF_Healium

	-- textures
	["normTex"] = [[Interface\AddOns\oUF_Healium\tukui_skin\medias\textures\normTex]], -- texture used for oUF_Healium healthbar/powerbar/etc
	["glowTex"] = [[Interface\AddOns\oUF_Healium\tukui_skin\medias\textures\glowTex]], -- the glow text around some frame.
	["bubbleTex"] = [[Interface\AddOns\oUF_Healium\tukui_skin\medias\textures\bubbleTex]], -- unitframes combo points
	["copyicon"] = [[Interface\AddOns\oUF_Healium\tukui_skin\medias\textures\copy]], -- copy icon
	["blank"] = [[Interface\AddOns\oUF_Healium\tukui_skin\medias\textures\blank]], -- the main texture for all borders/panels
	["bordercolor"] = C.general.bordercolor or { .6,.6,.6 }, -- border color of oUF_Healium panels
	["altbordercolor"] = C.general.bordercolor or { .4,.4,.4 }, -- alternative border color, mainly for unitframes text panels.
	["backdropcolor"] = C.general.backdropcolor or { .1,.1,.1 }, -- background color of oUF_Healium panels
	["buttonhover"] = [[Interface\AddOns\oUF_Healium\tukui_skin\medias\textures\button_hover]],
}
