# List Mode

List mode is one of the most powerful features of `mk`. It allows you to create a complex structure of files and directories from a single text file, making it perfect for scaffolding new projects or components.

## How it Works

You activate list mode with the `--list` (or `-l`) option, providing it with the path to a text file.

```bash
mk --list=my_project.txt
```

The script will then read the specified file line by line and use `mk` to create each entry.

## List File Syntax

The syntax of the list file is simple and intuitive:

-   **One Entry Per Line**: Each line represents a single file or directory to be created.
-   **Directories**: To specify a directory, simply end the line with a `/`.
-   **Comments**: Lines beginning with a `#` are treated as comments and are ignored.
-   **Empty Lines**: Empty or whitespace-only lines are also ignored.

### Per-Line Arguments

This is where the real power of list mode comes from. You can provide command-line options for each individual line. These per-line arguments will override any global options passed to the `mk` command.

**Note**: The format for per-line arguments with values must be `--option=value` (e.g., `--template=python`).

#### Example

Let's say you have a file named `react_component.txt` with the following content:

```
# react_component.txt
# Creates a new React component directory and files

components/<{&NAME&}>/
components/<{&NAME&}>/index.js --template=react_index
components/<{&NAME&}>/styles.css --template=css
```

And you run the following command:

```bash
mk --list=react_component.txt -DNAME=UserProfile
```

The script will perform the following actions:
1.  Create the `components/UserProfile/` directory.
2.  Create the `index.js` file inside it, using the `react_index` template.
3.  Create the `styles.css` file, using the `css` template.

This allows you to build complex, reusable project scaffolds that can be created with a single command.
