#
# Install profile for Solaris 10 on Sparc.
#

## IDs

target_id="sparc10"
id="binutils"
target="sparc-sun-solaris2.10"

## versions

binutils_version="binutils-2.22"
gcc_version="gcc-4.6.3"
mpc_version="mpc-0.9"
mpfr_version="mpfr-3.1.0"
gmp_version="gmp-5.0.4"
# c libraries
newlib_version="newlib-1.20.0"
glibc_version="glibc-2.15"

## Base directories

prefixBase="/usr/local/cross"
baseDir="/home/antonio/src/cross"

## Directories

prefix="${prefixBase}/${target_id}"
binutils_src="${baseDir}/binutils/${binutils_version}"
binutils_build="${baseDir}/binutils/build_${target_id}"
gcc_src="${baseDir}/gcc/${gcc_version}"
gcc_build="${baseDir}/gcc/build_${target_id}"
# needed only if you don't have native libraries 
gcc_bootstrap="${baseDir}/gcc/bootstrap_${target_id}"
newlib_src="${baseDir}/newlib/${newlib_version}"
newlib_build="${baseDir}/newlib/build_${target_id}"
glibc_src="${baseDir}/glibc/${glibc_version}"
glibc_build="${baseDir}/glibc/build_${target_id}"

# mpc / mpfr / gmp 
mpc_src="${baseDir}/mpc/${mpc_version}"
mpc_build="${baseDir}/mpc/build_${target_id}"
gmp_src="${baseDir}/gmp/${gmp_version}"
gmp_build="${baseDir}/gmp/build_${target_id}"
mpfr_src="${baseDir}/mpfr/${mpfr_version}"
mpfr_build="${baseDir}/mpfr/build_${target_id}"

# sysroot
sysrootdir="${prefix}/sysroot"

## EOF ##
