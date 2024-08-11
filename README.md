# iWin Share (iOS app)

iWin share is an iOS app for sharing content from iOS devices to Windows PCs. You can follow these steps below for installation and usage.

## Installation

1. Clone this repository into your Mac and open it with Xcode.
2. Connect your iOS device to your Mac, then run the app.
3. Your device will ask you to enable Developer Mode, so you need to go to Privacy & Security and turn on Developer Mode.
4. Then, it will ask you if you want to trust this app or not. To continue, go to VPN & Device Management under Settings, select "Developer App", and click on "Trust iWin Share".
5. After this, you may need to visit [iWin](https://github.com/archawitch/iwin) to complete your setup.

## Usage

iWin Share utilizes the iOS share extension for sharing content. The app allows only images, videos, files, URLs, and text to be shared at a time (not exceeding 50MB). Here is the steps that you can follow in order to share your contents with Windows PCs.

1. Select the content you want to share and click the share button.
2. A popup containing a list of apps will appear, then click on "iWin share".
3. This will take for a moment to find iWin services to which you have already registered.
4. Then, click "Send" on a PC that you want to share with.
5. After your content is successfully transferred, the popup will close, and now you can use your content on the Windows PC.

## Notes

- If your desired PC is not shown in the PC list (Share Extension), you can fix this by clicking the "Refresh" button on the settings page of your PC to restart the mDNS service.
- PCs will open your destination folder if you share files (pdf, docs, jpg, etc.).
- PCs will open a link on your browser if you share a URL.
- PCs will copy the text to the clipboard without notifying you when you share it.
