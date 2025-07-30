# Comparisons to `touch` and `mkdir`

While `mk` can do everything that `touch` and `mkdir` can, it's designed to be much more powerful. This page outlines the pros and cons of each to help you understand when to use `mk` and when the classic commands might still be sufficient.

---

## `touch`

`touch` is a simple utility for creating empty files and updating timestamps.

### Pros of `touch`

-   **Simplicity and Speed**: For creating a single empty file, `touch my_file.txt` is as simple and fast as it gets.
-   **Ubiquity**: `touch` is available on every Unix, Linux, and macOS system without any setup.
-   **Timestamp Manipulation**: `touch`'s primary purpose is to update file access and modification times, a feature `mk` does not have.

### Cons of `touch`

-   **Empty Files Only**: It cannot create files with content. This means you always have to perform a second step: opening the file and adding your boilerplate code.
-   **No Directory Creation**: It cannot create parent directories. If you run `touch my/nested/file.txt` and the `nested` directory doesn't exist, the command will fail.

---

## `mkdir`

`mkdir` is the standard utility for creating directories.

### Pros of `mkdir`

-   **Simplicity**: `mkdir my_dir` is straightforward and effective.
-   **Ubiquity**: Like `touch`, `mkdir` is available everywhere.
-   **Recursive Creation**: The `mkdir -p` option is very powerful, allowing you to create nested directory structures in one go (e.g., `mkdir -p my/nested/dir`).

### Cons of `mkdir`

-   **Directories Only**: It cannot create files. Creating a project structure always requires a combination of `mkdir` and `touch` commands.

---

## `mk`: The Best of Both Worlds and More

`mk` is designed to overcome the limitations of `touch` and `mkdir` by combining their functionality and adding a powerful templating engine on top.

### Pros of `mk`

-   **Unified Command**: `mk` can create both files and directories, including nested structures, with a single, consistent syntax.
-   **Template-Driven Creation**: This is the killer feature. Instead of creating an empty file, you can create a file that's already populated with your boilerplate code, saving you time and reducing errors.
-   **Dynamic Content**: Placeholders allow you to insert dynamic information (like the filename, date, or custom variables from a Lua script) into your templates.
-   **Project Scaffolding**: The powerful "list mode" allows you to define an entire project structure in a single text file and create it with one command.
-   **Extensible**: With custom Lua placeholders, you can extend `mk` to fit your exact workflow.

### Cons of `mk`

-   **Setup Required**: Unlike `touch` and `mkdir`, `mk` is a script that needs to be installed and sourced in your shell's profile.
-   **Slightly More Complex**: While basic usage is simple, mastering all of `mk`'s features (like templates and Lua placeholders) requires a bit of a learning curve.
-   **Not a Timestamp Tool**: `mk` does not replicate `touch`'s ability to manipulate file timestamps.

### Conclusion

-   For **quick, empty files** or **timestamp updates**, `touch` is still the king.
-   For **simple directory creation**, `mkdir` is perfectly fine.
-   For **any workflow that involves creating files with boilerplate content** or **scaffolding project structures**, `mk` is a vastly superior tool that will save you a significant amount of time and effort.
