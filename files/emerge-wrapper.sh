#!/bin/bash
set -ex

SNAPSHOT_NAME="portage-latest.tar.xz"
SNAPSHOT_DIST="http://distfiles.gentoo.org/snapshots"
SNAPSHOT_SIGNING_KEY="0xEC590EEAC9189250"

# download ebuild tree snapshot
wget -q -c "${SNAPSHOT_DIST}/${SNAPSHOT_NAME}" "${SNAPSHOT_DIST}/${SNAPSHOT_NAME}.gpgsig" "${SNAPSHOT_DIST}/${SNAPSHOT_NAME}.md5sum"

# verify ebuild tree snapshot, similar to the archive
gpg --keyserver hkps.pool.sks-keyservers.net --recv-keys ${SNAPSHOT_SIGNING_KEY} \
 || gpg --keyserver keys.gnupg.net --recv-keys ${SNAPSHOT_SIGNING_KEY} \
 || gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys ${SNAPSHOT_SIGNING_KEY} \
 && gpg --verify "${SNAPSHOT_NAME}.gpgsig" "${SNAPSHOT_NAME}"

# extract portage snapshot and clean up
mkdir -p /usr/portage/distfiles /usr/portage/packages
tar xpf "${SNAPSHOT_NAME}" -C /usr
rm ${SNAPSHOT_NAME} ${SNAPSHOT_NAME}.gpgsig ${SNAPSHOT_NAME}.md5sum

# these features conflict with containers which already sandbox
# for our purposes the dual sandboxing is not needed
FEATURES="-sandbox -usersandbox" emerge $@

## remove all traces of the ebuild tree to prevent large images
rm -rf /usr/portage

eselect news purge
