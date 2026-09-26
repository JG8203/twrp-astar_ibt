# Reproducible build environment for the RQ-713 TWRP port.
#
#   docker build -t twrp-astar-ibt-builder .
#   docker run --rm -it -v "$PWD/..:/work" -v "$HOME/twrp-build:/build" \
#       -e BUILD_DIR=/build twrp-astar-ibt-builder bash -lc 'cd /work && ./build_twrp.sh'
#
# (Or simply run ../docker/build.sh from the project root.)

FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive TZ=UTC

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openjdk-8-jdk git git-lfs gnupg flex bison gperf build-essential zip curl \
        zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 lib32ncurses-dev \
        lib32ncurses5-dev libncurses5 libncurses5-dev lib32readline-dev \
        libx11-dev lib32z1-dev ccache libgl1-mesa-dev libdw-dev libelf-dev \
        libsdl1.2-dev libxml2-dev libxml2-utils xsltproc unzip fontconfig \
        python2 python3 python3-protobuf protobuf-compiler bc libssl-dev rsync \
        cpio sudo file ca-certificates imagemagick pngcrush lzop lz4 \
        schedtool squashfs-tools && \
    ln -sf /usr/bin/python2 /usr/bin/python && \
    rm -rf /var/lib/apt/lists/*

# repo launcher (needs python3 + git)
RUN curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo \
        -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo && \
    git config --global user.email "builder@localhost" && \
    git config --global user.name "TWRP Builder" && \
    git config --global color.ui false

WORKDIR /work
