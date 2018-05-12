install_perl()
{
    name="perl-"
    version=$(find . -name "${name}*" -print0 | sed -r "s/.*${name}(.*)\.tar.*/\1/g")
    tar -xf ${name}${version}.tar*
    cd ${name}${version}
    
    sed -e '9751 a#ifndef PERL_IN_XSUB_RE' \
        -e '9808 a#endif'                  \
        -i regexec.c

    sh Configure -des -Dprefix=/tools -Dlibs=-lm

    make

    cp -v perl cpan/podlators/scripts/pod2man /tools/bin
    mkdir -pv /tools/lib/perl5/5.26.0
    cp -Rv lib/* /tools/lib/perl5/5.26.0

    cd ..
    rm -rf ${name}${version}
}
