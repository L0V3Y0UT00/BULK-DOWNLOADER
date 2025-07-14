#!/bin/bash

# Bulk Video Downloader Script using yt-dlp (Cookies for YouTube, Auto-Detect Platform, URL Validation)
# Version: 0.37
# Author: Ans Raza (0xAnsR), modified by Grok

# -----------------------------------------------
# Part 1: Color and Formatting Definitions
# -----------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# -----------------------------------------------
# Part 2: Header Display
# -----------------------------------------------
header() {
    clear
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BOLD}       BULK VIDEO DOWNLOADER TOOL ${NC}"
    echo -e "               ${YELLOW}By Ans Raza (0xAnsR)${NC}"
    echo -e "                                ${RED}v0.37${NC}"
    echo -e "${BLUE}=============================================${NC}\n"
}

# -----------------------------------------------
# Part 3: Check/Install yt-dlp
# -----------------------------------------------
check_ytdlp() {
    if ! command -v yt-dlp &>/dev/null; then
        echo -e "${RED}yt-dlp is not installed.${NC}"
        read -p "Install yt-dlp now? (y/n): " install_choice
        if [[ "$install_choice" == "y" ]]; then
            echo -e "${YELLOW}Installing yt-dlp...${NC}"
            sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
            sudo chmod a+rx /usr/local/bin/yt-dlp
            echo -e "${GREEN}yt-dlp installed successfully!${NC}"
            sleep 2
        else
            echo -e "${RED}Script requires yt-dlp. Exiting.${NC}"
            exit 1
        fi
    fi
}

# -----------------------------------------------
# Part 4: Detect Platform from URL
# -----------------------------------------------
detect_platform() {
    local url=$1
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
# Part 5: Get URL Identifier
# -----------------------------------------------
get_url_identifier() {
    local url=$1
    local platform=$2
    case $platform in
        youtube)
            if [[ $url == *"youtube.com/c/"* ]]; then
                echo "$url" | awk -F'youtube.com/c/' '{print $2}' | cut -d'/' -f1
            elif [[ $url == *"youtube.com/user/"* ]]; then
                echo "$url" | awk -F'youtube.com/user/' '{print $2}' | cut -d'/' -f1
            elif [[ $url == *"youtube.com/channel/"* ]]; then
                echo "$url" | awk -F'youtube.com/channel/' '{print $2}' | cut -d'/' -f1
            elif [[ $url == *"youtube.com/watch"* || $url == *"youtu.be"* || $url == *"youtube.com/playlist"* || $url == *"youtube.com/.*tab=shorts"* ]]; then
                echo "videos"
            else
                echo "videos"
            fi
            ;;
        tiktok)
            if [[ $url == *"tiktok.com/@"* ]]; then
                echo "$url" | awk -F'tiktok.com/@' '{print $2}' | cut -d'/' -f1
            else
                echo "tiktok_videos"
            fi
            ;;
        facebook)
            if [[ $url == *"facebook.com/"* ]]; then
                echo "$url" | awk -F'facebook.com/' '{print $2}' | cut -d'/' -f1
            else
                echo "fb_videos"
            fi
            ;;
        *)
            echo "${url##*/}_$(date +%s)"
            ;;
    esac | tr -dc '[:alnum:]_-'
}

