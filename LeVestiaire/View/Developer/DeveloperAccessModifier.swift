//
//  DeveloperAccessModifier.swift
//  LeVestaire
//

import SwiftUI

struct DeveloperAccessModifier: ViewModifier {
    @ObservedObject var access: DeveloperAccessViewModel

    func body(content: Content) -> some View {
        content
            .alert(L10n.developerMode, isPresented: $access.showPasswordDialog) {
                SecureField(L10n.password, text: $access.passwordInput)
                Button(L10n.validate) {
                    access.validatePassword()
                }
                Button(L10n.cancel, role: .cancel) {
                    access.cancelPasswordEntry()
                }
            } message: {
                Text(L10n.enterDeveloperPassword)
            }
            .alert(L10n.accessRefused, isPresented: $access.showPasswordError) {
                Button(L10n.ok, role: .cancel) {}
            } message: {
                Text(L10n.incorrectPassword)
            }
            .fullScreenCover(isPresented: $access.showDeveloperPage) {
                DeveloperView()
            }
    }
}

extension View {
    func developerAccess(_ access: DeveloperAccessViewModel) -> some View {
        modifier(DeveloperAccessModifier(access: access))
    }
}
