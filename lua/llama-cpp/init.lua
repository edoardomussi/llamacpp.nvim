--- @class LlamaConfig
--- @field endpoint string The local or remote OpenAI-compatible API completion endpoint.
--- @field model string The identifier of the targeted LLM model running on the server.
--- @field timeout string The max connection timeout duration for the underlying curl process.
--- @field system_prompt string Detailed instructions constraining the LLM patch behavior.

local M = {}

local config = require("llama-cpp.config")

--- Extends default settings with user-defined options and synchronizes upstream network options.
--- @param opts table|nil User configuration updates passed down via setup.
function M.setup(opts)
    config.setup(opts)
end

--- Entry-point execution loop. Captures editor state and handles the async lifecycle.
--- @param opts table Raw options map forwarded directly from the user command payload.
function M.execute_request(opts)
    local api = require("llama-cpp.api")
    local ui = require("llama-cpp.ui")
    local context = require("llama-cpp.context")
    local parser = require("llama-cpp.parser")

    local orig_win = vim.api.nvim_get_current_win()
    local original_buf = vim.api.nvim_win_get_buf(orig_win)
    opts.invocation_line  = vim.api.nvim_win_get_cursor(orig_win)[1]    -- Capture the scope line at invocation to avoid corrupting unrelated buffers

    if not vim.api.nvim_get_option_value("modifiable", { buf = original_buf }) then
        vim.notify("llama-cpp: Buffer is read-only!", vim.log.levels.WARN)
        return
    end


    local filetype = vim.api.nvim_get_option_value("filetype", { buf = original_buf })
    local user_prompt = context.build_user_prompt(orig_win, original_buf, opts)
    local stream = parser.new_stream_parser()

    vim.notify("Llama: Generating...", vim.log.levels.INFO)

    api.send_chat(
        config.options,
        { { role = "system", content = config.options.system_prompt }, { role = "user", content = user_prompt } },
        function(token) stream.append(token) end,
        function()
            vim.notify("Llama generation complete.", vim.log.levels.INFO)
            ui.create_preview(orig_win, original_buf, stream.flush(), filetype, opts)
        end
    )
end

M.execute = M.execute_request
return M
