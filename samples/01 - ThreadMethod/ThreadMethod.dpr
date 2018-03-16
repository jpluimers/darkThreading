program ThreadPool;
{$APPTYPE CONSOLE}
uses
  sysutils,
  darkThreading;

type
  TMyMultiThreadedClass = class
  private
    fConsoleCS: ICriticalSection;
    fThreadMethodA: IThreadMethod;
    fThreadMethodB: IThreadMethod;
  private
    function ThreadAHandler: boolean;
    function ThreadBHandler: boolean;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
  public
    procedure WriteToConsole( s: string );
  end;

{ TMyMultiThreadedClass }

constructor TMyMultiThreadedClass.Create;
begin
  inherited Create;
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
  inherited Destroy;
end;

function TMyMultiThreadedClass.ThreadAHandler: boolean;
begin
  WriteToConsole('Thread A Ping');
  Result := True;
end;

function TMyMultiThreadedClass.ThreadBHandler: boolean;
begin
  WriteToConsole('Thread B Ping');
  Result := True;
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
    while (i<5) do begin
      Sleep(1000);
      inc(i);
    end;
  finally
    MyMultiThreadedClass.WriteToConsole('Shutting down aux threads.');
    MyMultiThreadedClass.DisposeOf;
  end;
  Writeln('All shut down correctly.');
  Readln;
end.
