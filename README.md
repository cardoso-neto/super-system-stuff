# super-system-stuff

My setup scripts, dotfiles, that kind of stuff.

I made this for me, but feel free to have a look around and inspire yourself.

I usually write comments to explain my configs.

## What this is (and is not)

This is a **store of ideas and known-good implementations**, not an installer.
There is deliberately no bootstrap script, no symlink farm, and no package
runner. When I set up a new machine I point a coding agent at this repo and let
it work out how to apply the relevant parts to whatever OS and package manager
that machine has. Maintaining automation that has to stay correct across every
platform I might use costs more than it saves.

So: read these files as reference material. Scripts here record what I ran on a
particular machine at a particular time. Several are stale, and a few never
worked (noted inline where I know about it).

## Layout

Three layers, from most to least general. Later layers override or extend
earlier ones — nothing enforces that, it is just how the content is organised.

```text
shared/     works everywhere, on any OS
os/         everything true of an operating system but not a specific machine
hosts/      facts about one physical computer
docs/       notes that are not config
```

```text
shared/
├── dotfiles/
│   ├── .gitconfig                      identity, aliases, includes ~/.gitconfig.local
│   └── .config/Code/User/settings.json
├── shell/aliases.sh                    valid in both bash and zsh
└── vscode-extensions.sh                extensions are cross-platform
os/
├── ubuntu/
│   ├── dotfiles/{.bashrc,.bash_aliases,.inputrc}
│   ├── install/{apt-installs,snaps,flatpaks,docker-install,git-install,first-boot-installs}.sh
│   └── bin/clean-snaps.sh
└── macos/
    └── dotfiles/{.zshrc,.zprofile,.zshrc.secrets.example}
hosts/
├── gaius/                              the Ubuntu desktop
│   ├── dotfiles/{.gitconfig.local,.config/transmission/settings.json}
│   └── install/rocm-install-amdgpu.sh  AMD GPU: hardware, not OS
└── mbp/                                the MacBook Pro
    └── dotfiles/.gitconfig.local
docs/
├── icons.md
├── ipfs-install.md
└── lost-installers.md
```

Dotfiles mirror their real path under `$HOME`, so
`shared/dotfiles/.config/Code/User/settings.json` belongs at
`~/.config/Code/User/settings.json`. (This replaces an older `_-_` filename
encoding that had to be decoded by a script.)

### Why OS and host are separate

They genuinely diverge. Commit signing is the clearest case: the desktop signs
with a GPG key, this MacBook has no GPG key and signs with SSH instead. Both
machines want the same twelve git aliases. That is one shared file plus two
small per-host files, composed by git's own `[include]` directive — no
templating needed.

Similarly, `rocm-install-amdgpu.sh` is about an AMD GPU rather than about
Ubuntu, and the conda prefix differs per machine
(`/home/gaius/miniconda` vs `/opt/homebrew/Caskroom/miniconda/base`).

## Secrets

Never in this repo. `.gitignore` blocks `*.secrets` and friends; the only
tracked version is `os/macos/dotfiles/.zshrc.secrets.example`, which has empty
values. On the Mac the real file is `~/.zshrc.secrets`, `chmod 600`, sourced by
`.zshrc`.

## Known-broken, kept for the ideas

- `os/ubuntu/install/first-boot-installs.sh` untars JDK archives that no longer
  exist — see [docs/lost-installers.md](docs/lost-installers.md). The `tar`
  lines are otherwise correct now.
- `shared/dotfiles/.gitconfig` has an `ls-non-annexed-files` alias pointing at
  `~/apps/ls-non-annexed-files.sh`, which is not kept here.
- `shared/dotfiles/.config/Code/User/settings.json` hardcodes `java.home` to a
  path on the Ubuntu desktop. It is the one host-specific line in an otherwise
  portable file; VS Code has no include mechanism to split it out.
- The macOS `.zshrc` does not yet source `shared/shell/aliases.sh`, so the git
  aliases are Ubuntu-only in practice.
