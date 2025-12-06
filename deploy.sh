#!/bin/bash

KNOWN_HOSTS="${HOME}/.ssh/known_hosts"


PASS=${HOME}/.ssh/sch-passwd
PASS2=${HOME}/.ssh/sch2-passwd
PASS3=${HOME}/.ssh/rsc-auto-passwd
PASS4=${HOME}/.ssh/rsc-log-passwd

ELEVATED_USER_PREFIX=("de-" "dd-")

PRIMARY_USER=${USER}

HOST_LIST=()

HOST_SHORT_LIST=()

FILE_MANIFEST=( "shell/.aliases" "shell/.bash_prompt" "shell/.bashrc_add" "shell/.zprompt" "shell/.zshrc_add" "shell/.shared_prompt" "shell/.bashrc_add" "tmux/" )

read_hosts() {
    local HOST_FILE="hosts.txt"
    while IFS=' '
    read -r host short; do 
        # if line starts with a "#" to mark a comment
        if [[ "${host}" == "#"* ]]; then
            continue
        fi
        HOST_LIST+=("${host}")
        HOST_SHORT_LIST+=("${short}")
    done < $HOST_FILE
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
    elif [[ " ${ELEVATED_USER_PREFIX[@]} " =~ " ${user:0:3} " ]]; then
        host_short="de-${host_short}"
    fi
    echo "Host ${host_short}"
    echo "    HostName ${host}"
    echo "    SetEnv TERM=xterm-256color"
    echo "    User ${user}"
    echo "    Port 22"
    echo "    ForwardX11 yes"
    echo "    ForwardX11Trusted yes"
    echo "    PreferredAuthentications publickey"
    echo "    IdentityFile ${id_file}"
    echo ""
}

generate_clean_command() {
    # generates a string that may be eval'd to clean up old files such as:
    #   authorized keys from $HOME/.ssh/authorized_keys
    #   known_hosts from $HOME/.ssh/known_hosts
    # by removing the line containing some unique string or just deletes the file line remains
    # makes a backup to ${file_path}.bak, if it exists, before parsing
    # parameters: array of substrings to match to remove the line
    #   intended to pass $USER or $(hostname) or $(hostname -A) to pass the identifier from the comment in the pub token
    # if no passed search strings, return immediately
    # return export clean_command
    local file_path=$1 # store first param as file to clean up
    shift 1 # remove parsed parameters from $@
    if [[ ! "$@" ]]; then
        echo "No search strings"
        return
    fi
    local search_strings=("$@")
    echo "search_strings=${search_strings[*]}"
    
    export clean_command="" #this is the return value

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
    clean_command=$(echo "\
    if test -f ${file_path}; then
        temp_file=\$(mktemp);
        cp ${file_path} ${file_path}.bak;
        for arg in ${search_strings[@]}; do
            echo \${arg};
            if grep -v \"\${arg}\" ${file_path} > \$temp_file; then
                cat \$temp_file > ${file_path} && rm \$temp_file;
            else
                rm ${file_path} && rm \$temp_file;
            fi;
        done;
    fi;")
    # remove new line and carriage returns
    # my_trim="${clean_command//[$'\n\r']}"
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

        generate_clean_command "${search_strings[*]}"
        echo "export clean_command=${clean_command}"

        # uses sshpass to copy over id_file to host
        sshpass -f ${PASS} ssh ${USER}@${host} ${clean_command}
    done
}

remote_hosts_setup() {
    local user=$1
    local passfile=$2
    temp_config_file=$3
    shift 3 # remove parsed parameters from $@
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
    echo "temp_config_file=$temp_config_file"
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
        local id_file="${HOME}/.ssh/${user_prefix}${host}_ed25519"

        if [[ "${reset_keys}" == "reset_keys" ]]; then
            # since cleaning up keys, remove old keys of current machine from remote hosts
            # This prevents ssh-copy-id from reporting key already present since it was already removed if present.
            echo "resetting keys for ${key_comment}@${host}"
            generate_clean_command "\$HOME/.ssh/authorized_keys" ${key_comment}@${host}
            # echo "export clean_command=${clean_command}"
            # uses sshpass to make sure old key is removed from authorized_keys list on remote host
            sshpass -f ${passfile} ssh -t ${user}@${host} ${clean_command}

            # -R removes all keys of the host from the local machine before generating a new key
            ssh-keygen -R ${host} -f ${id_file}

            # back up old id_file just in case instead of deleting it
            if [ -f "${id_file}" ]; then
                # will silently overwrite existing backups if they exist
                echo "backing up old id file pair"
                mv ${id_file} ${id_file}.bak
                mv ${id_file}.pub ${id_file}.pub.bak
            fi
        fi
        # If need to generate a new key
        if [ ! -f "${id_file}" ]; then
            # generate a new key for user@host
            echo "generating new key"
            ssh-keygen -q -N "" -C ${key_comment}@${host} -f ${id_file} -t ed25519
        fi

        # Check if the host is already in known_hosts
        ssh-keygen -F "${host}"
        if [ $? -ne 0 ]; then
            # if ssh-keygen returns non-zero exit code, host needs to be added.
            # Retrieve the host's public key and append it
            # -H obfuscates hosts by converting them all to hashes
            echo "adding host to known_hosts ${host}"
            ssh-keyscan -t ed25519 "${host}" >> "$KNOWN_HOSTS"
        fi
        # uses sshpass to copy over id_file to host
        sshpass -f ${passfile} ssh-copy-id -i ${id_file} ${user}@${host}
        # verify ssh-key was registred properly
        ssh -i ${id_file} ${user}@${host} "echo verified"

        # copies custom dotfiles for my accounts only (not shared service accounts)
        if [[ ${user} == *"${USER}" ]]; then
            sshpass -f ${passfile} rsync -czPr ${FILE_MANIFEST[*]} ${user}@${host}:~/
        fi
        # build up ~/.ssh/config for the user per host
        host_template ${host} ${host_short} ${user} ${id_file} >> $temp_config_file
    done

    echo "To finish the deployment of the terminal preferences,"
    echo "when next logged in to remote host, edit ~/.bashrc with \"source .bashrc_add\" or similar with zshell"
}

read_hosts
temp_config_file=$(mktemp)

remote_hosts_setup "${USER}" "${PASS}" $temp_config_file
remote_hosts_setup "de-${USER}" "${PASS2}" $temp_config_file "skip_hpc"
remote_hosts_setup "svc_rsc_hpc_auto" "${PASS3}" $temp_config_file
remote_hosts_setup "svc_rsc_hpc_log" "${PASS4}" $temp_config_file

echo "deploying ssh key config with shortnames"
ssh_config=${HOME}/.ssh/config
if [ -f ${ssh_config} ]; then
    cp ${ssh_config} ${ssh_config}.bak
fi
cat $temp_config_file > ${ssh_config} && rm $temp_config_file

# cat ${ssh_config}

# echo "look at $(pwd)/config and deploy if valid"
# deploy "${USER}" "${PASS}"
# deploy "de-${USER}" "${PASS2}" "skip_hpc"
# deploy "svc_rsc_hpc_auto" "${PASS3}"
# deploy "svc_rsc_hpc_log" "${PASS4}"