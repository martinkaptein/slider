# FFMPEGSLIDER SCRIPT (Martin Kaptein | www.sonata8.com)
#
# Requirements: ffmpeg, imagemagick
#
# USAGE EXAMPLE
# ffmpegslider -a audiosource.mp3 -r 1920x1080 -i input.txt -o output.mp4 (-t facecam)
# The -t flag is optional.
# The audiosource depicted by the -a flag can also be a video file; the slideshow duration depends on it.
# Add the type flag (-t facecam) to add a facecam overlay to the video output.
#
## The -r flag depicts the resolution in the given format
# for vertical video (9:16) you can set 1080x1920
# for normal (horizontal) HD set 1920x1080
# for 4K set to 3840x2160

# INPUT FILE FORMAT
#
# < timestamp UNTIL the picture should appear in the video >;< filename OR text (text should start with < | >) >
# e.g.
#
# 00:00:05;pic1.jpg
# 00:00:10;|Some Text slide
# 00:00:12;pic2.jpg
#

while getopts a:r:i:o:t: flag
do
	case "${flag}" in
		a) audioinput=${OPTARG};;
		r) resolution=${OPTARG};;
		i) slidemaster=${OPTARG};;
		o) outputfile=${OPTARG};;
		t) type=${OPTARG};;
	esac
done

prevseconds=0
tmpdir="tmp-$((1 + $RANDOM % 100000))"
mkdir $tmpdir
type=${type:-'noface'}
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
# build the video
if [[ "$type" == "facecam" ]]; then
	height=$(echo "$resolution" | awk -Fx '{ print $2 }')
	desiredheight=$(($height*1/3))
	ffmpeg -f concat -i $tmpdir/ffmpeg.txt -i "${audioinput}" -c:a aac -c:v libx264 -r 30 -pix_fmt yuv420p "${tmpdir}/${outputfile}"
	ffmpeg -i "${audioinput}" -vf "scale=-2:$desiredheight" "${tmpdir}/scaled-facecam.mp4"
	ffmpeg -i "${tmpdir}/${outputfile}" -i "${tmpdir}/scaled-facecam.mp4" -filter_complex "overlay=W-w:0" "${outputfile}"
else
	ffmpeg -f concat -i $tmpdir/ffmpeg.txt -i "${audioinput}" -c:a aac -c:v libx264 -r 30 -pix_fmt yuv420p "${outputfile}"
fi
# cleanup
rm -rf $tmpdir
