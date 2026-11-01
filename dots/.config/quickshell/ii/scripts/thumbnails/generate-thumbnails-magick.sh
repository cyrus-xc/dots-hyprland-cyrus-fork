#!/usr/bin/env bash

# Generate thumbnails for files using ImageMagick, following Freedesktop spec
# Videos get a frame extracted with ffmpeg (when available) instead.
# Usage:
#   ./generate-thumbnails-magick.sh --file <path>
#   ./generate-thumbnails-magick.sh --directory <path>

set -e

# Thumbnail sizes mapping
get_thumbnail_size() {
    case "$1" in
        normal) echo 128 ;;
        large) echo 256 ;;
        x-large) echo 512 ;;
        xx-large) echo 1024 ;;
        *) echo 128 ;;
    esac
}

usage() {
    echo "Usage: $0 --file <path> | --directory <path>"
    exit 1
}

md5() {
    # Calculate md5 hash of the file's absolute path
    echo -n "$1" | md5sum | awk '{print $1}'
}

urlencode() {
    # Percent-encode a string for use in a URI, but do not encode slashes
    local str="$1"
    local encoded=""
    local c
    for ((i=0; i<${#str}; i++)); do
        c="${str:$i:1}"
        case "$c" in
            [a-zA-Z0-9.~_-]|/|'('|')'|'*') encoded+="$c" ;;
            *) printf -v hex '%%%02X' "'${c}'"; encoded+="$hex" ;;
        esac
    done
    echo "$encoded"
}

is_video() {
    case "${1,,}" in
        *.mp4|*.webm|*.mkv|*.avi|*.mov) return 0 ;;
        *) return 1 ;;
    esac
}

# One frame from a video, scaled to fit the thumbnail size. Written to a temp file first so a
# failed run never leaves a broken thumbnail behind.
generate_video_thumbnail() {
    local src="$1" out="$2"
    command -v ffmpeg &>/dev/null || return 0
    local tmp="$out.tmp.png"
    local filter="scale=${THUMBNAIL_SIZE}:${THUMBNAIL_SIZE}:force_original_aspect_ratio=decrease"
    # Prefer a frame 1 s in (the first frame is often black); fall back to the first frame
    ffmpeg -y -loglevel error -ss 1 -i "$src" -frames:v 1 -vf "$filter" "$tmp" 2>/dev/null \
        || ffmpeg -y -loglevel error -i "$src" -frames:v 1 -vf "$filter" "$tmp" 2>/dev/null \
        || { rm -f "$tmp"; return 0; }
    mv -f "$tmp" "$out"
}

generate_thumbnail() {
    local src="$1"
    local abs_path
    abs_path="$(realpath "$src")"
    # Skip animated images (multiple frames)
    case "${abs_path,,}" in
        *.gif)
            return
            ;;
    esac
    local encoded_path
    encoded_path="$(urlencode "$abs_path")"
    local uri
    uri="file://$encoded_path"
    local hash
    hash="$(md5 "$uri")"
    local out="$CACHE_DIR/$hash.png"
    mkdir -p "$CACHE_DIR"
    if [ -f "$out" ]; then
        return
    fi
    if is_video "$abs_path"; then
        generate_video_thumbnail "$abs_path" "$out"
        return
    fi
    magick "$abs_path" -resize "${THUMBNAIL_SIZE}x${THUMBNAIL_SIZE}" "$out"
}

# Parse arguments
SIZE_NAME="normal"
MODE=""
TARGET=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --file|-f)
            MODE="file"
            TARGET="$2"
            shift 2
            ;;
        --directory|-d)
            MODE="dir"
            TARGET="$2"
            shift 2
            ;;
        --size|-s)
            SIZE_NAME="$2"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
    # Only one mode allowed
    [[ -n "$MODE" ]] && break
done

THUMBNAIL_SIZE="$(get_thumbnail_size "$SIZE_NAME")"
CACHE_DIR="$HOME/.cache/thumbnails/$SIZE_NAME"

if [ -z "$MODE" ] || [ -z "$TARGET" ]; then
    usage
fi

case "$MODE" in
    file)
        if [ ! -f "$TARGET" ]; then
            echo "File not found: $TARGET"
            exit 2
        fi
        generate_thumbnail "$TARGET"
        ;;
    dir)
        if [ ! -d "$TARGET" ]; then
            echo "Directory not found: $TARGET"
            exit 2
        fi
        for f in "$TARGET"/*; do
            [ -f "$f" ] || continue
            generate_thumbnail "$f" &
        done
        wait
        ;;
    *)
        usage
        ;;
esac

