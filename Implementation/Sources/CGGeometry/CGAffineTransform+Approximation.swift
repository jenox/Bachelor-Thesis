import CoreGraphics
import Accelerate


/**
 * TODO: Description.
 *
 * - Author: christian.schnorr@me.com
 */
extension CGAffineTransform {
    public typealias Rule = (input: CGPoint, output: CGPoint)

    public static func interpolating(_ rule: Rule) -> CGAffineTransform {
        let (p_0, p_1) = rule

        return CGVector(from: p_0, to: p_1).displacement
    }

    public static func interpolating(_ first: Rule, _ second: Rule) -> CGAffineTransform {
        guard first.input != second.input else {
            if first.output == second.output {
                return self.interpolating(first)
            }
            else {
                return .identity
            }
        }

        let (p_0, p_1) = first
        let (q_0, q_1) = second

        let phase_0 = p_0.slope(to: q_0)
        let phase_1 = p_1.slope(to: q_1)
        let phi = phase_1 - phase_0

        let distance_0 = p_0.distance(to: q_0)
        let distance_1 = p_1.distance(to: q_1)
        let scale = distance_1 / distance_0

        let a = scale * cos(phi)
        let b = scale * sin(phi)
        let c = scale * -sin(phi)
        let d = scale * cos(phi)
        let tx = p_1.x - a * p_0.x - c * p_0.y
        let ty = p_1.y - b * p_0.x - d * p_0.y

        return CGAffineTransform(a: a, b: b, c: c, d: d, tx: tx, ty: ty)
    }

    public static func approximating(_ rules: Rule...) -> CGAffineTransform {
        return self.approximating(rules)
    }

    public static func approximating(_ rules: [Rule]) -> CGAffineTransform {
        guard let rules = self.validate(rules) else {
            return .identity
        }

        if rules.isEmpty {
            return .identity
        }
        else if rules.count == 1 {
            return self.interpolating(rules[0])
        }
        else if rules.count == 2 {
            return self.interpolating(rules[0], rules[1])
        }

        typealias Int = __CLPK_integer
        typealias Double = __CLPK_doublereal

        var matrix: [Double] = []
        var vector: [Double] = []

        for (input: p_0, output: p_1) in rules {
            matrix.append(contentsOf: [
                Double(p_0.x), 0, Double(p_0.y), 0, 1, 0,
                0, Double(p_0.x), 0, Double(p_0.y), 0, 1,
            ])

            vector.append(contentsOf: [
                Double(p_1.x),
                Double(p_1.y),
            ])
        }

        var transpose = "T".cString(using: .utf8)!.first!
        var m: Int = 6
        var n: Int = Int(vector.count)
        var nrhs: Int = 1
        var lda: Int = m
        var ldb: Int = n
        var lwork: Int = 6 + max(6, nrhs)
        var work: [Double] = Array(repeating: 0, count: Swift.Int(lwork))
        var info: Int = 0

        // http://www.netlib.org/lapack/double/dgels.f
        dgels_(&transpose, &m, &n, &nrhs, &matrix, &lda, &vector, &ldb, &work, &lwork, &info)

        guard info == 0 else {
            return .identity
        }

        let a = CGFloat(vector[0])
        let b = CGFloat(vector[1])
        let c = CGFloat(vector[2])
        let d = CGFloat(vector[3])
        let tx = CGFloat(vector[4])
        let ty = CGFloat(vector[5])

        return CGAffineTransform(a: a, b: b, c: c, d: d, tx: tx, ty: ty)
    }

    private static func validate(_ rules: [Rule]) -> [Rule]? {
        var unique: [(input: CGPoint, output: CGPoint)] = []

        for rule in rules {
            if let existing = unique.first(where: { $0.0 == rule.input }) {
                if existing.output == rule.output {
                    continue
                }
                else {
                    return nil
                }
            }
            else {
                unique.append((input: rule.input, output: rule.output))
            }
        }

        return unique
    }
}
