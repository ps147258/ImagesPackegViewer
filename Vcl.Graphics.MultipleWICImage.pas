// 只是簡單的 TWICImage 清單類別，暫時沒有打算做成像 TGifImage 那樣，

unit Vcl.Graphics.MultipleWICImage;

interface

uses
  System.RTLConsts, System.SysUtils, System.Classes, System.Generics.Collections,
  Winapi.Windows, Winapi.ActiveX, Winapi.Wincodec,
  Vcl.Graphics;

type
  TDataSourceType = (_DST_Non, _DST_Stream, _DST_File);

  TDataSource = record
    DataType: TDataSourceType;
    Stream: TStream;
    Filename: string;
  end;

  TWICImageEx = class(TWICImage)
  private
//    FKeepSource: Boolean;
    FSource: TDataSource;
  public
    procedure Assign(Source: TPersistent); override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure LoadFromFile(const Filename: string); override;
    procedure LoadFromClipboardFormat(AFormat: Word; AData: THandle; APalette: HPALETTE); override;
    procedure ReloadFromSource;
  end;

  TWICImages = class(TObjectList<TWICImageEx>)
  private
    FFrameCount: LongWord;
    FFrameIndex: LongWord;
    FSourceStream: TMemoryStream;
    FSource: TDataSource;
    FCurrent: TWICImage;
    procedure ExceptionImageFailed;
//    procedure SetBuffer(WICImage: TWICImage);
    function GetCurrent: TWICImage;
    function GetCurrentImageSize: TSize;
    procedure SetFrameIndex(NewIndex: LongWord);
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
    procedure LoadFromStream(Stream: TStream);
    procedure LoadFromFile(const Filename: string);
    function Load(Index: LongWord): TWICImageEx;
    procedure Prev;
    procedure Next;
    function ReadImage(Index: LongWord): TWICImageEx;
    procedure ReadImages(Renew: Boolean = True);
    property FrameIndex: LongWord read FFrameIndex write SetFrameIndex;
    property Current: TWICImage read GetCurrent;
    property CurrentImageSize: TSize read GetCurrentImageSize;
  end;

implementation

resourcestring
  ErrFmtImageFailed = 'Unable to extract image at index %d from %s';

{ TMWICImageEx }

procedure TWICImageEx.Assign(Source: TPersistent);
begin
  if not (Source is TWICImageEx) then
  begin
    inherited;
    Exit;
  end;

end;

procedure TWICImageEx.LoadFromStream(Stream: TStream);
begin
  inherited;
  FSource.Stream := Stream;
  FSource.Filename := '';
  FSource.DataType := _DST_Stream;
end;

procedure TWICImageEx.LoadFromFile(const Filename: string);
begin
  inherited;
  FSource.Stream := nil;
  FSource.Filename := Filename;
  FSource.DataType := _DST_File;
end;

procedure TWICImageEx.LoadFromClipboardFormat(AFormat: Word; AData: THandle; APalette: HPALETTE);
begin
  inherited;
  FSource.Stream := nil;
  FSource.Filename := '';
  FSource.DataType := _DST_Non;
end;

procedure TWICImageEx.ReloadFromSource;
begin
  case FSource.DataType of
    _DST_Stream: LoadFromStream(FSource.Stream);
    _DST_File: LoadFromFile(FSource.Filename);
  end;
end;

{ TWICImages }

constructor TWICImages.Create;
begin
  inherited;
  FFrameCount := 0;
  FFrameIndex := 0;
end;

destructor TWICImages.Destroy;
begin
  if Assigned(FSourceStream) then
    FSourceStream.Free;

  inherited;
end;

procedure TWICImages.ExceptionImageFailed;
var
  s: string;
begin
  if FSource.Filename.IsEmpty then
    if FSource.Stream is TFileStream then
      s := 'file: ' + sLineBreak + TFileStream(FSource.Stream).FileName
    else
      s := 'stream.'
  else
    s := 'file: ' + sLineBreak + FSource.Filename;
  raise Exception.CreateFmt(ErrFmtImageFailed, [FFrameIndex, s]) at ReturnAddress;
