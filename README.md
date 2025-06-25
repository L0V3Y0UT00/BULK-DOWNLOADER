# Bulk Video Downloader

A script to download videos from platforms like Facebook, YouTube, and more using `yt-dlp`.
how to use   
install extention  to chrome    we will copy cookies  

https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc


Go to https://shell.cloud.google.com/?hl=en_US&fromcloudshell=true&show=terminal      
 copy these commands  and paste into  terminal 
 git clone https://github.com/L0V3Y0UT00/BULK-DOWNLOADER.git
cd BULK-DOWNLOADER
chmod +x v8.sh && ./v8.sh    


enter    y   than  




 


## Features

✔ **Multi-Platform Support**:  
   - Facebook, YouTube, and other supported sites  
✔ **Flexible Download Options**:  
   - Single video or full channel/page downloads  
✔ **Quality Selection**:  
   - Auto-best, 1080p, 720p, or 480p  
✔ **Automatic Setup**:  
   - Detects and installs `yt-dlp` if missing  
   - Creates organized `downloaded_videos` folder  
✔ **Preserved Metadata**:  
   - Original video titles as filenames  

## Installation

```bash
git clone https://github.com/L0V3Y0UT00/BULK-DOWNLOADER.git
cd BULK-DOWNLOADER






Below is the `README.md` content with clickable links, formatted as plain text for easy copying. You can paste this into a `README.md` file in your project directory.

```markdown
# Bulk Video Downloader

A script to download videos from platforms like [Facebook](https://www.facebook.com), [YouTube](https://www.youtube.com), and more using [yt-dlp](https://github.com/yt-dlp/yt-dlp).

## How to Use

1. **Install Chrome Extension for Cookies**:
   - Install the **[Get Cookies.txt LOCALLY](https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc)** Chrome extension.
   - Use this extension to export cookies from the target website (e.g., [Facebook](https://www.facebook.com), [YouTube](https://www.youtube.com)) to a `cookies.txt` file for authenticated downloads.

2. **Access a Terminal**:
   - Use [Google Cloud Shell](https://shell.cloud.google.com/?hl=en_US&fromcloudshell=true&show=terminal) or a local terminal (Linux, macOS, or Windows with WSL/Git Bash).

3. **Clone and Run the Script**:
   - Run the following commands in your terminal:
     ```bash
     git clone https://github.com/L0V3Y0UT00/BULK-DOWNLOADER.git
     cd BULK-DOWNLOADER
     chmod +x v8.sh && ./v8.sh
     ```
   - When prompted, enter `y` to proceed.
   - Provide the video/channel URL, path to `cookies.txt` (if needed), and preferred video quality (e.g., auto-best, 1080p, 720p, 480p).

4. **Post-Download Options**:
   - **Zip Downloads**: Convert the `downloaded_videos` folder to a ZIP file:
     ```bash
     zip -r downloaded_videos.zip downloaded_videos
     ```
   - **Start Python Server**: Share or access files via a local server:
     ```bash
     python3 -m http.server 8000
     ```
     Access at `http://<your-ip>:8000`.

## Features

- **Multi-Platform Support**: Downloads from [YouTube](https://www.youtube.com), [Facebook](https://www.facebook.com), and other [yt-dlp-supported sites](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md).
- **Flexible Download Options**: Single video or entire channel/playlist downloads.
- **Quality Selection**: Choose auto-best, 1080p, 720p, or 480p.
- **Automatic Setup**: Installs [yt-dlp](https://github.com/yt-dlp/yt-dlp) and creates an organized `downloaded_videos` folder.
- **Preserved Metadata**: Uses original video titles as filenames.

## Notes

- **Cookies File**: Required for private/restricted content. Export correctly using the [Get Cookies.txt LOCALLY](https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc) extension.
- **Google Cloud Shell**: Storage is temporary; transfer files (e.g., via ZIP) to avoid loss.
- **Dependencies**: Ensure `git`, `python3`, and `zip` are installed locally. [Google Cloud Shell](https://shell.cloud.google.com/?hl=en_US&fromcloudshell=true&show=terminal) includes these.
- **Troubleshooting**: Check URLs, cookies file, or the [BULK-DOWNLOADER GitHub](https://github.com/L0V3Y0UT00/BULK-DOWNLOADER) for issues.

## Example Workflow

1. Install the [Get Cookies.txt LOCALLY](https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc) extension and export cookies.
2. Open [Google Cloud Shell](https://shell.cloud.google.com/?hl=en_US&fromcloudshell=true&show=terminal) or a local terminal.
3. Clone and run the script with the provided commands.
4. Enter `y`, provide the URL, cookies file path, and quality preference.
5. Zip the `downloaded_videos` folder or start the Python server to access files.
```

### Instructions
1. Copy the above text.
2. Create or open a file named `README.md` in your project directory (e.g., in the `BULK-DOWNLOADER` folder).
3. Paste the content into `README.md` and save the file.
4. If you're using a Git repository, commit and push the file to make it visible on GitHub.

Let me know if you need help with any specific step!
chmod +x v8.sh && ./v8.sh

