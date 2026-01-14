# Common aliases and configurations for bash and zsh
# This file is sourced by both .bash_profile and .zshrc

# Java execution
jax() { java "$@"; }

# JBang setup
if command -v jbang &> /dev/null; then
    alias j!=jbang
    export PATH="$HOME/.jbang/bin:$PATH"
fi

# Leetcode completions (shell-specific leet aliases remain in respective configs)
if command -v leetcode &> /dev/null; then
    eval "$(leetcode completions)"
fi

# Kubernetes
alias k=kubectl
