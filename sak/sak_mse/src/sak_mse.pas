unit sak_mse;

{*******************************************************************************
*                         Speech Assistive Kit ( sak )                         *
*                  --------------------------------------                      *
*                                                                              *
*          Assistive Procedures using eSpeak and Portaudio libraries           *
*                                                                              *
*                                                                              *
*                 Fred van Stappen /  fiens@hotmail.com                        *
*                                                                              *
*                                                                              *
********************************************************************************
*  5 th release: 2015-06-04  (mse compatible)                                  *
*  4 th release: 2015-03-13  (sak_dll synchronized with sak)                   *
*  3 th release: 2015-03-04  (fpGUI focus)                                     *
*  2 th release: 2013-08-01  (use espeak executable)                           *
*  1 th release: 2013-06-15  (multi objects, multi forms)                      *
*******************************************************************************}
    {
    Copyright (C) 2013 - 2015  Fred van Stappen

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA  02110-1301  USA
    }

interface

uses
  msetypes, mseglob, mseguiglob, mseguiintf, mseapplication, msestat, msemenus, msemenuwidgets, msegui,
  msegraphics, msegraphutils, mseevent, mseclasses, msewidgets, mseforms, msetimer, msetabs,
   mseassistiveserver,mseassistiveclient, msegrids, msestrings, msesimplewidgets,
  msedataedits, mseedit, msekeyboard, msefileutils, msestringcontainer,msedispwidgets,
  mseificomp, mseificompglob, mseifiglob, msestatfile, msestream, SysUtils, mseact,
  msegraphedits, msescrollbar, msewidgetgrid, msetoolbar,msebitmap,mseshapes, mseprocess,
  Math, Classes, Process
  {$IF not DEFINED(Windows)}
  , baseunix
       {$endif}  ;

(*
{$define darwin}
{$define freebsd}
{$define windows}
{$define cpu64}
{$define cpu86}
*)

const
  male = 1;
  female = 2;

type
  TSAK = class(TObject, iassistiveserver)
  protected
        
    ES_ExeFileName: filenamety;
    ES_DataDirectory: filenamety;
    ES_LibFileName: filenamety;

    PA_LibFileName: filenamety;
    
    old8087cw: word;
    mouseclicked: boolean;
    itementer: boolean;
    AProcess: TProcess;
    
    CompCount: integer;
    CheckObject: TObject;
    CheckPoint: Tpoint;
    CheckShift: TShiftState;

    voice_language: ansistring;
    voice_gender: ansistring;
    voice_speed: integer;  //-s
    voice_pitch: integer;  //-p
    voice_volume: integer;  //-a

     lastname: msestring;

  TheTimer: TTimer;
  TheSender: TObject;
  TheKeyInfo: keyeventinfoty;
  TheMouseInfo: mouseeventinfoty;
  TheMenuInfo: menucellinfoarty;
  TheMenuIndex : integer;

  TheWord: msestring;  //// use F11 key in memo
  TheSentence: msestring;   //// use F10 key in memo
  TheLastSentence: msestring;  //// use F10 key in memo
  TheLastCell: gridcoordty;
  TheCell: msestring;
  TheTypCell : integer;

  isentered: boolean;
  
    procedure doenter(const Sender: iassistiveclient);
    procedure clientmouseevent(const sender: iassistiveclient; const info: mouseeventinfoty);
    procedure dochange(const sender: iassistiveclient);   
    procedure dofocuschanged(const oldwidget, newwidget: iassistiveclient);
    procedure dokeydown(const Sender: iassistiveclient; const info: keyeventinfoty);
    procedure doactionexecute(const Sender: TObject; const info: actioninfoty);
    procedure doitementer(const sender: iassistiveclient; //sender can be nil
                            const items: shapeinfoarty; const aindex: integer);
    procedure doitementer(const sender: iassistiveclient;
                         const items: menucellinfoarty; const aindex: integer);
   procedure docellevent(const sender: iassistiveclientgrid; 
                                    const info: celleventinfoty);
    procedure ontimercell(const Sender: TObject);                               
    procedure ontimerkey(const Sender: TObject);
    procedure ontimermouse(const Sender: TObject);
    procedure ontimerenter(const Sender: TObject);
    procedure ontimeritementer(const Sender: TObject);
    procedure ontimerchange(const Sender: TObject);
    function LoadLib: integer;
    procedure espeak_key(Text: msestring);
    function WhatName(Sender: TObject): msestring;
    function WhatChar(Sender: TObject; const info: keyeventinfoty): msestring;
    function WhatChange(Sender: TObject) : msestring;
    function WhatPos(sender : Tobject; kind : integer) : msestring ;  // kind 0 = all, , 1 = part
    function WhatDeleted(sender : Tobject) : msestring;
    function WhatWord(sender : Tobject) : msestring;
    function WhatLine(sender : Tobject) : msestring;


  public
    constructor Create();
      destructor Destroy(); override;
  end;

{$IFDEF FREEBSD}
// These are missing for FreeBSD in FPC's RTL
const
  S_IRWXU = S_IRUSR or S_IWUSR or S_IXUSR;
  S_IRWXG = S_IRGRP or S_IWGRP or S_IXGRP;
  S_IRWXO = S_IROTH or S_IWOTH or S_IXOTH;

{$ENDIF}
  
  var
   sak: TSAK;
  
/// Load with custom sakit dir
function SAKLoadLib(const SakitDir: filenamety = ''): integer;
                            //'' = default

/// Load with custom espeak dir
function SAKLoadLib(const eSpeakBin: filenamety; const eSpeaklib: filenamety; const PortaudioLib: filenamety;
                                      const eSpeakDataDir: filenamety): integer;
