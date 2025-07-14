#!/bin/bash

# Bulk Video Downloader Script using yt-dlp
# Version: 0.38
# Author: Ans Raza (0xAnsR)
# Enhanced with fixed URL quoting, no eval, and working cookie paste

# ---------- Configuration ----------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'; BOLD='\033[1m'
LOG_FILE="video_downloader.log"

log_message() { echo -e "$1" | tee -a "$LOG_FILE"; }

header() {
    clear
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BOLD}       BULK VIDEO DOWNLOADER TOOL ${NC}"
    echo -e "               ${YELLOW}By Ans Raza (0xAnsR)${NC}"
    echo -e "                                ${RED}v0.38${NC}"
    echo -e "${BLUE}=============================================${NC}\n"
}

check_ytdlp() {
    if ! command -v yt-dlp &>/dev/null; then
        log_message "${RED}yt-dlp not found.${NC}"
        read -p "Install yt-dlp? (y/n): " choice
        [[ "$choice" =~ ^[yY]$ ]] || exit 1
        sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp &&
        sudo chmod a+rx /usr/local/bin/yt-dlp &&
        log_message "${GREEN}yt-dlp installed.${NC}" || {
            log_message "${RED}Failed to install yt-dlp.${NC}"; exit 1; }
    fi
}

setup_cookies() {
    header
    log_message "${BOLD}YouTube Cookies Setup${NC}"
    log_message "Required for private/restricted YouTube videos.\n"

    echo -e "Choose how to provide cookies:"
    log_message "1) Provide path to cookies.txt"
    log_message "2) Paste cookies directly (saved to cookies.txt)"
    log_message "3) Skip (for public videos only)"

    read -p "${YELLOW}Select option (1-3): ${NC}" cookie_choice
    until [[ "$cookie_choice" =~ ^[1-3]$ ]]; do
        read -p "${RED}Invalid choice. Enter 1, 2, or 3: ${NC}" cookie_choice
    done

    cookies_command=""

    if [[ "$cookie_choice" == "1" ]]; then
        read -p "${YELLOW}Enter full path to cookies.txt: ${NC}" cookie_path
        if [[ -f "$cookie_path" && -s "$cookie_path" ]]; then
            cp "$cookie_path" ./cookies.txt
            cookies_command="--cookies cookies.txt"
            log_message "${GREEN}cookies.txt copied successfully.${NC}"
        else
            log_message "${RED}Invalid file path or empty file. Skipping cookies.${NC}"
        fi

    elif [[ "$cookie_choice" == "2" ]]; then
        log_message "${YELLOW}Paste your cookies below (Netscape format)."
        log_message "Type ${BOLD}EOF${NC} on a new line when finished:${NC}"
        temp_file=$(mktemp)

        while true; do
            read -r line
            [[ "$line" == "EOF" ]] && break
            echo "$line" >> "$temp_file"
        done

        if grep -q "Netscape" "$temp_file" && grep -q "youtube.com" "$temp_file"; then
            mv "$temp_file" ./cookies.txt
            cookies_command="--cookies cookies.txt"
            log_message "${GREEN}cookies.txt created successfully.${NC}"
        else
            log_message "${RED}Invalid cookies: Missing 'Netscape' header or YouTube domain.${NC}"
            rm -f "$temp_file"
        fi
    else
        log_message "${YELLOW}No cookies provided. Proceeding with public videos only.${NC}"
    fi
}

main() {
    header
    check_ytdlp
    echo > "$LOG_FILE"

    log_message "${BOLD}Select Platform:${NC}"
    platforms=("YouTube" "TikTok" "Facebook" "Other")
    for i in "${!platforms[@]}"; do
        log_message "$((i+1))) ${platforms[i]}"
    done
    read -p "${YELLOW}Enter platform number (1-4): ${NC}" platform_choice
    until [[ "$platform_choice" =~ ^[1-4]$ ]]; do
        read -p "${YELLOW}Invalid. Enter 1-4: ${NC}" platform_choice
    done
    platform="${platforms[$((platform_choice-1))]}"
    platform_lc=$(echo "$platform" | tr '[:upper:]' '[:lower:]')

    [[ "$platform_lc" == "youtube" ]] && setup_cookies

    header
    log_message "${BOLD}Select Quality:${NC}"
    qualities=("Best quality" "1080p" "720p" "480p" "Audio only (MP3)")
    for i in "${!qualities[@]}"; do
        log_message "$((i+1))) ${qualities[i]}"
    done
    read -p "${YELLOW}Choose quality (1-5): ${NC}" quality_choice
    until [[ "$quality_choice" =~ ^[1-5]$ ]]; do
        read -p "${YELLOW}Invalid. Choose 1-5: ${NC}" quality_choice
    done

    case $quality_choice in
        1) quality="b"; label="Best";;
        2) quality="bestvideo[height<=1080]+bestaudio/best[height<=1080]"; label="1080p";;
        3) quality="bestvideo[height<=720]+bestaudio/best[height<=720]"; label="720p";;
        4) quality="bestvideo[height<=480]+bestaudio/best[height<=480]"; label="480p";;
        5) quality="bestaudio -x --audio-format mp3"; label="Audio";;
    esac

    read -p "${YELLOW}Enter video URL or path to videos.txt: ${NC}" input_value
    if [[ -f "$input_value" ]]; then
        input_command=(--batch-file "$input_value")
        url_identifier="batch_$(date +%s)"
    else
        input_command=("$input_value")
        url_identifier=$(echo "$input_value" | sed 's|https\?://||' | tr -cd '[:alnum:]_')
    fi

    output_dir="${platform_lc}_${url_identifier}_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$output_dir"
    output_template="$output_dir/%(title)s.%(ext)s"

    case "$platform_lc" in
        youtube) extra=($cookies_command --ignore-errors --embed-thumbnail --add-metadata);;
        tiktok) extra=(--ignore-errors --force-overwrites --referer https://www.tiktok.com/);;
        facebook|other) extra=(--ignore-errors);;
    esac

    header
    log_message "${GREEN}Starting Download...${NC}"
    log_message "Platform: $platform"
    log_message "Quality: $label"
    log_message "Output folder: $output_dir"
    sleep 1

    if ! yt-dlp "${extra[@]}" -f "$quality" -o "$output_template" "${input_command[@]}" 2>>"$LOG_FILE"; then
        log_message "${RED}Some downloads failed. Check $LOG_FILE${NC}"
    else
        log_message "${GREEN}Download complete.${NC}"
    fi

    ls -lh "$output_dir" | head -5
    [[ $(ls "$output_dir" | wc -l) -gt 5 ]] && log_message "[...] More files"
}

main
