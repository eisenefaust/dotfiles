based off of:
https://github.com/CoreyMSchafer/dotfiles/tree/master

Use at your own risk, I modified this and made this for my own personal use.

Read more about SSH config files: https://linux.die.net/man/5/ssh_config
ssh-keygen -R host -C user@host -f ~/.ssh/host_ed25519 -t ed25519
ssh-copy-id -i ~/.ssh/host_ed25519 user@host
ssh-keyscan -Ht ed25519 host >> ~/.ssh/known_hosts"

for ghostty and tmux per host
https://ghostty.org/docs/help/terminfo
infocmp -x xterm-ghostty | ssh sasquatch -- tic -x -
N.B. need to do this per user I want to access on the host as well.  
    e.g. infocmp -x xterm-ghostty | ssh \<different_user\>@\<other_host\> -- tic -x -  
    or use SetEnv TERM=xterm-256color  
    I chose xterm-256color since it's univsersal at this point in time  