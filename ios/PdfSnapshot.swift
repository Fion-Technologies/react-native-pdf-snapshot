import PDFKit

@objc(PdfSnapshot)
class PdfSnapshot: NSObject {

  @objc
  static func requiresMainQueueSetup() -> Bool {
    return false
  }
  
  func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
  }
  
  func getOutputFilePath(_ outputFileName: String, _ page: Int) -> URL? {
    let trimmedOutputFilename = outputFileName.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    
    var filename: URL
    if trimmedOutputFilename.count == 0 {
      let randomFilename = "fion-geopdf-\(page)-\(Int.random(in: 0 ..< Int.max)).jpg"
      filename = getDocumentsDirectory().appendingPathComponent(randomFilename)
    } else {
      guard let validOutputFilename = URL(string: trimmedOutputFilename) else {
        return nil
      }
        
      filename = validOutputFilename
    }
    
    if filename.pathExtension.count == 0 {
      filename = filename.appendingPathExtension("jpg")
    }
    
    if !filename.isFileURL {
      filename = URL(fileURLWithPath: filename.absoluteString)
    }

    return filename
  }

  func getSubstring(_ string: String, _ startIndex: Int, _ endIndex: Int) -> String {
    let start = string.index(string.startIndex, offsetBy: startIndex)
    let end = string.index(string.startIndex, offsetBy: endIndex)
    return String(string[start...end])
  }

  func generatePage(
    _ pdfPage: PDFPage,
    _ scale: CGFloat,
    _ max: CGFloat,
    _ disableSplit: Bool,
    _ output: String,
    _ page: Int
  ) -> Array<Dictionary<String, Any>>? {
      
    guard let outputPath = getOutputFilePath(output, page) else {
        return nil
    }

    let bounds = pdfPage.bounds(for: .cropBox)
    
    if disableSplit == true || max <= 0 {
      // passthrough to legacy mechanic of not splitting PDF into JPEG parts
      var validScale = scale
      if max > 0 {
        let maxScale = min(max / bounds.width, max / bounds.height)
        validScale = min(scale, maxScale)
      }
      
      let thumbnail = pdfPage.thumbnail(of: bounds.applying(.init(scaleX: validScale, y: validScale)).size, for: .mediaBox)
      guard let data = thumbnail.jpegData(compressionQuality: 1.0) else {
        return nil
      }
      
      do {
          try data.write(to: outputPath)

          let result = [[
            "uri": outputPath.absoluteString,
            "width": "\(bounds.width)",
            "height": "\(bounds.height)",
          ]]

          return result
      } catch {
          return nil
      }
    }

    // split pdf into jpeg elements based on target scale
    let thumbnail = pdfPage.thumbnail(of: bounds.applying(.init(scaleX: scale, y: scale)).size, for: .mediaBox)

    // calc 1st rect manually
    let splitAmountWidth = ceil((bounds.width * scale) / max)
    let splitAmountHeight = ceil((bounds.height * scale) / max)

    if (splitAmountHeight <= 1 && splitAmountWidth <= 1) {
      // no splits required
      return generatePage(pdfPage, scale, max, true, output, page)
    }
    
    let splitRectWidth = (bounds.width * scale) / splitAmountWidth
    let splitRectHeight = (bounds.height * scale) / splitAmountHeight

    var splitRects: Array<CGRect> = [] // [CGRect(x: 0, y: 0, width: splitRectWidth, height: splitRectHeight)]
    for x in 0..<Int(splitAmountWidth) {
      for y in 0..<Int(splitAmountHeight) {
        let rect = CGRect(x: CGFloat(x) * splitRectWidth, y: CGFloat(y) * splitRectHeight, width: splitRectWidth, height: splitRectHeight)
        splitRects.append(rect)
      }
    }

    // snapshot the rects in the scaled JPEG
    var results: Array<Dictionary<String, Any>> = []
    for (index, splitRect) in splitRects.enumerated() {
      guard let splitImage = thumbnail.croppedImage(inRect: splitRect) else {
        continue
      }
      
      guard let splitImageData = splitImage.jpegData(compressionQuality: 1.0) else {
        continue
      }
      
      let outputPathString = getSubstring(outputPath.absoluteString, 0, outputPath.absoluteString.count - 5)
      guard let splitImagePath = URL(string: "\(outputPathString)-split-\(index).jpg") else {
        continue
      }
      
      do {
        try splitImageData.write(to: splitImagePath)
        
        let result: Dictionary<String, Any> = [
          "uri": splitImagePath.absoluteString,
          "x": "\(splitRect.origin.x)",
          "y": "\(splitRect.origin.y)",
          "width": "\(splitRect.width)",
          "height": "\(splitRect.height)",
        ]
        
        results.append(result)
      } catch {
        continue
      }
    }
    
    return results
    
  }
  
  @available(iOS 11.0, *)
  @objc(generate:withResolver:withRejecter:)
  func generate(options: NSDictionary, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) -> Void {
    guard let config = options as? [String: Any] else {
      reject("OPTIONS_NOT_FOUND", "Valid JSON options need to be given to generate()", nil)
      return
    }
    
    guard let url = config["url"] as? String  else {
      reject("OPTIONS_MISSING_URL", "URL not found in config", nil)
      return
    }
    
    guard let fileUrl = URL(string: url) else {
      reject("FILE_NOT_FOUND", "File \(url) not found", nil)
      return
    }
    
    guard let pdfDocument = PDFDocument(url: fileUrl) else {
      reject("FILE_NOT_FOUND", "File \(url) not found", nil)
      return
    }
    
    /// Default Page Number
    let page = config["page"] as? Int ?? 0
    
    guard let pdfPage = pdfDocument.page(at: page) else {
      reject("INVALID_PAGE", "Page number \(page) is invalid, file has \(pdfDocument.pageCount) pages", nil)
      return
    }
    
    /// Default Output Filename
    let output = config["output"] as? String ?? ""

    /// Default Ouput Scale
    let scale = config["scale"] as? CGFloat ?? 2.0
    
    /// Default Max Resolution
    let max = config["max"] as? CGFloat ?? 0

    /// Default Split Flag
    let disableSplit = config["disableSplit"] as? Bool ?? false
    
    if let pageResult = generatePage(pdfPage, scale, max, disableSplit, output, page) {
      resolve(pageResult)
    } else {
      reject("INTERNAL_ERROR", "Cannot write image data", nil)
    }
  }
}

public extension UIImage {
  
  /// https://stackoverflow.com/a/48110726
  func croppedImage(inRect rect: CGRect) -> UIImage? {
    let rad: (Double) -> CGFloat = { deg in
      return CGFloat(deg / 180.0 * .pi)
    }
    var rectTransform: CGAffineTransform
    switch imageOrientation {
    case .left:
        let rotation = CGAffineTransform(rotationAngle: rad(90))
        rectTransform = rotation.translatedBy(x: 0, y: -size.height)
    case .right:
        let rotation = CGAffineTransform(rotationAngle: rad(-90))
        rectTransform = rotation.translatedBy(x: -size.width, y: 0)
    case .down:
        let rotation = CGAffineTransform(rotationAngle: rad(-180))
        rectTransform = rotation.translatedBy(x: -size.width, y: -size.height)
    default:
        rectTransform = .identity
    }
    rectTransform = rectTransform.scaledBy(x: scale, y: scale)
    let transformedRect = rect.applying(rectTransform)
    guard let imageRef = cgImage?.cropping(to: transformedRect) else {
      return nil
    }
    
    let result = UIImage(cgImage: imageRef, scale: scale, orientation: imageOrientation)
    return result
  }
  
}
