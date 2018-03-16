program AtomicRingBuffer;
{$APPTYPE CONSOLE}
uses
  sysutils,
  darkThreading;

type
  TMyMultiThreadedClass = class
  private
    fPrintOutput: boolean;
    fConsoleCS: ICriticalSection;
    fSignalCS: ISignaledCriticalSection;
    fThreadMethodA: IThreadMethod;
    fThreadMethodB: IThreadMethod;
    fAtomicRingBuffer: IAtomicRingBuffer<uint32>;

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
  fPrintOutput := false;
  fAtomicRingBuffer := TAtomicRingBuffer<uint32>.Create;
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
      fAtomicRingBuffer.Push(4);
      fPrintOutput := False;
      exit;
    end;
    //- Otherwise, sleep until there is work
    while not (fPrintOutput) do fSignalCS.Sleep;
    fAtomicRingBuffer.Push(4);
    fPrintOutput := False;
  finally
    fSignalCS.Release;
  end;
  Result := True;
end;

function TMyMultiThreadedClass.ThreadBHandler: boolean;
var
  EnumVal: uint32;
begin
  repeat
    while not fAtomicRingBuffer.Pull(EnumVal) do begin
      Sleep(1);
    end;
    WriteToConsole('Message recieved from Thread A, value ('+IntToStr(EnumVal)+')');
  until false;
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
