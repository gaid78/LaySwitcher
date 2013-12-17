unit LaySwitch;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Classes,
  Controls,
  StdCtrls,
  Forms,
  Dialogs,
  extctrls,
  StrUtils,
  typinfo;

Const
  BELARUSSIAN = LANG_BELARUSIAN;
  RUS = LANG_RUSSIAN;
  ENG = LANG_ENGLISH;
  BLR = LANG_BELARUSIAN;

type
  TOnLayoutChange = procedure(Sender: tobject;Lang: string) of object;
  TLanguageKeyBord = (NONE, ENGLISH, RUSSIAN, BELARUSIAN);

  TComponentsEvents = class
  private
    FOnEnter:TNotifyEvent;
    FOnExit:TNotifyEvent;
    FLang:String;
    procedure SetOnEnter(const Value: TNotifyEvent);
    procedure SetOnExit(const Value: TNotifyEvent);
    procedure SetLanguage(const Value: String);
  public
    Constructor Create;
    property OnEnter:TNotifyEvent read FOnEnter write SetOnEnter;
    property OnExit:TNotifyEvent read FOnExit write SetOnExit;
    property Language:String read FLang write SetLanguage;
  end;

  TComponentsList = class (TStringList)
  public
    constructor Create;
    function Add(const S: string): Integer; override;
    procedure Delete(Index: Integer);override;
  end;

  TLanguageListExt = class
  private
    FLangID:String;
    FLoadedID:HKL;
  public
    constructor Create(Langs:String);
    property LangID:String read FLangID;
    property LoadedId:HKL read FLoadedID write FLoadedID;
  end;

  TLanguageList = class(TStringList)
  public
    constructor Create;
    destructor Destroy; override;
    function Find(const S: string; var Index: Integer): Boolean;override;
    procedure SwitchToLang(Lang:String);
    procedure Delete(Index: Integer);override;
    procedure UnLoadAllLang;
  end;

  TLayoutSwitcher = Class(TComponent)
   private
    FCompsList: TComponentsList;
    FOnLayoutChange: TOnLayoutChange;
    FRestoreLayoutOnExit: boolean;
    class var CurentLanguage: Hkl;
    class var OldOnActivate: TNotifyEvent;
    class var OldOnDeactivate: TNotifyEvent;
    class var HLANG_ENGLISH: HKL;
    class var HLANG_RUSSIAN: HKL;
    class var HLANG_BELARUSIAN: HKL;
    class var LangDefault: integer;
    function GetLangList: TStringList;
   protected
    class Function GetKblLayoutName: String;
    procedure SetSwitch(Sender: TWinControl; Lang: integer);
    procedure SetRussianLayout(Sender: Tobject);
    procedure SetBelaRusianLayout(Sender: Tobject);
    procedure SetEnglishLayout(Sender: Tobject);
    procedure SetLangeageLayout(Sender: Tobject);
    procedure RestoreLayout(Sender: Tobject);
    class Function PrimaryLangId(Lang: Integer): Integer;
    Function SubLangId(Lang: Integer): Integer;
    class Function GetLangId: Integer;
    class Function MakeLangId(PLang, SLang: Integer): String;
    procedure DoOldOnEnter(Sender: TObject);
    procedure DoOldOnExit(Sender: TObject);
    procedure DoLangOnEnter(Sender: TObject);
    class procedure OnApplicationDeactivate(Sender: TObject);
    class procedure OnApplicationActivate(Sender: TObject);
  public
    Constructor Create(AOwner: TComponent); override;
    Destructor Destroy; override;
    procedure Add(Accessor: TWinControl; Lang: integer); overload;
    procedure Add(Accessor: TWinControl; Lang: TLanguageKeyBord); overload;
    procedure Add(Accessor: TWinControl; Lang: String); overload;
    procedure Remove(Accessor: TWinControl);
    procedure SwitchToLang(Lang:String);
    class procedure SwitchToRussian;
    class procedure SwitchToBelarusian;
    class procedure SwitchToEnglish;
    function GetActiveLang: string;
    property LanguageList:TStringList read GetLangList;
  published
    Property RestoreLayoutOnExit: boolean read FRestoreLayoutOnExit write FRestoreLayoutOnExit;
    property OnLayoutChange: TOnLayoutChange read FOnLayoutChange write FOnLayoutChange;
  end;

  function isList(AList: array of HKL;Lang: HKL): boolean;


