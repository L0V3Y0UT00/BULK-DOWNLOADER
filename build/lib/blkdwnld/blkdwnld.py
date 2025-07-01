#!/usr/bin/env python3

import os
import subprocess
import re
import shutil
import sys
import json
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
                print(f"{GREEN}Using existing cookies.txt{NC}")
                cookies_command = ["--cookies", str(cookies_file)]
                return cookies_command
            else:
                print(f"{RED}Existing cookies.txt is invalid!{NC}")
    
    print("Steps to get cookies:")
    print("1. Log in to the target site in Chrome/Firefox")
    print("2. Install the 'Get cookies.txt LOCALLY' extension:")
    print("   [Chrome Web Store](https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc)")
    print("3. Export cookies as 'cookies.txt' or paste them below\n")
    
    choice = input("Use cookies? (y/n): ").lower()
    if choice != 'y':
        return []
    
    print("\nCookie Setup Options:")
    print("1) Provide cookies.txt path")
    print("2) Paste cookies directly")
    print("3) Edit cookies.txt in text editor")
    print("4) Skip cookie setup")
    method = input("Select (1-4): ")
    
    while method not in {'1', '2', '3', '4'}:
        print(f"{RED}Invalid choice. Enter a number between 1 and 4.{NC}")
        method = input("Select (1-4): ")
    
    if method == '1':
        path = input("Enter full path to cookies.txt: ")
        if Path(path).exists() and Path(path).stat().st_size > 0:
            with open(path, 'r') as f:
                if "# Netscape HTTP Cookie File" in f.read():
                    cookies_file.write_text(Path(path).read_text())
                    print(f"{GREEN}Cookies configured from file!{NC}")
                    return ["--cookies", str(cookies_file)]
        print(f"{RED}File not found or invalid! Continuing without cookies.{NC}")
    
    elif method == '2':
        print(f"{YELLOW}Paste cookies (starting with '# Netscape HTTP Cookie File', press Ctrl+D or Ctrl+Z when done):{NC}")
        cookies_content = []
        try:
            while True:
                line = input()
                cookies_content.append(line)
        except EOFError:
            cookies_content = "\n".join(cookies_content)
            if "# Netscape HTTP Cookie File" in cookies_content:
                cookies_file.write_text(cookies_content)
                print(f"{GREEN}Cookies saved to cookies.txt!{NC}")
                return ["--cookies", str(cookies_file)]
            else:
                print(f"{RED}Invalid cookies format! Must start with '# Netscape HTTP Cookie File'. Continuing without cookies.{NC}")
    
    elif method == '3':
        editor = os.getenv("EDITOR", "nano")
        print(f"{YELLOW}Opening cookies.txt in {editor}. Save and exit when done.{NC}")
        if not cookies_file.exists():
            cookies_file.write_text("# Netscape HTTP Cookie File\n# Paste your cookies below\n")
        subprocess.run([editor, str(cookies_file)])
        if cookies_file.exists() and cookies_file.stat().st_size > 0:
            with open(cookies_file, 'r') as f:
                if "# Netscape HTTP Cookie File" in f.read():
                    print(f"{GREEN}Cookies configured from edited file!{NC}")
                    return ["--cookies", str(cookies_file)]
            print(f"{RED}Edited cookies.txt is invalid! Continuing without cookies.{NC}")
    
    return []

def validate_url(url):
    """Validate URL format and TLD."""
    # Regex for URLs with valid TLDs
    url_pattern = re.compile(
        r'^https?://'  # http:// or https://
        r'(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+[A-Z]{2,6}\.?|'  # domain...
        r'localhost|'  # localhost...
        r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'  # ...or IP
        r'(?::\d+)?'  # optional port
        r'(?:/?|[/?]\S+)$', re.IGNORECASE)
    
    # Common TLDs for validation
    valid_tlds = {'.com', '.net', '.org', '.edu', '.gov', '.co', '.io', '.me', '.tv', '.biz', '.info'}
    if not url_pattern.match(url):
        return False
    # Extract TLD
    tld = '.' + url.split('.')[-1].split('/')[0].lower()
    return tld in valid_tlds

