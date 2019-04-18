//
//  Extensions.swift
//  RavenWallet
//
//  Created by Samuel Sutch on 1/30/16.
//  Copyright (c) 2018 Ravenwallet Team
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
import Foundation
import Core
import libbz2
import UIKit


public extension String {
    static func buildQueryString(_ options: [String: [String]]?, includeQ: Bool = false) -> String {
        var s = ""
        if let options = options , options.count > 0 {
            s = includeQ ? "?" : ""
            var i = 0
            for (k, vals) in options {
                for v in vals {
                    if i != 0 {
                        s += "&"
                    }
                    i += 1
                    s += "\(k.urlEscapedString)=\(v.urlEscapedString)"
                }
            }
        }
        return s
    }
    
    static var urlQuoteCharacterSet: CharacterSet {
        if let cset = (NSMutableCharacterSet.urlQueryAllowed as NSCharacterSet).mutableCopy() as? NSMutableCharacterSet {
            cset.removeCharacters(in: "?=&")
            return cset as CharacterSet
        }
        return NSMutableCharacterSet.urlQueryAllowed as CharacterSet
    }
    
    func md5() -> String {
        guard let data = self.data(using: .utf8) else {
            assert(false, "couldnt encode string as utf8 data")
            return ""
        }
        
        var result = Data(count: 128/8)
        let resultCount = result.count
        return result.withUnsafeMutableBytes { (resultBytes: UnsafeMutablePointer<CUnsignedChar>) -> String in
            data.withUnsafeBytes { (dataBytes) -> Void in
                MD5(resultBytes, dataBytes, data.count)
            }
            var hash = String()
            for i in 0..<resultCount {
                hash = hash.appendingFormat("%02x", resultBytes[i])
            }
            return hash
        }
    }
    
    func base58DecodedData() -> Data {
        let len = BRBase58Decode(nil, 0, self)
        var data = Data(count: len)
        _ = data.withUnsafeMutableBytes({ BRBase58Decode($0, len, self) })
        return data
    }
    
    var urlEscapedString: String {
        return addingPercentEncoding(withAllowedCharacters: String.urlQuoteCharacterSet) ?? ""
    }
    
    func parseQueryString() -> [String: [String]] {
        var ret = [String: [String]]()
        var strippedString = self
        if String(self[..<self.index(self.startIndex, offsetBy: 1)]) == "?" {
            strippedString = String(self[self.index(self.startIndex, offsetBy: 1)...])
        }
        strippedString = strippedString.replacingOccurrences(of: "+", with: " ")
        strippedString = strippedString.removingPercentEncoding!
        for s in strippedString.components(separatedBy: "&") {
            let kp = s.components(separatedBy: "=")
            if kp.count == 2 {
                if var k = ret[kp[0]] {
                    k.append(kp[1])
                } else {
                    ret[kp[0]] = [kp[1]]
                }
            }
        }
        return ret
    }
    
    var cStr: UnsafePointer<CChar>? {
        return (self as NSString).utf8String
    }
    
    func isValidDouble(maxDecimalPlaces: Int) -> Bool {
        let formatter = NumberFormatter()
        formatter.allowsFloats = true // Default is true, be explicit anyways
        let decimalSeparator = formatter.decimalSeparator ?? "."  // Gets the locale specific decimal separator. If for some reason there is none we assume "." is used as separator.
        if formatter.number(from: self) != nil {
            // Split our string at the decimal separator
            let split = self.components(separatedBy: decimalSeparator)
            // Depending on whether there was a decimalSeparator we may have one
            // or two parts now. If it is two then the second part is the one after
            // the separator, aka the digits we care about.
            // If there was no separator then the user hasn't entered a decimal
            // number yet and we treat the string as empty, succeeding the check
            let digits = split.count == 2 ? split.last ?? "" : ""
            // Finally check if we're <= the allowed digits
            return digits.characters.count <= maxDecimalPlaces    // TODO: Swift 4.0 replace with digits.count, YAY!
        }
        return false // couldn't turn string into a valid number
    }
}

extension UITextField {
    func removeLast() {
        guard let text = text else { return}
        if text.utf8.count > 0 {
            self.text = String(text[..<text.index(text.startIndex, offsetBy: text.utf8.count - 1)])
        }
    }
}

