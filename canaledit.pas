unit canaledit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Spin, StdCtrls,
  ExtCtrls, Buttons, dataModule, DB;

type

  TCanal = record
    Id: integer;
    Freq: double;
    Lab: string;
    Mode: string;
  end;

  { TFCanalEdit }

  TFCanalEdit = class(TForm)
    btnAnnule: TBitBtn;
    btnEnregsitre: TBitBtn;
    cbMode: TComboBox;
    ControlBar1: TControlBar;
    eLabel: TEdit;
    eFrequence: TFloatSpinEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    ecanal: TSpinEdit;
    Panel1: TPanel;
    procedure btnAnnuleClick(Sender: TObject);
    procedure btnEnregsitreClick(Sender: TObject);
    procedure cbModeChange(Sender: TObject);
    procedure ecanalChange(Sender: TObject);
    procedure eFrequenceChange(Sender: TObject);
    procedure eLabelChange(Sender: TObject);
    procedure eLabelDblClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    mCanal: Tcanal;
    mNouveau: boolean;
    isChanged: boolean;
    function CanalExists(canal: integer): boolean;
  public
    property Canal: TCanal read mCanal write mCanal;
    property Nouveau: boolean write mNouveau;
  end;

var
  FCanalEdit: TFCanalEdit;

implementation

{$R *.lfm}

{ TFCanalEdit }

procedure TFCanalEdit.btnAnnuleClick(Sender: TObject);
begin
  if isChanged then
  begin
    if MessageDlg('Question',
      'le canal a été modifié. Voulez vous quitter sans enregistrer?' +
      #13, mtConfirmation, [mbYes, mbNo], 0) = mrNo then
      exit;
  end;
  Close;
end;

procedure TFCanalEdit.btnEnregsitreClick(Sender: TObject);
var
  sqlTexte: string;
  lCanal: Tcanal;
begin
  if eCanal.Value = 0 then
  begin
    ShowMessage('Le numéro de canal doit être compris entre 1 et 400.');
    exit;
  end;
  lCanal.Id := eCanal.Value;
  if (mCanal.Id = 0) and (CanalExists(eCanal.Value)) then
  begin
    ShowMessage('Un canal avec le même numéro existe. Modifiez le numéro');
    eCanal.SetFocus;
    exit;
  end;

  if (mNouveau = true) and (CanalExists(eCanal.Value)) then
  begin
    if MessageDlg('Question',
      'Un canal avec le même numéro existe. Voulez vous le remplacer?',
      mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      mNouveau := False
    else
      exit;
  end;



  if elabel.Text = emptyStr then
  begin
    lCanal.Lab := formatFloat('# ###0.00 khz', eFrequence.Value);
  end;

  lCanal.Lab := eLabel.Text;
  lCanal.Mode := cbMode.Text;
  lCanal.Freq := eFrequence.Value;
  with FdataModule do
  begin
    if (mcanal.Id = 0) or (mNouveau) then
      sqltexte := 'INSERT INTO canaux VALUES (' + IntToStr(lCanal.Id) +
        ', '' ' + floatToStr(lCanal.Freq) + ''', ''' +
        lCanal.Lab + ''', ''' + lCanal.Mode + ''');'
    else
      sqlTexte := 'UPDATE canaux set freq = ''' + floatToStr(lCanal.Freq) +
        ''', ' + 'label = ''' + lCanal.Lab + ''', ' + 'mode = ''' +
        lCanal.Mode + ''' WHERE id = ' + IntToStr(lCanal.Id) + ';';
    queryFonction.SQL.Clear;
    queryFonction.SQl.Add(sqlTexte);
    QueryFonction.ExecSQL;
    mCanal := lCanal;
  end;
  Close;
end;

procedure TFCanalEdit.cbModeChange(Sender: TObject);
begin
  isChanged := True;
end;

procedure TFCanalEdit.ecanalChange(Sender: TObject);
begin
  isChanged := True;
end;

procedure TFCanalEdit.eFrequenceChange(Sender: TObject);
begin
  isChanged := True;
end;

procedure TFCanalEdit.eLabelChange(Sender: TObject);
begin
  isChanged := True;
end;

procedure TFCanalEdit.eLabelDblClick(Sender: TObject);
begin
  TEdit(sender).SelectAll;
end;

procedure TFCanalEdit.FormShow(Sender: TObject);
begin
  if FdataModule.tblCanaux.State = dsInactive then
    FdataModule.tblCanaux.Open;
  if (mCanal.Id = 0) and (mNouveau = False) then
  begin
    eCanal.Value := 0;
    eFrequence.Value := 250;
    eLabel.Clear;
    cbMode.Text := 'U';
  end
  else
  begin
    eCanal.Value := mCanal.Id;
    eFrequence.Value := mcanal.Freq;
    elabel.Text := mCanal.Lab;
    cbMode.Text := mcanal.Mode;
  end;
  isChanged := False;
end;

function TFCanaledit.CanalExists(canal: integer): boolean;
begin
  with FdataModule do
  begin
    Result := tblCanaux.Locate('id', canal, []);
  end;
end;

end.
