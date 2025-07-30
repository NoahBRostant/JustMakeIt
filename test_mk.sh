#!/bin/bash

# Source the mk script to make the mk function available
# Get the directory of the test script
TEST_SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
MK_SCRIPT_PATH="$TEST_SCRIPT_DIR/mk.sh"
CONFIG_FILE="$TEST_SCRIPT_DIR/mk.conf"

source "$MK_SCRIPT_PATH" || { echo "Failed to source mk.sh from $MK_SCRIPT_PATH"; exit 1; }
type mk >/dev/null 2>&1 || { echo "mk command not found after sourcing"; exit 1; }

# Colors for output
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# --- Test Helper Functions ---
_assert_success() {
    local description="$1"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[PASS]${NC} $description"
    else
        echo -e "${RED}[FAIL]${NC} $description"
        exit 1
    fi
}

_assert_fail() {
    local description="$1"
    if [ $? -ne 0 ]; then
        echo -e "${GREEN}[PASS]${NC} $description"
    else
        echo -e "${RED}[FAIL]${NC} $description"
        exit 1
    fi
}

_assert_exists() {
    local path="$1"
    local description="$2"
    if [ -e "$path" ]; then
        _assert_success "$description"
    else
        echo -e "${RED}[FAIL]${NC} $description: File or directory '$path' does not exist."
        exit 1
    fi
}

_assert_contains() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    if grep -q "$pattern" "$file"; then
        _assert_success "$description"
    else
        echo -e "${RED}[FAIL]${NC} $description: Pattern '$pattern' not found in '$file'."
        exit 1
    fi
}

_assert_not_contains() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    if ! grep -q "$pattern" "$file"; then
        _assert_success "$description"
    else
        echo -e "${RED}[FAIL]${NC} $description: Pattern '$pattern' was found in '$file'."
        exit 1
    fi
}

# Check for Lua interpreter
LUA_AVAILABLE=false
if command -v lua >/dev/null; then
    LUA_AVAILABLE=true
else
    echo -e "\n\033[0;33m[WARN] 'lua' command not found. Skipping Lua placeholder tests.\033[0m"
fi

# --- Test Setup ---
TEST_DIR="$TEST_SCRIPT_DIR/mk_test_dir"
TEMPLATE_DIR="$TEST_SCRIPT_DIR/.templates"
# Note: The LUA_PLACEHOLDER_FILE is now created *inside* the TEST_DIR
LUA_PLACEHOLDER_FILE="$TEST_DIR/mk_placeholders.lua" 

# Clean up previous test runs
echo "Cleaning up old test directory and templates..."
rm -rf "$TEST_DIR"
rm -f "$CONFIG_FILE"
# Keep the python.py template, remove others
find "$TEMPLATE_DIR" -type f ! -name 'python.py' -delete

mkdir -p "$TEST_DIR"
cd "$TEST_DIR" || exit 1
echo "Running tests in $(pwd)"

# Create dummy templates for testing
echo "Creating dummy templates..."
echo "#!/bin/sh - shebang" > "$TEMPLATE_DIR/sh.sh"
echo "<h1>HTML Test</h1>" > "$TEMPLATE_DIR/html.html"
echo "Filename: <{&FILENAME&}>, Author: <{&AUTHOR&}>, OS: <{&USEROS&}>" > "$TEMPLATE_DIR/placeholder.tpl"
_assert_exists "$TEMPLATE_DIR/sh.sh" "Create sh.sh test template"
_assert_exists "$TEMPLATE_DIR/html.html" "Create html.html test template"
_assert_exists "$TEMPLATE_DIR/placeholder.tpl" "Create placeholder.tpl test template"

# Create dummy Lua placeholder script if Lua is available
if $LUA_AVAILABLE; then
cat <<EOL > "$LUA_PLACEHOLDER_FILE"
function get_placeholders()
    local placeholders = {}
    placeholders["AUTHOR"] = "Test Author"
    placeholders["USEROS"] = "TestOS"
    return placeholders
