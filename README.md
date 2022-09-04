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

// For iOS, the filePath can be a file URL.
// For Android, the filePath can be either a content URI, a file URI or an absolute path.
const filePath = 'file:///mnt/sdcard/myDocument.pdf';
const page = 0;

// Optional: custom DPI (resolution), instead of the 72 that is used be default.
const dpi = 144 / 72;

// The hi-res image is stored in Documents directory, file uri is returned.
// Image dimensions are also available to help you display it correctly.
const { uri, width, height } = await PdfSnapshot.generate(filePath, page, dpi);

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
