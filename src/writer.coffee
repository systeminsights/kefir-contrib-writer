R = require 'ramda'
K = require 'kefir'
{Left, Right} = require 'fantasy-eithers'
{leftMap, rightMap} = require 'fantasy-contrib-either'

# Functions for dealing with "writer" streams which are streams where every
# value is either a (w)rite or an (o)utput, i.e. Kefir e (Either w o).
#
# Functions in this file end in 'W' or 'O' to indicate whether they operate on
# the written or output side, respectively.
#
# In docs, we'll refer to this type of stream as Writer e w o.

# :: o -> Writer e w o
#
# Create a writer that emits a single output
#
constantO =
  R.compose(K.constant, Right)

# :: w -> Writer e w o
#
# Create a writer that emits a single write
#
constantW =
  R.compose(K.constant, Left)

# :: (o -> ()) -> Writer e w o -> Kefir e w
#
# Consume the output side of the writer using the given side-effect.
#
drainO = R.curry((f, writer) ->
  writer.withHandler((emitter, event) ->
    switch event.type
      when 'end'   then emitter.end()
      when 'error' then emitter.error(event.value)
      when 'value' then event.value.fold(emitter.emit, f)
  ))

# :: (w -> ()) -> Writer e w o -> Kefir e o
#
# Consume the write side of the writer using the given side-effect.
#
drainW = R.curry((f, writer) ->
  drainO(f, writer.invoke('swap')))

# :: Emitter -> o -> ()
#
# Emit the (o)utput side of a writer stream.
#
emitO = R.curry((emitter, o) ->
  emitter.emit(Right(o)))

# :: Emitter -> w -> ()
#
# Emit the (w)rite side of a writer stream.
#
emitW = R.curry((emitter, w) ->
  emitter.emit(Left(w)))

# :: (o -> Writer e w o) -> Writer e w o -> Writer e w o
#
# Monadic bind on the output side of a writer.
#
flatMapO = R.curry((f, writer) ->
  writer.flatMap((wo) -> wo.fold(constantW, f)))

# :: (w -> Writer e w o) -> Writer e w o -> Writer e w o
#
# Monadic bind on the write side of a writer.
#
flatMapW = R.curry((f, writer) ->
  writer.flatMap((wo) -> wo.fold(f, constantO)))

# :: Kefir e o -> Writer e w o
#
# Lift an observable to the output side of a writer.
#
liftO = (obsO) ->
  obsO.map(Right)

# :: Kefir e w -> Writer e w o
#
# Lift an observable to the write side of a writer.
#
liftW = (obsW) ->
  obsW.map(Left)

# :: (o -> o2) -> Writer e w o -> Writer e w o2
#
# Map over the output side of a writer.
#
mapO = R.curry((f, writer) ->
  writer.map(rightMap(f)))

# :: (w -> w2) -> Writer e w o -> Writer e w2 o
#
# Map over the write side of a writer.
#
mapW = R.curry((f, writer) ->
  writer.map(leftMap(f)))

# :: Kefir e w -> Kefir e o -> Writer e w o
#
# Merge two streams into a writer stream.
#
mergeAsWriter = R.curry((obsW, obsO) ->
  liftW(obsW).merge(liftO(obsO)))

# :: Writer e w o -> Kefir e w
#
# Remove the output side of this writer, returning a stream of writes.
#
stripO = (writer) ->
  writer.flatMap((wo) -> wo.fold(K.constant, R.always(K.never())))

# :: Writer e w o -> Kefir e o
#
# Remove the write side of this writer, returning a stream of outputs.
#
stripW = (writer) ->
  stripO(writer.invoke('swap'))

module.exports = {
  constantO,
  constantW,
  drainO,
  drainW,
  emitO,
  emitW,
  flatMapO,
  flatMapW,
  mapO,
  mapW,
  mergeAsWriter,
  stripO,
  stripW
}

