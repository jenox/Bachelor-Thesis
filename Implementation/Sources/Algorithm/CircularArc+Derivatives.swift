import CoreGraphics


extension CircularArc {

    // MARK: - Points

    private func point1(for progress: CGFloat) -> CGPoint {
        let (p_x, p_y) = (self.start.x, self.start.y)
        let (q_x, q_y) = (self.end.x, self.end.y)
        let progress = progress
        let phi = self.angle

        let x = p_x
            + 0.5 * (q_x - p_x)
            + 0.5 * (q_y - p_y) / tan(phi)
            - 0.5 * cos(2 * progress * phi) * (q_x - p_x)
            - 0.5 * cos(2 * progress * phi) * (q_y - p_y) / tan(phi)
            + 0.5 * sin(2 * progress * phi) * (q_x - p_x) / tan(phi)
            - 0.5 * sin(2 * progress * phi) * (q_y - p_y)

        let y = p_y
            - 0.5 * (q_x - p_x) / tan(phi)
            + 0.5 * (q_y - p_y)
            + 0.5 * sin(2 * progress * phi) * (q_x - p_x)
            + 0.5 * sin(2 * progress * phi) * (q_y - p_y) / tan(phi)
            + 0.5 * cos(2 * progress * phi) * (q_x - p_x) / tan(phi)
            - 0.5 * cos(2 * progress * phi) * (q_y - p_y)

        return CGPoint(x: x, y: y)
    }

    private func point2(for progress: CGFloat) -> CGPoint {
        let (p_x, p_y) = (self.start.x, self.start.y)
        let (q_x, q_y) = (self.end.x, self.end.y)
        let progress = progress
        let phi = self.angle

        let x = 0.5 * p_x + 0.5 * q_x
            + 0.5 * (q_y - p_y) / tan(phi)
            - 0.5 * (q_x - p_x) * sin(phi - 2 * progress * phi) / sin(phi)
            - 0.5 * (q_y - p_y) * cos(phi - 2 * progress * phi) / sin(phi)

        let y = 0.5 * p_y + 0.5 * q_y
            - 0.5 * (q_x - p_x) / tan(phi)
            - 0.5 * (q_y - p_y) * sin(phi - 2 * progress * phi) / sin(phi)
            + 0.5 * (q_x - p_x) * cos(phi - 2 * progress * phi) / sin(phi)

        return CGPoint(x: x, y: y)
    }



    // MARK: - Accurate Partial Derivatives

    public func derivativeWithRespectToStartX(at progress: CGFloat) -> CGVector {
        let phi = self.angle

        let dx, dy: CGFloat

        if fabs(phi.turns - 0) < 1e-6 { // 0deg
            dx = 1 - progress
            dy = 0
        }
        else if fabs(phi.turns - 0.25) < 1e-6 { // 90deg
            dx = 0.5 + 0.5 * cos(CGAngle.half * progress)
            dy = 0.0 - 0.5 * sin(CGAngle.half * progress)
        }
        else if fabs(phi.turns + 0.25) < 1e-6 { // -90deg
            dx = 0.5 + 0.5 * cos(CGAngle.half * progress)
            dy = 0.0 + 0.5 * sin(CGAngle.half * progress)
        }
        else {
            dx = 0.5
                + 0.5 * cos(2 * progress * phi)
                - 0.5 * sin(2 * progress * phi) / tan(phi)

            dy = 0.5 / tan(phi)
                - 0.5 * sin(2 * progress * phi)
                - 0.5 * cos(2 * progress * phi) / tan(phi)
        }

        return CGVector(dx: dx, dy: dy)
    }

    public func derivativeWithRespectToStartY(at progress: CGFloat) -> CGVector {
        let phi = self.angle

        let dx, dy: CGFloat

        if fabs(phi.turns - 0) < 1e-6 { // 0deg
            dx = 0
            dy = 1 - progress
        }
        else if fabs(phi.turns - 0.25) < 1e-6 { // 90deg
            dx = 0.0 + 0.5 * sin(CGAngle.half * progress)
            dy = 0.5 + 0.5 * cos(CGAngle.half * progress)
        }
        else if fabs(phi.turns + 0.25) < 1e-6 { // -90deg
            dx = 0.0 - 0.5 * sin(CGAngle.half * progress)
            dy = 0.5 + 0.5 * cos(CGAngle.half * progress)
        }
        else {
            dx = -0.5 / tan(phi)
                + 0.5 * cos(2 * progress * phi) / tan(phi)
                + 0.5 * sin(2 * progress * phi)

            dy = 0.5
                - 0.5 * sin(2 * progress * phi) / tan(phi)
                + 0.5 * cos(2 * progress * phi)
        }

        return CGVector(dx: dx, dy: dy)
    }

