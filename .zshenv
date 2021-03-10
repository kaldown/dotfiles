export EDITOR=nvim
export VISUAL=nvim
export FZF_DEFAULT_COMMAND='rg --files --no-ignore-vcs --hidden'
export LESS="-FRKX"
export TERM=xterm-256color
export XDG_CONFIG_HOME=$HOME/.config
export TMUXP_CONFIGDIR=$XDG_CONFIG_HOME/tmuxp

# fzf opts
export FZF_DEFAULT_OPTS='--preview "cat {}"'
export FZF_DEFAULT_COMMAND='fd --type f'
