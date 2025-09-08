
source "${HOME}/.zshrc_add"

sshpass -f ${HOME}/.ssh/sch-passwd /sbin/mount_smbfs //gmorto@helens.childrens.sea.kids/active ${HOME}/active
# sshpass -f ${HOME}/.ssh/sch-passwd /sbin/mount_smbfs //gmorto@baker.childrens.sea.kids/archive ${HOME}/archive

