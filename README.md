FFmpeg-iOS
==========

[FFmpeg](http://www.ffmpeg.org) static libraries compiled for armv7, armv7s and i386 for use in iOS development.

Usage
-----

Just drag the `/dependencies/include` and `/dependencies/lib` folders into your Xcode project and add them to your build target. If you want to, you can modify the `build-ffmpeg.sh` script to suit your needs and recompile.

Compilation
-----------

1. Make sure to copy the latest version of [gas-preprocessor.pl](https://github.com/yuvi/gas-preprocessor) to `/usr/local/bin` or you'll get some nasty linker errors.
2. Check `build-ffmpeg.sh` to see if `VERSION="2.0.1"` is your desired FFmpeg version and `SDKVERSION="6.1"` matches your current iOS SDK version.
3. `$ bash build-ffmpeg.sh`

License
-------

FFmpeg is LGPLv2.1+ depending on how you compile it. This may affect your ability to distribute binaries on the App Store, especially if you don't release your source code to allow someone to re-link against newer versions of FFmpeg. Beware!