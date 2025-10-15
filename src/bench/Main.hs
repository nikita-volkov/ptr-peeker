module Main (main) where

import Criterion.Main
import Data.Serialize qualified as Cereal
import Data.Store qualified as Store
import Data.Vector qualified as V
import Data.Vector.Unboxed qualified as Vu
import Flat.Decoder qualified as Flat
import GHC.Stack (HasCallStack)
import PtrPeeker qualified as PtrPeeker
import Test.Tasty.HUnit qualified as Tasty
import Prelude

main :: IO ()
main = do
  putStrLn "Testing"
  groups <-
    sequence
      [ let input = Cereal.runPut $ do
              Cereal.putWord32be 1
              Cereal.putWord32be 2
              Cereal.putWord32be 3
            correctDecoding = (1, 2, 3)
            subjects =
              [ ( "ptr-peeker/fixed",
                  hush . PtrPeeker.runVariableOnByteString (PtrPeeker.fixed $ (,,) <$> PtrPeeker.beUnsignedInt4 <*> PtrPeeker.beUnsignedInt4 <*> PtrPeeker.beUnsignedInt4)
                ),
                ( "ptr-peeker/variable",
                  hush . PtrPeeker.runVariableOnByteString ((,,) <$> PtrPeeker.fixed PtrPeeker.beUnsignedInt4 <*> PtrPeeker.fixed PtrPeeker.beUnsignedInt4 <*> PtrPeeker.fixed PtrPeeker.beUnsignedInt4)
                ),
                ( "store",
                  hush . Store.decode @(Word32, Word32, Word32)
                ),
                ( "cereal",
                  hush . Cereal.runGet ((,,) <$> Cereal.getWord32be <*> Cereal.getWord32be <*> Cereal.getWord32be)
                ),
                ( "flat",
                  let get = (,,) <$> Flat.dBE32 <*> Flat.dBE32 <*> Flat.dBE32
                   in \input -> hush (Flat.strictDecoder get input 0)
                )
              ]
         in initGroup "word32-be-triplet" input correctDecoding subjects,
        let input =
              Cereal.runPut
                $ Cereal.putWord32le 100
                <> replicateM_ 100 (Cereal.putWord32le 123)
            correctDecoding =
              Vu.replicate 100 123
            subjects =
              [ ( "ptr-peeker",
                  let decoder = do
                        size <- PtrPeeker.fixed PtrPeeker.leUnsignedInt4
                        PtrPeeker.fixed $ PtrPeeker.fixedArray @Vu.Vector PtrPeeker.leUnsignedInt4 $ fromIntegral size
                   in hush . PtrPeeker.runVariableOnByteString decoder
                ),
                ( "store",
                  let decoder = do
                        size <- Store.peek @Word32
                        Vu.replicateM (fromIntegral size) $ Store.peek @Word32
                   in hush . Store.decodeWith decoder
                ),
                ( "cereal",
                  let decoder = do
                        size <- Cereal.getWord32le
                        Vu.replicateM (fromIntegral size) $ Cereal.getWord32le
                   in hush . Cereal.runGet decoder
                )
                -- Disabled because Flat fails on this one with the following error:
                -- NotEnoughSpace (0x0000007002a04264,S {currPtr = 0x0000007002a04264, usedBits = 0})
                --
                -- ,
                -- ("flat",
                --   let get = do
                --         size <- Flat.dBE32
                --         Vu.replicateM (fromIntegral size) Flat.dBE32
                --    in \input -> hush (Flat.strictDecoder get input 0)
                -- )
              ]
         in initGroup "array-of-int4" input correctDecoding subjects,
        let input = Cereal.runPut $ do
              Cereal.putInt64le 100
              replicateM_ 100 $ do
                Cereal.putInt64le 3
                Cereal.putByteString "abc"
            correctDecoding = V.replicate 100 "abc"
            subjects =
              [ ( "ptr-peeker",
                  let decoder = do
                        size <- PtrPeeker.fixed PtrPeeker.leSignedInt8
                        PtrPeeker.variableArray @V.Vector byteStringDecoder $ fromIntegral size
                      byteStringDecoder = do
                        size <- PtrPeeker.fixed PtrPeeker.leSignedInt8
                        PtrPeeker.fixed $ PtrPeeker.byteArrayAsByteString $ fromIntegral size
                   in hush . PtrPeeker.runVariableOnByteString decoder
                ),
                ( "store",
                  hush . Store.decode
                ),
                ( "cereal",
                  let decoder = do
                        size <- Cereal.getInt64le
                        V.replicateM (fromIntegral size) $ do
                          size <- Cereal.getInt64le
                          Cereal.getByteString $ fromIntegral size
                   in hush . Cereal.runGet decoder
                )
              ]
         in initGroup "array-of-byte-arrays" input correctDecoding subjects
      ]

  putStrLn "Benchmarking"
  defaultMain groups

-- | Test functions and create a benchmark group out of them.
initGroup :: (HasCallStack) => (Eq a, Show a, NFData a) => String -> ByteString -> a -> [(String, ByteString -> Maybe a)] -> IO Benchmark
initGroup name input correctDecoding subjects = do
  fmap (bgroup name) . forM subjects $ \(name, f) -> do
    case f input of
      Nothing -> fail "Decoding failed"
      Just _decodedValue -> pure ()
    return $ bench name $ nf f input

-- | Suppress the 'Left' value of an 'Either'
hush :: Either a b -> Maybe b
hush = either (const Nothing) Just
