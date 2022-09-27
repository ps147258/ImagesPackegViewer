unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ActiveX, Winapi.MMSystem, Winapi.CommCtrl,
  System.SysUtils, System.Variants, System.Classes, System.Types, System.IOUtils,
  System.Generics.Defaults, System.Generics.Collections, System.Zip, System.ImageList,
  System.IniFiles,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.Menus, Vcl.ComCtrls, Vcl.ImgList, Vcl.Imaging.GIFImg,
//  Vcl.Imaging.GIFImg.GifExtend,
  JvComponentBase, JvThread,
  Vcl.DragFiles; //, Vcl.PositionControl;

type
  TForm1 = class(TForm)
    JvThread1: TJvThread;
    Timer1: TTimer;
    Timer2: TTimer;
    ScrollBox1: TScrollBox;
    Image1: TImage;
    StaticText1: TStaticText;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    Splitter1: TSplitter;
    ImageList1: TImageList;
    ListView1: TListView;
    Button1: TButton;
    JvThread2: TJvThread;
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
    procedure JvThread1Begin(Sender: TObject);
    procedure JvThread1Execute(Sender: TObject; Params: Pointer);
    procedure JvThread1FinishAll(Sender: TObject);
    procedure JvThread2Execute(Sender: TObject; Params: Pointer);
    procedure ScrollBox1Resize(Sender: TObject);
    procedure ScrollBox1DblClick(Sender: TObject);
    procedure ListView1Compare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
    procedure ListView1SelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure Image1DblClick(Sender: TObject);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure N1Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private type
    TViewState = set of (_VS_Resizing, _VS_SizeChanged, _VS_Turning, _VS_Selecting, _VS_ImageWating);
    TDisplayMode = (_DM_Suitable, _DM_Original);
    TOpenType = (_OT_Non, _OT_Files, _OT_Zip);
    TTurnPage = (_TP_First, _TP_Last, _TP_Prev, _TP_Next);
    TImageType = (_PIT_OBJ, _PIT_WIC, _PIT_GIF);
    TImageObj = record
      case TImageType of
        _PIT_OBJ:(Obj: TPersistent;);
        _PIT_WIC:(WIC: TWICImage;);
        _PIT_GIF:(GIF: TGIFImage;);
    end;
    PImageItem = ^TImageItem;
    TImageItem = record
      Mode: TImageType;
      Slot: TImageObj;
      function Assigned: Boolean; inline;
      procedure Free; inline;
//      procedure SetOBJ(Obj: TObject); inline;
//      procedure SetWIC(WIC: TWICImage); inline;
//      procedure SetGIF(GIF: TGIFImage); inline;
    end;
    PPictureItem = ^TPictureItem;
    TPictureItem = record
      ID: Integer;
      Name: string;
      Image: TImageItem;
      Thumb: TListItem;
    end;
    TPictureList = class(TList<TPictureItem>)
    private
      procedure SetId(Index: Integer; Id: Integer);
      function GetId(Index: Integer): Integer;
      procedure SetName(Index: Integer; const Name: string);
      function GetName(Index: Integer): string;
    protected
      procedure Notify(const Value: TPictureItem; Action: TCollectionNotification); override;
    public
      function Add(ID: Integer; const Name: string): Integer; overload; inline;

      procedure SetImage(Index: Integer; Mode: TImageType; Image: TPersistent; Thumb: TListItem = nil);
      procedure SetImageItem(Index: Integer; const Item: TImageItem);

      procedure SetWIC(Index: Integer; Image: TWICImage);
      procedure SetGIF(Index: Integer; Image: TGIFImage);

      procedure SetThumb(Index: Integer; Item: TListItem);

      function GetImage(Index: Integer; out Image: TPersistent; out Thumb: TListItem): TImageType; overload;
      function GetImage(Index: Integer; out Image: TPersistent): TImageType; overload;
      function GetImageItem(Index: Integer; out Thumb: TListItem): TImageItem; overload;
      function GetImageItem(Index: Integer): TImageItem; overload;

      function GetWIC(Index: Integer): TWICImage;
      function GetGIF(Index: Integer): TGIFImage;

      function GetThumb(Index: Integer): TListItem;

      property Id[Index: Integer]: Integer read GetId write SetId;
      property Names[Index: Integer]: string read GetName write SetName;
      property Thumb[Index: Integer]: TListItem read GetThumb write SetThumb;
    end;
    TGifFrameBuffer = record
      iFrame: Integer;
      Pic: TPictureItem;
      WIC: TWICImage;
