program Engine;

uses
  System.StartUpCopy,
  FMX.Forms,
  enginepas in 'enginepas.pas' ,
  Engine.Core.Math in 'src\Core\Engine.Core.Math.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
