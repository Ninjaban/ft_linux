install_perl()
{
    version_perl=5.26.0
    tar -xf perl-${version_perl}.tar.xz
    cd perl-${version_perl}
    
    sed -e '9751 a#ifndef PERL_IN_XSUB_RE' \
        -e '9808 a#endif'                  \
        -i regexec.c

    sh Configure -des -Dprefix=/tools -Dlibs=-lm

    make

    cp -v perl cpan/podlators/scripts/pod2man /tools/bin
    mkdir -pv /tools/lib/perl5/5.26.0
    cp -Rv lib/* /tools/lib/perl5/5.26.0

    cd ..
    rm -rf perl-${version_perl}
}
