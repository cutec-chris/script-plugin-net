library net;

{$mode objfpc}{$H+}
{$DEFINE USE_BIN_STR}

uses
  Classes, sysutils, laz_synapse, httpsend, synautil, blcksock, dnssend;

var
  FHttp : THTTPSend;

function HttpGet(aURL: string; aTimeout: Integer): string;
begin
  Fhttp.Timeout:=aTimeout;
  Fhttp.KeepAlive:=false;
  Fhttp.HTTPMethod('GET',aURL);
  if Fhttp.ResultCode=200 then
    begin
      setlength(Result,Fhttp.Document.Size);
      Fhttp.Document.Read(Result[1],Fhttp.Document.Size);
    end
  else Result:='';
end;
function HttpPost(aURL, Content: string; aTimeout: Integer
  ): string;
begin
  Fhttp := THTTPSend.Create;
  Fhttp.Timeout:=aTimeout;
  Fhttp.Document.Write(Content[1],length(Content));
  Fhttp.HTTPMethod('POST',aURL);
  if Fhttp.ResultCode=200 then
    begin
      setlength(Result,Fhttp.Document.Size);
      Fhttp.Document.Read(Result[1],Fhttp.Document.Size);
    end
  else Result:='';
end;
procedure HttpSetMimeType(MimeType: string);
begin
  Fhttp.MimeType:=MimeType;
end;
procedure HttpSetUserAgent(UserAgent: string);
begin
  Fhttp.UserAgent:=UserAgent;
end;
function HttpGetResult: Integer;
begin
  Result := Fhttp.ResultCode;
end;
function HttpGetHeaders: string;
begin
  Result := Fhttp.Headers.Text;
end;
procedure HttpSetHeaders(Headers: string);
begin
  Fhttp.Headers.Text:=Headers;
end;
function HttpGetCookies: string;
begin
  Result := Fhttp.Cookies.Text;
end;
procedure HttpSetCookies(Headers: string);
begin
  Fhttp.Cookies.Text:=Headers;
end;
procedure HttpClear;
begin
  Fhttp.Clear;
end;
function GetDNS: string;
begin
  //Result := GetDNS;
end;
function GetLocalIPs: string;
begin
  //Result := GetLocalIPs;
end;


function ScriptDefinition : PChar;stdcall;
begin
  Result := 'function HttpGet(URL : string;aTimeout : Integer) : string;'
       +#10+'function HttpPost(URL,Content : string;aTimeout : Integer) : string;'
       +#10+'procedure HttpSetMimeType(MimeType : string);'
       +#10+'procedure HttpSetuserAgent(UserAgent : string);'
       +#10+'function HttpGetResult : Integer;'
       +#10+'procedure HttpClear;'
       +#10+'function HttpGetHeaders : string;'
       +#10+'procedure HttpSetHeaders(Headers : string);'
       +#10+'function HttpGetCookies : string;'
       +#10+'procedure HttpSetCookies(Headers : string);'
       +#10+'function GetDNS : string;'
       +#10+'function GetLocalIPs : string;'
       //+#10+'function HTTPEncode(const str : String) : string;'
       //+#10+'function HTMLEncode(const str : String) : string;'
       //+#10+'function HTMLDecode(const str : String) : string;'
       ;
end;

exports
  HttpGet,
  HttpPost,
  HttpSetMimeType,
  HttpSetuserAgent,
  HttpGetResult,
  HttpClear,
  HttpGetHeaders,
  HttpSetHeaders,
  HttpGetCookies,
  HttpSetCookies,
  GetDNS,
  GetLocalIPs,
  //HTTPEncode,
  //HTMLEncode,
  //HTMLDecode,
  ScriptDefinition;

initialization
  FHttp := THTTPSend.Create;
finalization
  FHttp.Free;
end.