
source "${HOME}/.zshrc_add"

sshpass -f ${HOME}/.ssh/sch-passwd /sbin/mount_smbfs //gmorto@helens.childrens.sea.kids/active ${HOME}/active
# sshpass -f ${HOME}/.ssh/sch-passwd /sbin/mount_smbfs //gmorto@baker.childrens.sea.kids/archive ${HOME}/archive


# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/homebrew/Caskroom/miniforge/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh" ]; then
        . "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh"
    else
        export PATH="/opt/homebrew/Caskroom/miniforge/base/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

