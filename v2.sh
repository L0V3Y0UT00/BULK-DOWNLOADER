#!/bin/bash

# Bulk Video Downloader Script using yt-dlp with cookie support

# Function to display header
header() {
    clear
echo "============================================="
    echo "       BULK VIDEO DOWNLOADER TOOL "
     echo "               BY Ans Raza(0xAnsR)"
      echo "                                v:0.2"
    echo "============================================="
    echo
}
}

# Function to check if yt-dlp is installed
check_ytdlp() {
    if ! command -v yt-dlp &> /dev/null; then
        echo "yt-dlp is not installed."
        read -p "Would you like to install it now? (y/n): " install_choice
        if [[ "$install_choice" == "y" ]]; then
            echo "Installing yt-dlp..."
            sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
            sudo chmod a+rx /usr/local/bin/yt-dlp
            echo "yt-dlp installed successfully!"
            sleep 2
        else
            echo "This script requires yt-dlp. Exiting."
            exit 1
        fi
    fi
}

# Function to guide cookie file setup
setup_cookies() {
    header
    echo "COOKIE SETUP (Required for some private/age-restricted videos)"
    echo
    echo "To get cookies:"
    echo "1. Login to the website in Firefox or Chrome"
    echo "2. Install the 'Get cookies.txt' browser extension"
    echo "3. Export cookies and save as 'cookies.txt' in this folder"
    echo
    
    if [[ -f "cookies.txt" ]]; then
        echo "Existing cookies.txt file found!"
        echo "File size: $(du -h cookies.txt | cut -f1)"
        echo "Last modified: $(date -r cookies.txt)"
        echo
        read -p "Use this cookies file? (y/n): " use_cookies
        
        if [[ "$use_cookies" == "y" ]]; then
            cookies_command="--cookies cookies.txt"
            echo "Using existing cookies.txt file"
            sleep 2
            return
        else
            # If user doesn't want to use existing cookies, delete the old file
            rm -f cookies.txt
        fi
    fi
    
    read -p "Do you want to use cookies for this download? (y/n): " need_cookies
    
    if [[ "$need_cookies" == "y" ]]; then
        echo
        echo "1) Let me manually provide cookies.txt path"
        echo "2) Open Firefox to login and export cookies (requires firefox)"
        echo "3) Skip cookie setup and try without cookies"
        read -p "Enter choice (1-3): " cookie_method
        
        case $cookie_method in
            1)
                read -p "Enter full path to cookies.txt file: " cookie_path
                if [[ -f "$cookie_path" ]]; then
                    cp "$cookie_path" ./cookies.txt
                    cookies_command="--cookies cookies.txt"
                    echo "Cookies file set up successfully"
                else
                    echo "File not found! Continuing without cookies"
                    cookies_command=""
                fi
                ;;
            2)
                if command -v firefox &> /dev/null; then
                    echo "Opening Firefox..."
                    echo "Please login to the website, then export cookies using the extension"
                    firefox &
                    read -p "Press Enter after you've exported cookies.txt to this folder..."
                    
                    if [[ -f "cookies.txt" ]]; then
                        cookies_command="--cookies cookies.txt"
                        echo "Cookies file found and will be used"
                    else
                        echo "No cookies.txt file found in current directory"
                        cookies_command=""
                    fi
                else
                    echo "Firefox not installed! Cannot automate cookie export"
                    cookies_command=""
                fi
                ;;
            *)
                cookies_command=""
                echo "Continuing without cookies"
                ;;
        esac
    else
        cookies_command=""
    fi
    sleep 1
}

# Main function
main() {
    header
    check_ytdlp
    
    # Platform selection
    echo "Select platform:"
    echo "1) Facebook"
    echo "2) YouTube"
    echo "3) TikTok"
    echo "4) Other (enter URL directly)"
    read -p "Enter choice (1-4): " platform_choice
    
    case $platform_choice in
        1) platform="facebook"; profile_type="post/page";;
        2) platform="youtube"; profile_type="video/channel";;
        3) platform="tiktok"; profile_type="video/user";;
        4) platform="other"; profile_type="";;
        *) echo "Invalid choice"; exit 1;;
    esac
    
    # Setup cookies (Facebook, TikTok, and Other platforms often need cookies)
    if [[ "$platform" == "facebook" || "$platform" == "tiktok" || "$platform_choice" == "4" ]]; then
        setup_cookies
        
        # Special TikTok cookie handling
        if [[ "$platform" == "tiktok" && -n "$cookies_command" ]]; then
            cookies_command+=" --referer https://www.tiktok.com/"
        fi
    else
        cookies_command=""
    fi
    
    # Get URL
    if [[ "$platform" == "other" ]]; then
        read -p "Enter the full URL: " video_url
    else
        read -p "Enter the $profile_type URL: " video_url
    fi
    
    # Download scope selection
    header
    echo "Download scope:"
    echo "1) Single video"
    echo "2) All videos from a page/channel/user"
    read -p "Enter choice (1-2): " scope_choice
    
    # Quality selection
    header
    echo "Select quality:"
    echo "1) Best quality (recommended)"
    echo "2) 1080p"
    echo "3) 720p"
    echo "4) 480p"
    read -p "Enter choice (1-4): " quality_choice
    
    case $quality_choice in
        1) quality="best";;
        2) quality="bestvideo[height<=1080]+bestaudio/best[height<=1080]";;
        3) quality="bestvideo[height<=720]+bestaudio/best[height<=720]";;
        4) quality="bestvideo[height<=480]+bestaudio/best[height<=480]";;
        *) quality="best";;
    esac
    
    # Output folder
    mkdir -p downloaded_videos
    output_template="downloaded_videos/%(title)s.%(ext)s"
    
    # Additional options for TikTok
    tiktok_options=""
    if [[ "$platform" == "tiktok" ]]; then
        tiktok_options="--force-overwrites --write-description --write-thumbnail"
    fi
    
    # Download based on choices
    header
    echo "Starting download with these settings:"
    echo "Platform: $platform"
    echo "Quality: $quality_choice"
    [[ -n "$cookies_command" ]] && echo "Using cookies: Yes" || echo "Using cookies: No"
    echo
    
    if [[ "$scope_choice" == "1" ]]; then
        # Single video download
        yt-dlp $cookies_command $tiktok_options -f "$quality" -o "$output_template" "$video_url"
    else
        # Bulk download with different approaches per platform
        case $platform in
            tiktok)
                echo "Downloading all videos from TikTok user..."
                yt-dlp $cookies_command $tiktok_options -f "$quality" -o "$output_template" --yes-playlist --match-filter "!is_live" "$video_url"
                ;;
            *)
                yt-dlp $cookies_command $tiktok_options -f "$quality" -o "$output_template" --yes-playlist "$video_url"
                ;;
        esac
    fi
    
    echo
    echo "Download completed!"
    echo "Videos saved in: $(pwd)/downloaded_videos"
}

# Run main function
main
