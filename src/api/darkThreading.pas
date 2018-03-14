//------------------------------------------------------------------------------
// This file is part of the DarkGlass game engine project.
// More information can be found here: http://chapmanworld.com/darkglass
//
// DarkGlass is licensed under the MIT License:
//
// Copyright 2018 Craig Chapman
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the “Software”),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.
//------------------------------------------------------------------------------
unit darkThreading;

interface

type
  ///  <summary>
  ///    Represents a connection to a message channel for sending
  ///    messages.
  ///  </summary>
  THChannelConnection = uint32;

  ///  <summary>
  ///     This record is returned from a call to SendMessage() to indicate
  ///     if the message was successfully sent, and to return any response
  ///     value.
  ///  </summary>
  TMessageResponse = record
    Sent: boolean;
    ParamA: NativeUInt;
    ParamB: NativeUInt;
  end;

  ///  <summary>
  ///    A record type representing a communication message between
  ///    subsystems.
  ///  </summary>
  PMessage = ^TMessage;
  TMessage = record
    MessageValue: uint32;
    ParamA: NativeUInt;
    ParamB: NativeUInt;
    Original: PMessage;
    Handled: Boolean;
    LockResponse: procedure of object;
    UnlockResponse: procedure of object;
  end;


type

  /// <summary>
  ///   An implementation of IMessagePipe provides a thread-safe unidirectional
  ///   mechanism for sending messages between two threads. Each pipe may have
  ///   a single originator thread and a single target thread, and messages
  ///   flow from the originator to the target.
  /// </summary>
  /// <remarks>
  ///   The DarkGlass engine provides IMessageChannel and IMessageBus to
  ///   aggregate multiple pipes, allowing for bidirectional communication
  ///   among multiple originators and targets. The IMessagePipe is the
  ///   lowest-level primitive of this communications system, providing
  ///   lock-less communication between a single originator and a single target
  ///   which may exist on different execution threads.
  /// </remarks>
  IMessagePipe = interface
    ['{B8FE0D89-B21F-4352-B7FE-F96A335F6EBE}']


    /// <summary>
    ///   The originator inserts messages into the pipe by calling the Push()
    ///   method.
    /// </summary>
    /// <param name="aMessage">
    ///   A TMessage structure containing the message information to be sent to
    ///   the target.
    /// </param>
    /// <returns>
    ///   Returns true if the message is successfully inserted into the pipe
    ///   (does not indicate that the message is retrieved from the pipe by the
    ///   target). If this method returns false, it is likely that the pipe is
    ///   full, and a re-try later may be successful.
    /// </returns>
    function Push( aMessage: TMessage ): boolean;

    /// <summary>
    ///   The Pull() method is polled by the message target, and retreieves
    ///   messages from the pipe which were previously inserted by the
    ///   originator calling the Push() method.
    /// </summary>
    /// <param name="aMessage">
    ///   A TMessage structure to be populated with a message from the pipe.
    /// </param>
    /// <returns>
    ///   If there is a message in the pipe to be returned, the aMessage
    ///   parameter is populated and this method returns true. Otherwise, if
    ///   the pipe is empty, this method returns false.
    /// </returns>
    function Pull( var aMessage: TMessage ): boolean;
  end;

type
  ///  <summary>
  ///    A procedure callback for handling messages from the channel.
  ///  </summary>
  TMessageHandlerProc = procedure ( MessageValue: uint32; var ParamA: NativeUInt; var ParamB: NativeUInt; var Handled: boolean ) of object;

  /// <summary>
  ///   An implementation of IMessageChannel provides a named mechanism for
  ///   delivering messages to a sub-system. A message channel is a collection
  ///   of message pipes, where each message pipe facilitates communication
  ///   between one originator sub-system, and the target subsystem which owns
  ///   the channel.
  /// </summary>
  /// <remarks>
  ///   As an abstract example, there may be a sub-system responsible for
  ///   playing audio files, which owns a message channel named 'audio'. Every
  ///   sub-system which wishes to send messages to the audio sub-system, must
  ///   acquire a pipe from the 'audio' channel, and may then send messages
  ///   into that pipe, for the audio sub-system to receive.
  /// </remarks>
  IMessageChannel = interface
    ['{E72DE502-E6B9-49B9-829C-964587A555D4}']

    ///  <summary>
    ///    Returns the name of this message channel.
    ///  </summary>
    function getName: string;

    ///  <summary>
    ///  </summary>
    function ProcessMessages( MessageHandler: TMessageHandlerProc; WaitFor: Boolean = False ): boolean;

    /// <summary>
    ///    Pushes a message into the message channel using the pipe associated
    ///    with the message originator thread.
    /// </summary>
    function Push( Pipe: IMessagePipe; MessageValue: uint32; ParamA: NativeUInt; ParamB: NativeUInt; WaitFor: Boolean = False ): TMessageResponse;

    /// <summary>
    ///   Returns a handle to a message pipe, which the calling thread may
    ///   use to inject messages into this channel.
    /// </summary>
    /// <returns>
    ///   Returns a handle to the message pipe.
    /// </returns>
    /// <remarks>
    ///   Each originating sub-system must call this method to obtain it's own
    ///   dedicated message pipe handle for this channel. Pipes are only
    //    thread-safe between two threads, the originator and the target,
    //    they may not be shared between multiple originators.
    /// </remarks>
    function getPipe: IMessagePipe;

    // - Pascal Only, Property -//

    ///  <summary>
    ///    Returns the name of this message channel.
    ///  </summary>
    property Name: string read getName;
  end;

