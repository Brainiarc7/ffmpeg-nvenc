#!/bin/bash

# This script will compile and install a static ffmpeg build with support for
# nvenc on ubuntu. See the prefix path and compile options if edits are needed
# to suit your needs.

set -e

root_dir="$(pwd)"

source_dir="${root_dir}/source"
mkdir -p $source_dir
build_dir="${root_dir}/build"
mkdir -p $build_dir
bin_dir="${root_dir}/bin"
mkdir -p $bin_dir
inc_dir="${build_dir}/include"
mkdir -p $inc_dir

export PATH=$bin_dir:$PATH

InstallDependencies() {
    echo "Installing dependencies"
    sudo apt-get -y --force-yes install autoconf automake build-essential libass-dev \
        libfreetype6-dev libgpac-dev libsdl1.2-dev libtheora-dev libtool libva-dev \
        libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev \
        pkg-config texi2html zlib1g-dev nasm
}

InstallNvidiaSDK() {
    echo "Installing the nVidia NVENC SDK"
    sdk_version="6.0.1"
    sdk_basename="nvidia_video_sdk_${sdk_version}"
    sdk_url="http://developer.download.nvidia.com/assets/cuda/files/${sdk_basename}.zip"
    cd $source_dir
    wget $sdk_url
    unzip "$sdk_basename.zip"
    cd $sdk_basename
    cp -a Samples/common/inc/* $inc_dir
}

BuildYasm() {
    echo "Compiling yasm"
    cd $source_dir
    yasm_version="1.3.0"
    yasm_basename="yasm-${yasm_version}"
    wget http://www.tortall.net/projects/yasm/releases/${yasm_basename}.tar.gz
    tar xzf "${yasm_basename}.tar.gz"
    cd $yasm_basename
    ./configure --prefix="${build_dir}" --bindir="${bin_dir}"
    make
    make install
    make distclean
}

BuildX264() {
    echo "Compiling libx264"
    cd $source_dir
    wget http://download.videolan.org/pub/x264/snapshots/last_x264.tar.bz2
    tar xjf last_x264.tar.bz2
    cd x264-snapshot*
    ./configure --prefix="$build_dir" --bindir="$bin_dir" --enable-static
    make
    make install
    make distclean
}

BuildLibfdkcc() {
    echo "Compiling libfdk-cc"
    cd $source_dir
    wget -O fdk-aac.zip https://github.com/mstorsjo/fdk-aac/zipball/master
    unzip fdk-aac.zip
    cd mstorsjo-fdk-aac*
    autoreconf -fiv
    ./configure --prefix="$build_dir" --disable-shared
    make
    make install
    make distclean
}

BuildLibMP3Lame() {
    echo "Compiling libmp3lame"
    cd $source_dir
    lame_version="3.99.5"
    lame_basename="lame-${lame_version}"
    wget "http://downloads.sourceforge.net/project/lame/lame/3.99/${lame_basename}.tar.gz"
    tar xzf "${lame_basename}.tar.gz"
    cd $lame_basename
    ./configure --prefix="$build_dir" --enable-nasm --disable-shared
    make
    make install
    make distclean
}

BuildLibOpus() {
    echo "Compiling libopus"
    cd $source_dir
    opus_version="1.1"
    opus_basename="opus-${opus_version}"
    wget "http://downloads.xiph.org/releases/opus/${opus_basename}.tar.gz"
    tar xzf "${opus_basename}.tar.gz"
    cd $opus_basename
    ./configure --prefix="$build_dir" --disable-shared
    make
    make install
    make distclean
}

BuildLibPvx() {
    echo "Compiling libvpx"
    cd $source_dir
    vpx_version="1.3.0"
    vpx_basename="libvpx-v${vpx_version}"
    wget http://webm.googlecode.com/files/${vpx_basename}.tar.bz2
    tar xjf "${vpx_basename}.tar.bz2"
    cd $vpx_basename
    ./configure --prefix="$build_dir" --disable-examples
    make
    make install
    make clean
}

BuildFFmpeg() {
    echo "Compiling ffmpeg"
    cd $source_dir
    wget http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
    tar xjf ffmpeg-snapshot.tar.bz2
    cd ffmpeg
    PKG_CONFIG_PATH="${build_dir}/lib/pkgconfig" ./configure \
        --prefix="$build_dir" \
        --extra-cflags="-I$inc_dir" \
        --extra-ldflags="-L$build_dir/lib" \
        --bindir="$bin_dir" \
        --enable-gpl \
        --enable-libass \
        --enable-libfdk-aac \
        --enable-libfreetype \
        --enable-libmp3lame \
        --enable-libopus \
        --enable-libtheora \
        --enable-libvorbis \
        --enable-libvpx \
        --enable-libx264 \
        --enable-nonfree \
        --enable-nvenc
    make
    make install
    make distclean
}


if [ $1 ]; then
    $1
else
    InstallDependencies
    InstallNvidiaSDK
    BuildYasm
    BuildX264
    BuildLibfdkcc
    BuildLibMP3Lame
    BuildLibOpus
    BuildLibPvx
    BuildFFmpeg
fi
