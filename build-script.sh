#!/bin/bash

set -exu

# cd to workdir
mkdir /gentoo
cd /gentoo



SUFFIX=${suffix:-} # set default
STAGE3PATH="$(wget -q -O- "${DIST}/latest-stage3-${MICROARCH}${SUFFIX}.txt" | tail -n 1 | cut -f 1 -d ' ')"
STAGE3="$(basename ${STAGE3PATH})"

echo "Building Gentoo Container image for ${ARCH} ${SUFFIX} fetching from ${DIST}"

# install required dependencies
apk --no-cache add gnupg tar wget xz


wget -q -c "${DIST}/${STAGE3PATH}" "${DIST}/${STAGE3PATH}.CONTENTS" "${DIST}/${STAGE3PATH}.DIGESTS.asc"

# verify downloaded stage 3 archive, using multiple keyservers if needed
gpg --keyserver hkps.pool.sks-keyservers.net --recv-keys ${SIGNING_KEY} \
 || gpg --keyserver keys.gnupg.net --recv-keys ${SIGNING_KEY} \
 || gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys ${SIGNING_KEY} \
 && gpg --verify "${STAGE3}.DIGESTS.asc"


awk '/# SHA512 HASH/{getline; print}' ${STAGE3}.DIGESTS.asc | sha512sum -c

# extract stage3 archive
tar xjpf "${STAGE3}" --xattrs --numeric-owner \

# tell Gentoo we are in a docker world (i think)
sed -i -e 's/#rc_sys=""/rc_sys="docker"/g' etc/rc.conf \

# set timezone
echo 'UTC' > etc/timezone

# cleanup
rm ${STAGE3}.DIGESTS.asc ${STAGE3}.CONTENTS ${STAGE3} \

# download ebuild tree snapshot
wget -q -c "${SNAPSHOT_DIST}/${SNAPSHOT}" "${SNAPSHOT_DIST}/${SNAPSHOT}.gpgsig" "${SNAPSHOT_DIST}/${SNAPSHOT}.md5sum" \

# verify ebuild tree snapshot, similar to the archive
gpg --keyserver hkps.pool.sks-keyservers.net --recv-keys ${SNAPSHOT_SIGNING_KEY} \
 && gpg --verify "${SNAPSHOT}.gpgsig" "${SNAPSHOT}" \
 || gpg --keyserver keys.gnupg.net --recv-keys ${SNAPSHOT_SIGNING_KEY} \
 || gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys ${SNAPSHOT_SIGNING_KEY} \
 && md5sum -c ${SNAPSHOT}.md5sum \

# extract portage snapshot and clean up
mkdir -p usr/portage/distfiles usr/portage/packages \
 && tar xpf "${SNAPSHOT}" -C usr \
 && rm ${SNAPSHOT} ${SNAPSHOT}.gpgsig ${SNAPSHOT}.md5sum
