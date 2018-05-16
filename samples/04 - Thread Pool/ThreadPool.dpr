program ThreadMethod;
{$APPTYPE CONSOLE}
uses
  sysutils,
  darkThreading;

var
  ConsoleCS: ICriticalSection;
  ThreadPool: IThreadPool;

type
  TSecondTimer = class( TInterfacedObject, ISubSystem )
  private
    fName: string;
    function Install( MessageBus: IMessageBus ): boolean;
    function Initialize( MessageBus: IMessageBus ): boolean;
    function Execute: boolean;
    function Finalize: boolean;
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

function TSecondTimer.Finalize: boolean;
begin
  Result := True;
end;

function TSecondTimer.Initialize(MessageBus: IMessageBus): boolean;
begin
  Result := True;
end;

function TSecondTimer.Install(MessageBus: IMessageBus): boolean;
begin
  Result := True;
end;

begin
  ConsoleCS := TCriticalSection.Create;
  try
    WriteToConsole('Starting up timer threads.');
    ThreadPool := TThreadPool.Create;
    try
      ThreadPool.InstallSubSystem(TSecondTimer.Create('thread 0:'));
      ThreadPool.InstallSubSystem(TSecondTimer.Create('thread 1:'));
      ThreadPool.InstallSubSystem(TSecondTimer.Create('thread 2:'));
      ThreadPool.InstallSubSystem(TSecondTimer.Create('thread 3:'));
      ThreadPool.InstallSubSystem(TSecondTimer.Create('thread 4:'));
      ThreadPool.InstallSubSystem(TSecondTimer.Create('thread 5:'));
      ThreadPool.InstallSubSystem(TSecondTimer.Create('thread 6:'));
      ThreadPool.InstallSubSystem(TSecondTimer.Create('thread 7:'));
      ThreadPool.InstallSubSystem(TSecondTimer.Create('thread 8:'));
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
