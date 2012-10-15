#local return_status="%(?..%{$fg[100]%} ↵ %?)"
local time="$BG[232]$FG[016] $BG[233] ⌚ $FG[240]%* "
local return_status="%(?..$BG[232]$FG[016] $BG[233] ↵ $FG[009]%? )"

ZSH_THEME_GIT_PROMPT_PREFIX="$BG[232]$FG[016] $BG[233] ± $FG[240]"
ZSH_THEME_GIT_PROMPT_SUFFIX=" "
ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_CLEAN=""

ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[green]%}A"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[blue]%}M"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}D"
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[yellow]%}R"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[magenta]%}M"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[cyan]%}?"

PROMPT="$BG[233]$FG[240] %~ $BG[232] %{$reset_color%}$FX[bold]$FG[032] > %{$reset_color%}"
RPROMPT=" ${return_status}\$(git_prompt_info)${time}%{$reset_color%}"
