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
unit darkThreading.threadpool.standard;

interface
uses
  system.generics.collections,
  darkThreading;

type
  TThreadPool = class( TInterfacedObject, IThreadPool )
  private
    fRunning: boolean;
    fSubSystems: TList<ISubSystem>;
    fThreadMethods: array of IThreadMethod;
  private
    procedure CreateThreadMethods;
    procedure DisposeThreadMethods;
  private //- IThreadPool -//
    function InstallSubSystem( aSubSystem: ISubSystem ): boolean;
    function Start: boolean;
    function Stop: boolean;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
  end;

implementation
uses
  sysutils,
{$ifdef MSWINDOWS}
  darkThreading.threadmethod.windows;
{$else}
  darkThreading.threadmethod.posix;
{$endif}

type
{$ifdef MSWINDOWS}
  TThreadMethod = TWindowsThreadMethod;
{$else}
  TThreadMethod = TPosixThreadMethod;
{$endif}

  TPoolThread = class( TThreadMethod )
  private
    fSubSystem: ISubSystem;
  private
    function InternalExecute: boolean;
  public
    constructor Create( SubSystem: ISubSystem );
  end;

constructor TPoolThread.Create(SubSystem: ISubSystem);
begin
  inherited Create;
  fSubSystem := SubSystem;
  inherited setExecuteMethod(InternalExecute);
end;

function TPoolThread.InternalExecute: boolean;
begin
  Result := False;
  if not assigned(fSubSystem) then begin
    exit;
  end;
  Result := fSubSystem.Execute;
end;

constructor TThreadPool.Create;
begin
  inherited Create;
  fSubSystems := TList<ISubsystem>.Create;
  fRunning := False;
  SetLength(fThreadMethods,0);
end;

procedure TThreadPool.CreateThreadMethods;
var
  idx: int32;
begin
  if fRunning then begin
    exit;
  end;
  if fSubSystems.Count=0 then begin
    exit;
  end;
  SetLength(fThreadMethods,fSubSystems.Count);
  for idx := 0 to pred(fSubSystems.Count) do begin
    fThreadMethods[idx] := TPoolThread.Create( fSubSystems.Items[idx] );
  end;
  fRunning := True;
end;

destructor TThreadPool.Destroy;
begin
  if fRunning then begin
    Stop;
  end;
  fRunning := False;
  fSubSystems.DisposeOf;
  SetLength(fThreadMethods,0);
  inherited Destroy;
end;

procedure TThreadPool.DisposeThreadMethods;
var
  idx: int32;
begin
  if not fRunning then begin
    exit;
  end;
  if Length(fThreadMethods)=0 then begin
    exit;
  end;
  for idx := 0 to pred(Length(fThreadMethods)) do begin
    if not fThreadMethods[idx].Terminate(3000) then begin
      raise
        Exception.Create('Thread failed to terminate.');
    end;
  end;
end;

function TThreadPool.InstallSubSystem(aSubSystem: ISubSystem): boolean;
begin
  Result := False;
  if fRunning then begin
    exit;
  end;
  fSubSystems.Add(aSubsystem);
  Result := aSubSystem.Install( Self );
end;

function TThreadPool.Start: boolean;
var
  idx: int32;
  InitializeFailed: boolean;
begin
  Result := False;
  InitializeFailed := False;
  for idx := 0 to pred(fSubSystems.Count) do begin
    if not fSubSystems.Items[idx].Initialize( Self ) then begin
      InitializeFailed := True;
    end;
  end;
  if InitializeFailed then begin
    Exit;
  end;
  Result := True;
  CreateThreadMethods;
end;

function TThreadPool.Stop: boolean;
var
  idx: int32;
  FinalizeFailed: boolean;
begin
  Result := False;
  DisposeThreadMethods;
  if fSubSystems.Count=0 then begin
    exit;
  end;
  FinalizeFailed := False;
  for idx := 0 to pred(fSubSystems.Count) do begin
    if not fSubSystems.Items[idx].Finalize then begin
      FinalizeFailed := True;
    end;
  end;
  if FinalizeFailed then begin
    exit;
  end;
  Result := True;
end;

end.
