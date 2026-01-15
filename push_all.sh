#!/usr/bin/env bash
#
# push_all.sh — Commit WIP on all local branches and push them to remote.
#
# Usage: bash push_all.sh [REPO_DIR] [REMOTE_NAME] [MAIN_BRANCH]
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
# Save current branch/state to restore at end
# ─────────────────────────────────────────────────────────────────────────────
ORIGINAL_REF=$(git symbolic-ref --quiet HEAD 2>/dev/null || git rev-parse HEAD)
ORIGINAL_BRANCH="${ORIGINAL_REF#refs/heads/}"

cleanup() {
    log "Restoring original branch: $ORIGINAL_BRANCH"
    git checkout --quiet "$ORIGINAL_BRANCH" 2>/dev/null || git checkout --quiet "$ORIGINAL_REF" || true
}
trap cleanup EXIT

# ─────────────────────────────────────────────────────────────────────────────
# Fetch remote refs (non-destructive)
# ─────────────────────────────────────────────────────────────────────────────
log "Fetching from remote '$REMOTE_NAME'..."
if git remote get-url "$REMOTE_NAME" &>/dev/null; then
    git fetch "$REMOTE_NAME" --prune --quiet || warn "Fetch failed (network issue?). Continuing with local data."
else
    warn "Remote '$REMOTE_NAME' not found. Skipping fetch."
fi

# ─────────────────────────────────────────────────────────────────────────────
# Ensure main branch exists locally
# ─────────────────────────────────────────────────────────────────────────────
log "Ensuring local '$MAIN_BRANCH' branch exists..."

if git show-ref --verify --quiet "refs/heads/$MAIN_BRANCH"; then
    info "Local '$MAIN_BRANCH' already exists."
else
    # Try to create from remote
    if git show-ref --verify --quiet "refs/remotes/$REMOTE_NAME/$MAIN_BRANCH"; then
        git branch "$MAIN_BRANCH" "$REMOTE_NAME/$MAIN_BRANCH" --quiet
        info "Created local '$MAIN_BRANCH' from '$REMOTE_NAME/$MAIN_BRANCH'."
    else
        # Create orphan main if nothing else available
        warn "No '$REMOTE_NAME/$MAIN_BRANCH' found. Creating empty local '$MAIN_BRANCH'."
        git checkout --orphan "$MAIN_BRANCH" --quiet 2>/dev/null || true
        git checkout --quiet "$ORIGINAL_BRANCH" 2>/dev/null || true
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Collect all local branches
# ─────────────────────────────────────────────────────────────────────────────
mapfile -t LOCAL_BRANCHES < <(git for-each-ref --format='%(refname:short)' refs/heads/)

if [[ ${#LOCAL_BRANCHES[@]} -eq 0 ]]; then
    warn "No local branches found."
    exit 0
fi

log "Found ${#LOCAL_BRANCHES[@]} local branch(es): ${LOCAL_BRANCHES[*]}"

# ─────────────────────────────────────────────────────────────────────────────
# Process each branch: commit WIP if dirty, then push
# ─────────────────────────────────────────────────────────────────────────────
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %z')

for branch in "${LOCAL_BRANCHES[@]}"; do
    log "Processing branch: $branch"

    git checkout --quiet "$branch"

    # Stage all changes (including untracked)
    if [[ -n "$(git status --porcelain)" ]]; then
        git add --all
        COMMIT_MSG="chore: save WIP on $branch ($TIMESTAMP)"
        git commit -m "$COMMIT_MSG" --quiet
        info "Committed: $COMMIT_MSG"
    else
        info "Working tree clean — nothing to commit."
    fi

    # Push to remote (set upstream if missing)
    if git remote get-url "$REMOTE_NAME" &>/dev/null; then
        if git push --set-upstream "$REMOTE_NAME" "$branch" 2>&1; then
            info "Pushed '$branch' to '$REMOTE_NAME'."
        else
            warn "Push failed for '$branch' (permissions or network issue?)."
        fi
    else
        warn "Remote '$REMOTE_NAME' not configured — skipping push."
    fi
done

# ─────────────────────────────────────────────────────────────────────────────
# Pull main with rebase and push
# ─────────────────────────────────────────────────────────────────────────────
log "Pulling '$MAIN_BRANCH' with --rebase and pushing..."

git checkout --quiet "$MAIN_BRANCH"

if git show-ref --verify --quiet "refs/remotes/$REMOTE_NAME/$MAIN_BRANCH"; then
    if git pull --rebase "$REMOTE_NAME" "$MAIN_BRANCH" 2>&1; then
        info "Rebased '$MAIN_BRANCH' onto '$REMOTE_NAME/$MAIN_BRANCH'."
    else
        warn "Rebase failed — manual intervention may be needed."
    fi
fi

if git remote get-url "$REMOTE_NAME" &>/dev/null; then
    if git push --set-upstream "$REMOTE_NAME" "$MAIN_BRANCH" 2>&1; then
        info "Pushed '$MAIN_BRANCH' to '$REMOTE_NAME'."
    else
        warn "Push of '$MAIN_BRANCH' failed."
    fi
fi

log "All done!"
