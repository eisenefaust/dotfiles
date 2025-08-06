#!/bin/bash

PASS=~/.ssh/sch-passwd
PASS2=~/.ssh/sch2-passwd

deploy_dotfiles() {
    local user=$1
    local passfile=$2
    echo "user=$user"
    echo "passfile=$passfile"

    local HOST_LIST=(
        #"login-1.hpc.childrens.sea.kids"
        #"login-2.hpc.childrens.sea.kids"
        "pplvsq01.childrens.sea.kids"
        "rplasc01.childrens.sea.kids"
        "rplweb01.childrens.sea.kids"
        "rdldoc01.childrens.sea.kids"
        #".childrens.sea.kids"
    )
    user_prefix=""
    ELEVATED_USER_PREFIX=("de-" "dd-")
    if [[ " ${ELEVATED_USER_PREFIX[@]} " =~ " ${user:0:3} " ]]; then
        user_prefix="${user:0:3}"
    fi

    for HOST in ${HOST_LIST[@]}; do
        # echo "HOST=${HOST}"
        # echo sshpass -f $passfile scp -r * $user@$HOST:$DEPLOY_DIR || { echo "ERROR: couldn't copy files to $HOST:$DEPLOY_DIR"; exit 1; }
        echo "ssh-keygen -f ~/.ssh/${HOST}_${user_prefix}ed25519 -t ed25519"
        echo "ssh-copy-id -i ~/.ssh/${HOST}_${user_prefix}ed25519 ${user}@${HOST}"
        echo "infocmp -x xterm-ghostty | sshpass -f ${passfile} ssh ${user}@${HOST} -- tic -x -"
        echo ""
    done

    echo "To deploy dotfiles log in as ${user} to ${HOST}, clone this repo into \$HOME and run:"
    echo "cd dotfiles"
    echo "cp .aliases .bash_prompt .zprompt .shared_prompt ../"
    echo "Then copy the appropriate .bashrc or .zshrc chunk into that host's userfile."
    echo "If the .ssh/config is desired, copy to \$HOME/.ssh/config and make any changes."
}

deploy_dotfiles "${USER}" "${PASS}"
deploy_dotfiles "de-${USER}" "${PASS2}"