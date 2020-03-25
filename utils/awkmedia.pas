unit awkmedia;

interface

const
  MAX_MUSIC_GENRES = 148;

  Genres:array [0..MAX_MUSIC_GENRES-1] of PAnsiChar = (
{000} 'Blues',
{001} 'Classic Rock',
{002} 'Country',
{003} 'Dance',
{004} 'Disco',
{005} 'Funk',
{006} 'Grunge',
{007} 'Hip-Hop',
{008} 'Jazz',
{009} 'Metal',
{010} 'New Age',
{011} 'Oldies',
{012} 'Other',
{013} 'Pop',
{014} 'R&B',
{015} 'Rap',
{016} 'Reggae',
{017} 'Rock',
{018} 'Techno',
{019} 'Industrial',
{020} 'Alternative',
{021} 'Ska',
{022} 'Death Metal',
{023} 'Pranks',
{024} 'Soundtrack',
{025} 'Euro-Techno',
{026} 'Ambient',
{027} 'Trip-Hop',
{028} 'Vocal',
{029} 'Jazz+Funk',
{030} 'Fusion',
{031} 'Trance',
{032} 'Classical',
{033} 'Instrumental',
{034} 'Acid',
{035} 'House',
{036} 'Game',
{037} 'Sound Clip',
{038} 'Gospel',
{039} 'Noise',
{040} 'AlternRock',
{041} 'Bass',
{042} 'Soul',
{043} 'Punk',
{044} 'Space',
{045} 'Meditative',
{046} 'Instrumental Pop',
{047} 'Instrumental Rock',
{048} 'Ethnic',
{049} 'Gothic',
{050} 'Darkwave',
{051} 'Techno-Industrial',
{052} 'Electronic',
{053} 'Pop-Folk',
{054} 'Eurodance',
{055} 'Dream',
{056} 'Southern Rock',
{057} 'Comedy',
{058} 'Cult',
{059} 'Gangsta',
{060} 'Top 40',
{061} 'Christian Rap',
{062} 'Pop/Funk',
{063} 'Jungle',
{064} 'Native American',
{065} 'Cabaret',
{066} 'New Wave',
{067} 'Psychadelic',
{068} 'Rave',
{069} 'Showtunes',
{070} 'Trailer',
{071} 'Lo-Fi',
{072} 'Tribal',
{073} 'Acid Punk',
{074} 'Acid Jazz',
{075} 'Polka',
{076} 'Retro',
{077} 'Musical',
{078} 'Rock & Roll',
{079} 'Hard Rock',
{080} 'Folk',
{081} 'Folk-Rock',
{082} 'National Folk',
{083} 'Swing',
{084} 'Fast Fusion',
{085} 'Bebob',
{086} 'Latin',
{087} 'Revival',
{088} 'Celtic',
{089} 'Bluegrass',
{090} 'Avantgarde',
{091} 'Gothic Rock',
{092} 'Progressive Rock',
{093} 'Psychedelic Rock',
{094} 'Symphonic Rock',
{095} 'Slow Rock',
{096} 'Big Band',
{097} 'Chorus',
{098} 'Easy Listening',
{099} 'Acoustic',
{100} 'Humour',
{101} 'Speech',
{102} 'Chanson',
{103} 'Opera',
{104} 'Chamber Music',
{105} 'Sonata',
{106} 'Symphony',
{107} 'Booty Brass',
{108} 'Primus',
{109} 'Porn Groove',
{110} 'Satire',
{111} 'Slow Jam',
{112} 'Club',
{113} 'Tango',
{114} 'Samba',
{115} 'Folklore',
{116} 'Ballad',
{117} 'Poweer Ballad',
{118} 'Rhytmic Soul',
{119} 'Freestyle',
{120} 'Duet',
{121} 'Punk Rock',
{122} 'Drum Solo',
{123} 'A Capela',
{124} 'Euro-House',
{125} 'Dance Hall',
{126} 'Goa',
{127} 'Drum & Bass',
{128} 'Club-House',
{129} 'Hardcore',
{130} 'Terror',
{131} 'Indie',
{132} 'BritPop',
{133} 'Negerpunk',
{134} 'Polsk Punk',
{135} 'Beat',
{136} 'Christian Gangsta Rap',
{137} 'Heavy Metal',
{138} 'Black Metal',
{139} 'Crossover',
{140} 'Contemporary Christian',
{141} 'Christian Rock',
{142} 'Merengue',
{143} 'Salsa',
{144} 'Trash Metal',
{145} 'Anime',
{146} 'JPop',
{147} 'Synthpop');


function GenreName(idx:cardinal):PAnsiChar;


implementation

function GenreName(idx:cardinal):PAnsiChar;
begin
  if idx<MAX_MUSIC_GENRES then
  begin
    result:=Genres[idx];
  end
  else
    result:=nil;
end;

end.