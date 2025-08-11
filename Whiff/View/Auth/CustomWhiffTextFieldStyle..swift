import SwiftUI

struct CustomWhiffTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color.whiffSectionBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.whiffPrimary.opacity(0.5), lineWidth: 1)
            )
            .foregroundColor(.whiffPrimaryText)
            .font(.body)
    }
}

//
//  CustomWhiffTextFieldStyle..swift
//  Whiff
//
//  Created by 조예나 on 7/22/25.
//

