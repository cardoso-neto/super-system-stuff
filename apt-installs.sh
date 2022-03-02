
sudo apt-get install -y adb  # android
sudo apt-get install -y bmon  # network speedometer
sudo apt-get install -y byobu  # terminal application
sudo apt-get install -y cowsay  # echo inside an ASCII cow
sudo apt-get install -y dconf-editor  # gui to edit dconf settings
sudo apt-get install -y encfs  # encrypted file systems
sudo apt-get install -y exfat-utils exfat-fuse  # exfat filesystem stuff
sudo apt-get install -y fonts-firacode  # font with programming ligatures
sudo apt-get install -y fortune  # print a fortune cookie sentence to stdout
sudo apt-get install -y fuse-zip  # mount .zip files quickly https://bitbucket.org/agalanin/fuse-zip
sudo apt-get install -y glances  # system monitor
sudo apt-get install -y git-annex  # suggested: xdot bup magic-wormhole tahoe-lafs uftp youtube-dl
sudo apt-get install -y gitk  # visual tool for git repos
sudo apt-get install -y gnome-tweaks
sudo apt-get install -y gparted  # disk partitioner
sudo apt-get install -y hollywood  # feel like you're a hollywood hacker
sudo apt-get install -y lolcat  # rainbow-colored cat github.com/busyloop/lolcat
sudo apt-get install -y numlockx  # change numlock status programmatically
sudo apt-get install -y python3-nautilus  # add support for python extensions on nautilus
sudo apt-get install -y screenfetch
sudo apt-get install -y sqlitebrowser  # gui to explore sqlite dbs
sudo apt-get install -y texlive-full # http://tug.org/texlive/
sudo apt-get install -y terminator  # better terminal app
sudo apt-get install -y unrar  # support for .rar archives
sudo apt-get install -y xclip  # copy files to the clipboards
sudo apt-get install -y xkbset 

sudo apt-get install 
# one-liner
sudo apt-get install -y \
    adb \
    bmon \
    byobu \
    cowsay \
    dconf-editor \
    encfs \
    exfat-utils exfat-fuse \
    fonts-firacode \
    fortune \
    fuse-zip \
    glances \
    git-annex \
    gitk \
    gnome-tweaks \
    gparted \
    hollywood \
    lolcat \
    numlockx \
    python3-nautilus \
    screenfetch \
    sqlitebrowser \
    texlive-full \
    terminator \
    unrar \
    xclip \
    xkbset


# Brave
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
sudo apt update
sudo apt install brave-browser

# Vivaldi
sudo sh -c 'echo "deb https://repo.vivaldi.com/stable/deb/ stable main" >> /etc/apt/sources.list'
wget -q -O - https://repo.vivaldi.com/stable/linux_signing_key.pub | sudo apt-key add -
sudo apt update
sudo apt install vivaldi-stable

# AppImage Launcher https://github.com/TheAssassin/AppImageLauncher
sudo add-apt-repository ppa:appimagelauncher-team/stable
sudo apt install appimagelauncher

# sudo add-apt-repository -y ppa:alessandro-strada/google-drive-ocamlfuse-beta  # https://github.com/astrada/google-drive-ocamlfuse
# sudo apt-get install -y google-drive-ocamlfuse  # mount GDrive 

sudo apt-add-repository -y ppa:cappelikan/ppa  # mainline (ukuu fork)
sudo apt-get install -y mainline  # ubuntu kernel update utility (ukuu) replacement

sudo add-apt-repository -y ppa:git-core/ppa  # latest git
sudo apt-get install -y git

sudo add-apt-repository -y ppa:bashtop-monitor/bashtop  # bashtop
sudo apt-get install -y bashtop # system monitor

sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test # so we can grab the latest versions of gcc https://wiki.ubuntu.com/ToolChain
sudo apt-get install -y gcc-10  # recent gnu c compiler
# using multiple gcc versions https://linuxize.com/post/how-to-install-gcc-compiler-on-ubuntu-18-04/
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 100

sudo apt install flatpak gnome-software-plugin-flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
