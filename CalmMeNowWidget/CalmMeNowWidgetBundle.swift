//
//  CalmMeNowWidgetBundle.swift
//  CalmMeNowWidget
//
//  Created by Thierry De Belder on 25/01/2026.
//

import WidgetKit
import SwiftUI

@main
struct CalmMeNowWidgetBundle: WidgetBundle {
    var body: some Widget {
        CalmMeNowWidget()
        CalmMeNowMediumWidget()
        CalmMeNowLockScreenWidget()
        NightProtocolWidget()
    }
}
