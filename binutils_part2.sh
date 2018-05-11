install_binutils2()
{
    version_binutils=2.30
    tar -xf binutils-${version_binutils}.tar.xz
    cd binutils-${version_binutils}
    
    mkdir -v build
    cd build

    CC=$LFS_TGT-gcc                \
    AR=$LFS_TGT-ar                 \
    RANLIB=$LFS_TGT-ranlib         \
    ../configure                   \
        --prefix=/tools            \
        --disable-nls              \
        --disable-werror           \
        --with-lib-path=/tools/lib \
        --with-sysroot

    make
    make install

    make -C ld clean
    make -C ld LIB_PATH=/usr/lib:/lib
    cp -v ld/ld-new /tools/bin

    cd ..
    rm -rf binutils-${version_binutils}
}
