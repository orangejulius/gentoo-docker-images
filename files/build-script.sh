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
apk --no-cache add gnupg tar wget xz ca-certificates autoconf automake gettext gcc build-base libgcrypt-dev libgpg-error-dev libassuan-dev libksba-dev npth-dev gettext-dev

wget -q -c "${DIST}/${STAGE3PATH}" "${DIST}/${STAGE3PATH}.CONTENTS" "${DIST}/${STAGE3PATH}.DIGESTS.asc"

# verify downloaded stage 3 archive, using multiple keyservers if needed
gpg --keyserver hkps.pool.sks-keyservers.net --recv-keys ${SIGNING_KEY} \
 || gpg --keyserver keys.gnupg.net --recv-keys ${SIGNING_KEY} \
 || gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys ${SIGNING_KEY} \
 && gpg --verify "${STAGE3}.DIGESTS.asc"


awk '/# SHA512 HASH/{getline; print}' ${STAGE3}.DIGESTS.asc | sha512sum -c

# extract stage3 archive
tar xpf "${STAGE3}" --xattrs --numeric-owner

# tell Gentoo we are in a docker world (i think)
sed -i -e 's/#rc_sys=""/rc_sys="docker"/g' etc/rc.conf \

# set timezone
echo 'UTC' > etc/timezone

# cleanup
rm ${STAGE3}.DIGESTS.asc ${STAGE3}.CONTENTS ${STAGE3}

cd /root

## build a static gpg to bootstrap authentication of snapshots within the next step
GNUPG_VERSION=1.4.22
gpg --keyserver pgp.mit.edu --recv-keys 0x249B39D24F25E3B6
gpg --keyserver pgp.mit.edu --recv-keys 0x2071B08A33BD3F06
wget https://www.gnupg.org/ftp/gcrypt/gnupg/gnupg-${GNUPG_VERSION}.tar.bz2
wget https://www.gnupg.org/ftp/gcrypt/gnupg/gnupg-${GNUPG_VERSION}.tar.bz2.sig

gpg --verify gnupg-${GNUPG_VERSION}.tar.bz2.sig gnupg-${GNUPG_VERSION}.tar.bz2

tar xvpf gnupg-${GNUPG_VERSION}.tar.bz2

export LDFLAGS="-static"
cd gnupg-$GNUPG_VERSION
./autogen.sh
./configure --enable-static-rnd=linux
nice make -j4

# copy executable
cp ./g10/gpg /gentoo/usr/bin
# copy subprograms
mkdir -p /gentoo/usr/local/libexec/gnupg
cp ./keyserver/gpgkeys_curl /gentoo/usr/local/libexec/gnupg
cp ./keyserver/gpgkeys_hkp /gentoo/usr/local/libexec/gnupg
