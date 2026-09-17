/*
 * Atoll (DynamicIsland)
 * Copyright (C) 2024-2026 Atoll Contributors
 *
 * Originally from boring.notch project
 * Modified and adapted for Atoll (DynamicIsland)
 * See NOTICE for details.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

import Defaults
import SwiftUI
import UniformTypeIdentifiers

struct TabOrderSettingsSection: View {
    let highlightID: String

    @Default(.notchTabOrder) private var notchTabOrder
    @Default(.enableMinimalisticUI) private var enableMinimalisticUI
    @Default(.showStandardMediaControls) private var showStandardMediaControls
    @Default(.showCalendar) private var showCalendar
    @Default(.showMirror) private var showMirror
    @Default(.dynamicShelf) private var dynamicShelf
    @Default(.enableTimerFeature) private var enableTimerFeature
    @Default(.timerDisplayMode) private var timerDisplayMode
    @Default(.enableStatsFeature) private var enableStatsFeature
    @Default(.enableLLMUsageFeature) private var enableLLMUsageFeature
    @Default(.enableNotes) private var enableNotes
    @Default(.enableQuickNote) private var enableQuickNote
    @Default(.enableClipboardManager) private var enableClipboardManager
    @Default(.clipboardDisplayMode) private var clipboardDisplayMode
    @Default(.enableTerminalFeature) private var enableTerminalFeature
    @State private var dropTargetID: String?

    private var visibleTabs: [TabModel] {
        _ = (
            enableMinimalisticUI, showStandardMediaControls, showCalendar, showMirror,
            dynamicShelf, enableTimerFeature, timerDisplayMode, enableStatsFeature,
            enableLLMUsageFeature, enableNotes, enableQuickNote, enableClipboardManager,
            clipboardDisplayMode, enableTerminalFeature, notchTabOrder
        )
        return NotchTabOrder.visibleSystemTabs()
    }

    var body: some View {
        Section {
            if visibleTabs.isEmpty {
                Text("No notch tabs are enabled.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(visibleTabs.enumerated()), id: \.element.id) { index, tab in
                    tabRow(tab, at: index)
                }
            }

            Button("Restore Default Order") {
                notchTabOrder = NotchTabOrder.defaultSystemIDs
            }
            .disabled(notchTabOrder == NotchTabOrder.defaultSystemIDs)
        } header: {
            Text("Notch Tabs")
        } footer: {
            Text("Drag the handle to reorder tabs in the expanded notch, or use the arrows. Disabled features keep their place and reappear there when turned back on.")
        }
        .settingsHighlight(id: highlightID)
    }

    private func tabRow(_ tab: TabModel, at index: Int) -> some View {
        let canReorder = visibleTabs.count > 1
        let tabID = tab.view.rawValue
        return HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.secondary)
                .opacity(canReorder ? 1 : 0.3)
                .frame(width: 16, height: 16)
                .contentShape(Rectangle())
                .onDrag {
                    NSItemProvider(object: NSString(string: tabID))
                }
            Label(tab.label, systemImage: tab.icon)
            Spacer(minLength: 8)
            Button {
                move(tabID, by: -1)
            } label: {
                Image(systemName: "chevron.up")
            }
            .buttonStyle(.borderless)
            .disabled(!canReorder || index == 0)
            Button {
                move(tabID, by: 1)
            } label: {
                Image(systemName: "chevron.down")
            }
            .buttonStyle(.borderless)
            .disabled(!canReorder || index == visibleTabs.count - 1)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(dropTargetID == tabID ? Color.accentColor.opacity(0.16) : Color.clear)
        )
        .onDrop(of: [UTType.plainText], isTargeted: dropBinding(for: tabID)) { providers in
            handleDrop(providers, onto: tabID)
        }
    }

    private func dropBinding(for id: String) -> Binding<Bool> {
        Binding(
            get: { dropTargetID == id },
            set: { dropTargetID = $0 ? id : (dropTargetID == id ? nil : dropTargetID) }
        )
    }

    private func handleDrop(_ providers: [NSItemProvider], onto target: String) -> Bool {
        for provider in providers where provider.canLoadObject(ofClass: NSString.self) {
            provider.loadObject(ofClass: NSString.self) { item, _ in
                guard let dragged = item as? String else { return }
                DispatchQueue.main.async {
                    drop(dragged, onto: target)
                    dropTargetID = nil
                }
            }
            return true
        }
        return false
    }

    private func move(_ id: String, by offset: Int) {
        var enabled = visibleTabs.map(\.view.rawValue)
        guard let index = enabled.firstIndex(of: id) else { return }
        let destination = index + offset
        guard enabled.indices.contains(destination) else { return }
        enabled.move(fromOffsets: IndexSet(integer: index), toOffset: offset > 0 ? destination + 1 : destination)
        apply(enabled)
    }

    private func drop(_ dragged: String, onto target: String) {
        var enabled = visibleTabs.map(\.view.rawValue)
        guard dragged != target,
              let from = enabled.firstIndex(of: dragged),
              enabled.contains(target) else { return }
        enabled.remove(at: from)
        let insertAt = enabled.firstIndex(of: target) ?? enabled.endIndex
        enabled.insert(dragged, at: insertAt)
        apply(enabled)
    }

    private func apply(_ enabled: [String]) {
        notchTabOrder = NotchTabOrder.applying(
            enabledOrder: enabled,
            to: NotchTabOrder.resolvedOrder(notchTabOrder)
        )
    }
}
