local return_status="%(?..%{$fg[red]%} ↵ %?)"
local background="%(!.%{$fg[red]%}.%{$fg[blue]%})"

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[magenta]%} ± "
ZSH_THEME_GIT_PROMPT_SUFFIX=""
ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_CLEAN=""

ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[green]%}A"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[blue]%}M"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}D"
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[yellow]%}R"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[magenta]%}⌥ "
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[cyan]%}?"

PROMPT='%{$background%}%~ %{$fg_bold[blue]%}>%{$reset_color%} '
RPROMPT=' %{$fg[blue]%}%@%{$fg[red]%}${return_status}$(git_prompt_info)%{$reset_color%}'
