#!/usr/bin/env bash
set -euo pipefail

################################################################################
# reset_repo.sh
# Fully resets the repo to a fresh main branch with no history, pushes to origin.
# Creates a backup tag before any destructive operations.
################################################################################

REMOTE_NAME="origin"
REMOTE_URL="https://github.com/mrsbeata/microsoft-365-community.git"
MAIN_BRANCH="main"

# Timestamp for backup tag and commit messages
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
TIMESTAMP_FULL=$(date +"%Y-%m-%d %H:%M:%S %z")
BACKUP_TAG="pre-reset-backup-${TIMESTAMP}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_step() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}STEP: $1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

log_error() {
    echo -e "${RED}✗ $1${NC}"
}

################################################################################
# STEP 1: Verify we are inside a git repo
################################################################################
log_step "Verifying we are inside a git repository"

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    log_error "Not inside a git repository!"
    echo "Please run this script from inside a git repository."
    exit 1
fi

GIT_ROOT=$(git rev-parse --show-toplevel)
log_success "Git repository found at: ${GIT_ROOT}"
cd "${GIT_ROOT}"

################################################################################
# STEP 2: Ensure origin remote points to the correct URL
################################################################################
log_step "Ensuring remote '${REMOTE_NAME}' points to ${REMOTE_URL}"

CURRENT_URL=$(git remote get-url "${REMOTE_NAME}" 2>/dev/null || echo "")

if [[ -z "${CURRENT_URL}" ]]; then
    log_warning "Remote '${REMOTE_NAME}' does not exist. Creating it..."
    git remote add "${REMOTE_NAME}" "${REMOTE_URL}"
    log_success "Remote '${REMOTE_NAME}' added with URL: ${REMOTE_URL}"
elif [[ "${CURRENT_URL}" != "${REMOTE_URL}" ]]; then
    log_warning "Remote '${REMOTE_NAME}' has different URL: ${CURRENT_URL}"
    log_warning "Updating to: ${REMOTE_URL}"
    git remote set-url "${REMOTE_NAME}" "${REMOTE_URL}"
    log_success "Remote '${REMOTE_NAME}' URL updated"
else
    log_success "Remote '${REMOTE_NAME}' already points to ${REMOTE_URL}"
fi

################################################################################
# STEP 3: Fetch all and prune
################################################################################
log_step "Fetching all branches and pruning stale references"

git fetch --all --prune
log_success "Fetch complete"

################################################################################
# STEP 4: Create backup tag and push it
################################################################################
log_step "Creating backup tag: ${BACKUP_TAG}"

# Get current HEAD (even if detached)
CURRENT_REF=$(git rev-parse HEAD 2>/dev/null || echo "")

if [[ -z "${CURRENT_REF}" ]]; then
    log_warning "No commits exist yet. Skipping backup tag creation."
else
    git tag "${BACKUP_TAG}" HEAD
    log_success "Backup tag '${BACKUP_TAG}' created at ${CURRENT_REF}"
    
    echo "Pushing backup tag to remote..."
    if git push "${REMOTE_NAME}" "${BACKUP_TAG}"; then
        log_success "Backup tag pushed to remote"
    else
        log_warning "Could not push backup tag (remote may not exist yet or access denied)"
    fi
fi

################################################################################
# STEP 5: Stage and commit all untracked/uncommitted files
################################################################################
log_step "Staging and committing all uncommitted changes"

# Check if there are any changes to commit
if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
    git add -A
    COMMIT_MSG="chore: final WIP before full reset (${TIMESTAMP_FULL})"
    git commit -m "${COMMIT_MSG}" || log_warning "Nothing to commit or commit failed"
    log_success "Committed all changes: ${COMMIT_MSG}"
else
    log_success "Working tree is clean, nothing to commit"
fi

################################################################################
# STEP 6: Delete all local branches except main
################################################################################
log_step "Deleting all local branches except '${MAIN_BRANCH}'"

# Get current branch
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")

# Ensure main exists locally (create from current HEAD if not)
if ! git show-ref --verify --quiet "refs/heads/${MAIN_BRANCH}"; then
    log_warning "Branch '${MAIN_BRANCH}' does not exist locally. Creating it..."
    git branch "${MAIN_BRANCH}" HEAD 2>/dev/null || true
fi

# Switch to main if not already on it
if [[ "${CURRENT_BRANCH}" != "${MAIN_BRANCH}" ]]; then
    git checkout "${MAIN_BRANCH}" 2>/dev/null || git checkout -b "${MAIN_BRANCH}" HEAD
fi

# Delete all other local branches
LOCAL_BRANCHES=$(git for-each-ref --format='%(refname:short)' refs/heads/ | grep -v "^${MAIN_BRANCH}$" || true)

