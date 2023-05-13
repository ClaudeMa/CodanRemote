unit datamodule;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, DB, Menus, ZConnection, ZDataset;

type

  { TFDataModule }

  TFDataModule = class(TDataModule)
    Connection: TZConnection;
    dsCanaux: TDataSource;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    QueryCanaux: TZQuery;
    queryFonction: TZQuery;
    tblCanaux: TZTable;
  private

  public

  end;

var
  FDataModule: TFDataModule;

implementation

{$R *.lfm}

end.

