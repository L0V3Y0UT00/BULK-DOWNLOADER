#!/bin/bash

# Bulk Video Downloader Script using yt-dlp

# Function to display header
header() {
    clear
    echo "============================================="
    echo "       BULK VIDEO DOWNLOADER TOOL "
     echo "               BY Ans Raza(0xAnsR)"
      echo "                                v:0.1"
    echo "============================================="
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

# Main function
main() {
    header
    check_ytdlp
    
    # Platform selection
    echo "Select platform:"
    echo "1) Facebook"
    echo "2) YouTube"
    echo "3) Other (enter URL directly)"
    read -p "Enter choice (1-3): " platform_choice
    
    case $platform_choice in
        1) platform="facebook";;
        2) platform="youtube";;
        3) platform="other";;
        *) echo "Invalid choice"; exit 1;;
    esac
    
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
    echo "2) All videos from a page/channel"
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
    
    # Download based on choices
    header
    echo "Starting download..."
    echo
    
    if [[ "$scope_choice" == "1" ]]; then
        # Single video download
        yt-dlp -f "$quality" -o "$output_template" "$video_url"
    else
        # Bulk download
        yt-dlp -f "$quality" -o "$output_template" --yes-playlist "$video_url"
    fi
    
    echo
    echo "Download completed!"
}

# Run main function
main
