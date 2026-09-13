

unit Engine.IDE.Register;

interface

procedure Register;

implementation

uses
  System.SysUtils, System.Classes, System.IniFiles,
  Vcl.Forms, Vcl.Menus, Vcl.ActnList, Vcl.ComCtrls, Vcl.Controls, Vcl.ImgList,
  ToolsAPI,

  DesignIntf,
  Engine.IDE.ViewportFrame;

const
  VIEWPORT_ID = 'JojosEngineViewport';
  VIEWPORT_CAPTION = 'Jojos Viewport';
  MENU_ITEM_NAME = 'JojosViewportMenuItem';

type
  TJojosViewportDockable = class(TInterfacedObject, INTACustomDockableForm)
  public

    function GetCaption: string;
    function GetIdentifier: string;
    function GetFrameClass: TCustomFrameClass;
    procedure FrameCreated(AFrame: TCustomFrame);
    function GetMenuActionList: TCustomActionList;
    function GetMenuImageList: TCustomImageList;
    procedure CustomizePopupMenu(PopupMenu: TPopupMenu);
    function GetToolbarActionList: TCustomActionList;
    function GetToolbarImageList: TCustomImageList;
    procedure CustomizeToolBar(ToolBar: TToolBar);
    procedure LoadWindowState(Desktop: TCustomIniFile; const Section: string);
    procedure SaveWindowState(Desktop: TCustomIniFile; const Section: string;
      IsProject: Boolean);
    function GetEditState: TEditState;
    function EditAction(Action: TEditAction): Boolean;
  end;

var

  GDockable: INTACustomDockableForm = nil;
  GViewportForm: TCustomForm = nil;
  GMenuItem: TMenuItem = nil;

function TJojosViewportDockable.GetCaption: string;
begin
  Result := VIEWPORT_CAPTION;
end;

function TJojosViewportDockable.GetIdentifier: string;
begin

  Result := VIEWPORT_ID;
end;

function TJojosViewportDockable.GetFrameClass: TCustomFrameClass;
begin
  Result := TJojosViewportFrame;
end;

procedure TJojosViewportDockable.FrameCreated(AFrame: TCustomFrame);
begin

end;

function TJojosViewportDockable.GetMenuActionList: TCustomActionList;
begin
  Result := nil;
end;

function TJojosViewportDockable.GetMenuImageList: TCustomImageList;
begin
  Result := nil;
end;

procedure TJojosViewportDockable.CustomizePopupMenu(PopupMenu: TPopupMenu);
begin
end;

function TJojosViewportDockable.GetToolbarActionList: TCustomActionList;
begin
  Result := nil;
end;

function TJojosViewportDockable.GetToolbarImageList: TCustomImageList;
begin
  Result := nil;
end;

procedure TJojosViewportDockable.CustomizeToolBar(ToolBar: TToolBar);
begin
end;

procedure TJojosViewportDockable.LoadWindowState(Desktop: TCustomIniFile;
  const Section: string);
begin
end;

procedure TJojosViewportDockable.SaveWindowState(Desktop: TCustomIniFile;
  const Section: string; IsProject: Boolean);
begin
end;

function TJojosViewportDockable.GetEditState: TEditState;
begin
  Result := [];
end;

function TJojosViewportDockable.EditAction(Action: TEditAction): Boolean;
begin
  Result := False;
end;

procedure MostraViewport;
var
  Services: INTAServices;
begin
  Services := BorlandIDEServices as INTAServices;
  if Services = nil then
    Exit;

  if GViewportForm = nil then
    GViewportForm := Services.CreateDockableForm(GDockable);

  if GViewportForm <> nil then
  begin
    GViewportForm.Show;
    GViewportForm.BringToFront;
  end;
end;

type
  TMenuHandler = class
    procedure Clique(Sender: TObject);
  end;

procedure TMenuHandler.Clique(Sender: TObject);
begin
  MostraViewport;
end;

var
  GHandler: TMenuHandler = nil;

procedure AdicionaMenu;
var
  Services: INTAServices;
  MenuPrincipal: TMainMenu;
  ItemView: TMenuItem;
  I: Integer;
begin
  Services := BorlandIDEServices as INTAServices;
  if Services = nil then
    Exit;

  MenuPrincipal := Services.MainMenu;
  if MenuPrincipal = nil then
    Exit;

  ItemView := nil;
  for I := 0 to MenuPrincipal.Items.Count - 1 do
    if SameText(MenuPrincipal.Items[I].Name, 'ViewsMenu') or
       SameText(MenuPrincipal.Items[I].Name, 'ViewMenu') then
    begin
      ItemView := MenuPrincipal.Items[I];
      Break;
    end;

  if ItemView = nil then
    ItemView := MenuPrincipal.Items;

  GHandler := TMenuHandler.Create;

  GMenuItem := TMenuItem.Create(nil);
  GMenuItem.Name := MENU_ITEM_NAME;
  GMenuItem.Caption := VIEWPORT_CAPTION;
  GMenuItem.OnClick := GHandler.Clique;
  ItemView.Add(GMenuItem);
end;

procedure RemoveMenu;
begin
  FreeAndNil(GMenuItem);
  FreeAndNil(GHandler);
end;

procedure Register;
var
  Services: INTAServices;
begin

  GDockable := TJojosViewportDockable.Create;

  Services := BorlandIDEServices as INTAServices;
  if Services <> nil then
    Services.RegisterDockableForm(GDockable);

  AdicionaMenu;
end;

initialization

finalization
  RemoveMenu;

  if GDockable <> nil then
  begin
    if BorlandIDEServices <> nil then
      (BorlandIDEServices as INTAServices).UnregisterDockableForm(GDockable);
    GDockable := nil;
  end;
  GViewportForm := nil;

end.
