<div align="center">

<img src="./assets/logo.png" width="150px" alt="Project Logo" />

# JustMakeIt (mk)

![GitHub Release](https://img.shields.io/github/v/release/NoahBRostant/JustMakeIt?sort=semver&display_name=release&style=flat)
![GitHub License](https://img.shields.io/github/license/NoahBRostant/JustMakeIt)

**A fast, safe, template-driven alternative to `touch`/`mkdir`, written in Rust 🦀**

</div>

---

`mk` speeds up project setup by creating files and directories from templates, filling in variables automatically, and handling overwrites, permissions, and nested paths with care.

## ✨ Features

- **Template-based creation**
  - Built-in templates from your config (`~/.config/mk/config.toml`)
  - External templates from `~/.config/mk/templates/` (by name or, optionally, by file extension)
- **Dynamic placeholders**
  - Built-ins (e.g. `FILENAME`, `DATE`, `TIME`, `DATETIME`) for external templates
  - Lua-powered placeholders from `./mk_placeholders.lua` or `~/.config/mk/mk_placeholders.lua`
- **List mode**
  - Batch-create files/dirs from a list, with *per-line flags*
- **Safety & ergonomics**
  - Interactive overwrite prompts (with `--yes` / `--no`)
  - `--mode`/`-m` octal perms on Unix
  - Auto-creates parent directories (configurable)
  - Open in your editor (`-o`, `--editor`)

---

## 🚀 Installation

Using Cargo:

```bash
# From this repo
cargo install --path crates/mk

# Or directly from Git
cargo install --locked --git https://github.com/NoahBRostant/JustMakeIt mk
```

---

## ⚙️ Setup

Create the config and templates directory:

```bash
# Initialise the default config file.
mk init
```

Or

```bash
mk -p ~/.config/mk/templates ~/.config/mk/config.toml 
```

### Example config: `~/.config/mk/config.toml`

```toml
# Optional author used by config templates (e.g. {author})
author = "Your Name"

# Auto-create missing parent directories (like `mkdir -p`)
auto_create_parents = true

# When true, if -t is not provided, mk will try to pick an external template
# from ~/.config/mk/templates by matching the file extension.
# Example: mk index.html -> tries templates/*.html
extension_check = true

[templates.default]
# Used when nothing else matches
body = "{file_name}\n"

[templates.rs]
ext  = "rs"
body = """
// {file_name} — created {date}
/// Author: {author}

fn main() {
    println!("Hello, {file_stem}!");
}
"""

[templates.sh]
ext  = "sh"
mode = "755" # Unix only
body = """#!/usr/bin/env bash
set -euo pipefail

"""

[templates.md]
ext  = "md"
body = """# {file_stem}

"""
```

> **Note:** Config templates use `{date}`, `{year}`, `{author}`, `{file_name}`, `{file_stem}`.
> External file templates + Lua use the `<{&KEY&}>` syntax (see below).

### External templates

Put files in `~/.config/mk/templates/`, e.g.:

* `~/.config/mk/templates/sh` (or `sh.sh`)
* `~/.config/mk/templates/html.html`
* `~/.config/mk/templates/readme.md`

### Lua placeholders (optional)

Create either `./mk_placeholders.lua` (project-local) or `~/.config/mk/mk_placeholders.lua`.
It should print **`KEY=VALUE`** lines to stdout:

```lua
-- mk_placeholders.lua
print("AUTHOR=Name")
print("OS=" .. (os.getenv("OSTYPE") or "unknown"))
```

In external templates, reference as `<{&AUTHOR&}>`, `<{&OS&}>`, etc.
Built-ins always available: `FILENAME`, `DATE`, `TIME`, `DATETIME`.

---

## 🧪 Usage

### Basics

```bash
mk README.md                    # uses config templates (by ext) if present
mk -t sh script.sh              # use external template "sh" (errors if missing)
mk --no-template empty.py      # skip templates/placeholders entirely
```

### Implicit external template by extension

```bash
# requires: extension_check = true (in config)
mk index.html                   # picks ~/.config/mk/templates/*.html
```

### Directories

```bash
mk project/                     # trailing slash => directory
mk -d assets/images             # explicit directory
```

### Parents & permissions

```bash
mk nested/dir/file.txt          # parents auto-created (config: auto_create_parents)
mk deploy.sh -m 755             # set file mode (Unix)
```

### Overwrite behavior

```bash
mk overwrite.txt                # prompts if exists
mk overwrite.txt -y             # --yes/--force (no prompt, overwrite)
mk overwrite.txt -n             # --no/--no-clobber (skip if exists)
```

### Open in editor

```bash
mk src/main.rs -o               # opens $VISUAL or $EDITOR
mk src/main.rs -o --editor nvim
```

### List mode (batch)

```text
# list.txt
list_file1.txt
-d list_dir/
nested_list/file2.txt
-t=sh list_script.sh
--no-template list_no_template.txt
-c=755 list_exec.sh
```

```bash
mk -l list.txt
```

### From stdin

```bash
cat body.txt | mk --stdin from_stdin.txt
```

### Explore templates

```bash
mk --list-templates             # shows files in ~/.config/mk/templates
```

---

## ❗ Error on missing explicit template

When you pass `-t/--template <name>`, the template **must** exist either:

* in config (`[templates.<name>]`), or
* in `~/.config/mk/templates/` (e.g., `name` or `name.*`)

If not found, `mk` errors and does **not** create the file.

---

## 🧰 Testing

A shell test script is provided (covers external templates, Lua, overwrite logic, list mode, perms, etc.):

```bash
chmod +x ./test_mk.sh
./test_mk.sh
```

---

## 📜 License

This project is licensed under the **MIT License**. See `LICENSE` for details.
