#!/bin/bash
# 
# build_index_packages.sh
# Builds packages and index file for Arduino IDE
#
# Copyright (C) 2015 Aidilab Srl
# Author: Ettore Chimenti <ek5.chimenti@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

unset D
DEBUG=${DEBUG:-0}
(( $DEBUG == 1 )) && D='-v'

# we need bash 4 for associative arrays
if [ "${BASH_VERSION%%[^0-9]*}" -lt "4" ]; then
  echo "BASH VERSION < 4: ${BASH_VERSION}" >&2
  exit 1
fi

# get package script directory
REPO_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

#PACKAGE_VERSION=`git describe`
PACKAGE_VERSION=1.5.6

BOARD_DOWNLOAD_URL="https://udooboard.github.io/arduino-board-package"
BUILD=build

GREEN="\e[32m"
RED="\e[31m"
BOLD="\e[1m"
RST="\e[0m"

function log() {

  # args: string
  local EXIT 
  local COLOR=${GREEN}${BOLD}  
  local MOD="-e"

  case $1 in
    err) COLOR=${RED}${BOLD}
      shift ;;
    pre) MOD+="n" 
      shift ;;
    fat) COLOR=${RED}${BOLD}
      EXIT=1
      shift ;;
    *) ;;
  esac

  echo $MOD ${COLOR}$@${RST}

  (( $EXIT )) && exit $EXIT

}

# clean build dir
cd "$REPO_DIR"
rm -rf $BUILD
mkdir $BUILD

#change version as we like
sed -e "s/VERSION/$PACKAGE_VERSION/" \
    -e "s|URL|$BOARD_DOWNLOAD_URL|" \
    < library.properties > $BUILD/library.properties

#sync all libraries
git submodule sync

#copy all the examples
mkdir $D $BUILD/examples
find -type d -path '*/examples/*' -exec cp -r $D {} $BUILD/examples \;

#copy all the sources in the same dir
for i in `find -type f \( -name '*.c' -o -name '*.cpp' \)`
do 
  #add _neo suffix 
  unset NEW OLD
  OLD=`basename $i`
  NEW=`basename ${i%.*}_neo.${i##*.}`
  cp $D "$i" "$BUILD/$NEW"
done

#copy all headers
for i in `find -type f -name '*.h'`
do 

  #add _neo suffix 
  unset NEW OLD
  OLD=`basename $i`
  NEW=`basename ${i%.*}_neo.${i##*.}`
  cp $D "$i" "$BUILD/$NEW"

  #rename header includes inside sources
  find -D stat $BUILD -type f \( -name '*.c' -o -name '*.cpp' -o -name '*.ino' \) \
    -exec sed -i -e "s|$OLD|$NEW|" {} \;

done
