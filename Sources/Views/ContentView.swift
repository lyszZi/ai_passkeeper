import SwiftUI

/// Main content view - routes to appropriate screen based on app state
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var i18nService: I18nService

    var body: some View {
        Group {
            if appState.isFirstLaunch {
                // 首次启动显示创建密码界面
                SetupView()
            } else if appState.isLocked {
                // 已设置密码但已锁定
                LockScreenView()
            } else {
                // 已解锁，显示主界面
                MainView()
            }
        }
        .animation(.easeInOut, value: appState.isLocked)
    }
}

/// Lock screen for entering master password or biometric
struct LockScreenView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 32) {
            // App icon
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("app.title".localized)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("auth.enterPassword".localized)
                .foregroundStyle(.secondary)

            // Password field
            VStack(spacing: 16) {
                SecureField("auth.password".localized, text: $viewModel.primaryPassword)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)
                    .onSubmit {
                        Task {
                            _ = await viewModel.unlockWithPassword()
                        }
                    }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                Button("auth.unlock".localized) {
                    Task {
                        _ = await viewModel.unlockWithPassword()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)

#if false
                // Biometric option
                if viewModel.isBiometricAvailable {
                    Button {
                        Task {
                            _ = await viewModel.unlockWithBiometric()
                        }
                    } label: {
                        Label(viewModel.biometricType.displayName, systemImage: viewModel.biometricType.icon)
                    }
                    .buttonStyle(.bordered)
                }
#endif
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

/// Initial setup screen for first-time users
struct SetupView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 32) {
            // App icon
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("auth.welcome".localized)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("auth.createVaultDesc".localized)
                .foregroundStyle(.secondary)

            // Setup form
            VStack(spacing: 16) {
                SecureField("auth.password".localized, text: $viewModel.primaryPassword)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)

                SecureField("auth.confirmPassword".localized, text: $viewModel.confirmPassword)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)
                    .onSubmit {
                        Task {
                            _ = await viewModel.setupPrimaryPassword()
                        }
                    }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                Text("auth.passwordMinLength".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("auth.createVault".localized) {
                    Task {
                        _ = await viewModel.setupPrimaryPassword()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
}
