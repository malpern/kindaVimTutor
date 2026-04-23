import Foundation
import Testing
@testable import KindaVimTutor

@Suite("kindaVim support corpus")
struct KindaVimSupportCorpusTests {
    @Test("supported and unsupported command lists load")
    func loadsSupportCorpus() {
        let corpus = KindaVimSupportCorpus.shared

        #expect(!corpus.supported.isEmpty)
        #expect(!corpus.unsupported.isEmpty)
        #expect(corpus.supported.contains(where: { $0.command == "dw" }))
        #expect(corpus.unsupported.contains(where: { $0.command == "q" }))
        #expect(corpus.unsupported.contains(where: { $0.command == ":" }))
    }

    @Test("support lookup normalizes counts and registers")
    func supportLookupNormalizesTokens() {
        let corpus = KindaVimSupportCorpus.shared

        #expect(corpus.isSupported("dw"))
        #expect(corpus.isSupported("3dw"))
        #expect(corpus.isSupported("\"adw"))
        #expect(!corpus.isSupported("q"))
        #expect(!corpus.isSupported("\"aq"))
        #expect(corpus.isExplicitlyUnsupported("q"))
        #expect(corpus.isExplicitlyUnsupported("\"aq"))
    }

    @Test("unknown tokens stay neutral while known unsupported tokens carry notes")
    func neutralUnknownsAndNotes() {
        let corpus = KindaVimSupportCorpus.shared

        #expect(corpus.isSupported("not-a-real-command"))
        #expect(!corpus.isExplicitlyUnsupported("not-a-real-command"))
        #expect(corpus.note(for: "dw")?.contains("delete next word") == true)
        #expect(corpus.note(for: "q")?.contains("macro") == true)
    }

    @Test("prompt block mentions both supported and unsupported sections")
    func promptBlockContainsKeyCommands() {
        let block = KindaVimSupportCorpus.asPromptBlock()

        #expect(block.contains("### Supported kindaVim commands"))
        #expect(block.contains("### Unsupported"))
        #expect(block.contains("`dw`"))
        #expect(block.contains("`q`"))
    }
}