/// Unload sak 
function SAKUnloadLib: integer;

 {$IF DEFINED(unix)}
function ChangePermission(const thefile: filenamety = ''; raisemessage : boolean = true) : integer ;
 {$endif} 

 ///// to find the file in sak.ini (what => 0 = espeak bin, 1 = portaudio lib, 2 = espeak lib, 3 = epeak-data dir)
function WhatFile(const sakini : filenamety = ''; what : integer = 0) : string;

//// to know if sak is loaded
function SakIsEnabled: boolean;

////////////////////// Voice Config Procedures ///////////////
function SAKSetVoice(gender: shortint; language: msestring ; speed: integer ; pitch: integer ; volume : integer ): integer;
//// gender : 1 = man, 2 = woman.
//// language : is the language code, for example :
//// 'en' for english, 'fr' for french, 'pt' for Portugues, etc...
////           (check in /espeak-data if your language is there...)
//  speed sets the speed in words-per-minute , Range 80 to 450. The default value is 175. => -1
// pitch  range of 0 to 99. The default is 50.   => -1
// volume range of 0 to 200. The default is 100. => -1

///// Start speaking the text
function SAKSay(Text: msestring): integer;

// Cancel current speak.
function SakCancel: integer;


implementation

uses
  typinfo, mclasses, mseactions, mseformatstr, msegridsglob;
  
/////////////////////////// Capture Assistive Procedures

function Tsak.WhatDeleted(sender : Tobject) : msestring;
var
 strline, posword1, posword2 : string;
 pos1 : integer;
begin
{
   with sender as Tmemoedit do
      begin
           sakcancel;
          strline :=  Lines[caretpos.y];
        posword1 := '';
             pos1 := cursorpos ;
        while (copy(strline,pos1,1) <> ' ') and (pos1 > 0) do
          begin
        posword1 := copy(strline,pos1,1)   + posword1;
        dec(pos1);
          end;

    //    writeln('chars before pos = ' + posword1);  // the letters before cursor

    posword2 := '';
             pos1 := cursorpos +1 ;
        while (copy(strline,pos1,1) <> ' ') and (pos1 < length(strline) +1) do
          begin
        posword2 := posword2 + copy(strline,pos1,1)  ;
        inc(pos1);
          end;

      if trim(posword1 + posword2) = '' then posword1 := 'empty, ';


       if  copy(strline,cursorpos+1,1) = ' '   // the letter after cursor is space
              then
              begin
       result := 'deleted, space, after, '  +  posword1 + posword2 + ' in line ' + inttostr(cursorline+1)
  end else
   begin
     result := 'deleted, position, ' + inttostr(length(posword1)+1) +  ', line, ' + inttostr(cursorline+1) +  ', in, ' +  posword1 + posword2;
        end;

//     writeln(result);

        end;

}
end;

function Tsak.WhatPos(sender : Tobject; kind : integer) : msestring ;  // kind 0 = all, , 1 = part
var
 strline, posword1, posword2 : string;
 pos1 : integer;
begin
{
            with sender as Tmemoedit do
           begin
                  sakcancel;

         strline :=  Lines[cursorline];
        posword1 := '';
             pos1 := cursorpos ;
        while (copy(strline,pos1,1) <> ' ') and (pos1 > 0) do
          begin
        posword1 := copy(strline,pos1,1)   + posword1;
        dec(pos1);
          end;

    //    writeln('chars before pos = ' + posword1);  // the letters before cursor

    posword2 := '';
             pos1 := cursorpos +1 ;
        while (copy(strline,pos1,1) <> ' ') and (pos1 < length(strline) +1) do
          begin
        posword2 := posword2 + copy(strline,pos1,1)  ;
        inc(pos1);
          end;

      if trim(posword1 + posword2) = '' then posword1 := 'empty, ';


       if  copy(strline,cursorpos+1,1) = ' '   // the letter after cursor is space
              then
   //      writeln('space, after, '  +  posword1 + posword2 + ' in line ' + inttostr(cursorline) )
        if kind = 0 then
         result := 'space, after, '  +  posword1 + posword2 + ', in line, ' + inttostr(cursorline+1)
         else   result := 'space, after, '  +  posword1 + posword2

   else
   begin
   //   writeln(copy(strline,cursorpos+1,1) + ', line, ' + inttostr(cursorline) + ' , position, ' + inttostr(length(posword1)+1) + ', in, ' +
  // posword1 + posword2);
     if kind = 0 then
     result := copy(strline,cursorpos+1,1) +  ' , position, ' + inttostr(length(posword1)+1) + ', line, ' + inttostr(cursorline+1)+ ', in, ' +
   posword1 + posword2 else
      result := copy(strline,cursorpos+1,1) +  ' , position, ' + inttostr(length(posword1)+1) + ', in, ' +
   posword1 + posword2

   end;

  //   writeln(result);

end;
}
end;

function  Tsak.WhatLine(sender : Tobject) : msestring;
begin
{
               with sender as Tmemoedit do
           begin
                  sakcancel;
          result := 'line, ' + inttostr(cursorline +1) + ', ' +  Lines[cursorline];

           end;
}
end;

function Tsak.WhatWord(sender : Tobject) : msestring ;
var
 strline, posword1, posword2 : string;
 pos1 : integer;
