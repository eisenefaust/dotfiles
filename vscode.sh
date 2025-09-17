#!/usr/bin/env zsh

# Check if Homebrew's bin exists and if it's not already in the PATH
if [ -x "/opt/homebrew/bin/brew" ] && [[ ":$PATH:" != *":/opt/homebrew/bin:"* ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
fi

# Install VS Code Extensions
extensions=(
    ms-vscode-remote.remote-ssh
    charliermarsh.ruff
    esbenp.prettier-vscode
    foxundermoon.shell-format
    mechatroner.rainbow-csv
    ms-python.mypy-type-checker
    ms-python.python
    ms-toolsai.jupyter
    tamasfe.even-better-toml
    tomoki1207.pdf
    the0807.uv-toolkit
    jjjermiah.pixi-vscode
    nf-core.nf-core-extensionpack
    google.geminicodeassist
)

# Get a list of all currently installed extensions.
installed_extensions=$(code --list-extensions)

# no longer supported since can't trust all extension publishers in cli
# https://github.com/microsoft/vscode/issues/240283
for extension in "${extensions[@]}"; do
    if echo "$installed_extensions" | grep -qi "^$extension$"; then
        echo "$extension is already installed. Skipping..."
    else
        echo "Installing $extension..."
        code --install-extension "$extension"
    fi
done

# work around for not being able to install all extenions in CLI is to:
# create .vscode/extensions.json in an empty folder with list of extensions
# {
#     "recommendations":  [
#         "ms-vscode-remote.remote-ssh",
#         "charliermarsh.ruff",
#         "esbenp.prettier-vscode",
#         "foxundermoon.shell-format",
#         "mechatroner.rainbow-csv",
#         "ms-python.mypy-type-checker",
#         "ms-python.python",
#         "ms-toolsai.jupyter",
#         "tamasfe.even-better-toml",
#         "tomoki1207.pdf",
#         "the0807.uv-toolkit",
#         "jjjermiah.pixi-vscode",
#         "nf-core.nf-core-extensionpack",
#         "google.geminicodeassist"
#     ]
# }

echo "VS Code extensions have been installed."

# Define the target directory for VS Code user settings on macOS
VSCODE_USER_SETTINGS_DIR="${HOME}/Library/Application Support/Code/User"

if [ ! -f "${HOME}/dotfiles/settings/VSCode-Settings.json" ]; then
    echo "VS Code user settings source file does not exist. Please ensure it's in \"${HOME}/dotfiles/settings/VSCode-Settings.json.\""
# Check if VS Code settings directory exists
elif [ -d "$VSCODE_USER_SETTINGS_DIR" ]; then
    # Copy your custom settings.json and keybindings.json to the VS Code settings directory
    ln -sf "${HOME}/dotfiles/settings/VSCode-Settings.json" "${VSCODE_USER_SETTINGS_DIR}/settings.json"
    # ln -sf "${HOME}/dotfiles/settings/VSCode-Keybindings.json" "${VSCODE_USER_SETTINGS_DIR}/keybindings.json"

    echo "VS Code settings have been updated."
else
    echo "VS Code user settings directory does not exist. Please ensure VS Code is installed."
fi