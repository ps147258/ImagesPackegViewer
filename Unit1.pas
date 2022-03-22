unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ActiveX, Winapi.MMSystem,
  System.SysUtils, System.Variants, System.Classes, System.Types, System.IOUtils,
  System.Generics.Defaults, System.Generics.Collections, System.Zip, System.ImageList,
  System.IniFiles,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.Menus, Vcl.ComCtrls, Vcl.ImgList, Vcl.Imaging.GIFImg,
//  Vcl.Imaging.GIFImg.GifExtend,
  JvComponentBase, JvThread,
  Vcl.DragFiles, Vcl.PositionControl;

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
    TViewState = set of (_VS_Resizing, _VS_SizeChanged, _VS_Turning, _VS_Selecting);
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

      procedure SetWIC(Index: Integer; Image: TWICImage); overload;
      procedure SetGIF(Index: Integer; Image: TGIFImage); overload;

      procedure SetThumb(Index: Integer; Item: TListItem);

      function GetImage(Index: Integer; out Image: TPersistent; out Thumb: TListItem): TImageType; overload;
      function GetImage(Index: Integer; out Image: TPersistent): TImageType; overload;
      function GetImageItem(Index: Integer; out Thumb: TListItem): TImageItem; overload;
      function GetImageItem(Index: Integer): TImageItem; overload;

      function GetWIC(Index: Integer): TWICImage; overload;
      function GetGIF(Index: Integer): TGIFImage; overload;

      function GetThumb(Index: Integer): TListItem;

      property Id[Index: Integer]: Integer read GetId write SetId;
      property Names[Index: Integer]: string read GetName write SetName;
      property Thumb[Index: Integer]: TListItem read GetThumb write SetThumb;
    end;
  private
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
    Zip: TZipFile;
    MemBuf: TMemoryStream;
    BmpBuf: TBitmap;
    Pictures: TPictureList;
    iPicture: Integer;
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
    function LoadOriginal(Thread: TJvBaseThread; const FileItem: TPictureItem; var ImageItem: TImageItem; Buffer: TMemoryStream = nil): Boolean;
    function LoadPicture(Index: Integer): Boolean;
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

//uses
//  Debug;

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

procedure TForm1.FormCreate(Sender: TObject);
var
  I: Integer;
  N: Integer;
  M: TMonitor;
begin
  IsLoading := False;
  Closeing := False;
  ViewState := [];
  BaseThread := nil;
  Zip := nil;
  OpenType := _OT_Non;

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

  BmpBuf := TBitmap.Create;
//  BmpBuf.AlphaFormat := afIgnored;
  BmpBuf.SetSize(ThumbSize.Width, ThumbSize.Height);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  JvThread1.TerminateWaitFor(False);

  BmpBuf.Free;

  if Assigned(MemBuf) then
    MemBuf.Free;

  if Assigned(Zip) then
    Zip.Free;

  if Assigned(Pictures) then
    Pictures.Free;

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
  if Msg.message = WM_MOUSEWHEEL then
  begin
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
  end;
  if Assigned(OldAppMessage) then
    OldAppMessage(Msg, Handled);
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE: CloseImages;
    VK_LEFT: TurnPage(_TP_Prev);
    VK_RIGHT: TurnPage(_TP_Next);
    VK_F2: N2.Click;
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
begin
  if _VS_SizeChanged in ViewState then
  begin
    Exclude(ViewState, _VS_SizeChanged);
    Exit;
  end;
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

