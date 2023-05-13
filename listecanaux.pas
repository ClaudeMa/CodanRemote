unit listecanaux;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, SQLite3Conn, SQLDB, DB, Forms, Controls,
  Graphics, Dialogs, ExtCtrls, DBGrids, ZConnection, ZDataset, Grids, Buttons,
  Menus, StdCtrls, MaskEdit, SpinEx, DataModule, Canaledit, LCLType;

type

  { TFListeCanaux }

  TFListeCanaux = class(TForm)
    btnAjoute: TBitBtn;
    btnModifie: TBitBtn;
    btnSupprime: TBitBtn;
    btnSelection: TBitBtn;
    btnFerme: TBitBtn;
    dsListe: TDataSource;
    gridListe: TDBGrid;
    eLabel: TEdit;
    eFrequence: TEdit;
    GroupBox1: TGroupBox;
    ImageList1: TImageList;
    Label1: TLabel;
    Label2: TLabel;
    mAjout: TMenuItem;
    mModifie: TMenuItem;
    mSupprime: TMenuItem;
    mSelectionne: TMenuItem;
    Panel1: TPanel;
    mPopup: TPopupMenu;
    btnChercheFrequence: TSpeedButton;
    btnCherchelabel: TSpeedButton;
    btnEffaceFrequence: TSpeedButton;
    btnEffaceLabel: TSpeedButton;
    queryListe: TZQuery;
    procedure btnAjouteClick(Sender: TObject);
    procedure btnChercheFrequenceClick(Sender: TObject);
    procedure btnFermeClick(Sender: TObject);
    procedure btnModifieClick(Sender: TObject);
    procedure btnSelectionClick(Sender: TObject);
    procedure btnSupprimeClick(Sender: TObject);
    procedure dsListeDataChange(Sender: TObject; Field: TField);
    procedure eFrequenceChange(Sender: TObject);
    procedure eFrequenceEnter(Sender: TObject);
    procedure eFrequenceKeyPress(Sender: TObject; var Key: char);
    procedure eLabelChange(Sender: TObject);
    procedure eLabelEnter(Sender: TObject);
    procedure eLabelKeyPress(Sender: TObject; var Key: char);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure gridListeDblClick(Sender: TObject);
    procedure gridListeTitleClick(Column: TColumn);
    procedure mAjoutClick(Sender: TObject);
    procedure mModifieClick(Sender: TObject);
    procedure mSupprimeClick(Sender: TObject);
    procedure mSelectionneClick(Sender: TObject);
    procedure btnCherchelabelClick(Sender: TObject);
    procedure btnEffaceFrequenceClick(Sender: TObject);
    procedure btnEffaceLabelClick(Sender: TObject);
  private
    dbPath: string;
    mCanal: integer;
    sortField: string;
    sortOrder: string;
    procedure Ajoute;
    procedure Modifie;
    procedure supprime;
    procedure Selectionne;
    procedure Refresh(where: string = ''; sort: string = '');
  public
    property Canal: integer read mcanal;
  end;

var
  FListeCanaux: TFListeCanaux;

implementation

{$R *.lfm}

{ TFListeCanaux }

procedure TFListeCanaux.FormCreate(Sender: TObject);
begin

end;

procedure TFListeCanaux.btnAjouteClick(Sender: TObject);
begin
  Ajoute;
end;

procedure TFListeCanaux.btnChercheFrequenceClick(Sender: TObject);
begin
  refresh(' WHERE freq like ''%' + eFrequence.Text + '%'' ');
end;

procedure TFListeCanaux.btnFermeClick(Sender: TObject);
begin
  Close;
end;

procedure TFListeCanaux.btnModifieClick(Sender: TObject);
begin
  Modifie;
end;

procedure TFListeCanaux.btnSelectionClick(Sender: TObject);
begin
  Selectionne;
end;

procedure TFListeCanaux.btnSupprimeClick(Sender: TObject);
begin
  supprime;
end;

procedure TFListeCanaux.dsListeDataChange(Sender: TObject; Field: TField);
begin
  if queryListe.RecordCount = 0 then
  begin
    btnModifie.Enabled := False;
    btnSupprime.Enabled := False;
  end
  else
  begin
    btnModifie.Enabled := True;
    btnSupprime.Enabled := True;
  end;
end;

procedure TFListeCanaux.eFrequenceChange(Sender: TObject);
begin
  refresh(' WHERE freq LIKE ''%' + eFrequence.Text + '%'' ');
end;

procedure TFListeCanaux.eFrequenceEnter(Sender: TObject);
begin
  elabel.Clear;
end;

