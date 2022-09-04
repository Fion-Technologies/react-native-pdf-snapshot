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

    func generatePage(_ pdfPage: PDFPage, _ output: String, _ page: Int, _ dpi: Double) -> Dictionary<String, Any>? {
        /// Define destination path for the final JPEG image relative to the Documents directory.
        guard let outputPath = getOutputFilePath(output, page) else {
            return nil
        }
        
        /// Bounds for capturing the JPEG image, in this case, the entire bounds of the media of the PDF page.
        let pageRect = pdfPage.bounds(for: .mediaBox)
        
        /// Use 144 pixels per inch DPI instead of the default 72
        let scale = dpi / 72.0
        let scaledSize = CGSize(width: pageRect.size.width * scale, height: pageRect.size.height * scale)
        
        /// Begin a rendering context with the size of the PDF page and the scale of our display to ensure it shows at the ideal resolution.
        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        let image = renderer.image { ctx in
            /// Align the PDF based on the default CGContext origin placement (move to top-left instead of starting off on center point).
             ctx.cgContext.translateBy(x: 0, y: pageRect.size.height * scale)
            
            /// Flip the context as CGContext begin counting from bottom instead of top.
            ctx.cgContext.scaleBy(x: scale, y: -scale)
            
            /// Draw the full media box of the PDF page at full resolution onto the current CGContext.
            pdfPage.draw(with: .mediaBox, to: ctx.cgContext)
        }
        
        /// Safeguard to ensure we were able to convert the UIImage into valid JPEG Data (1.0 = no compression).
        guard let data = image.jpegData(compressionQuality: 1.0) else {
            return nil
        }
        
        do {
            /// Write high resolution JPEG data to outputFile path, the image size should match the pageRect.
            try data.write(to: outputPath)

            /// Output dimensions of the final image and the local Image URI we generated using the Documents directory and outputFilePath
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
        
        /// Default DPI
        let dpi = config["dpi"] as? Double ?? 72.0
        
        /// Default Output Filename
        let output = config["output"] as? String ?? ""

        if let pageResult = generatePage(pdfPage, output, page, dpi) {
            resolve(pageResult)
        } else {
            reject("INTERNAL_ERROR", "Cannot write image data", nil)
        }
    }
}
