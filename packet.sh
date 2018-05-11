install_packet()
{
    tar -xf $1-$2.tar*
    cd $1-$2
    
    ./configure --prefix=/tools

    make
    make install

    cd ..
    rm -rf $1-$2
}
