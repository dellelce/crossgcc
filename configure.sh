#choose ksh or bash (I'm neutral)
#
# Configure 
#
# by Antonio Dell'Elce
#
# configure & build a toolchain
# main objectives: simple
#
# name collision with GNU Configure, to be renamed
#


## ENVIRONMENT ##

PROFILE="./sparc10.profile"
. $PROFILE

dryrun=0 # this must be changed to 0 for actual builds

[ -z "$selectedLanguages" ] && selectedLanguages="c,c++"

[ -z "$debug" ] && debug=0 # 0=yes 1=no

state_ext="state"

## FUNCTIONS ##

#
# optional debugging... first version
#

if_debug()
{
 return $debug
}

#
# mk_conf 
# returns configure command.
# added for dryrun support
#
mk_conf()
{
  typeset configure="$1"

  [ ! -f "$configure" ] && return 1
  [ "$dryrun" -eq 1 ] && { echo "echo $*"; return 0; }

  echo "$*"
}

#
# do_make
# added for dryrun support
#

do_make()
{
 [ "$dryrun" -eq 1 ] && { echo "dry run: make && make install"; } || { make && make install; }
}



#
# src & build directories
# these should be moved out of profiles (made optional there)
# this is the first step for that objective
#

default_dirs()
{
 binutils_src="${baseDir}/binutils/${binutils_version}"
 binutils_build="${baseDir}/binutils/build_${target_id}"
 gcc_src="${baseDir}/gcc/${gcc_version}"
 gcc_build="${baseDir}/gcc/build_${target_id}"
 glibc_src="${baseDir}/glibc/${glibc_version}"
 glibc_build="${baseDir}/glibc/build_${target_id}"

# mpc / mpfr / gmp 
 mpc_src="${baseDir}/mpc/${mpc_version}"
 mpc_build="${baseDir}/mpc/build_${target_id}"
 gmp_src="${baseDir}/gmp/${gmp_version}"
 gmp_build="${baseDir}/gmp/build_${target_id}"
 mpfr_src="${baseDir}/mpfr/${mpfr_version}"
 mpfr_build="${baseDir}/mpfr/build_${target_id}"

# newlib is optional
 newlib_src="${baseDir}/newlib/${newlib_version}"
 newlib_build="${baseDir}/newlib/build_${target_id}"
}

#
# show components versions
#
show_versions()
{
cat << EOF

 MPFR:     ${mpfr_version}
 GMP:      ${gmp_version}
 MPC:      ${mpc_version}
 BINUTILS: ${binutils_version}
 GCC:      ${gcc_version}

EOF
}

#
# try_makedir
#

try_makedir()
{
  typeset dir="$1"
  typeset rc=""

  [ -z "$dir" ] && return 1

  [ ! -d "$dir" ] && 
  {
    mkdir "$dir"  > /dev/null 2>&1 
    rc="$?"

    [ "$rc" -ne 0 ] && return 2
  }

 cd "$dir" || return 3
}

#
# dirTest
#
# tests if a directory exists, if not it will create it
#

dirTest()
{
  [ -z "$1" ] && return 1

  typeset dir="$1"
  typeset rc=""

  [ ! -d "$dir" ] &&
  {
    mkdir "$dir" 2>/dev/null
    rc="$?"

    [ "$rc" -ne 0 ] &&
    return 1
  }
    
  return 0
}

#
# test
# 
testEnv()
{
  # IDs

  [ -z "$target_id" -o -z "$id" -o -z "$target" -o -z "$binutils_versions" ] &
  {
    echo "not all version variable set."
    return 1
  }

  # Base directories - those must exist

  [ ! -d "${prefixBase}" ] && 
  {
    echo "prefixBase [${prefixBase}] is invalid"
    return 1
  }

  # Non-base directories - those can be created if they do not exist

}

#
# get_state_time
#
# return date & time in state file
#

get_state_time()
{
  typeset id="$1"
  typeset aid="$2"
  typeset sval=""
  typeset s_last s_hour s_day

  [ -z "$aid" ] && return 1

  eval typeset fp="\$${id}_build/${aid}.${state_ext}"

  [ ! -s "$fp" ] && return 2 

  cat 
}

#
# read if exists success file
#

get_success()
{
  typeset id="$1"
  typeset aid="$2"

  [ -z "$aid" ] && return 1

  eval typeset fp="\$${id}_build/${aid}.success"
  
  [ -s "$fp" ] && { cat "${fp}"; } 
}



#
# sets success file
#

set_success()
{
  typeset id="$1"
  typeset aid="$2"

  [ -z "$aid" ] && return 1

  eval typeset fp=\$${id}_build/${aid}.success
  
  echo "$(date +%H%M) $(date +%d%m%y)" > "$fp"
}

