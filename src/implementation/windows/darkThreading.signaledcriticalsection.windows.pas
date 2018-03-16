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
unit darkThreading.signaledcriticalsection.windows;

interface
{$ifdef MSWINDOWS}
uses
  Windows,
  darkThreading;

type
  TWindowsSignaledCriticalSection = class( TInterfacedObject, ISignaledCriticalSection )
  private
    fMutex: _RTL_SRWLOCK;
    fCondition: CONDITION_VARIABLE;
  private //- ISignaledCriticalSection -//
    procedure Acquire;
    procedure Release;
    procedure Sleep;
    procedure Wake;
  public
    constructor Create; reintroduce;
  end;

{$endif}
implementation
{$ifdef MSWINDOWS}
uses
  sysutils;

{ TWindowsSignaledCriticalSection }

procedure TWindowsSignaledCriticalSection.Acquire;
begin
  AcquireSRWLockExclusive(fMutex);
end;

constructor TWindowsSignaledCriticalSection.Create;
begin
  inherited Create;
  InitializeSRWLock(fMutex);
  InitializeConditionVariable(fCondition);
end;

procedure TWindowsSignaledCriticalSection.Release;
begin
  ReleaseSRWLockExclusive(fMutex);
end;

procedure TWindowsSignaledCriticalSection.Sleep;
var
  Error: uint32;
begin
  if not SleepConditionVariableSRW(fCondition, fMutex, INFINITE, 0) then begin
    Error:=GetLastError;
    if Error<>ERROR_TIMEOUT then begin
      raise
        Exception.Create('A windows API error occurred on SleepConditionVariableSRW. ('+IntToStr(Error)+')');
    end;
  end;
end;

procedure TWindowsSignaledCriticalSection.Wake;
begin
  WakeConditionVariable(fCondition);
end;

{$endif}
end.