begin
{
            with sender as Tmemoedit do
           begin
                  sakcancel;
          strline :=  Lines[cursorline];
        posword1 := '';
             pos1 := cursorpos -1;
        while (copy(strline,pos1,1) <> ' ') and (pos1 > 0) do
          begin
        posword1 := copy(strline,pos1,1)   + posword1;
        dec(pos1);
          end;

    //    writeln('chars before pos = ' + posword1);  // the letters before cursor

    posword2 := '';
             pos1 := cursorpos  ;
        while (copy(strline,pos1,1) <> ' ') and (pos1 < length(strline) +1) do
          begin
        posword2 := posword2 + copy(strline,pos1,1)  ;
        inc(pos1);
          end;

      if trim(posword1 + posword2) = '' then posword1 := 'empty, ';

            result := posword1 + posword2  ;

end;
}
end;

function TSak.WhatChange(Sender: TObject) : msestring;
var
stringtemp : msestring;
begin
if (Sender is tbooleaneditradio) then
  begin
  if tbooleaneditradio(sender).value = false then stringtemp := 'false' else stringtemp := 'true';
       Result := ' changed to ' + stringtemp ;
   end
  else
  if (Sender is tbooleanedit) then
  begin
   if tbooleanedit(sender).value = false then stringtemp := 'false' else stringtemp := 'true';
       Result := ' changed to ' + stringtemp ;
  end
   else
  if (sender is tenumedit) then 
  begin
  result:= ' changed to ' + (tenumedit(sender).enumname(tenumedit(sender).value));
  end
  else
   if (Sender is tslider) then
    Result := ' changed position to ' + inttostr(round(tslider(sender).value * 100)) + ' ,%' ;
end;

function TSak.WhatChar(Sender: TObject; const info: keyeventinfoty): msestring;

procedure checkgrid();
 begin
  if (Sender is Tcustomstringgrid) then begin
   with tcustomstringgrid(Sender) do begin
    if focusedcellvalid then begin
    if col > 0 then
     Result := Result + ', column  ' +
              IntToStr(col) + ' , row  ' + 
              IntToStr(row) + '. ' + items[focusedcell] else
     Result := Result + ' , row  ' + 
              IntToStr(row) + '. ' + items[focusedcell];
     end;
   end;
  end;
 end;
 
var
  CheckKey: keyty;
  
begin
  CheckKey := info.key;
  Result := '';

  if ((CheckKey = key_Up) or (CheckKey = key_Space) or (CheckKey = key_down) or (CheckKey = key_left) or
    (CheckKey = key_right) or (CheckKey = key_tab)) and (sak.isentered = True)  and not (Sender is Tstringgrid) then
    sak.isentered := False
  else
  begin
    Result := info.chars;
    case CheckKey of

      key_Return:  begin
        Result := 'Enter';  
        end;
    
      key_Backspace: 
begin  /// backspace
      if (Sender is TMemoedit) or (Sender is Tstringedit) then
    begin
     //  writeln('before : ' + theword);
      if length(theword) > 1 then   theword := copy(theword,1,length(theword)-1);
     //  writeln('after : ' + theword);
     end;
       Result := 'back space';
          end;

     key_Backtab: Result := 'back tab';

     key_Up:
      begin
       if (Sender is Tstringgrid) or (Sender is Tcustomstringgrid) then checkgrid() else Result := 'up' ;
         end;
      
      key_down:
      begin
      if (Sender is Tstringgrid) or (Sender is Tcustomstringgrid) then checkgrid() else Result := 'down' ;
         end;

      key_left:
      begin
       if (Sender is Tstringgrid) or (Sender is Tcustomstringgrid) then checkgrid() else result := 'left';
          end;

      key_right:
      begin
     if (Sender is Tstringgrid) or (Sender is Tcustomstringgrid) then checkgrid() else Result := 'right';
         end;
      
      key_Tab:  
      begin
      Result := 'tab'; 
      checkgrid();
       end; 
 
      key_Space: Result := 'space';
     
      key_F1: Result := 'f, 1';
      key_F2: Result := 'f, 2';
      key_F3: Result := 'f, 3';
      key_F4: Result := 'f, 4';
      key_F5: Result := 'f, 5';
      key_F6: Result := 'f, 6';
      key_F7: Result := 'f, 7';
      key_F8: Result := 'f, 8';
      key_F9: if (CheckObject is TMemoedit) then
                    result := thelastsentence
                  else
          Result := 'f, 9';

      key_F10: if (CheckObject is TMemoedit) then
                   result := theword
                  else Result := 'f, 10';

      key_F11: if (CheckObject is TMemoedit) then
                   result := thesentence
                  else result := 'f, 11';
           
      key_F12: if (Sender is TMemoedit) then
          with Sender as TMemoedit do
              begin
              //  SAKSetVoice(2,'',165,-1,-1);
            result := Text ;
              //  SAKSetVoice(-1,'',-1,-1,-1);
              end
        else
        if (Sender is Tstringedit) then
          with Sender as Tstringedit do
            Result := Text
        else if (Sender is Tstringgrid) then
              with Sender as tstringgrid do  Result := Result + ' column  ' + 
        IntToStr(col) + ' , row  ' + IntToStr(row) + '. ' + Tstringgrid(sender)[col][row]
        else        
          Result := '';
          
      key_Shift: Result := 'shift';
      key_control: Result := 'control,';
      key_alt: Result := 'alt';
      key_CapsLock: Result := 'caps lock';
      key_NumLock: Result := 'num lock';
      key_AltGr: Result := 'alt gr';
      
      Key_PageUp:
       begin
        Result := 'page up';
      checkgrid();
        end;
      
      Key_PageDown:
       begin
        Result := 'page down';
       checkgrid();
       end;
      
      Key_delete: Result := 'delete';
      Key_insert: Result := 'insert';
      Key_escape: Result := 'escape';
      Key_end: Result := 'end';
    end;
  end;
