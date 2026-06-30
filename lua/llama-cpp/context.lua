local M = {}

--- Extracts and parses the buffer's native comment syntax
--- @param bufnr integer Active source buffer handle.
--- @return string prefix The left side of the comment tag.
--- @return string suffix The right side of the comment tag.
local function get_comment_syntax(bufnr)
    -- 1. Retrieve the bufffer-local commentstring
    local cs = vim.bo[bufnr].commentstring
    -- 2. Establish a safe fallback if the buffer lacks a defined syntax
    if not cs or cs == "" then
        cs = "# %s"
    end
    -- 3. Split the string at the `%s` placeholder
    local prefix, suffix = string.match(cs, "^(.-)%%s(.-)$")
    -- 4. Failsafe in case of badly formatted commentstring
    if not prefix then
        return "# ", ""
    end

    return prefix, suffix
end

--- Evaluates range settings and formats the current code buffer with structured comment tags.
--- @param winid integer Active window handle where the prompt was triggered.
--- @param bufnr integer Active source buffer handle.
--- @param opts table Command parameters containing line counts, range parameters, and text arguments.
--- @return string formatted_context Constructed multi-line string containing instructions and structured target tags.
function M.build_user_prompt(winid, bufnr, opts)
    local range = opts.range or 0
    local line1 = opts.line1
    local line2 = opts.line2
    local cursor_line = vim.api.nvim_win_get_cursor(winid)[1]

    -- 1. Fetch dynamic comment syntax for active buffer
    local prefix, suffix = get_comment_syntax(bufnr)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local formatted_lines = {}

    if range > 0 and line1 and line2 then
        for i, line in ipairs(lines) do
            -- 2. Inject dynamic open tag
            if i == line1 then
                table.insert(formatted_lines, prefix .. "<TARGET_ZONE>" .. suffix)
            end
            table.insert(formatted_lines, line)
            -- 3. Inject dynamic close tag
            if i == line2 then
                table.insert(formatted_lines, prefix .. "</TARGET_ZONE>" .. suffix)
            end
        end
    else
        for i, line in ipairs(lines) do
            table.insert(formatted_lines, line)
            -- 4. Inject dynamic cursor tag
            if i == cursor_line then
                table.insert(formatted_lines, prefix .. "<APPEND_HERE>" .. suffix)
            end
        end
    end

    local prompt = ""
    if opts.args and opts.args ~= "" then
        prompt = prompt .. "--- INSTRUCTION ---\n" .. opts.args .. "\n\n"
    end

    prompt = prompt .. "--- CONTEXT ---\n" .. table.concat(formatted_lines, "\n") .. "\n"
    return prompt
end

return M
