install_libstd()
{
    name=""
    version=$(find . -name "${name}*" -print0 | sed -r "s/.*${name}(.*)\.tar.*/\1/g")
    echo "Install ${name}${version}..."
    tar -xf ${name}${version}.tar*
    cd ${name}${version}
    
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
    make install && cd ..

    cd ..
    rm -rf ${name}${version}
}