end;

procedure TWICImages.LoadFromStream(Stream: TStream);
begin
  Self.Clear;

  FSource.Stream := Stream;
  FSource.Filename := '';
  FSource.DataType := _DST_Stream;

  if Assigned(FSourceStream) then
    FSourceStream.Clear
  else
    FSourceStream := TMemoryStream.Create;
  FSourceStream.LoadFromStream(Stream);
end;

procedure TWICImages.LoadFromFile(const Filename: string);
begin
  Self.Clear;

  FSource.Stream := nil;
  FSource.Filename := Filename;
  FSource.DataType := _DST_File;

  if Assigned(FSourceStream) then
    FSourceStream.Clear
  else
    FSourceStream := TMemoryStream.Create;
  FSourceStream.LoadFromFile(Filename);
end;

function TWICImages.Load(Index: LongWord): TWICImageEx;
begin
  if not Assigned(FSourceStream) then
    Exit(nil);
  Result := TWICImageEx.Create;
  Result.FrameIndex := Index;
  Result.LoadFromStream(FSourceStream);
end;

//procedure TWICImages.SetBuffer(WICImage: TWICImage);
//begin
//  FBuffer := WICImage;
//end;

function TWICImages.GetCurrent: TWICImage;
begin
  if Assigned(FCurrent) then
  begin
    Result := FCurrent;
  end
  else
  begin
    if FFrameIndex < LongWord(Self.Count) then
    begin
      Result := Self.Items[FFrameIndex];
      if not Assigned(Result) then
        Result := ReadImage(FFrameIndex);
    end
    else
    begin
      Result := ReadImage(FFrameIndex);
    end;
    FCurrent := Result;
  end;
end;

function TWICImages.GetCurrentImageSize: TSize;
var
  Image: TWICImage;
begin
  Image := GetCurrent;
  if not Assigned(Image) then
    ExceptionImageFailed;
  Result := TSize.Create(Image.Width, Image.Height);
end;

procedure TWICImages.SetFrameIndex(NewIndex: LongWord);
begin
  if NewIndex = FFrameIndex then
    Exit;
  FCurrent := nil;
  FFrameIndex := NewIndex;
end;

function TWICImages.ReadImage(Index: LongWord): TWICImageEx;
begin
  if Self.Count = 0 then
  begin
    Result := Load(0);
    FFrameCount := Result.FrameCount;
    Self.Count := FFrameCount;
    Self.Items[0] := Result;
  end
  else
  begin
    Result := Self.Items[0];
  end;

  if Index = 0 then
    Exit;

  if Index >= FFrameCount then
    Exit(nil);

  Result := Self.Items[Index];
  if Assigned(Result) then
    Exit;
  Result := Load(Index);
  Self.Items[Index] := Result;
end;

procedure TWICImages.ReadImages(Renew: Boolean);
var
  WIC: TWICImageEx;
  I: Integer;
begin
  if Renew then
  begin
    Self.Clear;
    I := 0;
    repeat
      WIC := Load(I);
      Self.Add(WIC);
      Inc(I);
    until (LongWord(I) >= WIC.FrameCount);
  end
  else
  begin
    I := 0;
    repeat
      WIC := Self.Items[I];
      if not Assigned(WIC) then
      begin
        WIC := Load(I);
        Self.Items[I] := WIC;
      end;
      Inc(I);
    until (LongWord(I) >= WIC.FrameCount);
  end;
  FFrameCount := WIC.FrameCount;
end;

procedure TWICImages.Next;
begin
  Inc(FFrameIndex);
  if FFrameIndex >= FFrameCount then
    FFrameIndex := 0;
  if Assigned(FCurrent) then
    FCurrent := ReadImage(FFrameIndex);
end;

procedure TWICImages.Prev;
begin
  if FFrameIndex > 0 then
    Dec(FFrameIndex)
  else
    FFrameIndex := FFrameCount - 1;
  if Assigned(FCurrent) then
    FCurrent := ReadImage(FFrameIndex);
end;

end.
