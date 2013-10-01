UNIT LaySwitch;

INTERFACE

USES
  Windows,
  Messages,
  SysUtils,
  Classes,
  Controls,
  StdCtrls,
  Forms,
  Dialogs,
  extctrls,
  typinfo;

Const

  BELARUSSIAN=LANG_BELARUSIAN;
  RUS=LANG_RUSSIAN;
  ENG=LANG_ENGLISH;
  BLR=LANG_BELARUSIAN;

TYPE
  TOnLayoutChange = procedure(Sender:tobject;Lang:string) of object;
   TLanguageKeyBord = (NONE, ENGLISH, RUSSIAN, BELARUSIAN);

  TEvent=class
    private
     FNotifyEvent:TNotifyEvent;
    public
     constructor Create(ANotifyEvent:TNotifyEvent);
     property NotifyEvent:TNotifyEvent read FNotifyEvent;
  end;

 TOnEnterList = class(TStringList)
   public
     function AddObject(const S: string; const ANotifyEvent: TNotifyEvent): Integer; reintroduce;virtual;
     procedure Delete(Index: Integer);override;

 end;

 TOnExitList = TOnEnterList;


  TLayoutSwitcher = Class(TComponent)
   Private
    FCompsList      : TStringList;
    FOnEnterList    : TOnEnterList;
    FOnExitList     : TOnExitList;
    FExtKey         : Boolean;
    FStateOn        : Boolean;
    FOnLayoutChange : TOnLayoutChange;
    FRestoreLayoutOnExit:boolean;
    //class var lastlayout      : Pchar;
    class var CurentLanguage:Hkl;
    class var OldOnActivate:TNotifyEvent;
    class var OldOnDeactivate:TNotifyEvent;
    class var HLANG_ENGLISH :HKL;
    class var HLANG_RUSSIAN :HKL;
    class var HLANG_BELARUSIAN :HKL;
    class var LangDefault:integer;
   Protected
    class Function GetKblLayoutName : String;
    Procedure SetSwitch(Sender: TWinControl; Lang : integer);
    Procedure SetRussianLayout(Sender:Tobject);
    Procedure SetBelaRusianLayout(Sender:Tobject);
    Procedure SetEnglishLayout(Sender:Tobject);
    Procedure RestoreLayout(Sender:Tobject);
    class Function PrimaryLangId(Lang : Integer) : Integer;
    Function SubLangId(Lang : Integer) : Integer;
    class Function GetLangId : Integer;
    class Function MakeLangId(PLang, SLang : Integer) : String;
    Procedure DoOldOnEnter(Sender:TObject);
    Procedure DoOldOnExit(Sender:TObject);
    class Procedure OnApplicationDeactivate(Sender:TObject);
    class Procedure OnApplicationActivate(Sender:TObject);
  Public
    Constructor Create(AOwner : TComponent); override;
    Destructor Destroy; override;
    Procedure Add(Accessor : TWinControl; Lang : integer); overload;
    Procedure Add(Accessor : TWinControl; Lang : TLanguageKeyBord); overload;
    Procedure Remove(Accessor : TWinControl);
    class Procedure SwitchToRussian;
    class Procedure SwitchToBelarusian;
    class Procedure SwitchToEnglish;
    function GetActiveLang:string;
  Published
    Property RestoreLayoutOnExit:boolean read FRestoreLayoutOnExit write FRestoreLayoutOnExit;
    property OnLayoutChange: TOnLayoutChange read FOnLayoutChange write FOnLayoutChange;
  End;

  function isList(AList:array of HKL;Lang:HKL):boolean;

IMPLEMENTATION

var
    AList : array[0..254] of Hkl;

const
 KLF_SETFORPROCESS = $100;

function HexToInt(HexNum: string): LongInt;
begin
   Result:=StrToInt('$' + HexNum) ;
end;

function MakeLangId(PLang, SLang: byte): string;
begin
  MakeLangId := IntToHex(((SLang shl 10) or PLang), 8);
end;

function TOnEnterList.AddObject(const S: string;const ANotifyEvent: TNotifyEvent): Integer;
begin
   result := inherited AddObject(S,TEvent.Create(ANotifyEvent));
end;

constructor TEvent.Create(ANotifyEvent: TNotifyEvent);
begin
   FNotifyEvent := ANotifyEvent;
end;

