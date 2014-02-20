#!/bin/sh

# Submit a build on the openSUSE Build Service. You need to have an
# account and have configured the osc client.

project=home:mgeisler
package=zvm-validator

if [ ! -d $project/$package ]; then
    osc checkout $project $package
fi
osc update $project/$package

git archive HEAD -o $project/$package/$package.tar.gz
osc commit --skip-validation -m "Git commit $commit" $project
