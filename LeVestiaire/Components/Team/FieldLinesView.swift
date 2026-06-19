//
//  FieldLinesView.swift
//  LeVestaire
//

import SwiftUI

/// Proportions inspirées d'un terrain FIFA (105 × 68 m), orienté verticalement.
private struct FootballPitchMetrics {
    let width: CGFloat
    let height: CGFloat

    var lineWidth: CGFloat { max(1.2, min(width, height) * 0.011) }
    var centerCircleRadius: CGFloat { width * (9.15 / 68) }
    var penaltyDepth: CGFloat { height * (16.5 / 105) }
    var penaltyWidth: CGFloat { width * (40.32 / 68) }
    var goalAreaDepth: CGFloat { height * (5.5 / 105) }
    var goalAreaWidth: CGFloat { width * (18.32 / 68) }
    var penaltySpotDistance: CGFloat { height * (11 / 105) }
    var penaltyArcRadius: CGFloat { width * (9.15 / 68) }
    var cornerArcRadius: CGFloat { width * (1 / 68) }
    var centerDotRadius: CGFloat { lineWidth * 0.75 }
    var penaltySpotRadius: CGFloat { lineWidth * 0.85 }

    var penaltyAreaLeft: CGFloat { (width - penaltyWidth) / 2 }
    var goalAreaLeft: CGFloat { (width - goalAreaWidth) / 2 }
    var center: CGPoint { CGPoint(x: width / 2, y: height / 2) }
}

struct FieldLinesView: View {
    var body: some View {
        Canvas { context, size in
            let metrics = FootballPitchMetrics(width: size.width, height: size.height)
            let paint = GraphicsContext.Shading.color(.white.opacity(0.92))
            let strokeStyle = StrokeStyle(
                lineWidth: metrics.lineWidth,
                lineCap: .round,
                lineJoin: .round
            )

            drawBoundary(context: &context, size: size, paint: paint, strokeStyle: strokeStyle)
            drawHalfwayLine(context: &context, metrics: metrics, paint: paint, strokeStyle: strokeStyle)
            drawCenterCircle(context: &context, metrics: metrics, paint: paint, strokeStyle: strokeStyle)
            drawPenaltyAreas(context: &context, metrics: metrics, paint: paint, strokeStyle: strokeStyle)
            drawGoalAreas(context: &context, metrics: metrics, paint: paint, strokeStyle: strokeStyle)
            drawPenaltySpots(context: &context, metrics: metrics)
            drawPenaltyArcs(context: &context, metrics: metrics, paint: paint, strokeStyle: strokeStyle)
            drawCornerArcs(context: &context, metrics: metrics, paint: paint, strokeStyle: strokeStyle)
        }
    }

    private func drawBoundary(
        context: inout GraphicsContext,
        size: CGSize,
        paint: GraphicsContext.Shading,
        strokeStyle: StrokeStyle
    ) {
        var boundary = Path()
        boundary.addRect(CGRect(origin: .zero, size: size))
        context.stroke(boundary, with: paint, style: strokeStyle)
    }

    private func drawHalfwayLine(
        context: inout GraphicsContext,
        metrics: FootballPitchMetrics,
        paint: GraphicsContext.Shading,
        strokeStyle: StrokeStyle
    ) {
        var linePath = Path()
        linePath.move(to: CGPoint(x: 0, y: metrics.height / 2))
        linePath.addLine(to: CGPoint(x: metrics.width, y: metrics.height / 2))
        context.stroke(linePath, with: paint, style: strokeStyle)
    }

    private func drawCenterCircle(
        context: inout GraphicsContext,
        metrics: FootballPitchMetrics,
        paint: GraphicsContext.Shading,
        strokeStyle: StrokeStyle
    ) {
        let centerCircle = Path(
            ellipseIn: CGRect(
                x: metrics.center.x - metrics.centerCircleRadius,
                y: metrics.center.y - metrics.centerCircleRadius,
                width: metrics.centerCircleRadius * 2,
                height: metrics.centerCircleRadius * 2
            )
        )
        context.stroke(centerCircle, with: paint, style: strokeStyle)

        let centerDot = Path(
            ellipseIn: CGRect(
                x: metrics.center.x - metrics.centerDotRadius,
                y: metrics.center.y - metrics.centerDotRadius,
                width: metrics.centerDotRadius * 2,
                height: metrics.centerDotRadius * 2
            )
        )
        context.fill(centerDot, with: .color(.white))
    }

    private func drawPenaltyAreas(
        context: inout GraphicsContext,
        metrics: FootballPitchMetrics,
        paint: GraphicsContext.Shading,
        strokeStyle: StrokeStyle
    ) {
        var topPenalty = Path()
        topPenalty.addRect(
            CGRect(
                x: metrics.penaltyAreaLeft,
                y: 0,
                width: metrics.penaltyWidth,
                height: metrics.penaltyDepth
            )
        )
        context.stroke(topPenalty, with: paint, style: strokeStyle)

        var bottomPenalty = Path()
        bottomPenalty.addRect(
            CGRect(
                x: metrics.penaltyAreaLeft,
                y: metrics.height - metrics.penaltyDepth,
                width: metrics.penaltyWidth,
                height: metrics.penaltyDepth
            )
        )
        context.stroke(bottomPenalty, with: paint, style: strokeStyle)
    }