procedure TOnEnterList.Delete(Index: Integer);
begin
  (Objects[Index] as TEvent).Free;
  inherited;
end;


procedure TLayoutSwitcher.Add(Accessor: TWinControl; Lang: TLanguageKeyBord);
begin
 case Lang of
  ENGLISH:  Add(Accessor, LANG_ENGLISH);
  RUSSIAN: Add(Accessor, LANG_RUSSIAN);
  BELARUSIAN: Add(Accessor, LANG_BELARUSIAN);
  else
     Begin
      Raise Exception.Create('Не определен язык!');
     End;
 end;
end;

Constructor TLayoutSwitcher.Create(AOwner : TComponent);
Begin
 inherited Create(Aowner);
 FCompsList:=TStringList.Create;
 FCompsList.Sorted:=true;
 FCompsList.Duplicates:=dupError;
 FOnEnterList:=TOnEnterList.create;
 FOnEnterList.Sorted:=true;
 FOnEnterList.Duplicates:=dupError;
 FOnExitList:=TOnExitList.create;
 FOnExitList.Sorted:=true;
 FOnExitList.Duplicates:=dupError;
 FStateOn:=False;
 FExtKey:=False;
End;
{______________________________________________________________________________________________________________________}

class Function TLayoutSwitcher.MakeLangId(PLang, SLang : Integer) : String;
Begin
 MakeLangId:=IntToHex(((SLang Shl 10) OR PLang), 8);
End;
{______________________________________________________________________________________________________________________}

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

{______________________________________________________________________________________________________________________}

class procedure TLayoutSwitcher.OnApplicationDeactivate(Sender: TObject);
begin
 CurentLanguage := GetLangId;
  case LangDefault of
   BLR: SwitchToBelarusian;
   RUS: SwitchToRussian;
   ENG: SwitchToEnglish;
  end;
 if not isList(AList,HLANG_ENGLISH) then
  Begin
   HLANG_ENGLISH:=0;
   UnloadKeyboardLayout(HLANG_ENGLISH);
  End;
 if not isList(AList,HLANG_RUSSIAN) then
  Begin
   UnloadKeyboardLayout(HLANG_RUSSIAN);
   HLANG_RUSSIAN:=0;
  End;
 if not isList(AList,HLANG_BELARUSIAN) then
  Begin
   UnloadKeyboardLayout(HLANG_BELARUSIAN);
   HLANG_BELARUSIAN:=0;
  End;
 if Assigned(OldOnDeactivate) then
    OldOnDeactivate(Sender);
end;

function TLayoutSwitcher.GetActiveLang:string;
var
  id:integer;
Begin
  id:=getlangid;
  case id of
    BLR: getactivelang:='BE';
    RUS: getactivelang:='RU';
    ENG: getactivelang:='EN';
  end;
end;

class Function TLayoutSwitcher.PrimaryLangId(Lang : Integer) : Integer;
Begin
 PrimaryLangId:=Lang AND $3FF;
End;

Function TLayoutSwitcher.SubLangId(Lang : Integer) : Integer;
Begin
 SubLangId:=Lang Shr 10;
End;

class Function TLayoutSwitcher.GetLangId : Integer;
Begin
 GetLangId:=PrimaryLangId(HexToInt(GetKblLayoutName));
End;

Procedure TLayoutSwitcher.RestoreLayout;
var
  lang: HKL;
begin
  lang := HLANG_ENGLISH;
  case getlangid of
    ENG: lang := HLANG_ENGLISH;
    RUS: lang := HLANG_RUSSIAN;
    BLR: lang := HLANG_BELARUSIAN;
  end;
 ActivateKeyboardLayout(lang, KLF_SETFORPROCESS);
 DoOldOnExit(Sender);
end;

Procedure TLayoutSwitcher.SetRussianLayout(Sender:Tobject);
begin
 SwitchToRussian;
 DoOldOnEnter(Sender);
 if Assigned(FOnLayoutChange) then
   FOnLayoutChange(Self,'RU');
end;

Procedure TLayoutSwitcher.SetBelaRusianLayout(Sender:Tobject);
begin
   SwitchToBelarusian;
   DoOldOnEnter(Sender);
end;

Procedure TLayoutSwitcher.SetEnglishLayout(Sender:Tobject);
begin
  SwitchToEnglish;
  DoOldOnEnter(Sender);
  if Assigned(FOnLayoutChange) then FOnLayoutChange(Self,'EN');
