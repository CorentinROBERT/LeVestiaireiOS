//
//  FieldLinesView.swift
//  LeVestaire
//

import SwiftUI

struct FieldLinesView: View {
    var body: some View {
        Canvas { context, size in
            let fieldWidth = size.width
            let fieldHeight = size.height

            let paint = GraphicsContext.Shading.color(.white.opacity(0.9))
            let strokeStyle = StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)

            var boundary = Path()
            boundary.addRect(CGRect(x: 0, y: 0, width: fieldWidth, height: fieldHeight))
            context.stroke(boundary, with: paint, style: strokeStyle)

            var linePath = Path()
            linePath.move(to: CGPoint(x: 0, y: fieldHeight / 2))
            linePath.addLine(to: CGPoint(x: fieldWidth, y: fieldHeight / 2))
            context.stroke(linePath, with: paint, style: strokeStyle)

            let centerCircleRadius: CGFloat = 35
            let centerCircle = Path(
                ellipseIn: CGRect(
                    x: fieldWidth / 2 - centerCircleRadius,
                    y: fieldHeight / 2 - centerCircleRadius,
                    width: centerCircleRadius * 2,
                    height: centerCircleRadius * 2
                )
            )
            context.stroke(centerCircle, with: paint, style: strokeStyle)

            let centerDot = Path(
                ellipseIn: CGRect(
                    x: fieldWidth / 2 - 3,
                    y: fieldHeight / 2 - 3,
                    width: 6,
                    height: 6
                )
            )
            context.fill(centerDot, with: .color(.white))

            let penaltyAreaHeight: CGFloat = 120
            let penaltyAreaWidth = fieldWidth * 0.6
            let penaltyAreaLeft = (fieldWidth - penaltyAreaWidth) / 2

            var topPenalty = Path()
            topPenalty.addRect(
                CGRect(x: penaltyAreaLeft, y: 0, width: penaltyAreaWidth, height: penaltyAreaHeight)
            )
            context.stroke(topPenalty, with: paint, style: strokeStyle)

            var bottomPenalty = Path()
            bottomPenalty.addRect(
                CGRect(
                    x: penaltyAreaLeft,
                    y: fieldHeight - penaltyAreaHeight,
                    width: penaltyAreaWidth,
                    height: penaltyAreaHeight
                )
            )
            context.stroke(bottomPenalty, with: paint, style: strokeStyle)

            let goalWidth: CGFloat = 80
            let goalHeight: CGFloat = 60
            drawGoal(
                context: &context,
                fieldWidth: fieldWidth,
                goalTop: 0,
                goalWidth: goalWidth,
                goalHeight: goalHeight,
                paint: paint,
                strokeStyle: strokeStyle
            )
            drawGoal(
                context: &context,
                fieldWidth: fieldWidth,
                goalTop: fieldHeight - goalHeight,
                goalWidth: goalWidth,
                goalHeight: goalHeight,
                paint: paint,
                strokeStyle: strokeStyle
            )

            let penaltySpotDistance: CGFloat = 80
            let spotPaint = GraphicsContext.Shading.color(.white)
            let topSpot = Path(
                ellipseIn: CGRect(
                    x: fieldWidth / 2 - 4,
                    y: penaltySpotDistance - 4,
                    width: 8,
                    height: 8
                )
            )
            context.fill(topSpot, with: spotPaint)

            let bottomSpot = Path(
                ellipseIn: CGRect(
                    x: fieldWidth / 2 - 4,
                    y: fieldHeight - penaltySpotDistance - 4,
                    width: 8,
                    height: 8
                )
            )
            context.fill(bottomSpot, with: spotPaint)

            let cornerRadius = min(fieldWidth, fieldHeight) * 0.038
            drawCornerArcs(
                context: &context,
                fieldWidth: fieldWidth,
                fieldHeight: fieldHeight,
                radius: cornerRadius,
                paint: paint,
                strokeStyle: strokeStyle
            )
        }
    }

    private func drawCornerArcs(
        context: inout GraphicsContext,
        fieldWidth: CGFloat,
        fieldHeight: CGFloat,
        radius: CGFloat,
        paint: GraphicsContext.Shading,
        strokeStyle: StrokeStyle
    ) {
        let corners: [(center: CGPoint, start: Angle, end: Angle)] = [
            (CGPoint(x: radius, y: radius), .degrees(180), .degrees(270)),
            (CGPoint(x: fieldWidth - radius, y: radius), .degrees(270), .degrees(360)),
            (CGPoint(x: radius, y: fieldHeight - radius), .degrees(90), .degrees(180)),
            (CGPoint(x: fieldWidth - radius, y: fieldHeight - radius), .degrees(0), .degrees(90))
        ]

        for corner in corners {
            var arc = Path()
            arc.addArc(
                center: corner.center,
                radius: radius,
                startAngle: corner.start,
                endAngle: corner.end,
                clockwise: false
            )
            context.stroke(arc, with: paint, style: strokeStyle)
        }
    }

    private func drawGoal(
        context: inout GraphicsContext,
        fieldWidth: CGFloat,
        goalTop: CGFloat,
        goalWidth: CGFloat,
        goalHeight: CGFloat,
        paint: GraphicsContext.Shading,
        strokeStyle: StrokeStyle
    ) {
        let goalLeft = (fieldWidth - goalWidth) / 2
        var goalPath = Path()
        goalPath.addRect(
            CGRect(x: goalLeft, y: goalTop, width: goalWidth, height: goalHeight)
        )
        context.stroke(goalPath, with: paint, style: strokeStyle)
    }
}

#if DEBUG
#Preview {
    FieldLinesView()
        .aspectRatio(0.68, contentMode: .fit)
        .padding()
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.16, green: 0.55, blue: 0.22),
                    Color(red: 0.10, green: 0.42, blue: 0.16)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding()
}
#endif
