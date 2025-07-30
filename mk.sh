#!/bin/bash

# JustMakeIt v1.1.0
CURRENT_VERSION="v1.1.0"

# --- Update Checker ---
_mk_check_for_updates() {
    local config_file="$HOME/.mk/mk.conf"
    local auto_update_check=false # Default to true

    if [ -f "$config_file" ]; then
        # Read the config file safely
        while IFS='=' read -r key value; do
            if [[ "$key" == "auto_update_check" ]]; then
                auto_update_check="$value"
            fi
        done < "$config_file"
    fi

    # Exit if the user has disabled the auto-update check
    if [[ "$auto_update_check" != "true" ]]; then
        return
    fi

    local last_check_file="$HOME/.mk/.last_check"
    # Check if an update check has been performed in this shell session
    if [ -n "$MK_UPDATE_CHECKED" ]; then
        return
    fi
    export MK_UPDATE_CHECKED=true

    # Only check for updates once every 24 hours
    if [ -f "$last_check_file" ]; then
        local last_check_time=$(stat -c %Y "$last_check_file")
        local current_time=$(date +%s)
        if (( (current_time - last_check_time) < 86400 )); then
            return
        fi
    fi

    # Fetch the latest release tag from GitHub API
    local latest_version
    latest_version=$(curl -s "https://api.github.com/repos/NoahBRostant/JustMakeIt/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

    if [[ -n "$latest_version" ]]; then
        # Use sort -V for a robust version comparison
        local highest_version
        highest_version=$(printf "%s\n%s" "$CURRENT_VERSION" "$latest_version" | sort -V | tail -n 1)

        if [[ "$highest_version" != "$CURRENT_VERSION" ]]; then
            # ANSI color codes for yellow text
            local yellow='\033[1;33m'
            local nc='\033[0m' # No Color
            # Write the notification to a file instead of echoing directly
            echo -e "${yellow}A new version of mk ($latest_version) is available! Run 'mk --update' to install it.${nc}" > "$HOME/.mk/.update_notice"
        fi
    fi

    # Update the timestamp file
    touch "$last_check_file"
}


# Get the directory where the script is located
# SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Function to show usage information
_mk_usage() {
  echo "Usage: mk [file_name|directory_name/] [options]"
  echo "Options:"
  echo "  -v, --verbose             Provide detailed output"
  echo "  -V, --version             Display the version number"
  echo "  -c, --chmod MODE          Set file or directory permissions (e.g., 644, 755)"
  echo "  -t, --template FILE       Create a file from a template file in ~/.mk/.templates/"
  echo "      --list-templates      List the available templates in ~/.mk/.templates/"
  echo "      --no-template         Do not apply any template"
  echo "  -o, --open                Open the created file or directory"
  echo "  -l, --list FILE           Create files and directories from a list"
  echo "  -y, --yes                 Automatically overwrite all conflicting files/directories"
  echo "  -n, --no                  Automatically skip all conflicting files/directories"
  echo "  -h, --help                Show this help message"
  echo "  -u, --update              Check and update JustMakeIt"
}

# Function to process placeholders in a template file
_mk_process_template_placeholders() {
    local input_file="$1"
    local verbose="$2"
    local sed_expressions=""

    # 1. Built-in placeholders
    local filename=$(basename "$input_file")
    local current_date=$(date +%Y-%m-%d)
    local current_time=$(date +%H:%M:%S)
    local current_datetime=$(date +"%Y-%m-%d %H:%M:%S")

    sed_expressions+="-e 's/<{&FILENAME&}>/$filename/g' "
    sed_expressions+="-e 's/<{&DATE&}>/$current_date/g' "
    sed_expressions+="-e 's/<{&TIME&}>/$current_time/g' "
    sed_expressions+="-e 's/<{&DATETIME&}>/$current_datetime/g' "

    # 2. Lua-defined placeholders
    # Check for a local placeholder file first, then fall back to the home directory
    local lua_script_path="./mk_placeholders.lua"
    if [ ! -f "$lua_script_path" ]; then
        lua_script_path="$HOME/.mk/mk_placeholders.lua"
    fi

    if command -v lua >/dev/null && [ -f "$lua_script_path" ]; then
        $verbose && echo "Executing Lua placeholder script from '$lua_script_path'..."
        local lua_output
        lua_output=$(lua "$lua_script_path")
        
        while IFS='=' read -r key value; do
            # Skip empty lines from Lua output
            if [ -n "$key" ]; then
                $verbose && echo "  - Found Lua placeholder: $key"
                sed_expressions+="-e 's/<{&"$key"&}>/$value/g' "
            fi
        done <<< "$lua_output"
    fi

    # 3. Perform all replacements in a single sed command
    if [ -n "$sed_expressions" ]; then
        # Use a temporary variable to build the command safely
        local sed_command="sed -i.bak $sed_expressions \"$input_file\""
        eval "$sed_command"
        rm -f "$input_file.bak"
        $verbose && echo "Processed placeholders in '$input_file'."
    fi
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
        # Read the config file safely, only parsing the expected variable
        while IFS='=' read -r key value; do
            # Remove potential quotes from value
            value=${value#\"}
            value=${value%\"}
            if [[ "$key" == "extension_check" ]]; then
                extension_check="$value"
            fi
        done < "$config_file"
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
        # 4. Process placeholders
        _mk_process_template_placeholders "$input" "$verbose"
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


# Function to list available templates
_mk_list_templates() {
    local template_dir="$HOME/.mk/.templates"
    if [ ! -d "$template_dir" ]; then
        echo "Template directory not found at '$template_dir'."
        return 1
    fi

    echo "Available templates:"
    local templates_found=false
    for template in "$template_dir"/*; do
        if [ -f "$template" ]; then
            echo "  - $(basename "$template")"
            templates_found=true
        fi
    done

    if ! $templates_found; then
        echo "  No templates found."
    fi
}

# Function to perform the self-update
_mk_perform_update() {
    echo "Checking for the latest version..."
    local latest_version
    latest_version=$(curl -s "https://api.github.com/repos/NoahBRostant/JustMakeIt/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

    if [[ -z "$latest_version" ]]; then
        echo "Could not fetch the latest version. Please check your internet connection."
        return 1
    fi

    local highest_version
    highest_version=$(printf "%s\n%s" "$CURRENT_VERSION" "$latest_version" | sort -V | tail -n 1)

    if [[ "$highest_version" == "$CURRENT_VERSION" && "$latest_version" != "$CURRENT_VERSION" ]]; then
        echo "You are on a newer version ($CURRENT_VERSION) than the latest release ($latest_version)."
        return 0
    elif [[ "$highest_version" == "$CURRENT_VERSION" ]]; then
        echo "You are already on the latest version ($CURRENT_VERSION)."
        return 0
    fi

    echo "A new version ($latest_version) is available. Do you want to update? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Update aborted."
        return 1
    fi

    echo "Downloading the latest version..."
    local download_url="https://github.com/NoahBRostant/JustMakeIt/releases/latest/download/mk.sh"
    local temp_file="/tmp/mk.sh.new"
    if ! curl -L "$download_url" -o "$temp_file"; then
        echo "Download failed. Please try again later."
        return 1
    fi

    # The path to the currently running script
    local script_path="$HOME/.mk/mk.sh"
    
    # Create a helper script to perform the overwrite
    local updater_script="/tmp/mk_updater.sh"
    cat <<EOL > "$updater_script"
#!/bin/bash
# Overwrite the old script with the new one
mv "$temp_file" "$script_path"
echo "Update complete! Please restart your terminal or run 'source ~/.mk/mk.sh' to apply the changes."
# Clean up this updater script by its explicit path
rm -- "$updater_script"
EOL

    # Make the updater executable and run it silently in the background
    chmod +x "$updater_script"
    set +m
    "$updater_script" &
    disown
    set -m
    
    echo "Update process initiated. The script will now exit."
    return 0
}

# Main function
mk() {
  # Check for and display a pending update notification
  local notice_file="$HOME/.mk/.update_notice"
  if [ -f "$notice_file" ]; then
      cat "$notice_file"
      rm "$notice_file"
  fi

  # This is the robust way to run a background process from a sourced function
  # in an interactive shell without getting any job control messages.
  ( _mk_check_for_updates & )

  local verbose=false
  local chmod_mode=""
  local list_file=""
  local template=""
  local open_after_creation=false
  local auto_overwrite=false
  local auto_skip=false
  local no_template=false
  local list_templates=false
  local show_version=false
  local do_update=false # New variable
  local input=""

  local options
  options=$(getopt -o uVvc:t:ol:ynh --long update,version,verbose,chmod:,template:,open,list:,yes,no,help,no-template,list-templates -n 'mk' -- "$@")
  if [ $? -ne 0 ]; then
    _mk_usage
    return 1
  fi

  eval set -- "$options"

  while true; do
    case "$1" in
      -u|--update) do_update=true; shift ;;
      -V|--version) show_version=true; shift ;;
      -v|--verbose) verbose=true; shift ;;
      -c|--chmod) chmod_mode="$2"; shift 2 ;;
      -t|--template) template="$2"; shift 2 ;;
      --no-template) no_template=true; shift ;;
      -o|--open) open_after_creation=true; shift ;;
      -l|--list) list_file="$2"; shift 2 ;;
      --list-templates) list_templates=true; shift ;;
      -y|--yes) auto_overwrite=true; shift ;;
      -n|--no) auto_skip=true; shift ;;
      -h|--help) _mk_usage; return 0 ;;
      --) shift; break ;;
      *) echo "Internal error!"; exit 1 ;;
    esac
  done

  if $show_version; then
    echo "$CURRENT_VERSION stable"
    return 0
  fi

  if $do_update; then
    _mk_perform_update
    return 0
  fi

  if $list_templates; then
    _mk_list_templates
    return 0
  fi

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
