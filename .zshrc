setopt PROMPT_SUBST

# Load dotfiles:
for file in ~/.{zprompt,aliases}; do
    # check if file is readable and a normal file before loading
    [ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file

# add autocomplete for pixi commands
autoload -Uz compinit
compinit
eval "$(pixi completion --shell zsh)"