function TForm1.LoadOriginal(Thread: TJvBaseThread; const FileItem: TPictureItem; var ImageItem: TImageItem; Buffer: TMemoryStream): Boolean;
var
  Stream: TStream;
  MemoryStream: TMemoryStream;
  Header: TZipHeader;
  WIC: TWICImage;
  Gif: TGIFImage;
  function LoadImage: TImageItem;
  begin
    FillChar(Result, SizeOf(Result), 0);
    MemoryStream.Position := 0;
    try
      WIC.LoadFromStream(MemoryStream);
    except on E: Exception do
      ImageItem.Mode := _PIT_OBJ;
    end;
    if WIC.ImageFormat = wifGif then
    begin
      Gif := TGIFImage.Create;
      MemoryStream.Position := 0;
      try
        Gif.LoadFromStream(MemoryStream);
        if Gif.Images.Count > 0 then
        begin
          FreeAndNil(WIC);
          Result.Slot.GIF := Gif;
          Gif := nil;
          Result.Mode := _PIT_GIF;
          Exit;
        end;
      except on E: Exception do
      end;
      FreeAndNil(Gif);
    end;
    Result.Slot.WIC := WIC;
    WIC := nil;
    Result.Mode := _PIT_WIC;
  end;
begin
  Gif := nil;
  WIC := TWICImage.Create;
  try
    if Assigned(Buffer) then
      MemoryStream := Buffer
    else
      MemoryStream := TMemoryStream.Create;
    try
      case OpenType of
        _OT_Files:
        begin
          MemoryStream.LoadFromFile(DirPath + FileItem.Name);
          ImageItem := LoadImage;
        end;
        _OT_Zip:
        begin
          if Assigned(Thread) then
            TThread.Synchronize(BaseThread, procedure
            begin
              Zip.Read(FileItem.ID, Stream, Header);
            end)
          else
            Zip.Read(FileItem.ID, Stream, Header);
          try
            MemoryStream.Position := 0;
            MemoryStream.Size := Header.UncompressedSize;
            MemoryStream.CopyFrom(Stream, Header.UncompressedSize);
          finally
            Stream.Free;
          end;
          ImageItem := LoadImage;
        end;
        else Exit(False);
      end;
    finally
      if Assigned(Buffer) then
        Buffer.SetSize(0)
      else
        MemoryStream.Free;
    end;
    Result := (ImageItem.Mode <> _PIT_OBJ) and Assigned(ImageItem.Slot.Obj);
  finally
    if Assigned(WIC) then
      WIC.Free;
    if Assigned(Gif) then
      Gif.Free;
  end;
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
begin
  Result := False;

  TThread.Synchronize(BaseThread, procedure
  begin
    PicItem := Pictures.List[Index];
  end);

  if not PicItem.Image.Assigned then
  begin
    if LoadOriginal(BaseThread, PicItem, Image, MemBuf) then
    begin
      B := True;
//      bWIC := False;
//      WIC := nil;

      case Image.Mode of
        _PIT_WIC:
          begin
            B := GetReduceSize(Image.Slot.WIC.Width, Image.Slot.WIC.Height, Size);
            if B then
            begin
              bWIC := False;
              WIC := Image.Slot.WIC.CreateScaledCopy(Size.Width, Size.Height, wipmHighQualityCubic);
//              Image.Slot.WIC := nil;
              FreeAndNil(Image.Slot.WIC);
            end
            else
            begin
              bWIC := False;
              WIC := Image.Slot.WIC;
//              Image.Slot.WIC := nil;
            end;
          end;
        _PIT_GIF:
        begin
//        if GetReduceSize(Gif.Width, Gif.Height, Size) then
//          Pictures.SetGIF(Index, CreateScaledGIF(Gif, Size.Width, Size.Height))
//        else
//        begin
            bWIC := True;
            WIC := TWICImage.Create;
            WIC.Assign(Image.Slot.Gif);
//        end;
        end;
        else
        begin
          bWIC := False;
          WIC := nil;
          B := False;
        end;
      end;

      if B then
      begin
        case Image.Mode of
          _PIT_WIC:
          begin
            TThread.Synchronize(BaseThread, procedure
            begin
              Pictures.SetWIC(Index, WIC);
            end);
          end;