//      Bmp: TBitmap;
      Frame: TGIFFrame;
    end;
    PGifFrameBuffer = ^TGifFrameBuffer;
  private
    Processors: DWORD;
    SettingChanged: Boolean;
    SplitterMin: Integer;
    SplitterMax: Integer;
    Closeing: Boolean;
    ViewState: TViewState;
    CursorTracking: Boolean;
    IsLoading: Boolean;
    LastCursor: TPoint;
    Loading: string;
    ThumbSize: TSize;
    DropFiles: TDropFiles;
    DirPath: string;
    Title: string;
    OpenType: TOpenType;
    ZipCS: TRTLCriticalSection;
    Zip: TZipFile;
    MemBuf: TMemoryStream;
    BmpBuf: TBitmap;
    Pictures: TPictureList;
    iPicture: Integer;
    iPictureOld: Integer;
    Limit: TSize;
    ScaledImage: TImageItem;
    DisplayMode: TDisplayMode;
    BaseThread: TJvBaseThread;
    OldAppMessage: TMessageEvent;
    procedure OnAppMessage(var Msg: TMsg; var Handled: Boolean);
    procedure SettingChange; inline;
    procedure UpdateSplitterMax;
    function GetSplitterCurr: Integer;
    procedure SplitterTo(X, Y: Integer); overload;
    procedure SplitterTo(Value: Integer); overload;
    procedure ViewTipAdjust;
    procedure ViewSizeTip;
    procedure FocusWindows;
    procedure SetLayoutSize(Width, Height: Integer);
    procedure CloseImages;
    function ComparePictureItem(const Left, Right: TPictureItem): Integer;
    procedure OpenImagesFormFiles(const Directory: string);
    procedure OpenImagesFormZip(const Path: string);
    function IndexOfFileName(const FileName: string): Integer;
    procedure OnDropFiles(Sender: TObject; WinControl: TWinControl);
    procedure ShowPageInfo;
    function LoadOriginal(const FileItem: TPictureItem; var ImageItem: TImageItem; FrameIndex: Integer = 0; Buffer: TMemoryStream = nil): Boolean;
    function LoadPicture(Index: Integer): Boolean;
    procedure SetTimerImageWating;
    procedure ShowImage(Index: Integer; Mode: TDisplayMode = _DM_Suitable); overload;
    procedure ShowImage(Mode: TDisplayMode); overload; inline;
    procedure ShowImage; overload; inline;
    procedure ViewOriginal(const Point: TPoint); overload;
    procedure ViewOriginal; overload;
    procedure TurnPage(Turn: TTurnPage);
    function GetCurrentImageSize(out Size: TSize): Boolean;
    function GetReduceSize(MaxWidth, MaxHeight, Width, Height: Integer; Inward: Boolean; out Size: TSize): Boolean; overload;
    function GetReduceSize(Width, Height: Integer; out Size: TSize): Boolean; overload; inline;
    procedure LoadSetting;
    procedure SaveSetting;

  public
    { Public declarations }
    procedure WndProc(var Message: TMessage); override;
  end;

var
  Form1: TForm1;

implementation

//{$IFDEF DEBUG}
uses
  Debug;
//{$ENDIF DEBUG}

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
  if hFind = INVALID_HANDLE_VALUE then
    Exit;
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
    if TryStrToInt(sL, iA) then
      Result := iA - iB
    else
      Result := 1
  else
    if TryStrToInt(sL, iA) then
      Result := -1
    else
      Result := CompareStr(sL, sR);
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
  if not GetScrollInfo(ListView.Handle, SB_VERT, si) then
    Exit;

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
  if Processors <= 0 then
    Processors := 8;

  Limit.Width := 0;
  Limit.Height := 0;
  for I := 0 to Screen.MonitorCount - 1 do
  begin
    M := Screen.Monitors[I];
    N := M.Width;
    if N > Limit.Width then Limit.Width := N;
    N := M.Height;
    if N > Limit.Height then Limit.Height := N;
  end;

  ScaledImage.Mode := _PIT_OBJ;
  ScaledImage.Slot.Obj := nil;
  MemBuf := nil;
  Pictures := TPictureList.Create(TComparer<TPictureItem>.Construct(ComparePictureItem));

  DropFiles := TDropFiles.Create(Self, OnDropFiles);
  ViewTipAdjust;

  ThumbSize := TSize.Create(ImageList1.Width, ImageList1.Height);

end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  JvThread1.TerminateWaitFor(False);

  if Assigned(Pictures) then
    Pictures.Free;

  if Assigned(MemBuf) then
    MemBuf.Free;

  if Assigned(Zip) then
  begin
    DeleteCriticalSection(ZipCS);
    Zip.Free;
  end;

  if ScaledImage.Assigned then
    ScaledImage.Slot.Obj.Free;
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
    if Msg.message <> WM_MOUSEWHEEL then
      Exit;

    if ListView1.MouseInClient then
      Exit;

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
  case Key of
    VK_ESCAPE: CloseImages;
    VK_LEFT  : TurnPage(_TP_Prev);
    VK_RIGHT : TurnPage(_TP_Next);
    VK_F2    : N2.Click;
    VK_F3:
    begin
      P := Pictures.Items[iPicture];
      if P.Image.Mode <> _PIT_WIC then
        Exit;
      W := P.Image.Slot.WIC;
      if not Assigned(W) then
        Exit;

      if W.FrameCount < 2 then
        Exit;

      if W.FrameIndex >= W.FrameCount -1 then
        W.FrameIndex := 0
      else
        W.FrameIndex := W.FrameIndex + 1;
      ShowImage(_DM_Original);
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

