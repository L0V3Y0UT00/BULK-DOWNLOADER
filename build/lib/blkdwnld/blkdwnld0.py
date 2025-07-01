#!/usr/bin/env python3

import os
import subprocess
import re
import shutil
import sys
from pathlib import Path
import yt_dlp
import ffmpeg

# Color codes for terminal output
RED = '\033[0;31m'
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
BLUE = '\033[0;34m'
NC = '\033[0m'  # No Color
BOLD = '\033[1m'

def header():
    """Display the header."""
    print(f"{BLUE}============================================={NC}")
    print(f"{BOLD}       BULK VIDEO DOWNLOADER TOOL {NC}")
    print(f"               {YELLOW}By Ans Raza (0xAnsR){NC}")
    print(f"                                {RED}v0.21{NC}")
    print(f"{BLUE}============================================={NC}\n")

def check_ytdlp():
    """Check if yt-dlp is installed, install if missing."""
    if not shutil.which("yt-dlp"):
        print(f"{RED}yt-dlp is not installed.{NC}")
        choice = input("Install yt-dlp now? (y/n): ").lower()
        if choice == 'y':
            print(f"{YELLOW}Installing yt-dlp...{NC}")
            subprocess.run([sys.executable, "-m", "pip", "install", "yt-dlp"], check=True)
            print(f"{GREEN}yt-dlp installed successfully!{NC}")
        else:
            print(f"{RED}Script requires yt-dlp. Exiting.{NC}")
            sys.exit(1)

def check_ffmpeg():
    """Check if ffmpeg is installed, install if missing."""
    if not shutil.which("ffmpeg"):
        print(f"{RED}ffmpeg is not installed.{NC}")
        choice = input("Install ffmpeg now? (y/n): ").lower()
        if choice == 'y':
            print(f"{YELLOW}Installing ffmpeg...{NC}")
            if sys.platform.startswith("linux"):
                subprocess.run(["sudo", "apt-get", "update"], check=True)
                subprocess.run(["sudo", "apt-get", "install", "-y", "ffmpeg"], check=True)
            elif sys.platform.startswith("darwin"):
                subprocess.run(["brew", "install", "ffmpeg"], check=True)
            else:
                print(f"{RED}Unsupported OS for auto-install. Please install ffmpeg manually.{NC}")
                sys.exit(1)
            print(f"{GREEN}ffmpeg installed successfully!{NC}")
            return True
        else:
            print(f"{YELLOW}Video editing requires ffmpeg. Continuing without editing.{NC}")
            return False
    return True

def setup_cookies():
    """Handle cookie setup for private/restricted videos."""
    cookies_file = Path("cookies.txt")
    cookies_command = []
    
    if cookies_file.exists() and cookies_file.stat().st_size > 0:
        with open(cookies_file, 'r') as f:
            if "# Netscape HTTP Cookie File" in f.read():
                print(f"{GREEN}Using cookies.txt{NC}")
                cookies_command = ["--cookies", str(cookies_file)]
                return cookies_command
            else:
                print(f"{RED}cookies.txt does not contain valid cookies!{NC}")
    
    print("Steps to get cookies:")
    print("1. Log in to the target site in Chrome/Firefox")
    print("2. Install the 'Get cookies.txt LOCALLY' extension:")
    print("   [Chrome Web Store](https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc)")
    print("3. Export cookies as 'cookies.txt' in this folder\n")
    
    choice = input("Use cookies? (y/n): ").lower()
    if choice != 'y':
        return []
    
    print("\nCookie Setup Options:")
    print("1) Provide cookies.txt path")
    print("2) Skip cookie setup")
    method = input("Select (1-2): ")
    
    if method == '1':
        path = input("Enter full path to cookies.txt: ")
        if Path(path).exists() and Path(path).stat().st_size > 0:
            with open(path, 'r') as f:
                if "# Netscape HTTP Cookie File" in f.read():
                    cookies_file.write_text(Path(path).read_text())
                    print(f"{GREEN}Cookies configured!{NC}")
                    return ["--cookies", str(cookies_file)]
        print(f"{RED}File not found or invalid! Continuing without cookies.{NC}")
    return []

def get_url_identifier(url, platform):
    """Extract identifier from URL."""
    if platform == "youtube":
        if "youtube.com/c/" in url:
            return re.search(r'youtube\.com/c/([^/]+)', url).group(1)
        elif "youtube.com/user/" in url:
            return re.search(r'youtube\.com/user/([^/]+)', url).group(1)
        elif "youtube.com/channel/" in url:
            return re.search(r'youtube\.com/channel/([^/]+)', url).group(1)
        return "videos"
    elif platform == "tiktok":
        if "tiktok.com/@" in url:
            return re.search(r'tiktok\.com/@([^/]+)', url).group(1)
        return "tiktok_videos"
    elif platform == "facebook":
        if "facebook.com/" in url:
            return re.search(r'facebook\.com/([^/]+)', url).group(1)
        return "fb_videos"
    return f"{url.split('/')[-1]}_{int(Path().absolute().stat().st_mtime)}"

