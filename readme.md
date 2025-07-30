<div align="center">

<img src="./assets/logo.png" width="150px" alt="Project Logo" />

# JustMakeIt

![GitHub Release](https://img.shields.io/github/v/release/NoahBRostant/JustMakeIt?sort=semver&display_name=release&style=flat)
![GitHub License](https://img.shields.io/github/license/NoahBRostant/JustMakeIt)

**A powerful command-line utility to streamline file and directory creation.**

</div>

---

`mk` is a smart alternative to `touch` and `mkdir`, designed to accelerate your development workflow. It allows you to create files and directories from powerful templates, reducing boilerplate and automating project setup.

<br>

### ✨ Core Features

-   **Template-Based Creation**: Instantly create files from templates stored in `~/.mk/.templates/`.
-   **Dynamic Placeholders**: Automatically populate your files with variables like `<{&FILENAME&}>` or even custom placeholders defined in Lua.
-   **Powerful List Mode**: Create entire project structures from a single text file, with per-line arguments for ultimate control.
-   **Smart & Safe**: Includes interactive overwrite protection, permission management, and a simple configuration system.

<br>

### 🚀 Quick Start

1.  **Install the script** and make it available in your shell by sourcing it in your profile (e.g., `~/.bashrc` or `~/.zshrc`).
    ```sh
    # Add this line to your shell's profile file
    source /path/to/your/mk.sh
    ```

2.  **Create a template.** For example, create a simple Python template at `~/.mk/.templates/python.py`:
    ```python
    # Author: <{&AUTHOR&}>
    # Created on: <{&DATE&}>
    # File: <{&FILENAME&}>

    def main():
        print("Hello, World!")

    if __name__ == "__main__":
        main()
    ```

3.  **Use `mk` to create a new file from your template!**
    ```bash
    mk my_new_script.py
    ```
    This will create `my_new_script.py` with all the placeholders automatically filled in.

<br>

> ### 📚 **Want to learn more?**
>
> This is just the beginning. `mk` has many more powerful features, including custom placeholders, advanced list mode, and configuration options.
>
> **[Check out the Wiki for detailed documentation and examples!](https://github.com/NoahBRostant/JustMakeIt/wiki)**

---

### 🛠️ Testing

The script includes a full test suite. To run it, first make the test script executable, then run it.

```bash
chmod +x ./test_mk.sh
./test_mk.sh
```

---

### 📜 License

This project is licensed under the **MIT License**. See the `LICENSE` file for more details.
