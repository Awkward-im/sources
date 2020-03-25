uses
  strutils,sysutils,
  fphttpclient,opensslsockets,
  jsontools;

const
{
  g_host  = 'http://imtranslator.net/translation/dictionary/DicService.asmx/lookup?dicID=&flags=DEFAULT';
  g_lang  = '&lang=en%2F';
  g_lang1 = '&langs=en%2F';
  g_text  = '&text=';
}

  g_host  = '';
  g_lang1 = '';

  l = '{ dirCode:''en-ru'', template:''General'', text:''';
  l2 = ''', lang:''en'', limit:''3000'',useAutoDetect:true, key:'''', ts:''MainSite'',tid:'''', IsMobile:true}';

  l0 = '{ dirCode:"en-ru", template:"General", text:"long life to the king", lang:"en", limit:"3000",useAutoDetect:true, key:"123", ts:"MainSite",tid:"", IsMobile:false}';
//  l0 = '{ dirCode:"en-ru", template:"General", text:"{text}", '+
//       'lang:"en", limit:3000,useAutoDetect:true, key:"", ts:"MainSite",tid:"", IsMobile:true}';

function TranslateGoogle(src:AnsiString):AnsiString;
var
  gt:TFPHTTPClient;
  ls,res:AnsiString;
  jn:TJsonNode;
  i1,i2,code:integer;
begin
  result:='';

  gt:=TFPHTTPClient.Create(nil);
  gt.IOTimeout:=17000;

  res:= g_host +
'https://translate.yandex.net/api/v1/tr/translate?lang=en-ru&text='+EncodeURLElement(src);
//    'https://www.online-translator.com/services/soap.asmx/GetTranslation?';
//    ls:=l+EncodeURLElement(src)+l2;
//    ls:=StringReplace(l0,'{text}',EncodeURLElement(src),[rfReplaceAll]);
//    ls:=EncodeURLElement(l)+EncodeURLElement(src)+EncodeURLElement(l2)
    ;
//    'https://www.apertium.org/apy/listPairs';
//    'https://www.apertium.org/apy/translate?langpair=eng|ru&q='+EncodeURLElement(src);
//        'https://www.bing.com/ttranslatev3/?text='+EncodeURLElement(src)+'&from=en&to=ru';
//        g_lang +{'ru'+
//        g_lang1+'ru'+}
//        g_text +EncodeURLElement(src);
//  gt.AddHeader('Content-length',IntToStr(Length(l+EncodeURLElement(src)+l2)));
//  gt.AddHeader('Content-Type','application/json; charset=UTF-8');
//  gt.AddHeader('Content-Type','application/x-www-form-urlencoded');

//writeln(gt.GetHeader('Content-length'));
//writeln(gt.GetHeader('Content-Type'));
  gt.Post(res,'f.txt');
//  result:=gt.FormPost(res,ls{,'f.txt'});

  gt.Free;
end;

begin
  writeln(TranslateGoogle('stars are Fl&ry bright. Isnt it?'));
end.
