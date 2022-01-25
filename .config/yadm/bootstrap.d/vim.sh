#!/bin/sh

# download vim-plug if missing
if [ ! -f "$HOME/.local/share/nvim/site/autoload/plug.vim" ] ; then
	echo "Installing vim-plug"
	sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
	nvim --headless +PlugInstall +qa
fi
