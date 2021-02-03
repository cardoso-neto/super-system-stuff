set -x

mkdir ~/apps

sudo add-apt-repository -y ppa:alessandro-strada/google-drive-ocamlfuse-beta  # https://github.com/astrada/google-drive-ocamlfuse
# sudo add-apt-repository -y ppa:bashtop-monitor/bashtop  # bashtop
sudo apt-add-repository -y ppa:cappelikan/ppa  # mainline (ukuu fork)
sudo add-apt-repository -y ppa:git-core/ppa  # latest git
sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test # so we can grab the latest versions of gcc https://wiki.ubuntu.com/ToolChain

sudo apt-get install -y \
	adb \  # android
	# bashtop \ # system monitor
	bmon \  # network speedometer
	byobu \  # terminal application
	cowsay \  # echo inside an ASCII cow
	dconf-editor \  # gui to edit dconf settings
	exfat-utils exfat-fuse \  # exfat filesystem stuff
	fortune \  # print a fortune cookie sentence to stdout
	fuse-zip \  # mount .zip files quickly https://bitbucket.org/agalanin/fuse-zip
	gcc-10 \  # recent gnu c compiler
	glances \  # system monitor
	google-drive-ocamlfuse \  # mount GDrive 
	git \
	git-annex \  # suggested: xdot bup magic-wormhole tahoe-lafs uftp youtube-dl
	gitk \
	gparted \  # disk partitioner
	hollywood \  # feel like you're a hollywood hacker
	lolcat \  # rainbow-colored cat github.com/busyloop/lolcat
	mainline \  # ubuntu kernel update utility (ukuu) replacement
	numlockx \  # change numlock status programmatically
	python-nautilus \  # add support for python extensions on nautilus
	screenfetch \
	sqlitebrowser \  # gui to explore sqlite dbs
	texlive-full \ # http://tug.org/texlive/
	terminator \  # better terminal app
	tor \
	unrar \  # support for .rar archives
	xclip \
	xkbset \


# docker stuff
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get install docker-ce docker-ce-cli containerd.io

# docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.28.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod ug+x /usr/local/bin/docker-compose


sudo snap install --classic code
sudo snap install --classic shotcut
sudo snap install --classic slack
sudo snap install --classic sublime-text

sudo snap install \
	chromium code \
	gimp gnome-system-monitor \
	htop \
	plexmediaserver postman \
	spotify \
	tree \  # directory listing tool
	vlc \
	youtube-dl


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
conda create --name main --channel conda-forge python=3.8 git=2.28 git-annex=*=alldep*

pip install \
	black \
	gpustat \
	pylint


# these two should be equivalent
# sudo apt-get install python3-gi
pip install --user PyGObject

# install nautilus-copypath extension to add "copy path" to the context menu of a file
pushd ~/apps
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


# code extensions
code --install-extension CoenraadS.bracket-pair-colorizer-2
code --install-extension eamodio.gitlens  # git lens
code --install-extension editorconfig.editorconfig
code --install-extension haskell.haskell
code --install-extension james-yu.latex-workshop  # https://github.com/James-Yu/LaTeX-Workshop
code --install-extension magicstack.Chromodynamics  # https://github.com/MagicStack/Chromodynamics
code --install-extension magicstack.magicpython  # https://github.com/MagicStack/MagicPython
code --install-extension mhutchie.git-graph  # https://github.com/mhutchie/vscode-git-graph
code --install-extension ms-python.python
code --install-extension ms-vsliveshare.vsliveshare  # official liveshare
code --install-extension njpwerner.autodocstring
code --install-extension njqdev.vscode-python-typehint
code --install-extension Tyriar.sort-lines  # https://github.com/Tyriar/vscode-sort-lines
code --install-extension vscjava.vscode-java-pack  # Java Extension Pack


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
