import { NativeModules } from 'react-native'

export type SnapshotResult = {
  /// Total output width
  width: string

  /// Total output height
  height: string
  
  /// All output images
  images: SnapshotImage[] 
}

export type SnapshotImage = {
  /// Output URI of the snapshot, located in the Documents directory using the filename given in the generate options, randomly generated.
  uri: string

  /// Output width of the JPEG
  width: string

  /// Output height of the JPEG
  height: string
}

export type SnapshotOptions = {
  /// File path or URL to the PDF image
  url: string

  /// Optional: output image scale, defaults to 2x
  scale?: number

  /// Optional: output max image resolution, defaults to 0
  max?: number

  /// Optional: page number to snapshot, defaults to 0
  page?: number

  /// Optional: output file path, defaults to Documents directory
  outputPath?: string

  /// Optional: output file name, defaults to "fion-geopdf-<page_number>-split-<split_number>"
  outputFilename?: string

  /// Optional: disables the split mechanic, limiting the return value to only 1 result JPEG
  disableSplit?: boolean
}

type PdfSnapshotType = {
  generate(options: SnapshotOptions): Promise<SnapshotResult>
}

const { PdfSnapshot } = NativeModules

export default PdfSnapshot as PdfSnapshotType
