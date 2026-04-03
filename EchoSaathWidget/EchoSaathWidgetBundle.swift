//
//  EchoSaathWidgetBundle.swift
//  EchoSaathWidget
//
//  Created by Javin Trivedi on 03/04/26.
//

import WidgetKit
import SwiftUI

@main
struct EchoSaathWidgetBundle: WidgetBundle {
    var body: some Widget {
        EchoSaathWidget()
        EchoSaathWidgetControl()
        EchoSaathWidgetLiveActivity()
    }
}
