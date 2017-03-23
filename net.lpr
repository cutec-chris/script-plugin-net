library net;

{$mode objfpc}{$H+}
{$DEFINE USE_BIN_STR}

uses
  Classes, sysutils, laz_synapse, httpsend, synautil, blcksock, general_nogui,Utils;

var
  FHttp : THTTPSend;
  TcpSockets : array of TTCPBlockSocket;
  UDPSockets : array of TUDPBlockSocket;
  Bound: String = '';

function HttpGet(aURL: PChar; aTimeout: Integer): PChar;
var
  ares : string;
begin
  Fhttp.Timeout:=aTimeout;
  Fhttp.KeepAlive:=false;
  Fhttp.HTTPMethod('GET',aURL);
  if Fhttp.ResultCode=200 then
    begin
      setlength(ares,Fhttp.Document.Size);
      Fhttp.Document.Read(aRes[1],Fhttp.Document.Size);
      Result := PChar(aRes);
    end
  else Result:='';
end;
function HttpPost(aURL, Content: PChar; aTimeout: Integer
  ): PChar;
var
  ares : string;
begin
  Fhttp.Timeout:=aTimeout;
  if Content<>'' then
    Fhttp.Document.Write(Content[1],length(Content));
  Fhttp.HTTPMethod('POST',aURL);
  if Fhttp.ResultCode=200 then
    begin
      setlength(ares,Fhttp.Document.Size);
      Fhttp.Document.Read(ares[1],Fhttp.Document.Size);
      Result := PChar(aRes);
    end
  else Result:='';
end;
procedure HttpSetMimeType(MimeType: PChar);
begin
  Fhttp.MimeType:=MimeType;
end;
procedure HttpSetUserAgent(UserAgent: PChar);
begin
  Fhttp.UserAgent:=UserAgent;
end;
function HttpGetResult: Integer;
begin
  Result := Fhttp.ResultCode;
end;
function HttpGetHeaders: PChar;
begin
  Result := PChar(Fhttp.Headers.Text);
end;
procedure HttpSetHeaders(Headers: PChar);
begin
  Fhttp.Headers.Text:=Headers;
end;
function HttpGetCookies: PChar;
begin
  Result := PChar(Fhttp.Cookies.Text);
end;
procedure HttpSetCookies(Headers: PChar);
begin
  Fhttp.Cookies.Text:=Headers;
end;
procedure HttpClear;
begin
  Fhttp.Clear;
  Bound := IntToHex(Random(MaxInt), 8) + '_Synapse_boundary';
end;
procedure HttpAddMultipartField(InputFieldName,InputFieldValue : PChar);
begin
  WriteStrToStream(Fhttp.Document,
    '--' + Bound + CRLF +
    'Content-Disposition: form-data; name=' + AnsiQuotedStr(InputFieldName, '"') + CRLF +
    'Content-Type: text/plain' + CRLF +
    CRLF);
  WriteStrToStream(Fhttp.Document, InputFieldValue + CRLF);
  Fhttp.MimeType := 'multipart/form-data; boundary=' + Bound;
end;
procedure HttpAddMultipartFile(InputFileFieldName,InputFileName,InputFile : PChar);
var
  InputFileData: TFileStream;
begin
  WriteStrToStream(Fhttp.Document,
    CRLF +
    '--' + Bound + CRLF +
    'Content-Disposition: form-data; name=' + AnsiQuotedStr(InputFileFieldName, '"') + ';' + CRLF +
    #9'filename=' + AnsiQuotedStr(InputFileName, '"') + CRLF +
    'Content-Type: application/octet-string' + CRLF +
    CRLF);
  InputFileData := TFileStream.Create(InputFile,fmOpenRead);
  FHTTP.Document.CopyFrom(InputFileData, 0);
  WriteStrToStream(Fhttp.Document,CRLF);
  InputFileData.Free;
  Fhttp.MimeType := 'multipart/form-data; boundary=' + Bound;
end;
procedure HttpCloseMultipart;
begin
  WriteStrToStream(Fhttp.Document,
    '--' + Bound + '--' + CRLF);
end;
function HttpSaveToFile(aFile : PChar) : Boolean;
begin
  Result := False;
  try
    FHttp.Document.SaveToFile(aFile);
    Result :=  True;
  except
  end;
