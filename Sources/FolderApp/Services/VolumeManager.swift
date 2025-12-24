import Foundation
import AppKit

@MainActor
class VolumeManager: ObservableObject {
    static let shared = VolumeManager()

    @Published var mountedVolumes: [VolumeInfo] = []

    private init() {
        loadMountedVolumes()
        setupNotifications()
    }

    private func setupNotifications() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(volumeDidMount(_:)),
            name: NSWorkspace.didMountNotification,
            object: nil
        )

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(volumeDidUnmount(_:)),
            name: NSWorkspace.didUnmountNotification,
            object: nil
        )
    }

    @objc private func volumeDidMount(_ notification: Notification) {
        loadMountedVolumes()
    }

    @objc private func volumeDidUnmount(_ notification: Notification) {
        loadMountedVolumes()
    }

    private func loadMountedVolumes() {
        guard let urls = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: [.volumeNameKey, .volumeIsRemovableKey, .volumeIsEjectableKey],
            options: [.skipHiddenVolumes]
        ) else {
            mountedVolumes = []
            return
        }

        var volumes: [VolumeInfo] = []

        for url in urls {
            do {
                let resourceValues = try url.resourceValues(forKeys: [
                    .volumeNameKey,
                    .volumeIsRemovableKey,
                    .volumeIsEjectableKey,
                    .volumeLocalizedNameKey
                ])

                // Skip system volumes (only show removable/external)
                let isRemovable = resourceValues.volumeIsRemovable ?? false
                let isEjectable = resourceValues.volumeIsEjectable ?? false

                if isRemovable || isEjectable {
                    let volumeName = resourceValues.volumeLocalizedName ?? resourceValues.volumeName ?? url.lastPathComponent

                    volumes.append(VolumeInfo(
                        url: url,
                        name: volumeName,
                        isRemovable: isRemovable,
                        isEjectable: isEjectable
                    ))
                }
            } catch {
                print("Failed to get volume info for \(url): \(error)")
            }
        }

        mountedVolumes = volumes.sorted { $0.name < $1.name }
    }

    func ejectVolume(_ volume: VolumeInfo) {
        do {
            try NSWorkspace.shared.unmountAndEjectDevice(at: volume.url)
        } catch {
            print("Failed to eject volume: \(error)")
        }
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}

struct VolumeInfo: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let name: String
    let isRemovable: Bool
    let isEjectable: Bool
}
