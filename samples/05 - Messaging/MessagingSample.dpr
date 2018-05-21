program MessagingSample;
{$APPTYPE CONSOLE}
uses
  sysutils,
  darkThreading;

const
  cSecondsChannel = 'seconds';

const
         MSG_EXIT = $0000;
  MSG_GET_SECONDS = $0100;
  MSG_ADD_SECONDS = $0200;

var
  KeepGoing: boolean;
  ThreadPool: IThreadPool;

type
  TSecondTimer = class( TInterfacedObject, ISubSystem )
  private
    fMessageChannel: IMessageChannel;
    fSecondCounter: uint32;
  private
    function Install( MessageBus: IMessageBus ): boolean;
    function Initialize( MessageBus: IMessageBus ): boolean;
    function Execute: boolean;
    function Finalize: boolean;
  private
    function MessageHandler(aMessage: TMessage): nativeuint;
  public
    constructor Create; reintroduce;
  end;

  TIOSystem = class( TInterfacedObject, ISubsystem )
  private
    fMessagePipe: IMessagePipe;
  private //- ISubSystem -//
    function Install( MessageBus: IMessageBus ): boolean;
    function Initialize( MessageBus: IMessageBus ): boolean;
    function Execute: boolean;
    function Finalize: boolean;
  end;

procedure WriteToConsole(s: string);
begin
  Writeln(s);
end;

{ TSecondTimer }

constructor TSecondTimer.Create;
begin
  inherited Create;
  fSecondCounter := 0;
end;

function TSecondTimer.MessageHandler( aMessage: TMessage ): nativeuint;
begin
  Result := 0;
  case aMessage.Value of

    MSG_EXIT: begin
      KeepGoing := False;
    end;

    MSG_GET_SECONDS: begin
      Result := fSecondCounter;
      fSecondCounter := 0;
    end;

    MSG_ADD_SECONDS: begin
      inc(fSecondCounter,1000);
    end;

  end;
end;

function TSecondTimer.Execute: boolean;
begin
  Result := False;
  if not KeepGoing then begin
    exit;
  end;
  Sleep(1000);
  inc(fSecondCounter);
  if fMessageChannel.MessagesWaiting then begin
    fMessageChannel.GetMessage(MessageHandler);
  end;
  Result := True;
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
  fMessageChannel := MessageBus.CreateChannel(cSecondsChannel);
  Result := True;
end;

{ TIOSystem }

function TIOSystem.Execute: boolean;
var
  ch: char;
begin
  Result := True;
  Read(Ch);
  case ch of
    'r': begin
      Writeln('Requesting second count.');
      Writeln(IntToStr(fMessagePipe.SendMessageWait(MSG_GET_SECONDS)));
    end;
    'a': begin
      Writeln('Adding 1000 seconds.');
      fMessagePipe.SendMessage(MSG_ADD_SECONDS);
    end;
    'x': begin
      fMessagePipe.SendMessage(MSG_EXIT);
      Result := False;
    end;
  end;
end;

function TIOSystem.Finalize: boolean;
begin
  Result := True;
end;

function TIOSystem.Initialize(MessageBus: IMessageBus): boolean;
begin
  Result := True;
end;

function TIOSystem.Install(MessageBus: IMessageBus): boolean;
begin
  fMessagePipe := MessageBus.GetMessagePipe(cSecondsChannel);
  Result := True;
end;

begin
  Writeln('Press ''x'' to exit.');
  Writeln('Press ''r'' to request second count');

  Writeln('Starting up timer threads.');
  ThreadPool := TThreadPool.Create;
  try
    KeepGoing := True;
    ThreadPool.InstallSubSystem(TSecondTimer.Create);
    ThreadPool.InstallSubSystem(TIOSystem.Create);
    ThreadPool.Start;
    try
      while keepgoing do sleep(1);
    finally
      ThreadPool.Stop;
    end;
  finally
    ThreadPool := nil;
  end;
  Writeln('Shutting down aux threads.');
end.
