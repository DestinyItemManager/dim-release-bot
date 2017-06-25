#!/bin/sh -exu

git config --global user.email "destinyitemmanager@gmail.com"
git config --global user.name "DIM Release Bot"

# Decrypt SSH key
openssl aes-256-cbc -K $encrypted_3184b4fb5b91_key -iv $encrypted_3184b4fb5b91_iv -in id_rsa.enc -out ~/.ssh/dim_travis.rsa -d
chmod 600 ~/.ssh/dim_travis.rsa
echo "Host github.com\n\tHostName github.com\n\tUser git\n\tIdentityFile ~/.ssh/dim_travis.rsa\n" >> ~/.ssh/config

# Clone project
git clone git@github.com:DestinyItemManager/DIM.git -b dev --depth 1

cd DIM

# bump version (creates tag and version commit)

if [ -e PATCH ]
then
    VERSION=$(npm version patch | sed 's/^v//')
    git rm PATCH
else
    VERSION=$(npm version minor | sed 's/^v//')

    # Build the changelog toaster
    # TODO: Add a sigil to changes so we can filter them down for this.
    CHANGES_HTML=$(perl -0777 -ne'print "$1\n" if /# Next\n*(.*?)\n{2,}/ms' CHANGELOG.md | perl -pe's/^\* /<li>/;s/$/<\/li>/;')

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
fi

# update changelog
perl -i'' -pe"s/^# Next/# Next\n\n# $VERSION/" CHANGELOG.md

# Add these other changes to the version commit
git add -u
git commit --amend --no-edit

# Set up SSH keys for rsync
cp ~/.ssh/dim_travis.rsa config
cp ../id_rsa.pub config/dim_travis.rsa.pub

# build and release using SSH keys
npm install
npm run publish-release

# push tags and changes
git push --tags origin dev:dev
