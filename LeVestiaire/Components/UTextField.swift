//
//  UTextField.swift
//  LeVestaire
//
//  Created by Corentin Robert on 14/06/2026.
//

import SwiftUI

enum UTextFieldStyle {
    case light
    case dark

    var iconColor: Color {
        switch self {
        case .light:
            return AppPalette.Primary.light
        case .dark:
            return .white.opacity(0.9)
        }
    }

    var textColor: Color {
        switch self {
        case .light:
            return AppPalette.Neutral.textPrimary
        case .dark:
            return .white
        }
    }

    var labelColor: Color {
        switch self {
        case .light:
            return AppPalette.Neutral.textSecondary
        case .dark:
            return .white.opacity(0.78)
        }
    }

    var accessoryColor: Color {
        switch self {
        case .light:
            return AppPalette.Primary.muted
        case .dark:
            return .white.opacity(0.75)
        }
    }

    var helperColor: Color {
        switch self {
        case .light:
            return AppPalette.Neutral.textTertiary
        case .dark:
            return .white.opacity(0.65)
        }
    }
}

struct UTextField: View {
    let label: String?
    let placeholder: String
    let icon: String?
    @Binding var text: String
    var style: UTextFieldStyle = .light
    var isSecure: Bool = false
    var isPasswordVisible: Binding<Bool>? = nil
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .never
    var autocorrectionDisabled: Bool = true
    var usesOneTimeCodeAutofill: Bool = false
    var errorMessage: String?
    var helperText: String?
    var submitLabel: SubmitLabel = .return
    var onSubmit: (() -> Void)? = nil
    var focusTag: Int? = nil
    var focusedTag: FocusState<Int?>.Binding? = nil
    var nextFocusTag: Int? = nil
    var usesSystemKeyboardToolbar = true

    @FocusState private var isInternallyFocused: Bool

    private var resolvedKeyboardType: UIKeyboardType {
        usesOneTimeCodeAutofill ? .default : keyboardType
    }

    private var showsKeyboardDismissButton: Bool {
        switch resolvedKeyboardType {
        case .numberPad, .decimalPad, .phonePad:
            return true
        default:
            return false
        }
    }

    private var resolvedTextContentType: UITextContentType? {
        usesOneTimeCodeAutofill ? .oneTimeCode : textContentType
    }

    private var hasError: Bool {
        errorMessage?.isEmpty == false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label {
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(style.labelColor)
            }

            HStack(spacing: 12) {
                if let icon {
                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(hasError ? AppPalette.Semantic.error : style.iconColor)
                        .frame(width: 22)
                }

                Group {
                    if isSecure, let isPasswordVisible, !isPasswordVisible.wrappedValue {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .modifier(FocusModifier(
                    focusTag: focusTag,
                    focusedTag: focusedTag,
                    internalFocus: $isInternallyFocused
                ))
                .keyboardType(resolvedKeyboardType)
                .textContentType(resolvedTextContentType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(autocorrectionDisabled)
                .foregroundStyle(style.textColor)
                .tint(AppPalette.Primary.main)
                .submitLabel(submitLabel)
                .onSubmit {
                    if let nextFocusTag, let focusedTag {
                        focusedTag.wrappedValue = nextFocusTag
                    } else {
                        resignFocus()
                    }
                    onSubmit?()
                }
                .toolbar {
                    if showsKeyboardDismissButton, usesSystemKeyboardToolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button(L10n.done) {
                                resignFocus()
                            }
                            .fontWeight(.semibold)
                        }
                    }
                }

                if isSecure, let isPasswordVisible {
                    Button {
                        isPasswordVisible.wrappedValue.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible.wrappedValue ? "eye.slash.fill" : "eye.fill")
                            .font(.body.weight(.medium))
                            .foregroundStyle(style.accessoryColor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .glassEffect(.regular, in: .rect(cornerRadius: 18))
            .overlay {
                if hasError {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(AppPalette.Semantic.error.opacity(0.6), lineWidth: 1)
                }
            }

            if let errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(AppPalette.Semantic.error)
            } else if let helperText, !helperText.isEmpty {
                Text(helperText)
                    .font(.caption)
                    .foregroundStyle(style.helperColor)
            }
        }
    }

    private func resignFocus() {
        if let focusedTag {
            focusedTag.wrappedValue = nil
        } else {
            isInternallyFocused = false
        }
    }
}

private struct FocusModifier: ViewModifier {
    let focusTag: Int?
    let focusedTag: FocusState<Int?>.Binding?
    let internalFocus: FocusState<Bool>.Binding

    func body(content: Content) -> some View {
        if let focusedTag, let focusTag {
            content.focused(focusedTag, equals: focusTag)
        } else {
            content.focused(internalFocus)
        }
    }
}

extension UTextField {
    init(
        placeholder: String,
        icon: String,
        text: Binding<String>,
        style: UTextFieldStyle = .light,
        isSecure: Bool = false,
        isPasswordVisible: Binding<Bool>? = nil,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        usesOneTimeCodeAutofill: Bool = false,
        autocapitalization: TextInputAutocapitalization = .never,
        submitLabel: SubmitLabel = .return,
        onSubmit: (() -> Void)? = nil,
        focusTag: Int? = nil,
        focusedTag: FocusState<Int?>.Binding? = nil,
        nextFocusTag: Int? = nil,
        usesSystemKeyboardToolbar: Bool = true
    ) {
        self.init(
            label: nil,
            placeholder: placeholder,
            icon: icon,
            text: text,
            style: style,
            isSecure: isSecure,
            isPasswordVisible: isPasswordVisible,
            keyboardType: keyboardType,
            textContentType: textContentType,
            autocapitalization: autocapitalization,
            autocorrectionDisabled: true,
            usesOneTimeCodeAutofill: usesOneTimeCodeAutofill,
            submitLabel: submitLabel,
            onSubmit: onSubmit,
            focusTag: focusTag,
            focusedTag: focusedTag,
            nextFocusTag: nextFocusTag,
            usesSystemKeyboardToolbar: usesSystemKeyboardToolbar
        )
    }
}

typealias UGlassTextField = UTextField
typealias UGlassTextFieldStyle = UTextFieldStyle

#Preview {
    @Previewable @State var email = ""
    @Previewable @State var password = ""
    @Previewable @State var name = "Corentin"
    @Previewable @State var isPasswordVisible = false

    ZStack {
        AuthScreenBackground()

        ScrollView {
            VStack(spacing: 20) {
                UTextField(
                    label: "Email",
                    placeholder: "Adresse email",
                    icon: "envelope.fill",
                    text: $email,
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    helperText: "Utilisé pour la connexion et la récupération de compte."
                )

                UTextField(
                    label: "Mot de passe",
                    placeholder: "Mot de passe",
                    icon: "lock.fill",
                    text: $password,
                    isSecure: true,
                    isPasswordVisible: $isPasswordVisible,
                    textContentType: .password
                )

                UTextField(
                    label: "Prénom",
                    placeholder: "Prénom",
                    icon: "person.fill",
                    text: $name,
                    autocapitalization: .words,
                    errorMessage: "Ce champ est obligatoire."
                )
            }
            .padding(24)
        }
    }
}