implementation

var
    AList: array[0..254] of Hkl;
    FLangList:TLanguageList;

const
  KLF_SETFORPROCESS = $100;

resourcestring
  Err_Unique = 'Компонент с именем %S находится в списке.';
  NoFindLayout = 'Расскладка "%s" не найдена в списке.';
{
  Err_Unique = 'The component with the name %S is in the list.';
  NoFindLayout = 'The apportion isn't found in the list.';
}

{$IF (NOT DEFINED(VER180)) OR (NOT DEFINED(VER185))}
 NEED FODING for UNICODE
{$IFEND}

function HEX2BIN(HEX: string): string;
var
  BIN: string;
  I: INTEGER;
  Error: BOOLEAN;

begin
  Error := False;
  BIN := '';
  for I := 1 to Length(HEX) do
    case UpCase(HEX[I]) of
      '0': BIN := BIN + '0000';
      '1': BIN := BIN + '0001';
      '2': BIN := BIN + '0010';
      '3': BIN := BIN + '0011';
      '4': BIN := BIN + '0100';
      '5': BIN := BIN + '0101';
      '6': BIN := BIN + '0110';
      '7': BIN := BIN + '0111';
      '8': BIN := BIN + '1000';
      '9': BIN := BIN + '1001';
      'A': BIN := BIN + '1010';
      'B': BIN := BIN + '1011';
      'C': BIN := BIN + '1100';
      'D': BIN := BIN + '1101';
      'E': BIN := BIN + '1110';
      'F': BIN := BIN + '1111';
    else
      Error := True;
    end;
  if Error then
    HEX2BIN := '0'
  else
    HEX2BIN := BIN;
end;
function BIN2DEC(BIN: string): LONGINT;
var
  J: LONGINT;
  Error: BOOLEAN;
  DEC: LONGINT;
begin
  DEC := 0;
  Error := False;
  for J := 1 to Length(BIN) do
  begin
    if (BIN[J] <> '0') and (BIN[J] <> '1') then
      Error := True;
    if BIN[J] = '1' then
      DEC := DEC + (1 shl (Length(BIN) - J));
    { (1 SHL (Length(BIN) - J)) = 2^(Length(BIN)- J) }
  end;
  if Error then
    BIN2DEC := 0
  else
    BIN2DEC := DEC;
end;



function HexToInt(HexNum: string): LongInt;
begin
   Result := StrToInt('$' + HexNum);
end;

function MakeLangId(PLang, SLang: byte): string;
begin
  MakeLangId := IntToHex(((SLang shl 10) or PLang), 8);
end;

procedure TLayoutSwitcher.Add(Accessor: TWinControl; Lang: TLanguageKeyBord);
begin
  case Lang of
  ENGLISH: Add(Accessor, LANG_ENGLISH);
  RUSSIAN: Add(Accessor, LANG_RUSSIAN);
  BELARUSIAN: Add(Accessor, LANG_BELARUSIAN);
  else
     begin
      Raise Exception.Create('Не определен язык!');
     end;
  end;
end;

procedure TLayoutSwitcher.Add(Accessor: TWinControl; Lang: String);
Var
   Index:Integer;
   EdTmp:TEdit;
begin
  EdTmp := TEdit(accessor);
  index:=FCompsList.add(accessor.name);
  (FCompsList.Objects[index] as TComponentsEvents).Language:=Lang;
  if assigned(edtmp.OnEnter) then
    (FCompsList.Objects[index] as TComponentsEvents).OnEnter:=edtmp.OnEnter;

  if assigned(edtmp.OnExit) then
    (FCompsList.Objects[index] as TComponentsEvents).OnExit:=edtmp.OnExit;

end;

Constructor TLayoutSwitcher.Create(AOwner: TComponent);
begin
  inherited Create(Aowner);
  FCompsList := TComponentsList.Create;
