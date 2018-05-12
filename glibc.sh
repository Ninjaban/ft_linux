install_glibc()
{
    name="glibc-"
    version=$(find . -name "${name}*" -print0 | sed -r "s/.*${name}(.*)\.tar.*/\1/g")
    tar -xf ${name}${version}.tar*
    cd ${name}${version}
    
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
    rm -rf ${name}${version}
}
