+++
author = "Fares Ismail"
date = "2019-09-03T20:55:00+00:00"
title = "Interactive Rebase for a Cleaner Git Commit History"
highlight = "true"
tags = [
    "git",
    "rebase",
    "fixup",
]
+++

Any article you read online about maintaining a clean project will mention a version control system (usually git) and will then talk about maintaining a clean commit history through atomic commits, meaningful commit messages and so on.

This article wont go into all the techniques above, instead Im going to focus on a single technique that I have recently learned: `Interactive Rebase`.

No matter how hard we try to keep our commit messages clean and clear, we often end up with something looking like this:

``` text
commit 89b4001bd1176243c6c338e18cf0039f2e1556a9 (HEAD -> master)
Author: Fares Ismail
Date:   Mon Sep 2 22:32:18 2019 +0200

    How About Now?

commit ba2998d748c30d2c334f688eb9900c6e3508548a
Author: Fares Ismail
Date:   Mon Sep 2 22:31:48 2019 +0200

    Hope My tests Pass now...

commit 8416c111d95c8cbcfa1f34deef515ca67676aecf
Author: Fares Ismail
Date:   Mon Sep 2 22:31:25 2019 +0200

    Added Unit Tests

commit efe7e3fad95af4c9b9edf780d5f7a5666662f099
Author: Fares Ismail
Date:   Mon Sep 2 22:30:53 2019 +0200

    Fixed Main Function

commit 5946d2e49a073e2d20c7f0bb97fa4ae2c8393dbc
Author: Fares Ismail
Date:   Mon Sep 2 22:30:05 2019 +0200

    Fixed typo in Main Function

commit 537dd485e5afbd8754a2ba5b68bf39a9580a6342
Author: Fares Ismail
Date:   Mon Sep 2 22:29:23 2019 +0200

    Added Man function

commit 5aedeb40a8c8f09b6ec876f1ef625108a2a9ad27
Author: Fares Ismail
Date:   Mon Sep 2 22:21:41 2019 +0200

    Initial Commit

```

Clearly this is not ideal... it starts off good and then its a slippery slope back to chaos.

So whats wrong with my Commit History?
Well the 2nd, 3rd and 4th commits are practically the same thing and could have been done in a single commit.

The same can be said about commits number 5, 6 and 7. Although commit 7 is just sad...

So here comes the interactive rebase to the rescue. More specifically, the Fixup.

`ﬁ rebase -i HEAD~6` to interactively rebase the last 6 commits.

This will generally open up your git editor, by default its vim.

``` text
pick 537dd48 Added Man function
pick 5946d2e Fixed typo in Main Function
pick efe7e3f Fixed Main Function
pick 8416c11 Added Unit Tests
pick ba2998d Hope My tests Pass now...
pick 89b4001 How About Now?

# Rebase 5aedeb4..89b4001 onto 5aedeb4 (6 commands)
#
# Commands:
# p, pick <commit> = use commit
# r, reword <commit> = use commit, but edit the commit message
# e, edit <commit> = use commit, but stop for amending
# s, squash <commit> = use commit, but meld into previous commit
# f, fixup <commit> = like "squash", but discard this commit's log message
# x, exec <command> = run command (the rest of the line) using shell
# b, break = stop here (continue rebase later with 'git rebase --continue')
# d, drop <commit> = remove commit
# l, label <label> = label current HEAD with a name
# t, reset <label> = reset HEAD to a label
# m, merge [-C <commit> | -c <commit>] <label> [# <oneline>]
# .       create a merge commit using the original merge commit's
# .       message (or the oneline, if no original merge commit was
# .       specified). Use -c <commit> to reword the commit message.
#
# These lines can be re-ordered; they are executed from top to bottom.
#
# If you remove a line here THAT COMMIT WILL BE LOST.
```

At the top we see our last six commits. later we see the possible transformations we can apply on them.

Most of the options are pretty self explanatory, but Ill be focusing on 3 in particular:

- Reword

- Fixup

- Squash

To start with the simplest case:

### Reword

Reword is my chance to tell the world that I actually do know how to write `Main` (If you haven't caught it by now, check my first commit... it says Man :/)

Simply erase the pick prior to the first commit and replace it with `r` or `reword`.
press :x and a new page will show up:

```text

Added Man function

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#

```

### Fixup

Alright, so on to more interesting stuff, as mentioned before some of my commits can be combined into one all while dropping the useless commit messages. This is exactly what fixup does. it re-writes the commits to the closest previous commit.

``` text
pick 33ff399 Added Main function
pick da9cc20 Fixed typo in Main Function
pick 5db3c38 Fixed Main Function
pick 1092c6e Added Unit Tests
f 0206a22 Hope My tests Pass now...
f 6728363 How About Now???
```
The following will re-write the last two commits onto the last previous one (`Added Unit Tests`)
The result ends up looking like this:

``` text
commit 6fc9e00fe20ff2c487cb14cfb20ad758cec7e771 (HEAD -> master)
Author: Fares Ismail
Date:   Mon Sep 2 22:31:25 2019 +0200

    Added Unit Tests

commit 5db3c38ff0a4566776b42c01a6775f83f3123191
Author: Fares Ismail
Date:   Mon Sep 2 22:30:53 2019 +0200

    Fixed Main Function

commit da9cc2021c2e7bf75673a2ed99b8d8a1cc0cdb1a
Author: Fares Ismail
Date:   Mon Sep 2 22:30:05 2019 +0200

    Fixed typo in Main Function

commit 33ff39916c98340fd4dab11f5dbf1a07fd6e35fd
Author: Fares Ismail
Date:   Mon Sep 2 22:29:23 2019 +0200

    Added Main function

commit 5aedeb40a8c8f09b6ec876f1ef625108a2a9ad27
Author: Fares Ismail
Date:   Mon Sep 2 22:21:41 2019 +0200

    Initial Commit
```

a bit cleaner no?

Those with a keen eye will notice that the commit hash for `Added Unit Tests` changed, this is because the commit was modified to include the two other commits.
Note that when pushing this to the remote branch, you might need to use `--force-with-lease` or `--force` since the local commit history no longer matches the remote version

### Squash

Squash is a bit similar to fixup only that it doesn't discard the commit messages, instead it melds them together.

```text
pick 33ff399 Added Main function
s da9cc20 Fixed typo in Main Function
s 5db3c38 Fixed Main Function
pick 6fc9e00 Added Unit Tests
```

executing this will pop the following:

``` text
# This is a combination of 3 commits.
# This is the 1st commit message:

Added Main function

# This is the commit message #2:

Fixed typo in Main Function

# This is the commit message #3:

Fixed Main Function

```

This allows us to make a modification to each commit message.

applying the above will yield the following commit history:

```text
commit b9d8ce4bd94bdec74b81782e5d684a5207287a03 (HEAD -> master)
Author: Fares Ismail
Date:   Mon Sep 2 22:31:25 2019 +0200

    Added Unit Tests

commit 7641555428b5abe903667f799a0deeefb21b2027
Author: Fares Ismail
Date:   Mon Sep 2 22:29:23 2019 +0200

    Added Main functions

    Fixed typo in Main Functions

    Fixed Main Functions

commit 5aedeb40a8c8f09b6ec876f1ef625108a2a9ad27
Author: Fares Ismail
Date:   Mon Sep 2 22:21:41 2019 +0200

    Initial Commit
```

Much cleaner than what we originally started with no?
