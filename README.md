based off of:
https://github.com/CoreyMSchafer/dotfiles/tree/master

Use at your own risk, I modified this and made this for my own personal use.

Feel free to read this and take what you want from it to make something that works for your use case. 

* [install.sh](install.sh) will setup my local mac the way I want it

* [deploy.sh](deploy.sh) will deploy the `$FILE_MANIFEST` to the hosts in [hosts.txt](hosts.txt) using the standard ssh tools as much as possible.
    * I assume location of secret information and elevated account prefix and then just hard code in my service accounts to just get it done quickly and easily.
    * It registers my user account and elevated user account and my service accounts to the various remote hosts I use.
    * It will copy out aliases and shared prompts to all hosts and for my user and elevated user accounts but will not deploy them to the service accounts
    * I do not deploy bashrc nor zshrc to remote host as those systems have their own bespoke system admin rc file. 
        * Instead I have a .bashrc_add that everything goes through that I simple source at the bottom of rc file e.g. `source .bashrc_add`

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