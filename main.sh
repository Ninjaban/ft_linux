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

install_binutils &> ${DIRLOG}binutils.log
install_gcc &> ${DIRLOG}gcc_part1.log
install_apiheader &> ${DIRLOG}API_header.log
install_glibc &> ${DIRLOG}glibc.log
install_libstd &> ${DIRLOG}libstd.log
install_binutils2 &> ${DIRLOG}binutils_part2.log
install_gcc2 &> ${DIRLOG}gcc_part2.log
install_tcl-core &> ${DIRLOG}tcl_core.log
install_expect &> ${DIRLOG}expect.log
install_dejagnu &> ${DIRLOG}dejagnu.log
install_check &> ${DIRLOG}check.log
install_bash &> ${DIRLOG}bash.log
install_bison &> ${DIRLOG}bison.log
install_bzip2 &> ${DIRLOG}bzip2.log
install_coreutils &> ${DIRLOG}coreutils.log
install_packet diffutils 3.6 &> ${DIRLOG}diffutils.log
install_packet file 5.31 &> ${DIRLOG}file.log
install_packet findutils 4.6.0 &> ${DIRLOG}findutils.log
install_packet gawk 4.1.4 &> ${DIRLOG}gawk.log
install_gettext &> ${DIRLOG}gettext.log
install_packet grep 3.1 &> ${DIRLOG}grep.log
install_packet gzip 1.8 &> ${DIRLOG}gzip.log
install_packet m4 1.4.18 &> ${DIRLOG}m4.log
install_make &> ${DIRLOG}make.log
install_packet patch 2.7.5 &> ${DIRLOG}patch.log
install_perl &> ${DIRLOG}perl.log
install_packet sed 4.4 &> ${DIRLOG}sed.log
install_packet tar 1.29 &> ${DIRLOG}tar.log
install_packet texinfo 6.4 &> ${DIRLOG}texinfo.log
install_util-linux &> ${DIRLOG}util_linux.log
install_packet xz 5.2.3 &> ${DIRLOG}xz.log
