# Changing TERM resets many zsh settings, so do it first.
export TERM=xterm-256color

# Set the custom colours for the selected base16 theme.
export BASE16_THEME=~/Code/base16-shell/base16-default.dark.sh
if [[ -a $BASE16_THEME ]]
then
	source $BASE16_THEME
fi

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
	autoload -Uz vcs_info

	local prompt_style="%B%F{32}"
	local return_style="%K{52}%F{203}"
	local block_style="%K{233}%F{240}"
	local reset="%k%f"
	local reset_bold="%b"

	# Use base16 colours if enabled.
	if [[ -a $BASE16_THEME ]]
	then
		prompt_style="%B%F{15}"
		return_style="%K{18}%F{1}"
		block_style="%K{18}%F{8}"
	fi

	local time=" $block_style %D{%k:%M:%S} $reset"
	local return_status="%(?.. $return_style ↵ %? $reset)"
	local vcs='$vcs_info_msg_0_'

	# Git branch display: this is substituted dynamically in the prompt, so
	# prompt_subst needs to be enabled and note the single quotes rounds $vcs
	# above. Also, %b normally means "reset bold", but it represents the branch
	# name in this format and the "reset bold" form is weirdly escaped, hence
	# the need to separate $reset and $reset_bold.
	setopt prompt_subst
	zstyle ':vcs_info:*' enable git
	zstyle ':vcs_info:*' formats " $block_style %b $reset"

	PROMPT="$block_style %~ $reset$prompt_style > $reset$reset_bold"
	RPROMPT="$return_status$vcs$time$reset"
	ZLE_RPROMPT_INDENT=0
}

# Update current branch and show current directory in window title.
precmd() {
	vcs_info
	print -Pn "\e]2;%~"
}

# Redraw the time in $RPROMPT after executing a command so the scrollback shows
# when each command was executed.
preexec() {
	local block_style="%K{233}%F{240}"
	local reset="%k%f"

	# Use base16 colours if enabled.
	if [[ -a $BASE16_THEME ]]
	then
		block_style="%K{18}%F{8}"
	fi

	local time="$(date +"%k:%M:%S")"
	local x=$(( $COLUMNS - 10 ))

	print -P "\033[1A\033[${x}C$block_style $time $reset"
}

# History
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

# Key bindings
bindkey "^r" history-incremental-search-backward
bindkey "^?" backward-delete-char

# Colors
alias ls="ls --color=tty"
alias grep="grep --color=always"

# Miscellaneous
autoload -U compinit && compinit
zstyle ":completion:*" menu select

setopt auto_cd

# Disable terminal shortcuts so Vim's Command-T CTRL+S shortcut works.
stty -ixon

# Environment variables
export EDITOR=vim
export GOPATH=$HOME/Code/go
export PATH=$PATH:$GOPATH/bin

# Custom aliases
