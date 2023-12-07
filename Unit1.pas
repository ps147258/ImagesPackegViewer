unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ActiveX, Winapi.MMSystem, Winapi.CommCtrl, Winapi.ShellAPI,
  System.SysUtils, System.Variants, System.Classes, System.Types, System.IOUtils,
  System.Generics.Defaults, System.Generics.Collections, System.Zip, System.ImageList,
  System.IniFiles, System.WideStrUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Clipbrd,
  Vcl.StdCtrls, Vcl.Menus, Vcl.ComCtrls, Vcl.ImgList, Vcl.Imaging.GIFImg,
  Vcl.ImageCollection,
  JvComponentBase, JvThread, JvBalloonHint,

  Vcl.Graphics.MultipleWICImage,
//  Vcl.Imaging.GIFImg.GifExtend,
  Vcl.Clipboard.Files,
//  Vcl.DragFiles, // 以 Sven Harazim 的 DragAndDrop 元件取代，支援檔案拖入拖出
//  Vcl.PositionControl,

  // DragAndDrop component suite.
  // © 1997-2010 Anders Melander
  // © 2011-2023 Sven Harazim
  // https://github.com/landrix/The-Drag-and-Drop-Component-Suite-for-Delphi
  DragDrop, DropSource, DropTarget, DragDropFile;

