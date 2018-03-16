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
    function Terminate( Timeout: uint32 = 25 ): boolean;
  protected
    procedure setExecuteMethod( value: TThreadExecuteMethod );
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
  fThreadedMethod := nil;
  Windows.CreateThread(nil,0,@InternalHandler,Self,0,ThreadID);
end;

function TWindowsThreadMethod.Terminate( Timeout: uint32 ): boolean;
var
  Counter: uint32;
begin
  Result := True;
  if not fRunning then begin
    exit;
  end;
  fTerminated := True;
  fThreadedMethod := nil;
  Counter := Timeout div 1;
  while (fRunning) and (Counter>0) do begin
    sleep(1);
    dec(Counter);
  end;
  Result := not fRunning;
end;

destructor TWindowsThreadMethod.Destroy;
begin
  if not Terminate( 500 ) then begin
    raise
      Exception.Create('Thread did not terminate.');
  end;
  CloseHandle(fHandle);
  inherited Destroy;
end;

function TWindowsThreadMethod.doExecute: uint32;
var
  fTempThreadedMethod: TThreadExecuteMethod;
begin
  fRunning := True;
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
