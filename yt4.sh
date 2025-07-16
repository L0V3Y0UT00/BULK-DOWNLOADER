#!/bin/bash

# ========== Styling ==========
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ========== Dependency Check ==========
echo -e "${YELLOW}Checking dependencies...${NC}"

install_if_missing() {
    if ! command -v "$1" &>/dev/null; then
        echo -e "${YELLOW}Installing $1...${NC}"
        pkg install -y "$1"
    fi
}

# Ensure Termux environment
if [[ -n "$PREFIX" ]]; then
    install_if_missing jq
    install_if_missing ffmpeg
    install_if_missing yt-dlp
else
    echo -e "${RED}This script is designed for Termux. Please run it inside Termux.${NC}"
    exit 1
fi

# ========== Step 1: Channel URL to Extract Shorts ==========
echo -e "\n${YELLOW}Enter the full YouTube channel URL (or press Enter to skip):${NC}"
read -r channel_url

if [[ -n "$channel_url" ]]; then
    echo -e "${GREEN}Extracting video URLs from channel...${NC}"

    channel_json=$(yt-dlp --flat-playlist --dump-single-json "$channel_url")
    channel_title=$(echo "$channel_json" | jq -r '.title' | sed 's/[^a-zA-Z0-9_-]/_/g')
    output_file="@${channel_title}_shorts.txt"

    echo "$channel_json" \
    | jq -r '.entries[].url' \
    | awk '{
        if ($0 ~ /^https?:\/\//) {
            print $0
        } else {
            print "https://www.youtube.com/watch?v=" $0
        }
    }' > "$output_file"

    if [[ -s "$output_file" ]]; then
        count=$(wc -l < "$output_file")
        full_path=$(realpath "$output_file")
        echo -e "${GREEN}Video URLs saved to ${output_file}${NC}"
        echo -e "${GREEN}Saved $count videos to ${output_file}${NC}"
        echo -e "${YELLOW}Path:${NC} $full_path"
    else
        echo -e "${RED}No URLs found. Please check the channel URL.${NC}"
        exit 1
    fi
fi

# ========== Step 2: Let user pick file or folder ==========
echo -e "\n${YELLOW}Listing items in current directory:${NC}"
items=(*)  # all files/folders
for i in "${!items[@]}"; do
    printf "%3d) %s\n" "$((i+1))" "${items[i]}"
done

echo
read -p "Select a number to pick a file or folder: " choice
selected="${items[choice-1]}"
echo -e "\n${GREEN}You selected: $selected${NC}"

# If folder, pick a file inside
if [[ -d "$selected" ]]; then
    echo -e "\n${YELLOW}Listing files in folder: $selected${NC}"
    files_in_folder=("$selected"/*)
    if [[ ${#files_in_folder[@]} -eq 0 ]]; then
        echo -e "${RED}No files found in the folder.${NC}"
        exit 1
    fi
    for i in "${!files_in_folder[@]}"; do
        printf "%3d) %s\n" "$((i+1))" "${files_in_folder[i]##*/}"
    done
    echo
    read -p "Select a number to pick a file from the folder: " file_choice
    file_selected="${files_in_folder[file_choice-1]}"
    echo -e "\n${GREEN}You picked file: $file_selected${NC}"
else
    file_selected="$selected"
    echo -e "${GREEN}You picked file: $file_selected${NC}"
fi

# ========== Step 3: Validate file ==========
if [[ ! -f "$file_selected" || "${file_selected##*.}" != "txt" ]]; then
    echo -e "${RED}The selected file is not a .txt file. Exiting.${NC}"
    exit 1
fi

# ========== Step 4: Show file contents ==========
echo -e "\n${YELLOW}File contents (YouTube Shorts URLs):${NC}"
nl -w3 -s'. ' "$file_selected"

total_lines=$(wc -l < "$file_selected")
range_label=$(basename "$file_selected" .txt)

# ========== Step 5: Ask for download range ==========
echo
read -p "Enter ${range_label} video range (1-${total_lines}) to download (e.g., 5-15): " range_input

start=$(echo "$range_input" | cut -d'-' -f1)
end=$(echo "$range_input" | cut -d'-' -f2)

if ! [[ "$start" =~ ^[0-9]+$ && "$end" =~ ^[0-9]+$ && "$end" -ge "$start" && "$start" -le "$total_lines" ]]; then
    echo -e "${RED}Invalid range: $range_input${NC}"
    exit 1
fi

# ========== Step 6: Prepare download ==========
selected_urls=$(sed -n "${start},${end}p" "$file_selected")
download_dir="${range_label}_videos"
mkdir -p "$download_dir"

echo -e "\n${YELLOW}Videos will be saved to: ${download_dir}${NC}"
echo -e "\n${GREEN}Selected URLs to download (${start}-${end}):${NC}"
echo "$selected_urls"

# ========== Step 7: Download using yt-dlp ==========
tmp_file="$(mktemp "$PREFIX/tmp/ytdl_urls.XXXXXX")"
echo "$selected_urls" > "$tmp_file"

yt-dlp -o "${download_dir}/%(title).80s.%(ext)s" -a "$tmp_file"

rm -f "$tmp_file"

echo -e "\n${GREEN}Download completed. Saved to '${download_dir}'${NC}"
