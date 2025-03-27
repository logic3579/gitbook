# Video Tools

## ffmpeg

```bash
# install
git clone https://github.com/FFmpeg/FFmpeg
cd FFmpeg && ./configure --prefix=/usr/local/ffmpeg --disable-x86asm && make -j$(nproc) && make install
ln -s /usr/local/ffmpeg/bin/ffmpeg /usr/bin/ffmpeg
ln -s /usr/local/ffmpeg/bin/ffprobe /usr/bin/ffprobe

# test push
ffmpeg -re -stream_loop -1 -i /tmp/test.mp4 -f flv rtmp://push-domain.com/appName/streamName
```

## ffplay

```bash
ffplay https://example.com/appName/streamName.flv
```

## ffprobe

```bash
ffprobe https://example.com/appName/streamName.flv
ffprobe rtmp://localhost:1935/appName/streamName
```

> Reference:
>
> 1. [Official Website](https://ffmpeg.org/)
> 2. [Repository](https://github.com/FFmpeg/FFmpeg)
