program codanremote;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, lazcontrols, main, LazSerialPort, zcomponent, apropos, listecanaux,
  canaledit, datamodule, importeliste;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Title:='CodanRemote';
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TFMain, FMain);
  Application.CreateForm(TFCanalEdit, FCanalEdit);
  Application.CreateForm(TFDataModule, FDataModule);
  Application.CreateForm(TFImporteListe, FImporteListe);
  Application.Run;
end.

