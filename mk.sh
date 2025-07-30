#!/bin/bash

# Get the directory where the script is located
# SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Function to show usage information
_mk_usage() {
  echo "Usage: mk [file_name|directory_name/] [options]"
  echo "Options:"
  echo "  -v, --verbose             Provide detailed output"
  echo "  -c, --chmod=MODE          Set file or directory permissions (e.g., 644, 755)"
  echo "  -t, --template=FILE       Create a file from a template file in ~/.mk/.templates/"
  echo "  -nt, --no-template        Do not apply any template"
  echo "  -o, --open                Open the created file or directory"
  echo "  -l, --list=FILE           Create files and directories from a list"
  echo "  -y, --yes                 Automatically overwrite all conflicting files/directories"
  echo "  -n, --no                  Automatically skip all conflicting files/directories"
  echo "  -h, --help                Show this help message"
}

# Refactored function to apply templates
_mk_apply_template_logic() {
    local input="$1"
    local template="$2"
    local verbose="$3"
    local no_template="$4"

    if $no_template; then
        return 0
    fi

    local template_file_to_use=""
    local template_dir="$HOME/.mk/.templates"
    local config_file="$HOME/.mk/mk.conf"
    local extension_check=true # Default

    if [ -f "$config_file" ]; then
        source "$config_file"
    fi

    if [ ! -d "$template_dir" ]; then
        $verbose && echo "Template directory not found at '$template_dir'."
        return 0
    fi

    # 1. Explicit template
    if [ -n "$template" ]; then
        local found_template=$(find "$template_dir" -maxdepth 1 -type f \( -name "$template" -o -name "$template.*" \) 2>/dev/null | head -n 1)
        if [ -n "$found_template" ]; then
            template_file_to_use="$found_template"
            $verbose && echo "Using explicit template: $template_file_to_use"
        else
            $verbose && echo "Warning: Template '$template' not found in '$template_dir'."
        fi
    # 2. Implicit template by extension
    elif [ "$extension_check" = true ]; then
        local extension="${input##*.}"
        if [[ -n "$extension" && "$extension" != "$input" ]]; then
            local found_template=$(find "$template_dir" -maxdepth 1 -type f -name "*.$extension" 2>/dev/null | head -n 1)
            if [ -n "$found_template" ]; then
                template_file_to_use="$found_template"
                $verbose && echo "Found implicit template for extension '.$extension': $template_file_to_use"
            fi
        fi
    fi

    # 3. Apply if found
    if [ -n "$template_file_to_use" ]; then
        cat "$template_file_to_use" > "$input"
        $verbose && echo "Template applied."
    fi
}

# Refactored function to handle overwrite logic
_mk_handle_overwrite() {
    local input="$1"
    local verbose="$2"
    local auto_overwrite="$3"
    local auto_skip="$4"

    if [ ! -e "$input" ]; then
        echo "proceed" # It's a new file/dir
        return 0
    fi

    if [ "$auto_overwrite" = true ]; then
        $verbose && echo "Overwriting '$input'..."
        echo "proceed"
        return 0
    fi

    if [ "$auto_skip" = true ]; then
        $verbose && echo "Skipping '$input'..."
        echo "skip"
        return 0
    fi

    echo "The file or directory '$input' already exists. Do you want to overwrite it? (y/n)"
    read -r response
    case "$response" in
        [Yy]*)
            $verbose && echo "Overwriting '$input'..."
            echo "proceed"
            ;;
        *)
            echo "Aborting creation of: $input"
            echo "abort"
            ;;
    esac
}

# Main creation function, now refactored
_mk_create_single() {
    local input="$1"
    local template="$2"
    local chmod_mode="$3"
    local open_after_creation="$4"
    local verbose="$5"
    local auto_overwrite="$6"
    local auto_skip="$7"
    local no_template="$8"

    local overwrite_status
    overwrite_status=$(_mk_handle_overwrite "$input" "$verbose" "$auto_overwrite" "$auto_skip")

    case "$overwrite_status" in
        *"skip"*) return 0 ;;
        *"abort"*) return 1 ;;
    esac

    local is_new_file=true
    [ -e "$input" ] && is_new_file=false

    # Handle directory creation
    if [[ "$input" == */ ]]; then
        local dir_name="${input%/}"
        if $is_new_file; then
            if ! mkdir -p "$dir_name"; then
                echo "Failed to create directory: $dir_name"
                return 1
            fi
            $verbose && echo "Directory created: $dir_name"
        fi
        
        [ -n "$chmod_mode" ] && chmod "$chmod_mode" "$dir_name"
        
        if $open_after_creation; then
            cd "$dir_name" && echo "Switched to directory: $dir_name"
        fi
    # Handle file creation
    else
        if $is_new_file; then
            local dir_name=$(dirname "$input")
            if ! mkdir -p "$dir_name" || ! touch "$input"; then
                echo "Failed to create file: $input"
                return 1
            fi
            $verbose && echo "File created: $input"
        fi

        _mk_apply_template_logic "$input" "$template" "$verbose" "$no_template"
        
        [ -n "$chmod_mode" ] && chmod "$chmod_mode" "$input"

        if $open_after_creation; then
            ${EDITOR:-nano} "$input"
        fi
    fi
    return 0
}

