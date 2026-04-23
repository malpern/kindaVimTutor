import SwiftUI

/// Card for a YouTube video result. Regular videos use a 16:9
/// thumbnail with duration + view-count badges; shorts use a taller
/// 9:16-style tile that groups in a horizontal rail.
struct VideoResultCard: View {
    let result: VideoResult
    var onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            if result.isShort {
                shortTile
            } else {
                videoRow
            }
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
    }

    private var videoRow: some View {
        HStack(alignment: .top, spacing: 10) {
            thumbnail
                .frame(width: 120, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(alignment: .bottomTrailing) {
                    if let duration = result.duration {
                        Text(duration)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.black.opacity(0.75),
                                        in: RoundedRectangle(cornerRadius: 3, style: .continuous))
                            .padding(4)
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(result.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text(result.channel)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                if let views = result.viewCount {
                    Text(views)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .background(Color.primary.opacity(0.04),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        }
    }

    private var shortTile: some View {
        VStack(alignment: .leading, spacing: 4) {
            thumbnail
                .aspectRatio(9.0/16.0, contentMode: .fill)
                .frame(width: 98, height: 174)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            Text(result.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .frame(width: 98, alignment: .leading)
            if let views = result.viewCount {
                Text(views)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        }
        // Without an explicit content shape, only the thumbnail
        // image receives tap hits — the title/views below aren't
        // clickable. Rectangle covers the full tile area.
        .contentShape(Rectangle())
    }

    private var thumbnail: some View {
        AsyncImage(url: result.thumbnailURL) { phase in
            switch phase {
            case .success(let img):
                img.resizable().aspectRatio(contentMode: .fill)
            default:
                Color.primary.opacity(0.08)
            }
        }
    }
}