end;
function HTTPLoadFromFile(aFile : PChar) : Boolean;
begin
  Result := False;
  try
    FHttp.Document.LoadFromFile(aFile);
    Result :=  True;
  except
  end;
end;
function GetDNS: PChar;
begin
  //Result := GetDNS;
end;
function GetLocalIPs: PChar;
begin
  //Result := GetLocalIPs;
end;
function TCPCreateSocket : Integer;
var
  i: Integer;
  aSock: TTCPBlockSocket;
begin
  Result := -1;
  aSock := TTCPBlockSocket.Create;
  for i := 0 to high(TcpSockets) do
    if TcpSockets[i] = nil then
      begin
        TcpSockets[i] := aSock;
        Result := i;
        break;
      end;
  if Result = -1 then
    begin
      SetLength(TcpSockets,length(TcpSockets)+1);
      Result := length(TcpSockets)-1;
      TcpSockets[Result] := aSock;
    end;
end;
function TCPDestroySocket(Id : Integer) : Boolean;
begin
  Result := False;
  if Id < length(TcpSockets) then
    begin
      TcpSockets[Id].Destroy;
      TcpSockets[Id] := nil;
      Result := True;
    end;
end;
function TCPConnect(Id : Integer;IP : PChar;Port : Integer) : Boolean;
begin
  Result := False;
  if Id < length(TcpSockets) then
    begin
      TcpSockets[Id].Connect(Ip,IntToStr(Port));
      Result := TcpSockets[Id].LastError=0;
    end;
end;
function TCPBind(Id : Integer;IP : PChar;Port : Integer) : Boolean;
begin
  Result := False;
  if Id < length(TcpSockets) then
    begin
      TcpSockets[Id].Bind(Ip,IntToStr(Port));
      Result := TcpSockets[Id].LastError=0;
    end;
end;
function TCPSendString(Id : Integer;Data : PChar) : Boolean;
begin
  Result := False;
  if Id < length(TcpSockets) then
    begin
      TcpSockets[Id].SendString(Data);
      Result := TcpSockets[Id].LastError=0;
    end;
end;
function TCPReceiveString(Id : Integer;Timeout : Integer) : PChar;
begin
  Result := PChar('');
  if Id < length(TcpSockets) then
    begin
      Result := PChar(TcpSockets[Id].RecvPacket(Timeout));
    end;
end;
function UDPCreateSocket : Integer;
var
  i: Integer;
  aSock: TUDPBlockSocket;
begin
  Result := -1;
  aSock := TUDPBlockSocket.Create;
  for i := 0 to high(UDPSockets) do
    if UDPSockets[i] = nil then
      begin
        UDPSockets[i] := aSock;
        Result := i;
        break;
      end;
  if Result = -1 then
    begin
      SetLength(UDPSockets,length(UDPSockets)+1);
      Result := length(UDPSockets)-1;
      UDPSockets[Result] := aSock;
    end;
end;
function UDPDestroySocket(Id : Integer) : Boolean;
begin
  Result := False;
  if Id < length(UDPSockets) then
    begin
      UDPSockets[Id].Destroy;
      UDPSockets[Id] := nil;
      Result := True;
    end;
end;
function UDPMulticastTTL(Id : Integer;TTL : Integer) : Boolean;
begin
  Result := False;
  if Id < length(UDPSockets) then
    begin
      UDPSockets[Id].MulticastTTL:=TTL;
      Result := True;
    end;
end;
function UDPAddMulticast(Id : Integer;IP : PChar) : Boolean;
begin
  Result := False;
  if Id < length(UDPSockets) then
    begin
      UDPSockets[Id].AddMulticast(IP);
      Result := True;
    end;
end;
function UDPConnect(Id : Integer;IP : PChar;Port : Integer) : Boolean;
begin
  Result := False;
  if Id < length(UDPSockets) then
    begin
      UDPSockets[Id].Connect(Ip,IntToStr(Port));
      Result := UDPSockets[Id].LastError=0;
    end;
end;
function UDPBind(Id : Integer;IP : PChar;Port : Integer) : Boolean;
begin
  Result := False;
  if Id < length(UDPSockets) then
    begin
      UDPSockets[Id].Bind(Ip,IntToStr(Port));
      Result := UDPSockets[Id].LastError=0;
    end;
