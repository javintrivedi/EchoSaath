//
//  AppIntent.swift
//  EchoSaathWidget
//
//  Created by Javin Trivedi on 03/04/26.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "EchoSaath Widget" }
    static var description: IntentDescription { "Shows your safety status at a glance." }
}
