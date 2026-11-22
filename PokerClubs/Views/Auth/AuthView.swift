import SwiftUI

struct AuthView: View {
    @State private var vm = AuthViewModel()
    @State private var mode: Mode = .signIn
    @State private var showForgotPassword = false
    @State private var forgotPasswordSent = false

    let onAuthenticated: () async -> Void

    enum Mode { case signIn, signUp }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    header
                    modePicker
                    form
                    submitButton
                    if mode == .signIn {
                        forgotPasswordButton
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                .padding(.bottom, 32)
            }
            .navigationTitle("")
            .navBarInline()
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView(vm: vm, sent: $forgotPasswordSent)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "suit.spade.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text("Poker Clubs")
                .font(.largeTitle.bold())
            Text("Track your club's games")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var modePicker: some View {
        Picker("Mode", selection: $mode) {
            Text("Sign In").tag(Mode.signIn)
            Text("Create Account").tag(Mode.signUp)
        }
        .pickerStyle(.segmented)
        .onChange(of: mode) { _, _ in vm.errorMessage = nil }
    }

    private var form: some View {
        VStack(spacing: 16) {
            if mode == .signUp {
                TextField("Full name", text: $vm.name)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.name)
                    .autocorrectionDisabled()
            }
            TextField("Email", text: $vm.email)
                .textFieldStyle(.roundedBorder)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .emailInput()
            SecureField("Password (8+ characters)", text: $vm.password)
                .textFieldStyle(.roundedBorder)
                .textContentType(mode == .signUp ? .newPassword : .password)

            if let error = vm.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var submitButton: some View {
        Button {
            Task {
                do {
                    if mode == .signIn {
                        try await vm.signIn()
                    } else {
                        try await vm.signUp()
                    }
                    await onAuthenticated()
                } catch {}
            }
        } label: {
            Group {
                if vm.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(mode == .signIn ? "Sign In" : "Create Account")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .disabled(vm.isLoading || !isFormValid)
    }

    private var forgotPasswordButton: some View {
        Button("Forgot password?") {
            showForgotPassword = true
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    private var isFormValid: Bool {
        let emailOk = vm.email.contains("@")
        let passOk = vm.password.count >= 8
        if mode == .signUp { return !vm.name.isEmpty && emailOk && passOk }
        return emailOk && passOk
    }
}

struct ForgotPasswordView: View {
    @Bindable var vm: AuthViewModel
    @Binding var sent: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if sent {
                    VStack(spacing: 16) {
                        Image(systemName: "envelope.badge.checkmark")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)
                        Text("Check your email")
                            .font(.title2.bold())
                        Text("We sent a password reset link to \(vm.email).")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        Button("Done") { dismiss() }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                    }
                    .padding()
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Enter your email and we'll send you a reset link.")
                            .foregroundStyle(.secondary)
                        TextField("Email", text: $vm.email)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .emailInput()
                        if let error = vm.errorMessage {
                            Text(error).font(.footnote).foregroundStyle(.red)
                        }
                        Button {
                            Task {
                                do {
                                    try await vm.requestPasswordReset()
                                    sent = true
                                } catch {}
                            }
                        } label: {
                            Group {
                                if vm.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Send Reset Link").fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity).frame(height: 50)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .disabled(vm.isLoading || !vm.email.contains("@"))
                    }
                    .padding()
                }
                Spacer()
            }
            .navigationTitle("Reset Password")
            .navBarInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
