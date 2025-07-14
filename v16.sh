#!/bin/bash

# Bulk Video Downloader Script using yt-dlp
# Version: 0.38
# Author: Ans Raza (0xAnsR), enhanced by Grok
# Description: Downloads videos from YouTube, TikTok, or Facebook with support for playlists,
#              batch files, and private videos using cookies.

# -----------------------------------------------
# Part 1: Configuration and Formatting
# -----------------------------------------------
# ANSI color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Log file for debugging
LOG_FILE="video_downloader.log"

# -----------------------------------------------
# Part 2: Logging Function
# -----------------------------------------------
log_message() {
    local message="$1"
    echo -e "$message" | tee -a "$LOG_FILE"
}

# -----------------------------------------------
# Part 3: Header Display
# -----------------------------------------------
header() {
    clear
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BOLD}       BULK VIDEO DOWNLOADER TOOL ${NC}"
    echo -e "               ${YELLOW}By Ans Raza (0xAnsR)${NC}"
    echo -e "                                ${RED}v0.38${NC}"
    echo -e "${BLUE}=============================================${NC}\n"
}

# -----------------------------------------------
# Part 4: Check/Install yt-dlp
# -----------------------------------------------
check_ytdlp() {
    if ! command -v yt-dlp &>/dev/null; then
        log_message "${RED}yt-dlp is not installed.${NC}"
        read -p "Install yt-dlp now? (y/n): " install_choice
        if [[ "$install_choice" =~ ^[yY]$ ]]; then
            log_message "${YELLOW}Installing yt-dlp...${NC}"
            if sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp; then
                sudo chmod a+rx /usr/local/bin/yt-dlp
                log_message "${GREEN}yt-dlp installed successfully!${NC}"
                sleep 2
            else
                log_message "${RED}Failed to install yt-dlp. Please install manually.${NC}"
                exit 1
            fi
        else
            log_message "${RED}Script requires yt-dlp. Exiting.${NC}"
            exit 1
        fi
    fi
}

# -----------------------------------------------
# Part 5: Detect Platform from URL
# -----------------------------------------------
detect_platform() {
    local url="$1"
    if [[ "$url" =~ (youtube\.com|youtu\.be) ]]; then
        echo "youtube"
    elif [[ "$url" =~ tiktok\.com ]]; then
        echo "tiktok"
    elif [[ "$url" =~ (facebook\.com|fb\.com) ]]; then
        echo "facebook"
    else
        echo "other"
    fi
}

# -----------------------------------------------
# Part 6: Get URL Identifier
# -----------------------------------------------
get_url_identifier() {
    local url="$1"
    local platform="$2"
    local identifier
    case $platform in
        youtube)
            if [[ $url == *"youtube.com/c/"* ]]; then
                identifier=$(echo "$url" | awk -F'youtube.com/c/' '{print $2}' | cut -d'/' -f1)
            elif [[ $url == *"youtube.com/user/"* ]]; then
                identifier=$(echo "$url" | awk -F'youtube.com/user/' '{print $2}' | cut -d'/' -f1)
            elif [[ $url == *"youtube.com/channel/"* ]]; then
                identifier=$(echo "$url" | awk -F'youtube.com/channel/' '{print $2}' | cut -d'/' -f1)
            elif [[ $url == *"youtube.com/watch"* || $url == *"youtu.be"* || $url == *"youtube.com/playlist"* || $url == *"youtube.com/.*tab=shorts"* ]]; then
                identifier="videos"
            else
                identifier="videos"
            fi
            ;;
        tiktok)
            if [[ $url == *"tiktok.com/@"* ]]; then
                identifier=$(echo "$url" | awk -F'tiktok.com/@' '{print $2}' | cut -d'/' -f1)
            else
                identifier="tiktok_videos"
            fi
            ;;
        facebook)
            if [[ $url == *"facebook.com/"* ]]; then
                identifier=$(echo "$url" | awk -F'facebook.com/' '{print $2}' | cut -d'/' -f1)
            else
                identifier="fb_videos"
            fi
            ;;
        *)
            identifier="${url##*/}_$(date +%s)"
            ;;
    esac
    echo "$identifier" | tr -dc '[:alnum:]_-'
}