end;

function TSak.WhatName(Sender: TObject): msestring;
begin

  Result := '';

  if (Sender is TLabel) then
    Result := 'label, ' + TLabel(Sender).Caption
  else
  if (Sender is TButton) then
  begin
    if (trim(TButton(Sender).Caption) <> '') then
      Result := 'button, ' + TButton(Sender).Caption
    else
    if (trim(TButton(Sender).Name) <> '') then
      Result := 'button, ' + TButton(Sender).Name
    else
    if (trim(TButton(Sender).hint) <> '') then
      Result := 'button, ' + TButton(Sender).hint;
  end
  else
 if (Sender is TStringEdit) then
    Result := 'edit, ' + TStringEdit(Sender).Name
  else
  if (Sender is TMemoEdit) then
    Result := 'memo, ' + TMemoEdit(Sender).Name
  else
  if (Sender is Twidgetgrid) then
    Result := 'page, ' + Twidgetgrid(Sender).Name
  else
   if (Sender is Tstringgrid) then
    Result := 'grid, ' + Tstringgrid(Sender).Name
  else
   if (Sender is Tstringdisp) then
    Result := 'Info panel, ' + Tstringdisp(Sender).value 
   else
    if (Sender is tstockglyphbutton) then
    Result := 'button, ' + tstockglyphbutton(Sender).name
   else
    if (Sender is Tenumedit) then  
   Result := 'combo box, ' + Tenumedit(Sender).Name
  else
   if (Sender is Ttabwidget) then  
   Result := 'tab, ' + Ttabwidget(Sender).Name
  else
  if (Sender is tbooleaneditradio) then
  begin
    if (Tbooleaneditradio(Sender).frame.Caption <> '') then
      Result := 'radio button, ' + Tbooleaneditradio(Sender).frame.Caption
    else
      Result := 'radio button, ' + Tbooleaneditradio(Sender).Name;
  end
  else if (Sender is tbooleanedit) then
  begin
    if (Tbooleanedit(Sender).frame.Caption <> '') then
      Result := 'checkbox, ' + Tbooleanedit(Sender).frame.Caption
    else
      Result := 'checkbox, ' + Tbooleanedit(Sender).Name;
  end
   else
   if (Sender is ttoolbar) then
    Result := 'tool bar, ' + ttoolbar(Sender).name
  else
  if (Sender is tslider) then
    Result := 'slider, ' + Tslider(Sender).Name
  else 
    if (Sender is ttoolbutton) then
    Result := 'tool button, ' +  ttoolbutton(Sender).hint
  else 
   if (Sender is tmenuitem) then
  begin
    if (tmenuitem(Sender).Caption <> '') then
      Result := 'menu item , ' + tmenuitem(Sender).Caption
    else
      Result := 'menu item , ' + tmenuitem(Sender).Name;
  end
  else 
  if (Sender is tmainmenu) or (Sender is tmainmenuwidget) or (Sender is tmenu) or  (Sender is tcustommenu) or   (Sender is tpopupmenu)  then
     Result :=  'menu, '
     ;
 //   else 
 //    if (Sender is twidget) then
 //   Result := 'widget, ' + Twidget(Sender).Name ;
    
end;

////////////////////// Loading Procedure

/// Load with custom espeak dir
function SAKLoadLib(const eSpeakBin: filenamety; const eSpeaklib: filenamety; const PortaudioLib: filenamety;
                                      const eSpeakDataDir: filenamety): integer;
begin
 Result := -1;

 if sak = nil then sak:= TSAK.Create();
 if (espeakdatadir = '') or (directoryexists(tosysfilepath(eSpeakDataDir))) then
 begin
  Result:= 0;
  sak.ES_DataDirectory:= tosysfilepath(eSpeakDataDir);
 end;
 if result = 0 then
 begin
 sak.ES_ExeFileName:= tosysfilepath(eSpeakBin);
 sak.PA_LibFileName:= tosysfilepath(PortaudioLib);
 sak.ES_LibFileName:= tosysfilepath(eSpeaklib);

 Result:= sak.loadlib;
 end;
 if result <> 0 then freeandnil(sak);

end;

function SAKLoadLib(const sakitdir: filenamety = ''): integer;
var
 tmp : string;
  ordir, sakini, espeakbin, espeaklib, portaudiolib, espeakdatadir : filenamety;
const
sakininame = 'sak.ini';

{$ifdef mswindows}
 espeaklibdir = 'libwin32';
 espeakdefault = 'espeak.exe';
{$else}
 espeakdefault = 'espeak';
{$endif}

{$if defined(linux) and  defined(cpu64)}
 espeaklibdir = 'liblinux64';
{$endif}
{$if defined(linux) and defined(cpu86) }
 espeaklibdir = 'liblinux32';
{$endif}
{$if defined(freebsd) and  defined(cpu64)}
 espeaklibdir = 'libfreebsd64';
{$endif}
{$if defined(freebsd) and defined(cpu86) } 
 espeaklibdir = 'libfreebsd32';
 {$endif}
{$ifdef darwin}
 espeaklibdir = 'libmac32';
{$endif}

begin
 Result := -1;
 espeakdatadir:= '';
 if sakitdir = '' then begin
  ordir:= IncludeTrailingBackslash(ExtractFilePath(ParamStr(0)));
 end
 else begin
  ordir:= sakitdir;
 end;

