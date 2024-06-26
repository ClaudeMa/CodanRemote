unit litcodan;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons,
  DBGrids, StdCtrls, Spin, Menus, LazSerial, ZDataset, IniFiles, StrUtils,
  CanalEdit, DB, DataModule;

type

  { TFLitCodan }

  TFLitCodan = class(TForm)
    btnAquerir: TBitBtn;
    btnFermer: TBitBtn;
    btnModifie: TBitBtn;
    btnSupprime: TBitBtn;
    dsCanaux: TDataSource;
    gridListe: TDBGrid;
    Label1: TLabel;
    mSupprime: TMenuItem;
    mModifie: TMenuItem;
    Panel1: TPanel;
    Panel2: TPanel;
    popupGrid: TPopupMenu;
    serCodan: TLazSerial;
    spCanal: TSpinEdit;
    tblCanaux: TZTable;
    procedure btnAquerirClick(Sender: TObject);
    procedure btnFermerClick(Sender: TObject);
    procedure btnModifieClick(Sender: TObject);
    procedure btnSupprimeClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure mModifieClick(Sender: TObject);
    procedure mSupprimeClick(Sender: TObject);
    procedure spCanalChange(Sender: TObject);
  private
    IniFile: TiniFile;
    CCanal: TCanal;
    FCanalEdit: TFCanalEdit;
    procedure OpenPort;
    procedure Modifie;
    procedure Supprime;
  public

  end;

var
  FLitCodan: TFLitCodan;

implementation

{$R *.lfm}

{ TFLitCodan }

procedure TFLitCodan.FormCreate(Sender: TObject);
begin
  IniFile := TIniFile.Create(GetAppConfigFile(False) + '.conf');
  FCanalEdit := TFCanalEdit.Create(self);
  tblCanaux.Open;
end;

procedure TFLitCodan.FormDestroy(Sender: TObject);
begin
  if Assigned(FCanalEdit) then
    FcanalEdit.Free;
end;

procedure TFLitCodan.FormShow(Sender: TObject);
begin
  openPort;
end;

procedure TFLitCodan.mModifieClick(Sender: TObject);
begin
  modifie;
end;

procedure TFLitCodan.mSupprimeClick(Sender: TObject);
begin
  supprime;
end;

procedure TFLitCodan.spCanalChange(Sender: TObject);
begin

end;

procedure TFLitCodan.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  serCodan.Close;
end;

procedure TFLitCodan.btnAquerirClick(Sender: TObject);
var
  i: integer;
  rxData: string;
  notFound: boolean;
begin
  for i := spCanal.Value to spCanal.MaxValue do
  begin
    notFound := False;
    rxData := '';
    serCodan.WriteData('CHAN=' + IntToStr(i) + #13#10);
    repeat
      rxData := trim(serCodan.ReadData);
      if ContainsText(rxdata, 'NOT FOUND') then
      begin
        notFound := True;
        rxdata := 'OK';
      end;
    until ContainsText(rxdata, 'OK') = True;
    if notfound then
    begin
      if MessageDlg('Question', 'Canal n° ' + IntToStr(i) + ' non trouvé.' +
        #13 + 'Voulez vous acquérir le canal suivant?', mtConfirmation,
        [mbYes, mbNo], 0) = mrNo then
      begin
        exit;
      end;
      continue;
    end;
    serCodan.WriteData('FREQ?' + #13#10);
    repeat
      rxData := trim(serCodan.ReadData);
    until ContainsText(rxdata, 'FREQ:') = True;
    cCanal.ID := i;
    cCanal.Freq := StrToFloat(ExtractWord(2, rxdata, [' ']));
    cCanal.Lab := rxData; //ExtractWord(3, rxdata, [' ']);
    serCodan.WriteData('SB?' + #13#10);
    sleep(2);
    repeat
      rxData := trim(serCodan.ReadData);
    until ContainsText(rxdata, 'SIDEBAND:') = True;
    cCanal.Mode := ExtractWord(2, rxdata, [' ']);
    if cCanal.Id > 0 then
    begin
      if MessageDlg('Question', 'Voulez vous enregistrer le canal n°' +
        IntToStr(i) + '?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        FCanalEdit.Nouveau := True;
        Fcanaledit.Canal := cCanal;
        FCanaledit.ShowModal;
        tblcanaux.Refresh;
      end;
    end;
    if MessageDlg('Question', 'Voulez vous acquérir le canal suivant?',
      mtConfirmation, [mbYes, mbNo], 0) = mrNo then
    begin
      exit;
    end;
  end;
end;

procedure TFLitCodan.btnFermerClick(Sender: TObject);
begin
  Close;
end;

procedure TFLitCodan.btnModifieClick(Sender: TObject);
begin
  modifie;
end;

procedure TFLitCodan.btnSupprimeClick(Sender: TObject);
begin
  supprime;
end;

procedure TFLitCodan.openPort;
var
  ser: string = '';
begin
  ser := Inifile.ReadString('CODAN', 'port', '');
  if ser <> EmptyStr then
  begin
    serCodan.Device := ser;
    try
      serCodan.Open;
    except
      ShowMessage('Ouverture du port "' + ser +
        '" impossible. Vérifiez les paramètres');
    end;
  end
  else
  begin
    ShowMessage('Codan non connecté : ' + ser);
    Close;
  end;
end;

procedure TFLitCodan.modifie;
var
  lCanal: Tcanal;
begin
  lCanal.Id := tblCanaux.FieldByName('id').AsInteger;
  lcanal.Freq := tblCanaux.FieldByName('freq').AsFloat;
  lcanal.Lab := tblCanaux.FieldByName('label').AsString;
  lCanal.Mode := tblCanaux.FieldByName('mode').AsString;
  FCanalEdit := TFCanalEdit.Create(self);
  Fcanaledit.Canal := lCanal;
  Fcanaledit.ShowModal;
  Fcanaledit.Free;
  Refresh;
end;

procedure TFLitCodan.supprime;
var
  lCanal: Tcanal;
begin
  lCanal.Id := tblCanaux.FieldByName('id').AsInteger;
  lcanal.Freq := tblCanaux.FieldByName('freq').AsFloat;
  lcanal.Lab := tblCanaux.FieldByName('label').AsString;
  lCanal.Mode := tblCanaux.FieldByName('mode').AsString;
  if MessageDlg('Question', 'Voulez vous supprimer le canal n°' +
    IntToStr(lCanal.Id) + '?' + #13, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    with FdataModule do
    begin
      queryFonction.sql.Clear;
      queryFonction.SQL.Add('DELETE FROM canaux WHERE id = ' +
        IntToStr(lCanal.id) + ';');
      queryFonction.ExecSQL;
    end;
  end;
  Refresh;
end;

end.