extension UserDefaults {
    var deviceID: String {
        if let s = string(forKey: "BR_DEVICE_ID") {
            return s
        }
        let s = CFUUIDCreateString(nil, CFUUIDCreate(nil)) as String
        setValue(s, forKey: "BR_DEVICE_ID")
        print("new device id \(s)")
        return s
    }
}

let VAR_INT16_HEADER: UInt64 = 0xfd
let VAR_INT32_HEADER: UInt64 = 0xfe
let VAR_INT64_HEADER: UInt64 = 0xff

extension NSMutableData {
    
    func appendVarInt(i: UInt64) {
        if (i < VAR_INT16_HEADER) {
            var payload = UInt8(i)
            append(&payload, length: MemoryLayout<UInt8>.size)
        }
        else if (Int32(i) <= UINT16_MAX) {
            var header = UInt8(VAR_INT16_HEADER)
            var payload = CFSwapInt16HostToLittle(UInt16(i))
            append(&header, length: MemoryLayout<UInt8>.size)
            append(&payload, length: MemoryLayout<UInt16>.size)
        }
        else if (UInt32(i) <= UINT32_MAX) {
            var header = UInt8(VAR_INT32_HEADER)
            var payload = CFSwapInt32HostToLittle(UInt32(i))
            append(&header, length: MemoryLayout<UInt8>.size)
            append(&payload, length: MemoryLayout<UInt32>.size)
        }
        else {
            var header = UInt8(VAR_INT64_HEADER)
            var payload = CFSwapInt64HostToLittle(i)
            append(&header, length: MemoryLayout<UInt8>.size)
            append(&payload, length: MemoryLayout<UInt64>.size)
        }
    }
}

var BZCompressionBufferSize: UInt32 = 1024
var BZDefaultBlockSize: Int32 = 7
var BZDefaultWorkFactor: Int32 = 100

private struct AssociatedKeys {
    static var hexString = "hexString"
}

public extension Data {
    var hexString: String {
        if let string = getCachedHexString() {
            return string
        } else {
            let string = reduce("") {$0 + String(format: "%02x", $1)}
            setHexString(string: string)
            return string
        }
    }
    
    private func setHexString(string: String) {
        objc_setAssociatedObject(self, &AssociatedKeys.hexString, string, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    private func getCachedHexString() -> String? {
        return objc_getAssociatedObject(self, &AssociatedKeys.hexString) as? String
    }
    
    var bzCompressedData: Data? {
        get {
            guard !self.isEmpty else {
                return self
            }
            
            var compressed = Data()
            var stream = bz_stream()
            var mself = self
            var success = true
            mself.withUnsafeMutableBytes { (selfBuff: UnsafeMutablePointer<Int8>) -> Void in
                let outBuff = UnsafeMutablePointer<Int8>.allocate(capacity: Int(BZCompressionBufferSize))
                defer { outBuff.deallocate() }
                
                stream.next_in = selfBuff
                stream.avail_in = UInt32(self.count)
                stream.next_out = outBuff
                stream.avail_out = BZCompressionBufferSize
                
                var bzret = BZ2_bzCompressInit(&stream, BZDefaultBlockSize, 0, BZDefaultWorkFactor)
                guard bzret == BZ_OK else {
                    print("failed compression init")
                    success = false
                    return
                }
                repeat {
                    bzret = BZ2_bzCompress(&stream, stream.avail_in > 0 ? BZ_RUN : BZ_FINISH)
                    guard bzret >= BZ_OK else {
                        print("failed compress")
                        success = false
                        return
                    }
                    let bpp = UnsafeBufferPointer(start: outBuff, count: (Int(BZCompressionBufferSize) - Int(stream.avail_out)))
                    compressed.append(bpp)
                    stream.next_out = outBuff
                    stream.avail_out = BZCompressionBufferSize
                } while bzret != BZ_STREAM_END
            }
            BZ2_bzCompressEnd(&stream)
            guard success else { return nil }
            return compressed
        }
    }
    
    init?(bzCompressedData data: Data) {
        guard !data.isEmpty else {
            return nil
        }
        var stream = bz_stream()
        var decompressed = Data()
        var myDat = data
        var success = true
        myDat.withUnsafeMutableBytes { (datBuff: UnsafeMutablePointer<Int8>) -> Void in
            let outBuff = UnsafeMutablePointer<Int8>.allocate(capacity: Int(BZCompressionBufferSize))
            defer { outBuff.deallocate() }
            
            stream.next_in = datBuff
            stream.avail_in = UInt32(data.count)
            stream.next_out = outBuff
            stream.avail_out = BZCompressionBufferSize
            
            var bzret = BZ2_bzDecompressInit(&stream, 0, 0)
            guard bzret == BZ_OK else {
                print("failed decompress init")
                success = false
                return
            }
            repeat {
                bzret = BZ2_bzDecompress(&stream)
                guard bzret >= BZ_OK else {
                    print("failed decompress")
                    success = false
                    return
                }
                let bpp = UnsafeBufferPointer(start: outBuff, count: (Int(BZCompressionBufferSize) - Int(stream.avail_out)))
                decompressed.append(bpp)
                stream.next_out = outBuff
                stream.avail_out = BZCompressionBufferSize
            } while bzret != BZ_STREAM_END
        }
        BZ2_bzDecompressEnd(&stream)
        guard success else { return nil }
        self.init(decompressed)
    }
    
    var base58: String {
        return self.withUnsafeBytes { (selfBytes: UnsafePointer<UInt8>) -> String in
            let len = BRBase58Encode(nil, 0, selfBytes, self.count)
            var data = Data(count: len)
            return data.withUnsafeMutableBytes { (b: UnsafeMutablePointer<Int8>) in
                BRBase58Encode(b, len, selfBytes, self.count)
                return String(cString: b)
            }
        }
    }
    
    var sha1: Data {
        var data = Data(count: 20)
        data.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) in
            self.withUnsafeBytes({ (selfBytes: UnsafePointer<UInt8>) in
                SHA1(bytes, selfBytes, self.count)
            })
        }
        return data
    }
    