sakini := ordir + sakininame;
 espeakbin:= ordir + WhatFile(sakini,0);

 tmp := WhatFile(sakini,1);
 if tmp <> '' then
 portaudiolib:= ordir + tmp else  portaudiolib:= '';

 espeaklib:= ordir + WhatFile(sakini,2);

 tmp := WhatFile(sakini,2);
 if tmp <> '' then
 espeaklib:= ordir + tmp else  espeaklib:= '';

tmp := WhatFile(sakini,3);
 if (tmp = '/') or (tmp = './') then
 espeakdatadir:= ordir else 
if tmp = '../' then
 espeakdatadir:= ExtractFilePath(ordir)
else 
 espeakdatadir:= tmp ;

   if (finddir(espeakdatadir)) and (findfile(espeakbin)) and (findfile(sakini)) and ((findfile(portaudiolib)) or (portaudiolib = ''))
 and ((findfile(espeaklib)) or (espeaklib = ''))
 then
  begin
   Result:= 0;
   espeakdatadir:= ordir ;
   {$ifdef unix}
 result := ChangePermission(espeakbin,true);
   {$endif}
  end
 else begin
  sakini:= ordir +  directoryseparator +'sakit' + directoryseparator +
  espeaklibdir + directoryseparator + sakininame;

  espeakbin:= ordir + directoryseparator + 'sakit' + directoryseparator +
  espeaklibdir+ directoryseparator + WhatFile(sakini, 0);

  tmp := WhatFile(sakini,1);
 if tmp <> '' then
  portaudiolib:= ordir + directoryseparator + 'sakit' + directoryseparator +
  espeaklibdir+ directoryseparator + tmp else  portaudiolib:= '';

 tmp := WhatFile(sakini,2);
 if tmp <> '' then
 espeaklib:= ordir + directoryseparator + 'sakit' + directoryseparator +
  espeaklibdir+ directoryseparator + tmp else  espeaklib:= '';

 tmp := WhatFile(sakini,3);
 if (tmp = '/') or (tmp = './') then
 espeakdatadir:= ordir + directoryseparator + 'sakit' + directoryseparator +
  espeaklibdir+ directoryseparator else 
if tmp = '../' then
 espeakdatadir:= ordir + directoryseparator + 'sakit' + directoryseparator
else 
 espeakdatadir:= tmp ;

   if (finddir(espeakdatadir)) and (findfile(espeakbin)) and (findfile(sakini)) and ((findfile(portaudiolib)) or (portaudiolib = ''))
   and ((findfile(espeaklib)) or (espeaklib = ''))   then
 begin
    Result:= 0;
        {$ifdef unix}
  result := ChangePermission(espeakbin,true);
    {$endif}
   end
  else begin
{$ifdef unix}
  if (fileexists('/usr/bin/'+espeakdefault)) then begin
  espeakbin:= '/usr/bin/'+espeakdefault;
 result := 0;
end else
 if
 (fileexists('/usr/local/bin/'+espeakdefault)) then
begin
  espeakbin:= '/usr/local/bin/'+espeakdefault;
result := 0;
end;
 {$endif}

