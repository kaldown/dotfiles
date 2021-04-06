export EDITOR=nvim
export VISUAL=nvim
export LESS='-FRKX'
export TERM=xterm-256color
export XDG_CONFIG_HOME=$HOME/.config
export TMUXP_CONFIGDIR=$XDG_CONFIG_HOME/tmuxp

# fzf opts
#export FZF_DEFAULT_OPTS='--preview "bat --style=numbers --color=always --line-range :500 {}"'
#export FZF_DEFAULT_COMMAND='rg --files --no-ignore-vcs --hidden'
#export FZF_DEFAULT_COMMAND='fd --type f'
#export FZF_CTRL_R_OPTS='--preview "bat --style=numbers --color=always --line-range :500 {}"'
export FZF_CTRL_T_COMMAND='git ls-files --deleted --modified --others --exclude-standard'
