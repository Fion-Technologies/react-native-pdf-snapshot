# react-native-pdf-snapshot

React Native module for generating high resolution snapshots of PDF files. iOS only.

Originally forked from [react-native-pdf-thumbnail](https://github.com/songsterq/react-native-pdf-thumbnail).

A wrapper for:
- PDFKit on iOS (requires iOS 11+)

In the future:
- PdfRenderer on Android (requires API level 21 - LOLLIPOP)

No other JavaScript or native dependencies needed.

## Installation

```sh
npm install react-native-pdf-snapshot
```

## Usage

```js
import PdfSnapshot from "react-native-pdf-snapshot"

const options = {
  /// URL of the PDF
  url: 'file:///mnt/sdcard/myDocument.pdf',

  /// Optional: output image scale, default to 2x
  scale: 2,

  /// Optional: output max image resolution, defaults to 0
  max: 4096,

  /// Optional: PDF page to snapshot, defaults to 0
  page: 0,

  /// Optional: Local path of output JPEG, defaults to Documents directory 
  outputPath: '/var/mobile/Containers/Data/Application/<APP_ID>/Library/Caches/',

  /// Optional: Local filename of output JPEG, defaults to "fion-geopdf-<page_number>-split-<split_number>"
  outputFilename: 'example.jpg',

  /// Optional: Disable split mechanic to fit within the max image resolution even after rescaling
  // disableSplit: false
}

/// The hi-res image is stored in Documents directory, the file uri is returned.
const result = await PdfSnapshot.generate(options)
const { uri, width, height } = result.images[0]
```

## Development

To develop for `react-native-pdf-snapshot`, use the following commands to get set up:

```sh
yarn install
yarn build
```

## License

See [LICENSE](LICENSE). 

MIT
Copyright (c) 2022 Fion, Julian Weiss
Copyright (c) 2020 Song Qian
