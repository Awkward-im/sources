unit Support;

interface

const
  monthnames:array [1..12] of AnsiString = (
   'Январь',
   'Февраль',
   'Март',
   'Апрель',
   'Май',
   'Июнь',
   'Июль',
   'Август',
   'Сентябрь',
   'Октябрь',
   'Ноябрь',
   'Декабрь'
  );

function GetSumm(avalue: cardinal): AnsiString;
function GetRusDate(date: TDateTime; full:boolean): AnsiString;

implementation

uses
  SysUtils;
{
const
  RusLetters:array [0..1,0..32] of UTF8Char = (
  ('А','Б','В','Г','Д','Е','Ё','Ж','З','И','Й','К','Л','М','Н','О',
   'П','Р','С','Т','У','Ф','Х','Ц','Ч','Ш','Щ','Ъ','Ы','Ь','Э','Ю','Я'),
  ('а','б','в','г','д','е','ё','ж','з','и','й','к','л','м','н','о',
   'п','р','с','т','у','ф','х','ц','ч','ш','щ','ъ','ы','ь','э','ю','я')
  );
}
function GetSumm(avalue: cardinal): AnsiString;
var
  st: string;
  i: integer;
  c: array[1..4] of integer;
  s: array[1..4, 1..3] of string;
begin
  s[1, 1] := 'миллиард';
  s[1, 2] := 'миллиарда';
  s[1, 3] := 'миллиардов';
  s[2, 1] := 'миллион';
  s[2, 2] := 'миллиона';
  s[2, 3] := 'миллионов';
  s[3, 1] := 'тысяча';
  s[3, 2] := 'тысячи';
  s[3, 3] := 'тысяч';
  s[4, 1] := '';
  s[4, 2] := '';
  s[4, 3] := '';

  st := '';
  c[1] := avalue div 1000000000;
  c[2] := (avalue mod 1000000000) div 1000000;
  c[3] := (avalue mod 1000000) div 1000;
  c[4] := avalue mod 1000;

  for i := 1 to 4 do
    if c[i] <> 0 then
    begin
      if c[i] div 100 <> 0 then
      begin
        case c[i] div 100 of
          1: st := st + 'Сто ';
          2: st := st + 'Двести ';
          3: st := st + 'Триста ';
          4: st := st + 'Четыреста ';
          5: st := st + 'Пятьсот ';
          6: st := st + 'Шестьсот ';
          7: st := st + 'Семьсот ';
          8: st := st + 'Восемьсот ';
          9: st := st + 'Девятьсот ';
        end;
      end;
      if (c[i] mod 100) div 10 <> 1 then
      begin
        case (c[i] mod 100) div 10 of
          2: st := st + 'Двадцать ';
          3: st := st + 'Тридцать ';
          4: st := st + 'Сорок ';
          5: st := st + 'Пятьдесят ';
          6: st := st + 'Шестьдесят ';
          7: st := st + 'Семьдесят ';
          8: st := st + 'Восемьдесят ';
          9: st := st + 'Девяносто ';
        end;
        case c[i] mod 10 of
          1: if i = 3 then
              st := st + 'Одна '
            else
              st := st + 'Один ';
          2: if i = 3 then
              st := st + 'Две '
            else
              st := st + 'Два ';
          3: st := st + 'Три ';
          4: st := st + 'Четыре ';
          5: st := st + 'Пять ';
          6: st := st + 'Шесть ';
          7: st := st + 'Семь ';
          8: st := st + 'Восемь ';
          9: st := st + 'Девять ';
        end;
      end
      else
      begin
        case (c[i] mod 100) of
          10: st := st + 'Десять ';
          11: st := st + 'Одиннадцать ';
          12: st := st + 'Двенадцать ';
          13: st := st + 'Тринадцать ';
          14: st := st + 'Четырнадцать ';
          15: st := st + 'Пятндцать ';
          16: st := st + 'Шестнадцать ';
          17: st := st + 'Семнадцать ';
          18: st := st + 'Восемнадцать ';
          19: st := st + 'Девятнадцать ';
        end;
      end;
      if (c[i] mod 100 >= 10) and (c[i] mod 100 <= 19) then
        st := st + s[i, 3] + ' '
      else
        case c[i] mod 10 of
          1   : st := st + s[i, 1] + ' ';
          2..4: st := st + s[i, 2] + ' ';
          5..9,
          0   : st := st + s[i, 3] + ' ';
        end;
    end;
  if st = '' then
  begin
    Result := 'Ноль '
  end
  else
  begin
    Result := AnsiLowerCase(st);
    Result[1] := st[1]; Result[2] := st[2];
  end;

  case avalue mod 100 of
    11..19: st := 'рублей';
  else
   case avalue mod 10 of
     1   : st := 'рубль';
     2..4: st := 'рубля';
   else
     st := 'рублей';
   end;
  end;
  Result := Result + st + ' 00 копеек'
end;

function GetRusDate(date: TDateTime; full:boolean): AnsiString;
const
  sMonth: array [1..12,boolean] of ansistring = (
    ('янв','Января'  ),
    ('фев','Февраля' ),
    ('мар','Марта'   ),
    ('апр','Апреля'  ),
    ('мая','Мая'     ),
    ('июн','Июня'    ),
    ('июл','Июля'    ),
    ('авг','Августа' ),
    ('сен','Сентября'),
    ('окт','Октября' ),
    ('ноя','Ноября'  ),
    ('дек','Декабря'  )
    );
var
  Year, Month, Day: word;
begin
  DecodeDate(Date, Year, Month, Day);
  Result := IntToStr(Day) + ' ' + sMonth[Month,full] + ' ' + IntToStr(Year) + ' г.';
end;


end.
