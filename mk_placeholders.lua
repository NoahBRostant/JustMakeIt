-- mk placeholder script in Lua
-- This script should return a table of key-value pairs.

-- This function will be called by the mk script.
function get_placeholders()
    local placeholders = {}

    -- Simple placeholders
    placeholders["AUTHOR"] = "Your Name Here"
    placeholders["EMAIL"] = "your.email@example.com"

    -- Dynamic placeholders that run shell commands
    -- Note: For security, be careful about what commands you run.

    -- Get the current operating system name
    local os_handle = io.popen("uname -s")
    if os_handle then
        placeholders["USEROS"] = os_handle:read("*a"):gsub("%s*$", "") -- Read and trim whitespace
        os_handle:close()
    end

    -- Check for internet connectivity by pinging a reliable host
    local ping_success = os.execute("ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1")
    if ping_success then
        placeholders["INTERNET"] = "Connected"
    else
        placeholders["INTERNET"] = "Disconnected"
    end

    return placeholders
end

-- The final part of the script should output the placeholders in a format
-- that the shell script can easily parse (e.g., key=value pairs).
local placeholders = get_placeholders()
for key, value in pairs(placeholders) do
    print(key .. "=" .. value)
end
