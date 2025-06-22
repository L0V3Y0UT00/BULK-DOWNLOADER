#!/bin/bash

# Bulk Video Downloader Script using yt-dlp with cookie support and real-time editing
# Version: 0.16
# Author: Ans Raza (0xAnsR)

# Part 1: Color and Formatting Definitions
# -----------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Part 2: Header Function
# -----------------------------------------------
header() {
    clear
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BOLD}       BULK VIDEO DOWNLOADER TOOL ${NC}"
    echo -e "               ${YELLOW}BY Ans Raza (0xAnsR)${NC}"
    echo -e "                                ${RED}v:0.16${NC}"
    echo -e "${BLUE}=============================================${NC}\n"
    echo -e "${BOLD}Script Parts:${NC}"
    echo -e "1) Color and Formatting Definitions"
    echo -e "2) Header Function"
    echo -e "3) Check/Install yt-dlp Function"
    echo -e "4) Check/Install ffmpeg Function"
    echo -e "5) Setup Cookies Function"
    echo -e "6) Extract URL Identifier Function"
    echo -e "7) Configure Video Editing Function"
    echo -e "8) Display Download Summary Function"
    echo -e "9) Main Download and Edit Logic"
    echo -e "10) Run Script\n"
}

# Part 3: Check/Install yt-dlp Function
# -----------------------------------------------
check_ytdlp() {
    if ! command -v yt-dlp &> /dev/null; then
        echo -e "${RED}[ERROR] yt-dlp is not installed.${NC}"
        read -p "Install yt-dlp now? (y/n): " install_choice
        if [[ "$install_choice" == "y" ]]; then
            echo -e "${YELLOW}[+] Installing yt-dlp...${NC}"
            sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
            sudo chmod a+rx /usr/local/bin/yt-dlp
            echo -e "${GREEN}[✔] yt-dlp installed successfully!${NC}"
            sleep 2
        else
            echo -e "${RED}[✗] Script requires yt-dlp. Exiting.${NC}"
            exit 1
        fi
    fi
}

# Part 4: Check/Install ffmpeg Function
# -----------------------------------------------
check_ffmpeg() {
    if ! command -v ffmpeg &> /dev/null; then
        echo -e "${RED}[ERROR] ffmpeg is not installed.${NC}"
        read -p "Install ffmpeg now? (y/n): " install_choice
        if [[ "$install_choice" == "y" ]]; then
            echo -e "${YELLOW}[+] Installing ffmpeg...${NC}"
            if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                sudo apt-get update && sudo apt-get install -y ffmpeg
            elif [[ "$OSTYPE" == "darwin"* ]]; then
                brew install ffmpeg
            else
                echo -e "${RED}[✗] Unsupported OS for auto-install. Please install ffmpeg manually.${NC}"
                exit 1
            fi
            echo -e "${GREEN}[✔] ffmpeg installed successfully!${NC}"
            sleep 2
        else
            echo -e "${RED}[✗] Video editing requires ffmpeg. Continuing without editing.${NC}"
            return 1
        fi
    fi
    return 0
}

