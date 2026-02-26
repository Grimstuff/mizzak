@echo off
title Discord Music Bot Console

:: Change to the directory where the script is located
pushd "%~dp0"

:: Set path to your virtual environment
SET VENV_FOLDER=venv
SET VENV_PATH=%VENV_FOLDER%\Scripts\activate.bat
SET BOT_SCRIPT=mizzak.py

echo ===============================================
echo             Discord Music Bot                  
echo ===============================================

:: Check for FFmpeg (Critical for voice/audio streaming)
ffmpeg -version >nul 2>&1
if %errorlevel% neq 0 (
    echo WARNING: FFmpeg is not detected in your system PATH!
    echo The bot will fail to play audio without it.
    echo Please install FFmpeg and ensure the \bin folder is in your environment variables.
    echo ===============================================
    echo Press any key to continue anyway, or close this window.
    pause >nul
)

:: Check for Deno (JavaScript runtime required by yt-dlp)
if not exist "bin\deno.exe" (
    echo ------------------------------------------------
    echo Setting up Deno ^(JavaScript runtime for YouTube extraction^)...
    if not exist "bin" mkdir bin
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/denoland/deno/releases/latest/download/deno-x86_64-pc-windows-msvc.zip' -OutFile 'bin\deno.zip'"
    powershell -Command "Expand-Archive -Path 'bin\deno.zip' -DestinationPath 'bin' -Force"
    del "bin\deno.zip"
    echo Deno setup complete!
    echo ------------------------------------------------
)

:: Add bin folder to PATH for this session so yt-dlp can find deno (and ffmpeg if placed there)
set PATH=%CD%\bin;%PATH%

:: Check if bot script exists
if not exist "%BOT_SCRIPT%" (
    echo Error: %BOT_SCRIPT% not found!
    echo Please make sure the bot script exists in this directory.
    pause
    exit /b 1
)

:: Check if secrets.json exists, if not, prompt for API key and create it
if not exist secrets.json (
    :prompt_token
    echo secrets.json not found. Please enter your Discord application API key:
    set /p BOT_TOKEN=
    if "%BOT_TOKEN%"=="" (
        echo API key cannot be empty. Please try again.
        goto prompt_token
    )
    echo { "BOT_TOKEN": "%BOT_TOKEN%" } > secrets.json
    echo secrets.json created successfully.
)

:: Check if venv exists, if not, create it and install dependencies
if not exist "%VENV_FOLDER%" (
    echo Virtual environment not found. Setting up for first time use...
    
    :: Check if Python is installed
    python --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo Error: Python is not installed or not in PATH
        echo Please install Python 3.8 or higher and try again.
        pause
        exit /b 1
    )
    
    echo ------------------------------------------------
    echo Creating virtual environment...
    python -m venv "%VENV_FOLDER%"
    
    if %errorlevel% neq 0 (
        echo Failed to create virtual environment.
        pause
        exit /b 1
    )
    
    echo Installing required packages...
    :: Added [voice] tag for PyNaCl, and yt-dlp
    call "%VENV_PATH%" && python -m pip install --upgrade pip && pip install "discord.py[voice]" yt-dlp
    
    if %errorlevel% neq 0 (
        echo Failed to install dependencies.
        pause
        exit /b 1
    )
    
    echo ------------------------------------------------
    echo Setup complete! Starting the bot for the first time...
    echo ------------------------------------------------
) else (
    echo Using existing virtual environment at: %VENV_FOLDER%
)

echo Bot script: %BOT_SCRIPT%

:: Main loop that restarts the bot if it crashes
:loop
echo Starting the Discord bot...
echo ------------------------------------------------
echo Date/Time: %date% %time%
echo ------------------------------------------------

:: Activate the virtual environment and run the bot
call "%VENV_PATH%" && python "%BOT_SCRIPT%"

if %errorlevel% equ 2 (
    echo.
    echo ==============================================================================
    echo  ERROR: PRIVILEGED INTENTS REQUIRED
    echo ==============================================================================
    echo.
    echo  Your bot token works, but the bot is missing permissions to read messages
    echo  and view server members.
    echo.
    echo  YOU MUST ENABLE BOTH PRIVILEGED INTENTS FOR YOUR BOT:
    echo  1. Go to: https://discord.com/developers/applications
    echo  2. Click on your bot application.
    echo  3. Go to the "Bot" tab on the left sidebar.
    echo  4. Scroll down to "Privileged Gateway Intents".
    echo  5. Toggle ON "PRESENCE INTENT", "SERVER MEMBERS INTENT", and "MESSAGE CONTENT INTENT".
    echo  6. Click "Save Changes" at the bottom.
    echo.
    echo ==============================================================================
    echo.
    echo Press any key once you have enabled the intents to retry...
    pause >nul
    goto loop
)

:: If the bot exits with an error (non-zero exit code)
echo.
echo Bot has exited or crashed with exit code: %errorlevel%
echo Restarting in 5 seconds...
echo.

:: Wait 5 seconds before restarting
timeout /t 5 /nobreak >nul
goto loop