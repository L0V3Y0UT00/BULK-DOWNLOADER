from setuptools import setup, find_packages
import os

setup(
    name="blkdwnld",
    version="0.21",
    packages=find_packages(),
    install_requires=[
        "yt-dlp>=2023.10.13",
        "ffmpeg-python>=0.2.0"
    ],
    entry_points={
        "console_scripts": [
            "blkdwnld=blkdwnld.blkdwnld:main"
        ]
    },
    author="Ans Raza (0xAnsR)",
    author_email="your.email@example.com",  # Replace with your email
    description="A bulk video downloader tool for YouTube, TikTok, Facebook, and more",
    long_description=open("README.md").read() if os.path.exists("README.md") else "",
    long_description_content_type="text/markdown",
    url="https://github.com/L0V3Y0UT00/BULK-DOWNLOADER",
    license="MIT",
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires=">=3.6",
)