end;

class Function TLayoutSwitcher.MakeLangId(PLang, SLang: Integer): String;
begin
  MakeLangId := IntToHex(((SLang Shl 10) OR PLang), 8);
end;

class procedure TLayoutSwitcher.OnApplicationActivate(Sender: TObject);
begin
  case CurentLanguage of
   BLR: SwitchToBelarusian;
   RUS: SwitchToRussian;
   ENG: SwitchToEnglish;
  end;
  if Assigned(OldOnActivate) then
    OldOnActivate(Sender);
end;

class procedure TLayoutSwitcher.OnApplicationDeactivate(Sender: TObject);
begin
  CurentLanguage := GetLangId;
  case LangDefault of
   BLR: SwitchToBelarusian;
   RUS: SwitchToRussian;
   ENG: SwitchToEnglish;
  end;
  if not isList(AList,HLANG_ENGLISH) then
  begin
   HLANG_ENGLISH := 0;
   UnloadKeyboardLayout(HLANG_ENGLISH);
  end;
  if not isList(AList,HLANG_RUSSIAN) then
  begin
   UnloadKeyboardLayout(HLANG_RUSSIAN);
   HLANG_RUSSIAN := 0;
  end;
  if not isList(AList,HLANG_BELARUSIAN) then
  begin
   UnloadKeyboardLayout(HLANG_BELARUSIAN);
   HLANG_BELARUSIAN := 0;
  end;
  FLangList.UnLoadAllLang;
  if Assigned(OldOnDeactivate) then
    OldOnDeactivate(Sender);
end;

function TLayoutSwitcher.GetActiveLang: string;
var
  id: integer;
begin
  id := getlangid;
  case id of
    BLR: getactivelang := 'BE';
    RUS: getactivelang := 'RU';
    ENG: getactivelang := 'EN';
  end;
end;

class Function TLayoutSwitcher.PrimaryLangId(Lang: Integer): Integer;
begin
  PrimaryLangId := Lang AND $3FF;
end;

Function TLayoutSwitcher.SubLangId(Lang: Integer): Integer;
begin
  SubLangId := Lang Shr 10;
end;

class Function TLayoutSwitcher.GetLangId: Integer;
begin
  GetLangId := PrimaryLangId(HexToInt(GetKblLayoutName));
end;

function TLayoutSwitcher.GetLangList: TStringList;
begin
 result:=(FLangList as TStringList);
end;

procedure TLayoutSwitcher.RestoreLayout;
var
  lang: HKL;
begin
  case getlangid of
    ENG: lang := HLANG_ENGLISH;
    RUS: lang := HLANG_RUSSIAN;
    BLR: lang := HLANG_BELARUSIAN;
    else lang := HLANG_ENGLISH;
  end;
  ActivateKeyboardLayout(lang, KLF_SETFORPROCESS);
  DoOldOnExit(Sender);
end;

procedure TLayoutSwitcher.SetRussianLayout(Sender: Tobject);
begin
  SwitchToRussian;
  DoOldOnEnter(Sender);
  if Assigned(FOnLayoutChange) then
    FOnLayoutChange(Self, 'RU');
end;

procedure TLayoutSwitcher.SetBelaRusianLayout(Sender: Tobject);
begin
  SwitchToBelarusian;
  DoOldOnEnter(Sender);
end;

procedure TLayoutSwitcher.SetEnglishLayout(Sender: Tobject);
begin
  SwitchToEnglish;
  DoOldOnEnter(Sender);
  if Assigned(FOnLayoutChange) then FOnLayoutChange(Self,'EN');
end;

procedure TLayoutSwitcher.SetLangeageLayout(Sender: Tobject);
Var
   Index:Integer;
begin
 if FCompsList.Find((Sender as TEdit).Name, index) then
  Begin

  End;
end;

Destructor TLayoutSwitcher.Destroy;
begin
  fcompslist.free;
  inherited Destroy;
end;

