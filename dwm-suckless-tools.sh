#!/bin/bash


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

# Enable and disable services
sudo systemctl stop avahi-daemon.socket
sudo systemctl disable avahi-daemon.socket
sudo systemctl mask avahi-daemon.socket
sudo systemctl stop avahi-daemon.service
sudo systemctl disable avahi-daemon.service
sudo systemctl mask avahi-daemon.service
sudo systemctl enable acpid


# Ensure /usr/share/xsessions directory exists
if [ ! -d /usr/share/xsessions ]; then
    sudo mkdir -p /usr/share/xsessions
    if [ $? -ne 0 ]; then
        echo "Failed to create /usr/share/xsessions directory. Exiting."
        exit 1
    fi
fi

sudo apt autoremove

#-- Kill sudo --#
stopsudo

printf "\n\e[1;32mYou can now reboot!\e[0m\n"

