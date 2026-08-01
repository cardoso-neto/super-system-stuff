# Lost installers

`installers/` used to hold eight large binaries tracked with
[git-annex](https://git-annex.branchable.com/). Only the pointer symlinks were
ever pushed to GitHub — the annex content lived on the Ubuntu desktop and was
never replicated to a remote this repo can reach. A fresh clone therefore gets
eight dangling symlinks and zero bytes of payload.

Removed from the tree on 2026-08-01. Nothing here was worth chasing: every item
is freely downloadable, and all of them are years stale (JDK 8/11/14, NVIDIA
450/455, a 2020 Steam package). They are recorded here purely so a stray copy
found on an old disk can be identified rather than guessed at.

`os/ubuntu/install/first-boot-installs.sh` still untars four of these JDK
archives. That part of the script has been dead since the annex content went
missing — treat it as a description of intent, not a runnable step.

## What they were

Sizes and checksums come from the git-annex `SHA256E` keys, which embed both.
To identify a candidate file: `sha256sum <file>` on Linux, `shasum -a 256 <file>`
on macOS.

| file | size | sha256 |
| --- | ---: | --- |
| `ipfs-update_v1.7.1_linux-amd64.tar.gz` | 6.5 MiB | `4e10768dfe9955bb04191b32ad31164958d7c88b0f4bb5a20fa6318f04565be2` |
| `JD2Setup_x64.sh` | 48.3 MiB | `ddd1a997afaf60c981fbfb1a1f3a600ff7bad7fccece9f2508fb695b8c2f153d` |
| `jre-8u261-linux-x64.tar.gz` | 85.5 MiB | `53e33ba35b1a8b799e1be943155c7b3c56a56a82956ddcf5d774325eca1df812` |
| `NVIDIA-Linux-x86_64-450.57.run` | 136.0 MiB | `d50c77fc4fda2a5c5ab2af64524da8a3214077bd7daf0dbf7c1986e0ca05d711` |
| `NVIDIA-Linux-x86_64-455.28.run` | 161.1 MiB | `e4e1499b15aedc7c0b5c0d30c170858ed1625ab2701d3bb11747ac8c8371da0f` |
| `OpenJDK11U-jdk_x64_linux_hotspot_11.0.8_10.tar.gz` | 184.4 MiB | `6e4cead158037cb7747ca47416474d4f408c9126be5b96f9befd532e0a762b47` |
| `OpenJDK14U-jdk_x64_linux_hotspot_14.0.2_12.tar.gz` | 201.0 MiB | `7d5ee7e06909b8a99c0d029f512f67b092597aa5b0e78c109bd59405bbfa74fe` |
| `steam_2020.10.09.deb` | 2.8 MiB | `8ddbb20ddf89c494f09446e4e2df788f8e13abe6cd601860c0c968094baffbaf` |

Total: roughly 815 MiB, none of it ever present in this clone.

## If you want binaries in here again

`git-annex` is in `os/ubuntu/install/apt-installs.sh`, so the desktop has it.
The failure last time was not annex itself but the absence of a second copy —
annex only tracks *where* content lives, and there was only ever one where.
Adding a remote (an external drive counts) before annexing anything would be
enough to avoid a repeat.
