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
        guard let outputPath = getOutputFilePath(output, page) else {
            return nil
        }
        
        let pageRect = pdfPage.bounds(for: .mediaBox)
        let scale = UIScreen.main.scale
        let scaledSize = CGSize(width: pageRect.size.width * scale, height: pageRect.size.height * scale)
        
        /// Begin a rendering context with the size of the PDF page and the scale of our display to ensure it shows at the ideal resolution.
        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        let image = renderer.image { ctx in
            ctx.cgContext.scaleBy(x: scale, y: scale)
            let destRect = CGRectMake(0, 0, scaledSize.width, scaledSize.height)
            let drawingTransform = pdfPage.pageRef!.getDrawingTransform(.mediaBox, rect: destRect, rotate: 0, preserveAspectRatio: true)
            ctx.cgContext.concatenate(drawingTransform)
            ctx.cgContext.drawPDFPage(pdfPage.pageRef!)
            pdfPage.draw(with: .mediaBox, to: ctx.cgContext)
        }
        
        /// Safeguard to ensure we were able to convert the UIImage into valid JPEG Data (1.0 = no compression).
        guard let data = image.jpegData(compressionQuality: 1.0) else {
            return nil
        }
        
        do {
            try data.write(to: outputPath)

            return [
                "uri": outputPath.absoluteString,
                "width": Int(scaledSize.width),
                "height": Int(scaledSize.height),
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
