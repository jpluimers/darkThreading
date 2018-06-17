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
unit darkThreading.threadsystem.standard;

interface
uses
  darkThreading;

type
  TThreadSystem = class( TInterfacedObject, IThreadSystem )
  private
    fRunning: boolean;
    fMessageBus: IMessageBus;
    fThreadPool: IThreadPool;
    fMainThread: IPoolThread;
  private //- IThreadSystem -//
    function MessageBus: IMessageBus;
    function InstallSubSystem( aSubSystem: IThreadSubsystem ): boolean;
    procedure Start;
    procedure Stop;
    procedure Run;
    function InstallAnyThread(aSubSystem: IThreadSubSystem): boolean;
    function InstallMainThread(aSubSystem: IThreadSubSystem): boolean;
  public
    constructor Create( ThreadCount: uint32 = 0 ); reintroduce;
    destructor Destroy; override;
  end;

implementation
uses
  sysutils,
  darkThreading.messagebus.standard,
  darkCollections.list;

type
  IThreadExecutor = interface
    ['{62101CBD-F657-42F0-A46B-4D22FF453FAE}']
    function isDedicated: boolean;
    function getSubSystemCount: uint32;
    function InstallSubSystem( aSubSystem: IThreadSubSystem ): boolean;
  end;

  TThreadExecutor = class( TInterfacedObject, IPoolThread, IThreadExecutor )
  private
    fDedicated: boolean;
    fMessageBus: IMessageBus;
    fSubSystems: IList<IThreadSubSystem>;
  protected
    function IsDedicated: boolean;
    function getSubSystemCount: uint32;
    function InstallSubSystem( aSubSystem: IThreadSubSystem ): boolean;
  private
    function Initialize: boolean;
    function Execute: boolean;
    procedure Finalize;
  public
    constructor Create( MessageBus: IMessageBus ); reintroduce;
    destructor Destroy; override;
  end;

constructor TThreadSystem.Create(ThreadCount: uint32);
var
  idx: uint32;
  DesiredThreads: uint32;
begin
  inherited Create;
  fRunning := False;
  fThreadPool := nil; //- unless required...
  fMessageBus := TMessageBus.Create;
  //- Determine the number of threads that are required.
  if ThreadCount=0 then begin
    DesiredThreads := CPUCount * 2;
  end else begin
    DesiredThreads := ThreadCount;
  end;
  //- Install ThreadExecutors for each of the threads.
  if DesiredThreads>1 then begin
    fThreadPool := TThreadPool.Create;
    for idx := 1 to pred(DesiredThreads) do begin
      fThreadPool.InstallThread(TThreadExecutor.Create(fMessageBus));
    end;
  end;
  //- Install a Thread executor for the main thread.
  fMainThread := TThreadExecutor.Create(fMessageBus);
end;

destructor TThreadSystem.Destroy;
begin
  if fRunning then begin
    Stop;
  end;
  fMainThread := nil;
  fThreadPool := nil;
  fMessageBus := nil;
  inherited Destroy;
end;

function TThreadSystem.InstallMainThread(aSubSystem: IThreadSubSystem): boolean;
begin
  Result := False;
  if aSubSystem.Dedicated then begin
    if (fMainThread as IThreadExecutor).getSubSystemCount>0 then begin
      exit;
    end;
  end;
  Result := (fMainThread as IThreadExecutor).InstallSubSystem(aSubSystem);
end;

function TThreadSystem.InstallAnyThread(aSubSystem: IThreadSubSystem): boolean;
var
  Executor: IThreadExecutor;
  ExecutorList: IList<IThreadExecutor>;
  LeastUsedIndex: uint32;
  idx: uint32;
begin
  Result := False;
  //- Build a list of executors which are available and not already dedicated
  ExecutorList := TList<IThreadExecutor>.Create;
  if assigned(fThreadPool) and (fThreadPool.ThreadCount>0) then begin
    for idx := 0 to pred(fThreadPool.ThreadCount) do begin
      Executor := (fThreadPool.Threads[idx] as IThreadExecutor);
      if not Executor.isDedicated then begin
        ExecutorList.Add(Executor);
      end;
    end;
  end;