end
local placeholders = get_placeholders()
for key, value in pairs(placeholders) do
    print(key .. "=" .. value)
end
EOL
_assert_exists "$LUA_PLACEHOLDER_FILE" "Create test mk_placeholders.lua"
fi



# --- Test Cases ---

# 1. Basic File and Directory Creation
echo -e "\n--- Testing Basic Creation ---"
mk test_file.txt --no-template -v
_assert_exists "test_file.txt" "Create a simple file"

mk test_dir/ -v
_assert_exists "test_dir" "Create a simple directory"

mk nested/dir/file.txt --no-template -v
_assert_exists "nested/dir/file.txt" "Create a file in a nested directory"

# 2. Template Creation
echo -e "\n--- Testing Template Creation (New System) ---"
# Explicit template
mk script.sh -t sh.sh -v
_assert_exists "script.sh" "Create a shell script with explicit --template"
_assert_contains "script.sh" "#!/bin/sh - shebang" "Shell script should contain content from sh.sh template"

# Implicit template by extension (with config enabled)
echo "extension_check=true" > "$CONFIG_FILE"
mk index.html -v
_assert_exists "index.html" "Create an HTML file with implicit template (check enabled)"
_assert_contains "index.html" "<h1>HTML Test</h1>" "HTML file should contain content from html.html template"

# Implicit template by extension (with config disabled)
echo "extension_check=false" > "$CONFIG_FILE"
mk no_implicit.html -v
_assert_exists "no_implicit.html" "Create an HTML file with implicit template (check disabled)"
_assert_not_contains "no_implicit.html" "<h1>HTML Test</h1>" "HTML file should be empty when check is disabled"

# No template flag
mk no_template.sh --no-template -v
_assert_exists "no_template.sh" "Create a file with --no-template flag"
_assert_not_contains "no_template.sh" "#!/bin/sh - shebang" "File with --no-template should be empty"

# Implicit python template
echo "extension_check=true" > "$CONFIG_FILE"
mk my_script.py -v
_assert_exists "my_script.py" "Create a Python file with implicit template"
_assert_contains "my_script.py" "if __name__ == \"__main__\":" "Python file should contain main execution block"

# 3. Placeholder Processing
echo -e "\n--- Testing Placeholder Processing ---"
if $LUA_AVAILABLE; then
    mk placeholder_test.txt --template=placeholder.tpl -v
    _assert_exists "placeholder_test.txt" "Create file with placeholders"
    _assert_contains "placeholder_test.txt" "Filename: placeholder_test.txt" "File should contain replaced filename"
    _assert_contains "placeholder_test.txt" "Author: Test Author" "File should contain replaced Lua author"
    _assert_contains "placeholder_test.txt" "OS: TestOS" "File should contain replaced Lua OS"
else
    # If Lua is not available, test that built-in placeholders still work
    mk placeholder_test.txt --template=placeholder.tpl -v
    _assert_exists "placeholder_test.txt" "Create file with placeholders (no Lua)"
    _assert_contains "placeholder_test.txt" "Filename: placeholder_test.txt" "File should contain replaced filename (no Lua)"
    _assert_not_contains "placeholder_test.txt" "Author: Test Author" "File should not contain Lua placeholders"
fi

# 4. Permissions
echo -e "\n--- Testing Permissions ---"
mk perm_test.txt --chmod=777 --no-template -v
_assert_exists "perm_test.txt" "Create a file with specific permissions"
if [ -x "perm_test.txt" ]; then
    _assert_success "File should have execute permissions"
else
    _assert_fail "File should have execute permissions"
fi

# 5. Overwrite Logic
echo -e "\n--- Testing Overwrite Logic ---"
echo "initial content" > overwrite.txt
# Test interactive overwrite 'y' with a template
echo 'y' | mk overwrite.txt -t sh.sh -v
_assert_success "Overwrite an existing file with 'y' and a template"
_assert_contains "overwrite.txt" "#!/bin/sh - shebang" "File content should be overwritten by the template"

