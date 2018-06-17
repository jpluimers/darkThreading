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
  ///    The thread execute method callback, used by IThreadMethod.
  ///  </summary>
  TThreadExecuteMethod = function(): boolean of object;

  ///  <summary>
  ///    IThreadMethod represents a long running thread, which will
  ///    repeatedly call an external execute method, until that method
  ///    returns false.
  ///  </summary>
  IThreadMethod = interface
    ['{FB86E522-F520-4496-AC08-CAAE6FA0C11A}']

    ///  <summary>
    ///    Causes the running thread to shut down.
    ///  </summary>
    function Terminate( Timeout: uint32 = 25 ): boolean;

    ///  <summary>
    ///    Returns a reference to the method to be executed.
    ///  </summary>
    function getExecuteMethod: TThreadExecuteMethod;

    ///  <summary>
    ///    Sets the reference for the method to be executed.
    ///  </summary>
    procedure setExecuteMethod( value: TThreadExecuteMethod );

    //- Pascal Only, Properties -//
    property ExecuteMethod: TThreadExecuteMethod read getExecuteMethod write setExecuteMethod;
  end;

  ///  <summary>
  ///    Represents a mutex lock which may be used to protect a critical
  ///    section of code, which must be executed by only one thread at any
  ///    time.
  ///  </summary>
  ICriticalSection = interface
    ['{21F4E11C-C165-4473-82C0-1674EBD90678}']

    ///  <summary>
    ///    Acquire the mutex lock. A thread should call this to ensure that
    ///    it is executing exclusively.
    ///  </summary>
    procedure Acquire;

    ///  <summary>
    ///    Release the mutex lock. A thread calls this method to release it's
    ///    exclusive execution.
    ///  </summary>
    procedure Release;
  end;


  ///  <summary>
  ///    Represents a critical section controlled by a condition variable.
  ///    This works in the same way as an ICriticalSection, except that a
  ///    thread can put it's self to sleep (releasing the mutex), until it
  ///    is woken by an external signal from another thread. Once woken the
  ///    thread re-aquires the mutex lock and continues execution.
  ///  </summary>
  ISignaledCriticalSection = interface
    ///  <summary>
    ///    Acquire the mutex lock. A thread should call this to ensure that
    ///    it is executing exclusively.
    ///  </summary>
    procedure Acquire;

    ///  <summary>
    ///    Release the mutex lock. A thread calls this method to release it's
    ///    exclusive execution.
    ///  </summary>
    procedure Release;

    ///  <summary>
    ///    Causes the calling thread to release the mutex lock and begin
    ///    sleeping. While sleeping, the calling thread is excluded from the
    ///    thread scheduler, allowing other threads to consume it's runtime.
    ///    <remarks>
    ///      Sleep may return at any time, regardless of the work having been
    ///      completed. You should check that the work has actually been
    ///      completed, and if not, put the signaled critical seciton back
    ///      to sleep.
    ///    </remarks>
    ///  </summary>
    procedure Sleep;

    ///  <summary>
    ///    Called by some external thread, Wake causes the sleeping thread to
    ///    re-aquire the mutex lock and to continue executing.
    ///  </summary>
    procedure Wake;
  end;

  /// <summary>
  ///   An implementation of IAtomicRingBuffer provides a buffer of items which
  ///   may be exchanged between two threads. Atomic variables are used to
  ///   marshal the sharing of data between threads. <br /><br />Only two
  ///   threads may use the ring buffer during it's life-cycle. One thread (the
  ///   producer) is able to push items into the buffer, and the other thread
  ///   (the consumer) is able to pull items out of the buffer.
  /// </summary>
  /// <remarks>
  ///   <b>CAUTION -</b> There is no mechanism to prevent the consumer thread
  ///   from calling the push() method, nor the producer thread from calling
  ///   the pull() method. There is also no mechanism to prevent threads other
  ///   than the producer and consumer from calling these methods. It is your
  ///   responsibility to ensure that only one producer, and one consumer
  ///   thread calls the respective methods.
  /// </remarks>
  IAtomicRingBuffer<T: record> = interface
    ['{6681F3CF-CF51-4312-816C-3E173F57C2CB}']

    /// <summary>
    ///   The producer thread may call Push() to add an item to the
    ///   IAtomicRingBuffer.
    /// </summary>
    /// <param name="item">
    ///   The item to be added to the ring buffer. <br />
    /// </param>
    /// <returns>
    ///   Returns true if the item is successfully inserted into the ring
    ///   buffer, however, this does not indicate that the message has been
    ///   retrieved by the consumer thread. <br />If this method returns false,
    ///   the buffer is full. An unsuccessful push operation can be retried and
    ///   will be successful if the consumer thread has called Pull() to free
    ///   up space for a new item in the buffer.
    /// </returns>
    /// <remarks>
    ///   The item will be copied during the push operation, permitting the
    ///   producer thread to dispose the memory after calling push.
    /// </remarks>
    function Push( item: T ): boolean;

    /// <summary>
    ///   The Pull() method is called by the consumer thread to retrieve an
    ///   item from the ring buffer.
    /// </summary>
    /// <param name="item">
    ///   Passed by reference, item will be set to match the next item in the
    ///   buffer.
    /// </param>
    /// <returns>
    ///   If there is an item in the ring buffer to be retrieved, this method
    ///   will return true. <br />If the method returns false, the buffer is
    ///   empty, a retry may be successful if the producer thread has pushed a
    ///   new item into the buffer.
    /// </returns>
    function Pull( var item: T ): boolean;

    ///  <summary>
    ///    Returns true if the ring buffer is currently empy.
    ///  </summary>
    function IsEmpty: boolean;
  end;

  /// <summary>
  ///   Implements IAtomicRingBuffer&lt;T: record&gt;
  /// </summary>
  /// <typeparam name="T">
  ///   A record datatype (or non-object)
  /// </typeparam>
  TAtomicRingBuffer<T: record> = class( TInterfacedObject, {$ifdef fpc} specialize {$endif} IAtomicRingBuffer<T> )
  private
    fPushIndex: uint32;
    fPullIndex: uint32;
    fItems: array of T;
  private //- IAtomicRingBuffer -//
    /// <exclude />
    function Push( item: T ): boolean;
    /// <exclude />
    function Pull( var item: T ): boolean;
    /// <exclude />
    function IsEmpty: boolean;
  public

    /// <summary>
    ///   The constructor creates an instance of the atomic ring-buffer with a
    ///   pre-allocated number of items. By default, 128 items are
    ///   pre-allocated, set the ItemCount parameter to override this.
    /// </summary>
    /// <param name="ItemCount">
    ///   The number of items to pre-allocate in the buffer.
    /// </param>
    constructor Create( ItemCount: uint32 = 128 ); reintroduce;
  end;

  /// <exclude />
  IThreadPool = interface; //- forward declaration for ISubSystem

  ///  <summary>
  ///    Represents a message to be transferred along a message channel/pipe.
  ///  </summary>
  TMessage = record
    Value: nativeuint;
    ParamA: nativeuint;
    ParamB: nativeuint;
    ParamC: nativeuint;
    ParamD: nativeuint;
  end;

  ///  <summary>
  ///    An implementation of IMessagePipe represents a sender which is able
  ///    to send message into a message channel.
  ///  </summary>
  IMessagePipe = interface
    ['{0BA78A88-4082-4B7E-BD07-3920CE7440B4}']

    ///  <summary>
    ///    Sends a message into the message pipe and waits until the message
    ///    has been handled. The message handler may return a result value
    ///    in the result of this method.
    ///  </summary>
    function SendMessageWait( MessageValue: nativeuint; ParamA: nativeuint = 0; ParamB: nativeuint = 0; ParamC: nativeuint = 0; ParamD: nativeuint = 0 ): nativeuint;

    ///  <summary>
    ///    Sends a message into the message pipe.
    ///    Returns TRUE if the message was successfully sent, otherwise
    ///    returns FALSE. This method returns immediately and therefore does not
    ///    wait for a response.
    ///  </summary>
    function SendMessage( MessageValue: nativeuint; ParamA: nativeuint = 0; ParamB: nativeuint = 0; ParamC: nativeuint = 0; ParamD: nativeuint = 0 ): boolean;

  end;

  ///  <summary>
  ///    Callback used to handle messages coming from a message channel.
  ///  </summary>
  TMessageHandler = function (aMessage: TMessage): nativeuint of object;

  ///  <summary>
  ///    An implementation of IMessageChannel represents a listener for a
  ///    channel of messages. The listener may be used by a single thread only.
  ///    See IMessagePipe for multiple sender.
  ///  </summary>
  IMessageChannel = interface
    ['{69D9504A-3DCC-4294-8D9C-29020D8FB997}']

    ///  <summary>
    ///    Creates and returns a new instance of IMessagePipe which is able
    ///    to send messages into the channel.
    ///  </summary>
    function GetMessagePipe: IMessagePipe;

    ///  <summary>
    ///    Checks all message pipes connected to the channel for new incomming
    ///    messages. This method will block execution and sleep the thread
    ///    until new messages are available.
    ///  </summary>
    procedure GetMessage( Handler: TMessageHandler );

    ///  <summary>
    ///    Checks all message pipes connected to the channel for new incomming
    ///    messages. If a new message is available, MessagesWaiting will return
    ///    TRUE, otherwise FALSE.
    ///  </summary>
    function MessagesWaiting: boolean;
  end;

  ///  <summary>
  ///    Represents the global messaging system between sub-systems within a
  ///    thread pool.
  ///  </summary>
  IMessageBus = interface
    ['{1C4AB336-BFA5-4A2B-88A3-C79A1CEEFA24}']

    ///  <summary>
    ///    Create a new message channel.
    ///    Channel name must be unique, or exception will be raised.
    ///  </summary>
    function CreateChannel( ChannelName: string ): IMessageChannel;

    ///  <summary>
    ///    Returns a message pipe which may be used to send messages into the
    ///    message channel.
    ///  </summary>
    function GetMessagePipe( ChannelName: string ): IMessagePipe;
  end;

  ///  <summary>
  ///    Implement IPoolThread to provide functionality for a thread running
  ///    within a thread pool (IThreadPool)
  ///  </summary>
  IPoolThread = interface
    ['{2806DC0F-ADA9-4C52-B65E-3966CBE3FAA6}']

    ///  <summary>
    ///    Called by the operating thread as the thread starts up.
    ///  </summary>
    function Initialize: boolean;

    ///  <summary>
    ///    Called repeatedly by the operating thread, so long as execute
    ///    returns true, and the thread continues running.
    ///  </summary>
    function Execute: boolean;

    ///  <summary>
    ///    Called as the operating thread shuts down.
    ///  </summary>
    procedure Finalize;
  end;

  ///  <summary>
  ///    Manages a pool of processing threads operating on a pool of ISubSystem.
  ///  </summary>
  IThreadPool = interface
    ['{F397A185-FD7E-4748-BA1F-B79D46348F34}']

    ///  <summary>
    ///    Returns the numnber of IPoolThreads that have been installed.
    ///  </summary>
    function getThreadCount: uint32;

    ///  <summary>
    ///    Returns one of the pool thread instances by index.
    ///  </summary>
    function getThread( idx: uint32 ): IPoolThread;

    ///  <summary>
    ///    Installs a thread into the thread pool.
    ///  </summary>
    function InstallThread( aSubSytem: IPoolThread ): boolean;

    ///  <summary>
    ///    Start the threads running.
    ///  </summary>
    function Start: boolean;

    ///  <summary>
    ///    Terminates the running threads and disposes the subsystems.
    ///  </summary>
    procedure Stop;

    //- Pascal Only, Properties -//
    property ThreadCount: uint32 read getThreadCount;
    property Threads[ idx: uint32 ]: IPoolThread read getThread;
  end;

  ///  <summary>
  ///    Implement IThreadSubsystem to provide functionality to be executed
  ///    within a thread system (IThreadSystem)
  ///  </summary>
  IThreadSubSystem = interface
    ['{9CBE79FE-CDAA-4D25-A269-F2A199A16E74}']

    ///  <summary>
    ///    Return true if this thread sub-system must run in the main thread.
    ///  </summary>
    function MainThread: boolean;

    ///  <summary>
    ///    Return true if this thread sub-system must have it's own dedicated
    ///    thread.
    ///  </summary>
    function Dedicated: boolean;

    ///  <summary>
    ///    The thread system will call this method when the subsystem is
    ///    first installed. This method is always called by the main thread
    ///    as it is called before the auxhillary threads are running.
    ///  </summary>
    function Install( MessageBus: IMessageBus ): boolean;

    ///  <summary>
    ///    The operating thread for this thread sub-system will call this
    ///    method immediately after the thread starts running.
    ///  </summary>
    function Initialize( MessageBus: IMessageBus ): boolean;

    ///  <summary>
    ///    The operating thread for this thread sub-system will call this
    ///    method repeatedly during the lifetime of the thread. If this
    ///    method returns true, execution will continue. If this method
    ///    returns false, then this thread sub-system will be removed from
    ///    it's operating thread and will no longer be executed.
    ///  </summary>
    function Execute: boolean;

    ///  <summary>
    ///    The operating thread will call this method when the subsystem is
    ///    being shut down, either because the thread is terminating, or
    ///    when this thread sub-system returns false from it's execute method.
    ///  </summary>
    procedure Finalize;
  end;

  ///  <summary>
  ///    Manages a collection of sub-systems to be executed within a pool
  ///    of threads.
  ///  </summary>
  IThreadSystem = interface
    ['{9C1FB3E1-A9BC-4897-BD01-D5EA2933132D}']
    ///  <summary>
    ///    Returns the message bus which is used to allow sub-modules to
    ///    communicate with each other.
    ///  </summary>
    function MessageBus: IMessageBus;

    ///  <summary>
    ///    Installs a subsystem to be executed by the operating threads.
    ///    This method may only be called before the thread system starts
    ///    running.
    ///  </summary>
    function InstallSubSystem( aSubSystem: IThreadSubsystem ): boolean;

    ///  <summary>
    ///    Starts the ancillary threads running. When using the Start()
    ///    method (rather than the run method), the main thread remains with
    ///    the calling application. Sub-systems installed on the main thread
    ///    will not be excuted when using Start()/Stop().
    ///  </summary>
    procedure Start;

    ///  <summary>
    ///    Stops the ancillary threads which were started with a call to the
    ///    Start() method.
    ///  </summary>
    procedure Stop;

    ///  <summary>
    ///    Starts the thread system running. Auxhillary threads are started
    ///    first, and then the main thread runs. Execution continues until
    ///    the main thread exits, at which time the Auxhillary threads are
    ///    also stopped. (Use exclusive to the Start() and Stop() methods).
    ///  </summary>
    procedure Run;
  end;

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
type
  TThreadMethod = class
  public
    class function Create: IThreadMethod; static;
  end;

  TCriticalSection = class
  public
    class function Create: ICriticalSection; static;
  end;

  TSignaledCriticalSection = class
  public
    class function Create: ISignaledCriticalSection; static;
  end;

  TThreadPool = class
  public
    class function Create: IThreadPool; static;
  end;

  TThreadSystem = class
  public
    ///  <summary>
    ///    Creates an instance of IThreadSystem with the specified number of
    ///    threads. If the threads parameter is omitted or passed as zero,
    ///    then the number of threads created will be CPUCount * 2.
    ///  </summary>
    class function Create( Threads: uint32 = 0 ): IThreadSystem; static;
  end;

