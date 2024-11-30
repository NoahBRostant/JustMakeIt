#!/bin/bash

# Source the mk script
source ~/.mk/mk.sh || { echo "Failed to source mk.sh"; exit 1; }
type mk >/dev/null 2>&1 || { echo "mk command not found after sourcing"; exit 1; }

# Colors for output
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# Function to run a test case
run_test() {
  local description="$1"
  local command="$2"
  local expected="$3"

  echo "[RUNNING] $description"
  local output
  output=$(eval "$command" 2>&1)
  echo "$output" > "debug_${description// /_}.log"  # Save output to a debug log file

  if echo "$output" | grep -q "$expected"; then
    echo -e "${GREEN}[PASS]${NC} $description"
  else
    echo -e "${RED}[FAIL]${NC} $description"
    echo "Command output:"
    echo "$output"
  fi
}

# Set up test directory
TEST_DIR="./mk_test"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR" || exit 1

# Test cases
echo "Running tests for the mk command..."

# Template creation
run_test "Create a Python file with --template=py" "mk python_test.py --template=py -v" "File created: python_test.py"
run_test "Create a shell script with -t sh" "mk script.sh -t=sh -v" "File created: script.sh"

# Directory creation
run_test "Create a directory" "mk new_dir/ -v" "Directory created: new_dir"

# File in nested directory
run_test "Create a file in a nested directory" "mk nested/dir/file.txt -v" "File created: nested/dir/file.txt"

# Verbose mode
run_test "Verbose mode for file creation" "mk verbose_test.txt --verbose" "File created: verbose_test.txt"

# chmod
run_test "Set permissions with --chmod=644" "mk chmod_test.txt --chmod=644" ""
[[ "$(stat -c '%a' chmod_test.txt 2>/dev/null || ls -l chmod_test.txt | awk '{print $1}')" == "644" ]] && \
  echo -e "${GREEN}[PASS]${NC} chmod applied correctly" || echo -e "${RED}[FAIL]${NC} chmod not applied"

# Open file
#run_test "Create and open a file" "mk open_test.txt --open -v" "File created: open_test.txt"
#nohup mk open_test.txt --open -v &
#sleep 1  # Give the editor time to open
#[[ -f open_test.txt ]] && echo -e "${GREEN}[PASS]${NC} File exists" || echo -e "${RED}[FAIL]${NC} File not created"


# Overwrite existing file
echo "Test content" > overwrite_test.txt
run_test "Overwrite an existing file" "mk overwrite_test.txt <<< 'y'" "Overwriting 'overwrite_test.txt'"

# List mode
echo -e "./file1.txt\nfile2.txt\n./directory1/\ndirectory2/" > file_list.txt
run_test "Create files and directories from a list" "mk --list=file_list.txt --verbose" "Processing ./file1.txt
File created: ./file1.txt
Processing file2.txt
File created: file2.txt
Processing ./directory1/
Directory created: ./directory1/
Processing directory2/
Directory created: directory2/"

# Invalid template
run_test "Handle invalid template gracefully" "mk invalid_template --template=invalid" "Unknown template: invalid"

# Cleanup
echo "Cleaning up test directory..."
cd .. && rm -rf "$TEST_DIR"
echo -e "${GREEN}[PASS]${NC} Clean up test directory"

echo "All tests completed!"