    public func derivativeWithRespectToEndX(at progress: CGFloat) -> CGVector {
        let phi = self.angle

        let dx, dy: CGFloat

        if fabs(phi.turns - 0) < 1e-6 { // 0deg
            dx = progress
            dy = 0
        }
        else if fabs(phi.turns - 0.25) < 1e-6 { // 90deg
            dx = 0.5 - 0.5 * cos(CGAngle.half * progress)
            dy = 0.0 + 0.5 * sin(CGAngle.half * progress)
        }
        else if fabs(phi.turns + 0.25) < 1e-6 { // -90deg
            dx = 0.5 - 0.5 * cos(CGAngle.half * progress)
            dy = 0.0 - 0.5 * sin(CGAngle.half * progress)
        }
        else {
            dx = 0.5
                - 0.5 * cos(2 * progress * phi)
                + 0.5 * sin(2 * progress * phi) / tan(phi)

            dy = -0.5 / tan(phi)
                + 0.5 * sin(2 * progress * phi)
                + 0.5 * cos(2 * progress * phi) / tan(phi)
        }

        return CGVector(dx: dx, dy: dy)
    }

    public func derivativeWithRespectToEndY(at progress: CGFloat) -> CGVector {
        let phi = self.angle

        let dx, dy: CGFloat

        if fabs(phi.turns - 0) < 1e-6 { // 0deg
            dx = 0
            dy = progress
        }
        else if fabs(phi.turns - 0.25) < 1e-6 { // 90deg
            dx = 0.0 - 0.5 * sin(CGAngle.half * progress)
            dy = 0.5 - 0.5 * cos(CGAngle.half * progress)
        }
        else if fabs(phi.turns + 0.25) < 1e-6 { // -90deg
            dx = 0.0 + 0.5 * sin(CGAngle.half * progress)
            dy = 0.5 - 0.5 * cos(CGAngle.half * progress)
        }
        else {
            dx = 0.5 / tan(phi)
                - 0.5 * cos(2 * progress * phi) / tan(phi)
                - 0.5 * sin(2 * progress * phi)

            dy = 0.5
                + 0.5 * sin(2 * progress * phi) / tan(phi)
                - 0.5 * cos(2 * progress * phi)
        }

        return CGVector(dx: dx, dy: dy)
    }

    public func derivativeWithRespectToAngle(at progress: CGFloat) -> CGVector {
        let (p_x, p_y) = (self.start.x, self.start.y)
        let (q_x, q_y) = (self.end.x, self.end.y)
        let phi = self.angle

        let dx, dy: CGFloat

        if fabs(phi.turns - 0) < 1e-6 { // 0deg
            dx = -progress * (1 - progress) * (q_y - p_y)
            dy = +progress * (1 - progress) * (q_x - p_x)
        }
        else if fabs(phi.turns - 0.25) < 1e-6 { // 90deg
            dx = (0.5 - progress) * (q_y - p_y) * cos(CGAngle.half * progress)
                + (progress - 0.5) * (q_x - p_x) * sin(CGAngle.half * progress)
                - 0.5 * (q_y - p_y)

            dy = (progress - 0.5) * (q_x - p_x) * cos(CGAngle.half * progress)
                + (progress - 0.5) * (q_y - p_y) * sin(CGAngle.half * progress)
                + 0.5 * (q_x - p_x)
        }
        else if fabs(phi.turns + 0.25) < 1e-6 { // -90deg
            dx = (0.5 - progress) * (q_y - p_y) * cos(CGAngle.half * progress)
                + (0.5 - progress) * (q_x - p_x) * sin(CGAngle.half * progress)
                - 0.5 * (q_y - p_y)

            dy = (progress - 0.5) * (q_x - p_x) * cos(CGAngle.half * progress)
                + (0.5 - progress) * (q_y - p_y) * sin(CGAngle.half * progress)
                + 0.5 * (q_x - p_x)
        }
        else {
            dx = 0.0
                - 0.5 * (q_y - p_y) / sin(phi) / sin(phi)
                + progress * (q_x - p_x) * sin(2 * progress * phi)
                + 0.5 * (q_y - p_y) / sin(phi) / sin(phi) * cos(2 * progress * phi)
                + progress * (q_y - p_y) / tan(phi) * sin(2 * progress * phi)
                + progress * (q_x - p_x) / tan(phi) * cos(2 * progress * phi)
                - 0.5 * (q_x - p_x) / sin(phi) / sin(phi) * sin(2 * progress * phi)
                - progress * (q_y - p_y) * cos(2 * progress * phi)

            dy = 0.0
                + 0.5 * (q_x - p_x) / sin(phi) / sin(phi)
                + progress * (q_x - p_x) * cos(2 * progress * phi)
                + progress * (q_y - p_y) / tan(phi) * cos(2 * progress * phi)
                - 0.5 * (q_y - p_y) / sin(phi) / sin(phi) * sin(2 * progress * phi)
                - 0.5 * (q_x - p_x) / sin(phi) / sin(phi) * cos(2 * progress * phi)
                - progress * (q_x - p_x) / tan(phi) * sin(2 * progress * phi)
                + progress * (q_y - p_y) * sin(2 * progress * phi)
        }

        return CGVector(dx: dx, dy: dy)
    }