# Function to process a list of files and directories
_mk_create_from_list() {
    local list_file="$1"
    # Capture global options passed from the main command
    local global_template="$2"
    local global_chmod_mode="$3"
    local global_open_after_creation="$4"
    local global_verbose="$5"
    local global_auto_overwrite="$6"
    local global_auto_skip="$7"
    local global_no_template="$8"

    if [ ! -f "$list_file" ]; then
        echo "List file not found: $list_file"
        return 1
    fi

    while IFS= read -r line; do
        # Skip empty lines, whitespace-only lines, and comments
        if ! [[ "$line" =~ [^[:space:]] ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi

        # Portably extract the first word (the input file/dir) and the rest of the line
        local input
        local line_args
        read -r input line_args <<< "$line"

        # Initialize line-specific options with global defaults
        local template="$global_template"
        local chmod_mode="$global_chmod_mode"
        local open_after_creation="$global_open_after_creation"
        local no_template="$global_no_template"
        local auto_overwrite="$global_auto_overwrite"
        local auto_skip="$global_auto_skip"

        # Parse per-line arguments from the rest of the line
        for arg in $line_args; do
            case "$arg" in
                -t=*|--template=*)
                    template="${arg#*=}"
                    ;;
                -c=*|--chmod=*)
                    chmod_mode="${arg#*=}"
                    ;;
                -o|--open)
                    open_after_creation=true
                    ;;
                --no-template)
                    no_template=true
                    ;;
                -y|--yes)
                    auto_overwrite=true
                    ;;
                -n|--no)
                    auto_skip=true
                    ;;
            esac
        done

        # Call the creation function with the final merged options for the line
        _mk_create_single "$input" "$template" "$chmod_mode" "$open_after_creation" "$global_verbose" "$auto_overwrite" "$auto_skip" "$no_template"
        if [ $? -ne 0 ]; then
            echo "Stopping list processing due to an error."
            return 1
        fi
    done < "$list_file"

    return 0
}

# Main function
mk() {
  local verbose=false
  local chmod_mode=""
  local list_file=""
  local template=""
  local open_after_creation=false
  local auto_overwrite=false
  local auto_skip=false
  local no_template=false # New variable
  local input=""

  local options
  options=$(getopt -o vc:t:ol:ynh --long verbose,chmod:,template:,open,list:,yes,no,help,no-template -n 'mk' -- "$@")
  if [ $? -ne 0 ]; then
    _mk_usage
    return 1
  fi

  eval set -- "$options"

  while true; do
    case "$1" in
      -v|--verbose) verbose=true; shift ;;
      -c|--chmod) chmod_mode="$2"; shift 2 ;;
      -t|--template) template="$2"; shift 2 ;;
      --no-template) no_template=true; shift ;; # New option
      -o|--open) open_after_creation=true; shift ;;
      -l|--list) list_file="$2"; shift 2 ;;
      -y|--yes) auto_overwrite=true; shift ;;
      -n|--no) auto_skip=true; shift ;;
      -h|--help) _mk_usage; return 0 ;;
      --) shift; break ;;
      *) echo "Internal error!"; exit 1 ;;
    esac
  done

  input="$1"

  if [[ -z "$input" && -z "$list_file" ]]; then
    _mk_usage
    return 1
  fi

  if [ -n "$list_file" ]; then
    _mk_create_from_list "$list_file" "$template" "$chmod_mode" "$open_after_creation" "$verbose" "$auto_overwrite" "$auto_skip" "$no_template"
    local ret_code=$?
    if [ $ret_code -ne 0 ]; then
        return $ret_code
    fi
  else
    _mk_create_single "$input" "$template" "$chmod_mode" "$open_after_creation" "$verbose" "$auto_overwrite" "$auto_skip" "$no_template"
    return $?
  fi
}