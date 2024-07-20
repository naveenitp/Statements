#!/bin/bash

# Directory to watch
WATCHED_DIR="D:/ITP/git"

# Change to the watched directory
cd "$WATCHED_DIR"

# Initialize Git if not already initialized
if [ ! -d ".git" ]; then
    git init
    git remote add origin https://github.com/naveenitp/Statements.git
fi

# Run watchman and trigger the sync on file change
watchman watch "$WATCHED_DIR"
watchman -- trigger "$WATCHED_DIR" sync-changes '*' -- bash -c '
    echo "Changes detected, running Git commands..."
    git add -A
    git commit -m "Auto-sync: $(date)" || echo "Nothing to commit"
    
    # Pull the latest changes from the remote branch and rebase
    git pull origin main --rebase || git pull origin master --rebase
    
    # Push the changes to the remote branch
    git push origin main || git push origin master
'
