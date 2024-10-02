#!/bin/bash

#----------------------------------------------------------------------->
# Loop sudo to keep script running, then kill sudo after script completes
startsudo() {
    sudo -v
    ( while true; do sudo -v; sleep 50; done; ) &
    SUDO_PID="$!"
    trap stopsudo SIGINT SIGTERM
}
stopsudo() {
    kill "$SUDO_PID"
    trap - SIGINT SIGTERM
    sudo -k
}
#----------------------------------------------------------------------->

#-- Start sudo --#
startsudo

sudo apt update && sudo apt upgrade -y

clear
printf "\n\e[1;32mCreating user directories.\e[0m\n"

# Create user directories
xdg-user-dirs-update
mkdir -p ~/Screenshots/

clear
printf "\n\e[1;32mInstalling core packages.\e[0m\n"

# Function to read core packages from a file
read_core_packages() {
    local core_file="$1"
    if [ -f "$core_file" ]; then
        packages+=( $(< "$core_file") )
    else
        echo "Core file not found: $core_file"
        exit 1
    fi
}
# Read core packages from file
read_core_packages "./core.txt"

# Function to install packages if they are not already installed
install_packages() {
    local pkgs=("$@")
    local missing_pkgs=()

    # Check if each package is installed
    for pkg in "${pkgs[@]}"; do
        if ! dpkg -l | grep -q " $pkg "; then
            missing_pkgs+=("$pkg")
        fi
    done

    # Install missing packages
    if [ ${#missing_pkgs[@]} -gt 0 ]; then
        echo "Installing missing packages: ${missing_pkgs[@]}"
        sudo apt update
        sudo apt install -y "${missing_pkgs[@]}"
        if [ $? -ne 0 ]; then
            echo "Failed to install some packages. Exiting."
            exit 1
        fi
    else
        echo "All required packages are already installed."
    fi
}
# Call function to install packages
install_packages "${packages[@]}"



# Ensure /usr/share/xsessions directory exists
if [ ! -d /usr/share/xsessions ]; then
    sudo mkdir -p /usr/share/xsessions
    if [ $? -ne 0 ]; then
        echo "Failed to create /usr/share/xsessions directory. Exiting."
        exit 1
    fi
fi

sudo apt autoremove

source ./dwm-suckless-tools.sh
