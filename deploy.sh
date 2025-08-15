#!/bin/bash

PASS=~/.ssh/sch-passwd
PASS2=~/.ssh/sch2-passwd
PASS3=~/.ssh/rsc-auto-passwd
PASS4=~/.ssh/rsc-log-passwd

ELEVATED_USER_PREFIX=("de-" "dd-")

PRIMARY_USER=${USER}

HOST_LIST=()

HOST_SHORT_LIST=()

read_hosts() {
    while IFS=' '
    read -r host short; do 
        # if line starts with a "#" to mark a comment
        if [[ "${host}" == "#"* ]]; then
            continue
        fi
        HOST_LIST+=("${host}")
        HOST_SHORT_LIST+=("${short}")
    done < "hosts.txt"
    printf '%s\n' "${HOST_LIST[@]}"
    printf '%s\n' "${HOST_SHORT_LIST[@]}"
}

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

generate_clean_keys_command() {
    # generates a string that may be eval'd to clean up old the authorized keys from $HOME/.ssh/authorized_keys
    # by removing the key containing some unique string or just deletes the authorized_keys file when no other key remains
    # makes a backup to $HOME/.ssh/authorized_keys.bak, if it exists, before parsing
    # parameters: array of substrings to match to remove the line
    #   intended to pass $USER or $(hostname) or $(hostname -A) to pass the identifier from the comment in the pub token
    # if no passed search strings, return immediately
    # return export clean_keys_command
    if [[ ! "$@" ]]; then
        echo "No search strings"
        return
    fi
    local search_strings=("$@")
    # echo "search_strings=${search_strings}"
    
    export clean_keys_command="" #this is the return value

    # primary output if needed to send this to remote host as single line remote ssh command
    # https://superuser.com/a/775195
    # if test -f $HOME/.ssh/authorized_keys; then
    #     temp_file=$(mktemp);
    #     cp $HOME/.ssh/authorized_keys $HOME/.ssh/authorized_keys.bak;
    #     for arg in ${search_strings}; do
    #         echo ${arg};
    #         if grep -v "${arg}" $HOME/.ssh/authorized_keys > $temp_file; then
    #             cat $temp_file > $HOME/.ssh/authorized_keys && rm $temp_file;
    #         else
    #             rm $HOME/.ssh/authorized_keys && rm $temp_file;
    #         fi;
    #     done;
    # fi;

    # search_strings=("head-1" "pplhpc1ln1.childrens.sea.kids")
    # serialze the main function into a string to send to remote host via ssh or eval locally if desired
    # https://superuser.com/a/775195
    clean_keys_command=$(echo "\
    if test -f \$HOME/.ssh/authorized_keys; then
        temp_file=\$(mktemp);
        cp \$HOME/.ssh/authorized_keys \$HOME/.ssh/authorized_keys.bak;
        for arg in ${search_strings}; do
            echo \${arg};
            if grep -v \"\${arg}\" \$HOME/.ssh/authorized_keys > \$temp_file; then
                cat \$temp_file > \$HOME/.ssh/authorized_keys && rm \$temp_file;
            else
                rm \$HOME/.ssh/authorized_keys && rm \$temp_file;
            fi;
        done;
    fi;")
    # remove new line and carriage returns
    # my_trim="${my_string//[$'\n\r']}"
    return
}

clean_keys() {
    # specifically overwriting global HOST_LIST locally
    # so I can comment out from specific hosts to all known easily
    local HOST_LIST=("login-2.hpc.childrens.sea.kids") # hosts to clean up
    search_strings=("head-1" "pplhpc1ln1.childrens.sea.kids") # retired machines to remove

    for idx in ${!HOST_LIST[@]}; do
        # echo "idx=${idx}"
        local host=${HOST_LIST[${idx}]}
        echo "host=${host}"

        generate_clean_keys_command "${search_strings[*]}"
        echo "export clean_keys_command=${clean_keys_command}"

        # uses sshpass to copy over id_file to host
        sshpass -f ${PASS} ssh ${USER}@${host} ${clean_keys_command}
    done
}

fingerprint() {
    local user=$1
    local passfile=$2
    shift 2 # remove parsed parameters from $@
    local parameter_array=("$@")
    echo "parameter_array=${parameter_array[*]}"
    local reset_keys=""
    local skip_hpc=""

    for arg in ${parameter_array[@]}; do
        echo "arg=${arg}"
        if [[ " ${arg} " =~ " reset_keys " ]]; then
            reset_keys="reset_keys"
        elif [[ " ${arg} " =~ " skip_hpc " ]]; then
            skip_hpc="skip_hpc"
        fi
    done

    echo "user=$user"
    echo "passfile=$passfile"
    echo "reset_keys=$reset_keys"
    echo "skip_hpc=$skip_hpc"

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

        if [[ "${reset_keys}" == "reset_keys" ]]; then
            # since cleaning up keys, remove old keys from remote hosts
            generate_clean_keys_command $host $host_short
            # echo "export clean_keys_command=${clean_keys_command}"
            # uses sshpass to make sure old key is removed from authorized_keys list on remote host
            echo "sshpass -f ${passfile} ssh ${user}@${host} ${clean_keys_command}"
            # -R removes all keys of the host from the local machine before generating a new key
            echo "ssh-keygen -R ${host} -C ${key_comment}@${host} -f ${id_file} -t ed25519"
            # gets hash of host with type specified and appends to known_hosts (gets fingerprint hash)
            echo "ssh-keyscan -Ht ed25519 ${host} >> ~/.ssh/known_hosts"
        elif [ ! -f "${id_file}" ]; then
            # not reseting key for user@host and the id_file doesn't exist, so generate it for the first time
            echo "ssh-keygen -C ${key_comment}@${host} -f ${id_file} -t ed25519"
        fi
        # uses sshpass to copy over id_file to host
        echo "sshpass -f ${passfile} ssh-copy-id -i ${id_file} ${user}@${host}"
        # copies custom dotfiles and verifies deployment of id file for passwordless host login
        echo "rsync -czP .aliases .bash_prompt .zprompt .shared_prompt tmux/.config/.tmux.conf ${user}@${host}:~/"
        # build up ~/.ssh/config for the user per host
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
# clean_keys

read_hosts
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