class procedure TLayoutSwitcher.SwitchToRussian;
begin
if HLANG_RUSSIAN = 0 then
  HLANG_RUSSIAN := LoadKeyboardLayout(pchar(makelangid(integer(LANG_RUSSIAN), sublang_default)),
   KLF_SETFORPROCESS );
  ActivateKeyboardLayout(HLANG_RUSSIAN, KLF_SETFORPROCESS);
end;

class procedure TLayoutSwitcher.SwitchToBelarusian;
begin
  if HLANG_BELARUSIAN=0 then
    HLANG_BELARUSIAN := LoadKeyboardLayout(pchar(makelangid(integer(LANG_BELARUSIAN), sublang_default)),
                                            KLF_SETFORPROCESS );
  ActivateKeyboardLayout(HLANG_BELARUSIAN, KLF_SETFORPROCESS);
end;

class procedure TLayoutSwitcher.SwitchToEnglish;
begin
  if HLANG_ENGLISH=0 then
  HLANG_ENGLISH := LoadKeyboardLayout(pchar(makelangid(integer(LANG_ENGLISH), sublang_default)),
    KLF_SETFORPROCESS);
  ActivateKeyboardLayout(HLANG_ENGLISH, KLF_SETFORPROCESS);
end;

procedure TLayoutSwitcher.SwitchToLang(Lang: String);
begin
 FLangList.SwitchToLang(Lang);
end;

class Function TLayoutSwitcher.GetKblLayoutName: String;
Var KLN: PChar;
begin
  KLN := StrAlloc(KL_NAMELENGTH+1);
  GetKeyboardLayoutName(KLN);
  GetKblLayoutName := StrPas(KLN);
  StrDispose(KLN);
end;

procedure TLayoutSwitcher.SetSwitch(Sender: TWinControl; Lang: integer);
Var
   a: integer;
   sender1: tcomponent;
begin
  Case Lang of
   lang_russian: begin
                   if (sender is tcustomform) or (sender is tcustompanel) then begin
                     for a := 0 to sender.Componentcount-1 do begin
                       sender1 := sender.components[a];
                       if (getpropinfo(sender1,'OnEnter')<>nil) and (getpropinfo(sender1,'OnExit')<>nil) then begin
                         TEdit(Sender1).OnEnter := SetRussianLayout;
                         if FRestoreLayoutOnExit then TEdit(Sender1).OnExit := RestoreLayout;
                       end;
                     end;
                   end
                   else if (getpropinfo(sender,'OnEnter')<>nil) and (getpropinfo(sender,'OnExit')<>nil) then begin
                     TEdit(Sender).OnEnter := setRussianLayout;
                     if FRestoreLayoutOnExit then TEdit(Sender).OnExit := RestoreLayout;
                   end;
                 end;
   lang_belarusian: begin
                      if (sender is tcustomform) or (sender is tcustompanel) then begin
                        for a := 0 to sender.ComponentCount-1 do begin
                          sender1 := sender.components[a];
                          if (getpropinfo(sender1,'OnEnter')<>nil) and (getpropinfo(sender1,'OnExit')<>nil) then begin
                            TEdit(Sender1).OnEnter := setBelarusianLayout;
                            if FRestoreLayoutOnExit then TEdit(Sender1).OnExit := RestoreLayout;
                          end;
                        end;
                      end
                      else if (getpropinfo(sender,'OnEnter')<>nil) and (getpropinfo(sender,'OnExit')<>nil) then begin
                        TEdit(Sender).OnEnter := setBelarusianLayout;
                        if FRestoreLayoutOnExit then TEdit(Sender).OnExit := RestoreLayout;
                      end;
                    end;

   lang_English: begin
                   if (sender is tcustomform) or (sender is tcustompanel) then begin
                     for a := 0 to sender.ComponentCount-1 do begin
                       sender1 := sender.components[a];
                       if (getpropinfo(sender1,'OnEnter')<>nil) and (getpropinfo(sender1,'OnExit')<>nil) then begin
                         TEdit(Sender1).OnEnter := setEnglishLayout;
                         if FRestoreLayoutOnExit then TEdit(Sender1).OnExit := RestoreLayout;
                       end;
                     end;
                   end
                   else if (getpropinfo(sender,'OnEnter')<>nil) and (getpropinfo(sender,'OnExit')<>nil) then begin
                     TEdit(Sender).OnEnter := setEnglishLayout;
                     if FRestoreLayoutOnExit then TEdit(Sender).OnExit := RestoreLayout;
                   end;
                 end;
  end;
