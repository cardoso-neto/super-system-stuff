local_dir=$(realpath ./dotfiles)
usr_dir=/usr/local/dotfiles

mkdir -p ~/.config/Code/User/
sudo mkdir ${usr_dir}

sudo ln "${local_dir}/.inputrc" "${usr_dir}/.inputrc"
ln -nfs !$ ~/.inputrc

sudo ln "${local_dir}/.config_-_Code_-_User_-_settings.json" "${usr_dir}/.config_-_Code_-_User_-_settings.json"
ln -nfs !$ ~/.config/Code/User/settings.json

dotfile=".config_-_transmission_-_settings.json"
destination=${dotfile//_-_/\/}  # change '_-_' to '/'
sudo ln "${local_dir}/${dotfile}" "${usr_dir}/${dotfile}"
ln -nfs !$ ~/${destination}

dotfile="/.gitconfig"
sudo ln "${local_dir}/${dotfile}" "${usr_dir}/${dotfile}"
ln -nfs !$ ~/${destination}


ln -nfs "${local_dir}/.bash_aliases" ~/.bash_aliases;
ln -nfs "${local_dir}/.bashrc" ~/.bashrc;

source ~/.bashrc ;
