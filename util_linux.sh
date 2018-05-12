install_util-linux()
{
    version_util_linux=2.30.1
    tar -xf util-linux-${version_util_linux}.tar.xz
    cd util-linux-${version_util_linux}
    
    mkdir -v build
    cd       build

    ../configure                                \
        --prefix=/tools                         \
        --host=$LFS_TGT                         \
        --build=$(../scripts/config.guess)      \
        --enable-kernel=3.2                     \
        --with-headers=/tools/include           \
        libc_cv_forced_unwind=yes               \
        libc_cv_c_cleanup=yes

    make
    make install

    cd ..
    rm -rf util-linux-${version_util_linux}
}
