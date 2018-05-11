install_bzip2()
{
    version_bzip2=1.0.6
    tar -xf bzip2-${version_bzip2}.tar.xz
    cd bzip2-${version_bzip2}
    
    make
    make PREFIX=/tools install

    cd ..
    rm -rf bzip2-${version_bzip2}
}
