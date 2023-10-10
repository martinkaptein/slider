# FFMPEG Bash Video Editor

A simple bash script to produce a video slideshow based on a text file.
Optionally also including a facecam.

## Requirements

ffmpeg, imagemagick

## Installation

Add the bash script to your `$path` or copy it over to `/usr/local/bin/`.
Don't forget to mark it as excecutable.

```
git clone https://github.com/martinkaptein/slider.git
cd slider
sudo cp ffmpegslider.sh /usr/local/bin/ffmpegslider
sudo chmod +x /usr/local/bin/ffmpegslider
```

## Usage

General usage:

```
ffmpegslider -s audiosource.mp3 -r 1920x1080 -i input.txt -o output.mp4 -t facecam
```

All the flags except the `-i` flag are optional, as they fall back one sane defaults.

`-s` Depicts the source of background audio.
This file can be an audio file or video file.
Coupled with the `-t facecam` parameter, it can become a facecam video in the top right of the viewport.
By default the slideshow length depends on the length of the file.
If no file is specified, the slideshow will be silent.
In that case you will **need to duplicate the last line** in the `-i input.txt` file.


`-r` flag depicts the resolution in the given format, for example:

- for vertical video (9:16) you can set 1080x1920
- for normal (horizontal) HD set 1920x1080
- for 4K set to 3840x2160

The default is *1920x1080*.
Any resolution and aspect ratio is supported.

The mandatory `-i` flag points to the main input file.
This is a text file formatted in the following way:

### Input file format

Format the input.txt file like this:

< timestamp UNTIL the picture should appear in the video >;< filename OR text (text should start with < | >) >

Example:

```
00:00:05;pic1.jpg
00:00:10;|Some Text slide
00:00:12;pic2.jpg
```

In the example above, pic1 will appear until the 5th second, then, until 10s you will see a text slide, etc..
Most image formats are supported, internally they will be converted to jpg anyway.
You can customize the text color and background color of the text generation here in the script.

***

`-o` depicts the output, ffmpeg codecs expect the output to be a `.mp4` file.

`-t` is fully optional.
Only add it if you want a facecam overlay (assuming `-s` is a video).
Pass it in this way: `-t facecam`.
