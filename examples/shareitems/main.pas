program main;

{$mode delphi}{$H+}

uses
  SysUtils,
  ShareItemsDemo,
  Tina4App;

begin
  if FileExists('app.html') then
    RunApp('Tina4 ShareItems Demo', GetCurrentDir, 'app.html', '{}', '', 440, 720)
  else
    RunApp('Tina4 ShareItems Demo', '',
      '<body style="font-family:sans-serif;padding:36px"><h1>ShareItems demo</h1>' +
      '<p>app.html was not found</p></body>', '{}', '', 440, 720);
end.