end;

{______________________________________________________________________________________________________________________}

Destructor TLayoutSwitcher.Destroy;
Begin
 fcompslist.free;
 fonenterlist.free;
 fonexitlist.free;
 inherited Destroy;
End;
 {______________________________________________________________________________________________________________________}

class Procedure TLayoutSwitcher.SwitchToRussian;
begin
if HLANG_RUSSIAN=0 then
 HLANG_RUSSIAN:=   LoadKeyboardLayout(pchar(makelangid(integer(LANG_RUSSIAN), sublang_default)),
   KLF_SETFORPROCESS );
  ActivateKeyboardLayout(HLANG_RUSSIAN, KLF_SETFORPROCESS);
end;

class Procedure TLayoutSwitcher.SwitchToBelarusian;
begin
 if HLANG_BELARUSIAN=0 then
  HLANG_BELARUSIAN:= LoadKeyboardLayout(pchar(makelangid(integer(LANG_BELARUSIAN), sublang_default)),
    KLF_SETFORPROCESS );
 ActivateKeyboardLayout(HLANG_BELARUSIAN, KLF_SETFORPROCESS);
end;

class Procedure TLayoutSwitcher.SwitchToEnglish;
begin
 if HLANG_ENGLISH=0 then
  HLANG_ENGLISH:= LoadKeyboardLayout(pchar(makelangid(integer(LANG_ENGLISH), sublang_default)),
    KLF_SETFORPROCESS);
 ActivateKeyboardLayout(HLANG_ENGLISH, KLF_SETFORPROCESS);
end;

class Function TLayoutSwitcher.GetKblLayoutName : String;
Var KLN : PChar;
Begin
 KLN:=StrAlloc(KL_NAMELENGTH+1);
 GetKeyboardLayoutName(KLN);
 GetKblLayoutName:=StrPas(KLN);
 StrDispose(KLN);
End;

Procedure TLayoutSwitcher.SetSwitch(Sender: TWinControl; Lang : integer);
Var
   a:integer;
   sender1:tcomponent;
Begin
  Case Lang of
   lang_russian  :  begin
                       if (sender is tcustomform) or (sender is tcustompanel) then begin
                         for a:=0 to sender.Componentcount-1 do begin
                           sender1:=sender.components[a];
                           if (getpropinfo(sender1,'OnEnter')<>nil) and (getpropinfo(sender1,'OnExit')<>nil) then begin
                             TEdit(Sender1).OnEnter:=SetRussianLayout;
                             if FRestoreLayoutOnExit then TEdit(Sender1).OnExit:=RestoreLayout;
                           end;
                         end;
                       end
                       else if (getpropinfo(sender,'OnEnter')<>nil) and (getpropinfo(sender,'OnExit')<>nil) then begin
                         TEdit(Sender).OnEnter:=setRussianLayout;
                         if FRestoreLayoutOnExit then TEdit(Sender).OnExit:=RestoreLayout;
                       end;
                    end;
   lang_belarusian :  begin
                           if (sender is tcustomform) or (sender is tcustompanel) then begin
                           for a:=0 to sender.ComponentCount-1 do begin
                             sender1:=sender.components[a];
                             if (getpropinfo(sender1,'OnEnter')<>nil) and (getpropinfo(sender1,'OnExit')<>nil) then begin
                               TEdit(Sender1).OnEnter:=setBelarusianLayout;
                               if FRestoreLayoutOnExit then TEdit(Sender1).OnExit:=RestoreLayout;
                             end;
                           end;
                         end
                         else if (getpropinfo(sender,'OnEnter')<>nil) and (getpropinfo(sender,'OnExit')<>nil) then begin
                           TEdit(Sender).OnEnter:=setBelarusianLayout;
                           if FRestoreLayoutOnExit then TEdit(Sender).OnExit:=RestoreLayout;
                         end;
                      end;

   lang_English :  begin
                       if (sender is tcustomform) or (sender is tcustompanel) then begin
                       for a:=0 to sender.ComponentCount-1 do begin
                         sender1:=sender.components[a];
                         if (getpropinfo(sender1,'OnEnter')<>nil) and (getpropinfo(sender1,'OnExit')<>nil) then begin
                           TEdit(Sender1).OnEnter:=setEnglishLayout;
                           if FRestoreLayoutOnExit then TEdit(Sender1).OnExit:=RestoreLayout;
                         end;
                       end;
                     end
                     else if (getpropinfo(sender,'OnEnter')<>nil) and (getpropinfo(sender,'OnExit')<>nil) then begin
                       TEdit(Sender).OnEnter:=setEnglishLayout;
                       if FRestoreLayoutOnExit then TEdit(Sender).OnExit:=RestoreLayout;
                     end;
                   end;
  End;