    public func derivativeWithRespectToProgress(at progress: CGFloat) -> CGVector {
        let (p_x, p_y) = (self.start.x, self.start.y)
        let (q_x, q_y) = (self.end.x, self.end.y)
        let phi = self.angle

        let dx, dy: CGFloat

        if fabs(phi.turns - 0) < 1e-6 { // 0deg
            dx = q_x - p_x
            dy = q_y - p_y
        }
        else if fabs(phi.turns - 0.25) < 1e-6 { // 90deg
            dx = 0.5 * .pi * ((q_x - p_x) * sin(CGAngle.half * progress) - (q_y - p_y) * cos(CGAngle.half * progress))
            dy = 0.5 * .pi * ((q_y - p_y) * sin(CGAngle.half * progress) + (q_x - p_x) * cos(CGAngle.half * progress))
        }
        else if fabs(phi.turns + 0.25) < 1e-6 { // -90deg
            dx = 0.5 * .pi * ((q_x - p_x) * sin(CGAngle.half * progress) + (q_y - p_y) * cos(CGAngle.half * progress))
            dy = 0.5 * .pi * ((q_y - p_y) * sin(CGAngle.half * progress) - (q_x - p_x) * cos(CGAngle.half * progress))
        }
        else {
            dx = 0
                + phi.radians * sin(2 * progress * phi) * ((q_x - p_x) + (q_y - p_y) / tan(phi))
                - phi.radians * cos(2 * progress * phi) * ((q_y - p_y) - (q_x - p_x) / tan(phi))

            dy = 0
                + phi.radians * cos(2 * progress * phi) * ((q_x - p_x) + (q_y - p_y) / tan(phi))
                + phi.radians * sin(2 * progress * phi) * ((q_y - p_y) - (q_x - p_x) / tan(phi))
        }

        return CGVector(dx: dx, dy: dy)
    }



    // MARK: - Approximated Partial Derivatives

    public func derivativeWithRespectToStartX(at progress: CGFloat, delta: CGFloat) -> CGVector {
        return self.approximate(progress, { $0.start.x += delta }, delta)
    }

    public func derivativeWithRespectToStartY(at progress: CGFloat, delta: CGFloat) -> CGVector {
        return self.approximate(progress, { $0.start.y += delta }, delta)
    }

    public func derivativeWithRespectToEndX(at progress: CGFloat, delta: CGFloat) -> CGVector {
        return self.approximate(progress, { $0.end.x += delta }, delta)
    }

    public func derivativeWithRespectToEndY(at progress: CGFloat, delta: CGFloat) -> CGVector {
        return self.approximate(progress, { $0.end.y += delta }, delta)
    }

    public func derivativeWithRespectToAngle(at progress: CGFloat, delta: CGFloat) -> CGVector {
        return self.approximate(progress, { $0.angle += .radians(delta) }, delta)
    }

    public func derivativeWithRespectToProgress(at progress: CGFloat, delta: CGFloat) -> CGVector {
        let a = self.point(for: progress)
        let b = self.point(for: progress + delta)

        return CGVector(from: a, to: b) / delta
    }

    private func approximate(_ progress: CGFloat, _ adjustment: (inout CircularArc) -> Void, _ delta: CGFloat) -> CGVector {
        var arc = self
        let before = arc.point(for: progress)
        adjustment(&arc)
        let after = arc.point(for: progress)

        return CGVector(from: before, to: after) / delta
    }
}
