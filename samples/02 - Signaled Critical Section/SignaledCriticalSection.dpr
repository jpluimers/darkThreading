program SignaledCriticalSection;
{$APPTYPE CONSOLE}
uses
  sysutils,
  darkThreading;

type
  TMyMultiThreadedClass = class
  private
    fCounter: uint32;
    fPrintOutput: boolean;
    fConsoleCS: ICriticalSection;
    fSignalCS: ISignaledCriticalSection;
    fThreadMethodA: IThreadMethod;
    fThreadMethodB: IThreadMethod;
  private
    function ThreadAHandler: boolean;
    function ThreadBHandler: boolean;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
  public
    procedure Print;
    procedure WriteToConsole( s: string );
  end;

{ TMyMultiThreadedClass }

constructor TMyMultiThreadedClass.Create;
begin
  inherited Create;
  fCounter := 0;
  fPrintOutput := false;
  fSignalCS := TSignaledCriticalSection.Create;
  fConsoleCS := TCriticalSection.Create;
  fThreadMethodA := TThreadMethod.Create;
  fThreadMethodB := TThreadMethod.Create;
  fThreadMethodA.ExecuteMethod := ThreadAHandler;
  fThreadMethodB.ExecuteMethod := ThreadBHandler;
end;

destructor TMyMultiThreadedClass.Destroy;
begin
  fThreadMethodA.Terminate(1001);
  fThreadMethodB.Terminate(1001);
  fThreadMethodA := nil;
  fThreadMethodB := nil;
  fConsoleCS := nil;
  fSignalCS := nil;
  inherited Destroy;
end;

function TMyMultiThreadedClass.ThreadAHandler: boolean;
begin
  fSignalCS.Acquire;
  try
    //- If there is work to do, do it.
    if fPrintOutput then begin
      WriteToConsole('Output Requested.');
      fPrintOutput := False;
      exit;
    end;
    //- Otherwise, sleep until there is work
    while not (fPrintOutput) do fSignalCS.Sleep;
    WriteToConsole('Output Requested.');
    fPrintOutput := False;
  finally
    fSignalCS.Release;
  end;
  Result := True;
end;

function TMyMultiThreadedClass.ThreadBHandler: boolean;
begin
  Sleep(1000);
  WriteToConsole(IntToStr(fCounter)+' Seconds passed');
  inc(fCounter);
  Result := True;
end;

procedure TMyMultiThreadedClass.print;
begin
  fSignalCS.Acquire;
  try
    fPrintOutput := True;
  finally
    fSignalCS.Release;
  end;
  fSignalCS.Wake;
end;

procedure TMyMultiThreadedClass.WriteToConsole(s: string);
begin
  fConsoleCS.Acquire;
  try
    Writeln(s);
  finally
    fConsoleCS.Release;
  end;
end;

var
  i: uint32;
  MyMultiThreadedClass: TMyMultiThreadedClass;

begin
  i := 0;
  Writeln('Starting up aux threads.');
  MyMultiThreadedClass := TMyMultiThreadedClass.Create;
  try
    Writeln('Press [RETURN] / [ENTER] to print output.');
    while (True) do begin
      Readln;
      MyMultiThreadedClass.Print;
    end;
  finally
    MyMultiThreadedClass.DisposeOf;
  end;
  Writeln('All shut down correctly.');
  Readln;
end.
