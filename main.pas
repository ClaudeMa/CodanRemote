unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  ExtCtrls, Menus, Buttons, MaskEdit, Spin, LazSerial, IniFiles, StrUtils,
  apropos, Controls.SegmentDisplay, LazSynaSer, DefaultTranslator;

type

  { TFMain }

  TFMain = class(TForm)
    btnFREQ: TSpeedButton;
    btnMODE1: TSpeedButton;
    chanDisplay: TLabel;
    cbMode: TComboBox;
    cbMute: TComboBox;
    eFreq: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    mEgal: TMenuItem;
    mProtocoleYeasu: TMenuItem;
    modeDisplay: TLabel;
    infoDisplay: TLabel;
    mCICS: TMenuItem;
    mHelp: TMenuItem;
    mApropos: TMenuItem;
    Panel1: TPanel;
    frequenceDisplay: TSegmentDisplay;
    serCodan: TLazSerial;
    serSource: TLazSerial;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    mQuitter: TMenuItem;
    MenuItem3: TMenuItem;
    mParamCodan: TMenuItem;
    mParamSource: TMenuItem;
    eChan: TSpinEdit;
    btnCHAN: TSpeedButton;
    btnMODE: TSpeedButton;
    SpeedButton1: TSpeedButton;
    StatusBar1: TStatusBar;
    procedure btnCHANClick(Sender: TObject);
    procedure btnFREQClick(Sender: TObject);
    procedure btnMODE1Click(Sender: TObject);
    procedure btnMODEClick(Sender: TObject);
    procedure eChanKeyPress(Sender: TObject; var Key: char);
    procedure eFreqKeyPress(Sender: TObject; var Key: char);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure mAproposClick(Sender: TObject);
    procedure mEgalClick(Sender: TObject);
    procedure mProtocoleYeasuClick(Sender: TObject);
    procedure mQuitterClick(Sender: TObject);
    procedure mParamSourceClick(Sender: TObject);
    procedure mParamCodanClick(Sender: TObject);
    procedure serCodanStatus(Sender: TObject; Reason: THookSerialReason;
      const Value: string);
    procedure serSourceRxData(Sender: TObject);
    procedure serCodanRxData(Sender: TObject);
    procedure serSourceStatus(Sender: TObject; Reason: THookSerialReason;
      const Value: string);
    procedure SpeedButton1Click(Sender: TObject);
  private
    iniFile: TIniFile;
    commands: TStringList;
    cicsV2: boolean;
    protocoleCodan: boolean;
    separatorSign: TsysCharset;
    { Decompose les données en entrée en mode Codan pour extraire les comandes}
    procedure SplitInputData(s: string; aList: TStringList);
    { Decompose les données en entrée en mode Yeasu pour extraire les comandes}
    procedure SplitYeasuInputData(const s: string; aList: TStringList);
    {convertion des commandes en entrée au format CODAN CICS}
    function parseCodanData(command: string): string;
    procedure SendData2Codan(Data: string);
    { conversion des commandes Codan CICSV3 en CICSV2 }
    procedure ParseInputData(Data: string);
    { Conversion des commandes YEASU en commandes Codan CICS }
    procedure ParseYeasuInputData(Data: string);

    procedure getCodanChannel;
    procedure openPorts;

    function String2Hex(const Buffer: ansistring): string;
    function Hex2String(const Buffer: string): ansistring;
    function StringtoHex(Data: string): string;
  public

  end;

var
  FMain: TFMain;

implementation

{$R *.lfm}

{ TFMain }

procedure TFMain.mParamCodanClick(Sender: TObject);
begin
  serCodan.ShowSetupDialog;
  if serCodan.Device = emptyStr then
  begin
    ShowMessage('Aucun port pour le Codan configuré. Connexion impossible');
    exit;
  end;
  try
    serCodan.Open;
  except;
    begin
      ShowMessage('Ouverture du port "' + serCodan.Device +
        '" du Codan impossible. Vérifiez les paramètres');
      statusbar1.Panels[1].Text := 'Codan : erreur ouverture: ' + serCodan.Device;
      exit;
    end;
  end;
  statusbar1.Panels[1].Text := 'Codan connectée: ' + serCodan.Device;
  IniFile.WriteString('CODAN', 'port', serCodan.Device);
  getCodanChannel;

end;

procedure TFMain.serCodanStatus(Sender: TObject; Reason: THookSerialReason;
  const Value: string);
begin
  case Reason of
    HR_SerialClose: StatusBar1.Panels[1].Text := 'Port ' + Value + ' closed';
    HR_Connect: StatusBar1.Panels[1].Text := 'Port ' + Value + ' connected';
    //    HR_CanRead :   StatusBar1.SimpleText := 'CanRead : ' + Value ;
    //    HR_CanWrite :  StatusBar1.SimpleText := 'CanWrite : ' + Value ;
    //    HR_ReadCount : StatusBar1.SimpleText := 'ReadCount : ' + Value ;
    //    HR_WriteCount : StatusBar1.SimpleText := 'WriteCount : ' + Value ;
    HR_Wait: StatusBar1.Panels[1].Text := 'En attente : ' + Value;
  end;
