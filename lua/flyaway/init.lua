-- Imports the plugin's additional Lua modules.
local flyaway = require("flyaway.flyaway")

-- Creates an object for the module. All of the module's
-- functions are associated with this object, which is
-- returned when the module is called with `require`.
local M = {}

-- Routes calls made to this module to functions in the
-- plugin's other modules.
M.SyncDirectory = flyaway.SyncDirectory

return M
