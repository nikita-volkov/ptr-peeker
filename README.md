# ptr-peeker

A high-performance binary data deserialization library for Haskell that provides composable decoders for both fixed-size and variable-size binary data structures.

## Features

- **High Performance**: Outperforms "cereal" and "store" (see [Benchmarks](#benchmarks))
- **Flexible**: Lets you implement decoders of any complexity using standard `Applicative` and `Monad` interfaces
- **Type-Safe**: Abstracts over low-level pointer manipulations

## Quick Start

```haskell
import PtrPeeker
import qualified Data.Vector

data Point = Point Int32 Int32 Int32

point :: Variable Point  
point =
  fixed (Point <$> beSignedInt4 <*> beSignedInt4 <*> beSignedInt4)

points :: Variable (Data.Vector.Vector Point)
points = do
  count <- fixed beUnsignedInt4
  Data.Vector.replicateM (fromIntegral count) point

decodePoint :: ByteString -> Either Int (Data.Vector.Vector Point)
decodePoint = runVariableOnByteString points
```

## Documentation

- [Haddocks for the latest commit on `master`](https://nikita-volkov.github.io/ptr-peeker)
- [Haddocks for releases on Hackage](https://hackage.haskell.org/package/ptr-peeker)

## Benchmarks

```
benchmarking word32-be-triplet/ptr-peeker/fixed
time                 15.09 ns   (14.84 ns .. 15.41 ns)
                     0.998 R²   (0.996 R² .. 1.000 R²)
mean                 14.93 ns   (14.85 ns .. 15.13 ns)
std dev              437.9 ps   (118.6 ps .. 739.7 ps)
variance introduced by outliers: 48% (moderately inflated)

benchmarking word32-be-triplet/ptr-peeker/variable
time                 16.19 ns   (16.12 ns .. 16.28 ns)
                     1.000 R²   (0.999 R² .. 1.000 R²)
mean                 16.31 ns   (16.15 ns .. 16.81 ns)
std dev              914.2 ps   (279.7 ps .. 1.695 ns)
variance introduced by outliers: 78% (severely inflated)

benchmarking word32-be-triplet/store
time                 122.3 ns   (121.7 ns .. 122.9 ns)
                     1.000 R²   (1.000 R² .. 1.000 R²)
mean                 121.9 ns   (121.2 ns .. 122.4 ns)
std dev              1.798 ns   (1.486 ns .. 2.254 ns)
variance introduced by outliers: 17% (moderately inflated)

benchmarking word32-be-triplet/cereal
time                 19.40 ns   (19.33 ns .. 19.48 ns)
                     1.000 R²   (1.000 R² .. 1.000 R²)
mean                 19.41 ns   (19.35 ns .. 19.48 ns)
std dev              259.2 ps   (187.3 ps .. 386.4 ps)
variance introduced by outliers: 16% (moderately inflated)

benchmarking word32-be-triplet/flat
time                 113.1 ns   (112.7 ns .. 113.5 ns)
                     1.000 R²   (1.000 R² .. 1.000 R²)
mean                 113.0 ns   (112.5 ns .. 113.4 ns)
std dev              1.587 ns   (1.218 ns .. 2.252 ns)
variance introduced by outliers: 16% (moderately inflated)

benchmarking array-of-int4/ptr-peeker
time                 105.2 ns   (105.0 ns .. 105.3 ns)
                     1.000 R²   (1.000 R² .. 1.000 R²)
mean                 105.1 ns   (104.9 ns .. 105.3 ns)
std dev              641.6 ps   (530.3 ps .. 814.7 ps)

benchmarking array-of-int4/store
time                 893.7 ns   (890.7 ns .. 896.7 ns)
                     1.000 R²   (1.000 R² .. 1.000 R²)
mean                 893.3 ns   (889.4 ns .. 897.8 ns)
std dev              13.54 ns   (10.62 ns .. 17.20 ns)
variance introduced by outliers: 15% (moderately inflated)

benchmarking array-of-int4/cereal
time                 2.102 μs   (2.090 μs .. 2.115 μs)
                     1.000 R²   (0.999 R² .. 1.000 R²)
mean                 2.097 μs   (2.088 μs .. 2.109 μs)
std dev              36.71 ns   (26.99 ns .. 52.83 ns)
variance introduced by outliers: 18% (moderately inflated)

benchmarking array-of-byte-arrays/ptr-peeker
time                 2.050 μs   (2.044 μs .. 2.056 μs)
                     1.000 R²   (1.000 R² .. 1.000 R²)
mean                 2.055 μs   (2.048 μs .. 2.071 μs)
std dev              31.48 ns   (16.48 ns .. 58.61 ns)
variance introduced by outliers: 15% (moderately inflated)

benchmarking array-of-byte-arrays/store
time                 3.180 μs   (3.169 μs .. 3.196 μs)
                     1.000 R²   (1.000 R² .. 1.000 R²)
mean                 3.171 μs   (3.159 μs .. 3.182 μs)
std dev              35.48 ns   (25.85 ns .. 56.55 ns)

benchmarking array-of-byte-arrays/cereal
time                 3.791 μs   (3.750 μs .. 3.866 μs)
                     0.997 R²   (0.990 R² .. 1.000 R²)
mean                 3.785 μs   (3.753 μs .. 3.903 μs)
std dev              188.2 ns   (36.25 ns .. 392.9 ns)
variance introduced by outliers: 63% (severely inflated)
```