procedure TForm1.ListView1SelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  Include(ViewState, _VS_Selecting);
  try
    if Selected and (Item.Index <> iPicture) and not (_VS_Turning in ViewState)then
    begin
      iPicture := Item.Index;
      ShowImage;
    end;
  finally
    Exclude(ViewState, _VS_Selecting);
  end;
end;

procedure TForm1.Image1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
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

procedure TForm1.Splitter1CanResize(Sender: TObject; var NewSize: Integer; var Accept: Boolean);
var
  Splitter: TSplitter ABSOLUTE Sender;
  N: Integer;
begin
  if NewSize > SplitterMax then
    Accept := False;

  N := GetSplitterCurr;
  if (NewSize > SplitterMin) and (N < SplitterMin) then
  begin
    if Splitter.MinSize > SplitterMin then
      Splitter.MinSize := SplitterMin;
  end;
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
  if Self.Showing then
    SettingChanged := True;
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
  if A <> B then
    Splitter1.Perform(WM_MOUSEMOVE, MK_LBUTTON, B);
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
    Caption := Format('Loading[%u/%u] ...', [iPicture + 1, Pictures.Count]);
    b := True;
  end;
  if _VS_SizeChanged in ViewState then
  begin
    Exclude(ViewState, _VS_SizeChanged);
    b := True;
  end;
  if b then
    Exit;

  TTimer(Sender).Enabled := False;
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

// 切換 原始/最佳 大小
// Toggle original/best size.
procedure TForm1.N1Click(Sender: TObject);
var
  Size: TSize;
  Point: TPoint;
begin
  if not GetCurrentImageSize(Size) then
    Exit;

  Point := PopupMenu1.PopupPoint;
  if (Point.X < 0) or (Point.X > Size.Width) then
    Point.X := 0;
  if (Point.Y < 0) or (Point.Y > Size.Height) then
    Point.Y := 0;

  ViewOriginal(Point);
end;

// 依影像放大視窗
// Enlarge window by image.
procedure TForm1.N2Click(Sender: TObject);
var
  SizeF, SizeI, Size: TSize;
  R, M: TRect;
begin
  if not GetCurrentImageSize(SizeI) then
    Exit;

  SizeF := TSize.Create(Self.Width - Self.ClientWidth, Self.Height - Self.ClientHeight);
  if GetReduceSize(Monitor.Width - SizeF.Width, Monitor.Height - SizeF.Height, SizeI.Width, SizeI.Height, True, Size) then
  begin
    Size := Size + SizeF;
    Size.Width := Size.Width + Splitter1.Width + ListView1.Width;
    if Size.Width > Monitor.Width then
      Size.Width := Monitor.Width;
    if Size.Height > Monitor.Height then
      Size.Height := Monitor.Height;

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

procedure TForm1.ViewTipAdjust;
begin
  StaticText1.Left := ScrollBox1.Left + ScrollBox1.ClientWidth - StaticText1.Width;
  StaticText1.Top := ScrollBox1.Top + ScrollBox1.ClientHeight - StaticText1.Height;
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
  if Width > Max then
    Image1.Width := Max
  else
    Image1.Width := Width;

  Max := ScrollBox1.ClientHeight;
  if Height > Max then
    Image1.Height := Max
  else
    Image1.Height := Height;
end;

procedure TForm1.ShowPageInfo;
var
  I: Integer;
begin
  I := iPicture;
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
        if Inward and (Size.Height > MaxHeight) then
          GetScaledByHeight;
      end
      else
      begin
        GetScaledByHeight;
        if Inward and (Size.Width > MaxWidth) then
          GetScaledByWidth;
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
        if Inward and (Size.Width > MaxWidth) then
          GetScaledByWidth;
      end
      else
      begin
        GetScaledByWidth;
        if Inward and (Size.Height > MaxHeight) then
          GetScaledByHeight;
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

procedure CopyStream(Source, Target: TStream; Size: UInt32); inline;
begin
  Target.Position := 0;
  Target.Size := Size;
  Target.CopyFrom(Source, Size);
end;

procedure LoadGifFromStream(Source: TStream; Gif: TGIFImage); inline;
begin
  Source.Position := 0;
  Gif.LoadFromStream(Source);
end;

function TForm1.LoadOriginal(const FileItem: TPictureItem; var ImageItem: TImageItem; FrameIndex: Integer; Buffer: TMemoryStream): Boolean;
var
  Stream: TStream;
  MemoryStream: TMemoryStream;
  Header: TZipHeader;
  function LoadImage: TImageItem;
  var
    WIC: TWICImage;
    Gif: TGIFImage;
  begin
    FillChar(Result, SizeOf(Result), 0);
    MemoryStream.Position := 0;
    Gif := nil;
    WIC := TWICImage.Create;
    if FrameIndex > 0 then
      WIC.FrameIndex := FrameIndex;
    try
      WIC.LoadFromStream(MemoryStream);
      case WIC.ImageFormat of
        wifGif:
        begin
          case ImageItem.Mode of
            _PIT_OBJ, _PIT_GIF:
            begin
              Gif := TGIFImage.Create;
              try
                LoadGifFromStream(MemoryStream, Gif);
                if Gif.Images.Count > 0 then
                begin
                  FreeAndNil(WIC);
                  Result.Slot.GIF := Gif;
                  Gif := nil;
                  Result.Mode := _PIT_GIF;
                  Exit;
                end;
              except on E: Exception do
                DbgMsg('Gif[%d] %s loading failure: ' + sLineBreak + '%s', [FileItem.ID, FileItem.Name, E.Message]);
              end;
            end;
          end;
        end;
        wifOther:
        begin
