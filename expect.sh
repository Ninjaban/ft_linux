install_expect()
{
    version_expect=5.45
    tar -xf expect-${version_expect}.tar.gz
    cd expect-${version_expect}

    cp -v configure{,.orig}
    sed 's:/usr/local/bin:/bin:' configure.orig > configure

    ./configure --prefix=/tools       \
                --with-tcl=/tools/lib \
                --with-tclinclude=/tools/include

    make
    make SCRIPTS="" install

    cd ..
    rm -rf expect-${version_expect}
}