def detect_platform(url):
    """Detect platform from URL."""
    if "youtube.com" in url or "youtu.be" in url:
        return "youtube"
    elif "tiktok.com" in url:
        return "tiktok"
    elif "facebook.com" in url or "fb.com" in url:
        return "facebook"
    elif "x.com" in url:
        return "x"
    elif "instagram.com" in url:
        return "instagram"
    elif "threads.net" in url:
        return "threads"
    return "other"

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
    elif platform == "x":
        if "x.com/" in url:
            return re.search(r'x\.com/([^/]+)', url).group(1)
        return "x_videos"
    elif platform == "instagram":
        if "instagram.com/" in url:
            return re.search(r'instagram\.com/([^/]+)', url).group(1)
        return "insta_videos"
    elif platform == "threads":
        if "threads.net/" in url:
            return re.search(r'threads\.net/([^/]+)', url).group(1)
        return "threads_videos"
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
        return f"-ss {start} -t {duration} -c:v copy -c:a copy", "_trimmed.mp4", choice, None
    elif choice == '3':
        resolution = input("Enter resolution (e.g., 1280x720): ")
        return f"-vf scale={resolution} -c:a copy", "_resized.mp4", choice, None
    elif choice == '4':
        format = input("Enter output format (e.g., mp4, avi): ")
        return "-c:v libx264 -c:a aac", f"_converted.{format}", choice, None
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
            return "-vf hflip -c:a copy", "_hflipped.mp4", choice, flip_choice
        elif flip_choice == '2':
            return "-vf vflip -c:a copy", "_vflipped.mp4", choice, flip_choice
        return "-vf hflip,vflip -c:a copy", "_flipped.mp4", choice, flip_choice
    return "", "", choice, None

def show_summary(platform, url_identifier, quality_label, output_dir, edit_choice, description_choice, video_url):
    """Display download settings summary."""
    header()
    print(f"{GREEN}Download Settings:{NC}")
    print(f" - Platform: {platform}")
    print(f" - URL: {video_url}")
    print(f" - Source: {url_identifier}")
    print(f" - Quality: {quality_label}")
    print(f" - Cookies: {'Enabled' if cookies_command else 'Disabled'}")
    print(f" - Description: {'Included' if description_choice == '1' else 'Excluded'}")
    print(f" - Editing: {'Disabled' if edit_choice == '1' or not edit_choice else options[int(edit_choice)-1]}")
    print(f" - Output: {output_dir}{NC}\n")

def load_last_config():
    """Load last configuration from last_config.json."""
    config_file = Path("last_config.json")
    if config_file.exists():
        try:
            with open(config_file, 'r') as f:
                return json.load(f)
        except json.JSONDecodeError:
            print(f"{RED}Invalid last_config.json. Starting fresh.{NC}")
    return None

def save_config(video_url, platform, scope_choice, quality_choice, description_choice, edit_choice, edit_subchoice):
    """Save configuration to last_config.json."""
    config = {
        "video_url": video_url,
        "platform": platform,
        "scope_choice": scope_choice,
        "quality_choice": quality_choice,
        "description_choice": description_choice,
        "edit_choice": edit_choice,
        "edit_subchoice": edit_subchoice
    }
    with open("last_config.json", 'w') as f:
        json.dump(config, f, indent=4)
    print(f"{GREEN}Configuration saved to last_config.json{NC}")

