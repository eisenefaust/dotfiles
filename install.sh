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
files=(zshrc_add zprompt bashrc_add bash_prompt shared_prompt aliases)
# tmux/.config/tmux.conf)

# change to the dotfiles directory
echo "Changing to the ${dotfiledir} directory"
cd "${dotfiledir}" || exit

# create symlinks (will overwrite old dotfiles)
for file in "${files[@]}"; do
    if [ -f ${HOME}/.$file ] && [ ! -L ${HOME}/.$file ]; then
        # move real file to backup dir
        mkdir -p ${HOME}/dotfiles.bkup
        mv ${HOME}/.$file ${HOME}/dotfiles.bkup/
    fi
    ln -sf "${dotfiledir}/.${file}" "${HOME}/.${file}"
done
# echo "rsync -czP .aliases .bash_prompt .zprompt .shared_prompt tmux/.config/.tmux.conf ${user}@${host}:~/"

# Run the Homebrew Script
./brew.sh

# Run VS Code Script
./vscode.sh

echo "Installation Complete!"