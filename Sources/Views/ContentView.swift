import SwiftUI

/// Main content view - routes to appropriate screen based on app state
struct ContentView: View {
    @EnvironmentObject var appState: AppState

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

            Text("PassKeeper")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Enter your master password to unlock")
                .foregroundStyle(.secondary)

            // Password field
            VStack(spacing: 16) {
                SecureField("Master Password", text: $viewModel.masterPassword)
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

                Button("Unlock") {
                    Task {
                        _ = await viewModel.unlockWithPassword()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)

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

            Text("Welcome to PassKeeper")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Create a master password to secure your vault")
                .foregroundStyle(.secondary)

            // Setup form
            VStack(spacing: 16) {
                SecureField("Master Password", text: $viewModel.masterPassword)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)

                SecureField("Confirm Password", text: $viewModel.confirmPassword)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)
                    .onSubmit {
                        Task {
                            _ = await viewModel.setupMasterPassword()
                        }
                    }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                Text("Password must be at least 8 characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Create Vault") {
                    Task {
                        _ = await viewModel.setupMasterPassword()
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