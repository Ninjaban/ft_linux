install_libstd()
{
    version_gcc=7.2.0
    tar -xf gcc-${version_gcc}.tar.xz
    cd gcc-${version_gcc}
    
    mkdir -v build
    cd       build

    ../libstdc++-v3/configure           \
    --host=$LFS_TGT                     \
    --prefix=/tools                     \
    --disable-multilib                  \
    --disable-nls                       \
    --disable-libstdcxx-threads         \
    --disable-libstdcxx-pch             \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/7.2.0

    make
    make install

    cd ..
    rm -rf gcc-${version_gcc}
}
