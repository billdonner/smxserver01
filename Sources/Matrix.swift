///  provenance - SocialMaxx Server
///  builds on DEVELOPMENT-SNAPSHOT-2016-05-03-a on OS X 10.11.4  Xcode Version 7.3.1 (7D1014)
///  26 May 2016
///

//  moved to Kitura on 5/4/16 swift 3
//
//  Matrix
//  SocialMaxx
//
//  Created by bill donner on 1/16/16.
//  Copyright © 2016 SocialMax. All rights reserved.
//

import Foundation

// hacked from the apple book - matrix is a simple linear array
struct Matrix {
    let rows: Int, columns: Int
    var grid: [Double]
    init(rows: Int=7, columns: Int=24) {
        self.rows = rows
        self.columns = columns
        grid = Array(repeating: 0.0,count: rows * columns)
    }
    func indexIsValidForRow(_ row: Int, column: Int) -> Bool {
        return row >= 0 && row < rows && column >= 0 && column < columns
    }
    subscript(row: Int, column: Int) -> Double {
        get {
            assert(indexIsValidForRow(row, column: column), "Index out of range")
            return grid[(row * columns) + column]
        }
        set {
            assert(indexIsValidForRow(row, column: column), "Index out of range")
            grid[(row * columns) + column] = newValue
        }
    }
    
}

struct AlphaMatrix { // a matrix that has normalized all values 0..1 to be useful as alpha values for rgb
    
    var matrix : Matrix
    var maxv:Double
    var gs : Double
    // round these numbers to reasonable size
    func  forRGB() -> [[String]] {
        var res:[[String]] = []
        for row in 0..<matrix.rows {
            var newrow : [String] = []
            for col in 0..<matrix.columns {
                let v = matrix[row,col]
                newrow.append(String(format:"%.3f",v))
            }
            res.append(newrow) // add new row
        }
        return res
    }
    init(m:Matrix) {
        func computeAlphas(_ m:Matrix)->(Matrix,Double,Double) {
            var res = Matrix(rows:m.rows,columns:m.columns)
            var maxval = 0.0
            var grandsum  = 0.0
            
            func translateToAlphasByScaling(_ a:Double) -> Double {
                return Double(a/maxval)
            }
            // frist figure grandsum and max
            let _ = m.grid.map {
                let v = $0
                grandsum += v
                if v > maxval {
                    maxval = v }
            }
            
            for row in 0..<m.rows {
                for col in 0..<m.columns {
                    let v = m[row,col]
                    res[row,col] = translateToAlphasByScaling(v)
                }
            }
            return (res,grandsum,maxval)
        }
        let (a,b,c) = computeAlphas(m)
        self.maxv = c
        self.gs = b
        self.matrix = a
    }
}


