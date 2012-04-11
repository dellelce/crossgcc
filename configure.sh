#
# Configure 
#


## ENVIRONMENT ##

PROFILE="./sparc10.profile"
. $PROFILE

echo
echo "MPFR: ${mpfr_version}"
echo "GMP: ${gmp_version}"
echo "MPC: ${mpc_version}"
echo "BINUTILS: ${binutils_version}"
echo "GCC: ${gcc_version}"
echo

## FUNCTIONS ##

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
  typeset conf="${gmp_src}/configure"

  try_makedir ${gmp_build} || return 1

  [ ! -f "${conf}" -o ! -s "${conf}" ] && return 2

  set -x
  ${conf}				\
	--prefix="${prefix}"
  rc="$?"
  set +x

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

  set -x
  make && make install
  rc="$?"

  set +x

  return "$rc"
}

#
# configure_mpfr
#

configure_mpfr()
{
  typeset rc
  typeset conf="${mpfr_src}/configure"

  try_makedir ${mpfr_build} || return 1

  [ ! -f "${conf}" -o ! -s "${conf}" ] && return 2

  set -x
  ${conf}				\
	--with-gmp="${prefix}"		\
	--prefix="${prefix}"
  rc="$?"
  set +x

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

  set -x
  make && make install
  rc="$?"

  set +x

  return "$rc"
}

#
# 
#

configure_binutils()
{
  typeset rc
  typeset conf="${binutils_src}/configure"

  try_makedir ${binutils_build} || return 1

  set -x
  [ ! -f "${conf}" -o ! -s "${conf}" ] && return 2

  ${conf}				\
	--prefix="${prefix}"		\
	--with-sysroot="${sysrootdir}"	\
	--with-gmp="${prefix}"		\
	--with-mpfr="${prefix}"		\
	--disable-nls			\
	--target="${target}"
  rc="$?"
  set +x

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

  set -x
  make && make install
  rc="$?"

  set +x

  return "$rc"
}

#
# 
#

configure_gcc()
{
  typeset rc

  try_makedir ${gcc_build} || return 1

  set -x
  ${gcc_src}/configure			\
	--prefix="${prefix}"		\
	--target="${target}"		\
	--with-sysroot="${sysrootdir}"	\
	--with-gmp="${prefix}"		\
	--with-mpfr="${prefix}"		\
	--with-mpc="${prefix}"		\
	--with-gnu-as			\
	--with-gnu-ld			\
	--disable-nls			\
	--enable-languages=c,c++

  rc="$?"
  set +x

  return "$rc"
}

#
#
#

configure_gccbootstrap()
{
  typeset rc

  try_makedir ${gcc_bootstrap} || return 1

#	--with-sysroot="${sysrootdir}"	\
  set -x
  ${gcc_src}/configure			\
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
  set +x

  return "$rc"
}
#
# 
#

configure_mpc()
{
  typeset rc

  set -x

  try_makedir ${mpc_build} || return 1

  ${mpc_src}/configure			\
	--prefix="${prefix}"		\
	--with-gmp="${prefix}"		\
	--with-mpfr="${prefix}"

  rc="$?"
  set +x

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

  set -x
  make && make install
  rc="$?"

  set +x

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

  set -x
  make && make install
  rc="$?"

  set +x

  return "$rc"
}

#
#
#

configure_newlib()
{
  typeset rc

  try_makedir ${newlib_build} || return 1

  set -x
  ${newlib_src}/configure			\
	--prefix="${prefix}"			\
	--target="${target}"

  rc="$?"
  set +x

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
  set -x

  eval configure_${id} 2>&1 
  rc="$?"
  cd "$cwd"
  set +x
 } > "${log}" 2>&1 

 [ "$rc" -ne 0 ] && { echo "configuring $id failed"; } || { set_success "$id" conf; } 

 return "$rc"
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

 [ "$rc" -ne 0 ] && { echo" configuring $id failed"; } || { set_success "${id}" build; } 

 return "$rc"
}


## MAIN ##


# Sanity tests

quickCheck || { echo "Sanity checks failed."; exit 1; }

# Run configure

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