//          DbgMsg('File: %s, ImageFormat: wifOther, FrameCount: %d, FrameIndex: %d',
//            [FileItem.Name, WIC.FrameCount, WIC.FrameIndex]);
        end;
      end;
      Result.Slot.WIC := WIC;
      WIC := nil;
      Result.Mode := _PIT_WIC;
    finally
      if Assigned(WIC) then
        FreeAndNil(WIC);
      if Assigned(Gif) then
        FreeAndNil(Gif);
    end;
  end;
begin
  Result := False;

  if Assigned(Buffer) then
    MemoryStream := Buffer
  else
    MemoryStream := TMemoryStream.Create;
  try
    try
      case OpenType of
        _OT_Files:
        begin
          MemoryStream.LoadFromFile(DirPath + FileItem.Name);
          ImageItem := LoadImage;
        end;
        _OT_Zip:
        begin
          EnterCriticalSection(ZipCS);
          try
            try
              Zip.Read(FileItem.ID, Stream, Header);
              CopyStream(Stream, MemoryStream, Header.UncompressedSize);
            finally
              if Assigned(Stream) then
                FreeAndNil(Stream);
            end;
            ImageItem := LoadImage;
          finally
            LeaveCriticalSection(ZipCS);
          end;
        end;
        else Exit(False);
      end;
    finally
      if Assigned(Buffer) then
        Buffer.SetSize(0)
      else
        FreeAndNil(MemoryStream);
    end;
  except on E: Exception do
    DbgMsg('Load [%d] failure: %s' + sLineBreak + '%s', [FileItem.ID, FileItem.Name, E.Message]);
  end;
  Result := (ImageItem.Mode <> _PIT_OBJ) and Assigned(ImageItem.Slot.Obj);
end;

function TForm1.LoadPicture(Index: Integer): Boolean;
var
  PicItem: TPictureItem;
  Image: TImageItem;
  bWIC: Boolean;
  WIC: TWICImage;
  Gif: TGIFImage;
  FrameCount: Integer;
  Frames: array of TGifFrameBuffer;
  I: Integer;
  Thumbnail: TWICImage;
  iThumbnail: Integer;
  Item: TListItem;
  Size: TSize;
  B: Boolean;
begin
  FillChar(Image, SizeOf(TImageItem), 0);

  TThread.Synchronize(BaseThread, procedure
  begin
    PicItem := Pictures.Items[Index];
  end);

  if PicItem.Image.Assigned then
    raise Exception.CreateFmt('Image field %d is occupied.', [PicItem.ID]);

  if not LoadOriginal(PicItem, Image, -1, MemBuf) then
    raise Exception.CreateFmt('Image[%d]: %s loading failed.', [PicItem.ID, PicItem.Name]);

  bWIC := False;
  WIC := nil;
  Gif := nil;

//  Thumbnail := nil;
  B := True;
  iThumbnail := -1;
  try
    case Image.Mode of
      _PIT_WIC:
      begin
        B := GetReduceSize(Image.Slot.WIC.Width, Image.Slot.WIC.Height, Size);
        B := B and not (Image.Slot.WIC.FrameCount > 1);
        if B then
        begin
          WIC := Image.Slot.WIC.CreateScaledCopy(Size.Width, Size.Height, wipmHighQualityCubic);
        end
        else
        begin
          WIC := Image.Slot.WIC;
        end;
      end;
      _PIT_GIF:
      begin
        if not Assigned(WIC) then
        begin
          bWIC := True;
          WIC := TWICImage.Create;
          WIC.Assign(Image.Slot.Gif);
        end;
      end;
      else
      begin
