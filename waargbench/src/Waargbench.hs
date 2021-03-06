{-# LANGUAGE RankNTypes #-}
module Main (main) where

import           Control.Applicative                          (liftA2)
import           Control.Lens                                 (isn't, _Left)

import           Data.Functor.Identity                        (Identity)

import           Data.Maybe                                   (isJust)
import           Data.Monoid                                  ((<>))

import           Data.ByteString                              (ByteString)
import qualified Data.ByteString                              as BS

import           Data.Attoparsec.ByteString                   (parseOnly)

import qualified Criterion.Main                               as G
import qualified HaskellWorks.Data.Json.Internal.Cursor.Token as HW

import qualified Waargonaut                                   as W

import           Waargonaut.Decode                            (Decoder)
import qualified Waargonaut.Decode.Traversal                  as D

import qualified Waargonaut.Decode                            as SD

import           Common                                       (decodeScientific, imageDecodeGeneric,
                                                               imageDecodeManual,
                                                               imageDecodeSuccinct,
                                                               parseBS)

parseOkay :: ByteString -> Bool
parseOkay = isn't _Left . parseOnly W.parseWaargonaut

succinctIndexOkay :: ByteString -> Bool
succinctIndexOkay = isJust . HW.jsonTokenAt . SD.unJCurs . SD.mkCursor

traversalDecode :: D.Decoder Identity a -> ByteString -> Bool
traversalDecode d = isn't _Left . D.simpleDecode parseBS d

succinctDecode :: Decoder Identity a -> ByteString -> Bool
succinctDecode d = isn't _Left . SD.runPureDecode d parseBS . SD.mkCursor

rf :: FilePath -> IO ByteString
rf f = BS.readFile $ "../test/json-data/" <> f

getParseFiles :: IO [ByteString]
getParseFiles = sequence
  [ (rf "jp100.json")
  , (rf "twitter100.json")
  , (rf "numbers.json")
  ]

getDecodeFiles :: IO (ByteString, ByteString)
getDecodeFiles = liftA2 (,)
  (rf "test1.json")
  (rf "numbers.json")

main :: IO ()
main = G.defaultMain
  [ parse
  , parseSuccinct
  , decode
  ]

decode :: G.Benchmark
decode = G.env getDecodeFiles $ \ ~(image, numbers) -> G.bgroup "Decode"
  [ G.bench "Image Decode (manual - traversal)" $ G.nf (traversalDecode imageDecodeManual) image
  , G.bench "Image Decode (manual - succinct)"  $ G.nf (succinctDecode imageDecodeSuccinct) image
  , G.bench "Image Decode (generic)"            $ G.nf (succinctDecode imageDecodeGeneric) image

  , G.bench "[Scientific] (manual - traversal)" $ G.nf (traversalDecode (D.list D.scientific)) numbers
  , G.bench "[Scientific] (generic)"            $ G.nf (succinctDecode decodeScientific) numbers
  ]

parse :: G.Benchmark
parse = G.env getParseFiles $ \ ~(jp100 :twitter100:numbers:_) -> G.bgroup "Parse - Attoparsec"
  [ G.bench "jp100"                    $ G.nf parseOkay jp100
  , G.bench "twitter100"               $ G.nf parseOkay twitter100
  , G.bench "numbers"                  $ G.nf parseOkay numbers
  ]

parseSuccinct :: G.Benchmark
parseSuccinct = G.env getParseFiles $ \ ~(jp100:twitter100:numbers:_) -> G.bgroup "Succinct Index"
  [ G.bench "jp100"                    $ G.nf succinctIndexOkay jp100
  , G.bench "twitter100"               $ G.nf succinctIndexOkay twitter100
  , G.bench "numbers"                  $ G.nf succinctIndexOkay numbers
  ]
