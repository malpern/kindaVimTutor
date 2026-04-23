import SwiftUI

struct DedicationPageView: View {
    private let creators = DedicationContent.youtubeCreators

    private var creatorColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 150, maximum: 190), spacing: 14, alignment: .top)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            heroSection
            peopleSection(title: "KindaVim", people: [DedicationContent.kindaVimCreator])
            peopleSection(title: "Neovim", people: [DedicationContent.neovimTeam])
            youtubeSection
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Dedication")
                .font(Typography.manualSectionLabel)
                .tracking(Typography.manualTracking)
                .foregroundStyle(AppColors.manualAccent)

            HStack(alignment: .top, spacing: 22) {
                portraitView(
                    title: DedicationContent.bram.title,
                    imageURL: DedicationContent.bram.imageURL,
                    size: 156,
                    cornerRadius: 24
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("For Bram Moolenaar")
                        .font(Typography.manualTopicTitle)

                    Text(DedicationContent.bram.subtitle)
                        .font(Typography.manualSummary)
                        .foregroundStyle(AppColors.manualMutedText)

                    Text(DedicationContent.bram.bio)
                        .font(Typography.manualBody)
                        .fixedSize(horizontal: false, vertical: true)

                    linksRow(DedicationContent.bram.links)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(22)
        .background(AppColors.manualHeroBackground, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(AppColors.manualHeroBorder.opacity(0.9), lineWidth: 0.9)
        }
    }

    private func peopleSection(title: String, people: [DedicationPerson]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading(title)

            ForEach(people) { person in
                HStack(alignment: .top, spacing: 18) {
                    portraitView(
                        title: person.title,
                        imageURL: person.imageURL,
                        size: 112,
                        cornerRadius: 18
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        Text(person.title)
                            .font(Typography.manualSectionTitle)
                        Text(person.subtitle)
                            .font(Typography.manualCardBody)
                            .foregroundStyle(AppColors.manualMutedText)
                        Text(person.bio)
                            .font(Typography.manualBody)
                            .fixedSize(horizontal: false, vertical: true)
                        linksRow(person.links)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(18)
                .background(AppColors.manualPanelBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(AppColors.manualPanelBorder.opacity(0.75), lineWidth: 0.75)
                }
            }
        }
    }

    private var youtubeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading("Teachers On YouTube")

            Text("A small field guide to the people who keep Vim, Neovim, and modal editing alive in public. Their channel avatars open their YouTube pages directly.")
                .font(Typography.manualBody)
                .foregroundStyle(AppColors.manualMutedText)

            LazyVGrid(columns: creatorColumns, alignment: .leading, spacing: 14) {
                ForEach(creators) { creator in
        Link(destination: creator.url) {
            VStack(alignment: .leading, spacing: 10) {
                            portraitView(
                                title: creator.name,
                                imageURL: creator.thumbnailURL,
                                size: 132,
                                cornerRadius: 20
                            )
                            .frame(maxWidth: .infinity, alignment: .center)

                            Text(creator.name)
                                .font(Typography.manualCardTitle)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)

                            Text(creator.tagline)
                                .font(Typography.manualCardBody)
                                .foregroundStyle(AppColors.manualMutedText)
                                .lineLimit(3)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, minHeight: 236, alignment: .topLeading)
                        .background(AppColors.manualPanelBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(AppColors.manualPanelBorder.opacity(0.75), lineWidth: 0.75)
            }
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
    }
            }
        }
    }

    private func portraitView(title: String, imageURL: URL, size: CGFloat, cornerRadius: CGFloat) -> some View {
        AsyncImage(url: imageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .empty:
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppColors.manualPanelBackground)
                    .overlay {
                        ProgressView()
                    }
            case .failure:
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppColors.manualPanelBackground)
                    .overlay {
                        Image(systemName: "person.crop.square")
                            .font(.system(size: size * 0.3, weight: .light))
                            .foregroundStyle(AppColors.manualMutedText)
                    }
            @unknown default:
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppColors.manualPanelBackground)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(AppColors.manualHeroBorder.opacity(0.85), lineWidth: 0.75)
        }
        .accessibilityLabel(title)
    }

    private func linksRow(_ links: [DedicationLink]) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                ForEach(links) { link in
                    linkChip(link)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(links) { link in
                    linkChip(link)
                }
            }
        }
    }

    private func linkChip(_ link: DedicationLink) -> some View {
        Link(destination: link.url) {
            Label(link.title, systemImage: "arrow.up.right")
                .font(Typography.manualMetaValue)
                .foregroundStyle(AppColors.manualAccent)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(AppColors.manualPanelBackground, in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(AppColors.manualPanelBorder.opacity(0.7), lineWidth: 0.75)
                }
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
    }

    private func sectionHeading(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(Typography.manualSectionLabel)
                .tracking(Typography.manualTracking)
                .foregroundStyle(AppColors.manualAccent)
            Rectangle()
                .fill(AppColors.manualPanelBorder.opacity(0.6))
                .frame(height: 1)
        }
    }
}

