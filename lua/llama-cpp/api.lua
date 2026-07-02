local M = {}

--- Spawns an isolated background curl process to stream completions via libuv.
--- @param config LlamaConfig Passed-down plugin configuration table.
--- @param messages table Standard format list of system and user chat message objects.
--- @param on_chunk fun(token: string) Callback executed on the main thread for each incoming text token.
--- @param on_complete fun() Callback executed on the main thread after the stream terminates cleanly.
function M.send_chat(config, messages, on_chunk, on_complete)
    local payload = vim.json.encode({
        model = config.model,
        messages = messages,
        stream = true
    })

    local cmd = {
        "curl", "--no-buffer", "-s",
        "--connect-timeout", tostring(config.timeout),
        "-X", "POST",
        "-H", "Content-Type: application/json",
        "-d", payload,
        config.endpoint
    }

    local chunck_accumulator = ""
    local has_completed = false

    vim.system(cmd, {
        stdout = function(_, data)
            if not data then return end
            chunck_accumulator = chunck_accumulator .. data

            while true do
                local line, pos = chunck_accumulator:match("([^\n]*)\n()")
                if not line then break end
                chunck_accumulator = chunck_accumulator:sub(pos)

                -- Look for Server-Sent Events data prefixes
                if line:sub(1, 5) == "data:" then
                    local json_str = vim.trim(line:sub(6))

                    if #json_str > 0 and json_str~="[DONE]" then
                        local ok, parsed = pcall(vim.json.decode, json_str)

                        -- Flattened extraction path using safe navigation checks
                        if ok and parsed.choices and parsed.choices[1] then
                            local delta = parsed.choices[1].delta
                            if delta and type(delta.content) == "string" and #delta.content > 0 then
                                on_chunk(delta.content)
                            end
                        end
                    end
                end
            end
        end,
    }, function(obj)
        vim.schedule( function()
        -- Connection execution finished
            if obj.code ~= 0 then
                vim.notify("curl failed with code " .. obj.code .. "\n" .. (obj.stderr or ""), vim.log.levels.ERROR)
            end

            if not has_completed then
                has_completed = true
                on_complete()
                end
            end)
        end)
end

return M
