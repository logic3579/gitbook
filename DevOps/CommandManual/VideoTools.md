---
description: FFmpeg video and audio processing CLI references
---

# Video Tools

## ffmpeg

```bash
# install
git clone https://github.com/FFmpeg/FFmpeg
cd FFmpeg && ./configure --prefix=/usr/local/ffmpeg --disable-x86asm && make -j$(nproc) && make install
ln -s /usr/local/ffmpeg/bin/ffmpeg /usr/bin/ffmpeg
ln -s /usr/local/ffmpeg/bin/ffprobe /usr/bin/ffprobe

# install via package manager
brew install ffmpeg             # macOS
apt install ffmpeg              # Ubuntu/Debian
dnf install ffmpeg              # Fedora
```

### Format Conversion

```bash
# video format conversion
ffmpeg -i input.mp4 output.avi
ffmpeg -i input.mkv -codec copy output.mp4        # copy streams without re-encoding
ffmpeg -i input.mov -c:v libx264 -c:a aac output.mp4

# change resolution
ffmpeg -i input.mp4 -vf scale=1280:720 output.mp4
ffmpeg -i input.mp4 -vf scale=-1:720 output.mp4   # auto width, keep aspect ratio

# change bitrate
ffmpeg -i input.mp4 -b:v 2M -b:a 128k output.mp4

# change framerate
ffmpeg -i input.mp4 -r 30 output.mp4
```

### Cut and Merge

```bash
# cut video (start at 00:01:00, duration 30 seconds)
ffmpeg -i input.mp4 -ss 00:01:00 -t 30 -c copy output.mp4

# cut video (start to end time)
ffmpeg -i input.mp4 -ss 00:01:00 -to 00:02:00 -c copy output.mp4

# merge videos (concat demuxer)
cat > filelist.txt << EOF
file 'part1.mp4'
file 'part2.mp4'
file 'part3.mp4'
EOF
ffmpeg -f concat -safe 0 -i filelist.txt -c copy output.mp4
```

### Audio

```bash
# extract audio from video
ffmpeg -i input.mp4 -vn -acodec copy output.aac
ffmpeg -i input.mp4 -vn -ar 44100 -ac 2 -ab 192k -f mp3 output.mp3

# remove audio from video
ffmpeg -i input.mp4 -an -c:v copy output.mp4

# replace audio
ffmpeg -i video.mp4 -i audio.mp3 -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 output.mp4
```

### Image

```bash
# video to images
ffmpeg -i input.mp4 -r 1 output_%04d.png           # 1 frame per second
ffmpeg -i input.mp4 -ss 00:00:05 -frames:v 1 thumbnail.png  # single frame

# images to video
ffmpeg -framerate 30 -i img_%04d.png -c:v libx264 -pix_fmt yuv420p output.mp4

# create GIF from video
ffmpeg -i input.mp4 -vf "fps=10,scale=320:-1" -loop 0 output.gif
```

### Streaming

```bash
# RTMP push
ffmpeg -re -stream_loop -1 -i /tmp/test.mp4 -f flv rtmp://push-domain.com/appName/streamName

# RTMP push with re-encoding
ffmpeg -re -i input.mp4 -c:v libx264 -preset veryfast -c:a aac -f flv rtmp://push-domain.com/appName/streamName

# HLS output
ffmpeg -i input.mp4 -c:v libx264 -c:a aac -hls_time 10 -hls_list_size 0 output.m3u8
```

### Other

```bash
# add watermark
ffmpeg -i input.mp4 -i logo.png -filter_complex "overlay=10:10" output.mp4

# add subtitles
ffmpeg -i input.mp4 -vf subtitles=subs.srt output.mp4

# show media info
ffmpeg -i input.mp4
```

## ffplay

```bash
ffplay input.mp4
ffplay https://example.com/appName/streamName.flv
ffplay -autoexit -loop 3 input.mp4     # auto exit after 3 loops
ffplay -vf "setpts=0.5*PTS" input.mp4  # 2x speed playback
```

## ffprobe

```bash
ffprobe input.mp4
ffprobe https://example.com/appName/streamName.flv
ffprobe rtmp://localhost:1935/appName/streamName

# JSON output
ffprobe -v quiet -print_format json -show_format -show_streams input.mp4

# show specific info
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1 input.mp4
ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 input.mp4
```

> Reference:
>
> 1. [FFmpeg Official Website](https://ffmpeg.org/)
> 2. [FFmpeg Documentation](https://ffmpeg.org/documentation.html)
> 3. [FFmpeg Repository](https://github.com/FFmpeg/FFmpeg)
