mkdir ~/apps

sudo add-apt-repository -y ppa:git-core/ppa  # latest git
sudo apt-add-repository -y ppa:cappelikan/ppa  # mainline (ukuu fork)
sudo add-apt-repository -y ppa:alessandro-strada/google-drive-ocamlfuse-beta  # https://github.com/astrada/google-drive-ocamlfuse

sudo apt-get --install-suggests install -y \
	bmon \  # network speedometer
	byobu \  # terminal application
	cowsay \  # echo inside an ASCII cow
	fortune \
	google-drive-ocamlfuse git git-annex gparted \
	hollywood \  # feel like you're a hollywood hacker
	lolcat \  # rainbow-colored cat github.com/busyloop/lolcat
	mainline \  # ubuntu kernel update utility (ukuu) replacement
	numlockx \  # change numlock status programmatically
	python-nautilus \  # add support for python extensions on nautilus
	screenfetch sqlitebrowser \
	terminator \  # better terminal app
	unrar \  # support for .rar archives
	xclip xkbset


sudo snap install --classic code
sudo snap install --classic shotcut
sudo snap install --classic sublime-text
sudo snap install \
	chromium code \
	gimp htop plexmediaserver postman spotify vlc youtube-dl


# Change GtkIMContextSimple (emoji input) from "['<Control><Shift>e']"
# so it won't interfere with Terminator's vertical split shortcut
gsettings set org.freedesktop.ibus.panel.emoji hotkey "['<Control><Shift>j']"


# install Anaconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/Downloads/miniconda.sh
bash ~/Downloads/miniconda.sh -b -p $HOME/miniconda
rm ~/Downloads/miniconda.sh
~/miniconda/bin/conda init
bash

pip install \
	black \
	gpustat \
	pylint


# these two should be equivalent
sudo apt-get install python3-gi
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


# JDownloader installation
bash ./installers/JD2Setup_x64.sh


# code extensions
code --install-extension ms-python.python
code --install-extension njpwerner.autodocstring
code --install-extension njqdev.vscode-python-typehint
code --install-extension CoenraadS.bracket-pair-colorizer-2
code --install-extension Tyriar.sort-lines  # github.com/Tyriar/vscode-sort-lines

