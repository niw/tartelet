import Foundation
import SettingsDomain
import VirtualMachineData

struct SettingsTartExecutableProvider<SettingsStoreType: SettingsStore>: TartExecutableProvider {
    let settingsStore: SettingsStoreType
    var executableURL: URL? {
        settingsStore.tartExecutableURL
    }
}
