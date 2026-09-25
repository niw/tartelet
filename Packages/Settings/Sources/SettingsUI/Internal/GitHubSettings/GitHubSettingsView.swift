import GitHubDomain
import Observation
import SettingsDomain
import SwiftUI

struct GitHubSettingsView<SettingsStoreType: SettingsStore & Observable>: View {
    @Bindable var settingsStore: SettingsStoreType
    let credentialsStore: GitHubCredentialsStore
    let isSettingsEnabled: Bool

    @State private var organizationName = ""
    @State private var ownerName = ""
    @State private var repositoryName = ""
    @State private var appId = ""
    @State private var privateKeyName = ""
    @State private var privateKeyDeletionFailed = false

    var body: some View {
        Form {
            Section {
                Picker(L10n.Settings.Github.runnerScope, selection: $settingsStore.githubRunnerScope) {
                    ForEach(GitHubRunnerScope.allCases, id: \.self) { scope in
                        Text(scope.title)
                    }
                }
                .pickerStyle(.segmented)
                switch settingsStore.githubRunnerScope {
                case .organization:
                    TextField(
                        L10n.Settings.Github.organizationName,
                        text: $organizationName,
                        prompt: Text(L10n.Settings.Github.OrganizationName.prompt)
                    )
                    .disabled(!isSettingsEnabled)
                case .repo:
                    TextField(
                        L10n.Settings.Github.ownerName,
                        text: $ownerName,
                        prompt: Text(L10n.Settings.Github.OwnerName.prompt)
                    )
                    .disabled(!isSettingsEnabled)
                    TextField(
                        L10n.Settings.Github.repositoryName,
                        text: $repositoryName,
                        prompt: Text(L10n.Settings.Github.RepositoryName.prompt)
                    )
                    .disabled(!isSettingsEnabled)
                }
            }
            Section {
                TextField(L10n.Settings.Github.appId, text: $appId)
                    .disabled(!isSettingsEnabled)
                GitHubPrivateKeyPicker(
                    filename: $privateKeyName,
                    scope: settingsStore.githubRunnerScope,
                    isEnabled: isSettingsEnabled,
                    hasPrivateKey: credentialsStore.privateKey != nil
                ) { fileURL in
                    Task {
                        await storePrivateKey(at: fileURL)
                    }
                } onDelete: {
                    deletePrivateKey()
                }
                if privateKeyDeletionFailed {
                    Text(L10n.Settings.Github.PrivateKey.deletionFailed)
                        .foregroundStyle(.red)
                }
            } footer: {
                Button {
                    openCreateApp()
                } label: {
                    Text(L10n.Settings.Github.createApp)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            organizationName = credentialsStore.organizationName ?? ""
            ownerName = credentialsStore.ownerName ?? ""
            repositoryName = credentialsStore.repositoryName ?? ""
            appId = credentialsStore.appId ?? ""
            if credentialsStore.privateKey != nil {
                privateKeyName = settingsStore.gitHubPrivateKeyName ?? ""
            } else {
                privateKeyName = ""
            }
        }
        .onChange(of: organizationName) { _, newValue in
            if !newValue.isEmpty {
                credentialsStore.setOrganizationName(newValue)
            } else {
                credentialsStore.setOrganizationName(nil)
            }
        }
        .onChange(of: ownerName) { _, _ in
            persistRepositoryNameAndOwnerName()
        }
        .onChange(of: repositoryName) { _, _ in
            persistRepositoryNameAndOwnerName()
        }
        .onChange(of: appId) { _, newValue in
            if !newValue.isEmpty {
                credentialsStore.setAppID(newValue)
            } else {
                credentialsStore.setAppID(nil)
            }
        }
    }
}

private extension GitHubSettingsView {
    private func openCreateApp() {
        var url = URL(string: "https://github.com")!
        if !organizationName.isEmpty, case .organization = settingsStore.githubRunnerScope {
            url.append(path: "/organizations/\(organizationName)")
        }
        url.append(path: "/settings/apps")
        NSWorkspace.shared.open(url)
    }

    private func storePrivateKey(at fileURL: URL) async {
        privateKeyDeletionFailed = false
        do {
            let data = try Data(contentsOf: fileURL)
            credentialsStore.setPrivateKey(data)
            let didStorePrivateKey = credentialsStore.privateKey != nil
            settingsStore.gitHubPrivateKeyName = didStorePrivateKey ? fileURL.lastPathComponent : nil
            privateKeyName = settingsStore.gitHubPrivateKeyName ?? ""
        } catch {
            #if DEBUG
            print(error)
            #endif
        }
    }

    private func deletePrivateKey() {
        credentialsStore.setPrivateKey(nil)
        privateKeyDeletionFailed = credentialsStore.privateKey != nil
        guard !privateKeyDeletionFailed else {
            return
        }
        settingsStore.gitHubPrivateKeyName = nil
        privateKeyName = ""
    }

    private func persistRepositoryNameAndOwnerName() {
        let repositoryName = !repositoryName.isEmpty ? self.repositoryName : nil
        let ownerName = !ownerName.isEmpty ? self.ownerName : nil
        credentialsStore.setRepository(repositoryName, withOwner: ownerName)
    }
}

private extension GitHubRunnerScope {
    var title: String {
        switch self {
        case .organization:
            L10n.Settings.RunnerScope.organization
        case .repo:
            L10n.Settings.RunnerScope.repository
        }
    }
}
