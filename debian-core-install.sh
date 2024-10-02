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

sleep 2

# Ensure /usr/share/xsessions directory exists
if [ ! -d /usr/share/xsessions ]; then
    sudo mkdir -p /usr/share/xsessions
    if [ $? -ne 0 ]; then
        echo "Failed to create /usr/share/xsessions directory. Exiting."
        exit 1
    fi
fi

clear
printf "\n\e[1;32mInstalling dwm.\e[0m\n"

## Get dwm and suckless-tools source from debian
mkdir -p $HOME/.config/suckless
(cd $HOME/.config/suckless; apt source dwm)
(cd $HOME/.config/suckless; rm -rf *.tar.gz *.tar.xz *.dsc)

# Install dwm
(
cd $HOME/.config/suckless/dwm*;
        if make; then
            make_success=true
        fi
        if $make_success; then
            break
        fi
)
(
cd $HOME/.config/suckless/dwm*;
        if sudo make install clean; then
            install_success=true
        fi
        if $install_success; then
            break
        fi
)

sleep 2

# install Vim and Neovim


# set up flatpak
sudo apt install flatpak
sudo apt install gnome-software-plugin-flatpak
flatpak remote-add --if-not-exists --subset=verified flathub https://dl.flathub.org/repo/flathub.flatpakrepo

sleep 2

# Enable and disable services
sudo systemctl stop avahi-daemon.socket
sudo systemctl disable avahi-daemon.socket
sudo systemctl mask avahi-daemon.socket
sudo systemctl stop avahi-daemon.service
sudo systemctl disable avahi-daemon.service
sudo systemctl mask avahi-daemon.service
sudo systemctl enable acpid

# Cleanup
sudo apt autoremove
sudo apt autoclean

#-- Kill sudo --#
stopsudo

printf "\n\e[1;32mYou can now reboot!\e[0m\n"
