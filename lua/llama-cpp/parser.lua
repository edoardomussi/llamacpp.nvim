local M = {}

--- @class StreamParser
--- @field raw_accumulator table Complete sequential list of fully processed text lines.
--- @field current_line string Ongoing text fragment accumulated across streaming chunks.
--- @field append fun(token: string) Ingests incoming stream data fragments and filters out markdown indicators.
--- @field flush fun(): table Outputs the finished array matrix containing the sanitized patch.

--- Instantiates a stateful, line-oriented stream parser to clear markdown formatting mid-flight.
--- @return StreamParser instance
function M.new_stream_parser()
    local self = {
        raw_accumulator = {},
        current_line = ""
    }

    function self.append(token)
        -- 1. Strip ANSI escape codes from the incoming token fragment
        token = token:gsub("\27%[[0-9;]*[a-zA-Z]", "")

        self.current_line = self.current_line .. token

        while true do
            local line, pos = self.current_line:match("([^\n]*)\n()")
            if not line then break end
            self.current_line = self.current_line:sub(pos)

            -- 2. Normalize line breaks by stripping trailing carriage returns
            line = line:gsub("\r$", "")

            if not line:match("^%s*```") then
                table.insert(self.raw_accumulator, line)
            end
        end
    end

    function self.flush()
        if self.current_line:match("%S") and not self.current_line:match("```") then
            table.insert(self.raw_accumulator, self.current_line)
        end
        return self.raw_accumulator
    end

    return self
end

return M