//        WIC := nil;
        B := False;
      end;
    end;

    if Image.Mode = _PIT_WIC then
    begin
      FrameCount := Image.Slot.WIC.FrameCount;
      if FrameCount > 1 then
      begin
        Gif := TGIFImage.Create;
        try
          Gif.SuspendDraw;
          try
            // And stop active renderers
            Gif.StopDraw;

            SetLength(Frames, FrameCount);
            FillChar(PGifFrameBuffer(Frames)^, FrameCount * SizeOf(TGifFrameBuffer), 0);
            Frames[0].WIC := WIC;

            I := 0;
            while I < FrameCount do
            begin
              Frames[I].iFrame := I;
              Frames[I].Pic := PicItem;
              Frames[I].Frame := TGIFFrame.Create(Gif);
              while JvThread2.Count >= Processors do
                Sleep(50);
              JvThread2.Execute(@Frames[I]);
              Inc(I);
            end;

            while JvThread2.OneThreadIsRunning do
              Sleep(50);

            // Adding loop extension in the first frame (0 = forever)
            TGIFAppExtNSLoop.Create(Frames[0].Frame).Loops := 0;

            Gif.Optimize([ooCrop, ooCleanup, ooColorMap], rmQuantize, dmNearest, 16);
            GIF.Pack;
          except on E: Exception do
            begin
              FreeAndNil(Gif);
              DbgMsg('Convert to Gif[%d] %s failure: ' + sLineBreak + '%s', [PicItem.ID, PicItem.Name, E.Message]);
            end;
          end;
        finally
          Gif.ResumeDraw;
        end;
      end;
    end;

    if not Assigned(WIC) then
      raise Exception.CreateFmt('Image[%d]: %s loading 2 failed.', [PicItem.ID, PicItem.Name]);

    if GetReduceSize(ThumbSize.Width, ThumbSize.Height, WIC.Width, WIC.Height, True, Size) then
    begin
      Thumbnail := WIC.CreateScaledCopy(Size.Width, Size.Height, wipmHighQualityCubic);
      if not Assigned(Thumbnail) then
        raise Exception.CreateFmt('Image[%d]: %s thumbnail failed.', [PicItem.ID, PicItem.Name]);
    end;

    TThread.Synchronize(BaseThread, procedure
    begin
      if Assigned(Thumbnail) then
      begin
        if (ThumbSize.Width > Thumbnail.Width) or (ThumbSize.Height > Thumbnail.Height) then
          BmpBuf.Canvas.FillRect(TRect.Create(0, 0, ThumbSize.Width, ThumbSize.Height));
        BmpBuf.Canvas.Draw((ThumbSize.Width - Thumbnail.Width) div 2, (ThumbSize.Height - Thumbnail.Height) div 2, Thumbnail);
      end
      else
      begin
        if (ThumbSize.Width > WIC.Width) or (ThumbSize.Height > WIC.Height) then
          BmpBuf.Canvas.FillRect(TRect.Create(0, 0, ThumbSize.Width, ThumbSize.Height));
        BmpBuf.Canvas.Draw((ThumbSize.Width - WIC.Width) div 2, (ThumbSize.Height - WIC.Height) div 2, WIC);
      end;

      iThumbnail := ImageList_Add(ImageList1.Handle, BmpBuf.Handle, 0);

      if Assigned(GIF) then
      begin
        if Image.Assigned then
          Image.Free;

        Image.Slot.GIF := Gif;
        Gif := nil;
        Image.Mode := _PIT_GIF;
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
        end;
      end;

      ListView1.Items.BeginUpdate;
      try
        Item := ListView1.Items.Add;
        Item.Data := Pointer(NativeInt(Index));
        Pictures.Thumb[Index] := Item;
        Item.ImageIndex := iThumbnail;
        Item.Caption := IntToStr(Index + 1);
  //      DbgMsg('Add thumbnail[%d]: ImageList %d, ListView %d', [Index, iThumbnail, Item.Index]);
      finally
        ListView1.Items.EndUpdate;
  //      ListView1.Invalidate;
      end;
    end);

    Result := True;
  finally
    if Assigned(Thumbnail) then
      FreeAndNil(Thumbnail);

    if bWIC then
      if Assigned(WIC) then
        FreeAndNil(WIC);

    if Image.Assigned then
      Image.Free;
  end;
end;

procedure TForm1.SetTimerImageWating;
begin
  Include(ViewState, _VS_ImageWating);
  Timer1.Enabled := True;
end;

procedure TForm1.ShowImage(Index: Integer; Mode: TDisplayMode);
var
  Size: TSize;
  b: Boolean;
  PicItem: TPictureItem;
  PicItemOld: TPictureItem;
  FrameIndex: Integer;
  WIC: TWICImage;
//  ImageIcon: TIcon;
begin
  if Pictures.Count = 0 then
    Exit;
  if Index <> iPicture then
    Exit;
  if Closeing then
    Exit;

  b := False;
  FillChar(PicItem, SizeOf(PicItem), 0);
  try
    PicItem := Pictures.Items[Index];
    if PicItem.Image.Mode = _PIT_OBJ then
      b := True
    else if not PicItem.Image.Assigned then
      b := True
    else if not Assigned(PicItem.Thumb) then
      b := True
  except on E: Exception do
    DbgMsg('Item[%d/%d]: ' + sLineBreak + '%s', [Index + 1, Pictures.Count, E.Message]);
  end;
  if b then
  begin
    SetTimerImageWating;
    Exit;
  end;

  if iPictureOld >= 0 then
  begin
    FillChar(PicItemOld, SizeOf(PicItemOld), 0);
    try
      PicItemOld := Pictures.Items[iPictureOld];
      if PicItemOld.Image.Mode = _PIT_GIF then
        if PicItemOld.Image.Assigned then
          PicItemOld.Image.Slot.GIF.Animate := False;
    except on E: Exception do
    end;
  end;

  if ScaledImage.Assigned then
    ScaledImage.Free;

  DisplayMode := Mode;

  if Mode = _DM_Original then
  begin
    if PicItem.Image.Mode = _PIT_WIC then
    begin
      WIC := PicItem.Image.Slot.WIC;
      if Assigned(WIC) then
        FrameIndex := WIC.FrameIndex
      else
        FrameIndex := -1;
    end
    else
      FrameIndex := -1;

    LoadOriginal(PicItem, ScaledImage, FrameIndex);
    Image1.Stretch := False;
    Image1.Proportional := False;
    case PicItem.Image.Mode of
      _PIT_WIC:
      begin
        Image1.Width := ScaledImage.Slot.WIC.Width;
        Image1.Height := ScaledImage.Slot.WIC.Height;
        Image1.Picture.WICImage := ScaledImage.Slot.WIC;
      end;
      _PIT_GIF:
      begin
        Image1.Width := ScaledImage.Slot.GIF.Width;
        Image1.Height := ScaledImage.Slot.GIF.Height;
        Image1.Picture.Graphic := ScaledImage.Slot.GIF;
        if Image1.Picture.Graphic is TGIFImage then
          TGIFImage(Image1.Picture.Graphic).Animate := True;
      end;
    end;
    ShowPageInfo;
    Exit;
  end;

