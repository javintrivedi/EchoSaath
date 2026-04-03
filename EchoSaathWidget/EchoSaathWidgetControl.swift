//
//  EchoSaathWidgetControl.swift
//  EchoSaathWidget
//
//  Created by Javin Trivedi on 03/04/26.
//

import AppIntents
import SwiftUI
import WidgetKit

struct EchoSaathWidgetControl: ControlWidget {
    static let kind: String = "jt.EchoSaath.EchoSaathWidgetControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenAppIntent()) {
                Label("EchoSaath", systemImage: "shield.checkered")
            }
        }
        .displayName("Open EchoSaath")
        .description("Quickly open EchoSaath safety app.")
    }
}

struct OpenAppIntent: AppIntent {
    static var title: LocalizedStringResource { "Open EchoSaath" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
