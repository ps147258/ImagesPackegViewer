object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 480
  ClientWidth = 498
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OnClose = FormClose
  OnCreate = FormCreate
  OnDblClick = FormDblClick
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  DesignSize = (
    498
    480)
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 342
    Top = 0
    Height = 480
    Align = alRight
    Beveled = True
    OnCanResize = Splitter1CanResize
    OnMoved = Splitter1Moved
    ExplicitLeft = 340
  end
  object ScrollBox1: TScrollBox
    Left = 0
    Top = 0
    Width = 342
    Height = 480
    HorzScrollBar.Tracking = True
    VertScrollBar.Tracking = True
    Align = alClient
    BorderStyle = bsNone
    Constraints.MinHeight = 380
    Constraints.MinWidth = 270
    PopupMenu = PopupMenu1
    TabOrder = 0
    OnDblClick = ScrollBox1DblClick
    OnResize = ScrollBox1Resize
    ExplicitWidth = 338
    ExplicitHeight = 479
    object Image1: TImage
      Left = 0
      Top = 0
      Width = 217
      Height = 177
      IncrementalDisplay = True
      PopupMenu = PopupMenu1
      Transparent = True
      OnDblClick = Image1DblClick
      OnMouseDown = Image1MouseDown
      OnMouseMove = Image1MouseMove
      OnMouseUp = Image1MouseUp
    end
    object Button1: TButton
      Left = 223
      Top = 3
      Width = 108
      Height = 25
      Caption = 'SplitterMinTest'
      TabOrder = 0
      Visible = False
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 223
      Top = 34
      Width = 108
      Height = 25
      Caption = 'NextImageTest'
      TabOrder = 1
      Visible = False
      OnClick = Button2Click
    end
  end
  object ListView1: TListView
    Left = 345
    Top = 0
    Width = 153
    Height = 480
    Margins.Left = 0
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    Align = alRight
    Columns = <>
    DoubleBuffered = True
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Consolas'
    Font.Style = []
    HideSelection = False
    LargeImages = ImageList1
    ReadOnly = True
    RowSelect = True
    ParentDoubleBuffered = False
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    SmallImages = ImageList1
    SortType = stData
    TabOrder = 2
    ViewStyle = vsSmallIcon
    OnCompare = ListView1Compare
    OnInfoTip = ListView1InfoTip
    OnSelectItem = ListView1SelectItem
    ExplicitLeft = 341
    ExplicitHeight = 479
  end
  object StaticText1: TStaticText
    Left = 416
    Top = 457
    Width = 82
    Height = 23
    Alignment = taRightJustify
    Anchors = [akRight, akBottom]
    Caption = 'StaticText1'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    Visible = False
    ExplicitLeft = 412
    ExplicitTop = 456
  end
  object JvThread1: TJvThread
    Exclusive = True
    MaxCount = 0
    RunOnCreate = False
    FreeOnTerminate = True
    OnBegin = JvThread1Begin
    OnExecute = JvThread1Execute
    OnFinishAll = JvThread1FinishAll
    Left = 16
    Top = 8
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 100
    OnTimer = Timer1Timer
    Left = 8
    Top = 56
  end
  object Timer2: TTimer
    OnTimer = Timer2Timer
    Left = 56
    Top = 56
  end
  object PopupMenu1: TPopupMenu
    OnPopup = PopupMenu1Popup
    Left = 168
    Top = 56
    object N1: TMenuItem
      Caption = #20999#25563' '#21407#22987'/'#26368#20339' '#22823#23567' ('#28369#40736#40670#20841#19979')'
      OnClick = N1Click
    end
    object N2: TMenuItem
      Caption = #20381#24433#20687#25918#22823#35222#31383' (F2)'
      OnClick = N2Click
    end
    object N3: TMenuItem
      Caption = '-'
    end
    object N4: TMenuItem
      Caption = #22312' Explorer '#20013#38283#21855'... (Ctrl+E)'
      OnClick = N4Click
    end
    object N5: TMenuItem
      Caption = '-'
    end
    object N6: TMenuItem
      Caption = #35079#35069#27284#26696#21040'... (Ctrl+C '#25110' Ctrl+'#28369#40736#24038#37749#25302#21205')'
      OnClick = N6Click
    end
    object N7: TMenuItem
      Caption = #31227#21205#27284#26696#21040'... (Ctrl+X '#25110' Shift+'#28369#40736#24038#37749#25302#21205')'
      OnClick = N7Click
    end
  end
  object ImageList1: TImageList
    BlendColor = clWhite
    BkColor = clWhite
    Height = 80
    Width = 80
    Left = 144
    Top = 8
  end
  object JvThread2: TJvThread
    Exclusive = False
    MaxCount = 0
    RunOnCreate = True
    FreeOnTerminate = True
    OnExecute = JvThread2Execute
    Left = 80
    Top = 8
  end
  object Timer3: TTimer
    Enabled = False
    Interval = 100
    OnTimer = Timer3Timer
    Left = 104
    Top = 56
  end
  object DropFileTarget1: TDropFileTarget
    DragTypes = [dtCopy, dtMove, dtLink]
    OnDragOver = DropFileTarget1DragOver
    OnDrop = DropFileTarget1Drop
    Target = ScrollBox1
    WinTarget = 0
    OptimizedMove = True
    Left = 32
    Top = 112
  end
  object DropFileSource1: TDropFileSource
    DragTypes = [dtCopy, dtMove]
    OnAfterDrop = DropFileSource1AfterDrop
    OnGetDragImage = DropFileSource1GetDragImage
    ShowImage = True
    Left = 128
    Top = 112
  end
  object JvBalloonHint1: TJvBalloonHint
    CustomAnimationTime = 0
    Left = 224
    Top = 112
  end
end