# Part 5: Setup Cookies Function
# -----------------------------------------------
setup_cookies() {
    header
    echo -e "${BOLD}COOKIE SETUP (for private/age-restricted videos)${NC}\n"
    
    if [[ -f "cookies.txt" ]]; then
        echo -e "${GREEN}[+] cookies.txt found in current folder:${NC}"
        echo -e "  Size: $(du -h cookies.txt | cut -f1)"
        echo -e "  Last modified: $(date -r cookies.txt)\n"
        cookies_command="--cookies cookies.txt"
        echo -e "${GREEN}[✔] Automatically using cookies.txt${NC}"
        sleep 1
        return
    fi
    
    echo -e "Steps to get cookies:"
    echo -e "1. Login to the target site in Firefox/Chrome"
    echo -e "2. Install the '${BLUE}Get cookies.txt${NC}' browser extension"
    echo -e "3. Export cookies as '${GREEN}cookies.txt${NC}' in this folder\n"
    
    read -p "Enable cookies for this download? (y/n): " need_cookies
    
    if [[ "$need_cookies" == "y" ]]; then
        echo -e "\n${BOLD}Cookie Setup Methods:${NC}"
        echo -e "1) Manually provide cookies.txt path"
        echo -e "2) Open Firefox to login and export (requires Firefox)"
        echo -e "3) Skip cookie setup"
        read -p "Choice (1-3): " cookie_method
        
        case $cookie_method in
            1)
                read -p "Enter full path to cookies.txt: " cookie_path
                if [[ -f "$cookie_path" ]]; then
                    cp "$cookie_path" ./cookies.txt
                    cookies_command="--cookies cookies.txt"
                    echo -e "${GREEN}[✔] Cookies file configured!${NC}"
                else
                    echo -e "${RED}[✗] File not found! Continuing without cookies.${NC}"
                    cookies_command=""
                fi
                ;;
            2)
                if command -v firefox &> /dev/null; then
                    echo -e "${YELLOW}[!] Opening Firefox... Login and export cookies.${NC}"
                    firefox about:blank &
                    read -p "Press Enter after exporting cookies.txt..."
                    
                    if [[ -f "cookies.txt" ]]; then
                        cookies_command="--cookies cookies.txt"
                        echo -e "${GREEN}[✔] Cookies file detected!${NC}"
                    else
                        echo -e "${RED}[✗] No cookies.txt found in current folder.${NC}"
                        cookies_command=""
                    fi
                else
                    echo -e "${RED}[✗] Firefox not installed! Manual cookie setup required.${NC}"
                    cookies_command=""
                fi
                ;;
            *) cookies_command="";;
        esac
    fi
    sleep 1
}

# Part 6: Extract URL Identifier Function
# -----------------------------------------------
get_url_identifier() {
    local url=$1
    local platform=$2
    
    case $platform in
        youtube)
            if [[ $url == *"youtube.com/c/"* ]]; then
                identifier=$(echo "$url" | awk -F'youtube.com/c/' '{print $2}' | cut -d'/' -f1)
            elif [[ $url == *"youtube.com/user/"* ]]; then
                identifier=$(echo "$url" | awk -F'youtube.com/user/' '{print $2}' | cut -d'/' -f1)
            elif [[ $url == *"youtube.com/channel/"* ]]; then
                identifier=$(echo "$url" | awk -F'youtube.com/channel/' '{print $2}' | cut -d'/' -f1)
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
            domain=$(echo "$url" | awk -F'://' '{print $2}' | awk -F'/' '{print $1}' | sed 's/www\.//')
            identifier="${domain}_$(date +%s)"
            ;;
    esac
    
    echo "$identifier" | tr -cd '[:alnum:].-_'
}

