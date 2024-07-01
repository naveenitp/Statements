
#!/bin/bash

# Directory to watch
WATCHED_DIR="D:\\ITP\\git"

# Change to the watched directory
cd "$WATCHED_DIR"

# Run watchman and trigger the sync on file change
watchman watch "$WATCHED_DIR"
watchman -- trigger "$WATCHED_DIR" sync-changes '*' -- bash -c '
    git add -A
    git commit -m "Auto-sync: $(date)"
    git push origin main || git push origin master
'
