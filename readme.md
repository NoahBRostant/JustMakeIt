<div align="center">
   <img src="./assets/Group@4x.png" width="150px" alt="Project Logo" />
    <h1>JustMakeIt (Linux)</h1>
</div>

## Description

"Just Make It" is a simple command-line utility designed to streamline the process of creating files and directories. With this script, users can quickly create files with specific templates, set file permissions, create nested directories, and manage various file attributes—all with minimal input. It supports features like verbose output for detailed progress, file permission management (chmod), and the ability to create files from a list. This tool is ideal for users who need to automate repetitive file and directory creation tasks in a consistent and efficient manner.

<br>

## Features

- **Create Files with Templates**: Supports creating files from templates stored in `~/.mk/.templates/`.
- **Dynamic Placeholders**: Use built-in or custom Lua-defined placeholders like `<{&FILENAME&}>` in your templates.
- **Verbose Mode**: Provides detailed output during file or directory creation using the `--verbose` or `-v` flag.
- **Create Directories**: Creates new directories with simple syntax (`mkdir` functionality).
- **Create Files in Nested Directories**: Supports creating files in nested directories using paths (e.g., `nested/dir/file.txt`).
- **Set File Permissions**: Allows setting file permissions with `--chmod=<mode>`, such as `--chmod=644`.
- **Create and Open Files**: Option to open the created file in the default editor automatically with `--open`.
- **Overwrite Existing Files**: Prompts users for confirmation when overwriting existing files.
- **Batch File and Directory Creation from a List**: Creates multiple files and directories from a provided list, with support for per-line arguments.
- **Open-Sourced-Software**: Feel free to copy, distribute, or modify this script to your heart's content. This project is to better everyone... and having fun coding. [MIT License](LICENSE).

<br>

## Installation

To install the script, you can use either `curl` or `git`. After installing, you must `source` the script in your shell's profile file (e.g., `~/.bashrc`, `~/.zshrc`) to make the `mk` command available.

```sh
# Add this line to your ~/.bashrc or ~/.zshrc
source ~/.mk/mk.sh
```

This makes the `mk` command available in your terminal.

<br>

## Usage

### Basic Command Syntax

```bash
mk [options] <filename>
```

Where:
- `<filename>` is the name of the file or directory to create.
- Options modify the behavior of the command.

### Options

- `--template=<template>` or `-t <template>`: Create a file using a specific template from `~/.mk/.templates/`. You can refer to the template by its full name (e.g., `python.py`) or its base name (`python`).
- `--list-templates`: Display a list of all available templates.
- `--no-template`: Create an empty file, ignoring all template logic (both implicit and explicit).
- `--open` or `-o`: Open the created file in the default text editor or move into the new directory after creation.
- `--verbose` or `-v`: Enable verbose mode, which prints detailed information about any processes.
- `--chmod=<mode>`: Set specific file permissions on the created file (e.g., `644`, `755`).
- `--list=<file>` or `-l <file>`: Create files and directories from a list provided in a text file.
- `--help` or `-h`: Display help information.

### Dynamic Placeholders

You can use placeholders in your templates to insert dynamic content. The script replaces them when it creates a file.

**Syntax**: `<{&PLACEHOLDER_NAME&}>`

#### Built-in Placeholders
- `<{&FILENAME&}>`: The name of the file being created.
- `<{&DATE&}>`: The current date (YYYY-MM-DD).
- `<{&TIME&}>`: The current time (HH:MM:SS).
- `<{&DATETIME&}>`: The current date and time.

#### Custom Placeholders with Lua
For ultimate flexibility, you can define your own placeholders using a Lua script.

1.  Create a file at `~/.mk/mk_placeholders.lua`.
2.  In this file, define a `get_placeholders` function that returns a table of your custom placeholders.

**Example `mk_placeholders.lua`:**
```lua
-- ~/.mk/mk_placeholders.lua
function get_placeholders()
    local placeholders = {}

    -- Simple placeholder
    placeholders["AUTHOR"] = "Your Name"

    -- Dynamic placeholder using a shell command
    local os_handle = io.popen("uname -s")
    if os_handle then
        placeholders["USEROS"] = os_handle:read("*a"):gsub("%s*$", "") -- Read and trim
        os_handle:close()
    end

    return placeholders
end

-- Boilerplate to return the values to the shell script
local placeholders = get_placeholders()
for key, value in pairs(placeholders) do
    print(key .. "=" .. value)
end
```

**Example Template using Placeholders:**
```python
# Template: ~/.mk/.templates/python.py
# Author: <{&AUTHOR&}>
# OS: <{&USEROS&}>
# Created on: <{&DATE&}>

def main():
    print("Hello from <{&FILENAME&}>")

if __name__ == "__main__":
    main()
```

### List Mode

The `--list` option allows you to create multiple files and directories at once. Each line in the list file can also have its own specific options, which will override any global options passed on the command line.

**Example `files.txt`:**
```
# This is a comment and will be ignored
my_project/
my_project/main.py --template=python
my_project/README.md --template=md
my_project/run.sh --chmod=755
```

**Command:**
```bash
mk --list=files.txt
```

### Configuration

You can configure the script's behavior by editing `~/.mk/mk.conf`.

- `extension_check=true|false`
  - If `true` (default), `mk script.py` will automatically look for a template named `python.py` or similar.
  - If `false`, templates are only used when specified with `--template`.

### File Overwrite Confirmation

If you try to create a file that already exists, **Just Make It** will ask for confirmation before overwriting the file. You can confirm with `y` or cancel with `n`.

## Testing the Script

To run the built-in test suite, first give the test script execute permissions:
```bash
chmod a+x ./test_mk.sh
```
Then run the tests:
```bash
./test_mk.sh
```

## License

This project is licensed under the [MIT License](LICENSE). See the `LICENSE` file for more details on terms and conditions.