procedure TFListeCanaux.eFrequenceKeyPress(Sender: TObject; var Key: char);
begin
  if not (Key in ['0'..'9', '.', #8, #9]) then
    Key := #0;
  if (Key = '.') and (Pos('.', eFrequence.Text) > 0) then
    key := #0;
end;

procedure TFListeCanaux.eLabelChange(Sender: TObject);
begin
  refresh(' WHERE label like ''%' + eLabel.Text + '%'' ');
end;

procedure TFListeCanaux.eLabelEnter(Sender: TObject);
begin
  eFrequence.Clear;
end;

procedure TFListeCanaux.eLabelKeyPress(Sender: TObject; var Key: char);
begin
  //refresh(' WHERE label like ''%' + eLabel.Text + '%'' ');
end;

procedure TFListeCanaux.FormShow(Sender: TObject);
var
  newDB: boolean = False;
begin
  mCanal := 0;
  dbPath := GetUserDir + 'codan.db3';
  FdataModule.Connection.Disconnect;
  FdataModule.Connection.Database := dbPath;
  try
    newDb := not FileExists(FdataModule.Connection.Database);
    if newDb then
    begin
      if MessageDlg('Question',
        'la liste des canaux n''a pas été trouvée. Voulez vous en créer une?' +
        #13, mtConfirmation, [mbYes, mbNo], 0) = mrNo then
        Close;
      try
        FdataModule.Connection.Connect;
        FdataModule.QueryFonction.SQL.Clear;
        FdataModule.QueryFonction.SQL.Add('CREATE TABLE "CANAUX"(' +
          ' "id" Integer NOT NULL PRIMARY KEY,' +
          ' "freq" numeric(8,2) NOT NULL,' + ' "label" Char(128),' +
          ' "mode" Char(3) NOT NULL default ''U'');');
        FdataModule.QueryFonction.ExecSQL;
        // Creating an index based upon id in the CANAUX Table
        FdataModule.QueryFonction.SQL.Clear;
        FdataModule.QueryFonction.SQL.Add(
          'CREATE UNIQUE INDEX "canaux_id_idx" ON "CANAUX"( "id" );');
        FdataModule.QueryFonction.ExecSQL;
      except
        ShowMessage('La création de la liste a échoué');
        Close;
      end;
    end;
  except
    ShowMessage('Impossible de détecter si la liste existe');
    Close;
  end;
  eFrequence.Clear;
  eFrequence.OnChange := @eFrequenceChange;
  eLabel.Clear;
  eLabel.OnChange := @eLabelChange;
  fDataModule.tblCanaux.Open;
  sortField := 'id';
  Refresh;
end;

procedure TFListeCanaux.gridListeDblClick(Sender: TObject);
begin
  mcanal := queryListe.FieldByName('id').AsInteger;
  Close;
end;

procedure TFListeCanaux.gridListeTitleClick(Column: TColumn);
var
  i: integer;
  field: string;
  where: string;
begin
  for i := 0 to gridListe.Columns.Count - 1 do
  begin
    gridListe.Columns.Items[i].Title.Font.Bold := False;
  end;
  field := Column.FieldName;
  if field = sortField then
  begin
    if sortOrder = 'asc' then
    begin
      sortOrder := 'desc';
    end
    else
    begin
      sortOrder := 'asc';
    end;
  end
  else
    sortOrder := 'asc';
  sortField := field;
  if sortOrder = 'asc' then
    gridListe.Columns.Items[Column.Index].Title.ImageIndex := 0
  else if sortOrder = 'desc' then
    gridListe.Columns.Items[Column.Index].Title.ImageIndex := 1
  else
    gridListe.Columns.Items[i].Title.ImageIndex := -1;
  column.Title.Font.Bold := True;
  if eFrequence.Text <> emptyStr then
    where := ' WHERE freq like ''%' + eFrequence.Text + '%'' ';
  if eLabel.Text <> emptyStr then
    where := ' WHERE label like ''%' + eLabel.Text + '%'' ';
  refresh(where, field + ' ' + sortorder);

end;

procedure TFListeCanaux.mAjoutClick(Sender: TObject);
begin
  Ajoute;
end;

procedure TFListeCanaux.mModifieClick(Sender: TObject);
begin
  Modifie;
end;

procedure TFListeCanaux.mSupprimeClick(Sender: TObject);
begin
  Supprime;
end;

procedure TFListeCanaux.mSelectionneClick(Sender: TObject);
begin
  Selectionne;
end;

procedure TFListeCanaux.btnCherchelabelClick(Sender: TObject);
begin
  refresh(' WHERE label like ''%' + eLabel.Text + '%'' ');
end;

procedure TFListeCanaux.btnEffaceFrequenceClick(Sender: TObject);
begin
  eFrequence.Clear;
  refresh;
end;

procedure TFListeCanaux.btnEffaceLabelClick(Sender: TObject);
begin
  eLabel.Clear;
  refresh;
end;

procedure TFListeCanaux.Ajoute;
var
  lCanal: Tcanal;
  FCanalEdit: TFcanalEdit;
begin
  lCanal.Id := 0;
  FCanalEdit := TFCanalEdit.Create(self);
  Fcanaledit.Canal := lCanal;
  Fcanaledit.ShowModal;
  Fcanaledit.Free;
  refresh;
end;

procedure TFListeCanaux.modifie;
var
  lCanal: Tcanal;
  FCanalEdit: TFcanalEdit;
begin
  lCanal.Id := queryListe.FieldByName('id').AsInteger;
  lcanal.Freq := queryListe.FieldByName('freq').AsFloat;
  lcanal.Lab := queryListe.FieldByName('label').AsString;
  lCanal.Mode := queryListe.FieldByName('mode').AsString;
  FCanalEdit := TFCanalEdit.Create(self);
  Fcanaledit.Canal := lCanal;
  Fcanaledit.ShowModal;
  Fcanaledit.Free;
  Refresh;
end;

procedure TFlisteCanaux.supprime;
var
  lCanal: Tcanal;
begin
  lCanal.Id := queryListe.FieldByName('id').AsInteger;
  lcanal.Freq := queryListe.FieldByName('freq').AsFloat;
  lcanal.Lab := queryListe.FieldByName('label').AsString;
  lCanal.Mode := queryListe.FieldByName('mode').AsString;
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

procedure TFListeCanaux.Selectionne;
begin
  mCanal := FdataModule.QueryCanaux.FieldByName('id').AsInteger;
  Close;
end;

procedure TFListeCanaux.Refresh(where: string = ''; sort: string = '');
var
  order: string;
begin
  if sort <> emptyStr then
    order := ' ORDER BY ' + sort
  else
    order := ' ORDER BY id';
  queryListe.sql.Clear;
  queryListe.SQL.Add('SELECT * FROM canaux' + where + order + ';');
  queryListe.Open;
end;

end.
