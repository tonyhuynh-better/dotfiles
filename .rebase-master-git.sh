#! /bin/zsh

export currentBranch=$(git branch --show-current)
echo
echo "rebasing $currentBranch"
echo
git checkout master
git pull --ff-only
git checkout $currentBranch
git rebase master
echo
echo "done rebasing $currentBranch"
echo