End;

Procedure TLayoutSwitcher.Add(Accessor : TWinControl; Lang : integer);
Var EdTmp : TEdit;
    index : integer;
Begin
  if (lang<>lang_russian) and (lang<>lang_english) and (lang<>lang_belarusian) then begin
    messagedlg('Неизвестный язык для '+accessor.name+'! ('+inttostr(lang)+')',mterror,[mbok],0);
    exit;
  end;
 if FCompsList.Find(accessor.name, index) then exit;

  EdTmp:=TEdit(accessor);
  FCompsList.add(accessor.name);
  if assigned(edtmp.OnEnter) then
    FOnEnterList.AddObject(accessor.name,edtmp.OnEnter);

  if assigned(edtmp.OnExit) then
    FOnExitList.AddObject(accessor.name,edtmp.OnExit);
  SetSwitch(Accessor, Lang);
End;

Procedure TLayoutSwitcher.Remove(Accessor : TWinControl);
Var
  EdTmp : TEdit;
  ind:integer;
Begin
 EdTmp:=TEdit(Accessor);
 if FCompsList.Find(EdTmp.Name,ind) then
  begin
   EdTmp.OnEnter:=nil;
   FCompsList.Delete(ind);
  end;
 if FonenterList.Find(EdTmp.Name,ind) then
   FonenterList.Delete(ind);
 if FonexitList.Find(EdTmp.Name,ind) then
   FonexitList.Delete(ind);
End;

Procedure TLayoutSwitcher.DoOldOnEnter(sender : TObject);
Var
  oldonenter : TNotifyEvent;
  index:integer;
Begin
 if FonenterList.Find(TWinControl(Sender).Name,index) then
  begin
  oldonenter:=(FonenterList.Objects[index] as TEvent).NotifyEvent;
  if Assigned(oldonenter) then oldonenter(Sender);
  end;
end;

Procedure TLayoutSwitcher.DoOldOnExit(sender : TObject);
Var
  oldonexit : TNotifyEvent;
    index:integer;
Begin
 if FonexitList.Find(TWinControl(Sender).Name,index) then
  begin
   oldonexit:=(FonexitList.Objects[Index] as TEvent).NotifyEvent;;
   if Assigned(oldonexit) then oldonexit(Sender);
  end;
end;

function isList(AList:array of HKL;Lang:HKL):boolean;
var
 I:integer;
begin
 result  := false;
 for I := 0 to Length(AList)-1 do
  if AList[i]=Lang then
   result := true;
end;

initialization
  TLayoutSwitcher.LangDefault := TLayoutSwitcher.GetLangId ;
  GetKeyboardLayoutList(255, AList);
  TLayoutSwitcher.HLANG_RUSSIAN:=0;
  TLayoutSwitcher.HLANG_BELARUSIAN:=0;
  TLayoutSwitcher.HLANG_ENGLISH:= 0;

  TLayoutSwitcher.OldOnActivate:=Application.OnActivate;
  TLayoutSwitcher.OldOnDeactivate:=Application.OnDeactivate;

  Application.OnDeactivate:=TLayoutSwitcher.OnApplicationDeactivate;
  Application.OnActivate:= TLayoutSwitcher.OnApplicationActivate;


finalization
 if not isList(AList,TLayoutSwitcher.HLANG_ENGLISH) then
  UnloadKeyboardLayout(TLayoutSwitcher.HLANG_ENGLISH);

 if not isList(AList,TLayoutSwitcher.HLANG_RUSSIAN) then
  UnloadKeyboardLayout(TLayoutSwitcher.HLANG_RUSSIAN);

 if not isList(AList,TLayoutSwitcher.HLANG_BELARUSIAN) then
  UnloadKeyboardLayout(TLayoutSwitcher.HLANG_BELARUSIAN);

Application.OnActivate:=TLayoutSwitcher.OldOnActivate;
Application.OnDeactivate:=TLayoutSwitcher.OldOnDeactivate;

END.
