# This Dockerfile creates a gentoo container image with the portage snapshot built in, to allow for it to be used as a baseimage for other Dockerfiles (i.e. emerge should work out of the box). It does this by effectively combining the stage3 and portage Dockerfiles and storing /usr/portage in the image rather than on a volume.

ARG BOOTSTRAP
FROM ${BOOTSTRAP:-alpine:3.6} as builder

WORKDIR /

ARG ARCH=amd64
ARG MICROARCH=amd64
ARG SUFFIX
ARG DIST="http://distfiles.gentoo.org/releases/${ARCH}/autobuilds/"
ARG SIGNING_KEY="0xBB572E0E2D182910"

COPY files/build-script.sh /

RUN /bin/sh /build-script.sh

# take the stage3 downloaded in the alpine image and use it as a new container base
FROM scratch

WORKDIR /
COPY --from=builder /gentoo/ /

# install custom make.conf
COPY files/make.conf /etc/portage/make.conf

# make directories for custom config
RUN mkdir -p /etc/portage/package.use /etc/portage/package.accept_keywords

COPY files/emerge-wrapper.sh /

# install gpg for real
RUN /emerge-wrapper.sh app-crypt/gnupg -j2

# emerge world, once with no security settings changes
RUN /emerge-wrapper.sh -e world -j2

# a few system things cannot be built in containers without this flag
RUN FEATURES="-sandbox -usersandbox" /emerge-wrapper.sh --resume

CMD ["/bin/bash"]
