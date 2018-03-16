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
    ///    Puts the calling thread to release the mutex lock and begin
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
  ///    Implement ISubSystem to provide functionality to be executed as part
  ///    of the thread pool.
  ///  </summary>
  ISubSystem = interface
    ['{00CA7ECE-AD5D-452D-B7C6-40255F5FE8D4}']
    function Install( ThreadPool: IThreadPool ): boolean;
    function Initialize( ThreadPool: IThreadPool ): boolean;
    function Execute: boolean;
    function Finalize: boolean;
  end;

  ///  <summary>
  ///    Manages a pool of processing threads operating on a pool of ISubSystem.
  ///  </summary>
  IThreadPool = interface
    ['{F397A185-FD7E-4748-BA1F-B79D46348F34}']

    ///  <summary>
    ///    Installs a subsystem into the thread pool.
    ///    Each sub-system will be given it's own dedicate thread.
    ///  </summary>
    function InstallSubSystem( aSubSytem: ISubSystem ): boolean;

    ///  <summary>
    ///    Start the threads running.
    ///  </summary>
    function Start: boolean;

    ///  <summary>
    ///    Terminates the running threads and disposes the subsystems.
    ///  </summary>
    function Stop: boolean;
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

implementation
uses
  darkthreading.threadpool.standard,
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


end.