//  DbgMsg('Show: %s, FrameCount: %d, FrameIndex: %d',
//    [Pictures.Items[Index].Name, Image.Slot.WIC.FrameCount, Image.Slot.WIC.FrameIndex]);

  if PicItem.Image.Slot.WIC.FrameCount > 1 then
    b := False
  else
    case PicItem.Image.Mode of
      _PIT_WIC: b := GetReduceSize(ScrollBox1.ClientWidth, ScrollBox1.ClientHeight,
                            PicItem.Image.Slot.WIC.Width, PicItem.Image.Slot.WIC.Height, True, Size);
      _PIT_GIF: b := GetReduceSize(ScrollBox1.ClientWidth, ScrollBox1.ClientHeight,
                            PicItem.Image.Slot.GIF.Width, PicItem.Image.Slot.GIF.Height, True, Size);
      else      b := False;
    end;

  if b then
  begin
    Image1.Width := Size.Width;
    Image1.Height := Size.Height;
    case PicItem.Image.Mode of
      _PIT_WIC:
      begin
        ScaledImage.Slot.WIC := PicItem.Image.Slot.WIC.CreateScaledCopy(Size.Width, Size.Height, wipmHighQualityCubic);
        ScaledImage.Mode := _PIT_WIC;
        Image1.Stretch := False;
        Image1.Proportional := False;
        Image1.Picture.WICImage := ScaledImage.Slot.WIC;
      end;
      _PIT_GIF:
      begin
        Image1.Proportional := True;
        Image1.Stretch := True;
        Image1.Picture.Graphic := PicItem.Image.Slot.GIF;
        if Image1.Picture.Graphic is TGIFImage then
          TGIFImage(Image1.Picture.Graphic).Animate := True;
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
        SetLayoutSize(PicItem.Image.Slot.WIC.Width, PicItem.Image.Slot.WIC.Height);
        Image1.Picture.WICImage := PicItem.Image.Slot.WIC;
      end;
      _PIT_GIF:
      begin
        SetLayoutSize(PicItem.Image.Slot.GIF.Width, PicItem.Image.Slot.GIF.Height);
        Image1.Picture.Graphic := PicItem.Image.Slot.GIF;
        if Image1.Picture.Graphic is TGIFImage then
          TGIFImage(Image1.Picture.Graphic).Animate := True;
      end;
    end;
  end;
  ShowPageInfo;
  iPictureOld := Index;
end;

procedure TForm1.ShowImage(Mode: TDisplayMode);
begin
  if Assigned(Pictures) then
    ShowImage(iPicture, Mode);
end;

procedure TForm1.ShowImage;
begin
  ShowImage(DisplayMode);
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

  if W > H then
    Scale := Image1.Width / W
  else
    Scale := Image1.Height / H;

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

procedure TForm1.TurnPage(Turn: TTurnPage);
var
  ListCount: Integer;
  I: Integer;
  ThumbItem: TListItem;
  LVItem: TLVItem;
begin
  Include(ViewState, _VS_Turning);
  try
    I := iPicture;
    ListCount := ListView1.Items.Count;
    if ListCount < 1 then
      Exit;
    if I >= ListCount then
      Exit;
    case Turn of
      _TP_First: I := 0;
      _TP_Last: I := ListCount - 1;
      _TP_Prev: if I < 1 then I := ListCount - 1 else Dec(I);
      _TP_Next: if I >= (ListCount - 1) then I := 0 else Inc(I);
    end;
    ThumbItem := Pictures.Thumb[I];
    if not Assigned(ThumbItem) then
      Exit
    else
      if ListView1.Items.IndexOf(ThumbItem) < 0 then
        Exit;
    iPicture := I;
    DbgMsg('Scroll to %d.', [iPicture]);
    CtlScrollTo(ListView1, I);
    LVItem.stateMask := LVIS_SELECTED or LVIS_FOCUSED;
    LVItem.state := LVIS_SELECTED or LVIS_FOCUSED;
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

