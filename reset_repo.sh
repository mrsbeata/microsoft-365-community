#!/usr/bin/env bash
#
# reset_repo.sh — Reset repository to a single clean commit on main, push force, delete all other branches.
#
# ⚠️  WARNING: This script is DESTRUCTIVE. It will:
#     - Rewrite the entire git history to a single commit
#     - Force push to remote (replacing remote history)
#     - Delete ALL branches (local and remote) except main
#
# Usage: bash reset_repo.sh [REPO_DIR] [REMOTE_NAME] [MAIN_BRANCH]
#
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Configuration (defaults, overridable via CLI args)
# ─────────────────────────────────────────────────────────────────────────────
REPO_DIR="${1:-.}"
REMOTE_NAME="${2:-origin}"
MAIN_BRANCH="${3:-main}"

# ─────────────────────────────────────────────────────────────────────────────
# Helper functions
# ─────────────────────────────────────────────────────────────────────────────
log()   { printf '\n\033[1;34m>>> %s\033[0m\n' "$*"; }
info()  { printf '    \033[0;32m✔ %s\033[0m\n' "$*"; }
warn()  { printf '    \033[0;33m⚠ %s\033[0m\n' "$*"; }
error() { printf '    \033[0;31m✖ %s\033[0m\n' "$*"; }

# ─────────────────────────────────────────────────────────────────────────────
# Validation
# ─────────────────────────────────────────────────────────────────────────────
if [[ ! -d "$REPO_DIR/.git" && ! -f "$REPO_DIR/.git" ]]; then
    error "Directory '$REPO_DIR' is not a Git repository."
    exit 1
fi

cd "$REPO_DIR"
log "Working in repository: $(pwd)"

# ─────────────────────────────────────────────────────────────────────────────
# Safety confirmation
# ─────────────────────────────────────────────────────────────────────────────
log "⚠️  DESTRUCTIVE OPERATION WARNING ⚠️"
warn "This will REWRITE all git history to a single commit."
warn "This will FORCE PUSH to '$REMOTE_NAME/$MAIN_BRANCH'."
warn "This will DELETE all other branches (local and remote)."
printf '\n    Type "YES" to confirm: '
read -r CONFIRM
if [[ "$CONFIRM" != "YES" ]]; then
    error "Aborted by user."
    exit 1
fi

# ─────────────────────────────────────────────────────────────────────────────
# Step 1: Commit all uncommitted/untracked files
# ─────────────────────────────────────────────────────────────────────────────
log "Step 1: Committing all uncommitted and untracked files..."

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %z')

# Ensure we're on a valid branch (prefer main if it exists)
if git show-ref --verify --quiet "refs/heads/$MAIN_BRANCH"; then
    git checkout "$MAIN_BRANCH" --quiet
    info "Checked out '$MAIN_BRANCH'."
else
    # Get the first available branch
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || git rev-parse --abbrev-ref HEAD)
    if [[ -z "$CURRENT_BRANCH" || "$CURRENT_BRANCH" == "HEAD" ]]; then
        CURRENT_BRANCH=$(git for-each-ref --format='%(refname:short)' refs/heads/ | head -n1)
        if [[ -n "$CURRENT_BRANCH" ]]; then
            git checkout "$CURRENT_BRANCH" --quiet
        fi
    fi
    info "Working from branch: $CURRENT_BRANCH"
fi

if [[ -n "$(git status --porcelain)" ]]; then
    git add --all
    COMMIT_MSG="chore: final WIP before full reset ($TIMESTAMP)"
    git commit -m "$COMMIT_MSG" --quiet
    info "Committed: $COMMIT_MSG"
else
    info "Working tree already clean — nothing to commit."
fi

# ─────────────────────────────────────────────────────────────────────────────
# Step 2: Delete all local branches except main
# ─────────────────────────────────────────────────────────────────────────────
log "Step 2: Deleting all local branches except '$MAIN_BRANCH'..."

mapfile -t LOCAL_BRANCHES < <(git for-each-ref --format='%(refname:short)' refs/heads/)

for branch in "${LOCAL_BRANCHES[@]}"; do
    if [[ "$branch" != "$MAIN_BRANCH" ]]; then
        git branch -D "$branch" --quiet 2>/dev/null || true
        info "Deleted local branch: $branch"
    fi
done

# ─────────────────────────────────────────────────────────────────────────────
# Step 3: Recreate main branch from a clean orphan commit
# ─────────────────────────────────────────────────────────────────────────────
log "Step 3: Recreating '$MAIN_BRANCH' with a fresh initial commit..."

TEMP_BRANCH="__temp_reset_orphan__"

# Create orphan branch (no history)
git checkout --orphan "$TEMP_BRANCH" --quiet
info "Created temporary orphan branch."

# Stage all files currently in the working tree
git add --all
info "Staged all files for the fresh commit."

# Create the new root commit
RESET_COMMIT_MSG="Initial commit (repository reset on $TIMESTAMP)"
git commit -m "$RESET_COMMIT_MSG" --quiet
info "Created fresh initial commit: $RESET_COMMIT_MSG"

# Delete old main if it exists
if git show-ref --verify --quiet "refs/heads/$MAIN_BRANCH"; then
    git branch -D "$MAIN_BRANCH" --quiet
    info "Deleted old '$MAIN_BRANCH' branch."
fi

# Rename temp branch to main
git branch -m "$MAIN_BRANCH"
info "Renamed orphan branch to '$MAIN_BRANCH'."

# ─────────────────────────────────────────────────────────────────────────────
# Step 4: Force push main to remote
# ─────────────────────────────────────────────────────────────────────────────
log "Step 4: Force pushing '$MAIN_BRANCH' to '$REMOTE_NAME'..."

if git remote get-url "$REMOTE_NAME" &>/dev/null; then
    if git push --force --set-upstream "$REMOTE_NAME" "$MAIN_BRANCH" 2>&1; then
        info "Force pushed '$MAIN_BRANCH' to '$REMOTE_NAME'."
    else
        warn "Force push failed — check permissions or network."
    fi
else
    warn "Remote '$REMOTE_NAME' not configured — skipping push."
fi

# ─────────────────────────────────────────────────────────────────────────────
# Step 5: Delete all remote branches except main
# ─────────────────────────────────────────────────────────────────────────────
log "Step 5: Deleting all remote branches except '$MAIN_BRANCH'..."

if git remote get-url "$REMOTE_NAME" &>/dev/null; then
    # Fetch to get current list of remote branches
    git fetch "$REMOTE_NAME" --prune --quiet 2>/dev/null || true

    mapfile -t REMOTE_BRANCHES < <(git for-each-ref --format='%(refname:short)' "refs/remotes/$REMOTE_NAME/" | sed "s|^$REMOTE_NAME/||")

    for rbranch in "${REMOTE_BRANCHES[@]}"; do
        # Skip HEAD pointer and main branch
        if [[ "$rbranch" == "HEAD" || "$rbranch" == "$MAIN_BRANCH" ]]; then
            continue
        fi
        if git push "$REMOTE_NAME" --delete "$rbranch" 2>&1; then
            info "Deleted remote branch: $REMOTE_NAME/$rbranch"
        else
            warn "Failed to delete remote branch: $REMOTE_NAME/$rbranch"
        fi
    done
else
    warn "Remote '$REMOTE_NAME' not configured — skipping remote branch cleanup."
fi

# ─────────────────────────────────────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────────────────────────────────────
log "Repository reset complete!"
info "Current branch: $(git branch --show-current)"
info "Commit count: $(git rev-list --count HEAD)"
info "All files preserved in the new initial commit."
