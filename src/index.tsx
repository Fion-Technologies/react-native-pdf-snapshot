import { NativeModules } from 'react-native';

export type SnapshotResult = {
  /// Output URI of the snapshot, located in the Documents directory using the filename given in the generate options, randomly generated.
  uri: string;

  /// Output width of the JPEG
  width: number;

  /// Output height of the JPEG
  height: number;
};

export type SnapshotOptions = {
  /// File path or URL to the PDF image
  url: string;

  /// Optional: output image scale, default to 2x
  scale?: number;

  /// Optional: page number to snapshot. Default to 0
  page?: number;

  /// Optional: output file path. Defaults to Documents directory with the filename "fion-geopdf-<page_number>-<random_number>"
  output?: string;
};

type PdfSnapshotType = {
  generate(options: SnapshotOptions): Promise<SnapshotResult>;
};

const { PdfSnapshot } = NativeModules;

export default PdfSnapshot as PdfSnapshotType;
