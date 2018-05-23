program ThreadMethod;
{$APPTYPE CONSOLE}
uses
  sysutils,
  darkThreading;

var
  ConsoleCS: ICriticalSection;
  ThreadPool: IThreadPool;

type
  TSecondTimer = class( TInterfacedObject, IPoolThread )
  private
    fName: string;
  private //- IThreadSubSystem -//
    function Initialize: boolean;
    function Execute: boolean;
    procedure Finalize;
  public
    constructor Create( aName: string ); reintroduce;
  public
    property Name: string read fName write fName;
  end;

procedure WriteToConsole(s: string);
begin
  ConsoleCS.Acquire;
  try
    Writeln(s);
  finally
    ConsoleCS.Release;
  end;
end;

procedure WriteNamedToConsole(Name: string);
begin
  ConsoleCS.Acquire;
  try
    Writeln(Name + ' Second passed.');
  finally
    ConsoleCS.Release;
  end;
end;

{ TSecondTimer }

constructor TSecondTimer.Create(aName: string);
begin
  inherited Create;
  fName := aName;
end;

function TSecondTimer.Execute: boolean;
begin
  Result := True;
  Sleep(1000);
  WriteNamedToConsole( Name );
end;

procedure TSecondTimer.Finalize;
begin
  //- Nothing to see here, method is required. -//
end;

function TSecondTimer.Initialize: boolean;
begin
  Result := True;
end;

begin
  ConsoleCS := TCriticalSection.Create;
  try
    WriteToConsole('Starting up timer threads.');
    ThreadPool := TThreadPool.Create;
    try
      ThreadPool.InstallThread(TSecondTimer.Create('thread 0:'));
      ThreadPool.InstallThread(TSecondTimer.Create('thread 1:'));
      ThreadPool.InstallThread(TSecondTimer.Create('thread 2:'));
      ThreadPool.InstallThread(TSecondTimer.Create('thread 3:'));
      ThreadPool.InstallThread(TSecondTimer.Create('thread 4:'));
      ThreadPool.InstallThread(TSecondTimer.Create('thread 5:'));
      ThreadPool.InstallThread(TSecondTimer.Create('thread 6:'));
      ThreadPool.InstallThread(TSecondTimer.Create('thread 7:'));
      ThreadPool.InstallThread(TSecondTimer.Create('thread 8:'));
      ThreadPool.Start;
      try
        Sleep(20000);
      finally
        ThreadPool.Stop;
      end;
    finally
      ThreadPool := nil;
    end;
    WriteToConsole('Shutting down aux threads.');
  finally
    ConsoleCS := nil;
  end;
  Readln;
end.
