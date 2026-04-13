# Shell functions for development and workflow helpers
# Sourced by both .bash_profile and .zshrc

# wt <branch> — create a git worktree for <branch> in a sibling REPO-worktrees directory
wt() {
    local branch="$1"

    if [[ -z "$branch" ]]; then
        echo "Usage: wt <branch>" >&2
        return 1
    fi

    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
        echo "wt: not a git repository" >&2
        return 1
    }

    local repo_name worktrees_dir
    repo_name=$(basename "$repo_root")
    worktrees_dir="$(dirname "$repo_root")/${repo_name}-worktrees"

    mkdir -p "$worktrees_dir"

    # Check out existing branch, or create a new one
    if git show-ref --verify --quiet "refs/heads/$branch"; then
        git worktree add "$worktrees_dir/$branch" "$branch"
    else
        git worktree add -b "$branch" "$worktrees_dir/$branch"
    fi
}