//            if GetReduceSize(Image.Slot.WIC.Width, Image.Slot.WIC.Height, Size) then
//            begin
//              bWIC := False;
//              WIC := Image.Slot.WIC.CreateScaledCopy(Size.Width, Size.Height, wipmHighQualityCubic);
//              Pictures.SetWIC(Index, WIC);
//            end
//            else
//            begin
//              bWIC := False;
//              WIC := Image.Slot.WIC;
//              Pictures.SetWIC(Index, WIC);
//              Image.Slot.WIC := nil;
//            end;
          _PIT_GIF:
          begin
  //        if GetReduceSize(Gif.Width, Gif.Height, Size) then
  //          Pictures.SetGIF(Index, CreateScaledGIF(Gif, Size.Width, Size.Height))
  //        else
  //        begin
            TThread.Synchronize(BaseThread, procedure
            begin
              Pictures.SetGIF(Index, Image.Slot.Gif);
            end);
//              bWIC := True;
//              WIC := TWICImage.Create;
//              WIC.Assign(Image.Slot.Gif);
              Image.Slot.Gif := nil;
  //        end;
          end;
//          else
//          begin
//            bWIC := False;
//            WIC := nil;
//            B := False;
//          end;
        end;
      end
      else
      begin
        case Image.Mode of
          _PIT_WIC:
          begin
            TThread.Synchronize(BaseThread, procedure
            begin
              Pictures.SetWIC(Index, Image.Slot.WIC);
            end);
            Image.Slot.WIC := nil;
          end;
          _PIT_GIF:
          begin
            TThread.Synchronize(BaseThread, procedure
            begin
              Pictures.SetGIF(Index, Image.Slot.Gif);
            end);
            Image.Slot.Gif := nil;
          end;
        end;
      end;

      if Assigned(WIC) then
      begin
        if GetReduceSize(ThumbSize.Width, ThumbSize.Height, WIC.Width, WIC.Height, True, Size) then
        begin
          Thumbnail := WIC.CreateScaledCopy(Size.Width, Size.Height, wipmHighQualityCubic);
          try
            TThread.Synchronize(BaseThread, procedure
            begin
              BmpBuf.Canvas.Draw((ThumbSize.Width - Thumbnail.Width) div 2, (ThumbSize.Height - Thumbnail.Height) div 2, Thumbnail);
            end);
          finally
            FreeAndNil(Thumbnail);
          end;
        end
        else
        begin
          BmpBuf.Canvas.Draw((ThumbSize.Width - WIC.Width) div 2, (ThumbSize.Height - WIC.Height) div 2, WIC);
        end;

        if bWIC then
          FreeAndNil(WIC)
        else
          WIC := nil;

        TThread.Synchronize(BaseThread, procedure
        begin
          iThumbnail := ImageList1.Add(BmpBuf, nil);
          Item := ListView1.Items.Add;
          Item.Caption := IntToStr(Index);
          Item.Data := Pointer(Index);
          Item.ImageIndex := iThumbnail;
          Pictures.Thumb[Index] := Item;
        end);

        BmpBuf.Canvas.FillRect(TRect.Create(0, 0, ThumbSize.Width, ThumbSize.Height));
        BmpBuf.Assign(nil);
        BmpBuf.SetSize(ThumbSize.Width, ThumbSize.Height);

        Result := True;
      end;

      FreeAndNil(Image.Slot.Obj);
      Image.Mode := _PIT_OBJ;
    end;  
  end;
end;

procedure TForm1.ShowImage(Index: Integer; Mode: TDisplayMode);
var
  Thumb: TListItem;
  Image: TImageItem;
  Size: TSize;
  b: Boolean;
  IsScaled: Boolean;