# -----------------------------------------------
# Part 6: Validate URL
# -----------------------------------------------
validate_url() {
    local url=$1
    if [[ "$url" =~ ^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/.*)?$ && ! "$url" =~ ^#.*Netscape.*Cookie.*File ]]; then
        return 0
    else
        return 1
    fi
}

# -----------------------------------------------
# Part 7: Setup Cookies for YouTube
# -----------------------------------------------
setup_cookies() {
    header
    echo -e "${BOLD}Cookie Setup for YouTube (for private/restricted videos)${NC}\n"
    echo -e "Steps to get cookies:"
    echo -e "1. Log in to YouTube in Chrome/Firefox with the account that has access to the videos."
    echo -e "2. Install the '${BLUE}Get cookies.txt LOCALLY${NC}' extension:"
    echo -e "   [Chrome Web Store](https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc)"
    echo -e "3. Export cookies from YouTube (https://www.youtube.com) and paste below (Netscape format)."
    echo -e "4. Ensure cookies are fresh (exported recently) to avoid authentication errors."
    echo -e "5. Press Enter twice to skip cookies and download public videos only.\n"
    
    # Check if cookies.txt exists and is valid
    if [[ -s cookies.txt ]] && grep -q "^# Netscape HTTP Cookie File" cookies.txt && grep -q "youtube.com" cookies.txt; then
        echo -e "${GREEN}Found existing cookies.txt with YouTube cookies.${NC}"
        echo -e "Options:"
        echo -e "1) Use existing cookies.txt"
        echo -e "2) Update cookies (paste new cookies)"
        echo -e "3) Skip cookies (download public videos only)"
        read -p "${YELLOW}Select option (1-3): ${NC}" cookie_choice
        until [[ "$cookie_choice" =~ ^[1-3]$ ]]; do
            echo -e "${RED}Invalid choice. Enter 1, 2, or 3.${NC}"
            read -p "${YELLOW}Select option (1-3): ${NC}" cookie_choice
        done
        case $cookie_choice in
            1)
                echo -e "${GREEN}Using existing cookies.txt${NC}"
                cookies_command="--cookies cookies.txt"
                return
                ;;
            2)
                echo -e "${YELLOW}Paste new cookies below (end with empty line):${NC}"
                ;;
            3)
                echo -e "${YELLOW}Skipping cookies. Continuing without cookies.${NC}"
                cookies_command=""
                return
                ;;
        esac
    else
        echo -e "${YELLOW}No valid cookies.txt found. Paste cookies below (end with empty line):${NC}"
    fi

    # Capture cookies with read loop
    cookies=""
    while IFS= read -r line; do
        [[ -z "$line" ]] && break
        cookies+="$line\n"
    done
    if [[ -n "$cookies" ]]; then
        # Save cookies to a temporary file first
        temp_file=$(mktemp)
        echo -e "$cookies" > "$temp_file"
        # Verify cookie format
        if grep -q "^# Netscape HTTP Cookie File" "$temp_file" && grep -q "youtube.com" "$temp_file"; then
            mv "$temp_file" cookies.txt
            if [[ -s cookies.txt ]]; then
                echo -e "${GREEN}Cookies successfully saved to cookies.txt${NC}"
                cookies_command="--cookies cookies.txt"
            else
                echo -e "${RED}Error: Failed to save cookies.txt (file is empty). Continuing without cookies.${NC}"
                cookies_command=""
                rm -f "$temp_file"
            fi
        else
            echo -e "${RED}Error: Invalid cookie format (missing Netscape header or YouTube cookies). Continuing without cookies.${NC}"
            cookies_command=""
            rm -f "$temp_file"
        fi
    else
        echo -e "${YELLOW}No cookies provided. Continuing without cookies.${NC}"
        cookies_command=""
    fi
    sleep 2
}

# -----------------------------------------------
# Part 8: Test Cookies (Optional)
# -----------------------------------------------
test_cookies() {
    local video_url=$1
    if [[ -n "$cookies_command" && -s cookies.txt ]]; then
        echo -e "${YELLOW}Testing cookies with a single video...${NC}"
        if grep -q "^# Netscape HTTP Cookie File" cookies.txt && grep -q "youtube.com" cookies.txt; then
            if yt-dlp $cookies_command --get-title "$video_url" >/dev/null 2>&1; then
                echo -e "${GREEN}Cookies appear valid! Proceeding with download.${NC}"
            else
                echo -e "${RED}Warning: Cookies may be invalid or insufficient. You may encounter authentication errors.${NC}"
                echo -e "Try refreshing cookies:"
                echo -e "- Log out and log back into YouTube."
                echo -e "- Export fresh cookies from https://www.youtube.com using the 'Get cookies.txt LOCALLY' extension."
                echo -e "- Ensure the account has access to the videos (e.g., not age-restricted or private)."
                echo -e "Continuing with current cookies, but downloads may fail."
                sleep 3
            fi
        else
            echo -e "${RED}Error: cookies.txt is invalid (missing Netscape header or YouTube cookies). Continuing without cookies.${NC}"
            cookies_command=""
        fi
    else
        echo -e "${RED}Error: cookies.txt not found or empty. Continuing without cookies.${NC}"
        cookies_command=""
    fi
}

