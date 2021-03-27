set -x


sudo apt-get install -y adb  # android
# sudo add-apt-repository -y ppa:bashtop-monitor/bashtop  # bashtop
# sudo apt-get install -y bashtop \ # system monitor
sudo apt-get install -y bmon  # network speedometer
sudo apt-get install -y byobu  # terminal application
sudo apt-get install -y cowsay  # echo inside an ASCII cow
sudo apt-get install -y dconf-editor  # gui to edit dconf settings
sudo apt-get install -y exfat-utils exfat-fuse  # exfat filesystem stuff
sudo apt install fonts-firacode  # font with programming ligatures
sudo apt-get install -y fortune  # print a fortune cookie sentence to stdout
sudo apt-get install -y fuse-zip  # mount .zip files quickly https://bitbucket.org/agalanin/fuse-zip
sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test # so we can grab the latest versions of gcc https://wiki.ubuntu.com/ToolChain
sudo apt-get install -y gcc-10  # recent gnu c compiler
sudo add-apt-repository -y ppa:git-core/ppa  # latest git
sudo apt-get install -y git
sudo apt-get install -y glances  # system monitor
sudo add-apt-repository -y ppa:alessandro-strada/google-drive-ocamlfuse-beta  # https://github.com/astrada/google-drive-ocamlfuse
sudo apt-get install -y google-drive-ocamlfuse  # mount GDrive 
sudo apt-get install -y git-annex  # suggested: xdot bup magic-wormhole tahoe-lafs uftp youtube-dl
sudo apt-get install -y gitk  # visual tool for git repos
sudo apt-get install -y gparted  # disk partitioner
sudo apt-get install -y hollywood  # feel like you're a hollywood hacker
sudo apt-get install -y lolcat  # rainbow-colored cat github.com/busyloop/lolcat
sudo apt-add-repository -y ppa:cappelikan/ppa  # mainline (ukuu fork)
sudo apt-get install -y mainline  # ubuntu kernel update utility (ukuu) replacement
sudo apt-get install -y numlockx  # change numlock status programmatically
sudo apt-get install -y python-nautilus  # add support for python extensions on nautilus
sudo apt-get install -y screenfetch
sudo apt-get install -y sqlitebrowser  # gui to explore sqlite dbs
sudo apt-get install -y texlive-full # http://tug.org/texlive/
sudo apt-get install -y terminator  # better terminal app
sudo apt-get install -y tor
sudo apt-get install -y unrar  # support for .rar archives
sudo apt-get install -y xclip  # copy files to the clipboards
sudo apt-get install -y xkbset 


sudo snap install --classic code
sudo snap install --classic shotcut
sudo snap install --classic slack
sudo snap install --classic sublime-text

sudo snap install chromium
sudo snap install gimp 
sudo snap install gnome-system-monitor
sudo snap install htop
sudo snap install insomnia  # http testing tool like Postman
sudo snap install plexmediaserver
sudo snap install postman
sudo snap install spotify
sudo snap install telegram-desktop
sudo snap install tree  # directory listing tool
sudo snap install vlc
sudo snap install youtube-dl


# using multiple gcc versions https://linuxize.com/post/how-to-install-gcc-compiler-on-ubuntu-18-04/
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 100


# Change GtkIMContextSimple (emoji input) from "['<Control><Shift>e']"
# so it won't interfere with Terminator's vertical split shortcut
gsettings set org.freedesktop.ibus.panel.emoji hotkey "['<Control><Shift>j']"


# install Anaconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/Downloads/miniconda.sh
bash ~/Downloads/miniconda.sh -b -p $HOME/miniconda
rm ~/Downloads/miniconda.sh
~/miniconda/bin/conda init
bash

# latest git-annex built straight from Joey's tarballs
conda create --name main --channel conda-forge python=3.8 git git-annex=*=alldep*

pip install \
	black \
	gpustat \
	pylint


# these two should be equivalent
# sudo apt-get install python3-gi
pip install --user PyGObject

# install nautilus-copypath extension to add "copy path" to the context menu of a file
pushd /usr/local/src
git clone https://github.com/ronen25/nautilus-copypath nautilus-copypath
mkdir -p ~/.local/share/nautilus-python/extensions
cp ./nautilus-copypath/nautilus-copypath.py ~/.local/share/nautilus-python/extensions/
popd

# https://github.com/Stunkymonkey/nautilus-open-any-terminal
pip install --user nautilus-open-any-terminal
glib-compile-schemas ~/.local/share/glib-2.0/schemas/
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal terminator

# restart nautilus for py-extensions to reload
nautilus -q


# Java runtime environment
mkdir -p ~/.local/java/
tar -xzf ./installers/jre-8u261-linux-x64.tar.gz -C !$
tar -xzf ./installers/OpenJDK11U-jdk_x64_linux_hotspot_11.0.8_10.tar.gz -C !$
tar -xzf ./installers/OpenJDK14U-jdk_x64_linux_hotspot_14.0.2_12.tar.gz -C !$


# JDownloader installation
bash ./installers/JD2Setup_x64.sh


# install nvm to manage npm/node.js
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
bash
nvm install node  # install latest node.js and npm


# install, init, and configure IPFS client
tar -xzf ./installers/go-ipfs_v0.6.0_linux-amd64.tar.gz /tmp/go-ipfs
sudo bash /tmp/go-ipfs/install.sh
ipfs init
ipfs config --json Experimental.FilestoreEnabled true
ipfs config --json Swarm.ConnMgr.LowWater 25
ipfs config --json Swarm.ConnMgr.HighWater 250


# Haskell env manager. Interactive installer
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh

# rclone https://rclone.org/install/
curl https://rclone.org/install.sh | sudo bash
