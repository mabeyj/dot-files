# Activate zsh syntax highlighting
local highlight_path=/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

if [[ -a $highlight_path ]]
then
	source $highlight_path
else
	echo "Syntax highlighting not installed (install zsh-syntax-highlighting from AUR)"
fi