procedure TForm1.CloseImages;
begin
  Caption := 'Closing...';
  Application.ProcessMessages;

  JvThread1.TerminateWaitFor(False);

  if Assigned(Pictures) then
    Pictures.Clear;

  ListView1.Clear;
  ImageList1.Clear;
  
  if Assigned(Zip) then
  begin
    DeleteCriticalSection(ZipCS);
    FreeAndNil(Zip);
  end;

  if ScaledImage.Assigned then
    ScaledImage.Free;

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
  OpenType := _OT_Files;
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
    FreeAndNil(Zip);
  end;
  //raise Exception.Create('Zip is not nil, it seems that the previous has not been released, this shouldn''t happen.');

  Title := ChangeFileExt(ExtractFileName(Path), '');
  OpenType := _OT_Zip;

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
      else
        FileName := Zip.Encoding.GetString(Infos[I].FileName);

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
end;

function TForm1.IndexOfFileName(const FileName: string): Integer;
var
  Count: Integer;
  I: Integer;
begin
  Count := Pictures.Count;
  if Count = 0 then
    Exit(-1);
  if not FileName.IsEmpty then
    for I := 0 to Count - 1 do
      if CompareText(Pictures.Names[I], FileName) = 0 then
        Exit(I);
  Result := 0;
end;

procedure TForm1.OnDropFiles(Sender: TObject; WinControl: TWinControl);
var
  FilePath: string;
begin
  CloseImages;

  FilePath := DropFiles.First;
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
    if not DirectoryExists(FilePath, False) then
      Exit;
    DirPath := IncludeTrailingPathDelimiter(FilePath);
    FilePath := '';
    OpenImagesFormFiles(DirPath);
  end;

  if Pictures.Count = 0 then
    Exit;

  iPictureOld := -1;
  iPicture := IndexOfFileName(ExtractFileName(FilePath));

  BaseThread := JvThread1.Execute(nil);
  BaseThread.Start;

  ShowImage(iPicture);
  FocusWindows;
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
//  Thread: TJvBaseThread;
  procedure Load(iStart, iEnd: Integer);
  var
    I: Integer;
  begin
    for I := iStart to iEnd do
    begin
      Loading := IntToStr((Count * 100) div Max) + '%';
      TThread.Synchronize(BaseThread, procedure
      begin
        ShowPageInfo;
      end);
      if BaseThread.Terminated then
        Exit;
      LoadPicture(I);
      Inc(Count);
    end;
  end;
begin
//  Thread := TJvBaseThread(PPointer(Params)^);
//  Thread := BaseThread;
  TThread.Synchronize(BaseThread, procedure
  begin
    Max :=  Pictures.Count;
    I := iPicture;
  end);

  if not Assigned(MemBuf) then
    MemBuf := TMemoryStream.Create;

  CoInitializeEx(nil, COINIT_MULTITHREADED or COINIT_DISABLE_OLE1DDE);
  try
    BmpBuf := TBitmap.Create;
    try
      BmpBuf.Canvas.Brush.Color := clWhite;
      BmpBuf.Canvas.Pen.Color := clWhite;
      BmpBuf.SetSize(ThumbSize.Width, ThumbSize.Height);

      Count := 0;
      Load(I, Max - 1);
      Load(0, I - 1);
    finally
      MemBuf.SetSize(0);
      FreeAndNil(BmpBuf);
    end;
  finally
    CoUninitialize;
  end;
end;

procedure TForm1.JvThread1FinishAll(Sender: TObject);
begin
  IsLoading := False;
  Loading := '';
  ShowPageInfo;
end;

procedure TForm1.JvThread2Execute(Sender: TObject; Params: Pointer);
var
  P: PGifFrameBuffer absolute Params;
  Frame: TGIFFrame;
  Image: TImageItem;
  Size: TSize;
  WIC: TWICImage;
  GCE: TGIFGraphicControlExtension;
begin
  if BaseThread.Terminated then
    Exit;

  Image.Mode := _PIT_WIC;
  Image.Slot.Obj := nil;
  if not Assigned(P.WIC) then
    if not LoadOriginal(P.Pic, Image, P.iFrame) then
      raise Exception.CreateFmt('Multiple images [%d]: %s loading frame %d failed.', [P.Pic.ID, P.Pic.Name, P.iFrame]);

  WIC := nil;
  try
    Frame := P.Frame;
    if Assigned(P.WIC) then
    begin
      if GetReduceSize(P.WIC.Width, P.WIC.Height, Size) then
      begin
        WIC := P.WIC.CreateScaledCopy(Size.Width, Size.Height, wipmHighQualityCubic);
        Frame.Assign(WIC); // Convert to Gif
      end
      else
      begin
        // Convert to Gif
        Frame.Assign(P.WIC); // Convert to Gif
      end;
    end
    else
    begin
      if GetReduceSize(Image.Slot.WIC.Width, Image.Slot.WIC.Height, Size) then
      begin
        WIC := Image.Slot.WIC.CreateScaledCopy(Size.Width, Size.Height, wipmHighQualityCubic);
        FreeAndNil(Image.Slot.WIC);
        Frame.Assign(WIC); // Convert to Gif
      end
      else
      begin
        Frame.Assign(Image.Slot.WIC); // Convert to Gif
      end;
    end;
    // Setting the delay for each frame
    GCE := TGIFGraphicControlExtension.Create(Frame);
    GCE.Delay := 20;
  finally
    if Assigned(Image.Slot.WIC) then
      Image.Slot.WIC.Free;
    if Assigned(WIC) then
      WIC.Free;
  end;
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
  if not FileExists(FileName, False) then
    Exit;
  Ini := TMemIniFile.Create(FileName);
  try
    b := Ini.ReadBool(SettingSection[_AS_Layout], SettingIdent[_ASL_ThumbnailList], True);
    N :=  Ini.ReadInteger(SettingSection[_AS_Layout], SettingIdent[_ASL_ThumbnailMargin], -1);

    if N > SplitterMax then
      N := SplitterMax;
    if N <= SplitterMin then
      N := ListView1.Width;

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
  if not SettingChanged then
    Exit;

  FileName := IniName;
  Ini := TMemIniFile.Create(FileName);
  try
    N := GetSplitterCurr;
    b := N > SplitterMin;
    Ini.WriteBool(SettingSection[_AS_Layout], SettingIdent[_ASL_ThumbnailList], b);
    if not b then
      N := Splitter1.Tag;
    if N <= SplitterMin then
      N := -1;
    Ini.WriteInteger(SettingSection[_AS_Layout], SettingIdent[_ASL_ThumbnailMargin], N);
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
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
  FreeAndNil(Image.Slot.Obj);

