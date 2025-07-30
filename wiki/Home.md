# Welcome to the JustMakeIt Wiki!

`JustMakeIt` (or `mk`) is a command-line utility designed to be a powerful and intuitive replacement for `touch` and `mkdir`. Its goal is to streamline your development workflow by automating the creation of files and directories with a flexible and powerful template system.

This wiki provides a comprehensive guide to all of `mk`'s features, from basic file creation to advanced project scaffolding with custom Lua placeholders.

## Core Concepts

-   **Simplicity First**: At its core, `mk` is as simple as `touch` or `mkdir`. Running `mk my_file.txt` will create an empty file, just as you'd expect.
-   **Template-Driven**: The real power of `mk` comes from its template system. You can create a library of reusable file templates in `~/.mk/.templates/` and use them to instantly generate boilerplate code, configuration files, or any other text-based file.
-   **Dynamic Content**: Templates can be populated with dynamic information using placeholders. The script has built-in placeholders for things like the filename and current date, but you can also define your own with a simple Lua script, allowing for infinite customization.
-   **Workflow Automation**: Features like the powerful "list mode" allow you to create entire project structures from a single file, turning a multi-step setup process into a single command.

## Where to Go Next

-   **[Getting Started](Getting-Started)**: Learn how to install and set up `mk` on your system.
-   **[Commands and Options](Commands-and-Options)**: A detailed reference for all the available command-line flags.
-   **[Templates and Placeholders](Templates-and-Placeholders)**: An in-depth guide to creating and using templates and placeholders.
-   **[List Mode](List-Mode)**: Master the powerful list mode to automate project scaffolding.
-   **[Comparisons](Comparisons)**: See how `mk` stacks up against `touch` and `mkdir`.