end;

procedure TLayoutSwitcher.Add(Accessor: TWinControl; Lang: integer);
Var EdTmp: TEdit;
    index: integer;
begin
  if (lang<>lang_russian) and (lang<>lang_english) and (lang<>lang_belarusian) then begin
    messagedlg('Неизвестный язык для '+accessor.name+'! ('+inttostr(lang)+')',mterror,[mbok],0);
    exit;
  end;

  EdTmp := TEdit(accessor);
  index:=FCompsList.add(accessor.name);
  if assigned(edtmp.OnEnter) then
    (FCompsList.Objects[index] as TComponentsEvents).OnEnter:=edtmp.OnEnter;

  if assigned(edtmp.OnExit) then
    (FCompsList.Objects[index] as TComponentsEvents).OnExit:=edtmp.OnExit;
  SetSwitch(Accessor, Lang);
end;

procedure TLayoutSwitcher.Remove(Accessor: TWinControl);
Var
  EdTmp: TEdit;
  ind: integer;
begin
  EdTmp := TEdit(Accessor);
  if FCompsList.Find(EdTmp.Name,ind) then
  begin
    EdTmp.OnEnter := (FCompsList.Objects[ind] as TComponentsEvents).OnEnter;
    EdTmp.OnExit := (FCompsList.Objects[ind] as TComponentsEvents).OnExit;
    FCompsList.Delete(ind);
  end;
end;

procedure TLayoutSwitcher.DoOldOnEnter(sender: TObject);
Var
  oldonenter: TNotifyEvent;
  index: integer;
begin
  if FCompsList.Find(TWinControl(Sender).Name,index) then
  begin
  oldonenter:=nil;
  oldonenter := (FCompsList.Objects[index] as TComponentsEvents).OnEnter;
  if Assigned(oldonenter) then oldonenter(Sender);
  end;
end;

procedure TLayoutSwitcher.DoOldOnExit(sender: TObject);
Var
  oldonexit: TNotifyEvent;
    index: integer;
begin
  if FCompsList.Find(TWinControl(Sender).Name,index) then
  begin
    oldonexit:=nil;
    oldonexit := (FCompsList.Objects[Index] as TComponentsEvents).OnExit;;
    if Assigned(oldonexit) then oldonexit(Sender);
  end;
end;

function isList(AList: array of HKL;Lang: HKL): boolean;
var
  I: integer;
begin
  result := false;
  for I := 0 to Length(AList)-1 do
  if AList[i]=Lang then
   Begin
    result := true;
    exit;
   End;
end;

{ TComponentsEvents }

constructor TComponentsEvents.Create;
begin
 FOnEnter:=NIL;
 FOnExit:=NIL;
 FLang:='';
end;

procedure TComponentsEvents.SetLanguage(const Value: String);
begin
  FLang := Value;
end;

procedure TComponentsEvents.SetOnEnter(const Value: TNotifyEvent);
begin
  FOnEnter := Value;
end;

procedure TComponentsEvents.SetOnExit(const Value: TNotifyEvent);
begin
  FOnExit := Value;
end;

{ TComponentsList }

function TComponentsList.Add(const S: string): Integer;
Var
   Index:Integer;
begin
 if Find(S, Index) then
  raise Exception.CreateResFmt(@Err_Unique, [S]);

 Result := AddObject(S, TComponentsEvents.Create);
end;

constructor TComponentsList.Create;
begin
  Sorted := true;
  Duplicates := dupError;
end;

procedure TComponentsList.Delete(Index: Integer);
begin
  (Objects[Index] as TComponentsEvents).Free;
  inherited;
end;


{ TLanguageListExt }

constructor TLanguageListExt.Create(Langs: String);
begin
 FLangID:=Langs;
 FLoadedID:=0;
end;

{ TLanguageList }

constructor TLanguageList.Create;
Var
  L:TLanguages;
  I:Integer;
  LStr1: String;
