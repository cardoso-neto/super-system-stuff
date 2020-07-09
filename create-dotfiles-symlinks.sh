dotfiles_folder=$(realpath ./dotfiles)

ln -nfs "${dotfiles_folder}/.bash_aliases" ~/.bash_aliases;
ln -nfs "${dotfiles_folder}/.bashrc" ~/.bashrc;
ln -nfs "${dotfiles_folder}/.gitconfig" ~/.gitconfig;
ln -nfs "${dotfiles_folder}/.inputrc" ~/.inputrc;

source ~/.bashrc;

# todo: use rsync -avh maybe? idk


