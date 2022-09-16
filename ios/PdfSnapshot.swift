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

    func generatePage(_ pdfPage: PDFPage, _ output: String, _ page: Int) -> Dictionary<String, Any>? {
        guard let outputPath = getOutputFilePath(output, page), let page = pdfPage.pageRef else {
            return nil
        }
//
//        guard  let url = pdfPage.document?.documentURL, let cfUrl = CFURLCreateWithString(kCFAllocatorDefault, url.absoluteString as CFString, nil) else {
//            return nil
//        }
//
        var mediaBox = page.getBoxRect(.mediaBox)
        let renderer = UIGraphicsImageRenderer(size: mediaBox.size)
        let data = renderer.jpegData(withCompressionQuality: 1.0, actions: { context in
            let writeContext = context.cgContext
            // let writeContext: CGContext = CGContext(cfUrl, mediaBox: nil, nil)!
            writeContext.beginPage(mediaBox: &mediaBox)
            let m = page.getDrawingTransform(.mediaBox, rect: mediaBox, rotate: 0, preserveAspectRatio: true)
            writeContext.translateBy(x: 0.0, y: mediaBox.size.height)
            writeContext.scaleBy(x: 1, y: -1)
            writeContext.concatenate(m)
            writeContext.drawPDFPage(page)
            writeContext.endPage()
            writeContext.closePDF()
        })
        
//        guard let cgImage = contextImage else {
//            return nil
//        }
//        let image = UIImage(cgImage: cgImage)
//        guard let data = image.jpegData(compressionQuality: 1.0) else {
//            return nil
//        }
        
        do {
            try data.write(to: outputPath)

            return [
                "uri": outputPath.absoluteString,
                "width": Int(mediaBox.width),
                "height": Int(mediaBox.height),
            ]
        } catch {
            return nil
        }
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

        if let pageResult = generatePage(pdfPage, output, page) {
            resolve(pageResult)
        } else {
            reject("INTERNAL_ERROR", "Cannot write image data", nil)
        }
    }
}
