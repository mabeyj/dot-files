#!/bin/bash

# Creates a link in the user's home directory to a file or directory in this
# repository.
link() {
	source=$(readlink -f $(dirname $0)/$1)
	dest=~/$1

	if [[ -h $dest ]]
	then
		echo "$dest already linked"
	elif [[ -a $dest ]]
	then
		echo "[!!] $dest already exists"
	else
		ln --symbolic $source $dest
		echo "Linked $source to $dest"
	fi
}

link .gitconfig
link .gitignore
link .tmux.conf
link .tmux.base16.conf
link .zshrc
