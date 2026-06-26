//
//  UFormPickers.swift
//  LeVestaire
//

import SwiftUI

enum UPickerLabelStyle {
    case row
    case hidden
}

struct UMenuPicker<SelectionValue: Hashable, Content: View>: View {
    let title: String
    @Binding var selection: SelectionValue
    var labelStyle: UPickerLabelStyle = .row
    var accessibilityValue: String?
    var isDisabled = false
    var onChange: (() -> Void)?
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack {
            if labelStyle == .row {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.Neutral.textPrimary)
            }

            Spacer()

            pickerControl
        }
    }

    @ViewBuilder
    private var pickerControl: some View {
        let picker = Picker(title, selection: $selection) {
            content()
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .tint(AppPalette.Primary.main)
        .disabled(isDisabled)
        .accessibilityLabel(title)
        .onChange(of: selection) { _, _ in
            onChange?()
        }

        if let accessibilityValue {
            picker.accessibilityValue(accessibilityValue)
        } else {
            picker
        }
    }
}

struct USegmentedPicker<SelectionValue: Hashable, Content: View>: View {
    let title: String?
    @Binding var selection: SelectionValue
    var accessibilityValue: String?
    var onChange: ((SelectionValue) -> Void)?
    @ViewBuilder let content: () -> Content

    init(
        title: String? = nil,
        selection: Binding<SelectionValue>,
        accessibilityValue: String? = nil,
        onChange: ((SelectionValue) -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self._selection = selection
        self.accessibilityValue = accessibilityValue
        self.onChange = onChange
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: title == nil ? 0 : 8) {
            if let title {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.Neutral.textPrimary)
            }

            segmentedControl
        }
    }

    @ViewBuilder
    private var segmentedControl: some View {
        let picker = Picker(title ?? "", selection: $selection) {
            content()
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .accessibilityLabel(title ?? "")
        .onChange(of: selection) { _, newValue in
            onChange?(newValue)
        }

        if let accessibilityValue {
            picker.accessibilityValue(accessibilityValue)
        } else {
            picker
        }
    }
}

struct UDatePickerRow: View {
    let title: String
    @Binding var selection: Date
    var minimumDate: Date?
    var maximumDate: Date?
    var displayedComponents: DatePicker.Components = .date
    var locale: Locale?

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.Neutral.textPrimary)

            Spacer()

            dateControl
        }
    }

    @ViewBuilder
    private var dateControl: some View {
        Group {
            switch (minimumDate, maximumDate) {
            case let (minimum?, maximum?):
                DatePicker(
                    "",
                    selection: $selection,
                    in: minimum...maximum,
                    displayedComponents: displayedComponents
                )
            case let (minimum?, nil):
                DatePicker(
                    "",
                    selection: $selection,
                    in: minimum...,
                    displayedComponents: displayedComponents
                )
            case let (nil, maximum?):
                DatePicker(
                    "",
                    selection: $selection,
                    in: ...maximum,
                    displayedComponents: displayedComponents
                )
            case (nil, nil):
                DatePicker(
                    "",
                    selection: $selection,
                    displayedComponents: displayedComponents
                )
            }
        }
        .labelsHidden()
        .datePickerStyle(.compact)
        .environment(\.locale, locale ?? .autoupdatingCurrent)
        .accessibilityLabel(title)
    }
}

struct UOptionalDatePickerRow: View {
    let title: String
    @Binding var selection: Date?
    var fallbackDate = Date()
    var displayedComponents: DatePicker.Components = .date

    var body: some View {
        UDatePickerRow(
            title: title,
            selection: Binding(
                get: { selection ?? fallbackDate },
                set: { selection = $0 }
            ),
            displayedComponents: displayedComponents
        )
    }
}

#if DEBUG
#Preview("Menu Picker") {
    struct PreviewWrapper: View {
        @State private var season = "2025-2026"

        var body: some View {
            UMenuPicker(title: "Saison", selection: $season) {
                Text("25-26").tag("2025-2026")
                Text("26-27").tag("2026-2027")
            }
            .padding()
        }
    }

    return PreviewWrapper()
}

#Preview("Segmented Picker") {
    struct PreviewWrapper: View {
        @State private var mode = 0

        var body: some View {
            USegmentedPicker(title: "Filtre", selection: $mode) {
                Text("Tous").tag(0)
                Text("Non lus").tag(1)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
#endif