def configure_editing():
    """Configure video editing options."""
    print(f"{BOLD}Video Editing Options:{NC}")
    options = ["No editing", "Trim video", "Resize video", "Convert format", "Flip video"]
    for i, opt in enumerate(options, 1):
        print(f"{i}) {opt}")
    choice = input(f"{YELLOW}Select option (1-5): {NC}")
    
    while choice not in {'1', '2', '3', '4', '5'}:
        print(f"{RED}Invalid choice. Enter a number between 1 and 5.{NC}")
        choice = input(f"{YELLOW}Select option (1-5): {NC}")
    
    if choice == '2':
        start = input("Enter start time (e.g., 00:00:10): ")
        duration = input("Enter duration (e.g., 00:00:30): ")
        return f"-ss {start} -t {duration} -c:v copy -c:a copy", "_trimmed.mp4"
    elif choice == '3':
        resolution = input("Enter resolution (e.g., 1280x720): ")
        return f"-vf scale={resolution} -c:a copy", "_resized.mp4"
    elif choice == '4':
        format = input("Enter output format (e.g., mp4, avi): ")
        return "-c:v libx264 -c:a aac", f"_converted.{format}"
    elif choice == '5':
        print(f"{BOLD}Flip Options:{NC}")
        flip_options = ["Horizontal flip", "Vertical flip", "Both"]
        for i, opt in enumerate(flip_options, 1):
            print(f"{i}) {opt}")
        flip_choice = input(f"{YELLOW}Select flip option (1-3): {NC}")
        while flip_choice not in {'1', '2', '3'}:
            print(f"{RED}Invalid choice. Enter a number between 1 and 3.{NC}")
            flip_choice = input(f"{YELLOW}Select flip option (1-3): {NC}")
        if flip_choice == '1':
            return "-vf hflip -c:a copy", "_hflipped.mp4"
        elif flip_choice == '2':
            return "-vf vflip -c:a copy", "_vflipped.mp4"
        return "-vf hflip,vflip -c:a copy", "_flipped.mp4"
    return "", ""

def show_summary(platform, url_identifier, quality_label, output_dir, edit_choice, description_choice):
    """Display download settings summary."""
    header()
    print(f"{GREEN}Download Settings:{NC}")
    print(f" - Platform: {platform}")
    print(f" - Source: {url_identifier}")
    print(f" - Quality: {quality_label}")
    print(f" - Cookies: {'Enabled' if cookies_command else 'Disabled'}")
    print(f" - Description: {'Included' if description_choice == '1' else 'Excluded'}")
    print(f" - Editing: {'Disabled' if edit_choice == '1' or not edit_choice else options[int(edit_choice)-1]}")
    print(f" - Output: {output_dir}{NC}\n")