    var sha256: Data {
        var data = Data(count: 32)
        data.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) in
            self.withUnsafeBytes({ (selfBytes: UnsafePointer<UInt8>) in
                SHA256(bytes, selfBytes, self.count)
            })
        }
        return data
    }
    
    var sha256_2: Data {
        return self.sha256.sha256
    }
    
    var uInt256: UInt256 {
        return self.withUnsafeBytes { (ptr: UnsafePointer<UInt256>) -> UInt256 in
            return ptr.pointee
        }
    }
    
    public func uInt8(atOffset offset: UInt) -> UInt8 {
        let offt = Int(offset)
        let size = MemoryLayout<UInt8>.size
        if self.count < offt + size { return 0 }
        return self.subdata(in: offt..<(offt+size)).withUnsafeBytes { (ptr: UnsafePointer<UInt8>) -> UInt8 in
            return ptr.pointee
        }
    }
    
    public func uInt32(atOffset offset: UInt) -> UInt32 {
        let offt = Int(offset)
        let size = MemoryLayout<UInt32>.size
        if self.count < offt + size { return 0 }
        return self.subdata(in: offt..<(offt+size)).withUnsafeBytes { (ptr: UnsafePointer<UInt32>) -> UInt32 in
            return CFSwapInt32LittleToHost(ptr.pointee)
        }
    }
    
    public func uInt64(atOffset offset: UInt) -> UInt64 {
        let offt = Int(offset)
        let size = MemoryLayout<UInt64>.size
        if self.count < offt + size { return 0 }
        return self.subdata(in: offt..<(offt+size)).withUnsafeBytes { (ptr: UnsafePointer<UInt64>) -> UInt64 in
            return CFSwapInt64LittleToHost(ptr.pointee)
        }
    }
    
    public func compactSign(key: BRKey) -> Data {
        return self.withUnsafeBytes({ (selfBytes: UnsafePointer<UInt8>) -> Data in
            var data = Data(count: 65)
            var k = key
            _ = data.withUnsafeMutableBytes({ BRKeyCompactSign(&k, $0, 65, self.uInt256) })
            return data
        })
    }
    
    fileprivate func genNonce() -> [UInt8] {
        var tv = timeval()
        gettimeofday(&tv, nil)
        var t = UInt64(tv.tv_usec) * 1_000_000 + UInt64(tv.tv_usec)
        let p = [UInt8](repeating: 0, count: 4)
        return Data(bytes: &t, count: MemoryLayout<UInt64>.size).withUnsafeBytes { (dat: UnsafePointer<UInt8>) -> [UInt8] in
            let buf = UnsafeBufferPointer(start: dat, count: MemoryLayout<UInt64>.size)
            return p + Array(buf)
        }
    }
    
    public func chacha20Poly1305AEADEncrypt(key: BRKey) -> Data {
        let data = [UInt8](self)
        let inData = UnsafePointer<UInt8>(data)
        let nonce = genNonce()
        var null =  CChar(0)
        var sk = key.secret
        return withUnsafePointer(to: &sk) {
            let outSize = Chacha20Poly1305AEADEncrypt(nil, 0, $0, nonce, inData, data.count, &null, 0)
            var outData = [UInt8](repeating: 0, count: outSize)
            Chacha20Poly1305AEADEncrypt(&outData, outSize, $0, nonce, inData, data.count, &null, 0)
            return Data(nonce + outData)
        }
    }
    
    var masterPubKey: BRMasterPubKey? {
        guard self.count >= (4 + 32 + 33) else { return nil }
        var mpk = BRMasterPubKey()
        mpk.fingerPrint = self.subdata(in: 0..<4).withUnsafeBytes { $0.pointee }
        mpk.chainCode = self.subdata(in: 4..<(4 + 32)).withUnsafeBytes { $0.pointee }
        mpk.pubKey = self.subdata(in: (4 + 32)..<(4 + 32 + 33)).withUnsafeBytes { $0.pointee }
        return mpk
    }
    
    init(masterPubKey mpk: BRMasterPubKey) {
        var data = [mpk.fingerPrint].withUnsafeBufferPointer { Data(buffer: $0) }
        [mpk.chainCode].withUnsafeBufferPointer { data.append($0) }
        [mpk.pubKey].withUnsafeBufferPointer { data.append($0) }
        self.init(data)
    }
    
    var urlEncodedObject: [String: [String]]? {
        guard let str = String(data: self, encoding: .utf8) else {
            return nil
        }
        return str.parseQueryString()
    }
}

