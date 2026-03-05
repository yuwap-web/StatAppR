// FilePicker.swift
import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct OpenCSVButton: View {
    @Binding var csvPath: String

    var body: some View {
        Button("CSVを選択…") {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            panel.canChooseFiles = true

            // macOS 11+ / Xcode 13+ 以降は allowedContentTypes
            panel.allowedContentTypes = [
                .commaSeparatedText,
                .text,
                .data
            ]

            if panel.runModal() == .OK, let url = panel.url {
                csvPath = url.path
            }
        }
    }
}
