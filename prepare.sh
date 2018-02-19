#!/bin/bash

# Get all our sources
mkdir -p dl
wget -P dl -i download.list

#Untar them all
mkdir -p srcs
while read f; do
	tar -xvf "$f" -C srcs
done < <(find ./dl -type f)

#clone cmake repos
mkdir -p "patches/cmake"
cd "patches/cmake"
while read f; do
	git clone "$f"
done < ../../cmakelists.list
cd ../../

# Add cmake to sources
while read cm; do
	p=`basename ${cm%-*}`
	rsync -a "$cm/" srcs/${p}*.*
done < <(find "patches/cmake/" -mindepth 1 -maxdepth 1 -name "*cmake")

# create out of src build tree
mkdir -p build
while read p; do
	p=`basename ${p%-*}`
	mkdir "build/$p"
done < <(ls srcs)

# setup pkgconfig
export PKG_CONFIG_LIBDIR="$(cygpath --mixed `pwd`/install/share/pkgconfig)"

# apply patches
cd srcs
patch -p0 < ../patches/*.patch # apply all patches
cd ../

exit 0; # end before cmakes
# cmake_defaults="-G 'Ninja' -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=../../install"
#zlib
cmake ../../srcs/zlib-1.2.11/ \
    -G 'Ninja' -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=../../install

#libpng
cmake ../../srcs/libpng-1.6.34/ \
    -G 'Ninja' -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=../../install

#freetype no hb
cmake ../../srcs/freetype-2.9/ \
    -DWITH_PNG=ON
    -G 'Ninja' -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=../../install

#harfbuzz (hb-glib required by pango fontconfig/freetype support.)
cmake ../../srcs/harfbuzz-1.7.5/ \
    -DHB_HAVE_FREETYPE=ON -DHB_HAVE_GLIB=ON \
    -G 'Ninja' -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=../../install

#freetype with hb
cmake ../../srcs/freetype-2.9/ \
    -DWITH_PNG=ON -DWITH_HARFBUZZ=ON \
    -G 'Ninja' -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=../../install

#libexpat
cmake ../../srcs/libexpat-R_2_2_5/expat/ \
    -DBUILD_examples=off -DBUILD_tests=off -DBUILD_shared=OFF \
    -G 'Ninja' -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=../../install

#fontconfig
cmake ../../srcs/fontconfig-2.12.6/ \
    -G 'Ninja' -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=../../install

#pixman
cmake ../../srcs/pixman-0.34.0/ \
    -G 'Ninja' -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=../../install

#glib ;_;
export PKG_CONFIG_LIBDIR='/' # stop it from using cygwin pkg-config
cd srcs/glib-2.55.2/
meson ../../build/glib/ --prefix="`cygpath --mixed ../../install/`" --buildtype=debugoptimized
cd ../../build/glib
ninja
# PCRE fix, libintl static, libffi static (stop using OBJECT:!!!!)
# Patch unistd out (not needed in windows...) in gio\gwin32networkmonitor.c
export PKG_CONFIG_LIBDIR="$(cygpath --mixed `pwd`/install/share/pkgconfig)"

#cairo
cmake ../../srcs/cairo-1.15.10/ \
    -G 'Ninja' -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=../../install

#pango
cmake ../../srcs/pango-1.41.0 \
    -G 'Ninja' -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=../../install