def main():
    """Main function to handle video downloads."""
    header()
    check_ytdlp()
    has_ffmpeg = check_ffmpeg()

    # Platform selection
    print(f"{BOLD}Select Platform:{NC}")
    platforms = ["YouTube", "Facebook", "TikTok", "Other"]
    for i, plat in enumerate(platforms, 1):
        print(f"{i}) {plat}")
    platform_choice = input(f"{YELLOW}Select platform (1-4): {NC}")
    while platform_choice not in {'1', '2', '3', '4'}:
        print(f"{RED}Invalid choice. Enter a number between 1 and 4.{NC}")
        platform_choice = input(f"{YELLOW}Select platform (1-4): {NC}")
    
    platform_map = {"1": "youtube", "2": "facebook", "3": "tiktok", "4": "other"}
    platform = platform_map[platform_choice]

    # Cookie setup
    global cookies_command
    cookies_command = setup_cookies()
    if platform == "tiktok":
        cookies_command.extend(["--referer", "https://www.tiktok.com/"])

    # URL input
    video_url = input(f"Enter {'video/channel' if platform in {'youtube', 'tiktok'} else 'post/page' if platform == 'facebook' else 'URL'} URL: ")
    if not video_url:
        print(f"{RED}URL cannot be empty!{NC}")
        sys.exit(1)

    # Scope selection
    print(f"{BOLD}Download Scope:{NC}")
    scopes = ["Single video", "All videos"]
    for i, scope in enumerate(scopes, 1):
        print(f"{i}) {scope}")
    scope_choice = input(f"{YELLOW}Select scope (1-2): {NC}")
    while scope_choice not in {'1', '2'}:
        print(f"{RED}Invalid choice. Enter a number between 1 and 2.{NC}")
        scope_choice = input(f"{YELLOW}Select scope (1-2): {NC}")

    # Quality selection
    print(f"{BOLD}Video Quality:{NC}")
    qualities = ["Best quality", "1080p", "720p", "480p", "Audio only (MP3)"]
    for i, qual in enumerate(qualities, 1):
        print(f"{i}) {qual}")
    quality_choice = input(f"{YELLOW}Select quality (1-5): {NC}")
    while quality_choice not in {'1', '2', '3', '4', '5'}:
        print(f"{RED}Invalid choice. Enter a number between 1 and 5.{NC}")
        quality_choice = input(f"{YELLOW}Select quality (1-5): {NC}")
    
    quality_map = {
        "1": ("bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]", "Best quality"),
        "2": ("bestvideo[height<=1080][ext=mp4]+bestaudio[ext=m4a]/best[height<=1080][ext=mp4]", "1080p"),
        "3": ("bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720][ext=mp4]", "720p"),
        "4": ("bestvideo[height<=480][ext=mp4]+bestaudio[ext=m4a]/best[height<=480][ext=mp4]", "480p"),
        "5": ("bestaudio -x --audio-format mp3", "Audio only (MP3)")
    }
    quality, quality_label = quality_map[quality_choice]

    # Description file selection
    description_command = []
    description_choice = "2"
    if quality_choice != "5":
        print(f"{BOLD}Download Options:{NC}")
        desc_options = ["MP4 with description file", "MP4 only"]
        for i, opt in enumerate(desc_options, 1):
            print(f"{i}) {opt}")
        description_choice = input(f"{YELLOW}Select option (1-2): {NC}")
        while description_choice not in {'1', '2'}:
            print(f"{RED}Invalid choice. Enter a number between 1 and 2.{NC}")
            description_choice = input(f"{YELLOW}Select option (1-2): {NC}")
        if description_choice == "1":
            description_command = ["--write-description"]

    # Editing options
    edit_command, edit_suffix = "", ""
    if scope_choice == "1" and has_ffmpeg:
        edit_command, edit_suffix = configure_editing()

    # Output directory
    url_identifier = get_url_identifier(video_url, platform)
    output_dir = f"{platform}_{url_identifier}_downloads" if scope_choice == "2" else f"{platform}_single_videos"
    Path(output_dir).mkdir(exist_ok=True)
    output_template = f"{output_dir}/%(title)s.%(ext)s"
    edit_output_template = f"{output_dir}/%(title)s{edit_suffix}"

    # Platform-specific options
    extra_options = {
        "youtube": ["--embed-thumbnail", "--add-metadata"],
        "tiktok": ["--force-overwrites", "--write-thumbnail"],
        "facebook": [],
        "other": []
    }[platform] + description_command

    # Show summary
    show_summary(platform, url_identifier, quality_label, output_dir, edit_command, description_choice)

    # Download execution
    ydl_opts = {
        "format": quality,
        "outtmpl": output_template,
        "noplaylist": scope_choice == "1",
        "merge_output_format": "mp4"  # Ensure MP4 output
    }
    if cookies_command:
        ydl_opts["cookiefile"] = cookies_command[cookies_command.index("--cookies") + 1]
    if "--referer" in cookies_command:
        ydl_opts["referer"] = cookies_command[cookies_command.index("--referer") + 1]

    print(f"{YELLOW}Downloading {'single video' if scope_choice == '1' else 'multiple videos'}...{NC}")
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([video_url])
    except Exception as e:
        print(f"{RED}Download failed: {e}{NC}")
        sys.exit(1)

    if scope_choice == "1" and edit_command and has_ffmpeg:
        print(f"{YELLOW}Editing video...{NC}")
        input_file = sorted(Path(output_dir).iterdir(), key=lambda x: x.stat().st_mtime, reverse=True)[0]
        output_file = f"{output_dir}/{input_file.stem}{edit_suffix}"
        try:
            stream = ffmpeg.input(str(input_file))
            stream = ffmpeg.output(stream, output_file, **{k: v for k, v in [x.split("=") for x in edit_command.split() if "=" in x]})
            ffmpeg.run(stream)
            print(f"{GREEN}Editing completed!{NC}")
        except ffmpeg.Error as e:
            print(f"{RED}Editing failed: {e.stderr.decode()}{NC}")
            sys.exit(1)

    print(f"{GREEN}Download completed!{NC}")
    for file in list(Path(output_dir).iterdir())[:5]:
        print(f"{file}")
    if len(list(Path(output_dir).iterdir())) > 5:
        print("[...] More files...")

if __name__ == "__main__":
    main()
