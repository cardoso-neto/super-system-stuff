sudo add-apt-repository ppa:git-core/ppa

sudo apt-get install -y \
	byobu \
	cowsay \
	fortune \
	git git-annex \
	lolcat \
	screenfetch \
	terminator \
	xclip xkbset

sudo snap install --classic code
sudo snap install --classic shotcut
sudo snap install \
code chromium vlc spotify gimp htop postman youtube-dl plexmediaserver


# set mouse speed when using the Universal Access Mouse Keys feature
xkbset ma 60 10 10 20 10

# Change GtkIMContextSimple (emoji input) from "['<Control><Shift>e']"

# so it won't interfere with Terminator's vertical split shortcut
gsettings set org.freedesktop.ibus.panel.emoji hotkey "['<Control><Shift>j']"

# install nautilus-copypath extension to add "copy path" to the context menu of a file
sudo apt-get install python-nautilus python3-gi  # installing gi here avoids a pip install PyGObject; right now, we don't have pip
mkdir ~/apps
pushd !$
git clone https://github.com/ronen25/nautilus-copypath nautilus-copypath
pushd !$
mkdir ~/.local/share/nautilus-python
mkdir ~/.local/share/nautilus-python/extensions
cp nautilus-copypath.py ~/.local/share/nautilus-python/extensions/
cp nautilus-copywinpath.py ~/.local/share/nautilus-python/extensions/
popd
popd

# restart nautilus for py-extensions to reload
nautilus -q

# install Anaconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh
bash ~/miniconda.sh -b -p $HOME/miniconda
rm ~/anaconda.sh
~/miniconda/bin/conda init
bash
conda --version
