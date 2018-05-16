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
unit darkThreading.messagechannel.standard;

interface
uses
  darkcollections.types,
  darkThreading;


type
  TMessageChannel = class( TInterfacedObject, IMessageChannel )
  private
    fMessagePipes: ICollection;
    fPushCS: ISignaledCriticalSection;
    fPullCS: ISignaledCriticalSection;
  private //- IMessageChannel -//
    function GetMessagePipe: IMessagePipe;
    procedure GetMessage( var aMessage: TMessage );
    function PeekMessage( var aMessage: TMessage ): boolean;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
  end;

implementation
uses
  darkCollections.list,
  darkThgreading.messaging.internal,
  darkThreading.messagepipe.standard;

type
  IMessagePipeList = {$ifdef fpc} specialize {$endif} IList<IMessagePipe>;
  TMessagePipeList = {$ifdef fpc} specialize {$endif} TList<IMessagePipe>;

{ TMessageChannel }

constructor TMessageChannel.Create;
begin
  inherited Create;
  fPushCS := TSignaledCriticalSection.Create;
  fPullCS := TSignaledCriticalSection.Create;
  fMessagePipes := TMessagePipeList.Create(16);
end;

destructor TMessageChannel.Destroy;
begin
  fMessagePipes := nil;
  fPushCS := nil;
  fPullCS := nil;
  inherited Destroy;
end;

procedure TMessageChannel.GetMessage(var aMessage: TMessage);
begin
  if not PeekMessage(aMessage) then begin
    while not PeekMessage(aMessage) do begin
      fPushCS.Sleep;
    end;
    fPushCS.Release;
  end;
end;

function TMessageChannel.GetMessagePipe: IMessagePipe;
var
  NewPipe: IMessagePipe;
begin
  NewPipe := TMessagePipe.Create(fPushCS,fPullCS);
  IMessagePipeList(fMessagePipes).Add(NewPipe);
  Result := NewPipe;
end;

function TMessageChannel.PeekMessage(var aMessage: TMessage): boolean;
var
  Count: uint32;
  idx: uint32;
  CurrentPipe: IMessagePipe;
  PipeRing: IPipeRing;
  aMessageRec: TInternalMessageRecord;
begin
  Result := False;
  Count := IMessagePipeList(fMessagePipes).Count;
  if Count=0 then begin
    exit;
  end;
  //- Loop through pipes.
  for idx := 0 to pred(Count) do begin
    CurrentPipe := IMessagePipeList(fMessagePipes).Items[idx];
    PipeRing := (CurrentPipe as IMessageRingBuffer).GetRingBuffer;
    if PipeRing.Pull(aMessageRec) then begin
      Move(aMessageRec.aMessage,aMessage,sizeof(TMessage));
      Result := True;
      exit;
    end;
  end;
end;

end.
