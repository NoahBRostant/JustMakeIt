<div align="center">
   <img src="./assets/Group@4x.png" width="150px" alt="Project Logo" />
    <h1>JustMakeIt</h1>
</div>

## Description

"Just Make It" is a simple command-line utility designed to streamline the process of creating files and directories. With this script, users can quickly create files with specific templates, set file permissions, create nested directories, and manage various file attributes—all with minimal input. It supports features like verbose output for detailed progress, file permission management (chmod), and the ability to create files from a list. This tool is ideal for users who need to automate repetitive file and directory creation tasks in a consistent and efficient manner.

<br>

## Features

- Create Files with Templates:
    Supports creating files with specific templates (e.g., Python, Shell script) using --template=py or -t sh.

- Verbose Mode:
    Provides detailed output during file or directory creation using the --verbose or -v flag.

- Create Directories:
    Creates new directories with simple syntax (mkdir functionality).

- Create Files in Nested Directories:
    Supports creating files in nested directories using paths (e.g., nested/dir/file.txt).

- Set File Permissions:
    Allows setting file permissions with --chmod=<mode>, such as --chmod=644.

- Create and Open Files:
    Option to open the created file in the default editor automatically with --open.

- Overwrite Existing Files:
    Prompts users for confirmation when overwriting existing files.

- Batch File and Directory Creation from a List:
    Creates multiple files and directories from a provided list (--list=<file>), processing each item in the list sequentially.

- Handle Invalid Templates Gracefully:
    Provides clear error messages when invalid templates or commands are used.

- Cross-Platform Compatibility:
    Works across different systems (Linux, macOS, Windows) with tools like curl, winget, and dnf for distribution.

<br>

## Installation

#### curl

Install the project with `curl` (recomended):

```bash
cd ~
curl -LO https://github.com/NoahBRostant/JustMakeIt/releases/download/v0.1.0/mk.sh
```
Once installed in the home directory you can enable it by adding it to your shell profile.
```sh
source ~/mk.sh
```
<br>

#### git

Install the project with `git`:
```bash
cd ~
git clone https://github.com/NoahBRostant/JustMakeIt.git/
```

Once installed in the home directory you can enable it by adding it to your shell profile.

```sh
source ~/JustMakeIt/mk.sh
```
<br>

And thats it...

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

- `--template=<template>` or `-t=<template>`: Create a file using a specific template.  
  **Available templates**: 


  Example:
  ```bash
  mk myfile.py --template=py
  ```

- `--open` or `-o`: Open the created file in the default text editor or move into the new directory after creation.

  Example:
  ```bash
  mk myfile.txt --open
  ```
  Example:
  ```bash
  mk mydirectory/ --open
  ```

- `--verbose` or `-v`: Enable verbose mode, which prints detailed information about any processes. (Useful for Development & Debuging)

  Example:
  ```bash
  mk myfile.txt --verbose
  ```

- `--chmod=<mode>`: Set specific file permissions on the created file (e.g., `644`, `755`).

  Example:
  ```bash
  mk myfile.txt --chmod=644
  ```

- `--list=<file>` or `-l <file>`: Create files and directories from a list provided in a text file. Each line in the file represents a file or directory to create.

  Example:
  ```bash
  mk --list=files.txt
  ```

  **files.txt** content example:
  ```
  ./file1.txt
  ./dir1/
  file.py -t=py
  dir2/subdir/ --open
  ```

- `--help` or `-h`: Display help information about the available options.

  Example:
  ```bash
  mk --help
  ```

### File Overwrite Confirmation

If you try to create a file that already exists, **Just Make It** will ask for confirmation before overwriting the file. You can confirm with `y` or cancel with `n`.

## Error Handling

If an invalid template is specified or an unknown argument is passed, **Just Make It** will display an error message like this:

```bash
Error: Unknown template
```

## Testing the Script

There is also a script provided to you for testing the features of JustMakeIt that can be found along every version of the program.
To run it you will need to use chmod to use it as an executable.

```bash
chmod a+x ./test_mk.sh
./test_mk.sh
```

## License

This project is licensed under the [MIT License](LICENSE). See the `LICENSE` file for more details on terms and conditions.

Feel free to use and contribute to the project under these terms!
