# Coloured man pages: https://wiki.archlinux.org/index.php/Man#Colored_man_pages
man() {
	env \
		LESS_TERMCAP_mb=$(printf "\e[1;31m") \
		LESS_TERMCAP_md=$(printf "\e[1;31m") \
		LESS_TERMCAP_me=$(printf "\e[0m") \
		LESS_TERMCAP_se=$(printf "\e[0m") \
		LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
		LESS_TERMCAP_ue=$(printf "\e[0m") \
		LESS_TERMCAP_us=$(printf "\e[1;32m") \
			man "$@"
}

# Syntax highlighting
function() {
	local highlight_path=/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

	if [[ -a $highlight_path ]]
	then
		source $highlight_path
	else
		echo "Syntax highlighting not installed (install zsh-syntax-highlighting from AUR)"
	fi
}

# Prompt
function() {
	autoload -U colors && colors
	autoload -U compinit

	local prompt_style="%B%F{32}"
	local return_style="%K{52}%F{203}"
	local block_style="%K{233}%F{240}"
	local reset="%k%f%b"

	local time=" $block_style %D{%k:%M:%S} $reset"
	local return_status="%(?.. $return_style ↵ %? $reset)"

	PROMPT="$block_style %~ $reset$prompt_style > $reset"
	RPROMPT="$return_status$time$reset"
}

# Show current directory in window title.
precmd() {
	print -Pn "\e]2;%~"
}

# Redraw the time in $RPROMPT after executing a command so the scrollback shows
# when each command was executed.
preexec() {
	local block_style="%K{233}%F{240}"
	local reset="%k%f"

	local time=$(date +"%k:%M:%S")
	local x=$(( $COLUMNS - 11 ))

	print -P "\033[1A\033[${x}C$block_style $time $reset"
}

# History
function() {
	HISTFILE=$HOME/.zsh_history
	HISTSIZE=10000
	SAVEHIST=10000

	setopt append_history
	setopt extended_history
	setopt hist_expire_dups_first
	setopt hist_ignore_dups
	setopt hist_ignore_space
	setopt hist_verify
	setopt inc_append_history
	setopt share_history
}

# Key bindings
function() {
	bindkey '^r' history-incremental-search-backward
}

# Colors
function() {
	alias ls="ls --color=tty"
	alias grep="grep --color=always"
}

# Miscellaneous
function() {
	autoload -U compinit && compinit
	zstyle ":completion:*" menu select

	setopt auto_cd
}

# Customize to your needs...
export PATH=/usr/lib/lightdm/lightdm:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games
export TERM=xterm-256color

# Disable terminal shortcuts so Vim's Command-T CTRL+S shortcut works
stty -ixon
