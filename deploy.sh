#!/bin/bash

PASS=~/.ssh/sch-passwd
PASS2=~/.ssh/sch2-passwd
PASS3=~/.ssh/rsc-auto-passwd
PASS4=~/.ssh/rsc-log-passwd

ELEVATED_USER_PREFIX=("de-" "dd-")

PRIMARY_USER=${USER}

HOST_LIST=(
    "login-1.hpc.childrens.sea.kids"
    "login-2.hpc.childrens.sea.kids"
    "pplvsq01.childrens.sea.kids"
    "pplvdb01.childrens.sea.kids"
    "rplasc01.childrens.sea.kids"
    "rplweb01.childrens.sea.kids"
    "rdldoc01.childrens.sea.kids"
    # "rplitl01.childrens.sea.kids"
    #".childrens.sea.kids"
)

deploy() {
    local user=$1
    local passfile=$2
    echo "user=$user"
    echo "passfile=$passfile"

    user_prefix=""
    key_comment=""
    if [[ " ${ELEVATED_USER_PREFIX[@]} " =~ " ${user:0:3} " ]]; then
        # use elevated user prefix as prefix for the ssh key
        user_prefix="${user:0:3}"
        key_comment="${user}@"
    elif [[ "${user}" != ${PRIMARY_USER} ]]; then
        # use entire svc account name as prefix for the ssh key
        user_prefix="${user}-"
        key_comment="${user}@"
    fi
    key_comment="${key_comment}${USER}@$(hostname)"

    for host in ${HOST_LIST[@]}; do
        # echo "host=${host}"
        # echo sshpass -f $passfile rsync -czPr * $user@$host:$DEPLOY_DIR || { echo "ERROR: couldn't copy files to $host:$DEPLOY_DIR"; exit 1; }
        # echo "infocmp -x xterm-ghostty | sshpass -f ${passfile} ssh ${user}@${host} -- tic -x -"
        # echo "sshpass -f ${passfile} ssh ${user}@${host}"
        echo "ssh-keygen -C ${key_comment}@${host} -f ~/.ssh/${user_prefix}${host}_ed25519 -t ed25519"
        echo "sshpass -f ${passfile} ssh-copy-id -i ~/.ssh/${user_prefix}${host}_ed25519 ${user}@${host}"
        echo "echo \"IdentityFile ~/.ssh/${user_prefix}${host}_ed25519\""
    done

    echo "To deploy dotfiles log in as ${user} to ${host}, clone this repo into \$HOME and run:"
    echo "cd dotfiles"
    echo "rsync -czP .aliases .bash_prompt .zprompt .shared_prompt ../   or"
    echo "rsync -czP .aliases .bash_prompt .zprompt .shared_prompt ${user}@${host}:~/"
    echo "Then copy the appropriate .bashrc or .zshrc chunk into that host's userfile."
    echo "If the .ssh/config is desired, copy to \$HOME/.ssh/config and make any changes."
}

deploy "${USER}" "${PASS}"
deploy "de-${USER}" "${PASS2}"
deploy "svc_rsc_hpc_auto" "${PASS3}"
deploy "svc_rsc_hpc_log" "${PASS4}"