//
//  PomodoroWidgetBundle.swift
//  PomodoroWidget
//
//  Created by sijan shrestha on 16/1/26.
//

import WidgetKit
import SwiftUI

@main
struct PomodoroWidgetBundle: WidgetBundle {
    var body: some Widget {
        PomodoroWidget()
        PomodoroWidgetControl()
    }
}