type
  /// <summary>
  ///   Implement the ISubSystem interface to provide functionality to be
  ///   executed by the threading system. <br /><br />ISubSystem represents a
  ///   sub-system executing within a thread. Sub-systems operate
  ///   cooperatively, in that the thread will call their execute method
  ///   repeatedly for the life of the thread, and the execute method is
  ///   expected to return execution to the thread. An implementation of
  ///   ISubSystem should not enter long running loops within it's Execute
  ///   method.
  /// </summary>
  ISubSystem = interface
  ['{37CF5CD7-EB5E-4FD5-A46B-A123EFC71870}']


    /// <summary>
    ///   The Install method is called by it's executing thread as the
    ///   sub-system is installed into that thread. A reference to the message
    ///   bus is provided so that the sub-system can create any message
    ///   channels it requires. *Note, this is an opportunity to create new
    ///   message channels for the sub-system, but is too early to acquire
    ///   pipes to other sub-systems. Acquiring pipes should be done within the
    ///   implementtion of the Initialize method.
    /// </summary>
    /// <param name="MessageBus">
    ///   A reference to the global message bus, through which sub-systems
    ///   communicate.
    /// </param>
    procedure Install;

    /// <summary>
    ///   The initialize method is called by the execution thread immediately
    ///   before the thread begins calling the execute method of the
    ///   sub-system. This is an opportunity for the sub-system to allocate
    ///   memory and acquire message pipes to communicate with other
    ///   sub-systems. Note* References to any message pipes acquired here
    ///   should be retained for use during execution, there is no later
    ///   opporunity to acquire new message pipes (this would violate the
    ///   thread-safety of the messaging system, which is lose to enable
    ///   lock-less threading).
    /// </summary>
    function Initialize: boolean;

    /// <summary>
    ///   The execute() method will be called repeatedly by the execution
    ///   thread into which this sub-system is installed. The execute method is
    ///   expected to return execution as quickly as possible, as it
    ///   co-operates in a round-robin with other sub-systems installed into
    ///   the same thread.
    /// </summary>
    /// <returns>
    ///   The execute method should return true so long as it needs to continue
    ///   running. When the execute method returns false, the executing thread
    ///   will uninstall and finalize the sub-system.
    /// </returns>
    function Execute: boolean;


    /// <summary>
    ///   The finalize method is called by the execute thread as the sub-system
    ///   is uninstalled from the thread. This is an opportunity for the
    ///   sub-system to free up resources that were allocated during it's
    ///   initialization or execution.
    /// </summary>
    procedure Finalize;
  end;

type
  /// <summary>
  ///   IThreadEngine represents a collection of execution threads, including
  ///   the main thread, each of which host sub-systems for long running
  ///   operations. The ThreadEngine also provides access to the cross-thread
  ///   messaging system which allows sub-systems to communicate with each
  ///   other.
  /// </summary>
  IThreadEngine = interface
    ['{30780107-FED7-4A3B-BF80-742FDE3A8620}']

    /// <summary>
    ///   Returns the number of execution threads operating within the thread
    ///   engine, including the main application thread, which is always at
    ///   index zero.
    /// </summary>
    function getThreadCount: uint32;

    /// <summary>
    ///   Adds a subsystem to the thread. This method will only function before
    ///   the thread is started.
    /// </summary>
    /// <param name="aSubSystem">
    ///   Pass a reference to the sub-system to be installed into the thread.
    ///   The sub-system will share execution time with other installed
    ///   sub-systems.
    /// </param>
    procedure InstallSubsystem( ThreadIndex: uint32; aSubSystem: ISubSystem );

    /// <summary>
    ///   The run method starts all of the execution threads running, including
    ///   the main thread. <br />The main thread is started after the others,
    ///   and retains execution until all of it's sub-systems have shut down,
    ///   at which time it will shut down all other threads and return from
    ///   this method.
    /// </summary>
    procedure Run;

    //- Pascal Only, Properties -//

    /// <summary>
    ///   Returns the number of execution threads operating within the thread
    ///   engine, including the main application thread, which is always at
    ///   index zero.
    /// </summary>
    property ThreadCount: uint32 read getThreadCount;

  end;


type
  /// <summary>
  ///   An implementation of IMessageBus represents a collection of named
  ///   communications channels across one or more sub-systems.
  /// </summary>
  IMessageBus = interface
    ['{CAB3C192-2164-4BDB-BAD9-4F087C1BB7A4}']

    ///  <summary>
    ///    Called by a subsystem during initialization, to add it's message
    ///    channel to the bus.
    ///  </summary>
    function CreateMessageChannel( name: string ): IMessageChannel;

    ///  <summary>
    ///    Called by a subsystem during initialization, to get a connection
    ///    to a message channel for sending messages. Each thread must have
    ///    it's own connection to the channel.
    ///  </summary>
    function GetConnection( ChannelName: string ): THChannelConnection;

    ///  <summary>
    ///    Sends a message into the message channel, using the given connection handle.
    ///  </summary>
    function SendMessage( Connection: THChannelConnection; MessageValue: uint32; ParamA: NativeUInt; ParamB: NativeUInt; WaitFor: Boolean = False ): TMessageResponse;
  end;

function MessageBus: IMessageBus;

implementation
{$ifdef MSWINDOWS}
uses
  darkthreading.messagebus.windows;
{$else}
uses
  darkthreading.messagebus.posix;
{$endif}

var
  SingletonMessageBus: IMessageBus = nil;

function MessageBus: IMessageBus;
begin
  if not assigned(SingletonMessageBus) then begin
    SingletonMessageBus := TMessageBus.Create;
  end;
  Result := SingletonMessageBus;
end;

initialization

finalization
  SingletonMessageBus := nil;
end.
