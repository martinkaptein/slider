#!/bin/bash
## FFMPEGSLIDER SCRIPT (Martin Kaptein | www.sonata8.com)
## START GITHUB README
## FFMPEG Bash Video Editor
#
#A simple bash script to produce a video slideshow based on a text file.
#Optionally also including a facecam.
#
### Requirements
#
#ffmpeg, imagemagick
#
### Installation
#
#Add the bash script to your `$path` or copy it over to `/usr/local/bin/`.
#Don't forget to mark it as excecutable.
#
#```
#git clone https://github.com/martinkaptein/slider.git
#cd slider
#sudo cp ffmpegslider.sh /usr/local/bin/ffmpegslider
#sudo chmod +x /usr/local/bin/ffmpegslider
#```
#
### Usage
#
#General usage:
#
#```
#ffmpegslider -r 1920x1080 -i input.txt -s audiosource.mp3 -o output.mp4
#```
#
#All the flags except the `-i` flag are optional, as they fall back one sane defaults.
#
#`-s` Depicts the source of background audio.
#This file can be an audio file or video file.
#If the file is a video file, the script will produce a facecam-style output with the video as an overlay on the top right.
#By default the slideshow length depends on the length of the file.
#If no file is specified, the slideshow will be silent.
#In that case you will **need to duplicate the last line** in the `-i input.txt` file.
#That's a ffmpeg nuisance.
#
#`-r` flag depicts the resolution in the given format, for example:
#
#- for vertical video (9:16) you can set 1080x1920
#- for normal (horizontal) HD set 1920x1080
#- for 4K set to 3840x2160
#
#The default is *1920x1080*.
#Any resolution and aspect ratio is supported.
#
#`-o` depicts the output, ffmpeg codecs expect the output to be a `.mp4` file.
#
#The mandatory `-i` flag points to the main input file.
#This is a text file formatted in the following way:
#
#### Input file format
#
#Format the input.txt file like this:
#
#< timestamp UNTIL the picture should appear in the video >;< filename OR text (text should start with < | >) >
#
#Example:
#
#```
#00:00:05;pic1.jpg
#00:00:10;|Some Text slide
#00:00:12;pic2.jpg
#```
#
#In the example above, pic1 will appear until the 5th second, then, until 10s you will see a text slide, etc..
#Most image formats are supported, internally they will be converted to jpg anyway.
#You can customize the text color and background color of the text generation here in the script.
#END GITHUB README
while getopts r:i:s:o: flag
do
	case "${flag}" in
		r) resolution=${OPTARG};;
		i) slidemaster=${OPTARG};;
		s) audiosource=${OPTARG};;
		o) outputfile=${OPTARG};;
	esac
done

prevseconds=0
tmpdir="tmp-$((1 + $RANDOM % 100000))"
mkdir $tmpdir
# Defaults
resolution=${resolution:-'1920x1080'}
audiosource=${audiosource:-'noaudio'}
outputfile=${outputfile:-'script-output.mp4'}
while read -r xline; do
	time="${xline%;*}"
	filetext="${xline#*;}"
	# convert seconds
	seconds=$(echo $time | awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }')
	duration="$((seconds - prevseconds))"
	prevseconds=$seconds
	# If start as ' | ' treat as text, else it's a file
	if [[ "$filetext" =~ ^\|.* ]]; then
		# come up with filename
		filename="pic-$((1 + $RANDOM % 100000)).jpg"
		# remove leading |
		text=$(echo $filetext | sed -r 's/\|//')
		# convert text to image using imagemagick, save it in ./tmp/
		convert -size "${resolution}" -background "#091d28" -fill "#F7EBEC" -pointsize "80" -gravity center caption:"$text" "$tmpdir/$filename"
		echo "file '$filename'" >> $tmpdir/ffmpeg.txt
	else
		# convert image to jpg & right size, save it in ./tmp
		convert $filetext -resize "${resolution}" -background "#091d28" -gravity center -extent "${resolution}" "${tmpdir}/${filetext}.jpg"
		echo "file '${filetext}.jpg'" >> $tmpdir/ffmpeg.txt
	fi
	echo "duration $duration" >> $tmpdir/ffmpeg.txt
done < "${slidemaster}"
# build the video, if audiosource is video too make it an overlay
if [[ "$audiosource" =~ .*\.(mov|mp4|mkv) ]]; then
	height=$(echo "$resolution" | awk -Fx '{ print $2 }')
	desiredheight=$(($height*1/3))
	ffmpeg -f concat -i $tmpdir/ffmpeg.txt -i "${audiosource}" -c:a aac -c:v libx264 -r 30 -pix_fmt yuv420p "${tmpdir}/${outputfile}"
	#ffmpeg -i "${audiosource}" -vf "scale=-2:$desiredheight" "${tmpdir}/scaled-facecam.mp4"
	#ffmpeg -i "${tmpdir}/${outputfile}" -i "${tmpdir}/scaled-facecam.mp4" -filter_complex "overlay=W-w:0" "${outputfile}"
	ffmpeg -i "${audiosource}" -i "${tmpdir}/${outputfile}" -filter_complex "[0]scale=-2:$desiredheight[scaled];[1][scaled]overlay=W-w:0" -c:a aac -c:v libx264 -r 30 -pix_fmt yuv420p "${outputfile}"
elif [[ "$audiosource" == "noaudio" ]]; then
	ffmpeg -f concat -i $tmpdir/ffmpeg.txt -c:v libx264 -r 30 -pix_fmt yuv420p "${outputfile}"
else
	ffmpeg -f concat -i $tmpdir/ffmpeg.txt -i "${audiosource}" -c:a aac -c:v libx264 -r 30 -pix_fmt yuv420p "${outputfile}"
fi
# cleanup
rm -rf $tmpdir
