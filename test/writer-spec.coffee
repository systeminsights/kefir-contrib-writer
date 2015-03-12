K = require 'kefir'
R = require 'ramda'
{Tuple2} = require 'fantasy-tuples'
{Left, Right} = require 'fantasy-eithers'
{runLogValues} = require 'kefir-contrib-run'
{
  constantW,
  constantO,
  drainW,
  flatMapO,
  flatMapW,
  mapO,
  mapW,
  mergeAsWriter,
  stripO,
  stripW
} = require '../src/writer'

ws = -> K.sequentially(10, ["A", "B", "C", "D"])
os = -> K.sequentially(13, [1, 2, 3, 4])

writer = -> mergeAsWriter(ws(), os())
writer2 = -> mergeAsWriter(ws().take(2), os().take(2))

describe "drainW", ->
  it "should run the side-effect on each write, emitting outputs", ->
    s = ""
    f = (w) -> s += w
    r = runLogValues(drainW(f, writer())).then((r0) -> Tuple2(r0, s))
    expect(r).to.become(Tuple2([1, 2, 3, 4], "ABCD"))

describe "flatMapO", ->
  it "should bind on output values", ->
    f = (n) -> constantW("W#{n}")
    expect(runLogValues(stripO(flatMapO(f, writer2())))).to.become(["A", "W1", "B", "W2"])

  it "should be identity when f = constantO", ->
    expect(runLogValues(flatMapO(constantO, writer2())))
      .to.become([Left("A"), Right(1), Left("B"), Right(2)])

describe "flatMapW", ->
  it "should bind on write values", ->
    f = -> constantO(0)
    expect(runLogValues(stripW(flatMapW(f, writer2())))).to.become([0, 1, 0, 2])

  it "should be identity when f = constantW", ->
    expect(runLogValues(flatMapW(constantW, writer2())))
      .to.become([Left("A"), Right(1), Left("B"), Right(2)])

describe "mapO", ->
  it "should apply f to each output value", ->
    f = (n) -> n - 5
    expect(runLogValues(mapO(f, writer2())))
      .to.become([Left("A"), Right(-4), Left("B"), Right(-3)])

  it "should be identity when f = identity", ->
    expect(runLogValues(mapO(R.identity, writer2())))
      .to.become([Left("A"), Right(1), Left("B"), Right(2)])

describe "mapW", ->
  it "should apply f to each write value", ->
    f = (s) -> s + "X"
    expect(runLogValues(mapW(f, writer2())))
      .to.become([Left("AX"), Right(1), Left("BX"), Right(2)])

  it "should be identity when f = identity", ->
    expect(runLogValues(mapW(R.identity, writer2())))
      .to.become([Left("A"), Right(1), Left("B"), Right(2)])

describe "stripW", ->
  it "should drop written values, emitting outputs", ->
    expect(runLogValues(stripW(writer()))).to.become([1, 2, 3, 4])

