#!/bin/bash

if ! command -v realpath &> /dev/null
then
    realpath() {
        [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
    }
fi

# Get the path of this script
SCRIPTPATH=$(realpath  $(dirname "$0"))

cd "${SCRIPTPATH}"

if [ ! -d "${SCRIPTPATH}/KERNEL" ]
then
    echo "KERNEL" directory missing, please run ./build_deb.sh first
    exit 1
fi

cd KERNEL

# Get the name of the currently checked-out branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$CURRENT_BRANCH" == "csd" ]
then
    echo "csd branch already created, skipping..."
    exit 1
fi

# Create "csd" branch
git checkout -b csd

# Apply patches
git am ../patches/csd/*.patch

# Copy .config
cp ../csd/linux/.config .