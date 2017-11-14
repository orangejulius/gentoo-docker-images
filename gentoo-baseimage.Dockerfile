# This Dockerfile creates a gentoo container image with the portage snapshot built in, to allow for it to be used as a baseimage for other Dockerfiles (i.e. emerge should work out of the box). It does this by effectively combining the stage3 and portage Dockerfiles and storing /usr/portage in the image rather than on a volume.

ARG BOOTSTRAP
FROM ${BOOTSTRAP:-alpine:3.6} as builder

WORKDIR /

ARG ARCH=amd64
ARG MICROARCH=amd64
ARG SUFFIX
ARG DIST="http://distfiles.gentoo.org/releases/${ARCH}/autobuilds/"
ARG SIGNING_KEY="0xBB572E0E2D182910"

ARG SNAPSHOT="portage-latest.tar.xz"
ARG SNAPSHOT_DIST="http://distfiles.gentoo.org/snapshots"
ARG SNAPSHOT_SIGNING_KEY="0xEC590EEAC9189250"

COPY build-script.sh /

RUN /bin/sh /build-script.sh

FROM scratch

WORKDIR /
COPY --from=builder /gentoo/ /

# install custom make.conf
COPY make.conf /etc/portage/make.conf

RUN emerge --sync

# disable features that need ptrace during build
RUN FEATURES="-sandbox -usersandbox" emerge -e world # rebuld the world :)

RUN eselect news read # i hate this notification :P

RUN mkdir -p /etc/portage/package.use /etc/portage/package.accept_keywords

CMD ["/bin/bash"]
