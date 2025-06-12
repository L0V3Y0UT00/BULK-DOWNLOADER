#!/bin/bash

# Bulk Video Downloader Script using yt-dlp with cookie support
# Version: 0.4
# Author: Ans Raza (0xAnsR)

# -----------------------------------------------
#   COLOR AND FORMATTING (for better UX)
# -----------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# -----------------------------------------------
#   FUNCTION: Print header
# -----------------------------------------------
header() {
    clear
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BOLD}       BULK VIDEO DOWNLOADER TOOL ${NC}"
    echo -e "               ${YELLOW}BY Ans Raza (0xAnsR)${NC}"
    echo -e "                                ${RED}v:0.4${NC}"
    echo -e "${BLUE}=============================================${NC}\n"
}

# -----------------------------------------------
#   FUNCTION: Check/install yt-dlp
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

# -----------------------------------------------
#   FUNCTION: Setup cookies for private content
# -----------------------------------------------
setup_cookies() {
    header
    echo -e "${BOLD}COOKIE SETUP (for private/age-restricted videos)${NC}\n"
    echo -e "Steps to get cookies:"
    echo -e "1. Login to the target site in Firefox/Chrome"
    echo -e "2. Install the '${BLUE}Get cookies.txt${NC}' browser extension"
    echo -e "3. Export cookies as '${GREEN}cookies.txt${NC}' in this folder\n"
    
    if [[ -f "cookies.txt" ]]; then
        echo -e "${GREEN}[+] Existing cookies.txt found:${NC}"
        echo -e "  Size: $(du -h cookies.txt | cut -f1)"
        echo -e "  Last modified: $(date -r cookies.txt)\n"
        read -p "Use this file? (y/n): " use_cookies
        
        if [[ "$use_cookies" == "y" ]]; then
            cookies_command="--cookies cookies.txt"
            echo -e "${GREEN}[✔] Using existing cookies.txt${NC}"
            sleep 1
            return
        else
            rm -f cookies.txt
            echo -e "${YELLOW}[!] Old cookies.txt removed.${NC}"
        fi
    fi
    
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

# -----------------------------------------------
#   FUNCTION: Extract username/channel from URL
# -----------------------------------------------
get_url_identifier() {
    local url=$1
    local platform=$2
    
    case $platform in
        youtube)
            # Extract channel name or user from YouTube URL
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
            # Extract username from TikTok URL
            if [[ $url == *"tiktok.com/@"* ]]; then
                identifier=$(echo "$url" | awk -F'tiktok.com/@' '{print $2}' | cut -d'/' -f1)
            else
                identifier="tiktok_videos"
            fi
            ;;
        facebook)
            # Extract page name from Facebook URL
            if [[ $url == *"facebook.com/"* ]]; then
                identifier=$(echo "$url" | awk -F'facebook.com/' '{print $2}' | cut -d'/' -f1)
            else
                identifier="fb_videos"
            fi
            ;;
        *)
            # For other URLs, use domain name + timestamp
            domain=$(echo "$url" | awk -F'://' '{print $2}' | awk -F'/' '{print $1}' | sed 's/www\.//')
            identifier="${domain}_$(date +%s)"
            ;;
    esac
    
    # Clean up the identifier (remove special characters)
    echo "$identifier" | tr -cd '[:alnum:].-_'
}

# -----------------------------------------------
#   FUNCTION: Main download logic
# -----------------------------------------------
main() {
    header
    check_ytdlp
    
    # Platform selection
    echo -e "${BOLD}Select Platform:${NC}"
    echo -e "1) ${BLUE}Facebook${NC}"
    echo -e "2) ${RED}YouTube${NC}"
    echo -e "3) ${YELLOW}TikTok${NC}"
    echo -e "4) Other (direct URL)"
    read -p "Enter choice (1-4): " platform_choice
    
    case $platform_choice in
        1) platform="facebook"; profile_type="post/page";;
        2) platform="youtube"; profile_type="video/channel";;
        3) platform="tiktok"; profile_type="video/user";;
        4) platform="other"; profile_type="";;
        *) echo -e "${RED}[✗] Invalid choice. Exiting.${NC}"; exit 1;;
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
    echo -e "1) Single video"
    echo -e "2) All videos from page/channel/user"
    read -p "Enter choice (1-2): " scope_choice
    
    # Quality selection
    header
    echo -e "${BOLD}Video Quality:${NC}"
    echo -e "1) Best quality (default)"
    echo -e "2) 1080p"
    echo -e "3) 720p"
    echo -e "4) 480p"
    echo -e "5) Audio only (MP3)"
    read -p "Enter choice (1-5): " quality_choice
    
    case $quality_choice in
        1) quality="best";;
        2) quality="bestvideo[height<=1080]+bestaudio/best[height<=1080]";;
        3) quality="bestvideo[height<=720]+bestaudio/best[height<=720]";;
        4) quality="bestvideo[height<=480]+bestaudio/best[height<=480]";;
        5) quality="bestaudio -x --audio-format mp3";;
        *) quality="best";;
    esac
    
    # Output folder naming logic
    if [[ "$scope_choice" == "2" ]]; then
        # For channel/user downloads
        output_dir="${platform}_${url_identifier}_downloads"
    else
        # For single video downloads
        output_dir="${platform}_${url_identifier}_$(date +%s)"
    fi
    
    mkdir -p "$output_dir"
    output_template="$output_dir/%(title)s.%(ext)s"
    
    # Platform-specific options
    case $platform in
        tiktok) 
            extra_options="--force-overwrites --write-description --write-thumbnail --match-filter '!is_live'";;
        youtube) 
            extra_options="--embed-thumbnail --add-metadata";;
        *) extra_options="";;
    esac
    
    # Download execution
    header
    echo -e "${GREEN}[+] Starting download with settings:${NC}"
    echo -e "  Platform: ${BOLD}$platform${NC}"
    [[ -n "$url_identifier" ]] && echo -e "  Source: ${YELLOW}$url_identifier${NC}"
    echo -e "  Quality: ${BOLD}$quality_choice${NC}"
    [[ -n "$cookies_command" ]] && echo -e "  Cookies: ${GREEN}Enabled${NC}" || echo -e "  Cookies: ${RED}Disabled${NC}"
    echo -e "  Output: ${BLUE}$output_dir${NC}\n"
    
    if [[ "$scope_choice" == "1" ]]; then
        # Single video
        yt-dlp $cookies_command $extra_options -f "$quality" -o "$output_template" "$video_url"
    else
        # Playlist/channel download
        yt-dlp $cookies_command $extra_options -f "$quality" -o "$output_template" --yes-playlist "$video_url"
    fi
    
    echo -e "\n${GREEN}[✔] Download complete!${NC}"
    echo -e "Files saved to: ${BOLD}$(pwd)/$output_dir${NC}"
}

# Run script
main
