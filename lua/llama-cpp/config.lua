local M = {}

M.defaults = {
endpoint = "http://127.0.0.1:8080/v1/chat/completions",
    model = "llama3",
    timeout = 30000,
    context_window = 4096,
    system_prompt= ""
}

M.options = {}

function M.setup(user_opts)
    M.options = vim.tbl_deep_extend("force", M.defaults, user_opts or {})
end

return M