# -----------------------------------------------
# Part 7: Validate URL
# -----------------------------------------------
validate_url() {
    local url="$1"
    if [[ "$url" =~ ^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/.*)?$ && ! "$url" =~ ^#.*Netscape.*Cookie.*File ]]; then
        return 0
    else
        return 1
    fi
}

# -----------------------------------------------
# Part 8: Setup Cookies for YouTube
# -----------------------------------------------
setup_cookies() {
    header
    log_message "${BOLD}Cookie Setup for YouTube (for private/restricted videos)${NC}\n"
    log_message "Instructions:"
    log_message "1. Log in to YouTube in Chrome/Firefox with the account that has access."
    log_message "2. Install the 'Get cookies.txt LOCALLY' extension:"
    log_message "   [Chrome Web Store](https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc)"
    log_message "3. Export cookies from https://www.youtube.com in Netscape format."
    log_message "4. Provide the path to cookies.txt or paste cookies below."
    log_message "5. Press Enter twice to skip cookies (public videos only).\n"

    read -p "${YELLOW}Enter path to cookies.txt or paste cookies (end with empty line): ${NC}" cookie_input
    cookies_command=""

    if [[ -f "$cookie_input" && -s "$cookie_input" ]]; then
        # Input is a file path
        if grep -q "^# Netscape HTTP Cookie File" "$cookie_input" && grep -q "youtube.com" "$cookie_input"; then
            cp "$cookie_input" cookies.txt
            log_message "${GREEN}Valid cookies.txt provided and copied.${NC}"
            cookies_command="--cookies cookies.txt"
        else
            log_message "${RED}Error: Provided cookies.txt is invalid (missing Netscape header or YouTube cookies). Continuing without cookies.${NC}"
        fi
    elif [[ -n "$cookie_input" ]]; then
        # Input is pasted cookies
        temp_file=$(mktemp)
        echo -e "$cookie_input" > "$temp_file"
        while IFS= read -r line; do
            [[ -z "$line" ]] && break
            echo -e "$line" >> "$temp_file"
        done
        if grep -q "^# Netscape HTTP Cookie File" "$temp_file" && grep -q "youtube.com" "$temp_file"; then
            mv "$temp_file" cookies.txt
            log_message "${GREEN}Cookies successfully saved to cookies.txt${NC}"
            cookies_command="--cookies cookies.txt"
        else
            log_message "${RED}Error: Invalid cookie format (missing Netscape header or YouTube cookies). Continuing without cookies.${NC}"
            rm -f "$temp_file"
        fi
    else
        log_message "${YELLOW}No cookies provided. Continuing without cookies.${NC}"
    fi
    sleep 2
}

# -----------------------------------------------
# Part 9: Test Cookies
# -----------------------------------------------
test_cookies() {
    local video_url="$1"
    if [[ -n "$cookies_command" && -s cookies.txt ]]; then
        log_message "${YELLOW}Testing cookies with a single video...${NC}"
        if yt-dlp $cookies_command --get-title "$video_url" >/dev/null 2>&1; then
            log_message "${GREEN}Cookies are valid!${NC}"
        else
            log_message "${RED}Warning: Cookies may be invalid or insufficient. Downloads may fail.${NC}"
            log_message "Try refreshing cookies:"
            log_message "- Log out and log back into YouTube."
            log_message "- Export fresh cookies from https://www.youtube.com."
            log_message "- Ensure the account has access to the videos."
            sleep 3
        fi
    fi
}

# -----------------------------------------------
# Part 10: Main Download Logic
# -----------------------------------------------
main() {
    header
    check_ytdlp
    echo > "$LOG_FILE" # Initialize log file

    while true; do
        header
        log_message "${BOLD}Select Input Method:${NC}"
        log_message "1) Batch file (videos.txt)"
        log_message "2) Playlist/channel URL"
        log_message "3) Exit"
        read -p "${YELLOW}Select option (1-3): ${NC}" input_choice
        until [[ "$input_choice" =~ ^[1-3]$ ]]; do
            log_message "${RED}Invalid choice. Enter 1, 2, or 3.${NC}"
            read -p "${YELLOW}Select option (1-3): ${NC}" input_choice
        done
        [[ "$input_choice" == "3" ]] && { log_message "${YELLOW}Exiting script.${NC}"; exit 0; }

        cookies_command=""
        if [[ "$input_choice" == "1" ]]; then
            read -p "${YELLOW}Enter full path to videos.txt (URLs only, one per line): ${NC}" batch_file
            until [[ -f "$batch_file" && -s "$batch_file" ]]; do
                log_message "${RED}File not found or empty!${NC}"
                read -p "${YELLOW}Enter full path to videos.txt: ${NC}" batch_file
            done
            valid_urls=$(grep -v '^\s*#' "$batch_file" | grep -v '^\s*$' | while read -r url; do
                if validate_url "$url"; then
                    echo "$url"
                fi
            done)
            if [[ -z "$valid_urls" ]]; then
                log_message "${RED}No valid URLs found in $batch_file!${NC}"
                continue
            fi
            echo "$valid_urls" > "videos.valid.txt"
            input_command="--batch-file videos.valid.txt"
            platform="other"
            if echo "$valid_urls" | grep -qE "(youtube\.com|youtu\.be)"; then
                platform="youtube"
                setup_cookies
            fi
            url_identifier="batch_$(date +%s)"
            output_dir="batch_downloads_$(date +%Y%m%d_%H%M%S)"
        else
            read -p "${YELLOW}Enter playlist/channel URL (e.g., https://youtube.com/...): ${NC}" video_url
            until validate_url "$video_url"; do
                log_message "${RED}Invalid URL! Please provide a valid URL starting with http:// or https://.${NC}"
                read -p "${YELLOW}Enter playlist/channel URL: ${NC}" video_url
            done
            platform=$(detect_platform "$video_url")
            url_identifier=$(get_url_identifier "$video_url" "$platform")
            input_command="$video_url"
            output_dir="${platform}_${url_identifier}_$(date +%Y%m%d_%H%M%S)"
            if [[ "$platform" == "youtube" ]]; then
                setup_cookies
                test_cookies "$video_url"
            fi

            if [[ "$platform" == "youtube" ]]; then
                log_message "${YELLOW}Checking total videos in playlist/channel...${NC}"
                total_videos=$(yt-dlp $cookies_command --get-id --flat-playlist "$video_url" 2>/dev/null | wc -l)
                if [[ $total_videos -eq 0 ]]; then
                    log_message "${RED}No videos found or URL is invalid!${NC}"
                    continue
                fi
                log_message "${GREEN}Found $total_videos videos.${NC}"
                read -p "${YELLOW}Enter video range to download (e.g., 5-20, or press Enter for 1-$total_videos, or 'exit' to change input method): ${NC}" range_input
                if [[ "$range_input" == "exit" ]]; then
                    continue
                elif [[ -z "$range_input" ]]; then
                    log_message "${GREEN}Downloading all videos (1-$total_videos).${NC}"
                    input_command="$input_command --playlist-start 1 --playlist-end $total_videos --yes-playlist"
                elif [[ "$range_input" =~ ^[0-9]+-[0-9]+$ ]]; then
                    start=$(echo "$range_input" | cut -d'-' -f1)
                    end=$(echo "$range_input" | cut -d'-' -f2)
                    if [[ "$start" -ge 1 && "$end" -ge "$start" && "$end" -le "$total_videos" ]]; then
                        input_command="$input_command --playlist-start $start --playlist-end $end --yes-playlist"
                    else
                        log_message "${RED}Invalid range. Start must be >= 1, end >= start, and end <= $total_videos.${NC}"
                        continue
                    fi
                else
                    log_message "${RED}Invalid range format. Use start-end (e.g., 5-20).${NC}"
                    continue
                fi
            fi
        fi

        # Quality selection
        header
        log_message "${BOLD}Video Quality:${NC}"
        local quality_options=("Best quality" "1080p" "720p" "480p" "Audio only (MP3)")
        for i in "${!quality_options[@]}"; do
            log_message "$((i+1))) ${quality_options[i]}"
        done
        read -p "${YELLOW}Select quality (1-5): ${NC}" quality_choice
        until [[ "$quality_choice" =~ ^[1-5]$ ]]; do
            log_message "${RED}Invalid choice. Enter a number between 1 and 5.${NC}"
            read -p "${YELLOW}Select quality (1-5): ${NC}" quality_choice
        done

        case $quality_choice in
            1) quality="b"; quality_label="Best quality";;
            2) quality="bestvideo[height<=1080]+bestaudio/best[height<=1080]"; quality_label="1080p";;
            3) quality="bestvideo[height<=720]+bestaudio/best[height<=720]"; quality_label="720p";;
            4) quality="bestvideo[height<=480]+bestaudio/best[height<=480]"; quality_label="480p";;
            5) quality="bestaudio -x --audio-format mp3"; quality_label="Audio only (MP3)";;
        esac

        # Platform-specific options
        case $platform in
            tiktok) extra_options="--ignore-errors --force-overwrites --referer https://www.tiktok.com/";;
            youtube) extra_options="--ignore-errors --embed-thumbnail --add-metadata $cookies_command";;
            facebook) extra_options="--ignore-errors";;
            *) extra_options="--ignore-errors";;
        esac

        # Output setup
        mkdir -p "$output_dir"
        output_template="$output_dir/%(title)s.%(ext)s"

        # Show summary
        header
        log_message "${GREEN}Download Settings:${NC}"
        log_message " - Platform: $platform"
        log_message " - Source: $url_identifier"
        log_message " - Quality: $quality_label"
        log_message " - Cookies: ${cookies_command:+Enabled}${cookies_command:-Disabled}"
        log_message " - Output: $output_dir"
        [[ -n "$start" ]] && log_message " - Video Range: $start-$end"
        echo
        sleep 2

        # Download execution
        log_message "${YELLOW}Starting download...${NC}"
        if ! yt-dlp $extra_options -f "$quality" -o "$output_template" $input_command 2>> "$LOG_FILE"; then
            log_message "${RED}Some downloads failed. Check $LOG_FILE for details.${NC}"
            if [[ -n "$cookies_command" ]]; then
                log_message "${RED}Possible authentication errors. Try refreshing cookies:${NC}"
                log_message "- Log out and log back into YouTube."
                log_message "- Export fresh cookies from https://www.youtube.com."
                log_message "- See https://github.com/yt-dlp/yt-dlp/wiki/FAQ#how-do-i-pass-cookies-to-yt-dlp"
            fi
        else
            log_message "${GREEN}Download completed successfully!${NC}"
        fi
        # Clean up
        [[ -f "videos.valid.txt" ]] && rm "videos.valid.txt"
        ls -lh "$output_dir" | head -5 | tee -a "$LOG_FILE"
        [[ $(ls "$output_dir" | wc -l) -gt 5 ]] && log_message "[...] More files..."
        break
    done
}

# -----------------------------------------------
# Part 11: Run Script
# -----------------------------------------------
main