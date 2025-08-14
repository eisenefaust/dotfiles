# Load dotfiles:
for file in ~/.{bash_prompt,aliases}; do
    # check if file is readable and a normal file before loading
    [ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file

eval "$(pixi completion --shell bash)"
