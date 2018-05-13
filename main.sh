#!/bin/bash

execPath=$(readlink -f $(dirname $0))

source ${execPath}/binutils_part1.sh
source ${execPath}/gcc_part1.sh
source ${execPath}/API_header.sh
source ${execPath}/glibc.sh
source ${execPath}/libstd.sh
source ${execPath}/binutils_part2.sh
source ${execPath}/gcc_part2.sh
source ${execPath}/tcl_core.sh
source ${execPath}/expect.sh
source ${execPath}/dejagnu.sh
source ${execPath}/check.sh
source ${execPath}/ncurses.sh
source ${execPath}/bash.sh
source ${execPath}/bison.sh
source ${execPath}/bzip2.sh
source ${execPath}/coreutils.sh
source ${execPath}/packet.sh
source ${execPath}/gettext.sh
source ${execPath}/make.sh
source ${execPath}/perl.sh
source ${execPath}/util_linux.sh

DIRLOG='LOG/'
mkdir ${DIRLOG}

touch ${DIRLOG}binutils.log
touch ${DIRLOG}gcc_part1.log
touch ${DIRLOG}API_header.log
touch ${DIRLOG}glibc.log
touch ${DIRLOG}libstd.log
touch ${DIRLOG}binutils_part2.log
touch ${DIRLOG}gcc_part2.log
touch ${DIRLOG}tcl_core.log
touch ${DIRLOG}expect.log
touch ${DIRLOG}dejagnu.log
touch ${DIRLOG}check.log
touch ${DIRLOG}bash.log
touch ${DIRLOG}bison.log
touch ${DIRLOG}bzip2.log
touch ${DIRLOG}coreutils.log
touch ${DIRLOG}diffutils.log
touch ${DIRLOG}file.log
touch ${DIRLOG}findutils.log
touch ${DIRLOG}gawk.log
touch ${DIRLOG}gettext.log
touch ${DIRLOG}grep.log
touch ${DIRLOG}gzip.log
touch ${DIRLOG}m4.log
touch ${DIRLOG}make.log
touch ${DIRLOG}patch.log
touch ${DIRLOG}perl.log
touch ${DIRLOG}sed.log
touch ${DIRLOG}tar*
touch ${DIRLOG}texinfo.log
touch ${DIRLOG}util_linux.log
touch ${DIRLOG}xz.log

echo "install binutils..." && install_binutils &> ${DIRLOG}binutils.log
echo "install gcc..." && install_gcc &> ${DIRLOG}gcc_part1.log
echo "install API header..." && install_apiheader &> ${DIRLOG}API_header.log
echo "install glibc..." && install_glibc &> ${DIRLOG}glibc.log
echo "install libstdc++..." && install_libstd &> ${DIRLOG}libstd.log
echo "install binutils..." && install_binutils2 &> ${DIRLOG}binutils_part2.log
echo "install gcc..." && install_gcc2 &> ${DIRLOG}gcc_part2.log
echo "install tcl-core..." && install_tcl-core &> ${DIRLOG}tcl_core.log
echo "install expect..." && install_expect &> ${DIRLOG}expect.log
echo "install dejagnu..." && install_dejagnu &> ${DIRLOG}dejagnu.log
echo "install check..." && install_check &> ${DIRLOG}check.log
echo "install bash..." && install_bash &> ${DIRLOG}bash.log
echo "install bison..." && install_bison &> ${DIRLOG}bison.log
echo "install bzip..." && install_bzip2 &> ${DIRLOG}bzip2.log
echo "install coreutils..." && install_coreutils &> ${DIRLOG}coreutils.log
echo "install diffutils..." && install_packet diffutils &> ${DIRLOG}diffutils.log
echo "install file..." && install_packet file &> ${DIRLOG}file.log
echo "install findutils..." && install_packet findutils &> ${DIRLOG}findutils.log
echo "install gawk..." && install_packet gawk &> ${DIRLOG}gawk.log
echo "install gettext..." && install_gettext &> ${DIRLOG}gettext.log
echo "install grep..." && install_packet grep &> ${DIRLOG}grep.log
echo "install gzip..." && install_packet gzip &> ${DIRLOG}gzip.log
echo "install m4..." && install_packet m4 &> ${DIRLOG}m4.log
echo "install make..." && install_make &> ${DIRLOG}make.log
echo "install patch..." && install_packet patch &> ${DIRLOG}patch.log
echo "install perl..." && install_perl &> ${DIRLOG}perl.log
echo "install sed..." && install_packet sed &> ${DIRLOG}sed.log
echo "install tar..." && install_packet tar &> ${DIRLOG}tar*
echo "install texinfo..." && install_packet texinfo &> ${DIRLOG}texinfo.log
echo "install util-linux..." && install_util-linux &> ${DIRLOG}util_linux.log
echo "install xz-utils..." && install_packet xz &> ${DIRLOG}xz.log