public extension Date {
    static func withMsTimestamp(_ ms: UInt64) -> Date {
        return Date(timeIntervalSince1970: Double(ms) / 1000.0)
    }
    
    func msTimestamp() -> UInt64 {
        return UInt64((self.timeIntervalSince1970 < 0 ? 0 : self.timeIntervalSince1970) * 1000.0)
    }
    
    // this is lifted from: https://github.com/Fykec/NSDate-RFC1123/blob/master/NSDate%2BRFC1123.swift
    // Copyright © 2015 Foster Yin. All rights reserved.
    fileprivate static func cachedThreadLocalObjectWithKey<T: AnyObject>(_ key: String, create: () -> T) -> T {
        let threadDictionary = Thread.current.threadDictionary
        if let cachedObject = threadDictionary[key] as! T? {
            return cachedObject
        }
        else {
            let newObject = create()
            threadDictionary[key] = newObject
            return newObject
        }
    }
    
    fileprivate static func RFC1123DateFormatter() -> DateFormatter {
        return cachedThreadLocalObjectWithKey("RFC1123DateFormatter") {
            let locale = Locale(identifier: "en_US")
            let timeZone = TimeZone(identifier: "GMT")
            let dateFormatter = DateFormatter()
            dateFormatter.locale = locale //need locale for some iOS 9 verision, will not select correct default locale
            dateFormatter.timeZone = timeZone
            dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
            return dateFormatter
        }
    }
    
    fileprivate static func RFC850DateFormatter() -> DateFormatter {
        return cachedThreadLocalObjectWithKey("RFC850DateFormatter") {
            let locale = Locale(identifier: "en_US")
            let timeZone = TimeZone(identifier: "GMT")
            let dateFormatter = DateFormatter()
            dateFormatter.locale = locale //need locale for some iOS 9 verision, will not select correct default locale
            dateFormatter.timeZone = timeZone
            dateFormatter.dateFormat = "EEEE, dd-MMM-yy HH:mm:ss z"
            return dateFormatter
        }
    }
    
    fileprivate static func asctimeDateFormatter() -> DateFormatter {
        return cachedThreadLocalObjectWithKey("asctimeDateFormatter") {
            let locale = Locale(identifier: "en_US")
            let timeZone = TimeZone(identifier: "GMT")
            let dateFormatter = DateFormatter()
            dateFormatter.locale = locale //need locale for some iOS 9 verision, will not select correct default locale
            dateFormatter.timeZone = timeZone
            dateFormatter.dateFormat = "EEE MMM d HH:mm:ss yyyy"
            return dateFormatter
        }
    }
    
