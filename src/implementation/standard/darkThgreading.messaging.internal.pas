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
unit darkThgreading.messaging.internal;

interface
uses
  darkThreading;

type
  ///  Record structure used internally to transport messages on the message
  ///  bus.
  PtrBoolean = ^Boolean;
  PtrNativeUInt = ^NativeUInt;
  TInternalMessageRecord = record
    Handled: PtrBoolean;
    Return: PtrNativeUInt;
    aMessage: TMessage;
  end;

  ///
  ///  Internal interface representing the ring buffer portion of a message pipe.
  IPipeRing = IAtomicRingBuffer<TInternalMessageRecord>;

  /// Internal implmentation of the ring buffer portion of a message pipe.
  TPipeRing = TAtomicRingBuffer<TInternalMessageRecord>;

  ///    Provides access to the ring buffer for the message channel.
  ///    This is used internally, and should not be made public.
  IMessageRingBuffer = interface
    ['{9EFC4D5D-A4B7-49F8-8ED6-E4F21E72E819}']

    ///  Provides internal access to the ring buffer from the message pipe to
    ///  the message channel.
    function GetRingBuffer: IPipeRing;
  end;

implementation

end.
