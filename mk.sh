#!/bin/bash

# Function to create file or directory with extended features
mk() {
  # Check if an argument is passed
  if [ -z "$1" ]; then
    echo "Usage: mk [file_name|directory_name/] [options]"
    echo "Options:"
    echo "  --verbose          | -v    Provide detailed output"
    echo "  --chmod=MODE              Set file or directory permissions (e.g., 644, 755)"
    echo "  --template=TYPE    | -t    Create a file with a predefined template (e.g., sh, html)"
    echo "  --open             | -o    Open the created file or directory"
    echo "  --list=FILE               Create files and directories from a list"
    echo "  --yes              | -y    Automatically overwrite all conflicting files/directories"
    echo "  --no               | -n    Automatically skip all conflicting files/directories"
    return 1
  fi

  # Initialize variables
  verbose=false
  chmod_mode=""
  list_mode=false
  template=""
  open_after_creation=false
  input=""
  auto_overwrite=false
  auto_skip=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --template=*|-t=*)
        template="${1#*=}"
        shift
        ;;
      --open|-o)
        open_after_creation=true
        shift
        ;;
      --verbose|-v)
        verbose=true
        shift
        ;;
      --chmod=*)
        chmod_mode="${1#*=}"
        shift
        ;;
      --list=*|-l=*)
        list_mode=true
        list_file="${1#*=}" # Extract the value after '='
        shift
        if [[ -z "$list_file" ]]; then
          echo "Error: No list file provided"
          return 1
        fi
        ;;
      --yes|-y)
        auto_overwrite=true
        shift
        ;;
      --no|-n)
        auto_skip=true
        shift
        ;;
      *)
        # Assign the first non-option argument as the input
        if [[ -z "$input" ]]; then
          input="$1"
        else
          echo "Unexpected argument: $1"
          return 1
        fi
        shift
        ;;
    esac
  done

  # Handle --list mode
  if [ "$list_mode" = true ]; then
    if [ ! -f "$list_file" ]; then
      echo "List file not found: $list_file"
      return 1
    fi

    # Read the list file line by line
    while IFS= read -r line; do
      # Check verbose mode
      if [ "$verbose" = true ]; then
        echo "Processing $line"
      fi

      # Check if file or directory already exists
      if [[ -e "$line" ]]; then
        if [ "$auto_overwrite" = true ]; then
          echo "Overwriting $line..." > /dev/tty
          rm -rf "$line"
        elif [ "$auto_skip" = true ]; then
          echo "Skipping $line..." > /dev/tty
          continue
        else
          while true; do
            echo "$line already exists. Overwrite? (y/n)" > /dev/tty
            read -r response < /dev/tty
            case "$response" in
              [Yy]*) 
                echo "Overwriting $line..." > /dev/tty
                rm -rf "$line"
                break
                ;;
              [Nn]*) 
                echo "Skipping $line..." > /dev/tty
                continue 2
                ;;
              *) 
                echo "Invalid response. Please enter 'y' or 'n'." > /dev/tty
                ;;
            esac
          done
        fi
      fi

      # Create the file or directory based on the list item
      if [[ "$line" == */ ]]; then
        # Directory creation
        mkdir -p "$line"
        if [ "$verbose" = true ]; then
          echo "Directory created: $line"
        fi
      else
        # File creation
        touch "$line"
        if [ "$verbose" = true ]; then
          echo "File created: $line"
        fi
      fi

      # Handle chmod if set
      if [ -n "$chmod_mode" ]; then
        chmod "$chmod_mode" "$line"
        if [ "$verbose" = true ]; then
          echo "Permissions set to $chmod_mode for $line"
        fi
      fi

      # Open file if requested
      if [ "$open_after_creation" = true ] && [[ -f "$line" ]]; then
        xdg-open "$line" 2>/dev/null
      fi
    done < "$list_file"

    return 0
  fi

  # Ensure input is valid
  if [ -z "$input" ]; then
    echo "Error: No file or directory name specified."
    return 1
  fi

  # Safety check for existing file or directory
  if [[ -e "$input" ]]; then
    if [ "$auto_overwrite" = true ]; then
      echo "Overwriting '$input'..."
      rm -rf "$input"
    elif [ "$auto_skip" = true ]; then
      echo "Skipping '$input'..."
      return 0
    else
      echo "The file or directory '$input' already exists. Do you want to overwrite it? (y/n)"
      read -r response
      case "$response" in
        [Yy]*) 
          echo "Overwriting '$input'..."
          rm -rf "$input" 
          ;;
        *) 
          echo "Aborting creation of: $input"
          return 1
          ;;
      esac
    fi
  fi

  # Handle directory creation
  if [[ "$input" == */ ]]; then
    dir_name="${input%/}" # Remove trailing slash
    if mkdir -p "$dir_name"; then
      $verbose && echo "Directory created: $dir_name"
      # Open the directory and switch shell if requested
      $open_after_creation && cd "$dir_name" && echo "Switched to directory: $dir_name"
    else
      echo "Failed to create directory: $dir_name"
      return 1
    fi
    [[ -n "$chmod_mode" ]] && chmod "$chmod_mode" "$dir_name"
  else
    # Handle file creation with parent directories
    dir_name=$(dirname "$input")
    base_name=$(basename "$input")
    if mkdir -p "$dir_name" && touch "$input"; then
      $verbose && echo "File created: $input"
      # Open the file in the default text editor if requested
      $open_after_creation && ${EDITOR:-nano} "$input"
    else
      echo "Failed to create file: $input"
      return 1
    fi

    # Apply file templates if specified
    if [ -n "$template" ]; then
      case "$template" in
        sh)
          echo -e "#!/bin/bash\n# Script generated by mk\n\n# TODO: Your code here\n" > "$input"
          ;;
        py)
          echo -e "#!/usr/bin/env python3\n\ndef main():\n    # TODO: Your code here\n    pass\n\nif __name__ == \"__main__\":\n    main()\n" > "$input"
          ;;
        js)
          echo -e "#!/usr/bin/env node\n\n(function() {\n    // TODO: Your code here\n})();\n" > "$input"
          ;;
        rb)
          echo -e "#!/usr/bin/env ruby\n\ndef main\n  # TODO: Your code here\nend\n\nif __FILE__ == \$0\n  main\nend\n" > "$input"
          ;;
        go)
          echo -e "package main\n\nimport \"fmt\"\n\nfunc main() {\n    // TODO: Your code here\n    fmt.Println(\"Hello, World!\")\n}\n" > "$input"
          ;;
        c)
          echo -e "#include <stdio.h>\n\nint main() {\n    // TODO: Your code here\n    printf(\"Hello, World!\\n\");\n    return 0;\n}\n" > "$input"
          ;;
        cpp)
          echo -e "#include <iostream>\n\nint main() {\n    // TODO: Your code here\n    std::cout << \"Hello, World!\" << std::endl;\n    return 0;\n}\n" > "$input"
          ;;
        html)
          echo -e "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n    <meta charset=\"UTF-8\">\n    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n    <title>Document</title>\n</head>\n<body>\n    <!-- TODO: Your content here -->\n</body>\n</html>\n" > "$input"
          ;;
        css)
          echo -e "/* Basic styles generated by mk */\n\n* {\n    margin: 0;\n    padding: 0;\n    box-sizing: border-box;\n}\n\nbody {\n    font-family: Arial, sans-serif;\n    background-color: #f4f4f4;\n    color: #333;\n}\n" > "$input"
          ;;
        json)
          echo -e "{\n    \"key\": \"value\"\n}\n" > "$input"
          ;;
        md)
          echo -e "# Title\n\n## Subtitle\n\n### Introduction\nWrite your introduction here.\n\n### Conclusion\nWrite your conclusion here.\n" > "$input"
          ;;
        php)
          echo -e "<?php\n// TODO: Your code here\necho \"Hello, World!\";\n" > "$input"
          ;;
        swift)
          echo -e "import Foundation\n\nfunc main() {
    // TODO: Your code here\n    print(\"Hello, World!\")\n}\n\nmain()\n" > "$input"
          ;;
        ts)
          echo -e "#!/usr/bin/env ts-node\n\nfunction main(): void {
    // TODO: Your code here
    console.log(\"Hello, World!\");\n}\n\nmain();\n" > "$input"
          ;;
        kt)
          echo -e "fun main() {
    // TODO: Your code here
    println(\"Hello, World!\")\n}\n" > "$input"
          ;;
        java)
          echo -e "public class Main {
    public static void main(String[] args) {
        // TODO: Your code here
        System.out.println(\"Hello, World!\");\n    }\n}\n" > "$input"
          ;;
        lua)
          echo -e "-- Lua script generated by mk

function main()
    -- TODO: Your code here
end

main()
" > "$input"
          ;;
        pl)
          echo -e "#!/usr/bin/perl

sub main {
    # TODO: Your code here
}

main();
" > "$input"
          ;;
        sql)
          echo -e "-- SQL template for creating a table

CREATE TABLE example (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TODO: Your SQL queries here
" > "$input"
          ;;
        r)
          echo -e "# R script generated by mk

main <- function() {
    # TODO: Your code here
    print(\"Hello, World!\")
}

main()
" > "$input"
          ;;
        # Add other templates here
        *)
          echo "Unknown template: $template"
          return 1
          ;;
      esac
      $verbose && echo "Template applied: $template"
    fi

    # Apply permissions if specified
    [[ -n "$chmod_mode" ]] && chmod "$chmod_mode" "$input"
  fi
}