#
# configure_gmp
#

configure_gmp()
{
  typeset rc
  typeset conf="$(mk_conf ${gmp_src}/configure)"

  [ -z "$conf" ] && return 2

  try_makedir ${gmp_build} || return 1

  if_debug && set -x
  ${conf}				\
	--prefix="${prefix}"
  rc="$?"
  if_debug && set +x

  return "$rc"
}

#
#
#
build_gmp()
{
  typeset rc
  typeset mf="${gmp_build}/Makefile"

  try_makedir ${gmp_build} || return 1

  [ ! -f "${mf}" -o ! -s "${mf}" ] && return 2

  if_debug && set -x
  do_make
  rc="$?"

  if_debug && set +x

  return "$rc"
}

#
# configure_mpfr
#

configure_mpfr()
{
  typeset rc
  typeset conf="$(mk_conf ${mpfr_src}/configure)"

  [ -z "$conf" ] && return 2

  try_makedir ${mpfr_build} || return 1

  if_debug && set -x
  ${conf}				\
	--with-gmp="${prefix}"		\
	--prefix="${prefix}"
  rc="$?"
  if_debug && set +x

  return "$rc"
}

#
#
#
build_mpfr()
{
  typeset rc
  typeset mf="${mpfr_build}/Makefile"

  try_makedir ${mpfr_build} || return 1

  [ ! -f "${mf}" -o ! -s "${mf}" ] && return 2

  if_debug && set -x
  do_make
  rc="$?"

  if_debug && set +x

  return "$rc"
}

#
# 
#

configure_binutils()
{
  typeset rc
  typeset conf="$(mk_conf ${binutils_src}/configure)"

  [ -z "$conf" ] && return 2

  try_makedir ${binutils_build} || return 1

  if_debug && set -x

  ${conf}				\
	--prefix="${prefix}"		\
	--with-sysroot="${sysrootdir}"	\
	--with-gmp="${prefix}"		\
	--with-mpfr="${prefix}"		\
	--disable-nls			\
	--target="${target}"
  rc="$?"
  if_debug && set +x

  return "$rc"
}

#
#
#
build_binutils()
{
  typeset rc
  typeset mf="${binutils_build}/Makefile"

  try_makedir ${binutils_build} || return 1

  [ ! -f "${mf}" -o ! -s "${mf}" ] && return 2

  if_debug && set -x
  do_make
  rc="$?"

  if_debug && set +x

  return "$rc"
}

#
# Run configure.sh for gcc 
#

configure_gcc()
{
  typeset rc
  typeset conf="$(mk_conf ${gcc_src}/configure)"

  [ -z "$conf" ] && { echo "invalid configure"; return 2; }

  try_makedir ${gcc_build} || return 1

  if_debug && set -x
  $conf					\
	--prefix="${prefix}"		\
	--target="${target}"		\
	--with-sysroot="${sysrootdir}"	\
	--with-gmp="${prefix}"		\
	--with-mpfr="${prefix}"		\
	--with-mpc="${prefix}"		\
	--with-gnu-as			\
	--with-gnu-ld			\
	--disable-nls			\
	--enable-languages="$selectedLanguages"

  rc="$?"
  if_debug && set +x

  return "$rc"
}

#
#
#

configure_gccbootstrap()
{
  typeset rc
  typeset conf="$(mk_conf ${gcc_src}/configure)"

  [ -z "$conf" ] && return 2
  try_makedir ${gcc_bootstrap} || return 1

#	--with-sysroot="${sysrootdir}"	\
  if_debug && set -x
  ${conf}				\
	--prefix="${prefix}"		\
	--target="${target}"		\
	--with-gmp="${prefix}"		\
	--with-mpfr="${prefix}"		\
	--with-mpc="${prefix}"		\
	--with-gnu-as			\
	--with-gnu-ld			\
	--disable-nls			\
	--without-headers		\
	--without-threads		\
	--enable-languages=c,c++

  rc="$?"
  if_debug && set +x

  return "$rc"
}
#
# 
#

configure_mpc()
{
  typeset rc
  typeset conf="$(mk_conf ${mpc_src}/configure)"

  [ -z "$conf" ] && return 2

  if_debug && set -x

  try_makedir ${mpc_build} || return 1

  ${conf}				\
	--prefix="${prefix}"		\
	--with-gmp="${prefix}"		\
	--with-mpfr="${prefix}"

  rc="$?"
  if_debug && set +x

  return "$rc"
}


#
# build_mpc
#

build_mpc()
{
  typeset rc
  typeset mf="${mpc_build}/Makefile"

  try_makedir ${mpc_build} || return 1

  [ ! -f "${mf}" -o ! -s "${mf}" ] && return 2

  if_debug && set -x
  do_make
  rc="$?"

  if_debug && set +x

  return "$rc"
}

