#!/bin/sh

set -e

printf "\033[0;32mDeploying updates to GitHub...\033[0m\n"

# Build the Project

hugo -t hello-friend-ng -d ../faresismail96.github.io/

# Go to Site repo

cd ../faresismail96.github.io/

#Add all the changes

git add .

# Commit changes.
msg="rebuilding site $(date)"
if [ -n "$*" ]; then
	msg="$*"
fi
git commit -m "$msg"

# Push source and build repos.

git push origin master

return 1