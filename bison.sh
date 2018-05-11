install_bison()
{
    version_bison=3.0.4
    tar -xf bison-${version_bison}.tar.xz
    cd bison-${version_bison}
    
    ./configure --prefix=/tools

    make
    make install

    cd ..
    rm -rf bison-${version_bison}
}
