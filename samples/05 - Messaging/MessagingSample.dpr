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
  ThreadSystem: IThreadSystem;

type
  TSecondTimer = class( TInterfacedObject, IThreadSubSystem )
  private
    fMessageChannel: IMessageChannel;
    fSecondCounter: uint32;
  private
    function MainThread: boolean;
    function Dedicated: boolean;
    function Install( MessageBus: IMessageBus ): boolean;
    function Initialize( MessageBus: IMessageBus ): boolean;
    function Execute: boolean;
    procedure Finalize;
  private
    function MessageHandler(aMessage: TMessage): nativeuint;
  public
    constructor Create; reintroduce;
  end;

  TIOSystem = class( TInterfacedObject, IThreadSubSystem )
  private
    fMessagePipe: IMessagePipe;
  private //- ISubSystem -//
    function MainThread: boolean;
    function Dedicated: boolean;
    function Install( MessageBus: IMessageBus ): boolean;
    function Initialize( MessageBus: IMessageBus ): boolean;
    function Execute: boolean;
    procedure Finalize;
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

function TSecondTimer.MainThread: boolean;
begin
  Result := False;
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

function TSecondTimer.Dedicated: boolean;
begin
  Result := True;
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

procedure TSecondTimer.Finalize;
begin
  //- Nothing to see here, method is required by interface -//
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

function TIOSystem.Dedicated: boolean;
begin
  Result := True;
end;

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
  Sleep(0); // keep from burning CPU cycles, IO is main thread dedicated and not sleeping on the GetMessage() call.
end;

procedure TIOSystem.Finalize;
begin
  //- Nothing to see here, method is required by interface -//
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

function TIOSystem.MainThread: boolean;
begin
  Result := True;
end;

begin
  Writeln('Press ''x'' to exit.');
  Writeln('Press ''r'' to request second count');

  Writeln('Starting up timer threads.');
  ThreadSystem := TThreadSystem.Create;
  try
    KeepGoing := True;
    ThreadSystem.InstallSubSystem(TSecondTimer.Create);
    ThreadSystem.InstallSubSystem(TIOSystem.Create);
    ThreadSystem.Run;
  finally
    ThreadSystem := nil;
  end;
  Writeln('Shutting down aux threads.');
end.
