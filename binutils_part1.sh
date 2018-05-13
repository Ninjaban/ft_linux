install_binutils()
{
    name="binutils-"
    version=$(find . -name "${name}*" -print0 | sed -r "s/.*${name}(.*)\.tar.*/\1/g")
    echo "Install ${name}${version}..."
    tar -xf ${name}${version}.tar*
    cd ${name}${version}
    
    mkdir -v build
    cd build

    ../configure --prefix=/tools            \
             --with-sysroot=$LFS            \
             --with-lib-path=/tools/lib     \
             --target=$LFS_TGT              \
             --disable-nls                  \
             --disable-werror
    
    make 

    case $(uname -m) in
	x86_64) mkdir -v /tools/lib && ln -sv lib /tools/lib64 ;;
    esac

    make install
    cd ..

    cd ..
    rm -rf ${name}${version}
}
