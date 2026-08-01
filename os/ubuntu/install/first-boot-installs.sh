set -x

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
tar -xzf ./installers/openjdk-17.0.2_linux-x64_bin.tar.gz -C !$

# JDownloader installation
bash ./installers/JD2Setup_x64.sh
# use ~/.local/share/jd2 as the installation directory
# copy the previous ~/.local/share/jd2/cfg dir contents to the new one


# install nvm to manage npm/node.js
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
bash
nvm install node  # install latest node.js and npm


# Haskell env manager. Interactive installer
sudo apt install \
	build-essential libffi-dev libffi8ubuntu1 libgmp-dev \
	libgmp10 libncurses-dev libncurses5 libtinfo5

curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh


# rclone https://rclone.org/install/
curl https://rclone.org/install.sh | sudo bash
