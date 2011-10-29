local ADDON_NAME, engine = ...

-- Get oUF from ElvUI or Tukui or oUF
local oUF = (ElvUI and ElvUF) or (Tukui and oUFTukui) or oUF
assert(oUF, "Healium was unable to locate oUF install.")

engine[1] = {}		-- H, functions, constants, variables
engine[2] = {}		-- C, config
engine[3] = {}		-- L, localization
engine[4] = oUF	-- oUF

local H, C, L = unpack(engine)

H.Internals = {} -- internal methods

Healium = engine -- global variable for skinning