end;

procedure TFMain.serSourceRxData(Sender: TObject);
var
  rxData: string;
begin
  rxData := trim(serSource.ReadData);
  if rxdata = emptyStr then
  begin
    exit;
  end;
  if protocoleCodan then
    parseInputData(rxData)
  else
  begin
    rxData := StringReplace(rxData, '', #00, [rfReplaceAll]);
    if rxData = emptyStr then
      exit;
    parseYeasuInputData(rxData);
  end;

end;

procedure TFMain.serCodanRxData(Sender: TObject);
var
  Data: string;
  command: string;
  i: integer;
begin
  Data := '';
  Data := serCodan.ReadData;
    command := data;
    if pos('?', command) = 0 then
    begin
      if ContainsText(command, 'CICS') then
      begin
        Caption := Caption + ' (' + command + ')';
      end;
      if ContainsText(command, 'FREQ') then
      begin
        frequenceDisplay.Text := ExtractWord(2, command, [' ']);
        infoDisplay.Caption := ExtractWord(3, command, [' ']);
      end;
      if ContainsText(command, 'SIDEBAND') then
      begin
        modeDisplay.Caption := ExtractWord(2, command, [':']);
        cbMode.Text := modeDisplay.Caption;
      end;
      if ContainsText(command, 'CHAN') then
      begin
        chanDisplay.Caption := ExtractWord(2, command, [':']);
        eChan.Text := trim(chanDisplay.Caption);
      end;
    end;
end;

procedure TFMain.serSourceStatus(Sender: TObject; Reason: THookSerialReason;
  const Value: string);
begin
  case Reason of
    HR_SerialClose: StatusBar1.Panels[2].Text := 'Port ' + Value + ' closed';
    HR_Connect: StatusBar1.Panels[2].Text := 'Port ' + Value + ' connected';
    //    HR_CanRead :   StatusBar1.SimpleText := 'CanRead : ' + Value ;
    //    HR_CanWrite :  StatusBar1.SimpleText := 'CanWrite : ' + Value ;
    //    HR_ReadCount : StatusBar1.SimpleText := 'ReadCount : ' + Value ;
    //    HR_WriteCount : StatusBar1.SimpleText := 'WriteCount : ' + Value ;
    HR_Wait: StatusBar1.Panels[2].Text := 'En attente : ' + Value;
  end;
end;

procedure TFMain.SpeedButton1Click(Sender: TObject);
begin
  eFreq.Clear;
end;

procedure TFMain.FormCreate(Sender: TObject);
begin
  commands := TStringList.Create();
  IniFile := TIniFile.Create(GetAppConfigFile(False) + '.conf');
end;

procedure TFMain.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  if MessageDlg('Question', 'Voulez vous fermer l''application?',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    serCodan.Close;
    serSource.Close;
    CanClose := True;
  end;
end;

procedure TFMain.btnFREQClick(Sender: TObject);
var
  i: integer;
begin
  if eFreq.Text = emptyStr then
  begin
    showmessage('Veuillez saisir une fréquence en Khz sans décimales');
    exit;
  end;
  i := StrToInt(eFreq.Text);
  if (i < 250) or (i > 30000) then
  begin
    ShowMessage('La fréquence doit être comprise' +  #13 + 'entre 0,250 Mhz et 30 Mhz');
    exit;
  end;
  if eFreq.Text <> emptyStr then
  begin
    sendData2Codan('FREQ=' + eFreq.Text);
    getCodanChannel;
  end;
end;

procedure TFMain.btnMODE1Click(Sender: TObject);
begin
  sendData2Codan('MUTE=' + cbMute.Text);
end;

procedure TFMain.btnCHANClick(Sender: TObject);
begin
  sendData2Codan('CHAN=' + eChan.Text);
  getCodanChannel;
end;

procedure TFMain.btnMODEClick(Sender: TObject);
begin
  sendData2Codan('SB=' + cbMode.Text);
  getCodanChannel;
end;


procedure TFMain.eChanKeyPress(Sender: TObject; var Key: char);
begin
  if key = #13 then
  begin
    sendData2Codan('CHAN=' + eChan.Text);
    getCodanChannel;
  end;
end;

procedure TFMain.eFreqKeyPress(Sender: TObject; var Key: char);
begin
  if key = #13 then
  begin
    sendData2Codan('FREQ=' + eFreq.Text);
    getCodanChanneL;
  end;
end;

procedure TFMain.FormDestroy(Sender: TObject);
begin
  commands.Free;
  IniFile.Free;
end;

procedure TFMain.FormShow(Sender: TObject);
begin
  cicsV2 := mCICS.Checked;
  eFreq.Clear;
  protocoleCodan := IniFile.ReadBool('PROTOCOLE', 'codan', True);
  if protocoleCodan then
  begin
    mProtocoleYeasu.Checked := False;
    serSource.RcvLineCRLF := True;
    serSource.SynSer.ConvertLineEnd := True;
    statusbar1.Panels[2].Text := 'Mode Codan';
  end
  else
  begin
    mProtocoleYeasu.Checked := True;
    serSource.RcvLineCRLF := False;
    serSource.SynSer.ConvertLineEnd := False;
    statusbar1.Panels[2].Text := 'Mode Yeasu';
  end;

  mProtocoleYeasu.OnClick := @mProtocoleYeasuClick;

  if IniFile.ReadBool('PROTOCOLE', 'Egal', True) then
  begin
    separatorSign := ['='];
    mEgal.Checked := True;
  end
  else
  begin
    separatorSign := [' '];
    mEgal.Checked := False;
  end;
  mEgal.OnClick := @mEgalClick;
  openPorts;
  if serCodan.active then
  begin
    SendData2Codan('VER?');
    getCodanChannel;
    cbMute.Text:= 'VOICE';
    SendData2Codan('MUTE=VOICE');
  end;
  eFreq.Clear;
end;

procedure TFMain.mAproposClick(Sender: TObject);
var
  FApropos: TFApropos;
begin
  FApropos := TFApropos.Create(self);
  FApropos.ShowModal;
  FApropos.Free;
end;

procedure TFMain.mEgalClick(Sender: TObject);
begin
  if mEgal.Checked then
  begin
    separatorSign := ['='];
    Inifile.WriteBool('PROTOCOLE', 'Egal', True);
  end
  else
  begin
    separatorSign := [' '];
    Inifile.WriteBool('PROTOCOLE', 'Egal', False);
  end;
end;

procedure TFMain.mProtocoleYeasuClick(Sender: TObject);
begin
  if mProtocoleYeasu.Checked = False then
  begin
    protocoleCodan := True;
    serSource.RcvLineCRLF := True;
    IniFile.WriteBool('PROTOCOLE', 'codan', True);
    statusbar1.Panels[2].Text := 'Mode Codan';
  end
  else
  begin
    protocoleCodan := False;
    serSource.RcvLineCRLF := False;
    IniFile.WriteBool('PROTOCOLE', 'codan', False);
    statusbar1.Panels[2].Text := 'Mode Yeasu';
  end;
end;

procedure TFMain.mQuitterClick(Sender: TObject);
begin
  Close;
end;

procedure TFMain.mParamSourceClick(Sender: TObject);
begin
  serSource.ShowSetupDialog;
  if serSource.Device = emptyStr then
  begin
    ShowMessage('Aucun port source configuré. Acquisition des commandes impossible');
    exit;
  end;
  try
    serSource.Open;
  except;
    begin
      ShowMessage('Ouverture du port "' + serSource.Device +
        '" pour la source impossible. Vérifiez les paramètres');
      statusbar1.Panels[0].Text := 'Source : erreur ouverture: ' + serSource.Device;
      exit;
    end;
  end;
  statusbar1.Panels[0].Text := 'Source connectée: ' + serSource.Device;
  IniFile.WriteString('SOURCE', 'port', serSource.Device);
end;

procedure TFMain.SplitInputData(s: string; aList: TStringList);
begin
  //s := StringReplace(s, #10, '', [rfReplaceAll]);
  aList.Delimiter := #13;
  aList.StrictDelimiter := True; // Spaces excluded from being a delimiter
  aList.DelimitedText := s;
end;

procedure TFMain.SplitYeasuInputData(const s: string; aList: TStringList);
begin
  aList.Delimiter := ';';
  aList.StrictDelimiter := True; // Spaces excluded from being a delimiter
  aList.DelimitedText := s;
end;


procedure TFMain.ParseInputData(Data: string);
var
  command: string;
  i: integer;
  frequency: double;
  cmd: string;
begin
  begin
    SplitInputData(Data, commands);
    for i := 0 to commands.Count - 1 do
    begin
      command := commands[i];
      if ContainsText(command, 'FREQ') then
      begin
        if length(command) = length('FREQ') then
        begin
          sersource.WriteData('FREQ: 7074 RX/TX' + #13#10);
          exit;
        end;
        command := stringReplace(command, '.', DecimalSeparator, [rfReplaceAll]);
        frequency := StrToFloat(trim(ExtractWord(2, command, separatorSign)));
        if CICSV2 then
        begin
          cmd := 'FREQ=' + IntToStr(trunc(frequency));
        end
        else
          cmd := 'FREQ=' + FormatFloat('#####.0', frequency);
      end;
      if ContainsText(command, 'CICS') then
        Caption := 'CodanRemote (' + command + ')';
      if (ContainsText(command, 'MODE')) or (ContainsText(command, 'SB')) then
        cmd := 'SB=' + trim(ExtractWord(2, command, separatorSign));
      if length(cmd) > 0 then
      begin
        SendData2Codan(cmd);
        getCodanChannel;
      end;
    end;
  end;
end;

procedure TFMain.ParseYeasuInputData(Data: string);
var
  command: string = '';
  freq: qWord;
  cmd: string;
  str: string;
begin
  command := trim(Data);
  if ContainsText(command, 'FA') then
  begin
    str := trim(copy(command, 3, length(command)));
    str := stringreplace(str, ';', '', [rfReplaceAll]);
    str := stringreplace(str, '.', DecimalSeparator, [rfReplaceAll]);
    freq := StrToInt(str);
    if CICSV2 then
      cmd := 'FREQ=' + IntToStr(round(freq / 10))
    else
      cmd := 'FREQ=' + IntToStr(round(freq / 10));
  end;

  if ContainsText(command, 'MD') then
  begin
    cmd := copy(command, 3, 5);
    if (cmd = '2') or (cmd = 'C') or (cmd = '9') then
      cmd := 'SB=USB'
    else
      cmd := 'SB=LSB';
  end;
  if length(cmd) > 0 then
  begin
    SendData2Codan(cmd);
    getCodanChannel;
  end;
end;

function TFMain.parseCodanData(command: string): string;
var
  param: string = '';
  freq: string;
  s: string;
begin

  if protocoleCodan then
  begin
    if cicsV2 then
    begin
      if ContainsStr(command, 'FREQ=') then
      begin
        s := copy(param, 0, length(param) - 1);
        insert(' ', s, rpos('.', s));
        freq := Copy2Symb(param, '.');
        Result := 'FREQ=' + freq + #13#10;
        exit;
      end
      else if ContainsStr(command, 'MODE=') then
      begin
        param := copy(command, rpos('=', command) + 1, length(command));
        s := copy(param, 0, length(param) - 1);
        Result := command + #13;
        exit;
      end;
    end;
    {TODO ajouter commmande pour CICS V3}
  end;
  Result := command + #13;
end;

procedure TFmain.getCodanChannel;
begin
  SendData2Codan('FREQ?');
  SendData2Codan('SB?');
  SendData2Codan('CHAN?');
end;

procedure TFMain.SendData2Codan(Data: string);
begin
  serCodan.WriteData(Data + #13#10);
  //getCodanChannel;
end;

function TFMain.String2Hex(const Buffer: ansistring): string;
begin
  SetLength(Result, Length(Buffer) * 2);
  BinToHex(pansichar(Buffer), PChar(Result), Length(Buffer));
end;

function TFMain.Hex2String(const Buffer: string): ansistring;
begin
  SetLength(Result, Length(Buffer) div 2);
  HexToBin(PChar(Buffer), pansichar(Result), Length(Result));
end;

// Converts String To Hexadecimal
// Maybe usefull for a hex-editor
// For example:
//     Input = 'ABCD'
//     Output = '41 42 43 44'

function TFMain.StringtoHex(Data: string): string;
var
  i, i2: integer;
  s: string = '';
begin
  i2 := 1;
  for i := 1 to Length(Data) do
  begin
    Inc(i2);
    if i2 = 2 then
    begin
      s := s + ' ';
      i2 := 1;
    end;
    s := s + IntToHex(Ord(Data[i]), 2);
  end;
  Result := s;
end;

procedure TFMain.openPorts;
var
  ser: string = '';
begin
  ser := Inifile.ReadString('CODAN', 'port', '');
  if ser <> EmptyStr then
  begin
    serCodan.Device := ser;
    try
      serCodan.Open;
      statusbar1.Panels[1].Text := 'Codan : ' + ser;
    except
      ShowMessage('Ouverture du port "' + ser +
        '" impossible. Vérifiez les paramètres');
      statusbar1.Panels[1].Text := 'Codan erreur ouverture: ' + ser;
    end;
  end
  else
  begin
    statusbar1.Panels[1].Text := 'Codan non connecté : ' + ser;
  end;
  ser := Inifile.ReadString('SOURCE', 'port', '');
  if ser <> EmptyStr then
  begin
    serSource.Device := ser;
    try
      serSource.Open;
      statusbar1.Panels[0].Text := 'Source : ' + ser;
    except
      ShowMessage('Ouverture du port "' + ser +
        '" impossible. Vérifiez les paramètres');
      statusbar1.Panels[0].Text := 'Source : erreur ouverture: ' + ser;
    end;
  end
  else
  begin
    statusbar1.Panels[0].Text := 'Source non connecté : ' + ser;
  end;
end;

end.
