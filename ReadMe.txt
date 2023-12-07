中文：
此說明適用於 1.3 及更高版本。

說明：
在記憶體中快速的將大型影像處理至螢幕大小，一系列的檔案會接連載入，可用於快速瀏覽多影像檔案。

支援的檔案：*.bmp; *.jpg; *.jpeg; *.png; *.webp; *.tiff; *.gif, *.zip
存取的範圍：資料夾下但不包括子資料夾下的。
使用方式：用滑鼠將檔案或者資料夾拖曳至本程式的視窗中後放開。

鍵盤操作：
在圖形上雙擊滑鼠左鍵切換視窗大小/原始大小。
  *視窗大小為記憶體中的最佳化大小影像。
  *原始大小為原始檔案的影像，原始影像沒有快取，所以顯示原始影像將會再次讀取檔案。
ESC: 關閉檔案
F2:最佳化視窗大小
左: 上一個
右: 下一個
Ctrl+X: 剪下正在瀏覽的檔案至剪貼簿。
Ctrl+C: 複製正在瀏覽的檔案至剪貼簿。
滑鼠操作：
Shift+滑鼠左鍵+滑鼠移動: 拖動正在瀏覽的檔案至其他位置(移動)或程式。
Ctrl+滑鼠左鍵+滑鼠移動: 拖動正在瀏覽的檔案至其他位置(複製)或程式。
[Shift 或 Ctrl]+滑鼠右鍵: 將檔案拖至目標後放開[滑鼠右鍵]以顯示檔案操作選單。

單影像容器使用TWICImage，可以支援有.NET 3.0的Windows XP SP2或以上的系統，單影像可支援 BMP, GIF, ICO, JPEG, PNG, TIFF。
動態影像支援GIF，但由於處理多影像格式會大幅影響處理速度，因此GIF縮圖仍然使用單影像，這意味著縮圖顯示將非動態，而顯示會以首位影格。

**拖放元件**
DragAndDrop 元件包.
用途：OLE 資料拖放操作，檔案拖放。
https://github.com/landrix/The-Drag-and-Drop-Component-Suite-for-Delphi


English:
This description for version 1.3 and later.

Description:
Quickly process large images to screen size in memory, series of files are loading for quick browsing of multi-image files.

Supported files: *.bmp; *.jpg; *.jpeg; *.png; *.webp; *.tiff; *.gif, *.zip
Scope of access: under the folder but not under the subfolder.
How to use: Use the mouse to drag the file or folder to the window of this program and release it.

Key operation:
Double click the left mouse button on the graph to toggle the window size/original size.
  *Window size is the optimal size image in memory.
  *The original size is the image of the original file, the original image is not cached, so displaying the original image will read the file again.
ESC: close file
F2: optimize window size
Left: previous
Right: next
Ctrl+X: Cut the image file browsing to the clipboard.
Ctrl+C: Copy the image file browsing to the clipboard.
Mouse operation:
Shift+[Left mouse button]+[Move mouse]: Drag the file browsing to another folder (move) or program.
Ctrl+[Left mouse button]+[Move mouse]: Drag the file browsing to another folder (copy) or program.
[Shift or Ctrl]+[Right mouse button]+[Move mouse]: Drag the file to the target and release the [right mouse button] to display the file operation menu.

Single image container using TWICImage, can support Windows XP SP2 or above with .NET 3.0. so single image can support BMP, GIF, ICO, JPEG, PNG, TIFF.
Animated images support GIF, but since processing multiple image formats will greatly affect the processing speed, GIF thumbnails still use a single image, which means that the thumbnail display will not be dynamic, and the display will be the first frame.

**Components**
DragAndDrop component suite.
Purpose: OLE data drag-and-drop operation, file drag-and-drop.
https://github.com/landrix/The-Drag-and-Drop-Component-Suite-for-Delphi