# Part 7: Configure Video Editing Function
# -----------------------------------------------
configure_editing() {
    header >/dev/null 2>&1 # Suppress header output to avoid ANSI codes
    echo -e "${BOLD}Video Editing Options:${NC}"
    local options=(
        "No editing (download only)"
        "Trim video (specify start and duration)"
        "Resize video (e.g., 720p)"
        "Convert format (e.g., to MP4)"
        "Flip video (horizontal, vertical, or both)"
    )
    
    while true; do
        for i in "${!options[@]}"; do
            echo -e "$((i+1))) ${options[i]}"
        done
        read -p "${YELLOW}Enter choice (1-5): ${NC}" edit_choice
        if [[ "$edit_choice" =~ ^[1-5]$ ]]; then
            header >/dev/null 2>&1
            echo -e "${BOLD}Video Editing Options:${NC}"
            for i in "${!options[@]}"; do
                if [[ $((i+1)) -eq $edit_choice ]]; then
                    echo -e "$((i+1))) ${GREEN}${options[i]}${NC}"
                else
                    echo -e "$((i+1))) ${RED}${options[i]}${NC}"
                fi
            done
            echo -e "\n${GREEN}[✔] Selected: ${options[$((edit_choice-1))]}${NC}"
            sleep 1
            break
        else
            echo -e "${RED}[✗] Invalid choice. Please enter a number between 1 and 5.${NC}"
            sleep 1
            header >/dev/null 2>&1
            echo -e "${BOLD}Video Editing Options:${NC}"
        fi
    done
    
    edit_command=""
    edit_suffix=""
    
    case $edit_choice in
        2)
            read -p "Enter start time (e.g., 00:00:10): " trim_start
            read -p "Enter duration (e.g., 00:00:30): " trim_duration
            edit_command="-ss $trim_start -t $trim_duration -c:v copy -c:a copy"
            edit_suffix="_trimmed"
            ;;
        3)
            read -p "Enter resolution (e.g., 1280x720): " resolution
            edit_command="-vf scale=$resolution -c:a copy"
            edit_suffix="_resized"
            ;;
        4)
            read -p "Enter output format (e.g., mp4, avi): " format
            edit_command="-c:v libx264 -c:a aac"
            edit_suffix="_converted.$format"
            ;;
        5)
            header >/dev/null 2>&1
            echo -e "${BOLD}Flip Options:${NC}"
            local flip_options=(
                "Horizontal flip"
                "Vertical flip"
                "Both (horizontal and vertical)"
            )
            while true; do
                for i in "${!flip_options[@]}"; do
                    echo -e "$((i+1))) ${flip_options[i]}"
                done
                read -p "${YELLOW}Enter flip choice (1-3): ${NC}" flip_choice
                if [[ "$flip_choice" =~ ^[1-3]$ ]]; then
                    header >/dev/null 2>&1
                    echo -e "${BOLD}Flip Options:${NC}"
                    for i in "${!flip_options[@]}"; do
                        if [[ $((i+1)) -eq $flip_choice ]]; then
                            echo -e "$((i+1))) ${GREEN}${flip_options[i]}${NC}"
                        else
                            echo -e "$((i+1))) ${RED}${flip_options[i]}${NC}"
                        fi
                    done
                    echo -e "\n${GREEN}[✔] Selected: ${flip_options[$((flip_choice-1))]}${NC}"
                    sleep 1
                    break
                else
                    echo -e "${RED}[✗] Invalid choice. Please enter a number between 1 and 3.${NC}"
                    sleep 1
                    header >/dev/null 2>&1
                    echo -e "${BOLD}Flip Options:${NC}"
                fi
            done
            case $flip_choice in
                1)
                    edit_command="-vf hflip -c:a copy"
                    edit_suffix="_hflipped"
                    ;;
                2)
                    edit_command="-vf vflip -c:a copy"
                    edit_suffix="_vflipped"
                    ;;
                3)
                    edit_command="-vf hflip,vflip -c:a copy"
                    edit_suffix="_flipped"
                    ;;
            esac
            ;;
        *) 
            edit_command=""
            edit_suffix=""
            ;;
    esac
    
    echo "$edit_command|$edit_suffix"
}

# Part 8: Display Download Summary Function
# -----------------------------------------------
show_summary() {
    local platform=$1
    local url_identifier=$2
    local quality_label=$3
    local output_dir=$4
    local edit_choice=$5
    
    header
    echo -e "${GREEN}[+] Starting download with settings:${NC}"
    echo -e "  Platform: ${BOLD}$platform${NC}"
    [[ -n "$url_identifier" ]] && echo -e "  Source: ${YELLOW}$url_identifier${NC}"
    echo -e "  Quality: ${BOLD}$quality_label${NC}"
    [[ -n "$cookies_command" ]] && echo -e "  Cookies: ${GREEN}Enabled${NC}" || echo -e "  Cookies: ${RED}Disabled${NC}"
    if [[ -n "$edit_choice" && "$edit_choice" != "1" ]]; then
        case $edit_choice in
            2) echo -e "  Editing: ${YELLOW}Trimming${NC}";;
            3) echo -e "  Editing: ${YELLOW}Resizing${NC}";;
            4) echo -e "  Editing: ${YELLOW}Converting${NC}";;
            5) echo -e "  Editing: ${YELLOW}Flipping${NC}";;
        esac
    else
        echo -e "  Editing: ${RED}Disabled${NC}"
    fi
    echo -e "  Output: ${BLUE}$output_dir${NC}\n"
}

