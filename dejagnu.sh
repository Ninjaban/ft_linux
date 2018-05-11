install_dejagnu()
{
    version_dejagnu=1.6
    tar -xf dejagnu-${version_dejagnu}.tar.gz
    cd dejagnu-${version_dejagnu}
    
    ./configure --prefix=/tools

    make
    make install

    cd ..
    rm -rf dejagnu-${version_dejagnu}
}
