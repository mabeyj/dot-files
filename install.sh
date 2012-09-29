#!/bin/bash

link_file()
{
	source_path=$(readlink -f $(dirname $0)/$1)
	dest_path=~/$1

	if [[ -h $dest_path ]]
	then
		echo "$1 already linked"
	elif [[ -a $dest_path ]]
	then
		echo "[!!] $dest_path already exists"
	else
		ln -s $source_path $dest_path
		echo "Linked $source_path to $dest_path"
	fi
}

link_file .gitconfig
link_file .gitignore
link_file .tmux.conf
link_file .zshrc

if [[ ! -d ~/.oh-my-zsh ]]
then
	echo "Installing oh-my-zsh"
	wget --no-check-certificate https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | sh
else
	echo "oh-my-zsh already installed"
fi

link_file .oh-my-zsh/custom