#
# build_gcc
#

build_gcc()
{
  typeset rc
  typeset mf="${gcc_build}/Makefile"

  try_makedir ${gcc_build} || return 1

  [ ! -f "${mf}" -o ! -s "${mf}" ] && return 2

  if_debug && set -x
  make && make install
  rc="$?"

  if_debug && set +x

  return "$rc"
}

#
#
#

configure_newlib()
{
  typeset rc
  typeset conf="$(mk_conf ${newlib_src}/configure)"

  [ -z "$conf" ] && return 2
  try_makedir ${newlib_build} || return 1

  if_debug && set -x
  ${conf}					\
	--prefix="${prefix}"			\
	--target="${target}"

  rc="$?"
  if_debug && set +x

  return "$rc"
}

#
# beta versioon of sanity checks
#

quickCheck()
{
[ -z "$target_id" ] && echo "variable target_id not set" && return 1
[ -z "$id" ] && echo "variable id not set" && return 1
[ -z "$target" ] && echo "variable target not set" && return 1
[ -z "$binutils_version" ] && echo "variable binutils_version not set" && return 1
[ -z "$prefixBase" ] && echo "variable prefixBase not set" && return 1
[ -z "$baseDir" ] && echo "variable baseDir not set" && return 1
[ -z "$prefix" ] && echo "variable prefix not set" && return 1
[ -z "$binutils_src" ] && echo "variable binutils_src not set" && return 1
[ -z "$binutils_build" ] && echo "variable binutils_build not set" && return 1
[ -z "$binutils_src" ] && echo "variable binutils_src not set" && return 1
[ -z "$gcc_build" ] && echo "variable gcc_build not set" && return 1
[ -z "$gcc_src" ] && echo "variable gcc_src not set" && return 1
[ -z "$sysrootdir" ] && echo "variable sysrootdir not set" && return 1

return 0
}

conf()
{
 typeset now="$(date +%H%M_%d%m%y)"
 typeset rc=""
 typeset cwd="$PWD"

 typeset id="$1"
 typeset log="$id.${now}.conf.log"
 typeset configlog=""

 [ -z "$id" ] && { echo "missing build id"; return 1; }  

 typeset sid="$(get_success $id conf)"
 [ ! -z "$sid" ] && { echo "configuration of $id already completed at: ${sid}"; return 0; }

# eval configlog="${id}/build_${target_id}/config.log"
# [ -s "${configlog}" ] && { echo "config.log for ${id} already exists"; return 0; } 

 echo "==> configuring: $id log: ${log}" 

 type configure_${id} 2>/dev/null >/dev/null
 [ "$?" -ne 0 ] && { echo "configure function not found!";  return 1; }


 {
  echo "begin:${now}"
  if_debug && set -x

  eval configure_${id} 2>&1 
  rc="$?"
  cd "$cwd"
  if_debug && set +x
 } > "${log}" 2>&1 

 [ "$rc" -ne 0 ] && { echo "configuring $id failed: rc = $rc"; return "$rc"; }
 set_success "${id}" conf

 return 0
}

#
# build
#

build()
{
 typeset now="$(date +%H%M_%d%m%y)"
 typeset rc=""
 typeset cwd="$PWD"

 typeset id="$1"
 typeset log="$id.${now}.build.log"
 typeset configlog=""

 [ -z "$id" ] && { echo "missing build id"; return 1; }

 typeset sid="$(get_success $id build)"
 [ ! -z "$sid" ] && { echo "build of $id already completed at: ${sid}"; return 0; }

# eval configlog="${id}/build_${target_id}/config.log"
# [ -s "${configlog}" ] && { echo "config.log for ${id} already exists"; return 0; }

 echo "==> building: $id log: ${log}" 

 type build_${id} 2>/dev/null >/dev/null
 [ "$?" -ne 0 ] && { echo "build function not found!";  return 1; }

 {
  echo "begin:${now}"

  eval build_${id} 2>&1
  rc="$?"
  cd "$cwd"
 } > "${log}" 2>&1

 [ "$rc" -ne 0 ] && { echo" configuring $id failed: rc = $rc"; return "$rc"; } 

 set_success "${id}" build;

 return 0
}


## MAIN ##


# Sanity tests

quickCheck || { echo "Sanity checks failed."; exit 1; }

# show module versions
show_versions

# Run configure and then build
#
conf gmp || exit 1
build gmp || exit 1
conf mpfr || exit 1
build mpfr || exit 1
conf mpc || exit 1
build mpc || exit 1
conf binutils || exit 1
build binutils || exit 1
conf gcc || exit 1
build gcc || exit 1


## EOF ##
