exit
mkdir ~/apps

sudo add-apt-repository ppa:git-core/ppa  # latest git
sudo apt-add-repository -y ppa:cappelikan/ppa  # mainline (ukuu fork)

sudo apt-get --install-suggests install -y \
	bmon \
	byobu \
	cowsay \
	fortune \
	git git-annex gparted \
	hollywood \
	lolcat \
	mainline \
	numlockx \
	screenfetch sqlitebrowser \
	terminator \
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
conda --version

pip install black gpustat pylint

# add support for python extensions
sudo apt-get install python-nautilus

# these two are equivalent
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

bash ./installers/JD2Setup_x64.sh
