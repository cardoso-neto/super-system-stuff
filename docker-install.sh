#!/bin/bash

sudo apt-get install -y \
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

# docker-compose: i know it looks hacky, but trust me lol
destination=/usr/local/bin/docker-compose
export version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
sudo curl -L "https://github.com/docker/compose/releases/download/${version}/docker-compose-$(uname -s)-$(uname -m)" -o ${destination}
sudo chmod ug+x ${destination}
sudo chown $USER:$USER ${destination}

# so you won't need sudo all the time
sudo groupadd docker # may already exists but it's ok
sudo usermod -aG docker $USER

# if you can't logout and log back in, use this
newgrp docker
