import std/httpclient
import std/htmlparser
import std/xmltree
import std/strtabs
import std/times
import std/osproc
import std/parseopt
import std/strutils
import std/os

const 
  statusPageUrl = "https://leagueoflinux.org/status/"

var
  parser = initOptParser() 
  client = newHttpClient()

type 
  Mode = enum
    once, repeat

type
  CmdOptions = object
    mode: Mode
    time: Duration

proc getOpts: CmdOptions
proc getStatus: string

proc main =
  let options = getOpts()
  let status = getStatus()

  while options.mode == repeat:
    discard execCmd("notify-send -a 'LoL Status' -t 10000 'Status: " & status & "'")
    sleep(options.time.inMilliseconds())
  
  discard execCmd("notify-send -a 'LoL Status' -t 10000 'Status: " & status & "'")

when isMainModule:
  main()


proc getOpts: CmdOptions =
  for _, key, val in parser.getopt():
    case key
    of "m", "mode":
      result.mode = if val == "repeat": repeat else: once
    of "t", "time":
      result.time = initDuration(minutes=parseInt(val))


proc getStatus: string =
  try:
    let html = client.getContent(statusPageUrl).parseHtml()
    for node in html.findAll("p"):
      if not node.attrs.isNil and node.attrs.hasKey("class") and node.attrs["class"] == "admonition-title":
        return node.innerText
  finally:
    client.close()
  return "Status read unavailable"