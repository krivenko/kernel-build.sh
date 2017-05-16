kernel-build.sh

Easy-to-use Bash script to build/install Linux kernel on Gentoo-based systems

Copyright (C) 2017 I. Krivenko

Usage
=====

    kernel-build.sh saveconfig
    kernel-build.sh loadconfig [kernel_version]
    kernel-build.sh configure
    kernel-build.sh build
    kernel-build.sh install
    kernel-build.sh oldconfig
    kernel-build.sh minorupdate

Configuration variables are contained in the header of the script.

Features
========

* Copy kernel configuration file between `${SRC_DIR}/linux` (`/usr/src/linux`
  by default) and `${CONFIGS_DIR}` (`/etc/kernel` by default). `loadconfig`
  called without arguments tries to guess the best configuration file to load.

* Call `make menuconfig`/`make xconfig` depending on `$DISPLAY` environment
  variable being set (`configure` command).

* Call `make oldconfig` (`oldconfig` command).

* Build kernel and modules (`build` command).

* Install kernel/modules, run `emerge -av1 @module-rebuild` and update EFI boot
  record (`install` command). EFI manipulation requires `sys-boot/efibootmgr`
  to be installed.

* Run a sequence of steps to upgrade from kernel version `x.y.z1` to `x.y.z2`
  (`minorupdate` command).

License
=======

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
