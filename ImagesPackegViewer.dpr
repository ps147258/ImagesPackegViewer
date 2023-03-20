program ImagesPackegViewer;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Vcl.Imaging.GIFImg.GifExtend in 'Vcl.Imaging.GIFImg.GifExtend.pas',
  Vcl.Graphics.MultipleWICImage in 'Vcl.Graphics.MultipleWICImage.pas';

{$R *.res}

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
