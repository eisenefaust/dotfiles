#!/usr/bin/env zsh
############################
# This files backs up dot files that will be overwritten by symlinks 
# This script creates symlinks from the home directory to any desired dotfiles in $HOME/dotfiles
# And also installs Homebrew Packages and Casks (Apps)
# And also sets up VS Code
############################

# dotfiles directory
dotfiledir="${HOME}/dotfiles"

# list of files/folders to symlink in ${homedir}
files=(.zshrc_add .zprompt .zshrc .bashrc_add .bash_prompt .bashrc .shared_prompt .aliases)
# tmux/.config/tmux.conf)

# change to the dotfiles directory
echo "Changing to the ${dotfiledir} directory"
cd "${dotfiledir}" || exit

# create symlinks (will overwrite old dotfiles)
for file in "${files[@]}"; do
    if [ -f ${HOME}/$file ] && [ ! -L ${HOME}/$file ]; then
        # move real file to backup dir if they exist
        mkdir -p ${HOME}/dotfiles.bkup
        mv ${HOME}/$file ${HOME}/dotfiles.bkup/
    fi
    ln -sf "${dotfiledir}/${file}" "${HOME}/${file}"
done

# Run the Homebrew Script
# gets stow for below step
./brew.sh

# echo "stow: ${files[@]}"
# stow -t ~ "${files[@]}"

config_dirs=(tmux)
# use stow to create symlinks for .config dirs (will overwrite old .config dirs)
for config_dir in "${config_dirs[@]}"; do
    if [ -d ${HOME}/.config/$config_dir ] && [ ! -L ${HOME}/.config/$config_dir ]; then
        # move real file to backup dir if they exist
        mkdir -p ${HOME}/dotfiles.bkup/.config/$config_dir
        cp -R ${HOME}/.config/$config_dir ${HOME}/dotfiles.bkup/.config/$config_dir
        rm -r ${HOME}/.config/$config_dir
    fi
    echo "stow: $config_dir"
    stow -t ~ $config_dir
done

# Run VS Code Script
./vscode.sh

#.zshrc contents
# source .zshrc_add
# sshpass -f ~/.ssh/sch-passwd /sbin/mount_smbfs //${USER}@helens.childrens.sea.kids/active ~/active
# sshpass -f ~/.ssh/sch-passwd /sbin/mount_smbfs //${USER}@baker.childrens.sea.kids/archive ~/archive
echo "Installation Complete!"