//  if (Image.Mode < Low(TImageType)) or (Image.Mode > High(TImageType)) then
//    raise Exception.CreateFmt('Unknown image mode[%d].', [Integer(Image.Mode)]);
end;

{ TForm1.TPictureList }

procedure TForm1.TPictureList.Notify(const Value: TPictureItem; Action: TCollectionNotification);
begin
  if Action = cnRemoved then
  begin
    if Value.Image.Assigned then
      Value.Image.Free;
  end;
  inherited;
end;

procedure TForm1.TPictureList.SetId(Index, Id: Integer);
begin
  if (Index < 0) or (Index >= Count) then
    ErrorArgumentOutOfRange;
  List[Index].ID := Id;
end;

function TForm1.TPictureList.GetId(Index: Integer): Integer;
begin
  if (Index < 0) or (Index >= Count) then
    ErrorArgumentOutOfRange;
  Result := List[Index].ID;
end;

procedure TForm1.TPictureList.SetName(Index: Integer; const Name: string);
begin
  if (Index < 0) or (Index >= Count) then
    ErrorArgumentOutOfRange;
  List[Index].Name := Name;
end;

function TForm1.TPictureList.GetName(Index: Integer): string;
begin
  if (Index < 0) or (Index >= Count) then
    ErrorArgumentOutOfRange;
  Result := List[Index].Name;
end;

procedure TForm1.TPictureList.SetImage(Index: Integer; Mode: TImageType; Image: TPersistent; Thumb: TListItem);
var
  PicItem: TPictureItem;
begin
  if (Index < 0) or (Index >= Count) then
    ErrorArgumentOutOfRange;
  PicItem := List[Index];
  PicItem.Thumb := Thumb;

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

procedure TForm1.TPictureList.SetGIF(Index: Integer; Image: TGIFImage);
begin
  SetImage(Index, _PIT_GIF, Image);
end;

function TForm1.TPictureList.GetImage(Index: Integer; out Image: TPersistent; out Thumb: TListItem): TImageType;
var
  PicItem: TPictureItem;
begin
  if (Index < 0) or (Index >= Count) then
    ErrorArgumentOutOfRange;
  PicItem := List[Index];
  Image := PicItem.Image.Slot.Obj;
  Thumb := PicItem.Thumb;
  Result := PicItem.Image.Mode;
end;

function TForm1.TPictureList.GetImage(Index: Integer; out Image: TPersistent): TImageType;
var
  PicItem: TPictureItem;
begin
  if (Index < 0) or (Index >= Count) then
    ErrorArgumentOutOfRange;
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
  if GetImage(Index, TPersistent(Result)) <> _PIT_WIC then
    Result := nil;
end;

function TForm1.TPictureList.GetGIF(Index: Integer): TGIFImage;
begin
  if GetImage(Index, TPersistent(Result)) <> _PIT_GIF then
    Result := nil;
end;

procedure TForm1.TPictureList.SetThumb(Index: Integer; Item: TListItem);
begin
  if (Index < 0) or (Index >= Count) then
    ErrorArgumentOutOfRange;
  List[Index].Thumb := Item;
end;

function TForm1.TPictureList.GetThumb(Index: Integer): TListItem;
begin
  if (Index < 0) or (Index >= Count) then
    ErrorArgumentOutOfRange;
  Result := List[Index].Thumb;
end;

function TForm1.TPictureList.Add(ID: Integer; const Name: string): Integer;
var
  AItem: TPictureItem;
begin
  AItem.ID := ID;
  AItem.Name := Name;
  AItem.Image.Mode := _PIT_OBJ;
  AItem.Image.Slot.Obj := nil;
  AItem.Thumb := nil;
  Result := inherited Add(AItem);
end;

initialization
  CoInitializeEx(nil, COINIT_APARTMENTTHREADED or COINIT_DISABLE_OLE1DDE);

finalization
  CoUninitialize;

end.
