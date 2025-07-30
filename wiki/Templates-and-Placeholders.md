# Templates and Placeholders

The template system is the core feature of `mk`. It allows you to define reusable skeletons for any type of file, which can be populated with dynamic information using placeholders.

## The Templates Directory

All templates are stored in the `~/.mk/.templates/` directory. When you run `mk`, it looks in this directory to find a suitable template.

### How Templates Are Chosen

There are two ways a template can be applied:

1.  **Explicitly**: You can specify a template with the `--template` (or `-t`) option. This is the most direct way and will always take precedence.
    ```bash
    # Uses the 'python.py' template
    mk my_script.py --template=python
    ```

2.  **Implicitly**: If you don't specify a template, `mk` will look for one that matches the file extension of the file you're creating. For example, if you run `mk my_file.html`, it will automatically look for a template with a `.html` extension (e.g., `html.html`, `web.html`) in your templates directory.

    You can disable this behavior in the **[Configuration File](Configuration.md)**.

## Placeholders

Placeholders allow you to insert dynamic content into your templates when a new file is created. The syntax is always `<{&PLACEHOLDER_NAME&}>`.

### Built-in Placeholders

The script comes with a few handy placeholders available in every template:

-   `<{&FILENAME&}>`: The name of the file being created (e.g., `my_script.py`).
-   `<{&DATE&}>`: The current date in `YYYY-MM-DD` format.
-   `<{&TIME&}>`: The current time in `HH:MM:SS` format.
-   `<{&DATETIME&}>`: The current date and time.

### Custom Placeholders with Lua

For ultimate flexibility, you can define your own placeholders using a simple Lua script. This allows you to run shell commands, perform calculations, or do anything else you can imagine to generate dynamic content.

#### How it Works

1.  Create a file at `~/.mk/mk_placeholders.lua`.
2.  If this file exists and you have the `lua` interpreter installed, `mk` will execute it every time it creates a file from a template.
3.  The script is expected to return a series of `key=value` pairs, which `mk` will use for placeholder replacement.

#### Example Lua Script

This example defines a static `AUTHOR` placeholder and a dynamic `USEROS` placeholder that gets the name of the current operating system.

**File: `~/.mk/mk_placeholders.lua`**
```lua
-- This function will be called by the mk script.
function get_placeholders()
    local placeholders = {}

    -- 1. A simple, static placeholder
    placeholders["AUTHOR"] = "Your Name"

    -- 2. A dynamic placeholder that runs a shell command
    local os_handle = io.popen("uname -s")
    if os_handle then
        -- Read the command's output and trim any trailing whitespace
        placeholders["USEROS"] = os_handle:read("*a"):gsub("%s*$", "")
        os_handle:close()
    end

    return placeholders
end

-- This part of the script formats the output for the shell script to read
local placeholders = get_placeholders()
for key, value in pairs(placeholders) do
    print(key .. "=" .. value)
end
```

#### Example Template

You can then use these new placeholders in any of your templates.

**File: `~/.mk/.templates/my_template.txt`**
```
This file was created by <{&AUTHOR&}> on a <{&USEROS&}> machine.
```

When you create a file from this template (`mk new_file.txt -t my_template`), the output will be:
```
This file was created by Your Name on a Linux machine.
```
