#!/bin/bash
# from: http://www.tomaz.me/2013/12/02/running-travis-ci-tests-on-arm.html
# Based on a test script from avsm/ocaml repo https://github.com/avsm/ocaml

CHROOT_DIR=/root
MIRROR=http://build.openrov.com:8080/view/Debian/job/OpenROV-DEBIAN-000-root-filesystem/lastSuccessfulBuild/artifact/deploy/debian-7.5-OpenROV-armhf-2014-09-06.tar.xz
VERSION=wheezy
CHROOT_ARCH=armhf

# Debian package dependencies for the host
HOST_DEPENDENCIES="debootstrap qemu-user-static binfmt-support sbuild"

# Debian package dependencies for the chrooted environment
GUEST_DEPENDENCIES=""

# Command used to run the tests
TEST_COMMAND="uname -a"

function setup_arm_chroot {
    # Host dependencies
    sudo apt-get install -qq -y ${HOST_DEPENDENCIES}

    # Create chrooted environment
    wget  -qO- ${MIRROR} | tar xvz
    ./lib/mount.sh debian-7.5-OpenROV-armhf-2014-09-06.img

    # Create file with environment variables which will be used inside chrooted
    # environment
    echo "export ARCH=${ARCH}" > envvars.sh
    echo "export TRAVIS_BUILD_DIR=${TRAVIS_BUILD_DIR}" >> envvars.sh
    chmod a+x envvars.sh

    # Install dependencies inside chroot
    sudo chroot ${CHROOT_DIR} apt-get update
//    sudo chroot ${CHROOT_DIR} apt-get --allow-unauthenticated install \
//        -qq -y ${GUEST_DEPENDENCIES}

    # Create build dir and copy travis build files to our chroot environment
    sudo mkdir -p ${CHROOT_DIR}/${TRAVIS_BUILD_DIR}
    sudo rsync -av ${TRAVIS_BUILD_DIR}/ ${CHROOT_DIR}/${TRAVIS_BUILD_DIR}/

    # Indicate chroot environment has been set up
    sudo touch ${CHROOT_DIR}/.chroot_is_done

    # Call ourselves again which will cause tests to run
    sudo chroot ${CHROOT_DIR} bash -c "cd ${TRAVIS_BUILD_DIR} && ./.travis-ci.sh"
}

if [ -e "/.chroot_is_done" ]; then
  # We are inside ARM chroot
  echo "Running inside chrooted environment"

  . ./envvars.sh
else
  if [ "${ARCH}" = "arm" ]; then
    # ARM test run, need to set up chrooted environment first
    echo "Setting up chrooted ARM environment"
    setup_arm_chroot
  fi
fi

echo "Running tests"
echo "Environment: $(uname -a)"

${TEST_COMMAND}

if [ -e "/.chroot_is_done" ]; then
  ./lib/unmount.sh
fi
