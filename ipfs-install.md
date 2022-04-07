# IPFS guide

## install

Check out [ipfs.io/ipns/dist.ipfs.io/#ipfs-update](https://ipfs.io/ipns/dist.ipfs.io/#ipfs-update) for new versions.

```bash
mkdir /tmp/ipfs-update
tar -xzf installers/ipfs-update_v1.8.0_linux-amd64.tar.gz -C !$
pushd !$
sudo bash ./install.sh
popd

sudo ipfs-update install latest
```

## setup

```bash
# create keys and initialize datastore
ipfs init
# link data over to datastore instead of copying
ipfs config --json Experimental.FilestoreEnabled true

# limit simultaneous peers so save on bandwidth
ipfs config --json Swarm.ConnMgr.LowWater 25
ipfs config --json Swarm.ConnMgr.HighWater 250
```

On [github.com/lucas-clemente/quic-go/wiki/UDP-Receive-Buffer-Size](https://github.com/lucas-clemente/quic-go/wiki/UDP-Receive-Buffer-Size) you'll see the Linux kernel has a low buffer size for UDP packets which limit the bandwidth on large trasnfer due to the overhead wasted on many smaller packets.

```bash
sudo sysctl -w net.core.rmem_max=2500000
```

Install CLI bash completion as described on [github.com/ipfs/go-ipfs/blob/794...4ff/docs/command-completion.md](https://github.com/ipfs/go-ipfs/blob/79403716bf52bd6f8aa288d709217b4b2c5f04ff/docs/command-completion.md): 

```bash
echo 'eval "$(ipfs commands completion bash)"' >> ~/.bashrc
```

## connecting to other nodes

Use `ipfs id` and copy one of the public addresses.
On the node you want to connect, you can add a peer temporarily or permanently.

Temporarily with:

```bash
ipfs swarm connect <multiaddr>
```

Permanently with:

```bash
ipfs bootstrap add <multiaddr>
```
