if SILE.outputter ~= SILE.outputters.libtexpdf then
  SU.error("pdf package requires libtexpdf backend")
end
local pdf = require("justenoughlibtexpdf")
local utf8
if _VERSION < "Lua 5.3" then
  utf8 = require("lua-utf8")
end

SILE.registerCommand("pdf:destination", function (o,c)
  local name = o.name
  SILE.typesetter:pushHbox({ 
    value = nil,
    height = 0,
    width = 0,
    depth = 0,
    outputYourself= function (self, typesetter)
      pdf.destination(name, typesetter.frame.state.cursorX, SILE.documentState.paperSize[2] - typesetter.frame.state.cursorY)
    end
  });
end)

SILE.registerCommand("pdf:bookmark", function (o,c)
  local dest = SU.required(o, "dest", "pdf:bookmark")
  local title = SU.required(o, "title", "pdf:bookmark")
  local level = o.level or 1
  local ustr = string.format("%02x%02x", 0xfe, 0xff)
  for pos, uchr in utf8.codes(title) do
    if (uchr < 0x10000) then
      ustr = ustr..string.format("%02x%02x", uchr / 256, uchr % 256)
    else
      local sur_hi = (uchr - 0x10000) / 0x400 + 0xd800
      local sur_lo = (uchr - 0x10000) % 0x400 + 0xdc00
      ustr = ustt..string.format("%02x%02x", sur_hi / 256, sur_hi % 256)
      ustr = ustr..string.format("%02x%02x", sur_lo / 256, sur_lo % 256)
    end
  end
  SILE.typesetter:pushHbox({ 
    value = nil, height = 0, width = 0, depth = 0,
    outputYourself= function ()
      local d = "<</Title<"..ustr..">/A<</S/GoTo/D("..dest..")>>>>"
      pdf.bookmark(d, level)
    end
  });
end)

if SILE.Commands.tocentry then
  SILE.scratch.pdf = { dests = {}, dc = 1 }
  local oldtoc = SILE.Commands.tocentry
  SILE.Commands.tocentry = function (o,c)
    SILE.call("pdf:destination", { name = "dest"..SILE.scratch.pdf.dc } )
    SILE.call("pdf:bookmark", { title = c[1], dest = "dest"..SILE.scratch.pdf.dc, level = o.level })
    oldtoc(o,c)
    SILE.scratch.pdf.dc = SILE.scratch.pdf.dc + 1
  end
end

SILE.registerCommand("pdf:link", function (o,c)
  local dest = SU.required(o, "dest", "pdf:bookmark")
  local llx, lly
  SILE.typesetter:pushHbox({ 
    value = nil, height = 0, width = 0, depth = 0,
    outputYourself= function (self,typesetter)
      llx = typesetter.frame.state.cursorX
      lly = SILE.documentState.paperSize[2] - typesetter.frame.state.cursorY
      pdf.begin_annotation()
    end
  });

  local hbox = SILE.Commands["hbox"]({}, c) -- hack
  SILE.typesetter:debugState()
  
  SILE.typesetter:pushHbox({ 
    value = nil, height = 0, width = 0, depth = 0,
    outputYourself= function (self,typesetter) 
      local d = "<</Type/Annot/Subtype/Link/C [ 1 0 0 ]/A<</S/GoTo/D("..dest..")>>>>"
      pdf.end_annotation(d, llx, lly, typesetter.frame.state.cursorX, SILE.documentState.paperSize[2] -typesetter.frame.state.cursorY + hbox.height);
    end
  });end)