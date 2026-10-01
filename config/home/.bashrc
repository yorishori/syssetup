 [[ $- != *i* ]] && return

 HISTCONTROL=ignoreboth
 HISTSIZE=10000
 HISTFILESIZE=20000
 HISTTIMEFORMAT='%F %T  '
 HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/.bash_history"
 PROMPT_COMMAND='history -a'

 shopt -s histappend checkwinsize globstar autocd cdspell

 stty -ixon
 
 alias ls="ls -aHl --color=auto"
 alias grep="grep --color=auto"
 [[ $TERM == xterm-kitty ]] && alias ssh='kitten ssh'

 # yazi, but the shell follows to the directory it quit in
 y() {
    local tmp cwd
    tmp="$(mktemp -t yazi-cwd.XXXXXX)"
    yazi "$@" --cwd-file="$tmp"
    cwd="$(<"$tmp")"
    [[ -n $cwd && $cwd != "$PWD" ]] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
 }

 # bash prompt
 _clr_mauve='\[\e[38;2;203;166;247m\]'   # #cba6f7 - mauve (user)
 _clr_lavender='\[\e[38;2;180;190;254m\]' # #b4befe - lavender (kaomoji)
 _clr_sky='\[\e[38;2;137;220;235m\]'      # #89dceb - sky (path)
 _clr_green='\[\e[38;2;166;227;161m\]'    # #a6e3a1 - green (prompt char)
 _clr_reset='\[\e[0m\]'
 PS1="${_clr_mauve}\u${_clr_lavender}(~^^)~ ${_clr_sky}\w${_clr_reset}\n${_clr_green}> \$${_clr_reset} "
 unset _clr_mauve _clr_lavender _clr_sky _clr_green _clr_reset
