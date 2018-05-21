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
unit darkThreading.messagebus.standard;

interface
uses
  darkCollections.types,
  darkThreading;

type
  TMessageBus = class( TInterfacedObject, IMessageBus )
  private
    fMessageChannels: ICollection;
  private //- IMessageBus -//
    function CreateChannel( ChannelName: string ): IMessageChannel;
    function GetMessagePipe( ChannelName: string ): IMessagePipe;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
  end;

implementation
uses
  sysutils,
  darklog,
  darkThreading.messagechannel.standard,
  darkCollections.dictionary;

type
  EUniqueChannelName = class(ELogEntry);

type
  IMessageChannelDictionary = {$ifdef fpc} specialize {$endif} IDictionary<IMessageChannel>;
  TMessageChannelDictionary = {$ifdef fpc} specialize {$endif} TDictionary<IMessageChannel>;

{ TMessageBus }

constructor TMessageBus.Create;
begin
  inherited Create;
  fMessageChannels := TMessageChannelDictionary.Create(16);
end;

function TMessageBus.CreateChannel(ChannelName: string): IMessageChannel;
var
  NewChannel: IMessageChannel;
  Dictionary: IMessageChannelDictionary;
  utChannelName: string;
begin
  Result := nil;
  utChannelName := uppercase(trim(ChannelName));
  Dictionary := (fMessageChannels as IMessageChannelDictionary);
  if Dictionary.KeyExists[utChannelName] then begin
    Log.Insert(EUniqueChannelName,TLogSeverity.lsFatal,[LogBind('channelname',ChannelName)]);
  end;
  NewChannel := TMessageChannel.Create;
  Dictionary.setValueByKey(utChannelName,NewChannel);
  Result := NewChannel;
end;

destructor TMessageBus.Destroy;
begin
  fMessageChannels := nil;
  inherited;
end;

function TMessageBus.GetMessagePipe(ChannelName: string): IMessagePipe;
var
  Dictionary: IMessageChannelDictionary;
  utChannelName: string;
begin
  Result := nil;
  utChannelName := uppercase(trim(ChannelName));
  Dictionary := (fMessageChannels as IMessageChannelDictionary);
  if not Dictionary.KeyExists[utChannelName] then begin
    exit;
  end;
  Result := Dictionary.ValueByKey[utChannelName].GetMessagePipe;
end;

initialization
  Log.Register(EUniqueChannelName,'Message channel name must be unique, (%channelname%) already exists.');

end.
