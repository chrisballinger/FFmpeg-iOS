# FFmpeg-iOS

[FFmpeg](http://www.ffmpeg.org) static libraries compiled for armv7, armv7s and x86_64 for use in iOS development.

## Usage

Just drag the `/dependencies/include` and `/dependencies/lib` folders into your Xcode project and add them to your build target. If you want to, you can modify the `build-ffmpeg.sh` script to suit your needs and recompile.

## Status

This most recent version has been tested with FFmpeg version 2.1.1 and version 7.0 of the iOS SDK.

## Compilation

1. Make sure you have the latest version of [gas-preprocessor.pl](https://github.com/libav/gas-preprocessor) installed into your PATH or you'll get some nasty linker errors.
2. Check `build-ffmpeg.sh` to see if `VERSION="X.X.X"` is your desired FFmpeg version and `SDKVERSION="Y.Y"` matches your current iOS SDK version.
3. To build normally: `$ bash build-ffmpeg.sh`
4. To build for debugging: `$ DEBUG=true bash build-ffmpeg.sh`

## License

FFmpeg is LGPLv2.1+ depending on how you compile it. This may affect your ability to distribute binaries on the App Store, especially if you don't release your source code to allow someone to re-link against newer versions of FFmpeg. Beware!

The license for this repository can be found in the `LICENSE` file parallel to this `README.md`.