implementation
uses
  darkthreading.threadpool.standard,
  darkThreading.threadsystem.standard,
  {$ifdef MSWINDOWS}
  darkthreading.threadmethod.windows,
  darkthreading.signaledcriticalsection.windows,
  darkthreading.criticalsection.windows;
  {$else}
  darkthreading.threadmethod.posix,
  darkthreading.signaledcriticalsection.posix,
  darkthreading.criticalsection.posix;
  {$endif}

{ TThreadMethod }

class function TThreadMethod.Create: IThreadMethod;
begin
  {$ifdef MSWINDOWS}
  Result := TWindowsThreadMethod.Create;
  {$else}
  Result := TPosixThreadMethod.Create;
  {$endif}
end;

{ TCriticalSection }

class function TCriticalSection.Create: ICriticalSection;
begin
  {$ifdef MSWINDOWS}
  Result := TWindowsCriticalSection.Create;
  {$else}
  Result := TPosixCriticalSection.Create;
  {$endif}
end;

{ TSignaledCriticalSection }

class function TSignaledCriticalSection.Create: ISignaledCriticalSection;
begin
  {$ifdef MSWINDOWS}
  Result := TWindowsSignaledCriticalSection.Create;
  {$else}
  Result := TPosixSignaledCriticalSection.Create;
  {$endif}
