#
# ~/.bashrc - Pure Monochrome (Strictly Black & White)
#

[[ $- != *i* ]] && return

# Source active theme environment if present
if [[ -f "$HOME/.config/themes/active-env.sh" ]]; then
    source "$HOME/.config/themes/active-env.sh"
fi

# eza — ls replacement with Nerd Font icons
alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='eza -lah --group-directories-first --icons=auto'
alias lt='eza --tree --level=2 --icons=auto'
alias lta='eza --tree --level=2 --all --icons=auto'
alias dots-sync='bash ~/.config/scripts/dots-sync.sh'

alias grep='grep --color=auto'
_PS1_BASE='\w ❯ '
PS1='\w ❯ '

function _osc7 {
    if [[ $TERM = *xterm* || $TERM = *kitty* || $TERM = *ghostty* ]]; then
        printf '\e]7;kitty-shell-cwd://%s%s\a' "${HOSTNAME:-}" "$(pwd)"
    fi
}
PROMPT_COMMAND="_osc7${PROMPT_COMMAND:+;$PROMPT_COMMAND}"

_nix_dev_icon=$'\uf313'
_git_icon=$'\ue0a0'
_file_icon=$'\uf15b'
_folder_icon=$'\uf07b'
_update_prompt() {
    local _NIX_PRE="" _GIT_PRE=""

    if [[ -n ${IN_NIX_SHELL:-} ]]; then
        if [[ -z ${_NIX_DEV_LABEL:-} ]]; then
            local nm="${name:-}"
            nm="${nm%-env}"
            if [[ -n $nm && $nm != "nix-shell" ]]; then
                _NIX_DEV_LABEL="$nm"
            else
                local root="${NIX_LDFLAGS#*-rpath }"
                root="${root%% *}"
                root="${root%/outputs/out/lib}"
                [[ $root == */outputs/out ]] && root="${root%/outputs/out}"
                if [[ -n $root && -d $root ]]; then
                    _NIX_DEV_LABEL="${root##*/}"
                else
                    _NIX_DEV_LABEL="${PWD##*/}"
                fi
            fi
        fi
        _NIX_PRE="\[\e[1m\]( ${_nix_dev_icon} ${_NIX_DEV_LABEL} )\[\e[0m\] "
    fi

    local st br file_count dir_count dirty_count line path
    st="$(git status --porcelain -b 2>/dev/null)"
    if [[ -n $st ]]; then
        br="${st%%$'\n'*}"
        br="${br##\#\# }"
        br="${br%%...*}"
        if [[ $br == "HEAD" || $br == *"(no branch)"* ]]; then
            br="$(git rev-parse --short HEAD 2>/dev/null)"
            [[ -n $br ]] && br="detached:${br}"
        fi
        if [[ -n $br ]]; then
            file_count=0; dir_count=0
            while IFS= read -r line; do
                [[ $line == \#\#* ]] && continue
                path="${line:3}"
                [[ $path == *' -> '* ]] && path="${path##* -> }"
                path="${path#\"}"; path="${path%\"}"
                if [[ $path == */* ]]; then
                    dir_count=$((dir_count + 1))
                else
                    file_count=$((file_count + 1))
                fi
            done <<< "$st"
            dirty_count=""
            if (( file_count > 0 || dir_count > 0 )); then
                (( file_count > 0 )) && dirty_count+=" ${_file_icon} ${file_count}"
                (( dir_count > 0 ))  && dirty_count+=" ${_folder_icon} ${dir_count}"
            fi
            _GIT_PRE="\[\e[1m\]( ${_git_icon} ${br}${dirty_count} )\[\e[0m\] "
        fi
    fi

    PS1="${_NIX_PRE}${_GIT_PRE}${_PS1_BASE}"
}
PROMPT_COMMAND="_update_prompt${PROMPT_COMMAND:+;$PROMPT_COMMAND}"

export PATH="/home/muadzhdz/.opencode/bin:$PATH"
export PATH="/home/muadzhdz/.local/bin:$PATH"
export PATH="$PATH:/home/muadzhdz/.lmstudio/bin"