if [[ -n "${LOCAL_BRANCHES}" ]]; then
    for branch in ${LOCAL_BRANCHES}; do
        echo "Deleting local branch: ${branch}"
        git branch -D "${branch}" 2>/dev/null || log_warning "Could not delete branch: ${branch}"
    done
    log_success "All local branches except '${MAIN_BRANCH}' deleted"
else
    log_success "No other local branches to delete"
fi

################################################################################
# STEP 7: Recreate main as a fresh root (orphan branch)
################################################################################
log_step "Recreating '${MAIN_BRANCH}' as a fresh root with no history"

# Create orphan branch
git checkout --orphan __temp_clean_root__

# Stage all files
git add -A

# Commit with timestamp
FRESH_COMMIT_MSG="feat: fresh start (${TIMESTAMP_FULL})"
git commit -m "${FRESH_COMMIT_MSG}"
log_success "Created fresh commit: ${FRESH_COMMIT_MSG}"

# Rename to main
git branch -M __temp_clean_root__ "${MAIN_BRANCH}"
log_success "Orphan branch renamed to '${MAIN_BRANCH}'"

################################################################################
# STEP 8: Force-push main to origin
################################################################################
log_step "Force-pushing '${MAIN_BRANCH}' to origin"

if git push "${REMOTE_NAME}" "${MAIN_BRANCH}" --force; then
    log_success "Successfully force-pushed '${MAIN_BRANCH}' to origin"
else
    log_error "Force-push failed!"
    echo ""
    echo -e "${YELLOW}This could mean:${NC}"
    echo "  1. The '${MAIN_BRANCH}' branch on GitHub has force-push protection enabled."
    echo "  2. You don't have permission to force-push to this repository."
    echo ""
    echo -e "${YELLOW}To fix this:${NC}"
    echo "  - Go to: https://github.com/mrsbeata/microsoft-365-community/settings/branches"
    echo "  - Find the branch protection rule for '${MAIN_BRANCH}'"
    echo "  - Temporarily disable 'Allow force pushes' restriction"
    echo "  - Re-run this script"
    echo "  - Re-enable protection after completion"
    echo ""
    echo -e "${YELLOW}Alternative (PR-based approach):${NC}"
    echo "  - Push to a temporary branch: git push ${REMOTE_NAME} ${MAIN_BRANCH}:temp-fresh-start"
    echo "  - Create a PR from temp-fresh-start to ${MAIN_BRANCH}"
    echo "  - Merge the PR (this will require admin override)"
    echo ""
    exit 1
fi

################################################################################
# STEP 9: Delete all remote branches except main
################################################################################
log_step "Deleting all remote branches except '${MAIN_BRANCH}'"

# Get list of remote branches (excluding HEAD and main)
REMOTE_BRANCHES=$(git for-each-ref --format='%(refname:short)' refs/remotes/${REMOTE_NAME}/ | \
    sed "s|^${REMOTE_NAME}/||" | \
    grep -v "^HEAD$" | \
    grep -v "^${MAIN_BRANCH}$" || true)

if [[ -n "${REMOTE_BRANCHES}" ]]; then
    for branch in ${REMOTE_BRANCHES}; do
        echo "Deleting remote branch: ${branch}"
        git push "${REMOTE_NAME}" --delete "${branch}" 2>/dev/null || log_warning "Could not delete remote branch: ${branch}"
    done
    log_success "All remote branches except '${MAIN_BRANCH}' deleted"
else
    log_success "No other remote branches to delete"
fi

################################################################################
# STEP 10: Push all tags to remote
################################################################################
log_step "Pushing all tags to remote"

git push "${REMOTE_NAME}" --tags
log_success "All tags pushed to remote"

################################################################################
# COMPLETE - Print rollback instructions
################################################################################
echo ""
echo -e "${GREEN}================================================================================${NC}"
echo -e "${GREEN}                         RESET COMPLETE!                                       ${NC}"
echo -e "${GREEN}================================================================================${NC}"
echo ""
echo -e "Your repository has been reset to a fresh '${MAIN_BRANCH}' branch with no history."
echo -e "All current files have been preserved in the new initial commit."
echo ""
echo -e "${YELLOW}ROLLBACK INSTRUCTIONS:${NC}"
echo -e "If you need to restore the previous state, run these commands:"
echo ""
echo -e "  ${BLUE}# Restore from backup tag${NC}"
echo -e "  git checkout -b restore-from-backup ${BACKUP_TAG}"
echo ""
echo -e "  ${BLUE}# Force-push the restored branch to main on origin${NC}"
echo -e "  git push ${REMOTE_NAME} +restore-from-backup:${MAIN_BRANCH}"
echo ""
echo -e "${YELLOW}BACKUP TAG:${NC} ${BACKUP_TAG}"
echo ""
echo -e "${GREEN}You can now refresh GitHub to verify the changes.${NC}"
echo ""