end;
function UDPSendString(Id : Integer;Data : PChar) : Boolean;
begin
  Result := False;
  if Id < length(UDPSockets) then
    begin
      UDPSockets[Id].SendString(Data);
      Result := UDPSockets[Id].LastError=0;
    end;
end;
function UDPReceiveString(Id : Integer;Timeout : Integer) : PChar;
begin
  Result := PChar('');
  if Id < length(UDPSockets) then
    begin
      Result := PChar(UDPSockets[Id].RecvPacket(Timeout));
    end;
end;

function ScriptDefinition : PChar;stdcall;
begin
  Result := 'function HttpGet(URL : PChar;aTimeout : Integer) : PChar;'
       +#10+'function HttpPost(URL,Content : PChar;aTimeout : Integer) : PChar;'
       +#10+'procedure HttpSetMimeType(MimeType : PChar);'
       +#10+'procedure HttpSetuserAgent(UserAgent : PChar);'
       +#10+'function HttpGetResult : Integer;'
       +#10+'procedure HttpClear;'
       +#10+'function HttpGetHeaders : PChar;'
       +#10+'procedure HttpSetHeaders(Headers : PChar);'
       +#10+'function HttpGetCookies : PChar;'
       +#10+'procedure HttpSetCookies(Headers : PChar);'
       +#10+'procedure HttpAddMultipartField(InputFieldName,InputFieldValue : PChar);'
       +#10+'procedure HttpAddMultipartFile(InputFileFieldName,InputFileName,InputFile : PChar);'
       +#10+'procedure HttpCloseMultipart;'
       +#10+'function HttpSaveToFile(aFile : PChar) : Boolean;'
       +#10+'function HTTPLoadFromFile(aFile : PChar) : Boolean;'
       +#10+'function GetDNS : PChar;'
       +#10+'function GetLocalIPs : PChar;'
       //+#10+'function HTMLEncode(const str : PChar) : PChar;'
       +#10+'function HTTPEncode(const str : PChar) : PChar;'
       //+#10+'function HTMLDecode(const str : PChar) : PChar;'
       +#10+'function TCPCreateSocket : Integer;'
       +#10+'function TCPDestroySocket(Id : Integer) : Boolean;'
       +#10+'function TCPConnect(Id : Integer;IP : PChar;Port : Integer) : Boolean;'
       +#10+'function TCPBind(Id : Integer;IP : PChar;Port : Integer) : Boolean;'
       +#10+'function TCPSendString(Id : Integer;Data : PChar) : Boolean;'
       +#10+'function TCPReceiveString(Id : Integer;Timeout : Integer) : PChar;'
       +#10+'function UDPCreateSocket : Integer;'
       +#10+'function UDPMulticastTTL(Id : Integer;TTL : Integer) : Boolean;'
       +#10+'function UDPAddMulticast(Id : Integer;IP : PChar) : Boolean;'
       +#10+'function UDPDestroySocket(Id : Integer) : Boolean;'
       +#10+'function UDPConnect(Id : Integer;IP : PChar;Port : Integer) : Boolean;'
       +#10+'function UDPBind(Id : Integer;IP : PChar;Port : Integer) : Boolean;'
       +#10+'function UDPSendString(Id : Integer;Data : PChar) : Boolean;'
       +#10+'function UDPReceiveString(Id : Integer;Timeout : Integer) : PChar;'
       ;
end;

exports
  HttpGet,
  HttpPost,
  HttpSetMimeType,
  HttpSetuserAgent,
  HttpGetResult,
  HttpClear,
  HttpAddMultipartField,
  HttpAddMultipartFile,
  HttpCloseMultipart,
  HttpGetHeaders,
  HttpSetHeaders,
  HttpGetCookies,
  HttpSetCookies,
  HttpSaveToFile,
  HTTPLoadFromFile,
  GetDNS,
  GetLocalIPs,
  HTTPEncode,
  //HTMLEncode,
  //HTMLDecode,
  TCPCreateSocket,
  TCPDestroySocket,
  TCPConnect,
  TCPBind,
  TCPSendString,
  TCPReceiveString,
  UDPCreateSocket,
  UDPDestroySocket,
  UDPMulticastTTL,
  UDPAddMulticast,
  UDPConnect,
  UDPBind,
  UDPSendString,
  UDPReceiveString,
  ScriptDefinition;

initialization
  FHttp := THTTPSend.Create;
finalization
  FHttp.Free;
end.