begin
  if Pictures.Count = 0 then
    Exit;
  b := True;
  while True do
  begin
    try
      Image := Pictures.GetImageItem(Index, Thumb);
      if Image.Mode <> _PIT_OBJ then
        if Image.Assigned and Assigned(Thumb) then
          Break
        else
          if b then
          begin
            b := False;
            Caption := Format('Loading[%u/%u] ...', [Index + 1, Pictures.Count]);
          end;
    except on E: Exception do

    end;
    if Closeing or (Index <> iPicture) then
      Exit;
    Application.HandleMessage;
  end;

  if ScaledImage.Assigned then
  begin
    FreeAndNil(ScaledImage.Slot.Obj);
    ScaledImage.Mode := _PIT_OBJ;
  end;

  DisplayMode := Mode;

  if Mode = _DM_Original then
  begin
    LoadOriginal(nil, Pictures.Items[Index], ScaledImage);

    Image1.Stretch := False;
    Image1.Proportional := False;
    case Image.Mode of
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
        Image.Slot.GIF.Animate := True;
      end;
    end;
    ShowPageInfo;
    Exit;
  end;

  case Image.Mode of
    _PIT_WIC: IsScaled := GetReduceSize(ScrollBox1.ClientWidth, ScrollBox1.ClientHeight, Image.Slot.WIC.Width, Image.Slot.WIC.Height, True, Size);
    _PIT_GIF: IsScaled := GetReduceSize(ScrollBox1.ClientWidth, ScrollBox1.ClientHeight, Image.Slot.GIF.Width, Image.Slot.GIF.Height, True, Size);
    else
    begin
      IsScaled := False;
    end;
  end;

  if IsScaled then
  begin
    Image1.Width := Size.Width;
    Image1.Height := Size.Height;
    case Image.Mode of
      _PIT_WIC:
      begin
        Image1.Stretch := False;
        Image1.Proportional := False;
        ScaledImage.Slot.WIC := Image.Slot.WIC.CreateScaledCopy(Size.Width, Size.Height, wipmHighQualityCubic);
        ScaledImage.Mode := _PIT_WIC;
        Image1.Picture.WICImage := ScaledImage.Slot.WIC;
      end;
      _PIT_GIF:
      begin
//        ScaledImage.Slot.GIF := CreateScaledGIF(Image.Slot.GIF, Size.Width, Size.Height);
//        ScaledImage.Mode := _PIT_GIF;
//        Image1.Picture.Graphic := ScaledImage.Slot.GIF;
//        ScaledImage.Slot.GIF.Animate := True;
        Image1.Proportional := True;
        Image1.Stretch := True;
        Image1.Picture.Graphic := Image.Slot.GIF;
        Image.Slot.GIF.Animate := True;
      end;
//      else
//        Image.Mode := _PIT_OBJ;
    end;
  end
  else
  begin
    Image1.Stretch := False;
    Image1.Proportional := False;
    case Image.Mode of
      _PIT_WIC:
      begin
        SetLayoutSize(Image.Slot.WIC.Width, Image.Slot.WIC.Height);
        Image1.Picture.WICImage := Image.Slot.WIC;
      end;
      _PIT_GIF:
      begin
        SetLayoutSize(Image.Slot.GIF.Width, Image.Slot.GIF.Height);
        Image1.Picture.Graphic := Image.Slot.GIF;
        Image.Slot.GIF.Animate := True;
      end;
    end;
  end;
  ShowPageInfo;
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
  Count: Integer;
begin
  Include(ViewState, _VS_Turning);
  try
    Count := Pictures.Count;
    if Count < 1 then Exit;
    if iPicture < ListView1.Items.Count then
    begin
      case Turn of
        _TP_First: iPicture := 0;
        _TP_Last: iPicture := Count - 1;
        _TP_Prev: if iPicture < 1 then iPicture := Count - 1 else Dec(iPicture);
        _TP_Next: if iPicture >= (Count - 1) then iPicture := 0 else Inc(iPicture);
      end;
      CtlScrollTo(ListView1, iPicture, True);
      ShowImage;
    end;
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
  
  ListView1.Clear;
  ImageList1.Clear;
  Application.ProcessMessages;
  
  if Assigned(Zip) then
    FreeAndNil(Zip);

  if Assigned(Pictures) then
    Pictures.Clear;

  if ScaledImage.Assigned then
  begin
    FreeAndNil(ScaledImage.Slot.Obj);
    ScaledImage.Mode := _PIT_OBJ;
  end;

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
    FreeAndNil(Zip);
  //raise Exception.Create('Zip is not nil, it seems that the previous has not been released, this shouldn''t happen.');

  Title := ChangeFileExt(ExtractFileName(Path), '');
  OpenType := _OT_Zip;
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
        Pictures.List[J] := Item;
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

  iPicture := IndexOfFileName(ExtractFileName(FilePath));

  BaseThread := JvThread1.Execute(@BaseThread);

  ShowImage(iPicture);
  FocusWindows;