    static func fromRFC1123(_ dateString: String) -> Date? {
        
        var date: Date?
        // RFC1123
        date = Date.RFC1123DateFormatter().date(from: dateString)
        if date != nil {
            return date
        }
        
        // RFC850
        date = Date.RFC850DateFormatter().date(from: dateString)
        if date != nil {
            return date
        }
        
        // asctime-date
        date = Date.asctimeDateFormatter().date(from: dateString)
        if date != nil {
            return date
        }
        return nil
    }
    
    func RFC1123String() -> String? {
        return Date.RFC1123DateFormatter().string(from: self)
    }
}

public extension BRKey {
    public var publicKey: Data {
        var k = self
        let len = BRKeyPubKey(&k, nil, 0)
        var data = Data(count: len)
        BRKeyPubKey(&k, data.withUnsafeMutableBytes({ (d: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> in d }), len)
        return data
    }
}

extension UIImage {
    
    /// Represents a scaling mode
    enum ScalingMode {
        case aspectFill
        case aspectFit
        
        /// Calculates the aspect ratio between two sizes
        ///
        /// - parameters:
        ///     - size:      the first size used to calculate the ratio
        ///     - otherSize: the second size used to calculate the ratio
        ///
        /// - return: the aspect ratio between the two sizes
        func aspectRatio(between size: CGSize, and otherSize: CGSize) -> CGFloat {
            let aspectWidth  = size.width/otherSize.width
            let aspectHeight = size.height/otherSize.height
            
            switch self {
            case .aspectFill:
                return max(aspectWidth, aspectHeight)
            case .aspectFit:
                return min(aspectWidth, aspectHeight)
            }
        }
    }
    
    /// Scales an image to fit within a bounds with a size governed by the passed size. Also keeps the aspect ratio.
    ///
    /// - parameters:
    ///     - newSize:     the size of the bounds the image must fit within.
    ///     - scalingMode: the desired scaling mode
    ///
    /// - returns: a new scaled image.
    func scaled(to newSize: CGSize, scalingMode: UIImage.ScalingMode = .aspectFill) -> UIImage {
        
        let aspectRatio = scalingMode.aspectRatio(between: newSize, and: size)
        
        /* Build the rectangle representing the area to be drawn */
        var scaledImageRect = CGRect.zero
        
        scaledImageRect.size.width  = size.width * aspectRatio
        scaledImageRect.size.height = size.height * aspectRatio
        scaledImageRect.origin.x    = (newSize.width - size.width * aspectRatio) / 2.0
        scaledImageRect.origin.y    = (newSize.height - size.height * aspectRatio) / 2.0
        
        /* Draw and retrieve the scaled image */
        UIGraphicsBeginImageContext(newSize)
        
        draw(in: scaledImageRect)
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
}

extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {
    var flattened: [Key: String] {
        var ret = [Key: String]()
        for (k, v) in self {
            if let v = v as? [String] {
                if v.count > 0 {
                    ret[k] = v[0]
                }
            }
        }
        return ret
    }
    
    var jsonString: String {
        guard let json = try? JSONSerialization.data(withJSONObject: self, options: []) else {
            return "null"
        }
        guard let jstring = String(data: json, encoding: .utf8) else {
            return "null"
        }
        return jstring
    }
}

extension UIView {
    
    // go thru this view's subviews and look for the current first responder
    func findFirstResponder() -> UIResponder? {
        // if self is the first responder, return it
        // (this is from the recursion below)
        if isFirstResponder {
            return self
        }
        
        let tt = subviews
        for v in subviews {
            if v.isFirstResponder == true {
                return v
            }
            if let fr = v.findFirstResponder() { // recursive
                return fr
            }
        }
        
        // no first responder
        return nil
    }
}

var tbKeyboard : UIToolbar?
var tfLast : UITextField?
var textFieldsList: [UITextField]?

extension UIViewController : UITextFieldDelegate {
    
