dotfiles_folder=$(realpath ./dotfiles)

mkdir -p ~/.config/Code/User/

ln -nfs "${dotfiles_folder}/.config_-_Code_-_User_-_settings.json" ~/.config/Code/User/settings.json
ln -nfs "${dotfiles_folder}/.config_-_transmission_-_settings.json" ~/.config/transmission/settings.json
ln -nfs "${dotfiles_folder}/.bash_aliases" ~/.bash_aliases;
ln -nfs "${dotfiles_folder}/.bashrc" ~/.bashrc;
ln -nfs "${dotfiles_folder}/.gitconfig" ~/.gitconfig;
ln -nfs "${dotfiles_folder}/.inputrc" ~/.inputrc;

source ~/.bashrc;
