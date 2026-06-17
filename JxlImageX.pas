unit JxlImageX;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// Description:	Jxl port                                                      //
// Version:	0.3                                                           //
// Date:	17-JUN-2026                                                   //
// License:     MIT                                                           //
// Target:	Win64, Free Pascal, Delphi                                    //
// Copyright:	(c) 2026 Xelitan.com.                                         //
//		All rights reserved.                                          //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

interface

uses Classes, Graphics, SysUtils, Math, Types, Dialogs,
     {$IFDEF FPC}IntfGraphics, FPImage, GraphType,{$ENDIF}
     jxl_encoder, jxlimage;

  { TJxlImage }
type
  TJxlImage = class(TGraphic)
  private
    FBmp: TBitmap;
    procedure DecodeFromStream(Str: TStream);
  protected
    procedure Draw(ACanvas: TCanvas; const Rect: TRect); override;
  //    function GetEmpty: Boolean; virtual; abstract;
    function GetHeight: Integer; override;
    function GetTransparent: Boolean; override;
    function GetWidth: Integer; override;
    procedure SetHeight(Value: Integer); override;
    procedure SetTransparent(Value: Boolean); override;
    procedure SetWidth(Value: Integer);override;
  public
    // Encode the internal bitmap to Jxl and write it to Str.
    procedure EncodeToStream(Str: TStream; IsLossless: Boolean = False;
                             CompressionLevel: Integer = 75);
    procedure Assign(Source: TPersistent); override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
    constructor Create; override;
    destructor Destroy; override;
    function ToBitmap: TBitmap;
  end;

implementation

{ TJxlImage }


procedure TJxlImage.DecodeFromStream(Str: TStream);
var
  Data    : array of Byte;
  DataSize: NativeUInt;
  Pixels  : TBytes;
  W, H, y,x,i : Integer;
  dec     : TJxlDEcoder;
  P       : PByteArray;
begin
  dec := TJxlDecoder.Create;  

  try
    dec.LoadFromStream(Str);
  except
  end;

  pixels := dec.GetRGBA8;

  W := dec.Width;
  H:= dec.Height;

  if Pixels = nil then
    raise EInvalidGraphic.Create('Jxl decode failed');
  try
    FBmp.PixelFormat := pf32bit;
    FBmp.SetSize(W, H);

    i := 0;
    for y := 0 to H - 1 do begin
      P := FBmp.Scanline[y];

      for x:=0 to W-1 do begin
        P[4*x+2] := Pixels[i];
        P[4*x+1] := Pixels[i+1];
        P[4*x+0] := Pixels[i+2];
        P[4*x+3] := Pixels[i+3];
        Inc(i,4);
      end;
    end;
  finally
    dec.Free;
  end;
end;

procedure TJxlImage.Draw(ACanvas: TCanvas; const Rect: TRect);
begin
  ACanvas.StretchDraw(Rect, FBmp);
end;

function TJxlImage.GetHeight: Integer;
begin
  Result := FBmp.Height;
end;

function TJxlImage.GetTransparent: Boolean;
begin
  Result := False;
end;

function TJxlImage.GetWidth: Integer;
begin
  Result := FBmp.Width;
end;

procedure TJxlImage.SetHeight(Value: Integer);
begin
  FBmp.Height := Value;
end;

procedure TJxlImage.SetTransparent(Value: Boolean);
begin
  //
end;

procedure TJxlImage.SetWidth(Value: Integer);
begin
  FBmp.Width := Value;
end;

procedure TJxlImage.Assign(Source: TPersistent);
var Src: TGraphic;
begin
  if source is tgraphic then begin
    Src := Source as TGraphic;
    FBmp.SetSize(Src.Width, Src.Height);
    FBmp.Canvas.Draw(0,0, Src);
  end;
end;

procedure TJxlImage.LoadFromStream(Stream: TStream);
begin
  DecodeFromStream(Stream);
end;

procedure TJxlImage.EncodeToStream(Str: TStream; IsLossless: Boolean = False;
                                    CompressionLevel: Integer = 75);
var
  rgb, jxl: TBytes;
  w, h, q,i,x: Integer;
  y: Integer;
  p: PByteArray;
begin
  if (FBmp = nil) or (FBmp.Width <= 0) or (FBmp.Height <= 0) then
    raise EInvalidGraphic.Create('Jxl encode: empty bitmap');
  
  w := FBmp.Width;
  h := FBmp.Height;

  SetLength(rgb, w*h*3);

  i := 0;
  for y := 0 to H - 1 do begin
    P := FBmp.Scanline[y];

    for x:=0 to W-1 do begin
      rgb[i  ] := P[4*x+2];
      rgb[i+1] := P[4*x+1];
      rgb[i+2] := P[4*x+0];
      //rgb[i+3] := P[4*x+3];
      Inc(i,3);
    end;
  end;

  q := 70;
  jxl := JxlEncodeRGB8(rgb, w, h, q);

  Str.Write(jxl[0], Length(jxl));
end;

procedure TJxlImage.SaveToStream(Stream: TStream);
begin
  // Default: lossy, quality 75. Use EncodeToStream for explicit control.
  EncodeToStream(Stream, False, 75);
end;

constructor TJxlImage.Create;
begin
  inherited Create;

  FBmp := TBitmap.Create;
  FBmp.PixelFormat := pf32bit;
  FBmp.SetSize(1,1);
end;

destructor TJxlImage.Destroy;
begin
  FBmp.Free;
  inherited Destroy;
end;

function TJxlImage.ToBitmap: TBitmap;
begin
  Result := FBmp;
end;

initialization
  TPicture.RegisterFileFormat('Jxl','JPEG XL Image', TJxlImage);

finalization
  TPicture.UnregisterGraphicClass(TJxlImage);

end.
