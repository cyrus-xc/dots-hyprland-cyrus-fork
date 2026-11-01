pragma Singleton

import Quickshell

Singleton {
    // Formats
    readonly property list<string> validImageTypes: ["jpeg", "png", "webp", "tiff", "svg"]
    readonly property list<string> validImageExtensions: ["jpg", "jpeg", "png", "webp", "tif", "tiff", "svg"]

    function isValidImageByName(name: string): bool {
        return validImageExtensions.some(t => name.endsWith(`.${t}`));
    }

    // Videos usable as wallpapers (played by mpvpaper, see scripts/colors/switchwall.sh).
    // Keep in sync with is_video() in that script.
    readonly property list<string> validVideoExtensions: ["mp4", "mkv", "webm", "mov", "avi"]
    function isVideoByName(name: string): bool {
        const lower = name.toLowerCase();
        return validVideoExtensions.some(t => lower.endsWith(`.${t}`));
    }
    // The wallpaper as a still image. For a video wallpaper switchwall.sh extracts a frame
    // (background.thumbnailPath), which is what previews and color extraction should use.
    function wallpaperStillPath(wallpaperPath: string, thumbnailPath: string): string {
        return isVideoByName(wallpaperPath) ? thumbnailPath : wallpaperPath;
    }

    // Thumbnails
    // https://specifications.freedesktop.org/thumbnail-spec/latest/directory.html
    readonly property var thumbnailSizes: ({
        "normal": 128,
        "large": 256,
        "x-large": 512,
        "xx-large": 1024
    })
    function thumbnailSizeNameForDimensions(width: int, height: int): string {
        const sizeNames = Object.keys(thumbnailSizes);
        for(let i = 0; i < sizeNames.length; i++) {
            const sizeName = sizeNames[i];
            const maxSize = thumbnailSizes[sizeName];
            if (width <= maxSize && height <= maxSize) return sizeName;
        }
        return "xx-large";
    }
}
