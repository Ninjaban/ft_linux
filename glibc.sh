install_glibc()
{
    version_glibc=2.26
    tar -xf glibc-${version_glibc}.tar.xz
    cd glibc-${version_glibc}
    
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
    rm -rf glibc-${version_glibc}
}
