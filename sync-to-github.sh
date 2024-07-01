WATCHED_DIR="/d/ITP/git"

git add -A
git commit -m "Auto-sync: $(date)"
git push origin main

fswatch -o $WATCHED_DIR | while read
do
	git add -A
	git commit -m "Auto-sync: $(date)"
	git push origin main
done

