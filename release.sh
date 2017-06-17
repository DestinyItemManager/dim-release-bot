#!/bin/sh -exu

git config --global user.email "release@destinyitemmanager.com"
git config --global user.name "DIM Release Bot"

# Clone project
git clone https://${GH_TOKEN}@github.com/DestinyItemManager/DIM.git -b dev --depth 1

cd DIM

# bump version (creates tag and version commit)
VERSION=$(npm version minor | sed 's/^v//')

CHANGES_HTML=$(perl -0777 -ne'print "$1\n" if /# Next\n*(.*?)\n{2,}/ms' CHANGELOG.md | perl -pe's/^\* /<li>/;s/$/<\/li>/;')

# Build the changelog toaster
# TODO: Add a sigil to changes so we can filter them down for this.
echo "<div>
  <p>v$VERSION</p>
  <ul class=\"changelog-toaster\">
$CHANGES_HTML
  </ul>
  <p>View the <a href=\"https://github.com/DestinyItemManager/DIM/blob/dev/CHANGELOG.md\" target=\"_blank\">changelog</a> for
    the full history.</p>
  <p>Follow us on: <a style=\"margin: 0 5px;\" href=\"http://destinyitemmanager.reddit.com\" target=\"_blank\"><i class=\"fa fa-reddit fa-2x\"></i></a>
  <a style=\"margin: 0 5px;\" href=\"http://twitter.com/ThisIsDIM\" target=\"_blank\"><i class=\"fa fa-twitter fa-2x\"></i></a></p>
</div>
" > src/views/changelog-toaster-release.html

# update changelog
perl -i'' -pe"s/^# Next/# Next\n\n# $VERSION/" CHANGELOG.md

# Add these other changes to the version commit
git add -u
git commit --amend --no-edit

# build and release using SSH keys
npm install
npm run publish_release

# push tags and changes
git push --tags origin dev:dev
