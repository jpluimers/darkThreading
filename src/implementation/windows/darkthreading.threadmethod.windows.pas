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
unit darkthreading.threadmethod.windows;

interface
{$ifdef MSWINDOWS}
uses
  Windows,
  darkthreading;

type
  TWindowsThreadMethod = class( TInterfacedObject, IThreadMethod )
  private
    fHandle: THandle;
    fRunning: boolean;
    fTerminated: Boolean;
    fThreadedMethod: TThreadExecuteMethod;
  private
    function getExecuteMethod: TThreadExecuteMethod;
    procedure setExecuteMethod( value: TThreadExecuteMethod );
    function WaitFor: boolean;
    procedure Terminate;
  protected
    function doExecute: uint32;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
  end;

{$endif}
implementation
{$ifdef MSWINDOWS}
uses
  SysUtils;

function InternalHandler( threadmethod: pointer ): uint32; stdcall;
begin
  Result := TWindowsThreadMethod(threadmethod).doExecute;
end;

constructor TWindowsThreadMethod.Create;
var
  ThreadID: uint32;
begin
  inherited Create;
  fTerminated := False;
  fRunning := True;
  fThreadedMethod := nil;
  Windows.CreateThread(nil,0,@InternalHandler,Self,0,ThreadID);
end;

function TWindowsThreadMethod.WaitFor: boolean;
var
  WaitCounter: uint32;
begin
  Result := False;
  WaitCounter := 500;
  while (fRunning) or (WaitCounter>0) do begin
    Sleep(1);
    dec(WaitCounter);
  end;
  Result := not fRunning;
end;

procedure TWindowsThreadMethod.Terminate;
begin
  fTerminated := True;
end;

destructor TWindowsThreadMethod.Destroy;
begin
  if fRunning then begin
    fTerminated := True;
    if not WaitFor then begin
      raise
        Exception.Create('Failed to terminate thread.');
    end;
  end;
  fThreadedMethod := nil;
  CloseHandle(fHandle);
  inherited Destroy;
end;

function TWindowsThreadMethod.doExecute: uint32;
var
  fTempThreadedMethod: TThreadExecuteMethod;
begin
  while not fTerminated do begin
    fTempThreadedMethod := fThreadedMethod;
    if assigned(fTempThreadedMethod) then begin
      if not fTempThreadedMethod() then begin
        fTerminated := True;
      end;
    end;
  end;
  fRunning := False;
  Result := 0;
end;

function TWindowsThreadMethod.getExecuteMethod: TThreadExecuteMethod;
begin
  Result := fThreadedMethod;
end;

procedure TWindowsThreadMethod.setExecuteMethod(value: TThreadExecuteMethod);
begin
  fThreadedMethod := value;
end;

{$endif}
end.
