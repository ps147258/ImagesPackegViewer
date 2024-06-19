//
//  複製檔案到系統剪貼簿
//
// 類型：系統剪貼簿 (利用 Vcl.Clipboard)
// 編寫：Wei-Lun Huang
// 說明：將檔案複製到系統剪貼簿，複製的檔案可於系統檔案瀏覽器(Explorer)中貼上。
//
// 初版：2023年11月16日
//
// 最後變更日期：2023年11月16日
//

//
//  Copy file to system clipboard.
//
// Type: System clipboard.
// Author: Wei-Lun Huang
// Description:
//   Copy one or more files to the system clipboard.
//   The copied files can be pasted in the system file browser (Explorer).
//
// First edition: Nov 16, 2023.
//
// Last modified date: Nov 16, 2023.
//

// Reference:
//
// Standard Clipboard Formats
// https://learn.microsoft.com/en-us/windows/win32/dataxchg/standard-clipboard-formats
//
// Using the Clipboard
// https://learn.microsoft.com/en-us/windows/win32/dataxchg/using-the-clipboard
//
// DROPFILES structure
// https://learn.microsoft.com/en-us/windows/win32/api/shlobj_core/ns-shlobj_core-dropfiles
//
// GlobalAlloc, GlobalLock, GlobalUnlock functions
// [url]https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-globalalloc
// https://learn.microsoft.com/zh-tw/windows/win32/api/winbase/nf-winbase-globallock
// https://learn.microsoft.com/zh-tw/windows/win32/api/winbase/nf-winbase-globalunlock


unit Vcl.Clipboard.Files;

interface

uses
  Winapi.Windows, Winapi.ActiveX, Winapi.ShlObj,
  System.SysUtils,
  System.Classes,
  Vcl.Clipbrd;

// Copy multiple files to clipboard.
procedure CopyFilesToClipboard(FileNames: TStrings; DropPoint: TPoint; NonClient: Boolean; bMove: Boolean = False); overload;
procedure CopyFilesToClipboard(const FileNames: string; DropPoint: TPoint; NonClient: Boolean; bMove: Boolean = False); overload;
procedure CopyFilesToClipboard(FileNames: TStrings; bMove: Boolean); overload; inline;
procedure CopyFilesToClipboard(const FileNames: string; bMove: Boolean); overload; inline;

// Copy a file to clipboard.
procedure CopyFileToClipboard(const FileName: string; DropPoint: TPoint; NonClient: Boolean; bMove: Boolean = False); overload;
procedure CopyFileToClipboard(const FileName: string; bMove: Boolean); overload; inline;

implementation