end;

class function TThreadPool.Create: IThreadPool;
begin
  Result := darkthreading.threadpool.standard.TThreadPool.Create;
end;

constructor TAtomicRingBuffer<T>.Create( ItemCount: uint32 );
begin
  inherited Create;
  fPushIndex := 0;
  fPullIndex := 0;
  SetLength(fItems,ItemCount);
end;

function TAtomicRingBuffer<T>.IsEmpty: boolean;
begin
  Result := True;
  if fPullIndex=fPushIndex then begin
    exit;
  end;
  Result := False;
end;

function TAtomicRingBuffer<T>.Pull(var item: T): boolean;
var
  NewIndex: uint32;
begin
  Result := False;
  if fPullIndex=fPushIndex then begin
    exit;
  end;
  Move( fItems[fPullIndex], item, sizeof(T) );
  NewIndex := succ(fPullIndex);
  if NewIndex>=Length(fItems) then begin
    NewIndex := 0;
  end;
  fPullIndex := NewIndex;
  Result := True;
end;

function TAtomicRingBuffer<T>.Push(item: T): boolean;
var
  NewIndex: uint32;
begin
  Result := False;
  NewIndex := succ(fPushIndex);
  if (NewIndex>=Length(fItems)) then begin
    NewIndex := 0;
  end;
  if NewIndex=fPullIndex then begin
    Exit;
  end;
  Move( item, fItems[fPushIndex], sizeof(T) );
  fPushIndex := NewIndex;
  Result := True;
end;


{  TThreadSystem }

class function TThreadSystem.Create( Threads: uint32 = 0 ): IThreadSystem;
begin
  Result := darkThreading.threadsystem.standard.TThreadSystem.Create( Threads );
end;

end.
