import Foundation
import SettingsDomain
import VirtualMachineData

struct SettingsTartRunOptionsProvider<SettingsStoreType: SettingsStore>: TartRunOptionsProvider {
    let settingsStore: SettingsStoreType
    var runOptions: [String] {
        settingsStore.tartRunOptions.split(whereSeparator: \.isWhitespace).map(String.init)
    }
}
