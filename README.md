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
import PdfSnapshot from "react-native-pdf-snapshot";

const options = {

  /// URL of the PDF
  url: 'file:///mnt/sdcard/myDocument.pdf',

  /// Optional: PDF page to snapshot
  page: 0,

  /// Optional: DPI (resolution) of output JPEG
  dpi: 72,

  /// Optional: Path of output JPEG, to override default Documents directory and random filename behavior
  output: '/var/mobile/Containers/Data/Application/<APP_ID>/Library/Caches/image.jpg'

};

/// The hi-res image is stored in Documents directory, the file uri is returned.
const { uri, width, height } = await PdfSnapshot.generate(options);

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
