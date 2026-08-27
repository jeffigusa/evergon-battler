local M = {}

local uid = 0
M.get_uid = function()
    uid = uid + 1
    return uid
end

return M