    // make the first UITextField (tag=0) the first responder
    // if no view is passed in, start w/ the self.view
    func firstTFBecomeFirstResponder(view : UIView? = nil) {
        for v in view?.subviews ?? self.view.subviews {
            if v is UITextField, v.tag == 0 {
                (v as! UITextField).becomeFirstResponder()
            }
            else if v.subviews.count > 0 { // recursive
                firstTFBecomeFirstResponder(view: v)
            }
        }
    }
    
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // set the tool bar as this text field's input accessory view
        textField.inputAccessoryView = tbKeyboard
        return true
    }
    
    func makeKeyBoardToolBar() {
        if tbKeyboard == nil {
            // if there's no tool bar, create it
            tbKeyboard = UIToolbar.init(frame: CGRect.init(x: 0, y: 0,
                                                           width: self.view.frame.size.width, height: 44))
            let bbiPrev = UIBarButtonItem.init(title: "<",
                                               style: .plain, target: self, action: #selector(doBtnPrev))
            let bbiNext = UIBarButtonItem.init(title: ">", style: .plain,
                                               target: self, action: #selector(doBtnNext))
            let bbiSpacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                            target: nil, action: nil)
            let bbiSubmit = UIBarButtonItem.init(title: "Done", style: .plain,
                                                 target: self, action: #selector(doBtnSubmit))
            tbKeyboard?.items = [bbiPrev, bbiNext, bbiSpacer, bbiSubmit]
        }
        //init textfields Tag
        textFieldsList = []
        initTextFieldTag(inViewsSubviewsOf: self.view/*, fromTag: 0*/)
        var tag:Int = 0
        for textField in textFieldsList! {
            textField.tag = tag
            tag = tag + 1
        }
    }
    
    func initTextFieldTag(inViewsSubviewsOf view : UIView? = nil/*, fromTag:Int*/) {
        //var tag:Int = fromTag
        for v in view?.subviews ?? self.view.subviews {
            
            // found a match? return it
            if v is UITextField {
                textFieldsList?.append(v as! UITextField)
                //v.tag = tag
                //tag = tag + 1
            }
            else if v.subviews.count > 0 { // recursive
                initTextFieldTag(inViewsSubviewsOf: v/*, fromTag: tag*/)
            }
        }
    }
    
    // search view's subviews
    // if no view is passed in, start w/ the self.view
    func findTextField(withTag tag : Int,
                       inViewsSubviewsOf view : UIView? = nil, next : Bool) -> UITextField? {
        var i:Int = 0
        var newTag = tag
        while i < (textFieldsList?.count)! {
            let textField = next ? textFieldsList![i] : textFieldsList!.reversed()[i]
            if textField.tag == newTag {
                let superView = textField.superview
                if !textField.isHidden && (superView?.frame.size.height)! > CGFloat(0) {
                    return textField
                }
                else {
                    newTag = tag + (next ? 1 : -1)
                }
            }
            i = i + 1
        }

//        for v in view?.subviews ?? self.view.subviews {
//
//            // found a match? return it
//            if v is UITextField, v.tag == tag, !v.isHidden {
//                return (v as! UITextField)
//            }
//            else if v.subviews.count > 0 { // recursive
//                if let tf = findTextField(withTag: tag, inViewsSubviewsOf: v) {
//                    return tf
//                }
//            }
//        }
        return nil // not found
    }
    
    func findFirstResponder() -> UITextField?{
        for textField in textFieldsList! {
            if textField.isFirstResponder {
                return textField
            }
        }
        return nil
    }
    
    // make the next (or previous if next=false) text field the first responder
    func makeTFFirstResponder(next : Bool) -> Bool {
        
        // find the current first responder (text field)
        if let fr = self.findFirstResponder() as? UITextField {
            
            // find the next (or previous) text field based on the tag
            if let tf = findTextField(withTag: fr.tag + (next ? 1 : -1), next: next) {
                tf.becomeFirstResponder()
                return true
            }
        }
        return false
    }
    
    @objc func doBtnPrev(_ sender: Any) {
        let _ = makeTFFirstResponder(next: false)
    }
    
    @objc func doBtnNext(_ sender: Any) {
        guard makeTFFirstResponder(next: true) else {
            doBtnSubmit(tbKeyboard?.items?.first as Any)
            return
        }
    }
    
    @objc func doBtnSubmit(_ sender: Any) {
        submitForm()
    }
    
    @objc func submitForm() {
        self.view.endEditing(true)
        for textField in textFieldsList! {
            textField.resignFirstResponder()
        }
        // override me
    }
}
