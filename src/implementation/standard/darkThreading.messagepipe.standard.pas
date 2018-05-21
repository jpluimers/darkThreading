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
unit darkThreading.messagepipe.standard;

interface
uses
  darkThgreading.messaging.internal,
  darkThreading;

type
  TMessagePipe = class( TInterfacedObject, IMessagePipe, IMessageRingBuffer )
  private
    fPipeRing: IPipeRing;
    [weak] fPullCS: ISignaledCriticalSection;
    [weak] fPushCS: ISignaledCriticalSection;
  private //- IMessageRingBuffer -//
    function GetRingBuffer: IPipeRing;
  private //- IMessagePipe -//
    function SendMessageWait( MessageValue: nativeuint; ParamA: nativeuint = 0; ParamB: nativeuint = 0; ParamC: nativeuint = 0; ParamD: nativeuint = 0 ): nativeuint;
    function SendMessage( MessageValue: nativeuint; ParamA: nativeuint = 0; ParamB: nativeuint = 0; ParamC: nativeuint = 0; ParamD: nativeuint = 0 ): boolean;
  public
    constructor Create( PushCS: ISignaledCriticalSection; PullCS: ISignaledCriticalSection ); reintroduce;
    destructor Destroy; override;
  end;

implementation
uses
  sysutils;


{ TMessagePipe }

constructor TMessagePipe.Create( PushCS: ISignaledCriticalSection; PullCS: ISignaledCriticalSection );
begin
  inherited Create;
  fPushCS := PushCS;
  fPullCS := PullCS;
  fPipeRing := TPipeRing.Create;
end;

destructor TMessagePipe.Destroy;
begin
  fPipeRing := nil;
  fPushCS := nil;
  inherited Destroy;
end;

function TMessagePipe.GetRingBuffer: IPipeRing;
begin
  Result := fPipeRing;
end;

function TMessagePipe.SendMessage(MessageValue: nativeuint; ParamA: nativeuint = 0; ParamB: nativeuint = 0; ParamC: nativeuint = 0; ParamD: nativeuint = 0): boolean;
var
  aMessageRec: TInternalMessageRecord;
begin
  aMessageRec.Handled := nil;
  aMessageRec.Return := nil;
  aMessageRec.aMessage.Value := MessageValue;
  aMessageRec.aMessage.ParamA := ParamA;
  aMessageRec.aMessage.ParamB := ParamB;
  aMessageRec.aMessage.ParamC := ParamC;
  aMessageRec.aMessage.ParamD := ParamD;
  Result := fPipeRing.Push(aMessageRec);
  fPushCS.Wake;
end;

function TMessagePipe.SendMessageWait(MessageValue: nativeuint; ParamA: nativeuint = 0; ParamB: nativeuint = 0; ParamC: nativeuint = 0; ParamD: nativeuint = 0): nativeuint;
var
  aMessageRec: TInternalMessageRecord;
  Handled: boolean;
begin
  Result := 0;
  Handled := False;
  aMessageRec.Handled := @Handled;
  aMessageRec.Return := @Result;
  aMessageRec.aMessage.Value := MessageValue;
  aMessageRec.aMessage.ParamA := ParamA;
  aMessageRec.aMessage.ParamB := ParamB;
  aMessageRec.aMessage.ParamC := ParamC;
  aMessageRec.aMessage.ParamD := ParamD;
  while not fPipeRing.Push(aMessageRec) do Sleep(0);
  fPushCS.Wake;
  fPullCS.Acquire;
  try
    while not Handled do begin
      fPullCS.Sleep;
    end;
  finally
    fPullCS.Release;
  end;
end;

end.
