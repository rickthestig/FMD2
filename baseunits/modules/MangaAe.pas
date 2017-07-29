unit MangaAe;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, WebsiteModules, uData, uBaseUnit, uDownloadsManager,
  XQueryEngineHTML, Cloudflare;

implementation

var
  cf: TCFProps;

const
  dirurl = '/manga';

function GetDirectoryPageNumber(const MangaInfo: TMangaInformation; var Page: Integer; const WorkPtr: Integer;
  const Module: TModuleContainer): Integer;
begin
  Result := NET_PROBLEM;
  Page := 1;
  if MangaInfo = nil then Exit(UNKNOWN_ERROR);
  if MangaInfo.FHTTP.GETCF(Module.RootURL + dirurl, cf) then begin
    Result := NO_ERROR;
    Page := XPathCount('//div[@class="pagination"]/a', MangaInfo.FHTTP.Document);
  end;
end;

function GetNameAndLink(const MangaInfo: TMangaInformation;
  const ANames, ALinks: TStringList; const AURL: String;
  const Module: TModuleContainer): Integer;
begin
  Result := NET_PROBLEM;
  if MangaInfo.FHTTP.GETCF(Module.RootURL + dirurl + '/page:' + IncStr(AURL), cf) then
  begin
    Result := NO_ERROR;
    XPathHREFAll('//div[@id="mangadirectory"]/div[@class="mangacontainer"]/a[2]', MangaInfo.FHTTP.Document, ALinks, ANames);
  end;
end;

function GetInfo(const MangaInfo: TMangaInformation;
  const AURL: String; const Module: TModuleContainer): Integer;
begin
  Result := NET_PROBLEM;
  if MangaInfo = nil then Exit(UNKNOWN_ERROR);
  with MangaInfo.mangaInfo, MangaInfo.FHTTP do
  begin
    url := MaybeFillHost(Module.RootURL, AURL);
    if GETCF(url, cf) then begin
      Result := NO_ERROR;
      with TXQueryEngineHTML.Create(Document) do try
        coverLink := XPathString('//img[@class="manga-cover"]/resolve-uri(@src)');
        if title = '' then title := TrimChar(XPathString('//h1[@class="EnglishName"]'), ['(', ')']);
        authors := XPathString('//div[@class="manga-details-author"]/h4[1]');
        genres := XPathString('//div[@class="manga-details-extended"]/ul/string-join(./li/a,", ")');
        summary := XPathString('//div[@class="manga-details-extended"]/h4[last()]');
        status := MangaInfoStatusIfPos(XPathString('//div[@class="manga-details-extended"]/h4[2]'),
          'مستمرة',
          'مكتملة');
        XPathHREFAll('//ul[@class="new-manga-chapters"]/li/a', chapterLinks, chapterName);
        InvertStrings([chapterLinks, chapterName]);
      finally
        Free;
      end;
    end;
  end;
end;

function GetPageNumber(const DownloadThread: TDownloadThread;
  const AURL: String; const Module: TModuleContainer): Boolean;
var
  u: String;
begin
  Result := False;
  if DownloadThread = nil then Exit;
  with DownloadThread.Task.Container, DownloadThread.FHTTP do
  begin
    PageLinks.Clear;
    PageNumber := 0;
    u := RemoveURLDelim(MaybeFillHost(Module.RootURL, AURL));
    if RightStr(u, 2) = '/1' then Delete(u, Length(u)-2, 2);
    u += '/0/full';
    if GETCF(u, cf) then
    begin
      Result := True;
      XPathStringAll('//*[@id="showchaptercontainer"]//img/resolve-uri(@src)', Document, PageLinks);
    end;
  end;
end;

function DownloadImage(const DownloadThread: TDownloadThread;
  const AURL, APath, AName: String; const Module: TModuleContainer): Boolean;
begin
  if DownloadThread.FHTTP.GETCF(AURL, cf) then begin
    Result := SaveImageStreamToFile(DownloadThread.FHTTP, APath, AName) <> '';
  end
  else
    Result := False;
end;

procedure RegisterModule;
begin
  with AddModule do
  begin
    Website := 'MangaAe';
    RootURL := 'https://www.manga.ae';
    OnGetDirectoryPageNumber := @GetDirectoryPageNumber;
    OnGetNameAndLink := @GetNameAndLink;
    OnGetInfo := @GetInfo;
    OnGetPageNumber := @GetPageNumber;
    OnDownloadImage := @DownloadImage;
  end;
end;

initialization
  cf := TCFProps.Create;
  RegisterModule;

finalization
  cf.Free;

end.