# Test automatic overwrite with --yes
echo "new content" > overwrite_yes.txt
mk overwrite_yes.txt --yes --no-template -v
_assert_success "Overwrite an existing file with --yes"

# Test skip with --no
echo "original" > no_overwrite.txt
mk no_overwrite.txt --no -t sh.sh -v
_assert_success "Skip overwriting an existing file with --no"
_assert_contains "no_overwrite.txt" "original" "File content should not be changed with --no"

# 6. List Mode
echo -e "\n--- Testing List Mode ---"
cat <<EOL > file_list.txt
list_file1.txt
list_dir/
nested_list/file2.txt
EOL
# Note: Template logic in list mode might have limitations
mk --list=file_list.txt --no-template -v
_assert_exists "list_file1.txt" "Create file from list"
_assert_exists "list_dir" "Create directory from list"
_assert_exists "nested_list/file2.txt" "Create nested file from list"

# 7. List Mode with Per-Line Arguments
echo -e "\n--- Testing List Mode with Arguments ---"
cat <<EOL > list_with_args.txt
# This is a test list with arguments
list_script.sh --template=sh.sh
list_html.html # Should use implicit template
list_no_template.txt --no-template
list_chmod.txt --chmod=777
EOL

# Set a global option that should be overridden
mk --list=list_with_args.txt --template=html.html -v
_assert_exists "list_script.sh" "List: Create shell script with per-line template"
_assert_contains "list_script.sh" "#!/bin/sh - shebang" "List: Shell script should contain sh content"
_assert_exists "list_html.html" "List: Create HTML file with implicit template"
_assert_contains "list_html.html" "<h1>HTML Test</h1>" "List: HTML file should contain html content"
_assert_exists "list_no_template.txt" "List: Create file with --no-template"
_assert_not_contains "list_no_template.txt" "<h1>" "List: no_template file should be empty"
_assert_exists "list_chmod.txt" "List: Create file with per-line chmod"
if [ -x "list_chmod.txt" ]; then
    _assert_success "List: chmod file should have execute permissions"
else
    _assert_fail "List: chmod file should have execute permissions"
fi

# 8. Edge Cases and Error Handling
echo -e "\n--- Testing Error Handling ---"
# Test invalid template (should create an empty file with a warning)
output=$(mk non_existent_dir/file.txt --template=invalid.tpl -v 2>&1)
_assert_exists "non_existent_dir/file.txt" "File should still be created with an invalid template"
if echo "$output" | grep -q "Warning: Template 'invalid.tpl' not found"; then
    _assert_success "Using an invalid template should show a warning"
else
    _assert_fail "Using an invalid template should show a warning. Output: $output"
fi

# mk --list=non_existent_list.txt >/dev/null 2>&1
# _assert_fail "Using a non-existent list file should fail"

# 9. --open flag (mocking the editor)
echo -e "\n--- Testing --open Flag ---"
export EDITOR="echo FAKE_EDITOR"
output=$(mk open_test.txt --open --no-template -v 2>&1)
if echo "$output" | grep -q "FAKE_EDITOR open_test.txt"; then
    _assert_success "--open should try to launch the editor for files"
else
    echo -e "${RED}[FAIL]${NC} --open did not launch the editor for a file. Output: $output"
fi
unset EDITOR


# --- Test Cleanup ---
echo -e "\n--- Cleaning up ---"
cd "$TEST_SCRIPT_DIR"
rm -rf "$TEST_DIR"
rm -f "$CONFIG_FILE"
rm -f "$LUA_PLACEHOLDER_FILE"
# Clean up dummy templates
rm -f "$TEMPLATE_DIR/sh.sh" "$TEMPLATE_DIR/html.html" "$TEMPLATE_DIR/placeholder.tpl"
echo -e "${GREEN}Cleanup complete.${NC}"

echo -e "\n${GREEN}All tests passed!${NC}"
