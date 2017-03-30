import CoreGraphics


/**
 * TODO: Description.
 *
 * - Author: christian.schnorr@me.com
 */
public struct CircularArc {

    /// Constructs a circular arc from between `start` and `end`.
    public init(from start: CGPoint, to end: CGPoint, with angle: CGAngle = .zero) {
        self.start = start
        self.end = end
        self.angle = angle
    }



    // MARK: - Representation

    /// The circular arc's start point.
    public var start: CGPoint

    /// The circular arc's end point.
    public var end: CGPoint

    /// The (signed) angle from the chord connecting the circular arc's
    /// endpoints and the tangent in its start point.
    public var angle: CGAngle {
        didSet {
            guard fabs(self.angle.normalized.degrees) != 180 else {
                preconditionFailure("The circular arc for φ = 180° is undefined.")
            }
        }
    }



    // MARK: - Metrics

    /// The (signed) percendicular distance from the arc's midpoint to the chord
    /// connecting its endpoint.
    public var height: CGFloat {
        let pq = self.start.distance(to: self.end)
        let phi = self.angle

        return 0 + pq / 2 * tan(phi / 2)
    }

    /// The distance between the circular arc's endpoints along the arc.
    public var length: CGFloat {
        let pq = self.start.distance(to: self.end)
        let phi = self.angle

        if phi == .zero {
            return pq
        }
        else {
            return pq * fmax(1, fabs(2 * phi.turns * .pi / sin(phi)))
        }
    }

    /// The (signed) central angle of the circular arc.
    private var theta: CGAngle {
        return -2 * self.angle
    }

    /// The circular arc's center. `nil` if and only if the arc is a straight
    /// line segment.
    private var center: CGPoint? {
        let phi = self.angle

        if phi == .zero || self.start == self.end {
            return nil
        }
        else {
            let factor = 1 / 2 / sin(phi)
            let angle = phi - .degrees(90)

            let op = CGVector(from: .zero, to: self.start)
            let pq = CGVector(from: self.start, to: self.end)
            let om = op + pq.scaled(by: factor).rotated(by: angle)

            return om.pointee
        }
    }



    // MARK: - Drawing

    /// A numeric value \in [0, 1] used for interpolation.
    public typealias Percentage = CGFloat

    /// The Core Graphics representation of the circular arc.
    public var path: CGPath {
        let path = CGMutablePath()

        if let center = self.center {
            let theta = self.theta
            let alpha = CGAngle.slope(from: center, to: self.start)
            let beta = alpha + theta

            let radius = self.start.distance(to: center)
            let clockwise = theta.turns < 0

            path.addArc(center: center, radius: radius, startAngle: alpha.radians, endAngle: beta.radians, clockwise: clockwise)
        }
        else {
            path.move(to: self.start)
            path.addLine(to: self.end)
        }

        return path
    }

    public var svg: String {
        let pq = self.start.distance(to: self.end)
        let radius = pq / 2 / sin(self.angle)
        let major = abs(self.angle).degrees > 90
        let clockwise = self.angle > .zero

        var path = "M\(self.start.x),\(self.start.y)"
        path += "A\(radius),\(radius),0,"
        path += "\(major ? 1 : 0),\(clockwise ? 0 : 1),"
        path += "\(self.end.x),\(self.end.y)"

        return path
    }

    /// The axis-aligned bounding box of the circular arc.
    public var bounds: CGRect {
        return self.path.boundingBoxOfPath
    }

    /// The point splitting the circular arc with a ratio of `progress` to
    /// `1 - progress`.
    public func point(for progress: Percentage) -> CGPoint {
        let progress = min(max(progress, 0), 1)

        if let center = self.center {
            let om = CGVector(from: .zero, to: center)
            let ms = CGVector(from: center, to: self.start)
            let mx = ms.rotated(by: progress * self.theta)
            let ox = om + mx

            return ox.pointee
        }
        else {
            let op = CGVector(to: self.start)
            let pq = CGVector(from: self.start, to: self.end)
            let ox = (op + progress * pq)

            return ox.pointee
        }
    }

    /// The interpolation progress of the point closest to `point` on the
    /// circular arc.
    public func progress(for point: CGPoint) -> Percentage {
        if let center = self.center {
            guard point != center else {
                return 0.5
            }

            let theta = self.theta
            let alpha = CGAngle.slope(from: center, to: self.start) + theta / 2
            let beta = CGAngle.slope(from: center, to: point)

            let progress = 0.5 + (beta - alpha).normalized / theta

            return min(max(progress, 0), 1)
        }
        else {
            // http://stackoverflow.com/a/3122532/
            let ab = CGVector(from: self.start, to: self.end)
            let ap = CGVector(from: self.start, to: point)

            guard ab.length > 0 else {
                return 0.5
            }

            let progress = (ab * ap) / pow(ab.length, 2)

            return min(max(progress, 0), 1)
        }
    }

    /// The point closest to `point` on the circular arc.
    public func distance(to point: CGPoint) -> CGFloat {
        let progress = self.progress(for: point)
        let closest = self.point(for: progress)
        let distance = CGVector(from: point, to: closest).length

        return distance
    }



    // MARK: - Derived Arcs

    /// Returns a circular arc with the same endpoints that intersects `point`.
    public func intersecting(_ point: CGPoint) -> CircularArc? {
        guard point != self.start else {
            return self
        }

        guard point != self.end else {
            return self
        }

        let alpha = CGAngle(from: self.start, by: point, to: self.end)

        guard alpha != .zero else {
            return nil
        }

        var copy = self
        copy.angle = (CGAngle.half - alpha).normalized

        return copy
    }

    /// Returns the reverse circular arc, i.e. with start and end being swapped.
    public func reversed() -> CircularArc {
        return CircularArc(from: self.end, to: self.start, with: -self.angle)
    }
}



// MARK: - Equatable

extension CircularArc: Equatable {
    public static func ==(lhs: CircularArc, rhs: CircularArc) -> Bool {
        return lhs.start == rhs.start && lhs.end == rhs.end && lhs.angle == rhs.angle
    }
}
