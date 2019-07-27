set -e

printf  "\033[0;32mCommiting updates Locally...\033[0m\n"

#Add all the changes

git add .

# Commit changes.

msg="updating site $(date)"
if [ -n "$*" ]; then
	msg="$*"
fi

git commit -m "$msg"

printf  "\033[0;32mPushing updates to origin...\033[0m\n"

# Push updates.

git push origin master

read