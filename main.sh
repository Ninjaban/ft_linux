source binutils.sh
source gcc_part1.sh
source API_header.sh

DIRLOG='LOG/'

install_binutils &> ${DIRLOG}binutils.log
install_gcc &> ${DIRLOG}gcc_part1.log
install_apiheader &> ${DIRLOG}API_header.log
