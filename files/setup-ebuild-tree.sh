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