# -----------------------------------------------
# Part 9: Main Download Logic
# -----------------------------------------------
main() {
    header
    check_ytdlp

    while true; do
        # Input method selection
        header
        echo -e "${BOLD}Select Input Method:${NC}"
        echo -e "1) Batch file (videos.txt)"
        echo -e "2) Playlist/channel URL"
        echo -e "3) Exit"
        read -p "${YELLOW}Select option (1-3): ${NC}" input_choice
        until [[ "$input_choice" =~ ^[1-3]$ ]]; do
            echo -e "${RED}Invalid choice. Enter 1, 2, or 3.${NC}"
            read -p "${YELLOW}Select option (1-3): ${NC}" input_choice
        done
        [[ "$input_choice" == "3" ]] && exit 0

        cookies_command=""
        # URL or batch file input
        if [[ "$input_choice" == "1" ]]; then
            read -p "Enter full path to videos.txt (URLs only, one per line, e.g., https://...): " batch_file
            until [[ -f "$batch_file" && -s "$batch_file" ]]; do
                echo -e "${RED}File not found or empty!${NC}"
                read -p "Enter full path to videos.txt (URLs only, one per line, e.g., https://...): " batch_file
            done
            # Validate batch file contents
            valid_urls=$(grep -v '^\s*#' "$batch_file" | grep -v '^\s*$' | while read -r url; do
                if validate_url "$url"; then
                    echo "$url"
                fi
            done)
            if [[ -z "$valid_urls" ]]; then
                echo -e "${RED}No valid URLs found in $batch_file! Please provide valid URLs (e.g., https://...).${NC}"
                continue
            fi
            echo "$valid_urls" > "$batch_file.valid"
            input_command="--batch-file $batch_file.valid"
            platform="other"
            # Check if any URL is YouTube
            if echo "$valid_urls" | grep -qE "(youtube\.com|youtu\.be)"; then
                platform="youtube"
                setup_cookies
            fi
            url_identifier="batch"
            output_dir="batch_downloads"
        else
            read -p "Enter playlist/channel URL (e.g., https://youtube.com/..., not cookies): " video_url
            until validate_url "$video_url"; do
                if [[ "$video_url" =~ ^#.*Netscape.*Cookie.*File ]]; then
                    echo -e "${RED}Error: You pasted cookie text! Please enter a valid video/playlist/channel URL (e.g., https://youtube.com/...).${NC}"
                else
                    echo -e "${RED}Invalid URL! Please provide a valid URL starting with http:// or https://.${NC}"
                fi
                read -p "Enter playlist/channel URL (e.g., https://youtube.com/..., not cookies): " video_url
            done
            platform=$(detect_platform "$video_url")
            url_identifier=$(get_url_identifier "$video_url" "$platform")
            input_command="$video_url"
            output_dir="${platform}_${url_identifier}_downloads"
            # Prompt for cookies only if YouTube
            if [[ "$platform" == "youtube" ]]; then
                setup_cookies
                test_cookies "$video_url"
            fi

            # Playlist range selection for YouTube
            if [[ "$platform" == "youtube" ]]; then
                attempts=0
                max_attempts=3
                while [[ $attempts -lt $max_attempts ]]; do
                    echo -e "${YELLOW}Checking total videos in playlist/channel...${NC}"
                    total_videos=$(yt-dlp $cookies_command --get-id --flat-playlist "$video_url" 2>/dev/null | wc -l)
                    if [[ $total_videos -eq 0 ]]; then
                        echo -e "${RED}No videos found or URL is invalid!${NC}"
                        read -p "Enter playlist/channel URL (e.g., https://youtube.com/..., not cookies): " video_url
                        until validate_url "$video_url"; do
                            if [[ "$video_url" =~ ^#.*Netscape.*Cookie.*File ]]; then
                                echo -e "${RED}Error: You pasted cookie text! Please enter a valid video/playlist/channel URL (e.g., https://youtube.com/...).${NC}"
                            else
                                echo -e "${RED}Invalid URL! Please provide a valid URL starting with http:// or https://.${NC}"
                            fi
                            read -p "Enter playlist/channel URL (e.g., https://youtube.com/..., not cookies): " video_url
                        done
                        platform=$(detect_platform "$video_url")
                        url_identifier=$(get_url_identifier "$video_url" "$platform")
                        input_command="$video_url"
                        output_dir="${platform}_${url_identifier}_downloads"
                        if [[ "$platform" == "youtube" ]]; then
                            setup_cookies
                            test_cookies "$video_url"
                        fi
                        continue
                    fi
                    echo -e "${GREEN}Found $total_videos videos.${NC}"
                    # Clear input buffer before reading
                    while read -r -t 0.1; do :; done
                    read -p "${YELLOW}Enter video range to download (e.g., 5-20, or press Enter for 1-$total_videos, or 'exit' to change input method): ${NC}" range_input
                    if [[ -z "$range_input" ]]; then
                        echo -e "${GREEN}No range provided. Defaulting to all videos (1-$total_videos).${NC}"
                        input_command="$input_command --playlist-start 1 --playlist-end $total_videos --yes-playlist"
                        break
                    fi
                    if [[ "$range_input" == "exit" ]]; then
                        break
                    fi
                    if [[ ! "$range_input" =~ ^[0-9]+-[0-9]+$ ]]; then
                        echo -e "${RED}Invalid range format. Use start-end (e.g., 5-20), press Enter for all, or type 'exit'.${NC}"
                        ((attempts++))
                        if [[ $attempts -ge $max_attempts ]]; then
                            echo -e "${RED}Too many invalid attempts! Returning to input method selection.${NC}"
                            break
                        fi
                        continue
                    fi
                    start=$(echo "$range_input" | cut -d'-' -f1)
                    end=$(echo "$range_input" | cut -d'-' -f2)
                    if [[ "$start" -ge 1 && "$end" -ge "$start" && "$end" -le "$total_videos" ]]; then
                        input_command="$input_command --playlist-start $start --playlist-end $end --yes-playlist"
                        break
                    else
                        echo -e "${RED}Invalid range. Start must be >= 1, end >= start, and end <= $total_videos.${NC}"
                        ((attempts++))
                        if [[ $attempts -ge $max_attempts ]]; then
                            echo -e "${RED}Too many invalid attempts! Returning to input method selection.${NC}"
                            break
                        fi
                    fi
                done
                [[ $attempts -ge $max_attempts || "$range_input" == "exit" ]] && continue
            fi
        fi

        # Quality selection
        header
        echo -e "${BOLD}Video Quality:${NC}"
        local quality_options=("Best quality" "1080p" "720p" "480p" "Audio only (MP3)")
        for i in "${!quality_options[@]}"; do
            echo -e "$((i+1))) ${quality_options[i]}"
        done
        read -p "${YELLOW}Select quality (1-5): ${NC}" quality_choice
        until [[ "$quality_choice" =~ ^[1-5]$ ]]; do
            echo -e "${RED}Invalid choice. Enter a number between 1 and 5.${NC}"
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
        echo -e "${GREEN}Download Settings:${NC}"
        echo -e " - Platform: ${platform}"
        echo -e " - Source: ${url_identifier}"
        echo -e " - Quality: ${quality_label}"
        echo -e " - Cookies: ${cookies_command:+Enabled}${cookies_command:-Disabled}"
        echo -e " - Output: ${output_dir}"
        [[ "$input_choice" == "2" && "$platform" == "youtube" && -n "$start" ]] && echo -e " - Video Range: $start-$end"
        echo
        sleep 2

        # Download execution
        echo -e "${YELLOW}Downloading videos...${NC}"
        if ! yt-dlp $extra_options -f "$quality" -o "$output_template" $input_command; then
            echo -e "${RED}Some downloads failed. Check output for details.${NC}"
            if [[ -n "$cookies_command" ]]; then
                echo -e "${RED}Authentication errors detected. Try refreshing cookies:${NC}"
                echo -e "- Log out and log back into YouTube."
                echo -e "- Export fresh cookies from https://www.youtube.com using the 'Get cookies.txt LOCALLY' extension."
                echo -e "- Ensure the account has access to the videos (e.g., not age-restricted or private)."
                echo -e "See https://github.com/yt-dlp/yt-dlp/wiki/FAQ#how-do-i-pass-cookies-to-yt-dlp for details."
            fi
        else
            echo -e "${GREEN}Download completed!${NC}"
        fi
        # Clean up temporary batch file
        [[ -f "$batch_file.valid" ]] && rm "$batch_file.valid"
        ls -lh "$output_dir" | head -5
        [[ $(ls "$output_dir" | wc -l) -gt 5 ]] && echo "[...] More files..."
        break
    done
}

# -----------------------------------------------
# Part 10: Run Script
# -----------------------------------------------
main