def main():
    """Main function to handle video downloads."""
    header()
    check_ytdlp()
    has_ffmpeg = check_ffmpeg()

    # Load last configuration
    last_config = load_last_config()
    if last_config:
        print(f"{YELLOW}Last configuration found:{NC}")
        print(f" - URL: {last_config['video_url']}")
        print(f" - Platform: {last_config['platform']}")
        print(f" - Scope: {'Single video' if last_config['scope_choice'] == '1' else 'All videos'}")
        print(f" - Quality: {['Best quality', '1080p', '720p', '480p', 'Audio only (MP3)'][int(last_config['quality_choice'])-1]}")
        print(f" - Description: {'Included' if last_config['description_choice'] == '1' else 'Excluded'}")
        print(f" - Editing: {'Disabled' if last_config['edit_choice'] == '1' or not last_config['edit_choice'] else ['No editing', 'Trim video', 'Resize video', 'Convert format', 'Flip video'][int(last_config['edit_choice'])-1]}")
        if last_config['edit_choice'] == '5' and last_config['edit_subchoice']:
            print(f" - Flip: {['Horizontal flip', 'Vertical flip', 'Both'][int(last_config['edit_subchoice'])-1]}")
        choice = input(f"{YELLOW}Use last configuration? (y/n): {NC}").lower()
        if choice == 'y':
            video_url = last_config['video_url']
            platform = last_config['platform']
            scope_choice = last_config['scope_choice']
            quality_choice = last_config['quality_choice']
            description_choice = last_config['description_choice']
            edit_choice = last_config['edit_choice']
            edit_subchoice = last_config.get('edit_subchoice')
        else:
            last_config = None
    else:
        last_config = None

    # URL input and platform detection
    if not last_config:
        while True:
            video_url = input(f"{YELLOW}Enter video/channel/post/page URL: {NC}")
            if not video_url:
                print(f"{RED}URL cannot be empty!{NC}")
                continue
            if validate_url(video_url):
                platform = detect_platform(video_url)
                print(f"{GREEN}Detected platform: {platform}{NC}")
                break
            print(f"{RED}Invalid URL! Must have a valid TLD (e.g., .com, .net, .org).{NC}")
    else:
        while True:
            video_url = input(f"{YELLOW}Enter new URL (press Enter to reuse {last_config['video_url']}): {NC}")
            if not video_url:
                video_url = last_config['video_url']
                platform = last_config['platform']
                break
            if validate_url(video_url):
                platform = detect_platform(video_url)
                print(f"{GREEN}Detected platform: {platform}{NC}")
                break
            print(f"{RED}Invalid URL! Must have a valid TLD (e.g., .com, .net, .org).{NC}")

    # Cookie setup
    global cookies_command
    cookies_command = setup_cookies()
    if platform == "tiktok":
        cookies_command.extend(["--referer", "https://www.tiktok.com/"])
    elif platform == "instagram":
        cookies_command.extend(["--referer", "https://www.instagram.com/"])
    elif platform == "threads":
        cookies_command.extend(["--referer", "https://www.threads.net/"])
    elif platform == "x":
        cookies_command.extend(["--referer", "https://www.x.com/"])

    # Scope selection
    if not last_config:
        print(f"{BOLD}Download Scope:{NC}")
        scopes = ["Single video", "All videos"]
        for i, scope in enumerate(scopes, 1):
            print(f"{i}) {scope}")
        scope_choice = input(f"{YELLOW}Select scope (1-2): {NC}")
        while scope_choice not in {'1', '2'}:
            print(f"{RED}Invalid choice. Enter a number between 1 and 2.{NC}")
            scope_choice = input(f"{YELLOW}Select scope (1-2): {NC}")
    else:
        scope_choice = last_config['scope_choice']

    # Quality selection
    if not last_config:
        print(f"{BOLD}Video Quality:{NC}")
        qualities = ["Best quality", "1080p", "720p", "480p", "Audio only (MP3)"]
        for i, qual in enumerate(qualities, 1):
            print(f"{i}) {qual}")
        quality_choice = input(f"{YELLOW}Select quality (1-5): {NC}")
        while quality_choice not in {'1', '2', '3', '4', '5'}:
            print(f"{RED}Invalid choice. Enter a number between 1 and 5.{NC}")
            quality_choice = input(f"{YELLOW}Select quality (1-5): {NC}")
    else:
        quality_choice = last_config['quality_choice']

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
    if quality_choice != "5":
        if not last_config:
            print(f"{BOLD}Download Options:{NC}")
            desc_options = ["MP4 with description file", "MP4 only"]
            for i, opt in enumerate(desc_options, 1):
                print(f"{i}) {opt}")
            description_choice = input(f"{YELLOW}Select option (1-2): {NC}")
            while description_choice not in {'1', '2'}:
                print(f"{RED}Invalid choice. Enter a number between 1 and 2.{NC}")
                description_choice = input(f"{YELLOW}Select option (1-2): {NC}")
        else:
            description_choice = last_config['description_choice']
        if description_choice == "1":
            description_command = ["--write-description"]
    else:
        description_choice = "2"

    # Editing options
    edit_command, edit_suffix, edit_choice, edit_subchoice = "", "", None, None
    if scope_choice == "1" and has_ffmpeg:
        if not last_config:
            edit_command, edit_suffix, edit_choice, edit_subchoice = configure_editing()
        else:
            edit_choice = last_config['edit_choice']
            edit_subchoice = last_config.get('edit_subchoice')
            if edit_choice == '2':
                start = input("Enter start time (e.g., 00:00:10): ")
                duration = input("Enter duration (e.g., 00:00:30): ")
                edit_command = f"-ss {start} -t {duration} -c:v copy -c:a copy"
                edit_suffix = "_trimmed.mp4"
            elif edit_choice == '3':
                resolution = input("Enter resolution (e.g., 1280x720): ")
                edit_command = f"-vf scale={resolution} -c:a copy"
                edit_suffix = "_resized.mp4"
            elif edit_choice == '4':
                format = input("Enter output format (e.g., mp4, avi): ")
                edit_command = "-c:v libx264 -c:a aac"
                edit_suffix = f"_converted.{format}"
            elif edit_choice == '5':
                if edit_subchoice == '1':
                    edit_command = "-vf hflip -c:a copy"
                    edit_suffix = "_hflipped.mp4"
                elif edit_subchoice == '2':
                    edit_command = "-vf vflip -c:a copy"
                    edit_suffix = "_vflipped.mp4"
                elif edit_subchoice == '3':
                    edit_command = "-vf hflip,vflip -c:a copy"
                    edit_suffix = "_flipped.mp4"

    # Save configuration
    save_config(video_url, platform, scope_choice, quality_choice, description_choice, edit_choice, edit_subchoice)

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
        "x": [],
        "instagram": [],
        "threads": [],
        "other": []
    }[platform] + description_command

    # Show summary
    show_summary(platform, url_identifier, quality_label, output_dir, edit_choice, description_choice, video_url)

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