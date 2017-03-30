import CoreGraphics


// MARK: - Uncategorized

extension CGPoint {
    public static func centroid(of first: CGPoint, _ others: CGPoint...) -> CGPoint {
        let x = others.reduce(first.x, { $0 + $1.x }) / CGFloat(others.count + 1)
        let y = others.reduce(first.y, { $0 + $1.y }) / CGFloat(others.count + 1)

        return CGPoint(x: x, y: y)
    }

    public func distance(to point: CGPoint) -> CGFloat {
        let dx = point.x - self.x
        let dy = point.y - self.y

        return sqrt(dx * dx + dy * dy)
    }

    public var position: CGVector {
        return CGVector(dx: self.x, dy: self.y)
    }
}
