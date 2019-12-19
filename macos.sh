#!/bin/sh

source ./functions.sh

set -e

# Create required files and directories
if [ ! -d "$HOME/.bin/" ]; then
  mkdir "$HOME/.bin"
fi
if [ ! -d "$HOME/git/" ]; then
  mkdir "$HOME/git"
fi

if [ ! -d "$HOME/Library/Application\ Support/Spectacle/" ]; then
  mkdir -p "$HOME/Library/Application\ Support/Spectacle"
fi

if [ ! -f "$HOME/.zshrc" ]; then
  touch "$HOME/.zshrc"
fi

append_to_zshrc 'export PATH="$HOME/.bin:$PATH"'

HOMEBREW_PREFIX="/usr/local"

if [ -d "$HOMEBREW_PREFIX" ]; then
  if ! [ -r "$HOMEBREW_PREFIX" ]; then
    sudo chown -R "$LOGNAME:admin" /usr/local
  fi
else
  sudo mkdir "$HOMEBREW_PREFIX"
  sudo chflags norestricted "$HOMEBREW_PREFIX"
  sudo chown -R "$LOGNAME:admin" "$HOMEBREW_PREFIX"
fi

case "$SHELL" in
  */zsh)
    if [ "$(which zsh)" != '/usr/local/bin/zsh' ] ; then
      update_shell
    fi
    ;;
  *)
    update_shell
    ;;
esac

# Install homebrew if not installed
if ! command -v brew >/dev/null; then
  echo "Installing Homebrew"
    curl -fsS 'https://raw.githubusercontent.com/Homebrew/install/master/install' | ruby

    append_to_zshrc '# recommended by brew doctor'

    append_to_zshrc 'export PATH="/usr/local/bin:$PATH"' 1

    export PATH="/usr/local/bin:$PATH"
fi


brew update --force
brew bundle --file=- <<EOF
tap "caskroom/cask"

brew "neovim"

brew "git"
brew "openssl"
brew "reattach-to-user-namespace"
brew "the_silver_searcher"
brew "tmux"
brew "vim"
brew "zsh"
brew "hub"
brew "imagemagick"
brew "thefuck"
brew "reattach-to-user-namespace"
brew "fzf"

tap "caskroom/fonts"
cask "google-chrome"
cask "iterm2"
cask "slack"
cask "spectacle"
cask "font-fira-code"
cask "karabiner-elements"
cask "gpg-suite"
cask "vscodium"

brew "postgres", restart_service: :changed
EOF

# Install fzf key bindings, fuzzy completions
$(brew --prefix)/opt/fzf/install

# Install nvm
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash

# Install prezto
git clone --recursive https://github.com/sorin-ionescu/prezto.git "$HOME/.zprezto"

zsh <<EOF
  setopt EXTENDED_GLOB
  for rcfile in "$HOME"/.zprezto/runcoms/^README.md(.N); do
    if [ ! -d "$HOME/.${rcfile:t}" ]; then
      ln -s "$rcfile" "$HOME/.${rcfile:t}"
    fi
  done
EOF

# Install tpm
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Clone dotfiles and copy them to the right places
git clone https://github.com/oscarekholm/dotfiles.git /tmp/dotfiles
rm -rf /tmp/dotfiles/.git
cp -r /tmp/dotfiles/.[^.]* "$HOME"
cp "$HOME/.config/iterm2/com.googlecode.iterm2.plist" "$HOME/Library/Preferences"
cp "$HOME/.config/spectacle/Shortcuts.json" "$HOME/Library/Application\ Support/Spectacle"
