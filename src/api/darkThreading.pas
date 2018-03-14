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
    ///   Returns a reference to the class which represents the execution
    ///   thread, as specified by index.
    /// </summary>
    /// <param name="idx">
    ///   The index of the thread to be returned.
    /// </param>
    /// <returns>
    ///   If the index reflects a valid thread, a reference to the class
    ///   representing that thread is returned, otherwise nil is returned.
    /// </returns>
    /// <remarks>
    ///   Index zero always represents the main application thread.
    /// </remarks>
    function getThread( idx: uint32 ): IEngineThread;


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
    property Count: uint32 read getThreadCount;

    /// <summary>
    ///   Returns a reference to the class which represents the execution
    ///   thread, as specified by index. <br />(Provides array-style access for
    ///   convenience.)
    /// </summary>
    /// <param name="idx">
    ///   The index of the thread to be returned.
    /// </param>
    /// <returns>
    ///   If the index reflects a valid thread, a reference to the class
    ///   representing that thread is returned, otherwise nil is returned.
    /// </returns>
    /// <remarks>
    ///   Index zero always represents the main application thread.
    /// </remarks>
    property Threads[ idx: uint32 ]: IEngineThread read getThread;

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

function MessageBus: IMessageBus;

implementation

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
