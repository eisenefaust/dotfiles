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
    "rplweb01.childrens.sea.kids"
    "rdldoc01.childrens.sea.kids"
    "pplvsq01.childrens.sea.kids"
    "pplvdb01.childrens.sea.kids"
    "rplasc01.childrens.sea.kids"
    # "rplitl01.childrens.sea.kids"
    #".childrens.sea.kids"
)

HOST_SHORT_LIST=(
    "sasquatch-1"
    "sasquatch"
    "gonzo"
    "bunsen"
    "pplvsq01"
    "pplvdb01"
    "rplasc01"
    # # ["rplitl01.childrens.sea.kids"]="rplitl01"
    # #".childrens.sea.kids"
)

host_template() {
    local host=$1
    local host_short=$2
    local user=$3
    local id_file=$4

    # echo "host_short=${host_short}"
    if [[ ${user} == *"svc"*"auto" ]]; then
        host_short="svc-${host_short}"
    elif [[ ${user} == *"svc"*"log" ]]; then
        host_short="svcl-${host_short}"
    fi
    echo "Host ${host_short}"
    echo "    HostName ${host}"
    echo "    SetEnv TERM=xterm-256color"
    echo "    User ${user}"
    echo "    Port 22"
    echo "    PreferredAuthentications publickey"
    echo "    IdentityFile ${id_file}"
    echo ""
}

fingerprint() {
    local user=$1
    local passfile=$2
    local skip_hpc=$3
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

    for idx in ${!HOST_LIST[@]}; do
        # echo "idx=${idx}"
        local host=${HOST_LIST[${idx}]}
        local host_short=${HOST_SHORT_LIST[${idx}]}
        echo "host=${host}"
        echo "host_short=${host_short}"
        echo "skip_hpc=${skip_hpc}"
        if [[ "${skip_hpc}" == "skip_hpc" ]] && [[ "${host}" == *".hpc.childrens.sea.kids" ]]; then
            continue
        fi
        local id_file="~/.ssh/${user_prefix}${host}_ed25519"

        # -R removes all keys from host
        echo "ssh-keygen -R ${host} -C ${key_comment}@${host} -f ${id_file} -t ed25519"
        echo "ssh-keyscan -Ht ed25519 ${host} >> ~/.ssh/known_hosts"
        echo "sshpass -f ${passfile} ssh-copy-id -i ${id_file} ${user}@${host}"
        echo "rsync -czP .aliases .bash_prompt .zprompt .shared_prompt ${user}@${host}:~/"
        # echo "echo \"IdentityFile ${id_file}\""
        host_template ${host} ${host_short} ${user} ${id_file} >> config
    done
}

deploy() {
    local user=$1
    local passfile=$2
    local skip_hpc=$3
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
        echo "host=${host}"
        echo "skip_hpc=${skip_hpc}"
        if [[ "${skip_hpc}" == "skip_hpc" ]] && [[ "${host}" == *".hpc.childrens.sea.kids" ]]; then
            continue
        fi
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
fingerprint "${USER}" "${PASS}"
fingerprint "${USER}" "${PASS}"
fingerprint "de-${USER}" "${PASS2}" "skip_hpc"
fingerprint "svc_rsc_hpc_auto" "${PASS3}"
fingerprint "svc_rsc_hpc_log" "${PASS4}"
cat ./config

# echo "look at $(pwd)/config and deploy if valid"
# deploy "${USER}" "${PASS}"
# deploy "de-${USER}" "${PASS2}" "skip_hpc"
# deploy "svc_rsc_hpc_auto" "${PASS3}"
# deploy "svc_rsc_hpc_log" "${PASS4}"