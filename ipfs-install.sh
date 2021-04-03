#!/bin/bash

# check https://ipfs.io/ipns/dist.ipfs.io/#ipfs-update for new versions

tar -xzf installers/ipfs-update_v1.7.1_linux-amd64.tar.gz /tmp/ipfs-update
pushd !$
sudo bash /tmp/ipfs-update/install.sh
popd

sudo ipfs-update install latest

# https://github.com/lucas-clemente/quic-go/wiki/UDP-Receive-Buffer-Size
sudo sysctl -w net.core.rmem_max=2500000

ipfs init
ipfs config --json Experimental.FilestoreEnabled true
ipfs config --json Swarm.ConnMgr.LowWater 25
ipfs config --json Swarm.ConnMgr.HighWater 250

pushd /usr/local/src/
git clone https://github.com/ipfs/go-ipfs.git
sudo ln -s /usr/local/src/go-ipfs/misc/completion/ipfs-completion.bash /etc/bash_completion.d/ipfs-completion.bash
popd
