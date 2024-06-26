unit apropos;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Buttons, LResources;

type

  { TFApropos }

  TFApropos = class(TForm)
    btnClose: TBitBtn;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    eVersion: TLabel;
    Label5: TLabel;
    lblOs: TLabel;
    Label6: TLabel;
    lblVersion: TLabel;
    procedure btnCloseClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    function GetFileDate(TheFileName: string): string;
    function GetFileModDate(filename : string) : TDateTime;
  public

  end;

var
  FApropos: TFApropos;

implementation

{$R *.lfm}

{ TFApropos }

procedure TFApropos.btnCloseClick(Sender: TObject);
begin
  close;
end;

procedure TFApropos.FormShow(Sender: TObject);
var
version, OS: string;
architecture: string;
begin
  {$IFDEF CPU64}
           architecture := '(64 bits)';
  {$ELSE}
           architecture := '(32 bits)';
  {$ENDIF}

  {$IFDEF LINUX}
          OS := ' Linux ';
  {$ENDIF}

  {$IFDEF WIN32}
          OS := ' Microsoft Windows ';
  {$ENDIF}
  version := {$i version.inc} + ' build ' + FormatDateTime('dd/mm/yyyy', GetFileModDate(application.exename));
  lblVersion.Caption := 'Version ' + version;
  lblOs.Caption := OS + architecture;
end;

function TFApropos.GetFileDate(TheFileName: string): string;
var
  ThisAge: longint;
begin
  ThisAge := FileAge(TheFileName);
  Result := DateToStr(FileDateToDateTime(ThisAge));
end;

function TFApropos.GetFileModDate(filename : string) : TDateTime;
var
   F : TSearchRec;
begin
   FindFirst(filename,faAnyFile,F);
   Result := F.TimeStamp;
   //if you really wanted an Int, change the return type and use this line:
   //Result := F.Time;
   FindClose(F);
end;

end.

