//  WHAT: A one-page PDF, the form every logo, badge, placeholder and illustration takes in the catalog: drawn with
//        CoreGraphics in points, y up, kept as vectors at every size (`preserves-vector-representation`).

import CoreGraphics
import Foundation

enum VectorPage {
    static func pdf(width: CGFloat, height: CGFloat, draw: (CGContext) -> Void) -> Data {
        let data = NSMutableData()
        var box = CGRect(x: 0, y: 0, width: width, height: height)
        let consumer = CGDataConsumer(data: data as CFMutableData)!
        let context = CGContext(consumer: consumer, mediaBox: &box, [kCGPDFContextCreator: "AssetsAgent"] as CFDictionary)!
        context.beginPDFPage(nil)
        draw(context)
        context.endPDFPage()
        context.closePDF()
        return data as Data
    }
}
