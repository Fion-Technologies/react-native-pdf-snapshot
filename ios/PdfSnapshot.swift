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

    func generatePage(_ pdfPage: PDFPage, _ scale: CGFloat, _ max: CGFloat, _ output: String, _ page: Int) -> Dictionary<String, Any>? {
        guard let outputPath = getOutputFilePath(output, page), let page = pdfPage.pageRef else {
            return nil
        }

        let bounds = pdfPage.bounds(for: .cropBox)
        
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

            return [
                "uri": outputPath.absoluteString,
                "width": Int(bounds.width),
                "height": Int(bounds.height),
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

        /// Default Ouput Scale
        let scale = config["scale"] as? CGFloat ?? 2.0
        
        /// Default Max Resolution
        let max = config["max"] as? CGFloat ?? 0
        
        if let pageResult = generatePage(pdfPage, scale, max, output, page) {
            resolve(pageResult)
        } else {
            reject("INTERNAL_ERROR", "Cannot write image data", nil)
        }
    }
}
