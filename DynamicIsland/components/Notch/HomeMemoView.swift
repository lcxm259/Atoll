/*
 * Atoll (DynamicIsland)
 * Copyright (C) 2024-2026 Atoll Contributors
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

import Defaults
import SwiftUI

struct HomeMemoView: View {
    var standalone: Bool = false

    @Default(.homeMemoText) private var homeMemoText
    @FocusState private var isFocused: Bool
    @State private var draft: String = ""
    @State private var isEditing = false
    @State private var pendingFocus = false

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var showsEmptyState: Bool {
        !isEditing && trimmedDraft.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(localized: "Memo"))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 4)
                .padding(.top, 2)

            Group {
                if showsEmptyState {
                    emptyState
                } else {
                    editor
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: standalone ? nil : 120)
        .frame(maxHeight: standalone ? .infinity : 120)
        .onAppear {
            draft = homeMemoText
            isEditing = !homeMemoText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        .onChange(of: homeMemoText) { _, newValue in
            guard !isFocused else { return }
            draft = newValue
        }
        .onChange(of: isFocused) { _, focused in
            if focused {
                isEditing = true
            } else {
                persist()
                isEditing = !trimmedDraft.isEmpty
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "note.text")
                .font(.title)
                .foregroundColor(Color(white: 0.65))
            Text(String(localized: "No memo"))
                .font(.subheadline)
                .foregroundColor(.white)
            Text(String(localized: "Click to add a memo"))
                .font(.caption)
                .foregroundColor(Color(white: 0.65))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            pendingFocus = true
            isEditing = true
        }
    }

    private var editor: some View {
        TextEditor(text: $draft)
            .font(.subheadline)
            .foregroundColor(.white)
            .scrollContentBackground(.hidden)
            .focused($isFocused)
            .padding(.horizontal, 2)
            .onAppear {
                guard pendingFocus else { return }
                pendingFocus = false
                isFocused = true
            }
            .onChange(of: draft) { _, newValue in
                homeMemoText = newValue
            }
    }

    private func persist() {
        homeMemoText = draft
    }
}

struct StandaloneHomeMemoView: View {
    var body: some View {
        HomeMemoView(standalone: true)
    }
}
