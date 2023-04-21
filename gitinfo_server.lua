-- gitinfo_server.lua
local log_file, _ = io.open("gitinfo_server.log", "w")
if not log_file then
    io.stderr:write("failed to open log file")
    io.stderr:flush()
    return
end

log_file:write("gitinfo server started\n")
log_file:flush()

function ParseGitBlameData(blame_data, log_data)
    local blame_data_lines = {}
    for match in string.gmatch(blame_data, "([^\n\r]+)") do
        table.insert(blame_data_lines, match)
    end
    for _, raw_commit_info in pairs(blame_data_lines) do
        local commit_hash = string.match(raw_commit_info, "^[%^]*([^%s]+)%s+%(") or ""
        local committer = string.match(raw_commit_info, "%(([^%s]+)%s") or ""
        local time_since_commit = string.match(raw_commit_info, "%([^%s]+%s+(.+ago)") or ""
        local commit_message = ""
        if commit_hash ~= "" then
            commit_message = string.match(log_data, commit_hash .. "[^%s]*[%s]+([^\n]*)") or ""
        end
        local commit_info = "last commit: [" .. committer .. "] [" .. time_since_commit .. "] [" .. commit_message .. "]\n"
        io.stdout:write(commit_info)
    end
end

while true do
    local filename = io.stdin:read()
    if not filename then
        log_file:write("failed to read from stdin\n")
        log_file:write("gitinfo exit\n")
        log_file:flush()
        break
    end
    log_file:write("get command: " .. filename)
    local blame_tmp_file = assert(io.popen("git blame --abbrev=40 --date=relative " .. filename, 'r'))
    local log_tmp_file = assert(io.popen('git log --format=format:"%H %s"', 'r'))
    local blame_data = blame_tmp_file:read('*all')
    local log_data = log_tmp_file:read('*all')
    ParseGitBlameData(blame_data, log_data)
    io.stdout:write("\n")   -- one more empty line to indicate end of message
    io.stdout:flush()
end
