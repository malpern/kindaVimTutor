import SwiftUI

/// Renders one web-search result. YouTube hits get a thumbnail card
/// (image + title overlay), everything else gets a text card with a
/// DuckDuckGo favicon. Clicking opens the URL in the default browser
/// via the caller-supplied handler.
struct WebResultCard: View {
    let result: WebResult
    var onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            if let videoId = result.youTubeVideoId {
                videoCard(videoId: videoId)
            } else {
                textCard
            }
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
    }

    private func videoCard(videoId: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .center) {
                AsyncImage(
                    url: URL(string: "https://img.youtube.com/vi/\(videoId)/mqdefault.jpg")
                ) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Color.primary.opacity(0.08)
                    }
                }
                .frame(height: 140)
                .frame(maxWidth: .infinity)
                .clipped()

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 4)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(result.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text(result.host)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.primary.opacity(0.04),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var textCard: some View {
        HStack(alignment: .center, spacing: 8) {
            AsyncImage(
                url: URL(string: "https://icons.duckduckgo.com/ip3/\(result.host).ico")
            ) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().aspectRatio(contentMode: .fit)
                default:
                    Image(systemName: "globe")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 14, height: 14)

            Text(result.title)
                .font(.system(size: 12))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
            Text(result.host)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .lineLimit(1)

            Spacer(minLength: 4)

            Image(systemName: "arrow.up.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.primary.opacity(0.04),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        }
    }
}
