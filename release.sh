#!/bin/sh -exu

git config --global user.email "destinyitemmanager@gmail.com"
git config --global user.name "DIM Release Bot"

# Decrypt SSH key
openssl aes-256-cbc -K $encrypted_3184b4fb5b91_key -iv $encrypted_3184b4fb5b91_iv -in id_rsa.enc -out ~/.ssh/dim_travis.rsa -d
chmod 600 ~/.ssh/dim_travis.rsa
echo "Host github.com\n\tHostName github.com\n\tUser git\n\tIdentityFile ~/.ssh/dim_travis.rsa\n" >> ~/.ssh/config

# Clone project
git clone git@github.com:DestinyItemManager/DIM.git -b master --depth 1

cd DIM

# bump version (creates tag and version commit)

if [ -e PATCH ]
then
    VERSION=$(npm --no-git-tag-version version patch | sed 's/^v//')
    git rm PATCH
else
    VERSION=$(npm --no-git-tag-version version minor | sed 's/^v//')
fi

NEW_CHANGES=$(perl -0777 -ne'print "$1\\n" if /# Next\n*(.*?)\n{2,}/ms' docs/CHANGELOG.md | perl -e 'while(<>) { $_ =~ s/[\r\n]/\\n/g; print "$_" }' )

# update changelog
perl -i'' -pe"s/^# Next/# Next\n\n# $VERSION ($(TZ="America/Los_Angeles" date +"%Y-%m-%d"))/" docs/CHANGELOG.md

# Add these other changes to the version commit
git add -u
git commit -m"$VERSION"
git tag "v$VERSION"

# Set up SSH keys for rsync
cp ~/.ssh/dim_travis.rsa config
cp ../id_rsa.pub config/dim_travis.rsa.pub

# build and release using SSH keys
yarn install
yarn run publish-release

# push tags and changes
git push --tags origin master:master

# publish a release on GitHub
API_JSON=$(printf '{"tag_name": "v%s","name": "%s","body": "%s","draft": false,"prerelease": false}' "$VERSION" "$VERSION" "$NEW_CHANGES")
curl --data "$API_JSON" "https://api.github.com/repos/DestinyItemManager/DIM/releases?access_token=$GITHUB_ACCESS_TOKEN"

curl -X POST "https://api.cloudflare.com/client/v4/zones/2c34c69276ed0f6eb2b9e1518fe56f74/purge_cache" \
     -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
     -H "X-Auth-Key: $CLOUDFLARE_KEY" \
     -H "Content-Type: application/json" \
     --data '{"files":["https://app.destinyitemmanager.com/index.html", "https://app.destinyitemmanager.com/version.json", "https://app.destinyitemmanager.com/service-worker.js", "https://app.destinyitemmanager.com/gdrive-return.html", "https://app.destinyitemmanager.com/return.html", "https://app.destinyitemmanager.com/manifest-webapp-6-2018.json", "https://app.destinyitemmanager.com/manifest-webapp-6-2018-ios.json"]}'
