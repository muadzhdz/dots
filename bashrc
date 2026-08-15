#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# eza — ls replacement with Nerd Font icons
# (requires eza + a Nerd Font such as ttf-jetbrains-mono-nerd)
alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='eza -lah --group-directories-first --icons=auto'
alias lt='eza --tree --level=2 --icons=auto'
alias lta='eza --tree --level=2 --all --icons=auto'

alias grep='grep --color=auto'
PS1='\w ❯ '

# Report cwd to the terminal (OSC 7, format kitty) so new kitty tabs/windows
# (ctrl+shift+t / ctrl+shift+n) open in the current directory.
function _osc7 {
    if [[ $TERM = *xterm* || $TERM = *kitty* || $TERM = *ghostty* ]]; then
        printf '\e]7;kitty-shell-cwd://%s%s\a' "${HOSTNAME:-}" "$(pwd)"
    fi
}
PROMPT_COMMAND="_osc7${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