{$ifdef windows}
  if (fileexists('c:\Program Files (x86)\eSpeak\command_line\'+espeakdefault)) then
begin
  espeakbin:= 'c:\Program Files (x86)\eSpeak\command_line\'+espeakdefault;
 result := 0;
end else
 if
 (fileexists('c:\Program Files\eSpeak\command_line\'+espeakdefault)) then
begin
  espeakbin:= 'c:\Program Files\eSpeak\command_line\'+espeakdefault;
result := 0;
end;
 {$endif}

espeakdatadir:= '';
portaudiolib:= '' ;

end;
 end;
 
 if result = 0 then begin
  result:= sakloadlib(espeakbin,espeaklib,portaudiolib,espeakdatadir);
 end;
end;

function SAKUnLoadLib: integer;
begin
 result:= -1;
 if assigned(sak) then begin
   SakCancel;
  result:= 0;
  freeandnil(sak.thetimer);
  freeandnil(sak.AProcess);
  freeandnil(sak);
 end;
end;

function checksakactive(const raiseexception: boolean = false): boolean;
begin
 result:= sak <> nil;
end;

procedure TSAK.dochange(const sender: iassistiveclient);
begin
 thetimer.enabled := false;
if WhatName(sender.getinstance) <> '' then
 begin  
  TheSender := sender.getinstance;  
  thetimer.interval := 600000 ;
  thetimer.ontimer := @ontimerchange;
  thetimer.enabled := true;
 end;
 end;

procedure TSAK.ontimerchange(const sender: TObject);
begin
thetimer.enabled := false;
 SakCancel;
 espeak_Key(WhatName(TheSender) + WhatChange(TheSender));
end;

procedure TSAK.ontimerenter(const Sender: TObject);
begin
  thetimer.Enabled := False;
  SakCancel;
  espeak_Key(WhatName(TheSender) + ', enter');
end;

procedure TSAK.doenter(const Sender: iassistiveclient);
begin
//if itementer = false then
//begin
  if WhatName(Sender.getinstance) <> '' then
  begin
    thetimer.Enabled := False;
    TheSender := Sender.getinstance;
    thetimer.interval := 600000;
    thetimer.ontimer := @ontimerenter;
    thetimer.Enabled := True;
    isentered := True;
  end;
//end;

end;

procedure TSAK.ontimerkey(const Sender: TObject);
begin
if itementer = false then begin
  thetimer.Enabled := False;
  SakCancel;
  espeak_Key(WhatChar(TheSender, TheKeyinfo));
    end;
end;

procedure TSAK.dokeydown(const Sender: iassistiveclient; const info: keyeventinfoty);
var
  WhatCh: msestring;
  oldlang : msestring;
  oldspeed, oldgender ,oldpitch, oldvolume : integer;
begin
  thetimer.Enabled := False;
  
    WhatCh := WhatChar(Sender.getinstance, info);
    TheSender := Sender.getinstance;
    TheKeyInfo := info;
    thetimer.ontimer := @ontimerkey;

  if (TheSender is Tstringedit) or (TheSender is Tmemoedit)  then  
  begin 
   oldlang := voice_language;
      if voice_gender = '' then
    oldgender := -1 else
     if voice_gender = 'm3' then
    oldgender := 1 else
     oldgender := 2 ;
  oldspeed := voice_speed;
  oldpitch := voice_pitch;
  oldvolume := voice_volume;

  if info.key = key_Space then
   begin
   SAKSetVoice(2,'',150,-1,-1);
   espeak_Key(Theword) ;
   TheSentence := TheSentence + ' ' + TheWord;
   Theword := '';
   SAKSetVoice(oldgender,oldlang,oldspeed,oldpitch,oldvolume);
   end else
   if (WhatCh = '.') or (WhatCh = '?') or (WhatCh = '!') then
   begin
   SAKSetVoice(2,'',150,-1,-1);
   espeak_Key( Theword + ', ' + TheSentence + ' ' + Theword) ;
   SAKSetVoice(oldgender,oldlang,oldspeed,oldpitch,oldvolume);
   TheLastSentence := TheSentence + ' ' + Theword ;
   TheSentence := '';
   Theword := '';
   end
   else
   begin
    thetimer.Interval := 1 ;
   Theword := Theword + info.chars;
     thetimer.Enabled := True;
   end;
   end else
   begin
   if (TheSender is Tcustomstringgrid) then
   begin
     if (info.key = key_down) or (info.key = key_up) or (info.key = key_left) or (info.key = key_right)
   then
   begin
      case info.key of
   key_down: WhatCh := 'down';
   key_up: WhatCh := 'up';
   key_left: WhatCh := 'left';
   key_right: WhatCh := 'right';
   end;
   
   SakCancel;
      espeak_Key(WhatCh) ; 
     thetimer.interval := 600000;
     thetimer.Enabled := True;
    end else
    begin
     thetimer.interval := 400000 ; 
     thetimer.Enabled := True;
     end;
   end;
   end;

end;

procedure TSAK.ontimermouse(const Sender: TObject);
var
stringtemp : msestring = '' ;

begin
  thetimer.Enabled := False;

 if TheMouseinfo.eventkind = ek_mousemove then
  begin

    if TComponent(TheSender).Name <> lastname then
    begin
      SakCancel;
      
      if(TheSender is tbooleaneditradio) then
  begin
  if tbooleaneditradio(TheSender).value = false then stringtemp := ' , false, ' else stringtemp := ' , true, ';
  end;
  
    if(TheSender is tbooleanedit) then
  begin
  if tbooleanedit(TheSender).value = false then stringtemp := ' , false, ' else stringtemp := ' , true, '; 
  end;
  
     if(TheSender is tslider) then
  begin
  stringtemp := ' , ' + inttostr(round(tslider(TheSender).value * 100)) + ' ,%, '
  end;
        
      espeak_Key(WhatName(TheSender) + stringtemp + ' focused.');
      lastname := TComponent(TheSender).Name;
    end;
  end
  else
  if TheMouseinfo.eventkind = ek_buttonpress then
  begin
    SakCancel;
    espeak_Key(WhatName(TheSender) + ' clicked.');
    lastname := TComponent(TheSender).Name;
  end;

end;

procedure TSAK.clientmouseevent(const sender: iassistiveclient;
                                           const info: mouseeventinfoty);
 begin
 //if itementer = false then
//begin
  if WhatName(Sender.getinstance) <> '' then
  begin
    TheSender := Sender.getinstance;
    TheMouseInfo := info;
    thetimer.Enabled := False;
    if info.eventkind = ek_mousemove then
  thetimer.interval := 60000 else
  thetimer.interval := 6000 ;
  
    thetimer.ontimer := @ontimermouse;
    thetimer.Enabled := True;
  end;
//  end;
end;

procedure TSAK.dofocuschanged(const oldwidget: iassistiveclient; const newwidget: iassistiveclient);
begin

end;

procedure TSAK.ontimeritementer(const Sender: TObject);
begin
  thetimer.Enabled := False;
  SakCancel;
  espeak_key(WhatName(TheSender) + ', ' + TheMenuInfo[TheMenuIndex].buttoninfo.ca.caption.text + ' , focused');
  itementer:= false;
 end;

procedure  TSAK.doitementer(const sender: iassistiveclient; //sender can be nil
                            const items: shapeinfoarty; const aindex: integer);
begin
end;  

procedure TSAK.doitementer(const sender: iassistiveclient;
                        const items: menucellinfoarty; const aindex: integer);
begin
 if WhatName(Sender.getinstance) <> '' then
  begin
    thetimer.Enabled := False; 
    isentered := True;
    TheSender := Sender.getinstance;
    TheMenuInfo := items;
    TheMenuIndex := aindex;
    thetimer.interval := 600000;
    thetimer.ontimer := @ontimeritementer;
    thetimer.Enabled := True;
  //  itementer:= true;
  end;
end;

procedure TSAK.doactionexecute(const Sender: TObject; const info: actioninfoty);
begin
end;



// for editor

procedure TSAK.ontimercell(const Sender: TObject);
var
 oldlang : msestring;
  oldspeed, oldgender ,oldpitch, oldvolume : integer;
begin
if itementer = false then begin
  thetimer.Enabled := False;
   SakCancel;
if TheTypCell = 1 then begin
oldlang := voice_language;
      if voice_gender = '' then
    oldgender := -1 else
     if voice_gender = 'm3' then
    oldgender := 1 else
     oldgender := 2 ;
  oldspeed := voice_speed;
  oldpitch := voice_pitch;
  oldvolume := voice_volume;

  SAKSetVoice(2,'',150,-1,-1);
  espeak_Key(TheCell);
   SAKSetVoice(oldgender,oldlang,oldspeed,oldpitch,oldvolume);
 end else espeak_Key(TheCell);
    end;
end;

procedure TSAK.docellevent(const sender: iassistiveclientgrid; 
                                     const info: celleventinfoty);
var
 mstr1, mstr2, mstr3: msestring;
begin
 if (Sender.getinstance is Twidgetgrid) then begin
  thetimer.enabled := false;
  thetimer.ontimer := @ontimercell;
  thetimer.interval := 600000;
	if info.eventkind = cek_keyup then begin  

	mstr1:= sender.getassistivecelltext(info.cell);
	//mstr1:= ' colum '+ inttostrmse(sender.getassistivecaretindex())+ ' row '+inttostrmse(info.cell.row);
		if TheLastCell.row > info.cell.row then
			begin
			sakCancel;
			Theword := '';
			espeak_Key('up') ;
			TheCell := ' row, '+ inttostrmse(info.cell.row+1) + ' , ' + mstr1;
			TheTypCell := 0 ;
    		thetimer.enabled := true;
			end else
		if TheLastCell.row < info.cell.row then
			begin
			sakCancel;
			espeak_Key('down') ;
 			Theword := '';
			TheCell := ' row, '+ inttostrmse(info.cell.row+1)  + ' , ' + mstr1;
			TheTypCell := 0 ;
    		thetimer.enabled := true;
			end else
		if length(mstr1) > 0 then
			begin 
			mstr2 := mstr1[sender.getassistivecaretindex()] ;
			
			if sender.getassistivecaretindex() < TheLastCell.col then
			mstr3 := ' colum '+ inttostrmse(sender.getassistivecaretindex()) + ' ' else
			mstr3 := '';
  					
        	if (mstr2 = ' ') or  (mstr2 = '.') or  (mstr2 = ',')  or  (mstr2 = '"') or 
  			 (mstr2 = '[') or  (mstr2 = ']') or  (mstr2 = '{') or  (mstr2 = '}') then
   				begin 
   				sakCancel;
   				espeak_Key(mstr3 + mstr2) ;
    		TheCell := ' ' + Theword;
    		TheTypCell := 1 ;
    		thetimer.enabled := true;
   			Theword := '';
    			end else
 			if mstr2 = ';'  then
   				begin
   				sakCancel;
    			espeak_Key(mstr3 +mstr2) ;
    			TheTypCell := 1 ;
    			TheCell := mstr1 ;
    			thetimer.enabled := true;
      			end  else
            begin
    			Theword := Theword + mstr2;
    			TheTypCell := 0 ;
    			SakCancel;
     			espeak_Key(mstr3 + mstr2) ;
   			end;
 		end;
	TheLastCell.col := sender.getassistivecaretindex() ; 
	TheLastCell.row := info.cell.row;
 end else
 if info.eventkind = cek_mousemove then
  begin 
     mstr2:= ' row '+inttostrmse(info.cell.row+1) + ' , ';
	mstr1 := mstr2 + sender.getassistivecelltext(info.cell);
 	Theword := '';
 	TheLastCell.col := sender.getassistivecaretindex() ; 
	TheLastCell.row := info.cell.row;
	TheTypCell := 0 ;
	TheCell := mstr1;
	 thetimer.interval := 300000;
	 SakCancel;
    thetimer.enabled := true;
 end;
 end;
end;

constructor TSAK.Create();
begin
        thetimer := ttimer.Create(nil);
        thetimer.interval := 500000;
        thetimer.tag := 0;
        thetimer.Enabled := False;
end;

destructor TSAK.Destroy();
begin
 thetimer.free();
 assistiveserver:= nil;
 end;


///////////////// loading sak

function WhatFile(const sakini : filenamety = ''; what : integer = 0) : string;
///// to find the file in sak.ini (what => 0 = espeak bin, 1 = portaudio lib, 2 = espeak lib)
var
tf: textfile;
ffinded : boolean ;
dataf, whatfil : string;
len : integer;
scriptfile : string;
begin
ffinded := false;
result := '';

//writeln( 'sakini is ' + sakini);

if findfile(sakini) then
begin
 scriptfile := tosysfilepath(sakini);
  AssignFile(tf,pchar(scriptfile));
   Reset(tF);

   case what of
    0: whatfil := 'BINESPEAK=';
    1: whatfil := 'LIBPORTAUDIO=';
    2: whatfil := 'LIBESPEAK=';
    3: whatfil := 'DIRESPEAKDATA=';
     end;

  len := length(whatfil);
  
   while (eof(tf) = false) and (ffinded = false) do
     begin
       Readln(tF, dataf);
    dataf := trim(dataf);

    if  Pos(whatfil,dataf) > 0 then
   begin
    if  Pos('#',dataf) > 0 then  dataf := trim(copy(dataf,1, Pos('#',dataf)-1));
     result := copy(dataf,Pos(whatfil,dataf)+ len , length(dataf)-len);
  // writeln( 'Result is ' +  result);
    ffinded := true;
   end;
     end;
  CloseFile(tf);
end;

end;

{$IF DEFINED(unix)}
function ChangePermission(const thefile: filenamety = ''; raisemessage : boolean = true) : integer ;
var
info : stat;
begin
  result := 0;
 if (FpStat(thefile,info{%H-})<>-1) and FPS_ISREG(info.st_mode) and
             (BaseUnix.FpAccess(thefile,BaseUnix.X_OK)=0) then else
 begin
  if raisemessage = true then
  begin
  
  if askok('Permission mode of file:' +lineend+ thefile
   +lineend+ 'is not set as executable...'
    +lineend+ 'Do you want to reset it?') then begin

  fpchmod(thefile, S_IRWXU);
  ///// => get error at compil
// sys_setfilerights(thefile,[s_irusr,s_iwusr,s_ixusr,s_irgrp,s_ixgrp, s_iroth,s_ixoth]);

   end else result := -1;
  
 end
 else result := -1;

end; 
end;

{$endif}

function TSAK.LoadLib: integer;
//var
// str1: msestring = '' ;
begin
 {  
result:= -1;
if (getprocessoutput(ES_ExeFileName+' --version','',str1,5000000,
                                           [pro_shell,pro_inactive]) = 0) and
                   ((pos('eSpeak',str1) <> 0) or 
                    (pos('speak text-to-speech',str1) <> 0)) then begin 
}
  result:= 0;
 
  AProcess := TProcess.Create(nil);
  AProcess.Executable :=
  tosysfilepath(filepath(trim(ES_ExeFileName), fk_file, True));
  AProcess.Options := AProcess.Options + [poNoConsole, poUsePipes];
  AProcess.FreeOnRelease;

   {$ifdef unix}
  if trim(ES_LibFileName) <> '' then
begin
 AProcess.Environment.Text := 'LD_LIBRARY_PATH=' + tosysfilepath(ExtractFilePath(ES_LibFileName)) ;
if trim(PA_LibFileName) <> '' then
   AProcess.Environment.Text := AProcess.Environment.Text + ':' + tosysfilepath(ExtractFilePath(PA_LibFileName))

end  else
  if trim(PA_LibFileName) <> '' then
   AProcess.Environment.Text := 'LD_PRELOAD=' + tosysfilepath(PA_LibFileName) ;
{$endif}

 AProcess.Executable :=  tosysfilepath(ES_ExeFileName);

  TheWord := '' ;
  TheSentence := '' ;
  TheLastSentence := '' ;

  voice_gender := '' ;
  voice_language := '' ;
  voice_speed := -1 ;
  voice_pitch := -1 ;
  voice_volume := -1 ;
  
  espeak_Key('sak is working...');

  assistiveserver:= iassistiveserver(self); //sak is now operable
// end;
end;

////////////////////// Voice Config Procedures ///////////////
function SAKSetVoice(gender: shortint; language: msestring ; speed: integer ; pitch: integer ; volume : integer): integer;
// gender => 1 = man / => 2 = woman => defaut -1 (man)
// language => 'en' or 'pt' or 'ru'  => default 'en' => ''
//  speed sets the speed in words-per-minute , Range 80 to 450. The default value is 175. => -1
// pitch  range of 0 to 99. The default is 50.  => -1
// volume range of 0 to 200. The default is 100. => -1
begin
   result := -1;
  if assigned(sak) then
  begin
   result := 0;
    if gender = -1 then
    sak.voice_gender := ''  else
   if gender = 1 then
    sak.voice_gender := 'm3'
  else
    sak.voice_gender := 'f2';
  sak.voice_language := language;
  sak.voice_speed := speed;
  sak.voice_volume := volume;
  sak.voice_pitch := pitch;
  end;
end;


////////////////////// Speecher Procedures ////////////////
procedure TSAK.espeak_key(Text: msestring);
var
 params: msestring = '';
begin
   aprocess.Parameters.clear;

if (voice_gender <> '') or (voice_language <> '') then begin
  params:= params + '-v';
  if voice_language <> '' then begin
   params:= params+voice_language;
   if voice_gender <> '' then begin
    params:= params+'+'+voice_gender;
   end;
  end
  else begin
   if voice_gender <> '' then begin
    params:= params+voice_gender;
   end;
  end;
 end;

if  params <> '' then AProcess.Parameters.Add(params) ;

if voice_speed <> -1 then AProcess.Parameters.Add('-s' + inttostr(voice_speed)) ;
if voice_pitch <> -1 then AProcess.Parameters.Add('-p' + inttostr(voice_pitch)) ;
if voice_volume <> -1 then AProcess.Parameters.Add('-a' + inttostr(voice_volume)) ;

    if es_datadirectory <> ''  then
    AProcess.Parameters.Add('--path=' + ES_DataDirectory);
   
  AProcess.Parameters.Add('"' + Text + '"');
  AProcess.Execute;
end;

//// custom speecher procedure => to use also as extra-speecher
function SAKSay(Text: msestring): integer;
begin
Result := -1;
if assigned(sak) then
begin
  sak.espeak_Key(Text);
  Result := 0;
end;
end;

/// cancel current speech
function SakCancel: integer;
begin
result := -1;
 if assigned(sak) then
  if assigned(sak.AProcess) then
  begin
    sak.AProcess.Terminate(0);
    sak.AProcess.active := false;
   // freeandnil(sak.AProcess);
    result := 0;
    end;
end;

///////////// Enabled procedure
function SakIsEnabled(): boolean;
begin
result:= sak <> nil;
end;

finalization
 sak.free();

end.
