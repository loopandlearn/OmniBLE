//
//  OmniBLEHUDProvider.swift
//  OmniBLE
//
//  Based on OmniKitUI/PumpManager/OmniBLEHUDProvider.swift
//  Created by Pete Schwamb on 11/26/18.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import UIKit
import SwiftUI
import LoopKit
import LoopKitUI

public enum ReservoirAlertState {
    case ok
    case lowReservoir
    case empty
}

internal class OmniBLEHUDProvider: NSObject, HUDProvider {
    var managerIdentifier: String {
        return pumpManager.pluginIdentifier
    }

    private let pumpManager: OmniBLEPumpManager

    private var reservoirView: OmniBLEReservoirView?
    
    private let bluetoothProvider: BluetoothProvider

    private let colorPalette: LoopUIColorPalette
    
    private var refreshTimer: Timer?
    
    private let allowedInsulinTypes: [InsulinType]

    var visible: Bool = false {
        didSet {
            if oldValue != visible && visible {
                hudDidAppear()
            }
        }
    }

    public init(pumpManager: OmniBLEPumpManager, bluetoothProvider: BluetoothProvider, colorPalette: LoopUIColorPalette, allowedInsulinTypes: [InsulinType]) {
        self.pumpManager = pumpManager
        self.bluetoothProvider = bluetoothProvider
        self.colorPalette = colorPalette
        self.allowedInsulinTypes = allowedInsulinTypes
        super.init()
        self.pumpManager.addPodStateObserver(self, queue: .main)

        // Needed setup if pod keep alives might be used
        podKeepAliveSetup(refresh: refresh)
    }

    public func createHUDView() -> BaseHUDView? {
        reservoirView = OmniBLEReservoirView.instantiate()
        updateReservoirView()

        return reservoirView
    }

    public func didTapOnHUDView(_ view: BaseHUDView, allowDebugFeatures: Bool) -> HUDTapAction? {
        let vc = pumpManager.settingsViewController(bluetoothProvider: bluetoothProvider, colorPalette: colorPalette, allowDebugFeatures: allowDebugFeatures, allowedInsulinTypes: allowedInsulinTypes)
        return HUDTapAction.presentViewController(vc)
    }

    func hudDidAppear() {
        updateReservoirView()
        refresh()
    }
    
    public var hudViewRawState: HUDProvider.HUDViewRawState {
        var rawValue: HUDProvider.HUDViewRawState = [:]
        
        rawValue["lastStatusDate"] = pumpManager.lastStatusDate

        if let reservoirLevel = pumpManager.reservoirLevel {
            rawValue["reservoirLevel"] = reservoirLevel.rawValue
        }

        if let reservoirLevelHighlightState = pumpManager.reservoirLevelHighlightState {
            rawValue["reservoirLevelHighlightState"] = reservoirLevelHighlightState.rawValue
        }

        return rawValue
    }

    public static func createHUDView(rawValue: HUDProvider.HUDViewRawState) -> BaseHUDView? {
        guard let rawReservoirLevel = rawValue["reservoirLevel"] as? ReservoirLevel.RawValue,
              let rawReservoirLevelHighlightState = rawValue["reservoirLevelHighlightState"] as? ReservoirLevelHighlightState.RawValue,
              let reservoirLevelHighlightState = ReservoirLevelHighlightState(rawValue: rawReservoirLevelHighlightState)
        else {
            return nil
        }

        let reservoirView: OmniBLEReservoirView?

        let reservoirLevel = ReservoirLevel(rawValue: rawReservoirLevel)

        if let lastStatusDate = rawValue["lastStatusDate"] as? Date {
            reservoirView = OmniBLEReservoirView.instantiate()
            reservoirView!.update(level: reservoirLevel, at: lastStatusDate, reservoirLevelHighlightState: reservoirLevelHighlightState)
        } else {
            reservoirView = nil
        }

        return reservoirView
    }
    
    private func refresh() {
        pumpManager.getPodStatus() { _ in
            DispatchQueue.main.async {
                self.updateReservoirView()
            }
        }
    }

    private func updateReservoirView() {
        guard let reservoirView = reservoirView,
              let lastStatusDate = pumpManager.lastStatusDate,
            let reservoirLevelHighlightState = pumpManager.reservoirLevelHighlightState else
        {
            return
        }
            
        reservoirView.update(level: pumpManager.reservoirLevel, at: lastStatusDate, reservoirLevelHighlightState: reservoirLevelHighlightState)
    }

    // Called when the podState has been updated.
    // Looks for changes in podState?.podTimeUpdated
    // as key to tell if a new response was received and
    // manage a timer based pod keep alive when in the foreground.
    private func gotUpdatedPodState(podState: PodState?) {
        guard let podTimeUpdated = podState?.podTimeUpdated,
            podTimeUpdated != Storage.shared.lastUpdateTime.value
        else {
            return // No new status return with this podState update
        }
        Storage.shared.lastUpdateTime.value = podTimeUpdated // save the pod time updated value

        let podKeepAliveType = Storage.shared.podKeepAliveType.value
        let inBackground = Storage.shared.inBackground.value
        if podKeepAliveType == .disabled {
            return // all done for now
        }

        // If podKeepAliveType is .rileyLink, only bail if running in the background so that we
        // can have longer than 2 minute pod alive status requests while running in the foreground.
        if inBackground && podKeepAliveType == .rileyLink {
            print("@@@ Skipping timer refresh while in background using rileyLink")
            return
        }

        var nowStr: String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm:ss"
            let str = dateFormatter.string(from: Date())
            return str
        }

        // Have a new status response and pod keep alives are enabled (typically for iPhone 16's with InPlay pods),
        // so create a new update Timer to potentially trigger a later pod keep alive refresh after updateTimerInterval.

        // The following code implementing a timer to trigger a refresh
        // after refreshTimerInterval seconds has past since the last response.
        // This code will be run with podKeepAliveType == .whenOpen or silentTune
        // or when podKeepAliveType and we are not running in the background.

        // Cancel the current refreshTimer and create a new one.
        refreshTimer?.invalidate()
        let refreshTimerInterval = Storage.shared.refreshTimerInterval.value
        refreshTimer = Timer(timeInterval: refreshTimerInterval, repeats: false) { [self] _ in
            print("@@@ refreshTimer expired, doing refresh at \(nowStr)")
            self.refresh()
        }

        print("@@@ refreshTimer created for \(nowStr) + \(refreshTimerInterval.timeIntervalStr)")
        RunLoop.main.add(refreshTimer!, forMode: .default)
    }
}

extension OmniBLEHUDProvider: PodStateObserver {
    func podConnectionStateDidChange(isConnected: Bool) {
        // ignore for now
    }

    func podStateDidUpdate(_ state: PodState?) {
        updateReservoirView()
        gotUpdatedPodState(podState: state)
    }
}
