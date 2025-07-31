setopt PROMPT_SUBST

# Load dotfiles:
for file in ~/.{zprompt,aliases,private}; do
    # check if file is readable and a normal file before loading
    [ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file