type
  TForm1 = class(TForm)
    ImageList1: TImageList;
    JvThread1: TJvThread;
    Timer1: TTimer; // 延遲載入
    Timer2: TTimer; // 訊息
    Timer3: TTimer; // 多圖動態顯示
    DropFileTarget1: TDropFileTarget;
    DropFileSource1: TDropFileSource;
    PopupMenu1: TPopupMenu;
      N1: TMenuItem;
      N2: TMenuItem;
      N3: TMenuItem;
      N4: TMenuItem;
      N5: TMenuItem;
      N6: TMenuItem;
      N7: TMenuItem;
    ScrollBox1: TScrollBox;
      Image1: TImage;
    StaticText1: TStaticText;
    Splitter1: TSplitter;
    ListView1: TListView;
    Button1: TButton;
    Button2: TButton;
    JvBalloonHint1: TJvBalloonHint;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormDblClick(Sender: TObject);
    procedure Splitter1CanResize(Sender: TObject; var NewSize: Integer; var Accept: Boolean);
    procedure Splitter1Moved(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure Timer3Timer(Sender: TObject);
    procedure JvThread1Begin(Sender: TObject);
    procedure JvThread1Execute(Sender: TObject; Params: Pointer);
    procedure JvThread1FinishAll(Sender: TObject);
    procedure ScrollBox1Resize(Sender: TObject);
    procedure ScrollBox1DblClick(Sender: TObject);
    procedure ListView1Compare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
    procedure ListView1InfoTip(Sender: TObject; Item: TListItem; var InfoTip: string);
    procedure ListView1SelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure Image1DblClick(Sender: TObject);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure DropFileTarget1Drop(Sender: TObject; ShiftState: TShiftState; APoint: TPoint; var Effect: Integer);
    procedure DropFileTarget1DragOver(Sender: TObject; ShiftState: TShiftState; APoint: TPoint; var Effect: Integer);
    procedure DropFileSource1GetDragImage(Sender: TObject; const DragSourceHelper: IDragSourceHelper; var Handled: Boolean);
    procedure DropFileSource1AfterDrop(Sender: TObject; DragResult: TDragResult; Optimized: Boolean);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure N4Click(Sender: TObject);
    procedure N6Click(Sender: TObject);
    procedure N7Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private type
    TViewState = set of (_VS_Resizing, _VS_SizeChanged, _VS_Turning, _VS_Selecting, _VS_ImageWating);
    TDisplayMode = (_DM_Suitable, _DM_Original);
    TOpenType = (_OT_Non, _OT_Files, _OT_Zip);
    TTurnPage = (_TP_First, _TP_Last, _TP_Prev, _TP_Next);
    TImageType = (_PIT_OBJ, _PIT_WIC, _PIT_GIF, _PIT_MultiWIC);
    TImageObj = record
      function GetSize(out ASize: TSize): Boolean; overload; inline;
      function GetSize: TSize; overload; inline;
      case TImageType of
        _PIT_OBJ:(Obj: TObject;);
        _PIT_WIC:(WIC: TWICImage;);
        _PIT_GIF:(GIF: TGIFImage;);
        _PIT_MultiWIC:(Multi: TWICImages;);
    end;
    PImageItem = ^TImageItem;
    TImageItem = record
      Mode: TImageType;
      Slot: TImageObj;
      function Assigned: Boolean; inline;
      procedure Free; inline;
    end;
    PPictureItem = ^TPictureItem;
    TPictureItem = record
      ID: Integer;
      Name: string;
      Image: TImageItem;
      iThumb: Integer;
      ThumbItem: TListItem;
    end;
    TPictureList = class(TList<TPictureItem>)
    private
      procedure SetId(Index: Integer; Id: Integer);
      function GetId(Index: Integer): Integer;
      procedure SetName(Index: Integer; const Name: string);
      function GetName(Index: Integer): string;
      procedure SetThumbIndex(Index: Integer; iThumb: Integer);
      function GetThumbIndex(Index: Integer): Integer;
    protected
      procedure Notify(const Value: TPictureItem; Action: TCollectionNotification); override;
    public
      function Add(ID: Integer; const Name: string): Integer; overload; inline;

      procedure SetImage(Index: Integer; Mode: TImageType; Image: TObject; Thumb: TListItem = nil);
      procedure SetImageItem(Index: Integer; const Item: TImageItem);

      procedure SetWIC(Index: Integer; Image: TWICImage);
      procedure SetGIF(Index: Integer; Image: TGIFImage);
      procedure SetMultiWIC(Index: Integer; Images: TWICImages);

      procedure SetThumbItem(Index: Integer; Item: TListItem);
      function GetThumbItem(Index: Integer): TListItem;

      function GetImage(Index: Integer; out Image: TObject; out Thumb: TListItem): TImageType; overload;
      function GetImage(Index: Integer; out Image: TObject): TImageType; overload;
      function GetImageItem(Index: Integer; out Thumb: TListItem): TImageItem; overload;
      function GetImageItem(Index: Integer): TImageItem; overload;

      function GetWIC(Index: Integer): TWICImage;
      function GetGIF(Index: Integer): TGIFImage;


      property Id[Index: Integer]: Integer read GetId write SetId;
      property Names[Index: Integer]: string read GetName write SetName;
      property ThumbItem[Index: Integer]: TListItem read GetThumbItem write SetThumbItem;
      property iThumb[Index: Integer]: Integer read GetThumbIndex write SetThumbIndex;
    end;
    TGifFrameBuffer = record
      iFrame: Integer;
      Pic: TPictureItem;
      WIC: TWICImage;
      Frame: TGIFFrame;
    end;
    PGifFrameBuffer = ^TGifFrameBuffer;
    TItemIndex = type Integer;
    TPictureIndex = type Integer;
  private
    Processors: DWORD;       // 處理器數量
    SettingChanged: Boolean; // 用於表示設定是否有變動
    SplitterMin: Integer;
    SplitterMax: Integer;
    Closeing: Boolean;       // 程式是否處於關閉程序中
    ViewState: TViewState;
    CursorTracking: Boolean; // 是否開始處理游標追蹤
    IsLoading: Boolean;      // 是否正在處理清單檔案的載入
    LastCursor: TPoint;      // 游標位置暫存
    Loading: string;         // 同步載入處理的提示訊息
    ThumbSize: TSize;        // 縮圖大小，在此介面建立時以 ImageList1 的圖形大小作為設定。
//    DropFiles: TDropFiles;
    DirPath: string;
    Title: string;
    OpenType: TOpenType;     // 檔案的開啟模式
    ZipCS: TRTLCriticalSection; // 防止 Zip 被同時存取，若 Class 沒有表明可同時多執行續，處理時都應預設為單一處理。
    Zip: TZipFile;
    MemBuf: TMemoryStream;   // 緩衝區，用來減少記憶體碎片產生的可能，雖機率應不大。
    Pictures: TPictureList;  // 來源影像資訊的清單

    iThumbItem: TItemIndex;       // 瀏覽清單索引

    iPicture: TPictureIndex;       // 主影像索引
    iPictureOld: TPictureIndex;    // 主影像索引變更前的索引
    Limit: TSize;            // 影像在介面中可顯示全圖的最大大小
    ImageView: TImageItem;   // 目前已最佳化的影像
    DisplayMode: TDisplayMode; // 顯示影像大小的方式
    BaseThread: TJvBaseThread; // 處理影像載入的執行續
    OldAppMessage: TMessageEvent;
    procedure OnAppMessage(var Msg: TMsg; var Handled: Boolean);
    procedure SettingChange; inline;
    procedure UpdateSplitterMax;
    function GetSplitterCurr: Integer;
    procedure SplitterTo(X, Y: Integer); overload;
    procedure SplitterTo(Value: Integer); overload;
    procedure ViewTipMode(bBlatant: Boolean);
    procedure ViewTipAdjust(bCentral: Boolean = False);
    procedure ViewSizeTip;
    procedure FocusWindows;
    procedure SetLayoutSize(Width, Height: Integer);
    procedure CloseImages;
    function ComparePictureItem(const Left, Right: TPictureItem): Integer;
    procedure OpenImagesFormFiles(const Directory: string);
    procedure OpenImagesFormZip(const Path: string);
    function PictureIndexOfFileName(const FileName: string): Integer;
    function GetPictureIndex(ThumbItem: TListItem): TPictureIndex; overload; inline;
    function GetPictureIndex(ThumbItemIndex: TItemIndex): TPictureIndex; overload;
    function GetThumbItemIndex(PictureIndex: TPictureIndex): TItemIndex;
//    procedure OnDropFiles(Sender: TObject; WinControl: TWinControl);
    procedure DoCopyFileToClipboard(bMove: Boolean);
    procedure ShowTip(const Text: string; Seconds: Byte = 1; Color: TColor = clWindowText);
    procedure ShowLoadingInfo;
    function SaveFileToTempPath(const PictureItem: TPictureItem): string;
    procedure LoadImage(var ImageItem: TImageItem; Stream: TStream; FrameIndex: Integer);
    function LoadOriginal(const FileItem: TPictureItem; var ImageItem: TImageItem; FrameIndex: Integer = 0; Buffer: TStream = nil): Boolean;
    function LoadPicture(Index: Integer): Boolean;
    procedure SetTimerImageWating;
    function ShowImage(Index: TPictureIndex; Mode: TDisplayMode = _DM_Suitable): Boolean; overload;
    function ShowImage(Index: TItemIndex; Mode: TDisplayMode = _DM_Suitable): Boolean; overload;
    function ShowImage(Mode: TDisplayMode): Boolean; overload; inline;
    function ShowImage: Boolean; overload; inline;
    procedure ViewOriginal(const Point: TPoint); overload;
    procedure ViewOriginal; overload;
    procedure NextWICImage;
    procedure TurnPage(Turn: TTurnPage);
    function GetCurrentImageSize(out Size: TSize): Boolean;
    function GetReduceSize(MaxWidth, MaxHeight, Width, Height: Integer; Inward: Boolean; out Size: TSize): Boolean; overload;
    function GetReduceSize(Width, Height: Integer; out Size: TSize): Boolean; overload; inline;
    function GetReduceInView(const PicItem: TPictureItem; Inward: Boolean; out Size: TSize): Boolean;
    procedure LoadSetting;
    procedure SaveSetting;

  public
    { Public declarations }
    procedure WndProc(var Message: TMessage); override;
  end;

var
  Form1: TForm1;

implementation

{$IFDEF DEBUG}
uses
  Debug;
{$ENDIF DEBUG}

type
  TSetting = (_AS_Layout);
  TSettingLayout = (_ASL_ThumbnailList, _ASL_ThumbnailMargin, _ASL_ThumbnailName);

const
  SettingSection: array[TSetting] of string = (
    'Layout'
  );
  SettingIdent: array[TSettingLayout] of string = (
    'ThumbnailList',
    'ThumbnailMargin',
    'ThumbnailName'
  );

{$R *.dfm}

var
  gExplorerPath: string = '';
  gTempDir: string = '';

function GetExplorerPath: string;
const
  ExplorerFileName = 'explorer.exe';
var
  I, J: Integer;
begin
  if gExplorerPath <> '' then Exit(gExplorerPath);

  SetLength(Result, MAX_PATH);
  I := GetWindowsDirectory(PChar(Result), MAX_PATH);

  if (I > 0) and (Result[I] <> PathDelim) then
  begin
    Inc(I);
    Result[I] := PathDelim;
  end;

  Inc(I);
  J := ExplorerFileName.Length;
  Move(ExplorerFileName, Result[I], (J + 1) * SizeOf(Char));
  Inc(I, J);
//  Result[I] := #0;
  SetLength(Result, I);
end;

function GetAppTempDir: string;
begin
  if gTempDir <> '' then Exit(gTempDir);

  gTempDir := IncludeTrailingPathDelimiter(TPath.GetTempPath) +
              ChangeFileExt(ExtractFileName(Application.ExeName), '') + PathDelim;
  Result := gTempDir
end;

function GetNearestDir(const Directory: string): string;
var
  I: Integer;
begin
  Result := Directory;
  if Result[Result.Length] = PathDelim then
    SetLength(Result, Result.Length - 1);
  while not DirectoryExists(Result, False) do
  begin
    I := Result.LastIndexOf(PathDelim);
    if I < 0 then Exit('');
    SetLength(Result, I - 1);
  end;
end;

type
  TExplorerOpenMode = (_FEO_All, _FEO_Dir, _FEO_Nearest);

function GetShellExecuteMessage(Code: HINST): string;
begin
//  case Code of
//    SE_ERR_FNF:             Result := 'File not found.';
//    SE_ERR_PNF:             Result := 'Path not found.';
//    SE_ERR_ACCESSDENIED:    Result := 'Access denied.';
//    SE_ERR_OOM:             Result := 'Out of memory.';
//    SE_ERR_DLLNOTFOUND:     Result := 'Dynamic-link library not found.';
//    SE_ERR_SHARE:           Result := 'Cannot share an open file.';
//    SE_ERR_ASSOCINCOMPLETE: Result := 'File association information not complete.';
//    SE_ERR_DDETIMEOUT:      Result := 'DDE operation timeout.';
//    SE_ERR_DDEFAIL:         Result := 'DDE operation fail.';
//    SE_ERR_DDEBUSY:         Result := 'DDE operation is busy.';
//    SE_ERR_NOASSOC:         Result := 'File association not available.';
//  else if Code <= 32 then Result := Format('Error(%d).', [Code]) else Result := '';
//  end;
  case Code of
    SE_ERR_FNF:             Result := '檔案不存在。';
    SE_ERR_PNF:             Result := '路徑不存在。';
    SE_ERR_ACCESSDENIED:    Result := '無法存取。';
    SE_ERR_OOM:             Result := '記憶體不足。';
    SE_ERR_DLLNOTFOUND:     Result := '找不到動態連接庫(DLL)。';
    SE_ERR_SHARE:           Result := '無法共用開啟的檔案。';
    SE_ERR_ASSOCINCOMPLETE: Result := '檔案關聯資訊不完整。';
    SE_ERR_DDETIMEOUT:      Result := 'DDE 操作逾時。';
    SE_ERR_DDEFAIL:         Result := 'DDE 操作失敗。';
    SE_ERR_DDEBUSY:         Result := 'DDE 操作忙碌。';
    SE_ERR_NOASSOC:         Result := '檔案關聯無法使用。';
  else if Code <= 32 then Result := Format('Error(%d).', [Code]) else Result := '';
  end;
end;

function ExplorerSucceed(Code: HINST): Boolean; inline;
begin
  Result := Code > 32;
end;

function OpenInExplorer(const Path: string; AsFolder: Boolean): HINST;
var
  s: string;
begin
// 使用 GetExplorerPath 以取得明確的 Exlporer 路徑，減少路徑搜索的步驟，
// 這只是個人需求，因沒必要搜尋系統變數路徑而已。
// 但不防止被 IFEO(Image File Execution Options) 變更實際執行映像位置。
//
// Image File Execution Options
// https://learn.microsoft.com/en-us/previous-versions/windows/desktop/xperf/image-file-execution-options
//
// HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe
//
  if AsFolder then s := '/e,"'+Path+'"' else s := '/select,"'+Path+'"';
    Result := ShellExecute(Application.Handle, 'open', PChar(GetExplorerPath), PChar(s), nil, SW_NORMAL)
//
// 或使用預設 explore 開啟方式
//  Result := ShellExecute(Application.Handle, 'explore', PChar(Path), nil, nil, SW_NORMAL);
end;

function BrowseByExplorer(Directory: string; Filename: string = ''; Mode: TExplorerOpenMode = _FEO_All): Boolean;
var
  Path: string;
  hInstApp: HINST;
begin
  if Filename.IsEmpty then
  begin
    if Directory.IsEmpty then Exit(True);
  end
  else
  begin
    if Directory.IsEmpty then
      Directory := ExcludeTrailingPathDelimiter(GetCurrentDir);

    Path := IncludeTrailingPathDelimiter(Directory) + Filename;
    if FileExists(Path, False) then
    begin
      hInstApp := OpenInExplorer(Path, False);
//      hInstApp := ShellExecute(Application.Handle, 'open', PChar(GetExplorerPath),
//        PChar('/select,"'+Path+'"'), nil, SW_NORMAL);

      if ExplorerSucceed(hInstApp) then Exit(True);
    end
    else
      hInstApp := SE_ERR_FNF;
    if Mode = _FEO_All then
    begin
      Application.MessageBox(PChar(Path + sLineBreak +
        GetShellExecuteMessage(hInstApp)), '檔案 或 資料夾 不存在！', MB_OK or MB_ICONHAND);
      Exit(False);
    end;
  end;

  if DirectoryExists(Directory, False) then
  begin
    hInstApp := OpenInExplorer(Path, True);
//    hInstApp := ShellExecute(Application.Handle, 'open', PChar(GetExplorerPath),
//      PChar('/e,"'+Directory+'"'), nil, SW_NORMAL);

    if ExplorerSucceed(hInstApp) then Exit(True);
  end
  else
    hInstApp := SE_ERR_PNF;

  case Mode of
    _FEO_All, _FEO_Dir:
    begin
      Application.MessageBox(PChar(Path + sLineBreak +
        GetShellExecuteMessage(hInstApp)), '資料夾不存在！', MB_OK or MB_ICONHAND);
      Exit(False);
    end;
  end;

  if Mode = _FEO_Nearest then
  begin
    Path := GetNearestDir(Directory);
    hInstApp := OpenInExplorer(Path, True);
//    hInstApp := ShellExecute(Application.Handle, 'open', PChar(GetExplorerPath),
//      PChar('/e,"'+Path+'"'), nil, SW_NORMAL);
    if ExplorerSucceed(hInstApp) then Exit(True);

    Application.MessageBox(PChar(Directory + sLineBreak +
      GetShellExecuteMessage(hInstApp)), '路徑不存在，也不存在上層路徑！', MB_OK or MB_ICONHAND);
  end;

  Result := False;
end;

function AppName: string; inline;
begin
  Result := Application.ExeName;
end;

var
  IniNameBuffer: string;

function IniName: string; inline;
begin
  if IniNameBuffer.IsEmpty then
    Result := ChangeFileExt(AppName, '.ini')
  else
    Result := IniNameBuffer;
end;

function CheckExt(const s: string): Boolean; inline;
const
  FileExt: array[0..6] of string = ('.bmp', '.jpg', '.jpeg', '.png', '.webp', '.tiff', '.gif');
var
  I: Integer;
begin
  for I := 0 to Length(FileExt) - 1 do
    if s.EndsWith(FileExt[I], True) then
      Exit(True);
  Result := False;
end;

type
  TFindFileNameProc = reference to procedure(const FileName: string);

procedure EnumFiles(const Path: string; AProc: TFindFileNameProc);
var
  hFind: THandle;
  FindData: TWIN32FindData;
  FileName: string;
begin
  hFind := Winapi.Windows.FindFirstFile(PChar(Path + '*'), FindData);
  if hFind = INVALID_HANDLE_VALUE then Exit;
  try
    repeat
      if FindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY = 0 then
      begin
        FileName := WideCharToString(FindData.cFileName);
        AProc(FileName);
      end;
    until not FindNextFile(hFind, FindData);
  finally
    Winapi.Windows.FindClose(hFind);
  end;
end;

function CompareName(const Left, Right: string): Integer; inline;
var
  sL, sR: string;
  iA, iB: Integer;
begin
  sR := ChangeFileExt(Right, '');
  sL := ChangeFileExt(Left, '');
  if TryStrToInt(sR, iB) then
    if TryStrToInt(sL, iA) then Result := iA - iB else Result := 1
  else
    if TryStrToInt(sL, iA) then Result := -1 else Result := CompareStr(sL, sR);
end;

//
// GetItemRect、GetHeaderHeight、CtlScrollTo
// 從 Vcl.PositionControl 中複製的一部份
//

// 取得 ListView 指定索引的矩形座標
function GetItemRect(ListView: TCustomListView; Index: Integer; out Rect: TRect): LRESULT;
begin
  Rect.left := LVIR_BOUNDS;
  Result := ListView.Perform(LVM_GETITEMRECT, Index, LPARAM(@Rect));
end;

// 取得 ListView 標題列高度，一般在 Report 模式為大於 0，否則通常為 0。
function GetHeaderHeight(LV: TCustomListView): Integer;
var
  h: THandle;
  R: TRect;
begin
  h := LV.Perform(LVM_GETHEADER, 0, 0);
  if h <> 0 then
    if GetWindowRect(h, R) then
      Exit(R.Height);
  Result := 0;
end;

// 捲動 ListView 並置中至指定索引的物件，如有捲動回傳 True，否則 False。
function CtlScrollTo(ListView: TCustomListView; Index: Integer): Boolean;
var
  si: TScrollInfo;
  TopR, ItemR: TRect;
  ClientRect: TRect;
begin
  Result := False;

  si.cbSize := SizeOf(si);
  si.fMask := SIF_ALL;
  if not GetScrollInfo(ListView.Handle, SB_VERT, si) then Exit;

  GetItemRect(ListView, si.nPos, TopR);
  GetItemRect(ListView, Index, ItemR);

  ClientRect := ListView.ClientRect;

  // 取得標題列高度 (雖 GetHeaderHeight 實際未使用，但為介面靈活性因此保留)
  ClientRect.Top := GetHeaderHeight(ListView);

  if ItemR.Height >= ClientRect.Height then
    ListView.Scroll(0, ItemR.Top - ClientRect.Top)
  else
    ListView.Scroll(0, ItemR.Top + (ItemR.Height div 2) - (ClientRect.Height div 2) + ClientRect.Top);
  Result := True;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  I: Integer;
  N: Integer;
  M: TMonitor;
  SI: TSystemInfo;
begin
  IsLoading := False;
  Closeing := False;
  ViewState := [];
  BaseThread := nil;
  Zip := nil;
  OpenType := _OT_Non;

  FillChar(SI, SizeOf(SI), 0);
  GetNativeSystemInfo(SI);
  Processors := SI.dwNumberOfProcessors;
  if Processors <= 0 then Processors := 8;

  Limit.Width  := 0;
  Limit.Height := 0;
  for I := 0 to Screen.MonitorCount - 1 do
  begin
    M := Screen.Monitors[I];
    N := M.Width;
    if N > Limit.Width  then Limit.Width  := N;
    N := M.Height;
    if N > Limit.Height then Limit.Height := N;
  end;

  ImageView.Mode := _PIT_OBJ;
  ImageView.Slot.Obj := nil;
  MemBuf := nil;
  Pictures := TPictureList.Create(TComparer<TPictureItem>.Construct(ComparePictureItem));

//  DropFiles := TDropFiles.Create(Self, OnDropFiles);
  ViewTipAdjust;

  ThumbSize := TSize.Create(ImageList1.Width, ImageList1.Height);

end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  JvThread1.TerminateWaitFor(False);

  if Assigned(Pictures) then Pictures.Free;
  if Assigned(MemBuf)   then MemBuf.Free;

  if Assigned(Zip) then
  begin
    DeleteCriticalSection(ZipCS);
    Zip.Free;
  end;

  if ImageView.Assigned then ImageView.Slot.Obj.Free;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  SplitterMin := Splitter1.MinSize;
  UpdateSplitterMax;
  LoadSetting;
  OldAppMessage := Application.OnMessage;
  Application.OnMessage := OnAppMessage;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Timer3.Enabled:= False;
  Timer2.Enabled:= False;
  Timer1.Enabled:= False;
  CloseImages;
  Application.OnMessage := OldAppMessage;
  SaveSetting;
end;

procedure TForm1.OnAppMessage(var Msg: TMsg; var Handled: Boolean);
type
  PCMMouseWheel = ^TCMMouseWheel;
var
  WheelDelta: SmallInt;
begin
  if Assigned(OldAppMessage) then
    OldAppMessage(Msg, Handled);

//  try
    if Msg.message <> WM_MOUSEWHEEL then Exit;
    if ListView1.MouseInClient      then Exit;

    WheelDelta := PCMMouseWheel(@Msg.message).WheelDelta;

    if WheelDelta > 0 then
    begin
      TurnPage(_TP_Prev);
      Handled := True;
    end
    else
    if WheelDelta < 0 then
    begin
      TurnPage(_TP_Next);
      Handled := True;
    end;
//  finally
//  end;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  W: TWICImage;
  P: TPictureItem;
begin
  if Shift = [] then
  begin
    case Key of
      VK_ESCAPE: CloseImages;
      VK_LEFT  : TurnPage(_TP_Prev);
      VK_RIGHT : TurnPage(_TP_Next);
      VK_F2    : N2.Click;
      VK_F3:
      begin
        P := Pictures.Items[iPicture];
        if P.Image.Mode <> _PIT_WIC then Exit;

        W := P.Image.Slot.WIC;
        if not Assigned(W)  then Exit;
        if W.FrameCount < 2 then Exit;

        if W.FrameIndex >= W.FrameCount -1 then
          W.FrameIndex := 0
        else
          W.FrameIndex := W.FrameIndex + 1;

        ShowImage(_DM_Original);
      end;
    end;
  end
  else if [ssCtrl] = Shift then
  begin
    case Chr(Key) of
      'E': N4.Click;
      'C': N6.Click;
      'X': N7.Click;
    end;
  end;
end;

procedure TForm1.FormDblClick(Sender: TObject);
begin
  if DisplayMode = _DM_Original then
    ShowImage(_DM_Suitable)
  else
    ShowImage(_DM_Original);
end;

procedure TForm1.ScrollBox1Resize(Sender: TObject);
begin
  ViewSizeTip;
  ViewTipAdjust;
  if not (_VS_SizeChanged in ViewState) then
  begin
    Include(ViewState, _VS_SizeChanged);
    StaticText1.Visible := True;
    Image1.Proportional := True;
    Image1.Stretch := True;
    Timer1.Enabled := True;
    Timer2.Enabled := True;
  end;
end;

procedure TForm1.ScrollBox1DblClick(Sender: TObject);
begin
  if DisplayMode = _DM_Original then
    ShowImage(_DM_Suitable)
  else
    ShowImage(_DM_Original);
end;

procedure TForm1.Image1DblClick(Sender: TObject);
begin
  ViewOriginal;
end;

procedure TForm1.ListView1Compare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
begin
  Compare := Integer(Item1.Data) - Integer(Item2.Data);
end;

procedure TForm1.ListView1InfoTip(Sender: TObject; Item: TListItem; var InfoTip: string);
begin
  if Item.SubItems.Count <= 0 then Exit;

  InfoTip := Item.SubItems.Strings[0];
end;

procedure TForm1.ListView1SelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  Include(ViewState, _VS_Selecting);
  try
    if Selected and (Item.Index <> iThumbItem) and not (_VS_Turning in ViewState)then
    begin
      iThumbItem := Item.Index;
      iPicture := GetPictureIndex(Item);
      ShowImage;
    end;
  finally
    Exclude(ViewState, _VS_Selecting);
  end;
end;

procedure TForm1.Image1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
label
  NoDrag;
var
  s: string;
begin
  if not ((ssShift in Shift) xor (ssCtrl in Shift)) then
    goto NoDrag;
//
//  // Check mouse button, if mouse left button only.
//  if not (ssLeft in Shift) or (ssRight in Shift) or (ssMiddle in Shift) then
//    goto NoDrag;

  if iPicture < 0 then                     goto NoDrag;
  if iPicture >= Pictures.Count then       goto NoDrag;
  if DropFileSource1.DragInProgress then   goto NoDrag;
  if DropFileSource1.Files.Count <> 0 then goto NoDrag;

  LastCursor := Mouse.CursorPos;
  if not DragDetectPlus(ScrollBox1.Handle, LastCursor) then goto NoDrag;

  case OpenType of
    _OT_Files:
    begin
      s := DirPath + Pictures.Items[iPicture].Name;
      DropFileSource1.DragTypes := [dtCopy, dtMove];
    end;
    _OT_Zip:
    begin
      s := SaveFileToTempPath(Pictures.Items[iPicture]);
      DropFileSource1.DragTypes := [dtCopy];
    end
    else goto NoDrag;
  end;

  if s.IsEmpty or not FileExists(s, False) then goto NoDrag;

  DropFileTarget1.Target := nil;
  DropFileSource1.Files.Add(s);
  DropFileSource1.Execute;
  Exit;

NoDrag:
  if (Button = mbLeft) and (DisplayMode = _DM_Original) then
  begin
    LastCursor := Mouse.CursorPos;
    CursorTracking := True;
  end;
end;

procedure TForm1.Image1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    CursorTracking := False;
  end;
  DropFileSource1.Files.Clear;
end;

procedure TForm1.Image1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
  Distance: TPoint;
begin
  if CursorTracking then
  begin
    P := Mouse.CursorPos;
    if P <> LastCursor then
    begin
      Distance := LastCursor - P;
      LastCursor := P;

      if Distance.X <> 0 then
        ScrollBox1.HorzScrollBar.Position := ScrollBox1.HorzScrollBar.Position + Distance.X;
      if Distance.Y <> 0 then
        ScrollBox1.VertScrollBar.Position := ScrollBox1.VertScrollBar.Position + Distance.Y;
    end;
  end;
end;

procedure TForm1.DropFileTarget1Drop(Sender: TObject; ShiftState: TShiftState; APoint: TPoint; var Effect: Integer);
begin
  try
    TThread.Synchronize(nil, procedure
    var
      FilePath: string;
    begin
      if DropFileSource1.DragInProgress   then Exit;
      if DropFileSource1.Files.Count  > 0 then Exit;
      if DropFileTarget1.Files.Count <> 1 then Exit;
      CloseImages;

      FilePath := DropFileTarget1.Files[0];
      if FileExists(FilePath, False) then
      begin
        if ExtractFileExt(FilePath) = '.zip' then
        begin
          DirPath := FilePath;
          OpenImagesFormZip(FilePath);
        end
        else
        begin
          DirPath := ExtractFilePath(FilePath);
          OpenImagesFormFiles(DirPath);
        end;
      end
      else
      begin
        if not DirectoryExists(FilePath, False) then Exit;

        DirPath := IncludeTrailingPathDelimiter(FilePath);
        FilePath := '';
        OpenImagesFormFiles(DirPath);
      end;

      if Pictures.Count = 0 then Exit;

      iThumbItem := -1;
      iPictureOld := -1;
      iPicture := PictureIndexOfFileName(ExtractFileName(FilePath));

      BaseThread := JvThread1.Execute(nil);
      BaseThread.Start;

      ShowImage(iPicture);
      FocusWindows;
    end);
  finally
    if (Effect = DROPEFFECT_MOVE) then Effect := DROPEFFECT_NONE;
  end;
end;

procedure TForm1.DropFileTarget1DragOver(Sender: TObject; ShiftState: TShiftState; APoint: TPoint; var Effect: Integer);
begin
  TThread.Synchronize(nil, procedure
  begin
    DropFileTarget1.Files.Clear;
  end);
end;

procedure TForm1.DropFileSource1GetDragImage(Sender: TObject;
  const DragSourceHelper: IDragSourceHelper; var Handled: Boolean);
var
  Pt: TPoint;
  h: HWND;
begin
  if GetCursorPos(Pt) then
  begin
    TThread.Synchronize(nil, procedure
    begin
      h := ScrollBox1.Handle;
    end);
    Handled:= Succeeded(DragSourceHelper.InitializeFromWindow(
      h, Pt, TCustomDropSource(Sender) as IDataObject));
  end;
end;

procedure TForm1.DropFileSource1AfterDrop(Sender: TObject; DragResult: TDragResult; Optimized: Boolean);
begin
  TThread.Synchronize(nil, procedure
  var
    Filename: string;
    HintTitle, HintMsg: string;
  begin
    if DropFileSource1.Files.Count <= 0 then Exit;

    Filename := DropFileSource1.Files[0];

    case OpenType of
      _OT_Zip:
        if string.StartsText(GetAppTempDir, Filename) then
          if FileExists(Filename, False) then
            DeleteFile(Filename);
    end;

    case DragResult of
      drDropCopy, drDropMove: ;
      else Exit;
    end;

    case OpenType of
      _OT_Files:
      case DragResult of
        drDropCopy: HintTitle := '複製檔案';
        drDropMove: HintTitle := '移動檔案';
      end;
      _OT_Zip:      HintTitle := '提取檔案';
      else Exit;
    end;
    JvBalloonHint1.UseBalloonAsApplicationHint := True;
    try
      case OpenType of
      _OT_Files: HintMsg := '來源：' + sLineBreak + IncludeTrailingPathDelimiter(DirPath) + Filename;
      _OT_Zip: HintMsg := '來源：' + DirPath + sLineBreak +
                         '提取：' + ExtractFileName(Filename);
      end;
      JvBalloonHint1.ActivateHintPos(nil, LastCursor, HintTitle, HintMsg, 2000);
    finally
      JvBalloonHint1.UseBalloonAsApplicationHint := False;
    end;
    DropFileSource1.Files.Clear;
    DropFileTarget1.Target := ScrollBox1;
  end);
end;

procedure TForm1.Splitter1CanResize(Sender: TObject; var NewSize: Integer; var Accept: Boolean);
var
  Splitter: TSplitter ABSOLUTE Sender;
  N: Integer;
begin
  if NewSize > SplitterMax then Accept := False;

  N := GetSplitterCurr;
  if (NewSize > SplitterMin) and (N < SplitterMin) then
    if Splitter.MinSize > SplitterMin then Splitter.MinSize := SplitterMin;
end;

procedure TForm1.Splitter1Moved(Sender: TObject);
var
  Splitter: TSplitter ABSOLUTE Sender;
begin
  if ListView1.Width > SplitterMin then
  begin
    Splitter.MinSize := SplitterMin;
    Splitter.Tag := ListView1.Width;
  end
  else
  begin
    Splitter.MinSize := TSplitter(Sender).Tag;
  end;

  SettingChange;
end;

procedure TForm1.SettingChange;
begin
  if Self.Showing then SettingChanged := True;
end;

procedure TForm1.UpdateSplitterMax;
begin
  SplitterMax := Self.ClientWidth - ScrollBox1.Constraints.MinWidth -
                 (ScrollBox1.Width - ScrollBox1.ClientWidth) - Splitter1.Width;
end;

function TForm1.GetSplitterCurr: Integer;
begin
  Result := Splitter1.Parent.ClientWidth - Splitter1.Left - Splitter1.Width;
end;

procedure TForm1.SplitterTo(X, Y: Integer);
var
  A, B: Cardinal;
  function GetPointCode(X, Y: Integer): Cardinal; inline;
  begin
    Result := (Y shl 16) or X;
  end;
begin
  A := GetPointCode(Splitter1.Left, Splitter1.Top);
  Splitter1.Perform(WM_LBUTTONDOWN, MK_LBUTTON, A);

  B := GetPointCode(X, Y);
  if A <> B then Splitter1.Perform(WM_MOUSEMOVE, MK_LBUTTON, B);
  Splitter1.Perform(WM_LBUTTONUP, MK_LBUTTON, B);
end;

procedure TForm1.SplitterTo(Value: Integer);
begin
  if Splitter1.Align in [alLeft, alRight] then
    SplitterTo(Value, 0)
  else
    SplitterTo(0, Value);
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  b: Boolean;
begin
  b := False;
  if _VS_ImageWating in ViewState then
  begin
    Exclude(ViewState, _VS_ImageWating);
    if iPicture <> iPictureOld then
      Caption := Format('Wating %s [%u/%u] ...', [Loading, iPicture + 1, Pictures.Count])
    else
      Caption := Format('Loading %s [%u/%u] ...', [iPicture + 1, Pictures.Count]);

    b := True;
  end;
//  else
//  begin
//    if IsLoading then
//      if OpenType <> _OT_Non then
//        ShowLoadingInfo;
//  end;
  if _VS_SizeChanged in ViewState then
  begin
    Exclude(ViewState, _VS_SizeChanged);
    b := True;
  end;

  if b then Exit;

  if ListView1.Items.Count = 0 then
  begin
    Exit;
  end;

  TTimer(Sender).Enabled := False;
  if ListView1.ItemIndex < 0 then
    ListView1.ItemIndex := 0
  else
    ShowImage;
end;

procedure TForm1.Timer2Timer(Sender: TObject);
begin
  if not (_VS_Resizing in ViewState) then
  begin
    StaticText1.Visible := False;
    TTimer(Sender).Enabled := False;
  end;
end;

procedure TForm1.Timer3Timer(Sender: TObject);
begin
  NextWICImage;
end;

procedure TForm1.PopupMenu1Popup(Sender: TObject);
begin
  N4.Enabled := OpenType <> _OT_Non;
  N6.Enabled := OpenType <> _OT_Non;
  N7.Enabled := OpenType = _OT_Files;
end;

// 切換 原始/最佳 大小
// Toggle original/best size.
procedure TForm1.N1Click(Sender: TObject);
var
  Size: TSize;
  Point: TPoint;
begin
  if not GetCurrentImageSize(Size) then Exit;

  Point := PopupMenu1.PopupPoint;
  if (Point.X < 0) or (Point.X > Size.Width)  then Point.X := 0;
  if (Point.Y < 0) or (Point.Y > Size.Height) then Point.Y := 0;

  ViewOriginal(Point);
end;

// 依影像放大視窗
// Enlarge window by image.
procedure TForm1.N2Click(Sender: TObject);
var
  SizeF, SizeI, Size: TSize;
  R, M: TRect;
begin
  if not GetCurrentImageSize(SizeI) then Exit;

  SizeF := TSize.Create(Self.Width - Self.ClientWidth, Self.Height - Self.ClientHeight);
  if GetReduceSize(Monitor.Width - SizeF.Width, Monitor.Height - SizeF.Height, SizeI.Width, SizeI.Height, True, Size) then
  begin
    Size := Size + SizeF;
    Size.Width := Size.Width + Splitter1.Width + ListView1.Width;
    if Size.Width  > Monitor.Width  then Size.Width  := Monitor.Width;
    if Size.Height > Monitor.Height then Size.Height := Monitor.Height;

    R := TRect.Create(Self.Left, Self.Top, Size.Width + Self.Left, Size.Height + Self.Top);
    M := Monitor.BoundsRect;

    if R.Right > M.Right then
    begin
      R.Left := R.Left - (R.Right - M.Right);
      R.Right := M.Right;
    end;

    if R.Left < M.Left then
    begin
      R.Right := R.Right + (M.Left - R.Left);
      R.Left := M.Left;
    end;

    if R.Bottom > M.Bottom then
    begin
      R.Top := R.Top - (R.Bottom - M.Bottom);
      R.Bottom := M.Bottom;
    end;

    if R.Top < M.Top then
    begin
      R.Bottom := R.Bottom + (M.Top - R.Top);
      R.Top := M.Top;
    end;

    Self.SetBounds(R.Left, R.Top, R.Width, R.Height);
  end;
end;

procedure TForm1.N4Click(Sender: TObject);
begin
  case OpenType of
    _OT_Files:
    begin
      if (iPicture >= 0) and (iPicture < Pictures.Count) then
        BrowseByExplorer(DirPath, Pictures.Items[iPicture].Name, _FEO_All);
    end;
    _OT_Zip:
      BrowseByExplorer(ExtractFileDir(DirPath), ExtractFileName(DirPath), _FEO_All);
  end;
end;

procedure TForm1.N6Click(Sender: TObject);
begin
  case OpenType of
    _OT_Files, _OT_Zip: DoCopyFileToClipboard(False);
  end;
end;

procedure TForm1.N7Click(Sender: TObject);
begin
  case OpenType of
    _OT_Files: DoCopyFileToClipboard(True);
  end;
end;

procedure TForm1.ViewTipMode(bBlatant: Boolean);
begin
  if bBlatant then
  begin
    StaticText1.BorderStyle := sbsSingle;
//    StaticText1.Font.Size := 12;
  end
  else
  begin
    StaticText1.BorderStyle := sbsNone;
//    StaticText1.Font.Size := 12;
  end;
end;

procedure TForm1.ViewTipAdjust(bCentral: Boolean);
begin
  if bCentral then
  begin
    StaticText1.Left := ScrollBox1.Left + (ScrollBox1.ClientWidth - StaticText1.Width) div 2;
    StaticText1.Top := ScrollBox1.Top + (ScrollBox1.ClientHeight - StaticText1.Height) div 2;
  end
  else
  begin
    StaticText1.Left := ScrollBox1.Left + ScrollBox1.ClientWidth - StaticText1.Width;
    StaticText1.Top := ScrollBox1.Top + ScrollBox1.ClientHeight - StaticText1.Height;
  end;
end;

procedure TForm1.ViewSizeTip;
begin
  StaticText1.Caption := Format('%u x %u ', [Self.ClientWidth, Self.ClientHeight]);
end;

procedure TForm1.WndProc(var Message: TMessage);
begin
  inherited;
  case Message.Msg of
    WM_ENTERSIZEMOVE:
    begin
      Include(ViewState, _VS_Resizing);
    end;
    WM_EXITSIZEMOVE:
    begin
      Exclude(ViewState, _VS_Resizing);
      UpdateSplitterMax;
      Timer2.Enabled := True;
    end;
  end;
end;

procedure TForm1.FocusWindows;
var
  Param: Integer;
begin
  if IsIconic(Application.Handle) then
    ShowWindow(Application.Handle, SW_RESTORE)
  else
  begin
    Param := 0;
    SystemParametersInfo(SPI_SETFOREGROUNDLOCKTIMEOUT, 0, Param, SPIF_SENDCHANGE);
    SetForegroundWindow(Application.MainForm.Handle);
  end;
end;

procedure TForm1.SetLayoutSize(Width, Height: Integer);
var
  Max: Integer;
begin
  Max := ScrollBox1.ClientWidth;
  if Width  > Max then Image1.Width  := Max else Image1.Width  := Width;
  Max := ScrollBox1.ClientHeight;
  if Height > Max then Image1.Height := Max else Image1.Height := Height;
end;

procedure TForm1.ShowTip(const Text: string; Seconds: Byte; Color: TColor);
begin
  StaticText1.Caption := Text;
  ViewTipMode(True);
  ViewTipAdjust(True);
  StaticText1.Show;
  Timer2.Interval := Seconds * 1000;
  Timer2.Enabled := True;
end;

procedure TForm1.ShowLoadingInfo;
var
  I: Integer;
begin
  I := iPicture;
//  ViewTipMode(False);
//  ViewTipAdjust(False);
  Caption := Format('%s[%u/%u] %s << %s', [Loading, I + 1, Pictures.Count, Pictures.Names[I], Title]);
end;

// 依影像放大視窗
// Adjust the window to fit the image size.
function TForm1.GetCurrentImageSize(out Size: TSize): Boolean;
var
  Image: TImageItem;
begin
  Result := Pictures.Count > 0;
  if Result then
  begin
    Image := Pictures.GetImageItem(iPicture);
    case Image.Mode of
      _PIT_WIC: Size := TSize.Create(Image.Slot.WIC.Width, Image.Slot.WIC.Height);
      _PIT_GIF: Size := TSize.Create(Image.Slot.GIF.Width, Image.Slot.GIF.Height);
      else
        Result := False;
    end;
  end;
end;

function TForm1.GetReduceSize(MaxWidth, MaxHeight, Width, Height: Integer; Inward: Boolean; out Size: TSize): Boolean;
  procedure GetScaledByWidth;
  begin
    Size.Width := MaxWidth;
    Size.Height := Round(MaxWidth / Width * Height);
  end;
  procedure GetScaledByHeight;
  begin
    Size.Width := Round(MaxHeight / Height * Width);
    Size.Height := MaxHeight;
  end;
begin
  if Width > MaxWidth then
  begin
    if Height > MaxHeight then
      if Width > Height then
      begin
        GetScaledByWidth;
        if Inward and (Size.Height > MaxHeight) then GetScaledByHeight;
      end
      else
      begin
        GetScaledByHeight;
        if Inward and (Size.Width > MaxWidth) then GetScaledByWidth;
      end
    else
      GetScaledByWidth;
    Result := True;
  end
  else
  if Height > MaxHeight then
  begin
    if Width > MaxWidth then
      if Height > Width then
      begin
        GetScaledByHeight;
        if Inward and (Size.Width > MaxWidth) then GetScaledByWidth;
      end
      else
      begin
        GetScaledByWidth;
        if Inward and (Size.Height > MaxHeight) then GetScaledByHeight;
      end
    else
      GetScaledByHeight;

    Result := True;
  end
  else
  begin
    Size.Width := Width;
    Size.Height := Height;
    Result := False;
  end;
end;

function TForm1.GetReduceSize(Width, Height: Integer; out Size: TSize): Boolean;
begin
  Result := GetReduceSize(Limit.Width, Limit.Height, Width, Height, False, Size);
end;

function TForm1.GetReduceInView(const PicItem: TPictureItem; Inward: Boolean; out Size: TSize): Boolean;
begin
  case PicItem.Image.Mode of
    _PIT_WIC:
      Result := GetReduceSize(ScrollBox1.ClientWidth, ScrollBox1.ClientHeight,
                  PicItem.Image.Slot.WIC.Width, PicItem.Image.Slot.WIC.Height,
                  True, Size);
    _PIT_GIF:
      Result := GetReduceSize(ScrollBox1.ClientWidth, ScrollBox1.ClientHeight,
                  PicItem.Image.Slot.GIF.Width, PicItem.Image.Slot.GIF.Height,
                  True, Size);
    _PIT_MultiWIC:
      Result:= GetReduceSize(ScrollBox1.ClientWidth, ScrollBox1.ClientHeight,
                 PicItem.Image.Slot.Multi.First.Width, PicItem.Image.Slot.Multi.First.Height,
                 True, Size);
    else Result := False;
  end;
end;

function TForm1.SaveFileToTempPath(const PictureItem: TPictureItem): string;
var
  TempDir, Filename: string;
  Stream: TFileStream;
  ImageItem: TImageItem;
begin
  Result := '';
  TempDir := GetAppTempDir;
  if not DirectoryExists(TempDir, False) then
    TDirectory.CreateDirectory(TempDir);

  Filename := TempDir + ExtractFileName(Pictures.Items[iPicture].Name);

  // Create a file, if the file exists, open it in write mode to override the file.
  Stream := TFileStream.Create(Filename, fmCreate, fmShareDenyWrite);
  if not Assigned(Stream) then Exit;
  try
    Stream.Seek(0, soBeginning);
    FillChar(ImageItem, SizeOf(TImageItem), 0);
    if LoadOriginal(PictureItem, ImageItem, -1, Stream) then
      Result := Filename;
  finally
    Stream.Free;
  end;
end;

procedure CopyStream(Source, Target: TStream; Size: UInt32); inline;
begin
  Target.Size := Size;
  Target.Position := 0;
  Target.CopyFrom(Source, Size);
end;

procedure LoadGifFromStream(Source: TStream; Gif: TGIFImage); inline;
begin
  Source.Position := 0;
  Gif.LoadFromStream(Source);
end;

procedure TForm1.LoadImage(var ImageItem: TImageItem; Stream: TStream; FrameIndex: Integer);
var
  Mode: TImageType;
  WIC: TWICImage;
  Gif: TGIFImage;
begin
  Mode := ImageItem.Mode;
  FillChar(ImageItem, SizeOf(ImageItem), 0);
  Stream.Position := 0;
  Gif := nil;
  WIC := TWICImage.Create;
  try
    if FrameIndex > 0 then WIC.FrameIndex := FrameIndex;
    WIC.LoadFromStream(Stream);
    case WIC.ImageFormat of
      wifGif:
      begin
        case Mode of
          _PIT_OBJ, _PIT_GIF:
          begin
            Gif := TGIFImage.Create;
            LoadGifFromStream(Stream, Gif);
            if Gif.Images.Count > 0 then
            begin
              FreeAndNil(WIC);
              ImageItem.Slot.GIF := Gif;
              Gif := nil;
              ImageItem.Mode := _PIT_GIF;
              Exit;
            end;
          end;
        end;
      end;
      wifOther:
      begin
        if WIC.FrameCount > 1 then
        begin
          FreeAndNil(WIC);
          ImageItem.Slot.Multi := TWICImages.Create;
          ImageItem.Slot.Multi.LoadFromStream(Stream);
          ImageItem.Mode := _PIT_MultiWIC;
          Exit;
        end;
      end;
    end;
    ImageItem.Slot.WIC := WIC;
    WIC := nil;
    ImageItem.Mode := _PIT_WIC;
  finally
    if Assigned(WIC) then WIC.Free;
    if Assigned(Gif) then Gif.Free;
  end;
end;

function TForm1.LoadOriginal(const FileItem: TPictureItem; var ImageItem: TImageItem; FrameIndex: Integer; Buffer: TStream): Boolean;
var
  Stream: TStream;
  DataStream: TStream;
  Header: TZipHeader;
begin
  if Assigned(Buffer) then
    DataStream := Buffer
  else
    DataStream := TMemoryStream.Create;
  try          
    try
      case OpenType of
        _OT_Files:
        begin
          if DataStream is TMemoryStream then
            TMemoryStream(DataStream).LoadFromFile(DirPath + FileItem.Name)
          else if DataStream is TFileStream then
          begin
            // 事實上這裡應該不需要，至少目前這隻程式的功能不會使用到，
            // 因為，在此函數前將直接使用系統 API 來處理 移動 或 複製 檔案。
            // + 檔案資料複製
            Stream := TFileStream.Create(DirPath + FileItem.Name, fmOpenRead, fmShareDenyWrite);
            try
              DataStream.CopyFrom(Stream);
            finally
              Stream.Free;
            end;
            // - 檔案資料複製
          end
          else
            raise Exception.CreateFmt('Unknown stream class "%s".', [DataStream.ClassName]);
        end;
        _OT_Zip:
        begin
          EnterCriticalSection(ZipCS);
          try
            try
              Zip.Read(FileItem.ID, Stream, Header); // 取得壓縮檔中目標資料串流
              CopyStream(Stream, DataStream, Header.UncompressedSize); // 解碼(解壓縮)資料
            finally
              // 由 Zip.Read 中建立傳出的 Stream 是一個包裝著解碼函數的 Object class，
              // 雖不是資料本身，但仍然是 Object class 有占用記憶體空間，也是需要釋放的。
              if Assigned(Stream) then FreeAndNil(Stream);
            end;
          finally
            LeaveCriticalSection(ZipCS);
          end;
        end;
        else
        begin
          Exit(False);
        end;
      end;
      if not (DataStream is TFileStream) then
        LoadImage(ImageItem, DataStream, FrameIndex);
    except
      on E: Exception do
      begin
        {$IFDEF DEBUG}
        DbgMsg('Load [%d] failure: %s' + sLineBreak + '%s', [FileItem.ID, FileItem.Name, E.Message]);
        {$ENDIF DEBUG}
        Exit(False);
      end;
    end;
  finally
    if Assigned(Buffer) then
    begin
      if Buffer is TMemoryStream then
        TMemoryStream(Buffer).SetSize(0);
//      else if Buffer is TFileStream then
//        TFileStream(Buffer).Position := 0;
    end
    else
      FreeAndNil(DataStream);
  end;
  Result := True;
//  Result := (ImageItem.Mode <> _PIT_OBJ) and Assigned(ImageItem.Slot.Obj);
end;

function TForm1.LoadPicture(Index: Integer): Boolean;
var
  PicItem: TPictureItem;
  Image: TImageItem;
  bWIC: Boolean;
  WIC: TWICImage;
  Thumbnail: TWICImage;
  iThumbnail: Integer;
  Item: TListItem;
  Size: TSize;
  B: Boolean;
  BmpBuf: TBitmap;
begin
  FillChar(Image, SizeOf(TImageItem), 0);

  TThread.Synchronize(BaseThread, procedure
  begin
    ShowLoadingInfo;
    PicItem := Pictures.Items[Index];
  end);

  if PicItem.Image.Assigned then
  begin
{$IFDEF DEBUG}
      DbgMsg('Image field %d is occupied.', [PicItem.ID]);
{$ENDIF DEBUG}
    Exit(False);
//    raise Exception.CreateFmt('Image field %d is occupied.', [PicItem.ID]);
  end;

  if not LoadOriginal(PicItem, Image, -1, MemBuf) then
  begin
{$IFDEF DEBUG}
      DbgMsg('Image[%d]: %s loading failed.', [PicItem.ID, PicItem.Name]);
{$ENDIF DEBUG}
    Exit(False);
//    raise Exception.CreateFmt('Image[%d]: %s loading failed.', [PicItem.ID, PicItem.Name]);
  end;

  bWIC := False;
  WIC := nil;

  B := True;
  Thumbnail := nil;
  iThumbnail := -1;
  try
    case Image.Mode of
      _PIT_WIC:
      begin
        B := GetReduceSize(Image.Slot.WIC.Width, Image.Slot.WIC.Height, Size);
        B := B and not (Image.Slot.WIC.FrameCount > 1);
        if B then
          WIC := Image.Slot.WIC.CreateScaledCopy(Size.Width, Size.Height, wipmHighQualityCubic)
        else
          WIC := Image.Slot.WIC;
      end;
      _PIT_GIF:
      begin
        bWIC := True;
        WIC := TWICImage.Create;
        TThread.Synchronize(BaseThread, procedure
        begin
          WIC.Assign(Image.Slot.Gif);
        end);
//        WIC.Assign(Image.Slot.Gif);
      end;
      _PIT_MultiWIC:
      begin
        B := False;
        WIC := Image.Slot.Multi.Current;
      end;
      else
      begin
        B := False;
      end;
    end;

    if not Assigned(WIC) then
    begin
{$IFDEF DEBUG}
      DbgMsg('Image[%d]: %s loading 2 failed.', [PicItem.ID, PicItem.Name]);
{$ENDIF DEBUG}
      Exit(False);
//      raise Exception.CreateFmt('Image[%d]: %s loading 2 failed.', [PicItem.ID, PicItem.Name]);
    end;

    if GetReduceSize(ThumbSize.Width, ThumbSize.Height, WIC.Width, WIC.Height, True, Size) then
    begin
      Thumbnail := WIC.CreateScaledCopy(Size.Width, Size.Height, wipmHighQualityCubic);
      if not Assigned(Thumbnail) then
      begin
{$IFDEF DEBUG}
        DbgMsg('Image[%d]: %s thumbnail failed.', [PicItem.ID, PicItem.Name]);
{$ENDIF DEBUG}
        Exit(False);
//        raise Exception.CreateFmt('Image[%d]: %s thumbnail failed.', [PicItem.ID, PicItem.Name]);
      end;
    end;

//    if Assigned(Gif) then
//    begin
//      if Image.Assigned then Image.Free;
//      Image.Slot.GIF := Gif;
//      Gif := nil;
//      Image.Mode := _PIT_GIF;
//    end;

//    SrcRect := TRect.Create(0,  Thumbnail.Width, Thumbnail.Height);
//    DstRect := TRect.Create(0, 0,0, ThumbSize.Width, ThumbSize.Height);

    TThread.Synchronize(BaseThread, procedure
    begin

      if Assigned(Thumbnail) then
      begin
        BmpBuf := TBitmap.Create(ThumbSize.Width, ThumbSize.Height);
        try
          BmpBuf.Canvas.Lock;
          BmpBuf.Canvas.Draw((ThumbSize.Width - Thumbnail.Width) div 2, (ThumbSize.Height - Thumbnail.Height) div 2, Thumbnail);
          iThumbnail := ImageList_Add(ImageList1.Handle, BmpBuf.Handle, 0);
        finally
          BmpBuf.Canvas.Unlock;
          BmpBuf.Free;
        end;
      end;

      if B then
      begin
        case Image.Mode of
          _PIT_WIC:
          begin
            Pictures.SetWIC(Index, WIC);
            WIC := nil;
          end;
          _PIT_GIF:
          begin
            Pictures.SetGIF(Index, Image.Slot.Gif);
            Image.Slot.Gif := nil;
          end;
          _PIT_MultiWIC:
          begin
            Pictures.SetMultiWIC(Index, Image.Slot.Multi);
            Image.Slot.Multi := nil;
          end;
        end;
      end
      else
      begin
        case Image.Mode of
          _PIT_WIC:
          begin
            Pictures.SetWIC(Index, Image.Slot.WIC);
            Image.Slot.WIC := nil;
          end;
          _PIT_GIF:
          begin
            Pictures.SetGIF(Index, Image.Slot.Gif);
            Image.Slot.Gif := nil;
          end;
          _PIT_MultiWIC:
          begin
            Pictures.SetMultiWIC(Index, Image.Slot.Multi);
            Image.Slot.Multi := nil;
          end;
        end;
      end;

      ListView1.Items.BeginUpdate;
      try
        Item := ListView1.Items.Add;
        Item.Data := Pointer(NativeInt(Index));
        Pictures.ThumbItem[Index] := Item;
        Item.ImageIndex := iThumbnail;
        Item.Caption := IntToStr(Index + 1);
        Item.SubItems.Add(PicItem.Name);
  //      DbgMsg('Add thumbnail[%d]: ImageList %d, ListView %d', [Index, iThumbnail, Item.Index]);
      finally
        ListView1.Items.EndUpdate;
      end;
    end);

    Result := True;
  finally            
    if Assigned(Thumbnail) then
      FreeAndNil(Thumbnail);

    if bWIC then
      if Assigned(WIC) then WIC.Free;

    if Image.Assigned then Image.Free;
  end;
end;

procedure TForm1.SetTimerImageWating;
begin
  Include(ViewState, _VS_ImageWating);
  Timer1.Enabled := True;
end;

function TForm1.ShowImage(Index: TPictureIndex; Mode: TDisplayMode): Boolean;
var
  Size: TSize;
  b: Boolean;
  PicItem: TPictureItem;
//  PicItemOld: TPictureItem;
  WIC: TWICImage;
begin
  Result := False;
  if Index <> iPicture then Exit;
  if Index < 0 then Exit;
  if Closeing  then Exit;

  b := False;
  try
    FillChar(PicItem, SizeOf(PicItem), 0);
    PicItem := Pictures.Items[Index];
  except on E: Exception do
{$IFDEF DEBUG}
    DbgMsg('Item[%d/%d]: ' + sLineBreak + '%s', [Index + 1, Pictures.Count, E.Message]);
{$ENDIF DEBUG}
  end;

  if PicItem.Image.Mode = _PIT_OBJ        then b := True
  else if not PicItem.Image.Assigned      then b := True
  else if not Assigned(PicItem.ThumbItem) then b := True;

  if b then
  begin
    SetTimerImageWating;
    Exit;
  end;

  if ListView1.Items.Count = 0 then Exit;

  if iPictureOld >= 0 then
  begin
    if Image1.Picture.Graphic is TGIFImage then
      TGIFImage(Image1.Picture.Graphic).Animate := False;
//    FillChar(PicItemOld, SizeOf(PicItemOld), 0);
//    try
//      PicItemOld := Pictures.Items[iPictureOld];
//      case PicItemOld.Image.Mode of
//        _PIT_GIF:
//        begin
//          if PicItemOld.Image.Assigned then
//          begin
//            PicItemOld.Image.Slot.GIF.Animate := False;
//          end;
//        end;
//      end;
//    except on E: Exception do
//    end;
//    iPictureOld := -1;
  end;

  if iPictureOld <> Index then
  begin
    if PicItem.Image.Mode = _PIT_MultiWIC then
      PicItem.Image.Slot.Multi.FrameIndex := 0
    else
      Timer3.Enabled := False;
  end;

  if ImageView.Assigned then ImageView.Free;

  if Mode = _DM_Original then
  begin
    Image1.Stretch := False;
    Image1.Proportional := False;
    b := False;
    case PicItem.Image.Mode of
      _PIT_WIC:
      if LoadOriginal(PicItem, ImageView, 0) then
      begin
        Timer3.Enabled := False;
        WIC := ImageView.Slot.WIC;
        Image1.Width := WIC.Width;
        Image1.Height := WIC.Height;
        Image1.Picture.WICImage := WIC;
        b := True;
      end;
      _PIT_GIF:
      if LoadOriginal(PicItem, ImageView, 0) then
      begin
        Timer3.Enabled := False;
        Image1.Width := ImageView.Slot.GIF.Width;
        Image1.Height := ImageView.Slot.GIF.Height;
        Image1.Picture.Graphic := ImageView.Slot.GIF;
        if Image1.Picture.Graphic is TGIFImage then
          TGIFImage(Image1.Picture.Graphic).Animate := True;
        b := True;
      end;
      _PIT_MultiWIC:
      if LoadOriginal(PicItem, ImageView, PicItem.Image.Slot.Multi.FrameIndex) then
      begin
        WIC := ImageView.Slot.Multi.Current;
        Image1.Width := WIC.Width;
        Image1.Height := WIC.Height;
        Image1.Picture.WICImage := WIC;
        Timer3.Enabled := True;
        b := True;
      end;
      else
      begin
        Timer3.Enabled := False;
      end;
    end;
    if b then
    begin
      DisplayMode := Mode;
    end
    else
    begin
      case OpenType of
        _OT_Files, _OT_Zip:
        begin
          ShowMessageFmt('無法載入影像：'+sLineBreak+'%s', [IncludeTrailingPathDelimiter(DirPath) + PicItem.Name]);
        end;
        else ShowMessage('未開啟檔案！');
      end;
    end;
    ShowLoadingInfo;
    Exit(b);
  end;

  if GetReduceInView(PicItem, True, Size) then
  begin
    Image1.Width := Size.Width;
    Image1.Height := Size.Height;
    case PicItem.Image.Mode of
      _PIT_WIC:
      begin
        Timer3.Enabled := False;
        ImageView.Slot.WIC := PicItem.Image.Slot.WIC.CreateScaledCopy(Size.Width, Size.Height, wipmHighQualityCubic);
        ImageView.Mode := _PIT_WIC;
        Image1.Stretch := False;
        Image1.Proportional := False;
        Image1.Picture.WICImage := ImageView.Slot.WIC;
      end;
      _PIT_GIF:
      begin
        Timer3.Enabled := False;
        Image1.Proportional := True;
        Image1.Stretch := True;
        Image1.Picture.Graphic := PicItem.Image.Slot.GIF;
        if Image1.Picture.Graphic is TGIFImage then
          TGIFImage(Image1.Picture.Graphic).Animate := True;
      end;
      _PIT_MultiWIC:
      begin
        ImageView.Slot.WIC := PicItem.Image.Slot.Multi.Current.CreateScaledCopy(Size.Width, Size.Height, wipmHighQualityCubic);
        ImageView.Mode := _PIT_WIC;
        Image1.Stretch := False;
        Image1.Proportional := False;
        Image1.Picture.WICImage := ImageView.Slot.WIC;
        Timer3.Enabled := True;
      end;
      else
      begin
        Timer3.Enabled := False;
      end;
    end;
  end
  else
  begin
    Image1.Stretch := False;
    Image1.Proportional := False;
    case PicItem.Image.Mode of
      _PIT_WIC:
      begin
        Timer3.Enabled := False;
        SetLayoutSize(PicItem.Image.Slot.WIC.Width, PicItem.Image.Slot.WIC.Height);
        Image1.Picture.WICImage := PicItem.Image.Slot.WIC;
      end;
      _PIT_GIF:
      begin
        Timer3.Enabled := False;
        SetLayoutSize(PicItem.Image.Slot.GIF.Width, PicItem.Image.Slot.GIF.Height);
        Image1.Picture.Graphic := PicItem.Image.Slot.GIF;
        if Image1.Picture.Graphic is TGIFImage then
          TGIFImage(Image1.Picture.Graphic).Animate := True;
      end;
      _PIT_MultiWIC:
      begin
        WIC := PicItem.Image.Slot.Multi.Current;
        ImageView.Slot.WIC := TWICImage.Create;
        ImageView.Slot.WIC.Assign(WIC);
        ImageView.Mode := _PIT_WIC;
        SetLayoutSize(ImageView.Slot.WIC.Width, ImageView.Slot.WIC.Height);
        Image1.Picture.WICImage := ImageView.Slot.WIC;
        Timer3.Enabled := True;
      end;
      else
      begin
        Timer3.Enabled := False;
      end;
    end;
  end;
  DisplayMode := Mode;
  ShowLoadingInfo;
  iPictureOld := Index;
  Result := True;
end;

function TForm1.ShowImage(Index: TItemIndex; Mode: TDisplayMode): Boolean;
begin
  Result := ShowImage(GetPictureIndex(Index), Mode);
end;

function TForm1.ShowImage(Mode: TDisplayMode): Boolean;
begin
  if Assigned(Pictures) then
    Result := ShowImage(iPicture, Mode)
  else
    Result := False;
end;

function TForm1.ShowImage: Boolean;
begin
  Result := ShowImage(DisplayMode);
end;

procedure TForm1.ViewOriginal(const Point: TPoint);
var
  RP: TPoint;
  W, H: Integer;
  Scale: Single;
  ScrollClient: TSize;
begin
  W := Image1.Width;
  H := Image1.Height;

  if DisplayMode = _DM_Original then
    ShowImage(_DM_Suitable)
  else
    ShowImage(_DM_Original);

  if W > H then Scale := Image1.Width / W else Scale := Image1.Height / H;

  ScrollClient := ScrollBox1.ClientRect.Size;

  RP.X := Round(Point.X * Scale) - (ScrollClient.Width div 2);
  RP.Y := Round(Point.Y * Scale) - (ScrollClient.Height div 2);

  ScrollBox1.HorzScrollBar.Position := RP.X;
  ScrollBox1.VertScrollBar.Position := RP.Y;
end;

procedure TForm1.ViewOriginal;
begin
  ViewOriginal(Image1.ScreenToClient(Mouse.CursorPos));
end;

procedure TForm1.NextWICImage;
var
  PicItem: TPictureItem;
  WIC: TWICImage;
  Size: TSize;
begin
  FillChar(PicItem, SizeOf(PicItem), 0);
  PicItem := Pictures.Items[iPicture];
  case PicItem.Image.Mode of
    _PIT_MultiWIC:
    begin
      PicItem.Image.Slot.Multi.Next;
      ShowImage;
    end
    else
      Timer3.Enabled := False;
  end;
  Exit;

  FillChar(PicItem, SizeOf(PicItem), 0);
  PicItem := Pictures.Items[iPicture];
  case PicItem.Image.Mode of
    _PIT_MultiWIC:
    begin
      PicItem.Image.Slot.Multi.Next;
      WIC := PicItem.Image.Slot.Multi.Current;

      if DisplayMode = _DM_Original then
      begin
        Image1.Width  := WIC.Width;
        Image1.Height := WIC.Height;
        Image1.Picture.WICImage := WIC;
      end
      else
      begin
        if GetReduceInView(PicItem, True, Size) then
        begin
          if ImageView.Assigned then ImageView.Free;
          ImageView.Slot.WIC := WIC.CreateScaledCopy(Size.Width, Size.Height, wipmHighQualityCubic);
          ImageView.Mode := _PIT_WIC;
          Image1.Picture.WICImage := ImageView.Slot.WIC;
        end
        else
        begin
          SetLayoutSize(WIC.Width, WIC.Height);
          Image1.Picture.WICImage := WIC;
        end;
      end;
    end;
    else
    begin
      Timer3.Enabled := False;
    end;
  end;
end;

procedure TForm1.TurnPage(Turn: TTurnPage);
var
  ListCount: Integer;
  I, J: Integer;
  ThumbItem: TListItem;
  LVItem: TLVItem;
begin
  Include(ViewState, _VS_Turning);
  try
    ListCount := ListView1.Items.Count;
    I := iThumbItem;
{$IFDEF DEBUG}
    DbgMsg('Scroll %d/%d.', [I, ListCount]);
{$ENDIF DEBUG}
    if ListCount < 1  then Exit;
//    if I >= ListCount then Exit;
    case Turn of
      _TP_First: I := 0;
      _TP_Last: I := ListCount - 1;
      _TP_Prev: if I < 1 then I := ListCount - 1 else Dec(I);
      _TP_Next: if I >= (ListCount - 1) then I := 0 else Inc(I);
      else Exit;
    end;
    J := GetPictureIndex(I);
    ThumbItem := Pictures.ThumbItem[J];
    if not Assigned(ThumbItem) then
      Exit
    else
      if ListView1.Items.IndexOf(ThumbItem) < 0 then Exit;
    iThumbItem := I;
    IPicture := J;
{$IFDEF DEBUG}
    DbgMsg('Scroll to %d.', [iThumbItem]);
{$ENDIF DEBUG}
    CtlScrollTo(ListView1, I);
    LVItem.stateMask := LVIS_SELECTED or LVIS_FOCUSED;
    LVItem.state     := LVIS_SELECTED or LVIS_FOCUSED;
    ListView1.Perform(LVM_SETITEMSTATE, I, LPARAM(@LVItem));
    ShowImage;
  finally
    Exclude(ViewState, _VS_Turning);
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  SplitterTo(Self.ClientWidth - Splitter1.Width);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  NextWICImage;
end;

procedure TForm1.CloseImages;
begin
  Caption := 'Closing...';
  Timer3.Enabled := False;
  Application.ProcessMessages;

  JvThread1.TerminateWaitFor(False);

  if Assigned(Pictures) then Pictures.Clear;

  ListView1.Clear;
  ImageList1.Clear;
  
  if Assigned(Zip) then
  begin
    DeleteCriticalSection(ZipCS);
    FreeAndNil(Zip);
  end;

  if ImageView.Assigned then ImageView.Free;

  if Image1.Picture.Graphic is TGIFImage then
    TGIFImage(Image1.Picture.Graphic).Animate := False;
  Image1.Picture.Graphic := nil;

  Caption := 'Closed.';
end;

function TForm1.ComparePictureItem(const Left, Right: TPictureItem): Integer;
begin
  Result := CompareName(Left.Name, Right.Name);
  if Result = 0 then
    Result := Left.ID - Right.ID;
end;

procedure TForm1.OpenImagesFormFiles(const Directory: string);
var
  I: Integer;
  function GetLastFolderName(str: string): string; inline;
  var
    iChar: Integer;
  begin
    Result := ExtractFileName(str);
    while Result.IsEmpty do
    begin
      iChar := str.LastIndexOf('\');
      SetLength(str, iChar);
      Result := ExtractFileName(str);
    end;
  end;
begin
  Title := GetLastFolderName(Directory);
  I := 0;
  EnumFiles(Directory,
    procedure(const FileName: string)
    begin
      if CheckExt(FileName) then
      begin
        Pictures.Add(I, FileName);
        Inc(I);
      end;
    end);
  Pictures.Sort;
  OpenType := _OT_Files;
end;

procedure TForm1.OpenImagesFormZip(const Path: string);
var
  Infos: TArray<TZipHeader>;
  Count: Integer;
  I, J: Integer;
  Item: TPictureItem;
  FileName: string;
begin
  if Assigned(Zip) then
  begin
  //raise Exception.Create('Zip is not nil, it seems that the previous has not been released, this shouldn''t happen.');
    FreeAndNil(Zip);
  end;

  Title := ChangeFileExt(ExtractFileName(Path), '');

  InitializeCriticalSection(ZipCS);
  Zip := TZipFile.Create;
  Zip.Open(Path, zmRead);
  Infos := Zip.FileInfos;
  Count := Length(Infos);
  Pictures.Count := Count;
  Item.Image.Mode := _PIT_OBJ;
  Item.Image.Slot.Obj := nil;
  J := 0;
  for I := 0 to Count - 1 do
  begin
    if Infos[I].ExternalAttributes and FILE_ATTRIBUTE_DIRECTORY = 0 then
    begin
      if Infos[I].UTF8Support then
        FileName := TEncoding.UTF8.GetString(Infos[I].FileName)
      else if Zip.Encoding.CodePage = 437 then
        FileName := UTF8ArrayToString(Infos[I].FileName)
      else
        FileName := Zip.Encoding.GetString(Infos[I].FileName);

      FileName := FileName.Replace('/', PathDelim);

      if CheckExt(FileName) then
      begin
        Item.ID := I;
        Item.Name := FileName;
        Pictures.Items[J] := Item;
        Inc(J);
      end;
    end;
  end;
  Pictures.Count := J;
  Pictures.Sort;
  OpenType := _OT_Zip;
end;

function TForm1.PictureIndexOfFileName(const FileName: string): Integer;
var
  Count: Integer;
  I: Integer;
begin
  Count := Pictures.Count;
  if Count = 0 then Exit(-1);

  if not FileName.IsEmpty then
    for I := 0 to Count - 1 do
      if CompareText(Pictures.Names[I], FileName) = 0 then
        Exit(I);
  Result := 0;
end;

function TForm1.GetPictureIndex(ThumbItem: TListItem): TPictureIndex;
begin
  Result := Integer(NativeInt(ThumbItem.Data));
end;

function TForm1.GetPictureIndex(ThumbItemIndex: TItemIndex): TPictureIndex;
begin
  if (ThumbItemIndex >= 0) and (ThumbItemIndex < ListView1.Items.Count) then
    Result := GetPictureIndex(ListView1.Items[ThumbItemIndex])
  else
    Result := -1;
end;

function TForm1.GetThumbItemIndex(PictureIndex: TPictureIndex): TItemIndex;
var
  Item: TListItem;
begin
  if (PictureIndex >= 0) and (PictureIndex < Pictures.Count) then
  begin
    Item := Pictures.List[PictureIndex].ThumbItem;
    if Assigned(Item) then
      Exit(Item.Index);
  end;
  Result := -1;
end;

procedure TForm1.DoCopyFileToClipboard(bMove: Boolean);
var
  s: string;
begin
  if iPicture < 0 then Exit;
  if iPicture >= Pictures.Count then Exit;

  SaveFileToTempPath(Pictures.Items[iPicture]);
  case OpenType of
    _OT_Files:
    begin
      s := DirPath + Pictures.Items[iPicture].Name;
      CopyFileToClipboard(s, bMove);
      if bMove then ShowTip('已移動檔案') else ShowTip('已複製檔案');
    end;
    _OT_Zip:
    begin
      s := SaveFileToTempPath(Pictures.Items[iPicture]);
      CopyFileToClipboard(s, True);
      ShowTip('已提取檔案');
    end;
  end;
end;

procedure TForm1.JvThread1Begin(Sender: TObject);
begin
  IsLoading := True;
end;

procedure TForm1.JvThread1Execute(Sender: TObject; Params: Pointer);
var
  Max: Integer;
  Count: Integer;
  I: Integer;
  procedure Load(iStart, iEnd: Integer);
  var
    I: Integer;
  begin
    for I := iStart to iEnd do
    begin
      Loading := IntToStr((Count * 100) div Max) + '%';
//      TThread.Synchronize(BaseThread, ShowLoadingInfo);
      if BaseThread.Terminated then Exit;
      LoadPicture(I);
      Inc(Count);
    end;
  end;
begin
  TThread.Synchronize(BaseThread, procedure
  begin
    Max :=  Pictures.Count;
    I := iPicture;
  end);

  CoInitializeEx(nil, COINIT_MULTITHREADED or COINIT_SPEED_OVER_MEMORY);
  try
    if not Assigned(MemBuf) then MemBuf := TMemoryStream.Create;
    try
      Count := 0;
      Load(I, Max - 1);
      Load(0, I - 1);
    finally
      MemBuf.SetSize(0);
    end;
  finally
    CoUninitialize;
  end;
end;

procedure TForm1.JvThread1FinishAll(Sender: TObject);
begin
  IsLoading := False;
  Loading := '';
  ShowLoadingInfo;
end;

procedure TForm1.LoadSetting;
var
  FileName: string;
  Ini: TMemIniFile;
  N: Integer;
  b: Boolean;
begin
  SettingChanged := False;
  FileName := IniName;
  Splitter1.Tag := ListView1.Width;
  if not FileExists(FileName, False) then Exit;

  Ini := TMemIniFile.Create(FileName);
  try
    b := Ini.ReadBool(SettingSection[_AS_Layout], SettingIdent[_ASL_ThumbnailList], True);
    N :=  Ini.ReadInteger(SettingSection[_AS_Layout], SettingIdent[_ASL_ThumbnailMargin], -1);

    if N >  SplitterMax then N := SplitterMax;
    if N <= SplitterMin then N := ListView1.Width;

    Splitter1.Tag := N;
    if b then
      SplitterTo(Splitter1.Parent.ClientWidth - Splitter1.Width - N)
    else
      SplitterTo(Splitter1.Parent.ClientWidth - Splitter1.Width);
  finally
    Ini.Free;
  end;
end;

procedure TForm1.SaveSetting;
var
  FileName: string;
  Ini: TMemIniFile;
  N: Integer;
  b: Boolean;
begin
  if not SettingChanged then Exit;

  FileName := IniName;
  Ini := TMemIniFile.Create(FileName);
  try
    N := GetSplitterCurr;
    b := N > SplitterMin;
    Ini.WriteBool(SettingSection[_AS_Layout], SettingIdent[_ASL_ThumbnailList], b);
    if not b then            N := Splitter1.Tag;
    if N <= SplitterMin then N := -1;
    Ini.WriteInteger(SettingSection[_AS_Layout], SettingIdent[_ASL_ThumbnailMargin], N);
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
end;

{ TForm1.TImageObj }

function TForm1.TImageObj.GetSize(out ASize: TSize): Boolean;
begin
  if not Assigned(Obj) then Exit(False);

  if      Obj is TWICImages then ASize := Multi.CurrentImageSize
  else if Obj is TGIFImage  then ASize := TSize.Create(GIF.Width, GIF.Height)
  else if Obj is TWICImage  then ASize := TSize.Create(WIC.Width, WIC.Height)
  else Exit(False);

  Result := True;
end;

function TForm1.TImageObj.GetSize: TSize;
begin
  if not GetSize(Result) then
    raise Exception.Create('Unable get image size.');
end;

{ TForm1.TImageItem }

function TForm1.TImageItem.Assigned: Boolean;
begin
  Result := System.Assigned(Slot.Obj);
end;

procedure TForm1.TImageItem.Free;
var
  Image: TImageItem;
begin
  Image := Self;
  Self.Slot.Obj := nil;
  Self.Mode := _PIT_OBJ;
  Image.Slot.Obj.Free;
end;

{ TForm1.TPictureList }

procedure TForm1.TPictureList.Notify(const Value: TPictureItem; Action: TCollectionNotification);
begin
  if Action = cnRemoved then
  begin
    if Value.Image.Assigned then Value.Image.Free;
  end;
  inherited;
end;

procedure TForm1.TPictureList.SetId(Index, Id: Integer);
begin
  if (Index < 0) or (Index >= Count) then ErrorArgumentOutOfRange;
  List[Index].ID := Id;
end;

function TForm1.TPictureList.GetId(Index: Integer): Integer;
begin
  if (Index < 0) or (Index >= Count) then ErrorArgumentOutOfRange;
  Result := List[Index].ID;
end;

procedure TForm1.TPictureList.SetName(Index: Integer; const Name: string);
begin
  if (Index < 0) or (Index >= Count) then ErrorArgumentOutOfRange;
  List[Index].Name := Name;
end;

function TForm1.TPictureList.GetName(Index: Integer): string;
begin
  if (Index < 0) or (Index >= Count) then ErrorArgumentOutOfRange;
  Result := List[Index].Name;
end;

procedure TForm1.TPictureList.SetThumbIndex(Index, iThumb: Integer);
begin
  if (Index < 0) or (Index >= Count) then ErrorArgumentOutOfRange;
  List[Index].iThumb := iThumb;
end;

function TForm1.TPictureList.GetThumbIndex(Index: Integer): Integer;
begin
  if (Index < 0) or (Index >= Count) then ErrorArgumentOutOfRange;
  Result := List[Index].iThumb
end;

procedure TForm1.TPictureList.SetImage(Index: Integer; Mode: TImageType; Image: TObject; Thumb: TListItem);
var
  PicItem: TPictureItem;
begin
  if (Index < 0) or (Index >= Count) then
    ErrorArgumentOutOfRange;
  PicItem := List[Index];
  PicItem.ThumbItem := Thumb;

  if PicItem.Image.Assigned then
    raise Exception.Create('Image already exists.');

  if PicItem.Image.Mode <> _PIT_OBJ then
    raise Exception.Create('The current mode is not the default.');

  PicItem.Image.Slot.Obj := Image;
  PicItem.Image.Mode := Mode;

  List[Index] := PicItem;
end;

procedure TForm1.TPictureList.SetImageItem(Index: Integer; const Item: TImageItem);
begin
  SetImage(Index, Item.Mode, Item.Slot.Obj);
end;

procedure TForm1.TPictureList.SetWIC(Index: Integer; Image: TWICImage);
begin
  SetImage(Index, _PIT_WIC, Image);
end;

procedure TForm1.TPictureList.SetMultiWIC(Index: Integer; Images: TWICImages);
begin
  SetImage(Index, _PIT_MultiWIC, Images);
end;

procedure TForm1.TPictureList.SetGIF(Index: Integer; Image: TGIFImage);
begin
  SetImage(Index, _PIT_GIF, Image);
end;

function TForm1.TPictureList.GetImage(Index: Integer; out Image: TObject; out Thumb: TListItem): TImageType;
var
  PicItem: TPictureItem;
begin
  if (Index < 0) or (Index >= Count) then ErrorArgumentOutOfRange;
  PicItem := List[Index];
  Image := PicItem.Image.Slot.Obj;
  Thumb := PicItem.ThumbItem;
  Result := PicItem.Image.Mode;
end;

function TForm1.TPictureList.GetImage(Index: Integer; out Image: TObject): TImageType;
var
  PicItem: TPictureItem;
begin
  if (Index < 0) or (Index >= Count) then ErrorArgumentOutOfRange;
  PicItem := List[Index];
  Image := PicItem.Image.Slot.Obj;
  Result := PicItem.Image.Mode;
end;

function TForm1.TPictureList.GetImageItem(Index: Integer; out Thumb: TListItem): TImageItem;
begin
  Result.Mode := GetImage(Index, Result.Slot.Obj, Thumb);
end;

function TForm1.TPictureList.GetImageItem(Index: Integer): TImageItem;
begin
  Result.Mode := GetImage(Index, Result.Slot.Obj);
end;

function TForm1.TPictureList.GetWIC(Index: Integer): TWICImage;
begin
  if GetImage(Index, TObject(Result)) <> _PIT_WIC then Result := nil;
end;

function TForm1.TPictureList.GetGIF(Index: Integer): TGIFImage;
begin
  if GetImage(Index, TObject(Result)) <> _PIT_GIF then Result := nil;
end;

procedure TForm1.TPictureList.SetThumbItem(Index: Integer; Item: TListItem);
begin
  if (Index < 0) or (Index >= Count) then ErrorArgumentOutOfRange;
  List[Index].ThumbItem := Item;
end;

function TForm1.TPictureList.GetThumbItem(Index: Integer): TListItem;
begin
  if (Index < 0) or (Index >= Count) then ErrorArgumentOutOfRange;
  Result := List[Index].ThumbItem;
end;

function TForm1.TPictureList.Add(ID: Integer; const Name: string): Integer;
var
  AItem: TPictureItem;
begin
  AItem.ID := ID;
  AItem.Name := Name;
  AItem.iThumb := -1;
  AItem.Image.Mode := _PIT_OBJ;
  AItem.Image.Slot.Obj := nil;
  AItem.ThumbItem := nil;
  Result := inherited Add(AItem);
end;

initialization
  CoInitializeEx(nil, COINIT_APARTMENTTHREADED or COINIT_DISABLE_OLE1DDE);

finalization
  CoUninitialize;

end.
