#!/bin/bash

PASS=~/.ssh/sch-passwd
PASS2=~/.ssh/sch2-passwd

deploy_dotfiles() {
    local user=$1
    local passfile=$2
    echo "user=$user"
    echo "passfile=$passfile"

    local HOST_LIST=(
        "login-1.hpc.childrens.sea.kids"
        "login-2.hpc.childrens.sea.kids"
        "pplvsq01.childrens.sea.kids"
        "rplasc01.childrens.sea.kids"
        "rplweb01.childrens.sea.kids"
        "rdldoc01.childrens.sea.kids"
        #".childrens.sea.kids"
    )

    for HOST in ${HOST_LIST[@]}; do
        # sshpass -f $passfile scp -r * $user@$HOST:$DEPLOY_DIR || { echo "ERROR: couldn't copy files to $HOST:$DEPLOY_DIR"; exit 1; }
        echo "infocmp -x xterm-ghostty | sshpass -f $passfile ssh $user@$HOST -- tic -x -"
    done
}