    private func drawGoalAreas(
        context: inout GraphicsContext,
        metrics: FootballPitchMetrics,
        paint: GraphicsContext.Shading,
        strokeStyle: StrokeStyle
    ) {
        var topGoal = Path()
        topGoal.addRect(
            CGRect(
                x: metrics.goalAreaLeft,
                y: 0,
                width: metrics.goalAreaWidth,
                height: metrics.goalAreaDepth
            )
        )
        context.stroke(topGoal, with: paint, style: strokeStyle)

        var bottomGoal = Path()
        bottomGoal.addRect(
            CGRect(
                x: metrics.goalAreaLeft,
                y: metrics.height - metrics.goalAreaDepth,
                width: metrics.goalAreaWidth,
                height: metrics.goalAreaDepth
            )
        )
        context.stroke(bottomGoal, with: paint, style: strokeStyle)
    }

    private func drawPenaltySpots(
        context: inout GraphicsContext,
        metrics: FootballPitchMetrics
    ) {
        let spotPaint = GraphicsContext.Shading.color(.white)
        let spotSize = metrics.penaltySpotRadius * 2

        let topSpot = Path(
            ellipseIn: CGRect(
                x: metrics.center.x - metrics.penaltySpotRadius,
                y: metrics.penaltySpotDistance - metrics.penaltySpotRadius,
                width: spotSize,
                height: spotSize
            )
        )
        context.fill(topSpot, with: spotPaint)

        let bottomSpot = Path(
            ellipseIn: CGRect(
                x: metrics.center.x - metrics.penaltySpotRadius,
                y: metrics.height - metrics.penaltySpotDistance - metrics.penaltySpotRadius,
                width: spotSize,
                height: spotSize
            )
        )
        context.fill(bottomSpot, with: spotPaint)
    }

    private func drawPenaltyArcs(
        context: inout GraphicsContext,
        metrics: FootballPitchMetrics,
        paint: GraphicsContext.Shading,
        strokeStyle: StrokeStyle
    ) {
        let topSpot = CGPoint(x: metrics.center.x, y: metrics.penaltySpotDistance)
        let bottomSpot = CGPoint(x: metrics.center.x, y: metrics.height - metrics.penaltySpotDistance)

        drawPenaltyArc(
            context: &context,
            spot: topSpot,
            penaltyLineY: metrics.penaltyDepth,
            arcRadius: metrics.penaltyArcRadius,
            opensDownward: true,
            paint: paint,
            strokeStyle: strokeStyle
        )

        drawPenaltyArc(
            context: &context,
            spot: bottomSpot,
            penaltyLineY: metrics.height - metrics.penaltyDepth,
            arcRadius: metrics.penaltyArcRadius,
            opensDownward: false,
            paint: paint,
            strokeStyle: strokeStyle
        )
    }

    private func drawPenaltyArc(
        context: inout GraphicsContext,
        spot: CGPoint,
        penaltyLineY: CGFloat,
        arcRadius: CGFloat,
        opensDownward: Bool,
        paint: GraphicsContext.Shading,
        strokeStyle: StrokeStyle
    ) {
        let dy = penaltyLineY - spot.y
        let clampedDY = abs(dy)
        guard clampedDY < arcRadius else { return }

        let halfChord = sqrt(max(0, arcRadius * arcRadius - clampedDY * clampedDY))
        let leftAngle = Angle.radians(Double(atan2(dy, -halfChord)))
        let rightAngle = Angle.radians(Double(atan2(dy, halfChord)))

        var arc = Path()
        arc.addArc(
            center: spot,
            radius: arcRadius,
            startAngle: leftAngle,
            endAngle: rightAngle,
            clockwise: opensDownward
        )
        context.stroke(arc, with: paint, style: strokeStyle)
    }

    private func drawCornerArcs(
        context: inout GraphicsContext,
        metrics: FootballPitchMetrics,
        paint: GraphicsContext.Shading,
        strokeStyle: StrokeStyle
    ) {
        let radius = metrics.cornerArcRadius
        let corners: [(center: CGPoint, start: Angle, end: Angle)] = [
            (CGPoint(x: 0, y: 0), .degrees(0), .degrees(90)),
            (CGPoint(x: metrics.width, y: 0), .degrees(90), .degrees(180)),
            (CGPoint(x: 0, y: metrics.height), .degrees(270), .degrees(360)),
            (CGPoint(x: metrics.width, y: metrics.height), .degrees(180), .degrees(270))
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

#Preview("Compact") {
    FieldLinesView()
        .aspectRatio(0.68, contentMode: .fit)
        .frame(maxHeight: 168)
        .padding(6)
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
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
}
#endif