//  if assigned(fMainThread) then begin
//    Executor := (fMainThread as IThreadExecutor);
//    if not Executor.isDedicated then begin
//      ExecutorList.Add(Executor);
//    end;
//  end;
  //- If there are no executors, this method will fail.
  if ExecutorList.Count=0 then begin
    exit;
  end;
  //- Now find the index of the least used executor.
  LeastUsedIndex := 0;
  if ExecutorList.Count>1 then begin
    for idx := 1 to pred(ExecutorList.Count) do begin
      if ExecutorList.Items[idx].getSubSystemCount<ExecutorList.Items[LeastUsedIndex].getSubSystemCount then begin
        LeastUsedIndex := idx;
      end;
    end;
  end;
  //- Install the new subsystem into the least used executor.
  Result := ExecutorList.Items[LeastUsedIndex].InstallSubSystem(aSubSystem);
end;

function TThreadSystem.InstallSubSystem(aSubSystem: IThreadSubsystem): boolean;
begin
  if aSubSystem.MainThread then begin
    Result := InstallMainThread(aSubSystem);
  end else begin
    Result := InstallAnyThread(aSubSystem);
  end;
end;

function TThreadSystem.MessageBus: IMessageBus;
begin
  Result := fMessageBus;
end;

procedure TThreadSystem.Run;
begin
  Start;
  try
    //- Execute the main thread
    if assigned(fMainThread) then begin
      if fMainThread.Initialize then begin
        try
          while fMainThread.Execute do;
        finally
          fMainThread.Finalize;
        end;
      end;
    end;
  finally
    Stop;
  end;
end;

procedure TThreadSystem.Start;
begin
  if fRunning then begin

    raise
      Exception.Create('Thread system already started.');
  end;
  fRunning := True;
  //- Start auxhillary threads.
  if assigned(fThreadPool) then begin
    fThreadPool.Start;
  end;
end;

procedure TThreadSystem.Stop;
begin
  if not fRunning then begin
    exit;
  end;
  fRunning := False;
  //- Terminate the auxhillary threads.
  if assigned(fThreadPool) then begin
    fThreadPool.Stop;
  end;
end;

{ TThreadExecutor }

constructor TThreadExecutor.Create(MessageBus: IMessageBus);
begin
  inherited Create;
  fDedicated := False;
  fMessageBus := MessageBus;
  fSubSystems := TList<IThreadSubSystem>.Create;
end;

destructor TThreadExecutor.Destroy;
begin
  fMessageBus := nil;
  inherited Destroy;
end;

function TThreadExecutor.Execute: boolean;
var
  idx: uint32;
begin
  Result := False;
  if fSubSystems.Count=0 then begin
    exit;
  end;
  //- Loop through and execute the subsystems.
  for idx := pred(fSubSystems.Count) downto 0 do begin
    if not fSubSystems[idx].Execute then begin
      //- remove this subsystem.
      fSubSystems[idx].Finalize;
      fSubSystems.RemoveItem(idx);
    end;
  end;
  Result := True;
end;

procedure TThreadExecutor.Finalize;
var
  idx: uint32;
begin
  if fSubSystems.Count=0 then begin
    exit;
  end;
  for idx := pred(fSubSystems.Count) downto 0 do begin
    fSubSystems[idx].Finalize;
    fSubSystems.RemoveItem(idx);
  end;
end;

function TThreadExecutor.getSubSystemCount: uint32;
begin
  Result := fSubSystems.Count;
end;

function TThreadExecutor.Initialize: boolean;
var
  idx: uint32;
begin
  Result := True;
  if fSubSystems.Count=0 then begin
    exit;
  end;
  for idx := pred(fSubSystems.Count) downto 0 do begin
    if not fSubSystems[idx].Initialize( fMessageBus ) then begin
      Result := False;
      fSubSystems.RemoveItem(idx);
    end;
  end;
end;

function TThreadExecutor.InstallSubSystem(aSubSystem: IThreadSubSystem): boolean;
begin
  Result := False;
  if not assigned(aSubSystem) then begin
    exit;
  end;
  if not aSubSystem.Install(fMessageBus) then begin
    exit;
  end;
  fSubSystems.Add(aSubSystem);
  if aSubSystem.Dedicated then begin
    fDedicated := True;
  end;
  Result := True;
end;

function TThreadExecutor.IsDedicated: boolean;
begin
  Result := fDedicated;
end;

end.
