# Commands and Options

This page provides a detailed reference for all the command-line options available in `mk`.

## Basic Syntax

The basic syntax for the `mk` command is:

```bash
mk [filename_or_directory] [options]
```

-   `filename_or_directory`: The file or directory you want to create. If the name ends with a `/`, it will be treated as a directory.
-   `options`: Flags that modify the command's behavior.

---

## Options Reference

### `--template=<template>` or `-t <template>`

Specifies a template to use for file creation.

-   **Argument**: The name of a template file located in `~/.mk/.templates/`.
-   **Behavior**: You can refer to the template by its full filename (e.g., `python.py`) or its base name (`python`). If a template is specified, it will be used regardless of the output filename's extension.
-   **Example**:
    ```bash
    # Both of these commands will use the python.py template
    mk my_app.py --template=python.py
    mk my_app.py -t python
    ```

### `--list-templates`

Lists all available templates.

-   **Behavior**: The script will print a list of all the template files found in `~/.mk/.templates/` and then exit.
-   **Example**:
    ```bash
    mk --list-templates
    ```

### `--no-template`

Disables all template logic for the current command.

-   **Behavior**: This flag ensures that an empty file is created. It prevents `mk` from performing an implicit template lookup based on the file extension.
-   **Example**:
    ```bash
    # Creates an empty file, even if python.py exists in the templates dir
    mk my_script.py --no-template
    ```

### `--list=<file>` or `-l <file>`

Creates files and directories from a list in a specified file.

-   **Argument**: The path to a text file containing a list of files/directories to create.
-   **Behavior**: See the **[List Mode](List-Mode.md)** page for a detailed guide.
-   **Example**:
    ```bash
    mk --list=my_project_files.txt
    ```

### `--chmod=<mode>`

Sets the permissions for the created file or directory.

-   **Argument**: A valid permission mode (e.g., `755`, `644`).
-   **Example**:
    ```bash
    # Creates an executable script
    mk my_script.sh --chmod=755
    ```

### `--open` or `-o`

Opens the created file or directory.

-   **Behavior**:
    -   If creating a **file**, it will be opened in the default text editor (determined by the `$EDITOR` environment variable, falling back to `nano`).
    -   If creating a **directory**, the script will change the current working directory to the new directory.
-   **Example**:
    ```bash
    mk my_file.txt --open
    ```

### `--verbose` or `-v`

Enables verbose mode, which provides detailed output about the script's operations. This is very useful for debugging.

### `--yes` or `-y` / `--no` or `-n`

Handles file overwrite confirmations automatically.

-   `--yes`: Automatically confirms any overwrite prompts.
-   `--no`: Automatically denies any overwrite prompts, skipping the creation of any files that already exist.

### `--help` or `-h`

Displays a brief help message with the available options and then exits.
