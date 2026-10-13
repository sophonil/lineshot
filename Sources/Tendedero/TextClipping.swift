import AppKit

/// Plain UTF-8 files keep text compatible with Finder, Quick Look and the
/// line's existing restore, drag and discard behavior. The card is a preview;
/// copying and exporting always use the complete original text.
enum TextClipping {
    static let maxBytes = 1024 * 1024
    static let pasteboardType = NSPasteboard.PasteboardType("app.tendedero.text-clipping")

    static func isText(_ url: URL) -> Bool { url.pathExtension.lowercased() == "txt" }

    static func accepts(_ text: String) -> Bool {
        text.utf8.count <= maxBytes && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func read(_ url: URL) -> String? {
        guard isText(url), let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
              size <= maxBytes, let data = try? Data(contentsOf: url), data.count <= maxBytes else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func save(_ text: String, in folder: URL) throws -> URL {
        guard accepts(text) else { throw CocoaError(.fileWriteInvalidFileName) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        // No text content in the filename. Create with private permissions
        // before writing any bytes, and never overwrite an existing clipping.
        let url = folder.appendingPathComponent("Clipboard Text \(UUID().uuidString).txt")
        let fd = Darwin.open(url.path, O_WRONLY | O_CREAT | O_EXCL, mode_t(0o600))
        guard fd >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        do {
            try handle.write(contentsOf: Data(text.utf8))
            try handle.close()
            return url
        } catch {
            try? handle.close()
            try? FileManager.default.removeItem(at: url)
            throw error
        }
    }

    static func pasteboardItem(for url: URL, includeFile: Bool = false) -> NSPasteboardItem? {
        guard let text = read(url) else { return nil }
        let entry = NSPasteboardItem()
        entry.setString(text, forType: .string)
        entry.setString("1", forType: pasteboardType)
        if includeFile { entry.setString(url.absoluteString, forType: .fileURL) }
        return entry
    }

    static func thumbnail(_ url: URL, maxPixels: Int) -> NSImage? {
        guard let text = read(url) else { return nil }
        // Match the proportions of the original photo cards. A quiet paper
        // surface sits inside the same glass frame and uses the same clothespin.
        let width = CGFloat(max(1, maxPixels)), scale = width / 272
        let size = NSSize(width: width, height: 208 * scale)
        let preview = String(text.prefix(2000))
        return NSImage(size: size, flipped: true) { bounds in
            NSColor(calibratedRed: 0.985, green: 0.98, blue: 0.955, alpha: 1).setFill()
            bounds.fill()
            let ink = NSColor(calibratedWhite: 0.20, alpha: 1)
            let secondary = NSColor(calibratedWhite: 0.50, alpha: 1)
            ("Aa" as NSString).draw(at: NSPoint(x: 20 * scale, y: 12 * scale), withAttributes: [
                .font: NSFont.systemFont(ofSize: 18 * scale, weight: .medium), .foregroundColor: secondary
            ])
            NSColor(calibratedWhite: 0.5, alpha: 0.18).setFill()
            NSRect(x: 20 * scale, y: 40 * scale, width: 232 * scale, height: scale).fill()
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineBreakMode = .byWordWrapping
            paragraph.lineSpacing = 3 * scale
            paragraph.baseWritingDirection = .natural
            (preview as NSString).draw(
                with: NSRect(x: 20 * scale, y: 52 * scale, width: 232 * scale, height: 138 * scale),
                options: [.usesLineFragmentOrigin, .usesFontLeading, .truncatesLastVisibleLine],
                attributes: [.font: NSFont.systemFont(ofSize: 19 * scale), .foregroundColor: ink,
                             .paragraphStyle: paragraph])
            return true
        }
    }
}
