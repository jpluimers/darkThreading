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
unit darkthreading.signaledcriticalsection.posix;

interface
{$ifndef MSWINDOWS}
uses
  Posix.SysTypes,
  darkThreading;

type
  TPosixSignaledCriticalSection = class( TInterfacedObject, ISignaledCriticalSection )
  private
    fMutex: pthread_mutex_t;
    fCondition: pthread_cond_t;
  private //- ISignaledCriticalSection -//
    procedure Acquire;
    procedure Release;
    procedure Sleep;
    procedure Wake;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
  end;

{$endif}
implementation
{$ifndef MSWINDOWS}
uses
  posix.pthread,
  posix.errno,
  sysutils;

{ TWindowsSignaledCriticalSection }

procedure TPosixSignaledCriticalSection.Acquire;
begin
  pthread_mutex_lock(fMutex);
end;

constructor TPosixSignaledCriticalSection.Create;
begin
  inherited Create;
  if pthread_mutex_init(fMutex, nil)<>0 then begin
    raise
      Exception.Create('Failed to initialize mutex. OS ERROR ('+IntToStr(errno)+')');
  end;
  if pthread_cond_init(fCondition,nil)<>0 then begin
    raise
      Exception.Create('Failed to initialize condition variable. OS ERROR ('+IntToStr(errno)+')');
  end;
end;

destructor TPosixSignaledCriticalSection.Destroy;
begin
  pthread_mutex_destroy(fMutex);
  pthread_cond_destroy(fCondition);
  inherited Destroy;
end;

procedure TPosixSignaledCriticalSection.Release;
begin
  pthread_mutex_unlock(fMutex);
end;

procedure TPosixSignaledCriticalSection.Sleep;
begin
  if pthread_cond_wait(fCondition,fMutex)<>0 then begin
    raise
      Exception.Create('An API error occurred on pthread_cond_wait(). OS ERROR ('+IntToStr(errno)+')');
  end;
end;

procedure TPosixSignaledCriticalSection.Wake;
begin
  pthread_cond_signal(fCondition);
end;

{$endif}
end.