//
// About list of multiple files.
//
// Each line ends with the character #0, and the last flight is followed by
// the character #0 indicating a blank line.
{ Text structure:
[String line 1][#0]
[String line 2][#0]
[String line 3][#0]
...
[String line last][#0]
[#0]
}
// So you can see that the end of the entire list will be two [#0].
// Example, a single line: 'C:\1\2\test.txt#0#0'
// or multiple lines: 'C:\test1.txt#0C:\test2.txt#0C:\test3.txt#0#0'

procedure CopyFilesToClipboard(FileNames: TStrings; DropPoint: TPoint; NonClient: Boolean; bMove: Boolean);
var
  hBuffer: HGLOBAL;
  pBuffer: PByte;
  S: string;
  I, iLen, iSize, Len: Integer;

  uDropEffect: UINT;
  hDropEffect: HGLOBAL;
  dwDropEffect: PDWORD;
begin
  // Count the number of characters in the string list.
  iLen := 0;
  for I := 0 to FileNames.Count - 1 do
  begin
    S := FileNames.Strings[I];
    if S = '' then
      Continue;
    Inc(iLen, Length(S) + 1);
  end;

  if iLen = 0 then
    Exit;

  Inc(iLen, 1);                 // Now have all the characters of the string list here.
  iSize := iLen * SizeOf(Char); // String list size by bytes.

  // A counter is needed to achieve release when system empty the clipboard.
  // so at least the flag GMEM_MOVEABLE is required. GHND contains GMEM_MOVEABLE.
  hBuffer := GlobalAlloc(GHND or GMEM_DDESHARE, SizeOf(TDropFiles) + iSize);
  if hBuffer = 0 then
    RaiseLastOSError;

  pBuffer := GlobalLock(hBuffer);
  if not Assigned(pBuffer) then
    RaiseLastOSError;

  try
    with PDropFiles(pBuffer)^ do // Set the list header.
    begin
      pFiles := SizeOf(TDropFiles); // offset of file list.
      pt := DropPoint;
      fNC := NonClient;

      // This follows the character bytes of the string type
      fWide := {$IFDEF UNICODE}True{$ELSE}False{$ENDIF};
    end;

    // Get the beginning of the list string memory.
    Inc(pBuffer, SizeOf(TDropFiles)); // Offset by byte type.

    // Copy strings to the buffer.
    for I := 0 to FileNames.Count - 1 do
    begin
      s := FileNames.Strings[I];
      Len := Length(s);
      if (Len = 0) or (s = '') then
        Continue;

      iSize := Len * SizeOf(Char);      // Calculate bytes of the string length.
      Move(PChar(S)^, pBuffer^, iSize); // Copy.
      Inc(pBuffer, iSize);              // Offset copied size.

// It is not needed here, because the flag has been set to GMEM_ZEROINIT when
// the buffer was created, and the entire buffer section has been cleared to 0.
//        PChar(pBuffer)^ := #0;
      Inc(pBuffer, SizeOf(Char)); // Offset by char type. pBuffer := pBuffer + [Chars] * SizeOf(Char);
    end;
//    PChar(pBuffer)^ := #0; // No need here, reason same as the previous in for loop.

    // Register Preferred DropEffect
    uDropEffect := RegisterClipboardFormat('Preferred DropEffect');
    hDropEffect := GlobalAlloc(GHND or GMEM_DDESHARE, SizeOf(DWORD));
    dwDropEffect := PDWORD(GlobalLock(hDropEffect));

    try
      // Set DropEffect
      if bMove then
        dwDropEffect^ := DROPEFFECT_MOVE
      else
        dwDropEffect^ := DROPEFFECT_COPY;

      Clipboard.Open;
      try
        Clipboard.SetAsHandle(uDropEffect, hDropEffect);
        Clipboard.SetAsHandle(CF_HDROP, hBuffer);
      finally
        Clipboard.Close;
      end;

    finally
      GlobalUnlock(hDropEffect);
    end;

  finally
    GlobalUnlock(hBuffer);
  end;

end;

procedure CopyFilesToClipboard(const FileNames: string; DropPoint: TPoint; NonClient: Boolean; bMove: Boolean);
var
  S: TStringList;
begin
  S := TStringList.Create;
  try
    S.Text := FileNames;
    CopyFilesToClipboard(S, DropPoint, NonClient, bMove);
  finally
    S.Free;
  end;
end;

procedure CopyFilesToClipboard(FileNames: TStrings; bMove: Boolean);
begin
  CopyFilesToClipboard(FileNames, TPoint.Create(0, 0), False, bMove);
end;

procedure CopyFilesToClipboard(const FileNames: string; bMove: Boolean);
begin
  CopyFilesToClipboard(FileNames, TPoint.Create(0, 0), False, bMove);
end;

procedure CopyFileToClipboard(const FileName: string; DropPoint: TPoint; NonClient: Boolean; bMove: Boolean);
var
  DropFiles: PDropFiles;
  hBuffer: HGLOBAL;
  iLen, iSize: Integer;

  uDropEffect: UINT;
  hDropEffect: HGLOBAL;
  dwDropEffect: PDWORD;
begin
  iLen := Length(FileName) + 2; // For the two #0 at end of string and end of list, so add 2.
  iSize := iLen * SizeOf(Char); // Buffer size by bytes.
  hBuffer := GlobalAlloc(GHND or GMEM_DDESHARE, SizeOf(TDropFiles) + iSize);
  if hBuffer = 0 then
    RaiseLastOSError;

  DropFiles := GlobalLock(hBuffer);
  if not Assigned(DropFiles) then
    RaiseLastOSError;
  try
    with DropFiles^ do
    begin
      pFiles := SizeOf(TDropFiles); // offset of file list.
      pt := DropPoint;
      fNC := NonClient;

      // This follows the character bytes of the string type
      fWide := {$IFDEF UNICODE}True{$ELSE}False{$ENDIF}; // UNICODE is Wide(two byte), or ASCII(one byte)
    end;
    Move(PChar(FileName)^, (PByte(DropFiles) + SizeOf(TDropFiles))^, Length(FileName) * SizeOf(Char));

    uDropEffect := RegisterClipboardFormat('Preferred DropEffect');
    hDropEffect := GlobalAlloc(GHND or GMEM_DDESHARE, SizeOf(DWORD));
    dwDropEffect := PDWORD(GlobalLock(hDropEffect));
    try
      if bMove then
        dwDropEffect^ := DROPEFFECT_MOVE
      else
        dwDropEffect^ := DROPEFFECT_COPY;

      Clipboard.Open;
      try
        Clipboard.SetAsHandle(uDropEffect, hDropEffect);
        Clipboard.SetAsHandle(CF_HDROP, hBuffer);
      finally
        Clipboard.Close;
      end;

    finally
      GlobalUnlock(hDropEffect);
    end;

  finally
    GlobalUnlock(hBuffer);
  end;
end;

procedure CopyFileToClipboard(const FileName: string; bMove: Boolean);
begin
  CopyFileToClipboard(FileName, TPoint.Create(0, 0), False, bMove);
end;

end.
