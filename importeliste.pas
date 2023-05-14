unit importeliste;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons,
  StdCtrls, DataModule, DB;

type

  { TFImporteListe }

  TFImporteListe = class(TForm)
    btnAnnule: TBitBtn;
    btnimporte: TBitBtn;
    cbDelete: TCheckBox;
    cbUpdate: TCheckBox;
    eFichier: TEdit;
    Label1: TLabel;
    OpenDialog: TOpenDialog;
    Panel1: TPanel;
    btnFichier: TSpeedButton;
    procedure btnAnnuleClick(Sender: TObject);
    procedure btnimporteClick(Sender: TObject);
    procedure cbDeleteChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnFichierClick(Sender: TObject);
  private
    procedure Modifie(row: TStringArray);
    procedure Ajoute(row: TStringArray);
  public

  end;

var
  FImporteListe: TFImporteListe;

implementation

{$R *.lfm}

{ TFImporteListe }

procedure TFImporteListe.btnAnnuleClick(Sender: TObject);
begin
  Close;
end;

procedure TFImporteListe.btnimporteClick(Sender: TObject);
var
  fileName: string;
  list: TStringList;
  row: TStringArray;
  i: integer;
  nb: integer = 0;
begin
  if eFichier.Text = emptyStr then
  begin
    ShowMessage('Vous devez saisir un nom de fichier à importer');
    eFichier.SetFocus;
    exit;
  end;
  fileName := eFichier.Text;
  if not (FileExists(filename)) then
  begin
    ShowMessage('le fichier "' + filename + '" est introuvable');
    exit;
  end;

  with FdataModule do
  begin
    if tblCanaux.State = dsInactive then
      tblCanaux.Open;
    try
      if cbDelete.Checked then
      begin
        if MessageDlg('Attention',
          'Tous les canaux de votre liste actuelle vont être supprimé avant l''importation.'
          + #13 + 'Voulez vous continuer?', mtConfirmation, [mbYes, mbNo], 0) = mrNo then
        begin
          exit;
        end;
        with FdataModule do
        begin
          queryFonction.sql.Clear;
          queryFonction.SQL.Add('DELETE FROM canaux;');
          queryFonction.ExecSQL;
        end;
      end;
      list := TStringList.Create;
      list.LoadFromFile(fileName);
      for i := 1 to list.Count - 1 do
      begin
        row := StringReplace(list[i], '"', '', [rfReplaceAll]).Split(';');
        if cbDelete.Checked = False then
        begin
          if tblCanaux.Locate('id', row[0], []) then
          begin
            if cbUpdate.Checked then
            begin
              Modifie(row);
              Inc(nb);
            end;
          end
          else
          begin
            Ajoute(row);
            Inc(nb);
          end;
        end
        else
        begin
          Ajoute(row);
          Inc(nb);
        end;
      end;
    except
      if assigned(list) then
        list.Free;
      ShowMessage('L''importation a echoué');
      exit
    end;
  end;
  if nb = 0 then
    ShowMessage('Aucun canal importé')
  else if nb = 1 then
    ShowMessage('1 canal importé sur ' + IntToStr(nb))
  else
    ShowMessage(IntToStr(nb) + ' canaux importés sur ' + IntToStr(nb));
  list.Free;
  Close;
end;

procedure TFImporteListe.cbDeleteChange(Sender: TObject);
begin
  cbUpdate.Checked := not cbDelete.Checked;
end;

procedure TFImporteListe.FormShow(Sender: TObject);
begin
  cbDelete.Checked := False;
  cbUpdate.Checked := False;
  eFichier.Clear;
end;

procedure TFImporteListe.btnFichierClick(Sender: TObject);
var
  fileName: string;
begin
  OpenDialog.InitialDir := GetUserDir;
  if OpenDialog.Execute then
  begin
    fileName := OpenDialog.Filename;
    eFichier.Text := fileName;
  end;
end;

procedure TFImporteListe.Modifie(row: TStringArray);
begin
  with fDataModule do
  begin
    queryFonction.SQL.Clear;
    queryFonction.SQL.Add('UPDATE canaux SET freq = ''' + row[1] +
      ''', label = ''' + row[2] + ''', ' + 'mode = ''' + row[3] +
      ''' WHERE id = ' + row[0] + ';');
    queryFonction.ExecSQL;
  end;
end;

procedure TFImporteListe.Ajoute(row: TStringArray);
begin
  with fDataModule do
  begin
    tblCanaux.Insert;
    tblCanaux.FieldByName('id').AsInteger := StrToInt(row[0]);
    tblCanaux.FieldByName('freq').AsFloat :=
      strToFloat(StringReplace(row[1], '.', ',', [rfReplaceAll]));
    tblCanaux.FieldByName('label').AsString := row[2];
    tblCanaux.FieldByName('mode').AsString := row[3];
    tblCanaux.Post;
  end;
end;

end.
