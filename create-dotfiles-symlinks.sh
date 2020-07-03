dotfiles_folder=$(realpath ./dotfiles)

ln -nfs "${dotfiles_folder}/.gitconfig" ~/.gitconfig;
ln -nfs "${dotfiles_folder}/.bash_aliases" ~/.bash_aliases;

source ~/.bashrc;

# todo: use rsync -avh maybe? idk