end;

procedure TForm1.JvThread1Begin(Sender: TObject);
begin
  IsLoading := True;
end;

procedure TForm1.JvThread1Execute(Sender: TObject; Params: Pointer);
var
  Count: Integer;
  Thread: TJvBaseThread;
  procedure Load(iStart, iEnd: Integer);
  var
    I: Integer;
  begin
    for I := iStart to iEnd do
    begin
      TThread.Synchronize(Thread, procedure
      begin
        Loading := IntToStr((Count * 100) div Pictures.Count) + '%';
        ShowPageInfo;
      end);
      if Thread.Terminated then
        Exit;
      LoadPicture(I);
      Inc(Count);
    end;
  end;
begin
  Thread := TJvBaseThread(PPointer(Params)^);

  CoInitializeEx(nil, COINIT_MULTITHREADED);
  try
    TThread.Synchronize(Thread, procedure
    begin
      if not Assigned(MemBuf) then
        MemBuf := TMemoryStream.Create;
    end);
    try
      Count := 0;
      Load(iPicture, Pictures.Count - 1);
      Load(0, iPicture - 1);
    finally
      TThread.Synchronize(Thread, procedure
      begin
        MemBuf.SetSize(0);
      end);
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

//    Ini.ReadInteger(SettingSection[_AS_Layout], SettingIdent[_ASL_ThumbnailName], 0);
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

//    Ini.WriteInteger(SettingSection[_AS_Layout], SettingIdent[_ASL_ThumbnailName], 0);

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

{ TForm1.TPictureList }

procedure TForm1.TPictureList.Notify(const Value: TPictureItem; Action: TCollectionNotification);
begin
  inherited;
  if Action = cnRemoved then
    Value.Image.Slot.Obj.Free;
end;

procedure TForm1.TPictureList.SetId(Index, Id: Integer);
begin
  if Cardinal(Index) >= Cardinal(Count) then
    ErrorArgumentOutOfRange;
  List[Index].ID := Id;
end;

function TForm1.TPictureList.GetId(Index: Integer): Integer;
begin
  if Cardinal(Index) >= Cardinal(Count) then
    ErrorArgumentOutOfRange;
  Result := List[Index].ID;
end;

procedure TForm1.TPictureList.SetName(Index: Integer; const Name: string);
begin
  if Cardinal(Index) >= Cardinal(Count) then
    ErrorArgumentOutOfRange;
  List[Index].Name := Name;
end;

function TForm1.TPictureList.GetName(Index: Integer): string;
begin
  if Cardinal(Index) >= Cardinal(Count) then
    ErrorArgumentOutOfRange;
  Result := List[Index].Name;
end;

procedure TForm1.TPictureList.SetImage(Index: Integer; Mode: TImageType; Image: TPersistent; Thumb: TListItem);
var
  PicItem: TPictureItem;
begin
  if Cardinal(Index) >= Cardinal(Count) then
    ErrorArgumentOutOfRange;
  PicItem := List[Index];
  PicItem.Thumb := Thumb;
  if PicItem.Image.Slot.Obj <> Image then
  begin
    PicItem.Image.Slot.Obj.DisposeOf;
    PicItem.Image.Slot.Obj := TPersistent(Image);
    PicItem.Image.Mode := Mode;
  end;
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
  if Cardinal(Index) >= Cardinal(Count) then
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
  if Cardinal(Index) >= Cardinal(Count) then
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
  if Cardinal(Index) >= Cardinal(Count) then
    ErrorArgumentOutOfRange;
  List[Index].Thumb := Item;
end;

function TForm1.TPictureList.GetThumb(Index: Integer): TListItem;
begin
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
  Result := Count;
  Count := Result + 1;
  List[Result] := AItem;
end;

initialization
  CoInitializeEx(nil, COINIT_APARTMENTTHREADED);

finalization
  CoUninitialize;

end.
