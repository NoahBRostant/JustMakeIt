# Getting Started with JustMakeIt

This guide will walk you through the installation and basic setup of the `mk` script.

## 1. Installation

The `mk` script is a single `bash` file, so installation is simple. You just need to place the `mk.sh` file somewhere on your system. The recommended location is in a dedicated directory in your home folder.

You can do this with `git`:

```bash
# 1. Clone the repository to ~/.mk
git clone https://github.com/NoahBRostant/JustMakeIt.git ~/.mk

# 2. (Optional) You can now delete the .git directory if you don't want to track changes
rm -rf ~/.mk/.git
```

## 2. Sourcing the Script

To make the `mk` command available in your terminal, you need to `source` the script in your shell's profile file. This file is usually `~/.bashrc` for Bash shells or `~/.zshrc` for Zsh shells.

1.  Open your profile file in a text editor (e.g., `nano ~/.bashrc`).
2.  Add the following line to the end of the file:

    ```sh
    # Make the 'mk' command available
    source ~/.mk/mk.sh
    ```

3.  Save the file and restart your terminal, or run `source ~/.bashrc` to apply the changes immediately.

Now, the `mk` command should be available in your terminal. You can test it by running `mk --help`.

## 3. Your First Template

The power of `mk` comes from its templates. Let's create a simple one.

1.  **Create the templates directory**: The `mk` script looks for templates in `~/.mk/.templates/`. Create this directory if it doesn't exist:
    ```bash
    mkdir -p ~/.mk/.templates
    ```

2.  **Create a template file**: Let's create a simple `python.py` template.
    ```bash
    nano ~/.mk/.templates/python.py
    ```

3.  **Add content to the template**: Paste the following into the file:
    ```python
    # Author: <{&AUTHOR&}>
    # Created on: <{&DATE&}>
    # File: <{&FILENAME&}>

    def main():
        print("Hello from <{&FILENAME&}>")

    if __name__ == "__main__":
        main()
    ```

## 4. Create a File

Now you can use your new template to create a Python file:

```bash
mk my_script.py
```

This command will:
1.  See that you're creating a `.py` file.
2.  Automatically find the `python.py` template in your templates directory.
3.  Create a new file named `my_script.py` and populate it with the template's content, replacing the placeholders with their dynamic values.

You've now successfully installed and used `mk`! To explore its more advanced features, check out the other pages in this wiki.
