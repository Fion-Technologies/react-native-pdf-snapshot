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
  max: number,

  /// Optional: PDF page to snapshot, defaults to 0
  page: 0,

  /// Optional: Local path of output JPEG, defaults to Documents directory with a random filename and the page number
  output: '/var/mobile/Containers/Data/Application/<APP_ID>/Library/Caches/image.jpg'

}

/// The hi-res image is stored in Documents directory, the file uri is returned.
const results = await PdfSnapshot.generate(options)
const { uri, width, height } = results[0]

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