struct DedicationLink: Identifiable {
    let id: String
    let title: String
    let url: URL
}

struct DedicationPerson: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let bio: String
    let imageURL: URL
    let links: [DedicationLink]
}

struct YouTubeCreator: Identifiable {
    let id: String
    let name: String
    let tagline: String
    let url: URL
    let thumbnailURL: URL
}

enum DedicationContent {
    static let bram = DedicationPerson(
        id: "bram-moolenaar",
        title: "Bram Moolenaar",
        subtitle: "Creator and long-time steward of Vim",
        bio: "Bram Moolenaar created Vim, maintained it for decades, and turned it into one of the great editor cultures in computing. He paired sharp software craftsmanship with generosity, stewardship, and support for children in Uganda through ICCF Holland.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/f/ff/Bram_Moolenaar_in_2007.jpg/330px-Bram_Moolenaar_in_2007.jpg")!,
        links: [
            .init(id: "bram-wikipedia", title: "Biography", url: URL(string: "https://en.wikipedia.org/wiki/Bram_Moolenaar")!),
            .init(id: "vim-home", title: "Vim", url: URL(string: "https://www.vim.org/")!)
        ]
    )

    static let kindaVimCreator = DedicationPerson(
        id: "guillaume-leclerc",
        title: "Guillaume Leclerc",
        subtitle: "Creator of kindaVim",
        bio: "Guillaume Leclerc built kindaVim around a harder idea than 'Vim keys everywhere': keep the grammar, but rewrite the implementation for macOS controls, accessibility surfaces, menus, and text fields. That product vision is what makes KindaVim an actual macOS tool instead of a shallow key-remapping trick.",
        imageURL: URL(string: "https://github.com/godbout.png?size=400")!,
        links: [
            .init(id: "guillaume-site", title: "Sleeplessmind", url: URL(string: "https://sleeplessmind.com.mo/")!),
            .init(id: "kindavim-site", title: "kindaVim", url: URL(string: "https://kindavim.app/")!),
            .init(id: "kindavim-docs", title: "Docs", url: URL(string: "https://docs.kindavim.app/")!)
        ]
    )

    static let neovimTeam = DedicationPerson(
        id: "neovim-team",
        title: "The Core Neovim Team",
        subtitle: "Maintainers and contributors carrying Vim's modal lineage forward",
        bio: "Neovim took the editing model forward with a more modern architecture, Lua-first extensibility, built-in LSP support, and an active contributor culture. The maintainers and contributors continue the hard work of keeping modal editing relevant, programmable, and alive for new generations of users.",
        imageURL: URL(string: "https://github.com/neovim.png?size=400")!,
        links: [
            .init(id: "neovim-home", title: "Neovim", url: URL(string: "https://neovim.io/")!),
            .init(id: "neovim-github", title: "GitHub", url: URL(string: "https://github.com/neovim/neovim")!),
            .init(id: "neovim-contrib", title: "Contributors", url: URL(string: "https://github.com/neovim/neovim/graphs/contributors")!)
        ]
    )

    static let youtubeCreators: [YouTubeCreator] = [
        .init(id: "theprimeagen", name: "ThePrimeagen", tagline: "Fast-talking Vim and Neovim advocacy, workflows, and editor philosophy.", url: URL(string: "https://www.youtube.com/channel/UC8ENHE5xdFSwx71u3fDH5Xw")!, thumbnailURL: URL(string: "https://yt3.googleusercontent.com/upUU8ypqOx28f8JTt6D3RzPx6vm23IokjDc704jRWDMAJvIKaTFryL3hu8numUJV8CRMfI6D=w2560-fcrop64=1,00005a57ffffa5a8-k-c0xffffffff-no-nd-rj")!),
        .init(id: "tjdevries", name: "TJ DeVries", tagline: "Deep Neovim craft, plugin architecture, and serious practical setup advice.", url: URL(string: "https://www.youtube.com/channel/UCd3dNckv1Za2coSaHGHl5aA")!, thumbnailURL: URL(string: "https://yt3.googleusercontent.com/jx4QxxANfQmnc6NezT9r__IprXaW8xtcEAeJ2N4DCjgGL3VjeHuwn_IPXgJA6r6Z8tgZqjl4-w=w2560-fcrop64=1,00005a57ffffa5a8-k-c0xffffffff-no-nd-rj")!),
        .init(id: "typecraft", name: "TypeCraft", tagline: "Clear, structured Neovim, tmux, and terminal workflow teaching.", url: URL(string: "https://www.youtube.com/channel/UCo71RUe6DX4w-Vd47rFLXPg")!, thumbnailURL: URL(string: "https://yt3.googleusercontent.com/1qL1oquRepcwOhsbRE_Vltwdo0tnoz0hyED7oKfCRUn_mh70s_I_m-miDgZceZsyQ3PdAgDL-Iw=w2560-fcrop64=1,00005a57ffffa5a8-k-c0xffffffff-no-nd-rj")!),
        .init(id: "josean-martinez", name: "Josean Martinez", tagline: "Developer environment tutorials with practical Neovim coverage.", url: URL(string: "https://www.youtube.com/channel/UC_NZ6qLS9oJgsMKQhqAkg-w")!, thumbnailURL: URL(string: "https://yt3.googleusercontent.com/bdGHW8oAhkxMYDtSswJk_TUm3dXIA6hwAZ8lLfUVxRK02uiwuw2k3nJQhUQV8YatkSlHXrxFlB4=w2560-fcrop64=1,00005a57ffffa5a8-k-c0xffffffff-no-nd-rj")!),
        .init(id: "vimjoyer", name: "Vimjoyer", tagline: "Focused Vim and Neovim teaching with strong conceptual explanations.", url: URL(string: "https://www.youtube.com/channel/UC_zBdZ0_H_jn41FDRG7q4Tw")!, thumbnailURL: URL(string: "https://yt3.googleusercontent.com/BbdJoE7bQKaU0kNcVor3GBivGqGq7x5nZhc9atCWe1xo6ok6Hm-L7WshXiUGNnEPquUvI3Ptuw=w2560-fcrop64=1,00005a57ffffa5a8-k-c0xffffffff-no-nd-rj")!),
        .init(id: "system-crafters", name: "System Crafters", tagline: "A broader keyboard-first tooling world with strong Vim and Emacs overlap.", url: URL(string: "https://www.youtube.com/channel/UCAiiOTio8Yu69c3XnR7nQBQ")!, thumbnailURL: URL(string: "https://yt3.googleusercontent.com/umwQEq9dV8Ufq8wS4WgYMPXzUf2b3RmihkKTdCHd1jlAl4C2iCBb-LIMi8S4wxjjwdKpW6jUMQ=w2560-fcrop64=1,00005a57ffffa5a8-k-c0xffffffff-no-nd-rj")!),
        .init(id: "chris-at-machine", name: "Chris@Machine", tagline: "Neovim setups, IDE-like workflows, and modern Lua-driven tooling.", url: URL(string: "https://www.youtube.com/channel/UCS97tchJDq17Qms3cux8wcA")!, thumbnailURL: URL(string: "https://yt3.googleusercontent.com/CAvxkyqDZO7IRugD0PorU_sv7Oxec9zhMJeBt6Ha5ZFQKsqNVflVnj1-QThCKcZUeSdMUMNvkg=w2560-fcrop64=1,00005a57ffffa5a8-k-c0xffffffff-no-nd-rj")!),
        .init(id: "distrotube", name: "DistroTube", tagline: "Terminal culture, Linux workflows, and long-running Vim advocacy.", url: URL(string: "https://www.youtube.com/channel/UCVls1GmFKf6WlTraIb_IaJg")!, thumbnailURL: URL(string: "https://yt3.googleusercontent.com/HzRBTTKyRujuULat6qzzXonLTk61tCj9K1YHOjMFr6zhUjPSEoq3QMNMGRJ8hRPu0Dw1wY2S=w2560-fcrop64=1,00005a57ffffa5a8-k-c0xffffffff-no-nd-rj")!),
        .init(id: "dreams-of-code", name: "Dreams of Code", tagline: "Polished engineering videos that often intersect with Neovim workflows.", url: URL(string: "https://www.youtube.com/channel/UCWQaM7SpSECp9FELz-cHzuQ")!, thumbnailURL: URL(string: "https://yt3.googleusercontent.com/ieM95e2YjMhKNOTqlv_UMo-76lX1ENOysMFtz_VbFP94LLhFd9KW7KOo_3yp1yhk_ymUACaqSQ=w2560-fcrop64=1,00005a57ffffa5a8-k-c0xffffffff-no-nd-rj")!),
        .init(id: "devaslife", name: "devaslife", tagline: "Lifestyle-heavy but still influential in spreading keyboard-centric dev tooling.", url: URL(string: "https://www.youtube.com/channel/UC7yZ6keOGsvERMp2HaEbbXQ")!, thumbnailURL: URL(string: "https://yt3.googleusercontent.com/TKmSMfGPz6UEaJvBc09IZSz2ZktYjDaszrWUnGxrdPAQ5wIdnZCP77j3XCD4jHUWwFAeGi9o=w2560-fcrop64=1,00005a57ffffa5a8-k-c0xffffffff-no-nd-rj")!),
        .init(id: "linkarzu", name: "Linkarzu", tagline: "Current Neovim workflow videos and practical configuration walk-throughs.", url: URL(string: "https://www.youtube.com/channel/UCrSIvbFncPSlK6AdwE2QboA")!, thumbnailURL: URL(string: "https://yt3.googleusercontent.com/W0QF1ICFjhm967lV1WT3U-WH9NDUJjD9tozPCVKLbOnBAdmUBFyKYRPGP9uSXLqN1a6Tg0q8=w2560-fcrop64=1,00005a57ffffa5a8-k-c0xffffffff-no-nd-rj")!),
        .init(id: "vhyrro", name: "Vhyrro", tagline: "Modern Neovim setup, plugin, and terminal ecosystem teaching.", url: URL(string: "https://www.youtube.com/channel/UCBKNuaxVlSNvIN139KplUKw")!, thumbnailURL: URL(string: "https://yt3.googleusercontent.com/jT9WkFkA6keqYnqGFSd0blyhIJXqhBPWMY623XQ0UoM-0z9a15_OjnOvcLdyPVa-IgP1HawR=s900-c-k-c0x00ffffff-no-rj")!)
    ]
}