begin
  Sorted := true;
  Duplicates := dupError;
  L:=TLanguages.Create;
  for i := 0 to L.Count-1 do
   Begin
    LStr1:=L.ID[i];
    AddObject(L.Ext[i]+'-'+L.Name[i], TLanguageListExt.Create(Copy(LStr1,2,Length(LStr1))));
   End;
  L.Free;
end;

procedure TLanguageList.Delete(Index: Integer);
Var
   Lng:TLanguageListExt;
begin
 Lng:=nil;
 Lng:=(Objects[Index] as TLanguageListExt);
 if Lng.LoadedId<>0 then
  Begin
   if not isList(AList, Lng.LoadedId) then
    UnloadKeyboardLayout(Lng.LoadedId);
  End;
 (Objects[Index] as TLanguageListExt).Free;
  inherited;
end;

destructor TLanguageList.Destroy;
begin
  while count<>0 do
  begin
   Delete(count-1);
  end;
  inherited;
end;

function TLanguageList.Find(const S: string; var Index: Integer): Boolean;
Var
   I:Integer;
begin
 result:=inherited Find(s, index);
 if not result then
  Begin
    for i := 0 to Count-1 do
     if CompareStr(Copy(Strings[i],1,3*SizeOf(char)),S)=0 then
      Begin
        result:=true;
        Index:=i;
        exit;
      End;
  End;
end;

procedure TLanguageList.SwitchToLang(Lang: String);
Var
   I:Integer;
   Lng:TLanguageListExt;
begin
 if not Find(Lang, I) then
  Begin
   raise Exception.CreateResFmt(@NoFindLayout, [Lang]);
   exit;
  End;
 Lng:=nil;
 Lng:=(Objects[i] as TLanguageListExt);
 if Lng.LoadedId=0 then
    Lng.LoadedId := LoadKeyboardLayout(pchar(Lng.LangID), KLF_SETFORPROCESS );
 if Lng.LoadedId=0 then
   RaiseLastOSError;
 ActivateKeyboardLayout(Lng.LoadedId, KLF_SETFORPROCESS);

end;

procedure TLanguageList.UnLoadAllLang;
Var
   I:Integer;
   Lng:TLanguageListExt;
begin
 for I := 0 to count-1 do
  Begin
   Lng:=nil;
   Lng:=(Objects[i] as TLanguageListExt);
   if Lng.LoadedId<>0 then
    Begin
     if not isList(AList, Lng.LoadedId) then
      UnloadKeyboardLayout(Lng.LoadedId);
     Lng.LoadedId:=0;
    End;

  End;

end;

initialization
  TLayoutSwitcher.LangDefault := TLayoutSwitcher.GetLangId ;
  GetKeyboardLayoutList(255, AList);
  TLayoutSwitcher.HLANG_RUSSIAN := 0;
  TLayoutSwitcher.HLANG_BELARUSIAN := 0;
  TLayoutSwitcher.HLANG_ENGLISH := 0;
  FLangList:=TLanguageList.Create;

  TLayoutSwitcher.OldOnActivate := Application.OnActivate;
  TLayoutSwitcher.OldOnDeactivate := Application.OnDeactivate;

  Application.OnDeactivate := TLayoutSwitcher.OnApplicationDeactivate;
  Application.OnActivate := TLayoutSwitcher.OnApplicationActivate;

finalization
  if not isList(AList,TLayoutSwitcher.HLANG_ENGLISH) then
  UnloadKeyboardLayout(TLayoutSwitcher.HLANG_ENGLISH);

  if not isList(AList,TLayoutSwitcher.HLANG_RUSSIAN) then
  UnloadKeyboardLayout(TLayoutSwitcher.HLANG_RUSSIAN);

  if not isList(AList,TLayoutSwitcher.HLANG_BELARUSIAN) then
  UnloadKeyboardLayout(TLayoutSwitcher.HLANG_BELARUSIAN);

  Application.OnActivate := TLayoutSwitcher.OldOnActivate;
  Application.OnDeactivate := TLayoutSwitcher.OldOnDeactivate;

  FLangList.Free;

end.
