# This Dockerfile creates a gentoo container image with the portage snapshot built in, to allow for it to be used as a baseimage for other Dockerfiles (i.e. emerge should work out of the box). It does this by effectively combining the stage3 and portage Dockerfiles and storing /usr/portage in the image rather than on a volume.

ARG BOOTSTRAP
FROM ${BOOTSTRAP:-alpine:3.6} as builder

WORKDIR /gentoo

ARG ARCH=amd64
ARG MICROARCH=amd64
ARG SUFFIX
ARG DIST="http://distfiles.gentoo.org/releases/${ARCH}/autobuilds/"
ARG SIGNING_KEY="0xBB572E0E2D182910"

ARG SNAPSHOT="portage-latest.tar.xz"
ARG SNAPSHOT_DIST="http://distfiles.gentoo.org/snapshots"
ARG SNAPSHOT_SIGNING_KEY="0xEC590EEAC9189250"

RUN echo "Building Gentoo Container image for ${ARCH} ${SUFFIX} fetching from ${DIST}" \
 && apk --no-cache add gnupg tar wget xz \
 && STAGE3PATH="$(wget -q -O- "${DIST}/latest-stage3-${MICROARCH}${SUFFIX}.txt" | tail -n 1 | cut -f 1 -d ' ')" \
 && STAGE3="$(basename ${STAGE3PATH})" \
 && wget -q -c "${DIST}/${STAGE3PATH}" "${DIST}/${STAGE3PATH}.CONTENTS" "${DIST}/${STAGE3PATH}.DIGESTS.asc" \
 && gpg --keyserver hkps.pool.sks-keyservers.net --recv-keys ${SIGNING_KEY} \
 || gpg --keyserver keys.gnupg.net --recv-keys ${SIGNING_KEY} \
 || gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys ${SIGNING_KEY} \
 && gpg --verify "${STAGE3}.DIGESTS.asc" \
 && awk '/# SHA512 HASH/{getline; print}' ${STAGE3}.DIGESTS.asc | sha512sum -c \
 && tar xjpf "${STAGE3}" --xattrs --numeric-owner \
 && sed -i -e 's/#rc_sys=""/rc_sys="docker"/g' etc/rc.conf \
 && echo 'UTC' > etc/timezone \
 && rm ${STAGE3}.DIGESTS.asc ${STAGE3}.CONTENTS ${STAGE3} \
 && wget -q -c "${SNAPSHOT_DIST}/${SNAPSHOT}" "${SNAPSHOT_DIST}/${SNAPSHOT}.gpgsig" "${SNAPSHOT_DIST}/${SNAPSHOT}.md5sum" \
 && gpg --keyserver hkps.pool.sks-keyservers.net --recv-keys ${SNAPSHOT_SIGNING_KEY} \
 && gpg --verify "${SNAPSHOT}.gpgsig" "${SNAPSHOT}" \
 || gpg --keyserver keys.gnupg.net --recv-keys ${SNAPSHOT_SIGNING_KEY} \
 || gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys ${SNAPSHOT_SIGNING_KEY} \
 && md5sum -c ${SNAPSHOT}.md5sum \
 && mkdir -p usr/portage/distfiles usr/portage/packages \
 && tar xpf "${SNAPSHOT}" -C usr \
 && rm ${SNAPSHOT} ${SNAPSHOT}.gpgsig ${SNAPSHOT}.md5sum

FROM scratch

WORKDIR /
COPY --from=builder /gentoo/ /

RUN emerge -e world # rebuld the world :)

CMD ["/bin/bash"]