# Part 9: Main Download and Edit Logic
# -----------------------------------------------
main() {
    header
    check_ytdlp
    check_ffmpeg
    has_ffmpeg=$?
    
    # Platform selection
    echo -e "${BOLD}Select Platform:${NC}"
    local platform_options=(
        "Facebook"
        "YouTube"
        "TikTok"
        "Other (direct URL)"
    )
    while true; do
        echo -e "1) ${BLUE}${platform_options[0]}${NC}"
        echo -e "2) ${RED}${platform_options[1]}${NC}"
        echo -e "3) ${YELLOW}${platform_options[2]}${NC}"
        echo -e "4) ${platform_options[3]}"
        read -p "${YELLOW}Enter choice (1-4): ${NC}" platform_choice
        if [[ "$platform_choice" =~ ^[1-4]$ ]]; then
            header
            echo -e "${BOLD}Select Platform:${NC}"
            for i in "${!platform_options[@]}"; do
                if [[ $((i+1)) -eq $platform_choice ]]; then
                    echo -e "$((i+1))) ${GREEN}${platform_options[i]}${NC}"
                else
                    echo -e "$((i+1))) ${RED}${platform_options[i]}${NC}"
                fi
            done
            echo -e "\n${GREEN}[✔] Selected: ${platform_options[$((platform_choice-1))]}${NC}"
            sleep 1
            break
        else
            echo -e "${RED}[✗] Invalid choice. Please enter a number between 1 and 4.${NC}"
            sleep 1
            header
            echo -e "${BOLD}Select Platform:${NC}"
        fi
    done
    
    case $platform_choice in
        1) platform="facebook"; profile_type="post/page";;
        2) platform="youtube"; profile_type="video/channel";;
        3) platform="tiktok"; profile_type="video/user";;
        4) platform="other"; profile_type="";;
    esac
    
    # Cookie setup for platforms that often require it
    if [[ "$platform" =~ ^(facebook|tiktok|other)$ ]]; then
        setup_cookies
        [[ "$platform" == "tiktok" ]] && cookies_command+=" --referer https://www.tiktok.com/"
    else
        cookies_command=""
    fi
    
    # URL input
    if [[ "$platform" == "other" ]]; then
        read -p "Enter full URL: " video_url
    else
        read -p "Enter $profile_type URL: " video_url
    fi
    
    # Get identifier for folder naming
    url_identifier=$(get_url_identifier "$video_url" "$platform")
    
    # Download scope
    header
    echo -e "${BOLD}Download Scope:${NC}"
    local scope_options=(
        "Single video"
        "All videos from page/channel/user"
    )
    while true; do
        for i in "${!scope_options[@]}"; do
            echo -e "$((i+1))) ${scope_options[i]}"
        done
        read -p "${YELLOW}Enter choice (1-2): ${NC}" scope_choice
        if [[ "$scope_choice" =~ ^[1-2]$ ]]; then
            header
            echo "${BOLD}Download Scope:${NC}"
            for i in "${!scope_options[@]}"; do
                if [[ $((i+1)) -eq $scope_choice ]]; then
                    echo -e "$((i+1))) ${GREEN}${scope_options[i]}${NC}"
                else
                    echo -e "$((i+1))) ${RED}${scope_options[i]}${NC}"
                fi
            done
            echo -e \n${GREEN}[✔] Selected: ${scope_options[$((scope_choice-1))]}${NC}"
            sleep 1
            break
        else
            echo -e "${RED}[✗] Invalid choice. Please enter a number between 1 and 2."
            sleep 1
            header
            echo -e "${BOLD}Download Scope:${NC}"
        fi
    done
    
    # Quality selection
    header
    echo -e "${BOLD}Video Quality:${NC}"
    local quality_options=(
        "Best quality (default)"
        "1080p"
        "720p"
        "480p"
        "Audio only (MP3)"
    )
    while true; do
        for i in "${!quality_options[@]}"; do
            echo -e "$((i+1))) ${quality_options[i]}"
        done
        read -p "${YELLOW}Enter choice (1-5): ${NC}" quality_choice
        if [[ "$quality_choice" =~ ^[1-5]$ ]]; then
            header
            echo -e "${BOLD}Video Quality:${NC}"
            for i in "${!quality_options[@]}"; do
                if [[ $((i+1)) -eq $quality_choice ]]; then
                    echo -e "$((i+1))) ${GREEN}${quality_options[i]}${NC}"
                else
                    echo -e "$((i+1))) ${RED}${quality_options[i]}${NC}"
                fi
            done
            echo -e "\n${GREEN}[✔] Selected: ${quality_options[$((quality_choice-1))]}${NC}"
            sleep 1
            break
        else
            echo -e "${RED}[✗] Invalid choice. Please enter a number between 1 and 5.${NC}"
            sleep 1
            header
            echo -e "${BOLD}Video Quality:${NC}"
        fi
    done
    
    case $quality_choice in
        1) quality="best"; quality_label="Best quality (default)";;
        2) quality="bestvideo[height<=1080][ext=mp4]+bestaudio[ext=m4a]/best[height<=1080]"; quality_label="1080p";;
        3) quality="bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720]"; quality_label="720p";;
        4) quality="bestvideo[height<=480][ext=mp4]+bestaudio[ext=m4a]/best[height<=480]"; quality_label="480p";;
        5) quality="bestaudio -x --audio-format mp3"; quality_label="Audio only (MP3)";;
    esac
    
    # Editing options (only for single video and if ffmpeg is installed)
    edit_command=""
    edit_suffix=""
    if [[ "$scope_choice" == "1" && $has_ffmpeg -eq 0 ]]; then
        IFS='|' read -r edit_command edit_suffix <<< "$(configure_editing)"
    elif [[ "$scope_choice" == "2" && $has_ffmpeg -eq 0 ]]; then
        echo -e "${YELLOW}[!] Editing is only supported for single video downloads${NC}"
        sleep 1
    fi
    
    # Output folder naming logic
    if [[ "$scope_choice" == "2" ]]; then
        output_dir="${platform}_${url_identifier}_downloads"
    else
        output_dir="${platform}_single_videos"
    fi
    
    mkdir -p "$output_dir"
    if [[ "$scope_choice" == "2" ]]; then
        output_template="$output_dir/%(upload_date)s_%(title)s.%(ext)s"
    else
        output_template="$output_dir/${url_identifier}_%(title)s.%(ext)s"
        edit_output_template="$output_dir/${url_identifier}_%(title)s${edit_suffix}.%(ext)s"
    fi
    
    # Platform-specific options
    case $platform in
        tiktok) 
            extra_options="--force-overwrites --write-description --write-thumbnail --no-check-certificate"
            ;;
        youtube) 
            extra_options="--embed-thumbnail --add-metadata --write-description --write-info-json --write-thumbnail"
            ;;
        *) 
            extra_options=""
            ;;
    esac
    
    # Show summary before downloading
    show_summary "$platform" "$url_identifier" "$quality_label" "$output_dir" "$edit_choice"
    
    # Add slight delay
    sleep 2
    
    # Download execution
    if [[ "$scope_choice" == "1" && -n "$edit_command" && $has_ffmpeg -eq 0 ]]; then
        # Single video with editing
        # Single video
 without editing
        echo -e "${YELLOW}[+] Downloading video...${YNC}"
        echo -e "${YELLOW}[+] Downloading single video..."
        if ! yt-dlp $cookies_command $extra_options -f "$quality" -o "$output_template" "$video_url"; then
            echo -e "${RED}[✗] Failed to download failed. Exiting...${NC}"
            exit 1
        fi
        echo -e "${YELLOW}[+] Editing video...${NC}"
        if ! ffmpeg -f "$output_template" "$edit_command" "$edit_output_template" 2> ffmpeg_error.log; then
            echo -e "${RED}[✗] Editing failed. Check ffmpeg_error.log for details."
            cat ffmpeg_error.log
            else
            if [[ -f "$edit_output_template" ]]; then
                echo -e "${GREEN}[✔] Editing completed! Edited file: $edit_output_template${NC}"
            else
                echo -e "${RED}[✗] Edited file not found. Editing failed${NC}"
            fi
        fi
    elif [[ "$scope_choice" == "1" ]]; then
        # Single video without editing
        echo -e "${YELLOW}[+] Downloading video...${NC}"
        if ! yt-dlp $cookies_command $extra_options -f "$quality" -o "$output_template" "$video_url"; then
            echo -e "${RED}[✗] Download failed. Exiting...${NC}"
            exit 1
        fi
    else
        # Playlist/channel/user download (no editing supported)
        echo -e "${YELLOW}[+] Downloading videos...${NC}"
        if ! yt-dlp $cookies_command $extra_options -f "$quality" -o "$output_template" --yes-playlist "$video_url"; then
            echo -e "${RED}[✗] Download failed. Exiting...${NC}"
            exit 1
        fi
    fi
    
    # Completion message
    echo -e "\n${GREEN}[✔] Download completed!${NC}"
    echo - ls -lh "${output_dir" | head -n 10
    [[ $(ls -l "$output_dir" | wc -l) -gt 10 ]] && echo "[...more files not shown...]"
}

# Part 10: Run Script
# -----------------------------------------------
main
